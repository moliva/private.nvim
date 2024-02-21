local M = {}

local cache = {}

--- Execute a given closure with the password for the given path
---@param path string Path of the file to be encrypted/decrypted
---@param exec function function(password: string): table, boolean
---@return table result, boolean success Table and boolean value
function M.with_password(path, exec)
  local cached_password = cache[path]

  local password
  if cached_password ~= nil then
    password = cached_password
  else
    password = vim.fn.input('Password > ')
  end

  local result, success = exec(password)

  if success then
    cache[path] = password
  end

  return result, success
end

return M
