require("private.string") -- loads the string:ends_with and string:get_file_extension functions
local hooks = require("private.hooks")

local STRATEGIES = require("private.strategies").strategies

local M = {}

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
  opts = vim.tbl_extend("force", hooks.DEFAULT_SETUP_OPTS, opts)

  if opts.encryption_strategy == nil then
    print("setting encryption strategy to default")
    opts.encryption_strategy = hooks.DEFAULT_SETUP_OPTS.encryption_strategy
  elseif not tbl_contains_value(STRATEGIES, opts.encryption_strategy) then
    -- TODO - make this restriction more flexible to allow user modules for encrypting - moliva - 2024/02/22
    print("encryption strategy used not yet supported, using 'ccrypt' instead!")
    opts.encryption_strategy = hooks.DEFAULT_SETUP_OPTS.encryption_strategy
  end

  hooks.DEFAULT_ENCRYPTION_OPTS.strategy = opts.encryption_strategy

  if opts.setup_bindings then
    local private_group = vim.api.nvim_create_augroup("private.nvim", { clear = true })
    local all_patterns = vim.tbl_map(function(extension)
      return "*." .. extension
    end, vim.tbl_keys(STRATEGIES))

    vim.api.nvim_create_autocmd("BufReadPost", {
      pattern = all_patterns,
      callback = require("private.hooks").read_hook,
      group = private_group,
    })

    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = all_patterns,
      callback = require("private.hooks").write_hook,
      group = private_group,
    })
  end
end

return M
