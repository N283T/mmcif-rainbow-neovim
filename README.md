# mmcif-rainbow.nvim

Rainbow column highlighting for mmCIF files in Neovim.

A Neovim port of [mmcif-rainbow-vscode](https://github.com/nagaet/mmcif-rainbow-vscode), using Lua parser and extmarks for accurate, performant highlighting.

## Features

- Rainbow highlighting for data columns in mmCIF `loop_` sections
- Cursor column highlight to visually track the current column
- Category navigation with `:MmcifGoToCategory`
- Automatic filetype detection for `.cif` and `.mmcif` files
- Configurable colors and file size limit

## Installation

### lazy.nvim

```lua
{
  "nagaet/mmcif-rainbow.nvim",
  ft = "mmcif",
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

## Credits

- [mmcif-rainbow-vscode](https://github.com/nagaet/mmcif-rainbow-vscode) -- the original VSCode extension this plugin is ported from

## License

MIT
