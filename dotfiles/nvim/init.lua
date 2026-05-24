require("config.lazy")
require("config.options")

local user_lua = vim.fn.stdpath("config") .. "/user.lua"
if vim.fn.filereadable(user_lua) == 1 then
    dofile(user_lua)
end
