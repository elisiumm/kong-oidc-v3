**#EDIT: Using kong-oidc via luarocks: Supporting Kong v3+**

If you're using Docker, add this line to your Dockerfile:
RUN ["luarocks", "install", "kong-oidc-v3"] 

# What is Kong OIDC plugin

[![Join the chat at https://gitter.im/nokia/kong-oidc](https://badges.gitter.im/nokia/kong-oidc.svg)](https://gitter.im/nokia/kong-oidc?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

**Continuous Integration:** [![Build Status](https://travis-ci.org/nokia/kong-oidc.svg?branch=master)](https://travis-ci.org/nokia/kong-oidc)
[![Coverage Status](https://coveralls.io/repos/github/nokia/kong-oidc/badge.svg?branch=master)](https://coveralls.io/github/nokia/kong-oidc?branch=master) <br/>

**kong-oidc** is a plugin for [Kong](https://github.com/Mashape/kong) implementing the
[OpenID Connect](http://openid.net/specs/openid-connect-core-1_0.html) Relying Party (RP) functionality.

It authenticates users against an OpenID Connect Provider using
[OpenID Connect Discovery](http://openid.net/specs/openid-connect-discovery-1_0.html)
and the Basic Client Profile (i.e. the Authorization Code flow).

It maintains sessions for authenticated users by leveraging `lua-resty-openidc` thus offering
a configurable choice between storing the session state in a client-side browser cookie or use
in of the server-side storage mechanisms `shared-memory|memcache|redis`.



It supports server-wide caching of resolved Discovery documents and validated Access Tokens.

It can be used as a reverse proxy terminating OAuth/OpenID Connect in front of an origin server so that
the origin server/services can be protected with the relevant standards without implementing those on
the server itself.

The introspection functionality adds capability for already authenticated users and/or applications that
already possess access token to go through kong. The actual token verification is then done by Resource Server.

## How does it work

The diagram below shows the message exchange between the involved parties.

![alt Kong OIDC flow](docs/kong_oidc_flow.png)

The `X-Userinfo` header contains the **Base64 encoded** payload from the Userinfo Endpoint.
 
 **Decoded payload example:**
```json
X-Userinfo: {"preferred_username":"alice","id":"60f65308-3510-40ca-83f0-e9c0151cc680","sub":"60f65308-3510-40ca-83f0-e9c0151cc680"}
```

The plugin also sets the `ngx.ctx.authenticated_credential` variable, which can be using in other Kong plugins:

```lua
ngx.ctx.authenticated_credential = {
    id = "60f65308-3510-40ca-83f0-e9c0151cc680",   -- sub field from Userinfo
    username = "alice"                             -- preferred_username from Userinfo
}
```

For successfully authenticated request, possible (anonymous) consumer identity set by higher priority plugin is cleared as part of setting the credentials.

The plugin will try to retrieve the user's groups from a field in the token (default `groups`) and set `kong.ctx.shared.authenticated_groups` so that Kong authorization plugins can make decisions based on the user's group membership.

## Dependencies

**kong-oidc** depends on the following package:

- [`lua-resty-openidc`](https://github.com/zmartzone/lua-resty-openidc/) (version >= 1.7.6 is required for Kong 3.x compatibility)

## Installation
 
 1. Install the plugin via `luarocks`:
 
    ```bash
    luarocks install kong-openidconnect-code-flow-v3
    ```
 
 2. Enable the plugin:
 
    **Option A: kong.conf**
    ```properties
    plugins = bundled,oidc
    ```
 
    **Option B: Docker / Env Var**
    ```bash
    KONG_PLUGINS=bundled,oidc
    ```
 
 ### Kong 3.9+ Configuration (Critical)
 
 Due to `lua-resty-session` v4+ changes, you **must** inject specific Nginx variables.
 
 1. Create a file named `nginx_oidc_variables.conf` with the following content:
    ```nginx
    set $session_secret 'your-32-byte-base64-secret';
    ```
    *(Other variables like `session_cookie_samesite` can be configured directly in the Plugin parameters)*
 
 2. Inject it into Kong configuration:
 
    **Option A: kong.conf**
    ```properties
    nginx_proxy_include = /path/to/nginx_oidc_variables.conf
    ```
 
    **Option B: Docker / Env Var**
    ```bash
    KONG_NGINX_PROXY_INCLUDE=/path/to/nginx_oidc_variables.conf
    ```
 
 ## Usage
| `profile` | Typically claims like `name`, `family_name`, `given_name`, `middle_name`, `preferred_username`, `nickname`, `picture` and `updated_at` |
| `email`   | `email` and `email_verified` (_boolean_) indicating if the email address has been verified by the user                                 |

_Note that the `openid` scope is a mandatory designator scope._

#### Description of the standard claims

| Claim                | Type           | Description                                                                                                                                                 |
| -------------------- | -------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `iss`                | URI            | The Uniform Resource Identifier uniquely identifying the OpenID Connect Provider (_OP_)                                                                     |
| `aud`                | string / array | The intended audiences. For ID tokens, the identity token is one or more clients. For Access tokens, the audience is typically one or more Resource Servers |
| `nbf`                | integer        | _Not before_ timestamp in Unix Epoch time\*. May be omitted or set to 0 to indicate that the audience can disregard the claim                               |
| `exp`                | integer        | _Expires_ timestamp in Unix Epoch time\*                                                                                                                    |
| `name`               | string         | Preferred display name. Ex. `John Doe`                                                                                                                      |
| `family_name`        | string         | Last name. Ex. `Doe`                                                                                                                                        |
| `given_name`         | string         | First name. Ex. `John`                                                                                                                                      |
| `middle_name`        | string         | Middle name. Ex. `Donald`                                                                                                                                   |
| `nickname`           | string         | Nick name. Ex. `Johnny`                                                                                                                                     |
| `preferred_username` | string         | Preferred user name. Ex. `johdoe`                                                                                                                           |
| `picture`            | base64         | A Base-64 encoded picture (typically PNG or JPEG) of the subject                                                                                            |
| `updated_at`         | integer        | A timestamp in Unix Epoch time\*                                                                                                                            |

`*` (Seconds since January 1st 1970).

### Passing the Access token as a normal Bearer token

To pass the access token to the upstream server as a normal Bearer token, configure the plugin as follows:

| Key                                    | Value           |
| -------------------------------------- | --------------- |
| `config.access_token_header_name`      | `Authorization` |
| `config.access_token_header_as_bearer` | `yes`           |
 
 ### Performance & Caching (Recommended)
 To avoid fetching the Discovery URL and JWKS on every request (which causes performance issues and "cannot use cached JWKS" warnings), define a shared dictionary in your `kong.conf`:
 
 ```properties
 nginx_http_lua_shared_dict = discovery 1m
 ```
 *(Or via environment variable: `KONG_NGINX_HTTP_LUA_SHARED_DICT=discovery 1m`)*

### Troubleshooting
 
 #### Session not found / Infinite Redirect Loop
 If you are testing on **localhost** or via **HTTP** (not HTTPS), modern browsers may reject the session cookie if `SameSite=None`.
 *   **Fix**: Set `config.session_cookie_samesite="Lax"` and `config.session_cookie_secure=false`.
 *   **Note**: For production (HTTPS), standard `SameSite=None; Secure=true` is recommended.
 
 #### Error: "variable 'session_secret' not found for writing"
 This confirms you are using Kong 3.9+ with `lua-resty-session` v4.
 *   **Fix**: You **MUST** inject the Nginx variables as described in the [Installation](#installation) section using `KONG_NGINX_PROXY_INCLUDE`.
 
 ## Development

### Running Unit Tests

To run unit tests, run the following command:

```shell
./bin/run-unit-tests.sh
```

This may take a while for the first run, as the docker image will need to be built, but subsequent runs will be quick.

### Building the Integration Test Environment

To build the integration environment (Kong with the oidc plugin enabled, and Keycloak as the OIDC Provider), you will first need to find your computer's IP, and assign that to the environment variable `IP`. Finally, you will run the `./bin/build-env.sh` command. Here's an example:

```shell
export IP=192.168.0.1
./bin/build-env.sh
```

To tear the environment down:

```shell
./bin/teardown-env.sh
```
