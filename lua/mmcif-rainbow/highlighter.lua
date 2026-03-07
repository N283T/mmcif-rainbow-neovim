local cache = require("mmcif-rainbow.cache")
local parser = require("mmcif-rainbow.parser")

local M = {}

local ns = vim.api.nvim_create_namespace("mmcif_rainbow")

function M.setup_highlights()
  local cfg = require("mmcif-rainbow").config
  vim.api.nvim_set_hl(0, "MmcifRainbow1", { default = true, fg = cfg.colors.category })
  for i, color in ipairs(cfg.colors.rainbow) do
    vim.api.nvim_set_hl(0, "MmcifRainbow" .. (i + 1), { default = true, fg = color })
  end
  vim.api.nvim_set_hl(0, "MmcifCursorColumn", { default = true, bg = "#333333" })
end

function M.update(buf)
  local cfg = require("mmcif-rainbow").config

  -- File size check
  local line_count = vim.api.nvim_buf_line_count(buf)
  local byte_count = vim.api.nvim_buf_get_offset(buf, line_count)
  if byte_count > cfg.max_file_size then return end

  local changedtick = vim.api.nvim_buf_get_changedtick(buf)
  local blocks = cache.get(buf, changedtick)

  if not blocks then
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    blocks = parser.parse_blocks(lines)
    cache.set(buf, changedtick, blocks)
  end

  -- Clear existing extmarks
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  local rainbow_count = #cfg.colors.rainbow

  for _, block in ipairs(blocks) do
    -- Color field names
    for field_index, field in ipairs(block.field_names) do
      -- Category part (fixed color)
      pcall(vim.api.nvim_buf_set_extmark, buf, ns, field.line, field.category_start, {
        end_col = field.category_start + field.category_length,
        hl_group = "MmcifRainbow1",
      })

      -- Field name part (cycling color)
      local token_type = 1 + ((field_index - 1) % rainbow_count)
      pcall(vim.api.nvim_buf_set_extmark, buf, ns, field.line, field.start, {
        end_col = field.start + field.length,
        hl_group = "MmcifRainbow" .. (token_type + 1),
      })
    end

    -- Color data values
    for _, data_row in ipairs(block.data_rows) do
      for _, vr in ipairs(data_row.value_ranges) do
        if vr.length > 0 then
          local token_type = 1 + (vr.column_index % rainbow_count)
          pcall(vim.api.nvim_buf_set_extmark, buf, ns, data_row.line, vr.start, {
            end_col = vr.start + vr.length,
            hl_group = "MmcifRainbow" .. (token_type + 1),
          })
        end
      end
    end
  end
end

return M
