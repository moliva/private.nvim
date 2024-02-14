local actions = require('private.actions')
local path = require('private.path')

local M = {}

--- Triggers the action with the corresponding decryption algorithm for the current buffer file.
--- @return boolean result Representing whether the operation was a success or not
function M.encrypt_current_file()
  return actions.encrypt(path.get_current_path)
end

--- Triggers the action with the corresponding decryption algorithm prompting the user for the file path.
--- @return boolean result Representing whether the operation was a success or not
function M.encrypt_path()
  return actions.encrypt(path.prompt_path)
end

--- Triggers the action with the corresponding encryption algorithm for the current buffer file.
--- @return boolean result Representing whether the operation was a success or not
function M.decrypt_current_file()
  return actions.decrypt(path.get_current_path)
end

--- Asks for input for the file to be decrypted and triggers the action with the corresponding encryption algorithm.
function M.decrypt_path()
  return actions.decrypt(path.prompt_path)
end

return M
