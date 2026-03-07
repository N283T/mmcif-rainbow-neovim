# mmcif-rainbow.nvim

Rainbow column highlighting for mmCIF (Macromolecular Crystallographic Information File) files in Neovim.

A Neovim port of [mmcif-rainbow-vscode](https://github.com/nagaet/mmcif-rainbow-vscode), using Lua parser and extmarks for accurate, performant highlighting.

<!-- TODO: Add screenshot -->

## Features

- Rainbow column highlighting (9 cycling colors + category color)
- Cursor column highlighting
- Category navigation (`:MmcifGoToCategory`) with Telescope support
- Configurable colors
- Automatic filetype detection for `.cif` and `.mmcif` files

## Requirements

- Neovim >= 0.9.0
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (optional, for enhanced category picker)

## Installation

### lazy.nvim

```lua
{
  'N283T/mmcif-rainbow-neovim',
  ft = { 'mmcif' },
  opts = {},
}
```

## Configuration

```lua
require("mmcif-rainbow").setup({
  colors = {
    category = "#4B69FF",
    rainbow = {
      "#E06C75", "#D19A66", "#E5C07B", "#98C379",
      "#56B6C2", "#528BFF", "#C678DD", "#BE5046", "#7F848E",
    },
  },
  cursor_column = true,
  max_file_size = 50 * 1024 * 1024, -- 50 MB
})
```

| Option | Default | Description |
|--------|---------|-------------|
| `colors.category` | `"#4B69FF"` | Highlight color for `_category.item` names |
| `colors.rainbow` | 9 colors | Cycle of colors assigned to data columns |
| `cursor_column` | `true` | Highlight the column under the cursor |
| `max_file_size` | `52428800` | Skip highlighting for files larger than this (bytes) |

## Commands

| Command | Description |
|---------|-------------|
| `:MmcifGoToCategory` | Jump to a category definition by name |

When Telescope is available, the picker uses a Telescope dropdown. Otherwise it falls back to `vim.ui.select`.

## Highlight Groups

The following highlight groups can be overridden by colorscheme authors:

| Group | Description |
|-------|-------------|
| `MmcifRainbow1` | Category prefix color (fixed) |
| `MmcifRainbow2` - `MmcifRainbow10` | Cycling rainbow column colors |
| `MmcifCursorColumn` | Cursor column background |

## Credits

- [mmcif-rainbow-vscode](https://github.com/nagaet/mmcif-rainbow-vscode) -- the original VSCode extension this plugin is ported from

## License

MIT
