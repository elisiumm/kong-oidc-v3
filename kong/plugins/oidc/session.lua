local M = {}

function M.configure(config)
	if config.session_secret then
		local decoded_session_secret = ngx.decode_base64(config.session_secret)
		if not decoded_session_secret then
			kong.log.warn("Invalid plugin configuration, session secret could not be decoded")
			-- Fallback to using the secret as-is if decoding fails (it might be raw string)
			decoded_session_secret = config.session_secret
		end

		if #decoded_session_secret ~= 32 then
			kong.log.err(
				"Session secret must be exactly 32 bytes long for AES-256 encryption. Current length: "
					.. #decoded_session_secret
			)
		end

		ngx.var.session_secret = decoded_session_secret
	end

	-- Configure other session variables if they are exposed in nginx
	if config.session_storage then
		ngx.var.session_storage = config.session_storage
	end
	if config.session_name then
		ngx.var.session_name = config.session_name
	end
	if config.session_cookie_samesite then
		ngx.var.session_cookie_samesite = config.session_cookie_samesite
	end
	if config.session_cookie_secure ~= nil then
		ngx.var.session_cookie_secure = tostring(config.session_cookie_secure)
	end
	if config.session_cookie_httponly ~= nil then
		ngx.var.session_cookie_httponly = tostring(config.session_cookie_httponly)
	end
end

return M
