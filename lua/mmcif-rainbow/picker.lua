local cache = require("mmcif-rainbow.cache")

local M = {}

function M.show()
  local buf = vim.api.nvim_get_current_buf()
  local changedtick = vim.api.nvim_buf_get_changedtick(buf)
  local blocks = cache.get(buf, changedtick)

  if not blocks or #blocks == 0 then
    vim.notify("No mmCIF data found or file is being parsed.", vim.log.levels.INFO)
    return
  end

  local seen = {}
  local items = {}
  for _, block in ipairs(blocks) do
    if block.category_name and not seen[block.category_name] then
      seen[block.category_name] = true
      local target_line = block.start_line
      if #block.field_names > 0 then
        target_line = block.field_names[1].line
      end
      items[#items + 1] = {
        label = block.category_name,
        line = target_line,
      }
    end
  end

  table.sort(items, function(a, b) return a.label < b.label end)

  -- Try Telescope first
  local has_telescope, _ = pcall(require, "telescope.pickers")
  if has_telescope then
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    pickers.new({}, {
      prompt_title = "mmCIF Categories",
      finder = finders.new_table({
        results = items,
        entry_maker = function(entry)
          return {
            value = entry,
            display = string.format("%s (line %d)", entry.label, entry.line + 1),
            ordinal = entry.label,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          if selection then
            vim.api.nvim_win_set_cursor(0, { selection.value.line + 1, 0 })
            vim.cmd("normal! zt")
          end
        end)
        return true
      end,
    }):find()
  else
    -- Fallback to vim.ui.select
    local labels = {}
    local label_map = {}
    for _, item in ipairs(items) do
      local display = string.format("%s (line %d)", item.label, item.line + 1)
      labels[#labels + 1] = display
      label_map[display] = item
    end

    vim.ui.select(labels, { prompt = "mmCIF Categories:" }, function(choice)
      if choice then
        local item = label_map[choice]
        if item then
          vim.api.nvim_win_set_cursor(0, { item.line + 1, 0 })
          vim.cmd("normal! zt")
        end
      end
    end)
  end
end

return M
