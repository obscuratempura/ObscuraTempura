-- LinkPool.lua
local Link = require("link")  -- your original Link module
local LinkPool = {}

-- The pool table to hold inactive Link objects
LinkPool.pool = {}

-- Get a Link from the pool (or create a new one if none available)
function LinkPool.getLink(posA, posB, nodeA, nodeB, linkType)
  local link
  if #LinkPool.pool > 0 then
    -- Reuse an existing link from the pool
    link = table.remove(LinkPool.pool)
    -- Reset its properties:
    link.x = (posA.x + posB.x) / 2
    link.y = (posA.y + posB.y) / 2
    link.nodeA = nodeA
    link.nodeB = nodeB
    link.type = linkType or "grey"
    -- (Reset any additional properties you might need)
  else
    -- Create a new Link if the pool is empty.
    link = Link.new(posA, posB, nodeA, nodeB, linkType)
  end
  return link
end

-- Release a Link back into the pool
function LinkPool.releaseLink(link)
  -- Optionally, reset fields that you want cleared
  link.nodeA = nil
  link.nodeB = nil
  link.lifetime = 0
  table.insert(LinkPool.pool, link)
end

-- Optionally, you can add a function to clear the pool:
function LinkPool.clear()
  LinkPool.pool = {}
end

return LinkPool
