local M = {}

function M.configure(_)
	-- No manual assignment of Nginx variables.
	-- We rely entirely on variables defined in the Nginx configuration injected via kong.conf.
end

return M
