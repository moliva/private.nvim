local M = {}

local modules = {
  require('private.strategies.ccrypt'),
  require('private.strategies.base64'),
}

-- transform into a look up table
local strategies = {}
for _, s in ipairs(modules) do
  strategies[s.file_extension] = s
end

M.strategies = strategies

return M
