# mmcif-rainbow.nvim

Rainbow column highlighting for mmCIF (Macromolecular Crystallographic Information File) files in Neovim.

A Neovim port of [mmcif-rainbow-vscode](https://github.com/nagaet/mmcif-rainbow-vscode), using Lua parser and extmarks for accurate, performant highlighting.

<!-- TODO: Add screenshot -->

## Features

- Rainbow column highlighting (9 cycling colors + category color)
- Cursor column highlighting
- Category navigation (`:MmcifGoToCategory`) with Telescope support
- Dictionary-backed hover tooltips (press `K` on categories, items, or values)
- AlphaFold/ModelCIF pLDDT confidence coloring (auto-detected)
- `:MmcifDownloadDictionary` command to download dictionary files
- Configurable colors
- Automatic filetype detection for `.cif` and `.mmcif` files

## Requirements

- Neovim >= 0.9.0
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (optional, for enhanced category picker)

## Installation

> **Note:** This plugin requires **Neovim** (not Vim). It uses Neovim-specific APIs (extmarks, `vim.system`, etc.).

### lazy.nvim

```lua
{
  'N283T/mmcif-rainbow-neovim',
  ft = { 'mmcif' },
  opts = {},
}
```

### packer.nvim

```lua
use {
  'N283T/mmcif-rainbow-neovim',
  config = function()
    require('mmcif-rainbow').setup()
  end,
}
```

### Others (vim-plug, mini.deps, rocks.nvim, etc.)

Any Neovim-compatible plugin manager works. For example with vim-plug:

```vim
Plug 'N283T/mmcif-rainbow-neovim'
```

```lua
-- After plugin is loaded
require('mmcif-rainbow').setup()
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
  dictionary = {
    enabled = true,       -- Enable hover tooltips (default: true)
    auto_download = false, -- Auto-download dictionary (default: false)
  },
  plddt = true,           -- pLDDT confidence coloring (default: true)
})
```

| Option | Default | Description |
|--------|---------|-------------|
| `colors.category` | `"#4B69FF"` | Highlight color for `_category.item` names |
| `colors.rainbow` | 9 colors | Cycle of colors assigned to data columns |
| `cursor_column` | `true` | Highlight the column under the cursor |
| `max_file_size` | `52428800` | Skip highlighting for files larger than this (bytes) |
| `dictionary.enabled` | `true` | Enable dictionary-backed hover tooltips |
| `dictionary.auto_download` | `false` | Auto-download dictionary on first use |
| `plddt` | `true` | Enable pLDDT confidence coloring for ModelCIF files |

## Commands

| Command | Description |
|---------|-------------|
| `:MmcifGoToCategory` | Jump to a category definition by name |
| `:MmcifDownloadDictionary` | Download dictionary files for hover documentation |

When Telescope is available, the picker uses a Telescope dropdown. Otherwise it falls back to `vim.ui.select`.

## Highlight Groups

The following highlight groups can be overridden by colorscheme authors:

| Group | Description |
|-------|-------------|
| `MmcifRainbow1` | Category prefix color (fixed) |
| `MmcifRainbow2` - `MmcifRainbow10` | Cycling rainbow column colors |
| `MmcifCursorColumn` | Cursor column background |
| `MmcifPlddtVeryHigh` | pLDDT > 90 (dark blue) |
| `MmcifPlddtHigh` | 70 < pLDDT <= 90 (light blue) |
| `MmcifPlddtLow` | 50 < pLDDT <= 70 (yellow) |
| `MmcifPlddtVeryLow` | pLDDT <= 50 (orange) |

## Dictionary Hover

Run `:MmcifDownloadDictionary` once to download the mmCIF dictionary and enable hover documentation. Press `K` on any category, item, or value to see its description in a floating window.

The dictionary is downloaded from wwPDB and stored in `~/.local/share/nvim/mmcif-rainbow/`.

## pLDDT Coloring

pLDDT confidence coloring is auto-detected for ModelCIF files (AlphaFold predictions). When detected, `B_iso_or_equiv` values are highlighted using the AlphaFold color scheme based on confidence score ranges.

## Credits

- [mmcif-rainbow](https://marketplace.visualstudio.com/items?itemName=N283T.mmcif-rainbow) -- the original VSCode extension this plugin is ported from
- [rainbow_csv.nvim](https://github.com/cameron-wags/rainbow_csv.nvim) -- inspired by its Neovim-native rainbow column approach
- [rainbow_csv](https://github.com/mechatroner/rainbow_csv) -- the original rainbow CSV plugin for Vim

## License

MIT
