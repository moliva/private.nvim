local M = {}

local STRATEGIES = require("private.strategies").strategies

--- @type SetupOptions
M.DEFAULT_SETUP_OPTS = {
  encryption_strategy = STRATEGIES.cpt, -- use ccrypt as default
  setup_bindings = true,
}

--- @type EncryptionOptions
M.DEFAULT_ENCRYPTION_OPTS = {
  strategy = M.DEFAULT_SETUP_OPTS.encryption_strategy,
  in_place = false,
  force = false,
}

--- @type DecryptionOptions
M.DEFAULT_DECRYPTION_OPTS = {
  strategy = M.DEFAULT_SETUP_OPTS.encryption_strategy,
  persist_changes = false,
}

local function validate_suffix(path, suffix, force)
  if path:ends_with(suffix) and not force then
    print("path '" .. path .. "' is already encrypted, no operation will be applied")
    return false
  end

  return true
end

function M.read_hook()
  local current_buf = vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(current_buf)

  local file_extension = filename:get_file_extension()
  local strategy = STRATEGIES[file_extension]

  if strategy then
    local decrypted_text, success = M.decrypt(filename, { strategy = strategy, persist_changes = false })
    if not success then
      print("Wrong password!")
      return
    end

    vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, decrypted_text)

    local nfilename = filename:sub(1, #filename - #file_extension - 1) -- account for the `.`
    local nfile_extension = nfilename:get_file_extension()
    -- print(nfilename, nfile_extension)
    local filetype, _ = vim.filetype.match({ filename = nfilename })

    vim.bo[current_buf].filetype = filetype
  end
end

function M.write_hook()
  local current_buf = vim.api.nvim_get_current_buf()
  local filename_path = vim.api.nvim_buf_get_name(current_buf)

  local buf_text_before_encrypt = vim.api.nvim_buf_get_lines(current_buf, 0, -1, false)

  local file_extension = filename_path:get_file_extension()
  local strategy = STRATEGIES[file_extension]

  local success = M.encrypt(filename_path, { strategy = strategy, in_place = true, force = true })

  if not success then
    print("Encryption failed!")
  end

  vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, buf_text_before_encrypt)
end

--- Encrypts the current file path using the selected cryptographic algorithm.
--- @param path string Path for the file to be encrypted
--- @param opts EncryptionOptions|nil Options to be passed for encryption
--- @return boolean result Representing whether the operation was a success or not
function M.encrypt(path, opts)
  opts = opts or {}
  opts = vim.tbl_extend("force", M.DEFAULT_ENCRYPTION_OPTS, opts)

  local file_extension = path:get_file_extension()

  local strategy = opts.strategy or STRATEGIES[file_extension]
  if not strategy then
    print('cannot find a strategy for this extension "' .. file_extension('"'))
  end

  if not validate_suffix(path, strategy.file_extension, opts.force) then
    return false
  end

  return strategy.encrypt(path, opts)
end

--- Decrypts the current file path using the selected cryptographic algorithm.
--- @param path string Path for the file to be decrypted
--- @param opts DecryptionOptions|nil Options to be passed for decryption
--- @return table, boolean Table with the result of the job and boolean representing whether the operation was a success or not
function M.decrypt(path, opts)
  opts = opts or {}
  opts = vim.tbl_extend("force", M.DEFAULT_DECRYPTION_OPTS, opts)

  local file_extension = path:get_file_extension()

  local strategy = opts.strategy or STRATEGIES[file_extension]
  if not strategy then
    print('cannot find a strategy for this extension "' .. file_extension('"'))
  end

  return strategy.decrypt(path, opts)
end

return M
