local M = {}

--- Triggers the action with the corresponding decryption algorithm for the current buffer file.
--- @return boolean result Representing whether the operation was a success or not
function M.encrypt_current_file()
  local current_buf = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(current_buf)

  local result = require('private').encrypt(path)

  if not result then
    print("error while encrypting file '" .. path "'")
  end

  return result
end

--- Asks for input for the file to be encrypted and triggers the action with the corresponding encryption algorithm.
--- @return boolean result Representing whether the operation was a success or not
function M.encrypt()
  local path = vim.fn.input('Path to encrypt > ')
  if path == "" then
    -- user cancelled the input, skip the action
    return false
  end

  local result = require('private').encrypt(path)

  if not result then
    print("error while encrypting file '" .. path "'")
  end

  return result
end

--- Triggers the action with the corresponding encryption algorithm for the current buffer file.
--- @return boolean result Representing whether the operation was a success or not
function M.decrypt_current_file()
  local current_buf = vim.api.nvim_get_current_buf()
  local path = vim.api.nvim_buf_get_name(current_buf)

  local result = require('private').decrypt(path, true)

  if not result then
    print("error while decrypting file '" .. path "'")
  end

  return result
end

--- Asks for input for the file to be decrypted and triggers the action with the corresponding encryption algorithm.
--- @return boolean result Representing whether the operation was a success or not
function M.decrypt()
  local path = vim.fn.input('Path to decrypt > ')
  if path == "" then
    -- user cancelled the input, skip the action
    return false
  end

  local result = require('private').decrypt(path, true)

  if not result then
    print("error while decrypting file '" .. path "'")
  end

  return result
end

return M
