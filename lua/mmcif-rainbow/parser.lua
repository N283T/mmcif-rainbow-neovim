-- CIF/mmCIF parser: tokenizer, helpers, and block parser.
-- Ported from mmcif-rainbow-vscode/src/parser.ts.

local M = {}

-- ---------------------------------------------------------------------------
-- special_split: split a line into tokens handling quoted strings.
-- Returns array of {[1]=string, [2]=boolean} where [2] indicates if quoted.
-- ---------------------------------------------------------------------------

---@param content string
---@return table[] tokens  each element is {text, is_quoted}
function M.special_split(content)
  local output = { { "", false } }
  local quote = false
  local qtype = nil
  local length = #content
  local olast = 1

  for i = 1, length do
    local char = content:sub(i, i)
    local is_ws = char == " " or char == "\t"

    if (char == "'" or char == '"')
      and (i == 1
        or content:sub(i - 1, i - 1) == " "
        or content:sub(i - 1, i - 1) == "\t"
        or i == length
        or content:sub(i + 1, i + 1) == " "
        or content:sub(i + 1, i + 1) == "\t")
      and (not quote or char == qtype) then
      quote = not quote
      qtype = quote and char or nil
      output[olast][1] = output[olast][1] .. char
      output[olast][2] = true
    elseif not quote and is_ws and output[olast][1] ~= "" then
      output[#output + 1] = { "", false }
      olast = #output
    elseif not quote and char == "#" then
      break
    elseif not is_ws or quote then
      output[olast][1] = output[olast][1] .. char
      if quote then
        output[olast][2] = true
      end
    end
  end

  if output[olast][1] == "" then
    output[olast] = nil
  end

  return output
end

-- ---------------------------------------------------------------------------
-- Helper predicates
-- ---------------------------------------------------------------------------

---@param token table {text, is_quoted}
---@return boolean
function M.is_data_name(token)
  return token[1]:sub(1, 1) == "_" and not token[2]
end

---@param token table {text, is_quoted}
---@return boolean
function M.is_loop_keyword(token)
  return token[1] == "loop_" and not token[2]
end

---@param token table {text, is_quoted}
---@return boolean
function M.is_block_keyword(token)
  if token[2] then
    return false
  end
  local text = token[1]
  return text == "global_"
    or text:sub(1, 5) == "data_"
    or text:sub(1, 5) == "save_"
end

-- ---------------------------------------------------------------------------
-- parse_blocks: parse an array of lines into CategoryBlock structures.
--
-- Input:  lines  - 1-indexed Lua array of strings (raw file lines)
-- Output: array of CategoryBlock tables with 0-indexed line numbers
--
-- CategoryBlock = {
--   start_line      : number (0-indexed),
--   category_name   : string,
--   field_names     : FieldDef[],
--   data_rows       : DataRow[],
-- }
--
-- FieldDef = {
--   line            : number (0-indexed),
--   start           : number (0-indexed column),
--   length          : number,
--   field_name      : string,
--   category_start  : number (0-indexed column),
--   category_length : number,
-- }
--
-- ValueRange = { start: number (0-indexed), length: number, column_index: number }
-- DataRow    = { line: number (0-indexed), value_ranges: ValueRange[],
--                multi_line_range?: {start_line: number, end_line: number} }
-- ---------------------------------------------------------------------------

---@param block table ParserBlock
---@return number
local function current_column_index(block)
  local field_count = #block.field_names
  if field_count == 0 then
    field_count = 1
  end
  return block.processed_value_count % field_count
end

---@param block table ParserBlock
---@return table CategoryBlock
local function emit_block(block)
  return {
    start_line = block.start_line,
    category_name = block.category_name,
    field_names = block.field_names,
    data_rows = block.data_rows,
  }
end

---@param lines string[] 1-indexed array of file lines
---@return table[] CategoryBlock[] with 0-indexed line numbers
function M.parse_blocks(lines)
  local blocks = {}
  local current = nil
  local multi_line_mode = false
  local multi_line_start_line = -1
  local multi_line_data_row_start_idx = -1

  local function emit_current()
    if current and #current.field_names > 0 then
      blocks[#blocks + 1] = emit_block(current)
    end
    current = nil
  end

  for i = 1, #lines do
    local line_text = lines[i]
    local first_char = #line_text > 0 and line_text:sub(1, 1) or ""
    local line_idx = i - 1 -- 0-indexed for output

    -- Skip comment lines
    if first_char == "#" then
      if current and #current.field_names > 0 and current.header_complete then
        emit_current()
      end
      goto continue
    end

    -- Handle multi-line strings (; ... ;)
    if first_char == ";" then
      if multi_line_mode then
        -- End of multi-line string
        multi_line_mode = false
        if current then
          local col_index = current_column_index(current)

          current.data_rows[#current.data_rows + 1] = {
            line = line_idx,
            value_ranges = { { start = 0, length = #line_text, column_index = col_index } },
          }
          current.processed_value_count = current.processed_value_count + 1

          -- Set multi_line_range on all rows in this multi-line block
          if multi_line_data_row_start_idx >= 1 then
            local range = { start_line = multi_line_start_line, end_line = line_idx }
            for j = multi_line_data_row_start_idx, #current.data_rows do
              current.data_rows[j].multi_line_range = range
            end
          end
        end
        if current and #current.field_names > 0 then
          current.header_complete = true
        end
      else
        -- Start of multi-line string
        multi_line_mode = true
        multi_line_start_line = line_idx
        multi_line_data_row_start_idx = current and (#current.data_rows + 1) or -1
        if current then
          local col_index = current_column_index(current)

          current.data_rows[#current.data_rows + 1] = {
            line = line_idx,
            value_ranges = { { start = 0, length = #line_text, column_index = col_index } },
          }
        end
      end
      goto continue
    end

    if multi_line_mode then
      -- Inside a multi-line string
      if current then
        local col_index = current_column_index(current)

        current.data_rows[#current.data_rows + 1] = {
          line = line_idx,
          value_ranges = { { start = 0, length = #line_text, column_index = col_index } },
        }
      end
      goto continue
    end

    do
      local trimmed = line_text:match("^%s*(.-)%s*$")
      if trimmed == "" then
        if current and #current.field_names > 0 and not current.header_complete then
          current.header_complete = true
        end
        goto continue
      end

      local tokens = M.special_split(trimmed)
      if #tokens == 0 then
        goto continue
      end

      -- Block keywords (data_, save_, global_)
      if M.is_block_keyword(tokens[1]) then
        emit_current()
        goto continue
      end

      -- loop_ keyword
      if M.is_loop_keyword(tokens[1]) then
        emit_current()
        current = {
          start_line = line_idx,
          category_name = "",
          field_names = {},
          data_rows = {},
          is_loop = true,
          header_complete = false,
          processed_value_count = 0,
        }
        goto continue
      end

      -- Data name (_category.field)
      if M.is_data_name(tokens[1]) then
        local data_name = tokens[1][1]
        local cat, field = data_name:match("^(_[A-Za-z0-9_]+)%.([A-Za-z0-9_%[%]]+)$")

        if cat then
          local category_name = cat
          local field_name = field

          -- Find position in the original line
          local match_start = line_text:find(data_name, 1, true)
          if not match_start then
            goto continue
          end

          local leading_len = match_start - 1 -- 0-indexed
          local field_start = leading_len + #category_name + 1 -- after "category."
          local field_length = #field_name

          -- Decide whether to emit the current block and start a new one
          if current then
            if current.is_loop then
              if current.header_complete then
                emit_current()
              elseif current.category_name ~= "" and current.category_name ~= category_name then
                emit_current()
              end
            else
              if current.category_name ~= category_name then
                emit_current()
              end
            end
          end

          -- Create new block if needed
          if not current then
            current = {
              start_line = line_idx,
              category_name = category_name,
              field_names = {},
              data_rows = {},
              is_loop = false,
              header_complete = false,
              processed_value_count = 0,
            }
          end

          if current.category_name == "" then
            current.category_name = category_name
          end

          -- Add field definition
          local column_index = #current.field_names
          current.field_names[#current.field_names + 1] = {
            line = line_idx,
            start = field_start,
            length = field_length,
            field_name = field_name,
            category_start = leading_len,
            category_length = #category_name + 1,
          }

          -- For non-loop blocks, inline values on the same line become data
          if not current.is_loop and #tokens > 1 then
            local value_ranges = {}
            -- search_start: position in line_text after the full data_name match
            local search_start = match_start + #data_name

            for col = 2, #tokens do
              local token_text = tokens[col][1]
              if token_text and token_text ~= "" then
                local idx = line_text:find(token_text, search_start, true)
                if idx then
                  value_ranges[#value_ranges + 1] = {
                    start = idx - 1, -- 0-indexed
                    length = #token_text,
                    column_index = column_index,
                  }
                  search_start = idx + #token_text
                end
              end
            end

            if #value_ranges > 0 then
              current.data_rows[#current.data_rows + 1] = {
                line = line_idx,
                value_ranges = value_ranges,
              }
              current.processed_value_count = current.processed_value_count + #value_ranges
              current.header_complete = true
            end
          end
        end
      elseif current and #current.field_names > 0 then
        -- Data line (not a data name)
        if not current.header_complete then
          current.header_complete = true
        end

        local value_ranges = {}
        local field_count = #current.field_names
        local max_cols = math.min(field_count, #tokens)
        local search_start = 1

        for col = 1, max_cols do
          local token_text = tokens[col][1]
          if token_text and token_text ~= "" then
            local idx = line_text:find(token_text, search_start, true)
            if idx then
              local current_total_count = current.processed_value_count + (col - 1)
              local effective_col_index = current_total_count % field_count

              value_ranges[#value_ranges + 1] = {
                start = idx - 1, -- 0-indexed
                length = #token_text,
                column_index = effective_col_index,
              }
              search_start = idx + #token_text
            end
          end
        end

        if #value_ranges > 0 then
          current.data_rows[#current.data_rows + 1] = {
            line = line_idx,
            value_ranges = value_ranges,
          }
          current.processed_value_count = current.processed_value_count + #value_ranges
        end
      end
    end

    ::continue::
  end

  emit_current()
  return blocks
end

return M
