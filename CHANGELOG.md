# Changelog

## [0.2.0] - 2026-03-07

### Added

- Dictionary-backed hover tooltips with floating window (`K` keymap)
- `:MmcifDownloadDictionary` command to download dictionary files from wwPDB
- AlphaFold/ModelCIF pLDDT confidence coloring (auto-detected)
- Dictionary type auto-detection via `_audit_conform.dict_name`
- `dictionary` and `plddt` configuration options in `setup()`

## [0.1.0] - 2026-03-07

### Added

- Rainbow column highlighting for mmCIF files using extmarks
- Cursor column highlighting on CursorMoved
- Category navigation via `:MmcifGoToCategory` (Telescope / vim.ui.select)
- Filetype detection for `.cif` and `.mmcif` files
- Configurable colors via `setup()`
