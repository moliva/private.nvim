local Job = require 'plenary.job'

local ENCRYPTION_SUFFIX = ".cpt"

--- Determines if the current string ends with the paramater string given
--- @param ending string
--- @return boolean
function string:ends_with(ending)
  return ending == "" or self:sub(- #ending) == ending
end

local M = {}

M.cache = {}

--- Execute a given closure with the password for the given path
---@param path string Path of the file to be encrypted/decrypted
---@param exec function function(password: string): table, boolean
---@return table result, boolean success Table and boolean value
local function with_password(path, exec)
  local cached_password = M.cache[path]

  local password
  if cached_password ~= nil then
    password = cached_password
  else
    password = vim.fn.input('Password > ')
  end

  local result, success = exec(password)

  if success then
    M.cache[path] = password
  end

  return result, success
end

local function read_hook()
  local current_buf = vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(current_buf)

  if filename:ends_with(".cpt") then
    local decrypted_text, success = M.decrypt(filename, { persist_changes = false })
    if not success then
      print("Wrong password!")
      return
    end

    vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, decrypted_text)
  end
end

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

local function write_hook()
  local current_buf = vim.api.nvim_get_current_buf()
  local filename_path = vim.api.nvim_buf_get_name(current_buf)

  local buf_text_before_encrypt = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
  local _, success = encrypt(filename_path, "")

  if not success then
    print("Encryption failed!")
  end

  vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, buf_text_before_encrypt)
end

--- @class SetupOptions

--- Sets up the current plugin with the given opts.
--- @param opts SetupOptions
function M.setup(opts)
  local private_group = vim.api.nvim_create_augroup("private.nvim", { clear = true })

  vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = "*.cpt",
    callback = read_hook,
    group = private_group,
  })

  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*.cpt",
    callback = write_hook,
    group = private_group,
  })
end

--- Encrypts the current file path using the selected cryptographic algorithm.
--- @param path string Path for the file to be encrypted
--- @return boolean result Representing whether the operation was a success or not
function M.encrypt(path)
  local suffix = ENCRYPTION_SUFFIX

  if path:ends_with(suffix) then
    print("path '" .. path "' is already encrypted, no operation will be applied")
    return false
  end

  local _, result = encrypt(path, suffix)

  return result
end

--- @class DecryptionOptions
--- @field persist_changes boolean Persists changes to disk when true

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
