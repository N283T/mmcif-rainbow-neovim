local dictionary = require("mmcif-rainbow.dictionary")

describe("dictionary", function()
  before_each(function()
    dictionary.clear()
  end)

  it("returns correct data_dir path", function()
    local dir = dictionary.data_dir()
    assert.is_true(dir:find("mmcif%-rainbow") ~= nil)
  end)

  it("returns correct dict_path", function()
    local path = dictionary.dict_path("mmcif_pdbx")
    assert.is_true(path:find("mmcif_pdbx_v50.dic.json") ~= nil)
  end)

  it("detects mmcif_pdbx type by default", function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "data_test", "_entry.id 1ABC" })
    assert.are.equal("mmcif_pdbx", dictionary.detect_type(buf))
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("detects mmcif_ma type", function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "data_test",
      "_audit_conform.dict_name mmcif_ma.dic",
    })
    assert.are.equal("mmcif_ma", dictionary.detect_type(buf))
    vim.api.nvim_buf_delete(buf, { force = true })
  end)

  it("returns nil for unloaded dictionary", function()
    assert.is_nil(dictionary.get_category("_entry", "mmcif_pdbx"))
  end)
end)
