std = "ngx_lua"
globals = {
    "kong",
    "ngx",
    -- Testing globals if needed
    "describe", "it", "setup", "teardown", "before_each", "after_each", "spy", "stub"
}

-- Ignore max line length (631)
ignore = { "631" }

-- Exclude spec files from some strict checks if needed
files["spec/**/*.lua"] = {
    std = "lua51+busted"
}
