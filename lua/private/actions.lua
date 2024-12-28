local M = {}

local s = require("private.string")

---@param action_desc string
---@param get_path function () => string
local function with_file_path(action_desc, action, get_path)
  local path = get_path()
  if path == "" then
    -- user cancelled the input/invalid path, skip the action
    return false
  end

  local result = action(path)

  if not result then
    vim.print("error while " .. action_desc .. " file '" .. path .. "'")
  end

  return result
end

--- Triggers the action with the corresponding encryption algorithm for the path strategy given.
--- @param get_path function function(): string Function that retrieves path for the file to encrypt
--- @return boolean result Representing whether the operation was a success or not
function M.encrypt(get_path)
  return with_file_path("encrypting", function(path)
    local result, encrypted_path = require("private.hooks").encrypt(path)

    if result then
      local encrypted_filename = s.get_filename(encrypted_path)
      vim.notify("Successfully created " .. encrypted_filename)

      local current_path = vim.fn.expand("%:p")

      if current_path == path then
        vim.cmd("bdelete!")
        vim.cmd("edit " .. encrypted_path)
      end
    else
      local filename = s.get_filename(path)
      vim.notify("Encryption failed for " .. filename, vim.log_levels.ERROR)
    end

    return result
  end, get_path)
end

--- Triggers the decryption with the corresponding encryption algorithm for a given path strategy.
--- @param get_path function function(): string Function that retrieves path for the file to encrypt
--- @return boolean result Representing whether the operation was a success or not
function M.decrypt(get_path)
  return with_file_path("decrypting", function(path)
    local _, result = require("private.hooks").decrypt(path, { persist_changes = true })

    if result then
      -- TODO - return and notify with new path - moliva - 2024/12/28
      -- local decrypted_filename = s.get_filename(decrypted_path)
      -- vim.notify("Successfully decrypted " .. decrypted_filename)
      vim.notify("Successfully decrypted")

      local current_path = vim.fn.expand("%:p")

      if current_path == path then
        vim.cmd("bdelete!")
        -- vim.cmd("edit " .. decrypted_path)
      end
    else
      local filename = s.get_filename(path)
      vim.notify("Decryption failed for " .. filename, vim.log_levels.ERROR)
    end

    return result
  end, get_path)
end

return M
