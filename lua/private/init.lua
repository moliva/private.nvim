local Job = require 'plenary.job'

--- Determines if the current string ends with the paramater string given
--- @param ending string
--- @return boolean
function string:ends_with(ending)
  return ending == "" or self:sub(- #ending) == ending
end

local M = {}

local function read_pre_hook()
  local current_buf = vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(current_buf)

  if filename:ends_with(".cpt") then
    local decrypted_text, success = M.decrypt(filename, false)
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
  local password = vim.fn.input('Password > ')

  local result, code = Job:new({
    command = 'ccrypt',
    args = { '-e', '-S', suffix, '-K', password, path },
    cwd = cwd,
  }):sync()

  return result, code == 0
end

local function write_post_hook()
  local current_buf = vim.api.nvim_get_current_buf()
  local filename_path = vim.api.nvim_buf_get_name(current_buf)

  local buf_text_before_encrypt = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
  local _, success = encrypt(filename_path, "")

  if not success then
    print("Encryption failed!")
  end

  vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, buf_text_before_encrypt)
end

--- Sets up the current plugin with the given opts.
--- @param opts table
function M.setup(opts)
  local cryptic_group = vim.api.nvim_create_augroup("Cryptic", { clear = true })

  vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = "*.cpt",
    callback = read_pre_hook,
    group = cryptic_group,
  })

  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*.cpt",
    callback = write_post_hook,
    group = cryptic_group,
  })
end

--- Encrypts the current file path using the selected cryptographic algorithm.
--- @param path string Path for the file to be encrypted
--- @return boolean result Representing whether the operation was a success or not
function M.encrypt(path)
  local suffix = ".cpt"

  if path:ends_with(suffix) then
    print("path '" .. path "' is already encrypted, no operation will be applied")
    return false
  end

  local _, result = encrypt(path, suffix)

  return result
end

--- Decrypts the current file path using the selected cryptographic algorithm.
--- @param path string Path for the file to be decrypted
--- @param persist_changes boolean Persists changes to disk when true
--- @return table, boolean Table with the result of the job and boolean representing whether the operation was a success or not
function M.decrypt(path, persist_changes)
  persist_changes = persist_changes or false

  local cwd = vim.fn.getcwd()
  local password = vim.fn.input('Password > ')

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
end

return M
