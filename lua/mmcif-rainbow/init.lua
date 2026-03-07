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
  dictionary = {
    enabled = true,
    auto_download = false,
  },
  plddt = true,
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

  -- Highlight on file open and changes
  vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI" }, {
    group = augroup,
    pattern = { "*.cif", "*.mmcif" },
    callback = function(ev)
      highlighter.update(ev.buf)
    end,
  })

  -- Cursor column highlight
  if M.config.cursor_column then
    local cursor_timer = vim.uv.new_timer()
    vim.api.nvim_create_autocmd("CursorMoved", {
      group = augroup,
      pattern = { "*.cif", "*.mmcif" },
      callback = function(ev)
        cursor_timer:stop()
        cursor_timer:start(50, 0, vim.schedule_wrap(function()
          if vim.api.nvim_buf_is_valid(ev.buf) then
            local pos = vim.api.nvim_win_get_cursor(0)
            cursor.update(ev.buf, pos[1] - 1, pos[2])
          end
        end))
      end,
    })
  end

  -- Clean up cache on buffer delete
  vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    group = augroup,
    pattern = { "*.cif", "*.mmcif" },
    callback = function(ev)
      cache.delete(ev.buf)
    end,
  })

  -- User commands
  vim.api.nvim_create_user_command("MmcifGoToCategory", function()
    require("mmcif-rainbow.picker").show()
  end, { desc = "Jump to mmCIF category" })

  vim.api.nvim_create_user_command("MmcifDownloadDictionary", function()
    require("mmcif-rainbow.dictionary").download()
  end, { desc = "Download mmCIF dictionary for hover" })

  -- Hover keymap for mmcif buffers
  if M.config.dictionary.enabled then
    vim.api.nvim_create_autocmd("FileType", {
      group = augroup,
      pattern = "mmcif",
      callback = function(ev)
        vim.keymap.set("n", "K", function()
          require("mmcif-rainbow.hover").show()
        end, { buffer = ev.buf, desc = "mmCIF hover" })
      end,
    })
  end

  -- pLDDT coloring
  local plddt = M.config.plddt and require("mmcif-rainbow.plddt") or nil
  if plddt then
    plddt.setup_highlights()

    vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI" }, {
      group = augroup,
      pattern = { "*.cif", "*.mmcif" },
      callback = function(ev)
        plddt.update(ev.buf)
      end,
    })
  end

  -- Re-apply highlights on colorscheme change
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = augroup,
    callback = function()
      highlighter.setup_highlights()
      if plddt then plddt.setup_highlights() end
    end,
  })
end

return M
