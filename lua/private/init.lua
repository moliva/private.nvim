local Job = require 'plenary.job'

--- Determines if the current string ends with the paramater string given
---@param ending string
---@return boolean
function string:ends_with(ending)
  return ending == "" or self:sub(- #ending) == ending
end

local M = {}

local function read_pre_hook()
  local current_buf = vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(current_buf)

  if filename:ends_with(".cpt") then
    local decrypted_text, success = M.decrypt(filename)
    if not success then
      print("Wrong password!")
      return
    end

    vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, decrypted_text)
  end
end

local function write_post_hook()
  local current_buf = vim.api.nvim_get_current_buf()
  local filename_path = vim.api.nvim_buf_get_name(current_buf)

  local buf_text_before_encrypt = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)
  local result, success = M.encrypt(filename_path, "")

  if not success then
    print("Encryption failed!")
  end

  vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, buf_text_before_encrypt)
end

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
--- @param suffix string Suffix to be used for the resulting encrypted file (e.g. ".cpt")
--- @return table, boolean Table with the result of the job and boolean representing whether the operation was a success or not
function M.encrypt(path, suffix)
  local cwd = vim.fn.getcwd()
  local password = vim.fn.input('Password > ')

  local result, code = Job:new({
    command = 'ccrypt',
    args = { '-e', '-S', suffix, '-K', password, path },
    cwd = cwd,
  }):sync() -- or start()

  return result, code == 0
end

--- Decrypts the current file path using the selected cryptographic algorithm.
--- @param path string Path for the file to be decrypted
--- @return table, boolean Table with the result of the job and boolean representing whether the operation was a success or not
function M.decrypt(path)
  local cwd = vim.fn.getcwd()
  local password = vim.fn.input('Password > ')

  local result, code = Job:new({
    command = 'ccrypt',
    args = { '-dc', '-K', password, path },
    cwd = cwd,
  }):sync() -- or start()

  if code == 0 then
    print(vim.inspect(result))
  end

  return result, code == 0
end

return M
