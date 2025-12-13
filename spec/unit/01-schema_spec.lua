local PLUGIN_NAME = "oidc"
local schema_def = require("kong.plugins." .. PLUGIN_NAME .. ".schema")
local v = require("spec.helpers").validate_plugin_config_schema

describe("Plugin: " .. PLUGIN_NAME .. " (Schema)", function()

  it("validates default config", function()
    local config = {}
    local ok, _, err = v(config, schema_def)
    assert.truthy(ok)
    assert.is_nil(err)
  end)

  it("accepts redis configuration", function()
    local config = {
      client_id = "test-client",
      client_secret = "test-secret",
      discovery = "https://issuer/.well-known/openid-configuration",
      session_storage = "redis",
      session_redis_host = "192.168.56.11",
      session_redis_port = 6379
    }
    local ok, _, err = v(config, schema_def)
    assert.truthy(ok)
    assert.is_nil(err)
  end)

end)
