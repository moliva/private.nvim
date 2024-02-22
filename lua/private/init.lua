require('private.string') -- loads the string:ends_with and string:get_file_extension functions

local STRATEGIES = require('private.strategies').strategies

local M = {}

local function read_hook()
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
  end
end


local function write_hook()
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

--- @class EncryptionModule
--- @field encrypt function
--- @field decrypt function
--- @field file_extension string

--- @class SetupOptions
--- @field encryption_strategy EncryptionModule
--- @field setup_bindings boolean Defaults to `true`

--- @class DecryptionOptions
--- @field strategy EncryptionModule Encryption algorithm to use (or autodetect if `nil``)
--- @field persist_changes boolean Persists changes to disk when true

--- @class EncryptionOptions
--- @field strategy any Encryption algorithm to use (or default if `nil``)
--- @field in_place boolean Persists changes in same file instead of new one with given suffix
--- @field force boolean Forces file to be encrypted even if it already has the encryption suffix

--- @type SetupOptions
local DEFAULT_SETUP_OPTS = {
  encryption_strategy = STRATEGIES.cpt, -- use ccrypt as default
  setup_bindings = true,
}

--- @type EncryptionOptions
local DEFAULT_ENCRYPTION_OPTS = {
  strategy = DEFAULT_SETUP_OPTS.encryption_strategy,
  in_place = false,
  force = false,
}

--- @type DecryptionOptions
local DEFAULT_DECRYPTION_OPTS = {
  strategy = DEFAULT_SETUP_OPTS.encryption_strategy,
  persist_changes = false,
}

local function tbl_contains_value(table, value)
  for _, v in pairs(table) do
    if value == v then
      return true
    end
  end
  return false
end

--- Sets up the current plugin with the given opts.
--- @param opts SetupOptions
function M.setup(opts)
  opts = opts or {}
  opts = vim.tbl_extend("force", DEFAULT_SETUP_OPTS, opts)

  if opts.encryption_strategy == nil then
    print("setting encryption strategy to default")
    opts.encryption_strategy = DEFAULT_SETUP_OPTS.encryption_strategy
  elseif not tbl_contains_value(STRATEGIES, opts.encryption_strategy) then
    -- TODO - make this restriction more flexible to allow user modules for encrypting - moliva - 2024/02/22
    print("encryption strategy used not yet supported, using 'ccrypt' instead!")
    opts.encryption_strategy = DEFAULT_SETUP_OPTS.encryption_strategy
  end

  DEFAULT_ENCRYPTION_OPTS.strategy = opts.encryption_strategy

  if opts.setup_bindings then
    local private_group = vim.api.nvim_create_augroup("private.nvim", { clear = true })
    local all_patterns = vim.tbl_map(function(extension) return "*." .. extension end, vim.tbl_keys(STRATEGIES))

    vim.api.nvim_create_autocmd("BufReadPost", {
      pattern = all_patterns,
      callback = read_hook,
      group = private_group,
    })

    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = all_patterns,
      callback = write_hook,
      group = private_group,
    })
  end
end

local function validate_suffix(path, suffix, force)
  if path:ends_with(suffix) and not force then
    print("path '" .. path .. "' is already encrypted, no operation will be applied")
    return false
  end

  return true
end

--- Encrypts the current file path using the selected cryptographic algorithm.
--- @param path string Path for the file to be encrypted
--- @param opts EncryptionOptions Options to be passed for encryption
--- @return boolean result Representing whether the operation was a success or not
function M.encrypt(path, opts)
  opts                 = opts or {}
  opts                 = vim.tbl_extend("force", DEFAULT_ENCRYPTION_OPTS, opts)

  local file_extension = path:get_file_extension()

  local strategy       = opts.strategy or STRATEGIES[file_extension]
  if not strategy then
    print('cannot find a strategy for this extension "' .. file_extension '"')
  end

  if not validate_suffix(path, strategy.file_extension, opts.force) then
    return false
  end

  return strategy.encrypt(path, opts)
end

--- Decrypts the current file path using the selected cryptographic algorithm.
--- @param path string Path for the file to be decrypted
--- @param opts DecryptionOptions Options to be passed for decryption
--- @return table, boolean Table with the result of the job and boolean representing whether the operation was a success or not
function M.decrypt(path, opts)
  opts                 = opts or {}
  opts                 = vim.tbl_extend("force", DEFAULT_DECRYPTION_OPTS, opts)

  local file_extension = path:get_file_extension()

  local strategy       = opts.strategy or STRATEGIES[file_extension]
  if not strategy then
    print('cannot find a strategy for this extension "' .. file_extension '"')
  end

  return strategy.decrypt(path, opts)
end

return M
