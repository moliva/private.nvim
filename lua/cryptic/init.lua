local Job = require 'plenary.job'

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

function M.setup(opts)
  local cryptic_group = vim.api.nvim_create_augroup("Cryptic", { clear = true })

  vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = "*",
    callback = read_pre_hook,
    group = cryptic_group,
  })
end

--- Encrypts the current file path using the selected cryptographic algorithm.
--- @param path string
--- @return table, boolean
function M.encrypt(path)
  local cwd = vim.fn.getcwd()
  local password = vim.fn.input('Password > ')

  Job:new({
    -- command = 'ccrypt -e -K ' .. password .. ' < ' .. path .. ' > ./' .. path .. '.cpt',
    command = 'ccrypt',
    args = { '-e', '-K', password, path },
    cwd = cwd,
    -- env = { ['a'] = 'b' },
    on_exit = function(j, return_val)
      print(return_val)
    end,
  }):sync() -- or start()
end

--- Encrypts the current file path using the selected cryptographic algorithm.
--- @param path string
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
