-- Helper to mock Kong dependencies for unit testing
local M = {}

function M.mock_kong_environment()
	-- Mock ngx global
	_G.ngx = {
		log = function(_) end,
		DEBUG = "debug",
		ERR = "err",
		WARN = "warn",
		INFO = "info",
		req = {
			get_headers = function()
				return {}
			end,
			get_uri_args = function()
				return {}
			end,
		},
		var = {
			request_uri = "/",
			uri = "/",
		},
		header = {},
		status = 200,
		say = function(_) end,
		exit = function(_) end,
		redirect = function(_) end,
		encode_base64 = function(s)
			return s
		end,
		decode_base64 = function(s)
			return s
		end,
	}

	-- Mock kong global
	_G.kong = {
		log = {
			err = function(_) end,
			warn = function(_) end,
			debug = function(_) end,
		},
		client = {
			get_credential = function()
				return nil
			end,
			authenticate = function() end,
		},
		service = {
			request = {
				set_header = function(_) end,
				clear_header = function(_) end,
			},
		},
		ctx = {
			shared = {},
		},
		response = {
			error = function(_) end,
		},
		constants = {
			HEADERS = {
				CONSUMER_ID = "X-Consumer-ID",
				CONSUMER_CUSTOM_ID = "X-Consumer-Custom-ID",
				CONSUMER_USERNAME = "X-Consumer-Username",
				CREDENTIAL_IDENTIFIER = "X-Credential-Identifier",
				ANONYMOUS = "X-Anonymous-Consumer",
			},
		},
	}

	-- Mock kong.db.schema.typedefs
	package.loaded["kong.db.schema.typedefs"] = {
		url = function()
			return { type = "string" }
		end,
		host = { type = "string" },
		port = { type = "integer" },
	}

	-- Mock kong.constants
	package.loaded["kong.constants"] = _G.kong.constants

	-- Mock resty.openidc (avoid actual network calls)
	package.loaded["resty.openidc"] = {
		authenticate = function(_)
			return nil, "mocked error"
		end,
		introspect = function(_)
			return nil, "mocked error"
		end,
		jwt_verify = function(_)
			return nil, "mocked error"
		end,
		bearer_jwt_verify = function(_)
			return nil, "mocked error"
		end,
	}
end

return M
