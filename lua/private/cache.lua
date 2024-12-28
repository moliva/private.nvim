local M = {}

local cache = {}

--- Execute a given closure with the password for the given path
---@param path string Path of the file to be encrypted/decrypted
---@param cached boolean Whether to use cached password for encryption
---@param exec function function(password: string): table, boolean
---@return table result, boolean success Table and boolean value
function M.with_password(path, cached, exec)
  local cached_password = cached and cache[path] or nil

  local password
  if cached_password ~= nil then
    password = cached_password
  else
    password = vim.fn.input("Password > ")
  end

  local result, success = exec(password)

  if success then
    -- if success, cache password and return result
    cache[path] = password

    return result, success
  else
    -- if cached password fails, remove from cache and try with input
    cache[path] = nil

    return M.with_password(path, cached, exec)
  end
end

return M
