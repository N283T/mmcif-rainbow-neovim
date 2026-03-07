local cache = require("mmcif-rainbow.cache")

describe("cache", function()
  before_each(function()
    cache.clear()
  end)

  it("stores and retrieves blocks by buffer", function()
    local blocks = { { category_name = "_entry", field_names = {}, data_rows = {}, start_line = 0 } }
    cache.set(1, 10, blocks)
    local result = cache.get(1, 10)
    assert.are.same(blocks, result)
  end)

  it("returns nil for wrong changedtick", function()
    local blocks = { { category_name = "_entry", field_names = {}, data_rows = {}, start_line = 0 } }
    cache.set(1, 10, blocks)
    assert.is_nil(cache.get(1, 11))
  end)

  it("returns nil for unknown buffer", function()
    assert.is_nil(cache.get(999, 1))
  end)

  it("deletes cache entry", function()
    cache.set(1, 10, {})
    cache.delete(1)
    assert.is_nil(cache.get(1, 10))
  end)

  it("clears all entries", function()
    cache.set(1, 10, {})
    cache.set(2, 20, {})
    cache.clear()
    assert.is_nil(cache.get(1, 10))
    assert.is_nil(cache.get(2, 20))
  end)
end)
