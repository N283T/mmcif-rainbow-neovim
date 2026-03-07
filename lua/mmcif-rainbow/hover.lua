local cache = require("mmcif-rainbow.cache")
local dictionary = require("mmcif-rainbow.dictionary")

local M = {}

local function category_hover(category_name, dict_type)
  local clean = category_name:gsub("^_", "")
  local url = string.format(
    "https://mmcif.wwpdb.org/dictionaries/mmcif_pdbx_v50.dic/Categories/%s.html", clean
  )

  local lines = {
    "### " .. category_name,
    "",
    "[Online Documentation](" .. url .. ")",
    "",
    "---",
    "",
  }

  local cat_def = dictionary.get_category(category_name, dict_type)
  if cat_def and cat_def.description ~= "" then
    lines[#lines + 1] = cat_def.description
  end

  return lines
end

local function item_hover(category_name, field_name, dict_type)
  local full_tag = category_name .. "." .. field_name
  local clean = category_name:gsub("^_", "")
  local item_url = string.format(
    "https://mmcif.wwpdb.org/dictionaries/mmcif_pdbx_v50.dic/Items/_%s.%s.html", clean, field_name
  )
  local cat_url = string.format(
    "https://mmcif.wwpdb.org/dictionaries/mmcif_pdbx_v50.dic/Categories/%s.html", clean
  )

  local lines = {
    "### " .. full_tag,
    "",
    "[Online Documentation](" .. item_url .. ")",
    "",
    "---",
    "",
    "Category : [`" .. clean .. "`](" .. cat_url .. ")",
    "",
    "Attribute : `" .. field_name .. "`",
    "",
    "---",
    "",
  }

  local item_def = dictionary.get_item(category_name, field_name, dict_type)
  if item_def and item_def.description ~= "" then
    lines[#lines + 1] = item_def.description
  elseif dictionary.is_downloaded(dict_type) then
    lines[#lines + 1] = "*(No dictionary definition found)*"
  else
    lines[#lines + 1] = "*(Run `:MmcifDownloadDictionary` to enable descriptions)*"
  end

  return lines
end

local function value_hover(category_name, field_name)
  return { "**" .. category_name .. "." .. field_name .. "**" }
end

function M.show()
  local buf = vim.api.nvim_get_current_buf()
  local changedtick = vim.api.nvim_buf_get_changedtick(buf)
  local blocks = cache.get(buf, changedtick)
  if not blocks then return end

  local pos = vim.api.nvim_win_get_cursor(0)
  local row = pos[1] - 1
  local col = pos[2]

  local dict_type = dictionary.detect_type(buf)
  local hover_lines

  for _, block in ipairs(blocks) do
    for _, field in ipairs(block.field_names) do
      if field.line == row then
        if col >= field.category_start and col < field.category_start + field.category_length then
          hover_lines = category_hover(block.category_name, dict_type)
          break
        end
        if col >= field.start and col < field.start + field.length then
          hover_lines = item_hover(block.category_name, field.field_name, dict_type)
          break
        end
      end
    end
    if hover_lines then break end

    for _, data_row in ipairs(block.data_rows) do
      if data_row.line == row then
        for _, vr in ipairs(data_row.value_ranges) do
          if col >= vr.start and col < vr.start + vr.length then
            if vr.column_index < #block.field_names then
              local field = block.field_names[vr.column_index + 1]
              hover_lines = value_hover(block.category_name, field.field_name)
            end
            break
          end
        end
      elseif data_row.line > row then
        break
      end
      if hover_lines then break end
    end
    if hover_lines then break end
  end

  if hover_lines then
    vim.lsp.util.open_floating_preview(hover_lines, "markdown", {
      border = "rounded",
      focus_id = "mmcif_hover",
    })
  end
end

return M
