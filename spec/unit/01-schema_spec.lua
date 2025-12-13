local mock_helper = require("spec.unit.mock_helper")
mock_helper.mock_kong_environment()

local schema = require("kong.plugins.oidc.schema")

describe("Schema", function()
	it("can be required and inspected", function()
		-- Without full Kong PDK validator, we essentially test that the module loads
		-- and definition table structure exists
		assert.truthy(schema)
		assert.truthy(schema.fields)
		assert.are.equal("kong-oidc", schema.name)
	end)

	it("contains redis configuration fields", function()
		local has_redis = false
		for _, field in ipairs(schema.fields) do
			if field.config then
				for _, config_field in ipairs(field.config) do
					if config_field.session_redis_host then
						has_redis = true
					end
				end
			end
		end
		-- Note: Schema structure in Kong 3.x is complex (nested fields/config),
		-- meaningful assertions depend on understanding 'kong.db.schema' format.
		-- For unit testing logic mostly resides in handler/utils, schema is declarative.
		assert.truthy(has_redis)
	end)
end)
