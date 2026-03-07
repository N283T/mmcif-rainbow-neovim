local M = {}

local defaults = {
  colors = {
    category = "#4B69FF",
    rainbow = {
      "#E06C75", "#D19A66", "#E5C07B", "#98C379",
      "#56B6C2", "#528BFF", "#C678DD", "#BE5046", "#7F848E",
    },
  },
  cursor_column = true,
  max_file_size = 50 * 1024 * 1024,
}

M.config = vim.deepcopy(defaults)

local augroup = vim.api.nvim_create_augroup("MmcifRainbow", { clear = true })

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

  local highlighter = require("mmcif-rainbow.highlighter")
  local cursor = require("mmcif-rainbow.cursor")
  local cache = require("mmcif-rainbow.cache")

  -- Define highlight groups
  highlighter.setup_highlights()

  -- Re-apply highlights on colorscheme change
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = augroup,
    callback = function()
      highlighter.setup_highlights()
    end,
  })

  -- Highlight on file open and changes
  vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI" }, {
    group = augroup,
    pattern = { "*.cif", "*.mmcif" },
    callback = function(ev)
      highlighter.update(ev.buf)
    end,
  })

  -- Cursor column highlight (debounced via CursorMoved)
  if M.config.cursor_column then
    vim.api.nvim_create_autocmd("CursorMoved", {
      group = augroup,
      pattern = { "*.cif", "*.mmcif" },
      callback = function(ev)
        local pos = vim.api.nvim_win_get_cursor(0)
        cursor.update(ev.buf, pos[1] - 1, pos[2])
      end,
    })
  end

  -- Clean up cache on buffer delete
  vim.api.nvim_create_autocmd("BufDelete", {
    group = augroup,
    pattern = { "*.cif", "*.mmcif" },
    callback = function(ev)
      cache.delete(ev.buf)
    end,
  })

  -- User command
  vim.api.nvim_create_user_command("MmcifGoToCategory", function()
    require("mmcif-rainbow.picker").show()
  end, { desc = "Jump to mmCIF category" })
end

return M
