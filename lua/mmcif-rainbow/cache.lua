local M = {}

local store = {}

function M.set(buf, changedtick, blocks)
  store[buf] = { changedtick = changedtick, blocks = blocks }
end

function M.get(buf, changedtick)
  local entry = store[buf]
  if entry and entry.changedtick == changedtick then
    return entry.blocks
  end
  return nil
end

function M.delete(buf)
  store[buf] = nil
end

function M.clear()
  store = {}
end

return M
