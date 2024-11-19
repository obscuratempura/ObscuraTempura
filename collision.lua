local Collision = {}
local Abilities = {}
local Effects = require("effects")

function Collision.checkCircle(x1, y1, r1, x2, y2, r2)
    local dx = x1 - x2
    local dy = y1 - y2
    local distanceSquared = dx * dx + dy * dy
    local radiusSum = r1 + r2
    return distanceSquared <= radiusSum * radiusSum
end

function Collision.checkRectangle(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 + w1 > x2 and x1 < x2 + w2 and y1 + h1 > y2 and y1 < y2 + h2
end

function Collision.checkRectangleCollision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and x1 + w1 > x2 and y1 < y2 + h2 and y1 + h1 > y2
end

function resolveCollision(char, wall)
    -- Calculate the overlap distances for each axis
    local overlapX = (char.x + char.width) - wall.x
    local overlapY = (char.y + char.height) - wall.y

    -- Adjust only on the axis with the smallest overlap to avoid jumping
    if math.abs(overlapX) < math.abs(overlapY) then
        if char.x < wall.x then
            char.x = wall.x - char.width  -- Place exactly at the left edge of the wall
        else
            char.x = wall.x + wall.width  -- Place exactly at the right edge of the wall
        end
    else
        if char.y < wall.y then
            char.y = wall.y - char.height  -- Place exactly at the top edge of the wall
        else
            char.y = wall.y + wall.height  -- Place exactly at the bottom edge of the wall
        end
    end
end





function Collision.checkCircleRectangle(cx, cy, cr, rx, ry, rw, rh)
    -- Find the closest point to the circle within the rectangle
    local closestX = math.max(rx, math.min(cx, rx + rw))
    local closestY = math.max(ry, math.min(cy, ry + rh))

    -- Calculate the distance between the circle's center and this closest point
    local distanceX = cx - closestX
    local distanceY = cy - closestY

    -- If the distance is less than the circle's radius, an intersection occurs
    local distanceSquared = (distanceX * distanceX) + (distanceY * distanceY)
    return distanceSquared < (cr * cr)
end

function Collision.checkPointInCircle(px, py, cx, cy, cr)
    local dx = px - cx
    local dy = py - cy
    return dx * dx + dy * dy <= cr * cr
end

-- Add the clampPosition function to keep the player within defined boundaries
function Collision.clampPosition(player, leftBoundary, rightBoundary, topBoundary, bottomBoundary)
    player.x = math.max(leftBoundary, math.min(player.x, rightBoundary))
    player.y = math.max(topBoundary, math.min(player.y, bottomBoundary))
end

return Collision
