require('private.string') -- loads the string:ends_with function

local ccrypt = require('private.strategies.ccrypt')

-- TODO - document strategy module interfaces - moliva - 2024/02/21
local strategies = {
  cpt = ccrypt,
  -- b64 = base64,
  b64 = 1,
}

local M = {}

local function read_hook()
  local current_buf = vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(current_buf)

  local file_extension = filename:get_file_extension()
  local strategy = strategies[file_extension]

  if strategy then
    local decrypted_text, success = strategy.decrypt(filename, { persist_changes = false })
    if not success then
      print("Wrong password!")
      return
    end

    vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, decrypted_text)
  end
end


local function write_hook()
  local current_buf = vim.api.nvim_get_current_buf()
  local filename_path = vim.api.nvim_buf_get_name(current_buf)

  local buf_text_before_encrypt = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)

  local file_extension = filename_path:get_file_extension()
  local strategy = strategies[file_extension]

  local success = strategy.encrypt(filename_path, { in_place = true, force = true })

  if not success then
    print("Encryption failed!")
  end

  vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, buf_text_before_encrypt)
end

--- @class SetupOptions
--- @field encryption_strategy string Defaults to `ccrypt`
--- @field setup_bindings boolean Defaults to `true`

--- @name SetupOptions
local default_opts = {
  encryption_strategy = 'ccrypt',
  setup_bindings = true,
}

--- Sets up the current plugin with the given opts.
--- @param opts SetupOptions
function M.setup(opts)
  opts = opts or {}
  opts = vim.tbl_extend("force", default_opts, opts)
  -- print(vim.inspect(opts))

  if opts.encryption_strategy ~= 'ccrypt' then
    print("encryption strategy '" .. opts.encryption_strategy .. "' not yet supported, using 'ccrypt' instead!")
  end

  if opts.setup_bindings then
    local private_group = vim.api.nvim_create_augroup("private.nvim", { clear = true })

    vim.api.nvim_create_autocmd("BufReadPost", {
      -- TODO - extend pattern to all strategies - moliva - 2024/02/21
      pattern = "*.cpt",
      callback = read_hook,
      group = private_group,
    })

    vim.api.nvim_create_autocmd("BufWritePost", {
      -- TODO - extend pattern to all strategies - moliva - 2024/02/21
      pattern = "*.cpt",
      callback = write_hook,
      group = private_group,
    })
  end
end

--- @class EncryptionOptions
--- @field strategy string encryption algorithm to use (or default if `nil``)
--- @field in_place boolean Persists changes in same file instead of new one with given suffix
--- @field force boolean Forces file to be encrypted even if it already has the encryption suffix

--- Encrypts the current file path using the selected cryptographic algorithm.
--- @param path string Path for the file to be encrypted
--- @param opts EncryptionOptions Options to be passed for encryption
--- @return boolean result Representing whether the operation was a success or not
function M.encrypt(path, opts)
  return strategies.cpt.encrypt(path, opts)
end

--- @class DecryptionOptions
--- @field strategy string encryption algorithm to use (or autodetect if `nil``)
--- @field persist_changes boolean Persists changes to disk when true

--- Decrypts the current file path using the selected cryptographic algorithm.
--- @param path string Path for the file to be decrypted
--- @param opts DecryptionOptions Options to be passed for decryption
--- @return table, boolean Table with the result of the job and boolean representing whether the operation was a success or not
function M.decrypt(path, opts)
  -- TODO - try to detect encryption used based on metadta/extension - moliva - 2024/02/16
  return strategies.cpt.decrypt(path, opts)
end

return M
