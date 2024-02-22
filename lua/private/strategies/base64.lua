local Job = require('plenary.job')

require('private.string') -- loads the string:ends_with and string:get_file_extension functions

local ENCRYPTION_SUFFIX = ".b64"

local M = {}

--- Encrypts the current file path using the selected cryptographic algorithm.
--- @param path string Path for the file to be encrypted
--- @param opts EncryptionOptions Options to be passed for encryption
--- @return boolean result Representing whether the operation was a success or not
function M.encrypt(path, opts)
  local suffix = ENCRYPTION_SUFFIX

  if opts.in_place then
    suffix = ".swp" -- temporary swap file
  end

  local suffixed_path = path .. ENCRYPTION_SUFFIX

  local cwd = vim.fn.getcwd()

  local _, code = Job:new({
    command = 'base64',
    args = { '-i', path, '-o', suffixed_path },
    cwd = cwd,
  }):sync()

  local success = code == 0

  -- if the encrypted file above was successful  delete the old file
  if success then
    local _, rm_code = Job:new({
      command = 'rm',
      args = { path },
      cwd = cwd,
    }):sync()

    if rm_code ~= 0 then
      print('unable to delete the clear text file "' .. path .. "'")
    end

    -- also if the encryption was in place, we need to move the swap file to the output (original) one, since base64 doesn't work properly in this cases
    if opts.in_place then
      local _, mv_code = Job:new({
        command = 'mv',
        args = { suffixed_path, path },
        cwd = cwd,
      }):sync()
    end
  end

  return success
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

  local args = { '-d', '-i', path }
  if persist_changes then
    -- if changes should be persisted, add the output file parameter
    table.insert(args, '-o')
    table.insert(args, path_unsuffixed)
  end

  local result, code = Job:new({
    command = 'base64',
    args = args,
    cwd = cwd,
  }):sync()

  local success = code == 0

  -- if decryption was successful and we persisted the changes, we will remove the encrypted file
  if success and persist_changes then
    local _, rm_code = Job:new({
      command = 'rm',
      args = { path },
      cwd = cwd,
    }):sync()

    if rm_code ~= 0 then
      print("failed to remove encrypted file '" .. path .. "'")
    end
  end

  return result, success
end

return M
