local parser = require("mmcif-rainbow.parser")

-- Helper: extract just the text strings from special_split result
local function texts(tokens)
  local result = {}
  for _, t in ipairs(tokens) do
    result[#result + 1] = t[1]
  end
  return result
end

-- Helper: extract just the quoted flags from special_split result
local function quotes(tokens)
  local result = {}
  for _, t in ipairs(tokens) do
    result[#result + 1] = t[2]
  end
  return result
end

describe("special_split", function()
  it("splits simple whitespace-separated tokens", function()
    local result = parser.special_split("hello world foo")
    assert.are.same({ "hello", "world", "foo" }, texts(result))
    assert.are.same({ false, false, false }, quotes(result))
  end)

  it("handles single-quoted strings", function()
    local result = parser.special_split("'hello world' foo")
    assert.are.same({ "'hello world'", "foo" }, texts(result))
    assert.are.same({ true, false }, quotes(result))
  end)

  it("handles double-quoted strings", function()
    local result = parser.special_split('"hello world" foo')
    assert.are.same({ '"hello world"', "foo" }, texts(result))
    assert.are.same({ true, false }, quotes(result))
  end)

  it("ignores comments", function()
    local result = parser.special_split("foo bar # this is a comment")
    assert.are.same({ "foo", "bar" }, texts(result))
  end)

  it("does not treat # inside quotes as comment", function()
    local result = parser.special_split("'foo # bar' baz")
    assert.are.same({ "'foo # bar'", "baz" }, texts(result))
  end)

  it("returns empty table for empty string", function()
    local result = parser.special_split("")
    assert.are.same({}, result)
  end)

  it("returns empty table for whitespace-only string", function()
    local result = parser.special_split("   ")
    assert.are.same({}, result)
  end)

  it("returns empty table for comment-only line", function()
    local result = parser.special_split("# just a comment")
    assert.are.same({}, result)
  end)

  it("handles tabs as whitespace", function()
    local result = parser.special_split("foo\tbar\tbaz")
    assert.are.same({ "foo", "bar", "baz" }, texts(result))
  end)

  it("handles leading whitespace", function()
    local result = parser.special_split("   foo bar")
    assert.are.same({ "foo", "bar" }, texts(result))
  end)

  it("handles trailing whitespace", function()
    local result = parser.special_split("foo bar   ")
    assert.are.same({ "foo", "bar" }, texts(result))
  end)

  it("preserves internal apostrophes (not quote boundaries)", function()
    local result = parser.special_split("it's a test")
    assert.are.same({ "it's", "a", "test" }, texts(result))
    assert.are.same({ false, false, false }, quotes(result))
  end)

  it("handles single token", function()
    local result = parser.special_split("hello")
    assert.are.same({ "hello" }, texts(result))
  end)

  it("handles mixed quoted and unquoted", function()
    local result = parser.special_split("_entry.id 'my value' 42")
    assert.are.same({ "_entry.id", "'my value'", "42" }, texts(result))
    assert.are.same({ false, true, false }, quotes(result))
  end)
end)

describe("helper functions", function()
  describe("is_data_name", function()
    it("returns true for underscore-prefixed unquoted token", function()
      assert.is_true(parser.is_data_name({ "_entry.id", false }))
    end)

    it("returns false for quoted underscore token", function()
      assert.is_false(parser.is_data_name({ "_entry.id", true }))
    end)

    it("returns false for non-underscore token", function()
      assert.is_false(parser.is_data_name({ "hello", false }))
    end)
  end)

  describe("is_loop_keyword", function()
    it("returns true for unquoted loop_", function()
      assert.is_true(parser.is_loop_keyword({ "loop_", false }))
    end)

    it("returns false for quoted loop_", function()
      assert.is_false(parser.is_loop_keyword({ "loop_", true }))
    end)

    it("returns false for other text", function()
      assert.is_false(parser.is_loop_keyword({ "data_", false }))
    end)
  end)

  describe("is_block_keyword", function()
    it("returns true for data_xxx", function()
      assert.is_true(parser.is_block_keyword({ "data_myblock", false }))
    end)

    it("returns true for save_xxx", function()
      assert.is_true(parser.is_block_keyword({ "save_frame", false }))
    end)

    it("returns true for global_", function()
      assert.is_true(parser.is_block_keyword({ "global_", false }))
    end)

    it("returns false for quoted block keyword", function()
      assert.is_false(parser.is_block_keyword({ "data_myblock", true }))
    end)

    it("returns false for loop_", function()
      assert.is_false(parser.is_block_keyword({ "loop_", false }))
    end)

    it("returns false for regular text", function()
      assert.is_false(parser.is_block_keyword({ "hello", false }))
    end)
  end)
end)

describe("parse_blocks", function()
  it("parses a simple loop block", function()
    local lines = {
      "loop_",
      "_atom.id",
      "_atom.symbol",
      "1 C",
      "2 N",
    }

    local blocks = parser.parse_blocks(lines)
    assert.are.equal(1, #blocks)

    local b = blocks[1]
    assert.are.equal(0, b.start_line) -- 0-indexed
    assert.are.equal("_atom", b.category_name)
    assert.are.equal(2, #b.field_names)
    assert.are.equal("id", b.field_names[1].field_name)
    assert.are.equal("symbol", b.field_names[2].field_name)
    assert.are.equal(2, #b.data_rows)

    -- Check first data row
    assert.are.equal(3, b.data_rows[1].line) -- 0-indexed
    assert.are.equal(2, #b.data_rows[1].value_ranges)
    assert.are.equal(0, b.data_rows[1].value_ranges[1].column_index)
    assert.are.equal(1, b.data_rows[1].value_ranges[2].column_index)
  end)

  it("parses non-loop tag-value pairs", function()
    local lines = {
      "_entry.id myentry",
      "_entry.title 'My Title'",
    }

    local blocks = parser.parse_blocks(lines)
    assert.are.equal(1, #blocks)

    local b = blocks[1]
    assert.are.equal("_entry", b.category_name)
    assert.are.equal(2, #b.field_names)
    assert.are.equal("id", b.field_names[1].field_name)
    assert.are.equal("title", b.field_names[2].field_name)
    assert.are.equal(2, #b.data_rows)

    -- Check value position (0-indexed)
    local vr = b.data_rows[1].value_ranges[1]
    assert.are.equal(10, vr.start) -- "_entry.id " is 10 chars
    assert.are.equal(7, vr.length) -- "myentry"
  end)

  it("handles semicolon multi-line strings", function()
    local lines = {
      "_entry.id test",
      "_entry.desc",
      ";first line",
      "second line",
      ";",
    }

    local blocks = parser.parse_blocks(lines)
    assert.are.equal(1, #blocks)

    local b = blocks[1]
    assert.are.equal("_entry", b.category_name)
    assert.are.equal(2, #b.field_names)

    -- The multi-line value should have rows with multi_line_range
    local multi_rows = {}
    for _, row in ipairs(b.data_rows) do
      if row.multi_line_range then
        multi_rows[#multi_rows + 1] = row
      end
    end
    assert.is_true(#multi_rows > 0)

    -- Check multi_line_range spans correct lines
    local range = multi_rows[1].multi_line_range
    assert.are.equal(2, range.start_line) -- 0-indexed line of ";"
    assert.are.equal(4, range.end_line)   -- 0-indexed line of closing ";"
  end)

  it("groups different categories into separate blocks", function()
    local lines = {
      "_entry.id myentry",
      "_cell.length_a 10.0",
      "_cell.length_b 20.0",
    }

    local blocks = parser.parse_blocks(lines)
    assert.are.equal(2, #blocks)
    assert.are.equal("_entry", blocks[1].category_name)
    assert.are.equal("_cell", blocks[2].category_name)
  end)

  it("skips comment lines", function()
    local lines = {
      "# This is a comment",
      "_entry.id myentry",
    }

    local blocks = parser.parse_blocks(lines)
    assert.are.equal(1, #blocks)
    assert.are.equal("_entry", blocks[1].category_name)
  end)

  it("skips empty lines", function()
    local lines = {
      "",
      "_entry.id myentry",
      "",
    }

    local blocks = parser.parse_blocks(lines)
    assert.are.equal(1, #blocks)
  end)

  it("handles block keywords separating blocks", function()
    local lines = {
      "data_myblock",
      "_entry.id myentry",
      "data_other",
      "_cell.length 10.0",
    }

    local blocks = parser.parse_blocks(lines)
    assert.are.equal(2, #blocks)
    assert.are.equal("_entry", blocks[1].category_name)
    assert.are.equal("_cell", blocks[2].category_name)
  end)

  it("handles column index cycling with processedValueCount", function()
    -- 3 columns but values split across multiple lines
    local lines = {
      "loop_",
      "_atom.id",
      "_atom.symbol",
      "_atom.charge",
      "1 C 0",
      "2 N -1",
    }

    local blocks = parser.parse_blocks(lines)
    assert.are.equal(1, #blocks)

    local b = blocks[1]
    assert.are.equal(3, #b.field_names)
    assert.are.equal(2, #b.data_rows)

    -- First row: columns 0, 1, 2
    assert.are.equal(0, b.data_rows[1].value_ranges[1].column_index)
    assert.are.equal(1, b.data_rows[1].value_ranges[2].column_index)
    assert.are.equal(2, b.data_rows[1].value_ranges[3].column_index)

    -- Second row: columns 0, 1, 2 (cycling restarts)
    assert.are.equal(0, b.data_rows[2].value_ranges[1].column_index)
    assert.are.equal(1, b.data_rows[2].value_ranges[2].column_index)
    assert.are.equal(2, b.data_rows[2].value_ranges[3].column_index)
  end)

  it("handles field definitions with correct 0-indexed positions", function()
    local lines = {
      "  _atom.id",
    }

    local blocks = parser.parse_blocks(lines)
    -- No value, but still a block with field info (loop-like, no data)
    -- Actually for non-loop with no value, we get a field but no data row
    assert.are.equal(1, #blocks)

    local fd = blocks[1].field_names[1]
    assert.are.equal(0, fd.line)
    assert.are.equal(2, fd.category_start)   -- 0-indexed leading spaces
    assert.are.equal(6, fd.category_length)  -- "_atom." = 6 chars
    assert.are.equal(8, fd.start)            -- after "  _atom."
    assert.are.equal(2, fd.length)           -- "id"
    assert.are.equal("id", fd.field_name)
  end)

  it("emits current block when comment follows loop data", function()
    local lines = {
      "loop_",
      "_atom.id",
      "1",
      "# comment terminates block",
      "_entry.id test",
    }

    local blocks = parser.parse_blocks(lines)
    assert.are.equal(2, #blocks)
    assert.are.equal("_atom", blocks[1].category_name)
    assert.are.equal("_entry", blocks[2].category_name)
  end)

  it("handles loop with values on fewer columns than headers", function()
    local lines = {
      "loop_",
      "_atom.id",
      "_atom.symbol",
      "_atom.charge",
      "1 C",
    }

    local blocks = parser.parse_blocks(lines)
    assert.are.equal(1, #blocks)

    local b = blocks[1]
    -- Only 2 values on the line, but 3 field definitions
    -- max_cols = min(3, 2) = 2
    assert.are.equal(1, #b.data_rows)
    assert.are.equal(2, #b.data_rows[1].value_ranges)
    assert.are.equal(0, b.data_rows[1].value_ranges[1].column_index)
    assert.are.equal(1, b.data_rows[1].value_ranges[2].column_index)
  end)

  it("handles multi-line value inside a loop", function()
    local lines = {
      "loop_",
      "_item.name",
      "_item.desc",
      "alpha",
      ";multi",
      "line value",
      ";",
    }

    local blocks = parser.parse_blocks(lines)
    assert.are.equal(1, #blocks)

    local b = blocks[1]
    assert.are.equal(2, #b.field_names)
    -- "alpha" is value for column 0
    -- Then multi-line is value for column 1
    -- After alpha: processedValueCount = 1, so col_index = 1 % 2 = 1
  end)

  it("returns empty blocks for empty input", function()
    local blocks = parser.parse_blocks({})
    assert.are.same({}, blocks)
  end)

  it("returns empty blocks for comments-only input", function()
    local blocks = parser.parse_blocks({ "# comment", "# another" })
    assert.are.same({}, blocks)
  end)
end)
