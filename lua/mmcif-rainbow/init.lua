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

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
end

return M
