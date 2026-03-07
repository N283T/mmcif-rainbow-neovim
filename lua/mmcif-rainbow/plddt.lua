local cache = require("mmcif-rainbow.cache")
local dictionary = require("mmcif-rainbow.dictionary")

local M = {}

local ns = vim.api.nvim_create_namespace("mmcif_plddt")

local THRESHOLDS = { VERY_HIGH = 90, HIGH = 70, LOW = 50 }
local COLORS = {
  VERY_HIGH = "#0053D6",
  HIGH = "#65CBF3",
  LOW = "#FFDB13",
  VERY_LOW = "#FF7D45",
}

function M.setup_highlights()
  vim.api.nvim_set_hl(0, "MmcifPlddtVeryHigh", { default = true, fg = COLORS.VERY_HIGH, bold = true })
  vim.api.nvim_set_hl(0, "MmcifPlddtHigh", { default = true, fg = COLORS.HIGH, bold = true })
  vim.api.nvim_set_hl(0, "MmcifPlddtLow", { default = true, fg = COLORS.LOW, bold = true })
  vim.api.nvim_set_hl(0, "MmcifPlddtVeryLow", { default = true, fg = COLORS.VERY_LOW, bold = true })
end

local function get_dict_type(buf)
  local cached = vim.b[buf].mmcif_dict_type
  if cached then return cached end
  local dt = dictionary.detect_type(buf)
  vim.b[buf].mmcif_dict_type = dt
  return dt
end

function M.update(buf)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  local dict_type = get_dict_type(buf)
  if dict_type ~= "mmcif_ma" then return end

  local changedtick = vim.api.nvim_buf_get_changedtick(buf)
  local blocks = cache.get(buf, changedtick)
  if not blocks then return end

  for _, block in ipairs(blocks) do
    if block.category_name ~= "_atom_site" then goto next_block end

    local b_iso_col = -1
    for i, field in ipairs(block.field_names) do
      if field.field_name == "B_iso_or_equiv" then
        b_iso_col = i - 1
        break
      end
    end

    if b_iso_col == -1 then goto next_block end

    local line_cache = {}

    for _, data_row in ipairs(block.data_rows) do
      for _, vr in ipairs(data_row.value_ranges) do
        if vr.column_index == b_iso_col and vr.length > 0 then
          if not line_cache[data_row.line] then
            local lines = vim.api.nvim_buf_get_lines(buf, data_row.line, data_row.line + 1, false)
            line_cache[data_row.line] = lines[1] or ""
          end
          local line_text = line_cache[data_row.line]
          local value_text = line_text:sub(vr.start + 1, vr.start + vr.length)
          local plddt = tonumber(value_text)

          if plddt then
            local hl_group
            if plddt > THRESHOLDS.VERY_HIGH then
              hl_group = "MmcifPlddtVeryHigh"
            elseif plddt > THRESHOLDS.HIGH then
              hl_group = "MmcifPlddtHigh"
            elseif plddt > THRESHOLDS.LOW then
              hl_group = "MmcifPlddtLow"
            else
              hl_group = "MmcifPlddtVeryLow"
            end

            pcall(vim.api.nvim_buf_set_extmark, buf, ns, data_row.line, vr.start, {
              end_col = vr.start + vr.length,
              hl_group = hl_group,
              priority = 200,
            })
          end
        end
      end
    end

    ::next_block::
  end
end

return M
