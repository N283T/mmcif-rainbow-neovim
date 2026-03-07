local M = {}

local DICT_URLS = {
  mmcif_pdbx = "https://raw.githubusercontent.com/N283T/mmcif-rainbow-vscode/main/assets/mmcif_pdbx_v50.dic.json",
  mmcif_ma = "https://raw.githubusercontent.com/N283T/mmcif-rainbow-vscode/main/assets/mmcif_ma.dic.json",
}

local DICT_FILES = {
  mmcif_pdbx = "mmcif_pdbx_v50.dic.json",
  mmcif_ma = "mmcif_ma.dic.json",
}

local loaded = {}
local downloading = false

function M.data_dir()
  return vim.fn.stdpath("data") .. "/mmcif-rainbow"
end

function M.dict_path(dict_type)
  return M.data_dir() .. "/" .. DICT_FILES[dict_type]
end

function M.is_downloaded(dict_type)
  return vim.fn.filereadable(M.dict_path(dict_type)) == 1
end

function M.download(callback)
  if downloading then
    vim.notify("Dictionary download already in progress.", vim.log.levels.WARN)
    return
  end

  if vim.fn.executable("curl") ~= 1 then
    vim.notify("mmcif-rainbow: 'curl' is required for dictionary download but was not found.", vim.log.levels.ERROR)
    return
  end

  downloading = true

  local dir = M.data_dir()
  vim.fn.mkdir(dir, "p")

  local remaining = 0
  local errors = {}

  local function finish()
    downloading = false
    M.clear()
    if #errors > 0 then
      local err_msg = table.concat(errors, "; ")
      vim.notify("Dictionary download failed: " .. err_msg, vim.log.levels.ERROR)
      if callback then callback(err_msg) end
    else
      vim.notify("Dictionary downloaded successfully.", vim.log.levels.INFO)
      if callback then callback(nil) end
    end
  end

  for dict_type, url in pairs(DICT_URLS) do
    remaining = remaining + 1
    local output_path = M.dict_path(dict_type)
    local tmp_path = output_path .. ".tmp"

    local spawn_ok, spawn_err = pcall(vim.system,
      { "curl", "-fsSL", "-o", tmp_path, url },
      {},
      vim.schedule_wrap(function(result)
        if result.code ~= 0 then
          pcall(os.remove, tmp_path)
          errors[#errors + 1] = string.format("%s: %s", dict_type, result.stderr or "download failed")
        else
          local ok, err = os.rename(tmp_path, output_path)
          if not ok then
            pcall(os.remove, tmp_path)
            errors[#errors + 1] = string.format("%s: rename failed: %s", dict_type, err)
          end
        end
        remaining = remaining - 1
        if remaining == 0 then finish() end
      end)
    )
    if not spawn_ok then
      errors[#errors + 1] = string.format("%s: %s", dict_type, tostring(spawn_err))
      remaining = remaining - 1
      if remaining == 0 then finish() end
    end
  end
end

function M.load(dict_type)
  if loaded[dict_type] then return true end

  if not M.is_downloaded(dict_type) then return false end

  local path = M.dict_path(dict_type)
  local ok, content = pcall(vim.fn.readfile, path)
  if not ok then
    vim.notify(string.format("mmcif-rainbow: Failed to read dictionary: %s", content), vim.log.levels.WARN)
    return false
  end

  local json_str = table.concat(content, "\n")
  local ok2, json_data = pcall(vim.json.decode, json_str)
  if not ok2 then
    vim.notify(string.format("mmcif-rainbow: Failed to parse dictionary: %s", json_data), vim.log.levels.WARN)
    return false
  end

  local categories = {}

  local frames
  for _, block_data in pairs(json_data) do
    if type(block_data) == "table" and block_data.Frames then
      frames = block_data.Frames
      break
    end
  end

  if not frames then
    vim.notify("mmcif-rainbow: Dictionary has unexpected format (no Frames found)", vim.log.levels.WARN)
    return false
  end

  for _, frame in pairs(frames) do
    local cat_id = frame["_category.id"]
    if cat_id then
      local desc = frame["_category.description"]
      if type(desc) == "table" then desc = table.concat(desc, "\n") end
      categories[cat_id] = categories[cat_id] or { description = desc or "", items = {} }
    end

    local raw_names = frame["_item.name"]
    local raw_cats = frame["_item.category_id"]
    if raw_names then
      local names = type(raw_names) == "table" and raw_names or { raw_names }
      local cats = type(raw_cats) == "table" and raw_cats or { raw_cats }
      local desc = frame["_item_description.description"]
      if type(desc) == "table" then desc = table.concat(desc, "\n") end

      for i, item_name in ipairs(names) do
        local item_cat = cats[i] or cats[1]
        if item_name and item_cat then
          categories[item_cat] = categories[item_cat] or { description = "", items = {} }
          local dot_pos = item_name:find("%.")
          if dot_pos then
            local attr = item_name:sub(dot_pos + 1)
            categories[item_cat].items[attr] = { description = (desc or ""):match("^%s*(.-)%s*$") or "" }
          end
        end
      end
    end
  end

  loaded[dict_type] = { categories = categories }
  return true
end

function M.detect_type(buf)
  local cached = vim.b[buf].mmcif_dict_type
  if cached then return cached end

  local line_count = vim.api.nvim_buf_line_count(buf)
  local limit = math.min(line_count, 500)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, limit, false)
  local dt = "mmcif_pdbx"
  for _, line in ipairs(lines) do
    if line:find("_audit_conform.dict_name", 1, true) and line:find("mmcif_ma.dic", 1, true) then
      dt = "mmcif_ma"
      break
    end
  end
  vim.b[buf].mmcif_dict_type = dt
  return dt
end

function M.get_category(category_name, dict_type)
  if not loaded[dict_type] then
    if not M.load(dict_type) then return nil end
  end
  local clean = category_name:gsub("^_", "")
  return loaded[dict_type].categories[clean]
end

function M.get_item(category_name, item_name, dict_type)
  local cat = M.get_category(category_name, dict_type)
  if cat then return cat.items[item_name] end
end

function M.clear()
  loaded = {}
end

return M
