local Job = require('plenary.job')

require('private.string') -- loads the string:ends_with and string:get_file_extension functions
local with_password = require('private.cache').with_password

local ENCRYPTION_SUFFIX = ".cpt"

--- Encrypts the current file path using the selected cryptographic algorithm.
--- @param path string Path for the file to be encrypted
--- @param suffix string Suffix to be used for the resulting encrypted file (e.g. ".cpt")
--- @return table, boolean result Table with the result of the job and boolean representing whether the operation was a success or not
local function encrypt(path, suffix)
  local cwd = vim.fn.getcwd()

  local path_unsuffixed
  if suffix == "" then
    path_unsuffixed = path:sub(1, - #ENCRYPTION_SUFFIX - 1)
  elseif suffix == ENCRYPTION_SUFFIX then
    path_unsuffixed = path
  end
  if path:sub(1, 1) ~= "/" then
    path_unsuffixed = cwd .. "/" .. path_unsuffixed
  end

  local result, success = with_password(path_unsuffixed, function(password)
    local result, code = Job:new({
      command = 'ccrypt',
      args = { '-e', '-S', suffix, '-K', password, path },
      cwd = cwd,
    }):sync()

    return result, code == 0
  end)

  return result, success
end


local M = {}

--- Encrypts the current file path using the selected cryptographic algorithm.
--- @param path string Path for the file to be encrypted
--- @param opts EncryptionOptions Options to be passed for encryption
--- @return boolean result Representing whether the operation was a success or not
function M.encrypt(path, opts)
  local suffix = ENCRYPTION_SUFFIX

  if opts.in_place then
    suffix = ""
  end

  local _, result = encrypt(path, suffix)

  return result
end

--- Decrypts the current file path using the selected cryptographic algorithm.
--- @param path string Path for the file to be decrypted
--- @param opts DecryptionOptions Options to be passed for decryption
--- @return table, boolean Table with the result of the job and boolean representing whether the operation was a success or not
function M.decrypt(path, opts)
  local persist_changes = opts.persist_changes or false

  local cwd = vim.fn.getcwd()

  local path_unsuffixed = path:sub(1, - #ENCRYPTION_SUFFIX - 1)
  if path:sub(1, 1) ~= "/" then
    path_unsuffixed = cwd .. "/" .. path_unsuffixed
  end

  local result, success = with_password(path_unsuffixed, function(password)
    local args = { '-d', '-K', password, path }
    if not persist_changes then
      -- if changes should not be persisted, add the cat parameter after the decrypt one (i.e. '-d')
      table.insert(args, 2, '-c')
    end

    local result, code = Job:new({
      command = 'ccrypt',
      args = args,
      cwd = cwd,
    }):sync()

    return result, code == 0
  end)

  return result, success
end

return M
