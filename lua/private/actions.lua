local M = {}

local function with_file_path(action_desc, action, get_path)
  local path = get_path()
  if path == "" then
    -- user cancelled the input/invalid path, skip the action
    return false
  end

  local result = action(path)

  if not result then
    print("error while " .. action_desc .. " file '" .. path .. "'")
  end

  return result
end

--- Triggers the action with the corresponding encryption algorithm for the path strategy given.
--- @param get_path function function(): string Function that retrieves path for the file to encrypt
--- @return boolean result Representing whether the operation was a success or not
function M.encrypt(get_path)
  return with_file_path("encrypting", function(path)
    return require("private.hooks").encrypt(path)
  end, get_path)
end

--- Triggers the decryption with the corresponding encryption algorithm for a given path strategy.
--- @param get_path function function(): string Function that retrieves path for the file to encrypt
--- @return boolean result Representing whether the operation was a success or not
function M.decrypt(get_path)
  return with_file_path("decrypting", function(path)
    local _, result = require("private.hooks").decrypt(path, { persist_changes = true })
    return result
  end, get_path)
end

return M
