local cache = require("mmcif-rainbow.cache")

local M = {}

local ns = vim.api.nvim_create_namespace("mmcif_cursor")

function M.update(buf, row, col)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  local changedtick = vim.api.nvim_buf_get_changedtick(buf)
  local blocks = cache.get(buf, changedtick)
  if not blocks then return end

  for _, block in ipairs(blocks) do
    local target_col_index = -1

    -- Check field names (headers)
    for i, field in ipairs(block.field_names) do
      if field.line == row and col >= field.start and col < field.start + field.length then
        target_col_index = i - 1  -- 0-based
        break
      end
    end

    -- Check data values
    if target_col_index == -1 then
      for _, data_row in ipairs(block.data_rows) do
        if data_row.line == row then
          for _, vr in ipairs(data_row.value_ranges) do
            if col >= vr.start and col < vr.start + vr.length then
              target_col_index = vr.column_index
              break
            end
          end
        elseif data_row.line > row then
          break  -- data rows are ordered, no need to continue
        end
        if target_col_index ~= -1 then break end
      end
    end

    if target_col_index ~= -1 then
      -- Highlight header
      if target_col_index < #block.field_names then
        local field = block.field_names[target_col_index + 1]
        pcall(vim.api.nvim_buf_set_extmark, buf, ns, field.line, field.start, {
          end_col = field.start + field.length,
          hl_group = "MmcifCursorColumn",
        })
      end

      -- Highlight data values
      for _, data_row in ipairs(block.data_rows) do
        for _, vr in ipairs(data_row.value_ranges) do
          if vr.column_index == target_col_index then
            pcall(vim.api.nvim_buf_set_extmark, buf, ns, data_row.line, vr.start, {
              end_col = vr.start + vr.length,
              hl_group = "MmcifCursorColumn",
            })
          end
        end
      end

      break
    end
  end
end

function M.clear(buf)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
end

return M
