# private.nvim

A simple plugin for encrypting/decrypting files from your favorite editor, originally based on [ccryptor.nvim](https://github.com/kurotych/ccryptor.nvim).

## Features

- Encrypt/decrypt files using an existing encryption algorithm
- Automatically open/edit encrypted files from Neovim based on their file extensions
- [WIP] Introduce new encryption modules

## Requirements

- Plenary
- The encryption tool of your liking (currently supported 'ccrypt' and 'base64') installed in your machine

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
    "moliva/private.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    lazy = false,
    config = function()
      require("private").setup()
    end,
    keys = {
      { '<leader>iep', function() require('private.predef_actions').encrypt_path() end,         desc = "encrypt file by path" },
      { '<leader>iec', function() require('private.predef_actions').encrypt_current_file() end, desc = "encrypt current file" },
      { '<leader>idp', function() require('private.predef_actions').decrypt_path() end,         desc = "decrypt file by path" },
      { '<leader>idc', function() require('private.predef_actions').decrypt_current_file() end, desc = "decrypt current file" },
    }
```

## Configuration

Default setup opts.
```lua
{
  encryption_strategy = require('private.strategies.ccypt'), -- use ccrypt as default
  setup_bindings = true, -- sets up autocommands for all known modules to be decrypted on open and encrypted on save
}
```

