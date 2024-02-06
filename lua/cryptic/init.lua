-- local dump = require('kmobic33/utils').dump
local Job = require 'plenary.job'

print "CRYPTIIIC"

M = {}

function M.setup(opts)
  -- setup function is a convention for plugins in lua neovim
end

local function read_pre_hook()
  local current_buf = vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(current_buf)

  if ends_with(filename, ".cpt") then
    local decrypted_text = decrypt_file(filename, 0)
    if decrypted_text == nil then
      return
    end
    vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, decrypted_text)
  else
    -- if vim.env.ccrypt_pass == nil then
    --   L.input_ccrypt_pass()
    -- end
  end
end

--- Encrypts the current file path using the selected cryptographic algorithm.
--- @param path string
function M.encrypt(path)
  local cwd = vim.fn.getcwd()
  local password = vim.fn.input('Password > ')

  Job:new({
    -- command = 'ccrypt -e -K ' .. password .. ' < ' .. path .. ' > ./' .. path .. '.cpt',
    command = 'ccrypt',
    args = { '-e', '-K', password, '<', path, '>', './' .. path .. '.cpt' },
    cwd = cwd,
    -- env = { ['a'] = 'b' },
    on_exit = function(j, return_val)
      print(return_val)
      -- print(dump(j:result()))
    end,
  }):sync() -- or start()
end

--- Encrypts the current file path using the selected cryptographic algorithm.
--- @param path string
function M.decrypt(path)
  local cwd = vim.fn.getcwd()
  local password = vim.fn.input('Password > ')

  Job:new({
    command = 'ccrypt',
    args = { '-d', '-K', password, path },
    cwd = cwd,
    -- env = { ['a'] = 'b' },
    on_exit = function(j, return_val)
      print(return_val)
      -- print(dump(j:result()))
    end,
  }):sync() -- or start()
end

function M.sayhi()
  print("HIIIIIIIIIIIIIIIIIIIIIIIIIII")
end

return M




--:lua require('kmobic33/cryptic').encrypt('holis.txt')
--:lua require('kmobic33/cryptic').decrypt('holis.txt.cpt')

