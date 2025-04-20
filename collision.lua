-- Collision.lua
local Collision = {}
local Config = require("config")  -- Include config module

-- Checks collision between two circles using squared distances.
function Collision.checkCircle(x1, y1, r1, x2, y2, r2)
    if not r1 or not r2 then return false end  -- Skip if radius is missing
    local dx = x1 - x2
    local dy = y1 - y2
    local distanceSquared = dx * dx + dy * dy
    return distanceSquared <= (r1 + r2) * (r1 + r2)
end

-- NEW: Optimized version that returns a boolean using only squared values.
function Collision.checkCircleSquared(x1, y1, r1, x2, y2, r2)
    if not r1 or not r2 then return false end
    local dx = x1 - x2
    local dy = y1 - y2
    local distSq = dx * dx + dy * dy
    local radiusSum = r1 + r2
    return distSq <= radiusSum * radiusSum
end

-- Checks collision between an object and a rectangle.
function Collision.checkObjectCollision(object, x, y, w, h)
    local colType = object.collisionType or "rectangle"
    if colType == "rectangle" then
        -- Use collisionData if available; otherwise, use width/height.
        local objX = object.x or 0
        local objY = object.y or 0
        local objW = (object.collisionData and object.collisionData.w) or object.width or w
        local objH = (object.collisionData and object.collisionData.h) or object.height or h
        return Collision.checkRectangle(objX, objY, objW, objH, x, y, w, h)
    elseif colType == "circle" then
        -- Use collisionData.radius if available; otherwise, half of the width.
        local radius = (object.collisionData and object.collisionData.radius) or ((object.width or 0) / 2)
        local centerX = (object.x or 0) + (object.width or 0) / 2
        local centerY = (object.y or 0) + (object.height or 0) / 2
        return Collision.checkCircleRectangle(centerX, centerY, radius, x, y, w, h)
    else
        return false
    end
end

-- Checks collision between two rectangles.
function Collision.checkRectangle(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 + w1 > x2 and x1 < x2 + w2 and y1 + h1 > y2 and y1 < y2 + h2
end

function Collision.checkRectangleCollision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and x1 + w1 > x2 and y1 < y2 + h2 and y1 + h1 > y2
end

-- Checks collision between a circle and a rectangle.
function Collision.checkCircleRectangle(cx, cy, cr, rx, ry, rw, rh)
    -- Find the closest point in the rectangle to the circle's center.
    local closestX = math.max(rx, math.min(cx, rx + rw))
    local closestY = math.max(ry, math.min(cy, ry + rh))
    -- Calculate the squared distance between the circle's center and this point.
    local distanceX = cx - closestX
    local distanceY = cy - closestY
    local distanceSquared = (distanceX * distanceX) + (distanceY * distanceY)
    return distanceSquared < (cr * cr)
end

-- Checks if a point is inside a circle.
function Collision.checkPointInCircle(px, py, cx, cy, cr)
    local dx = px - cx
    local dy = py - cy
    return dx * dx + dy * dy <= cr * cr
end

-- Add this function to your collision.lua file

function Collision.checkPointInRectangle(pointX, pointY, rectX, rectY, rectWidth, rectHeight)
    return pointX >= rectX and pointX <= rectX + rectWidth and
           pointY >= rectY and pointY <= rectY + rectHeight
end

-- Checks intersection between a line segment and a circle.
function Collision.lineCircle(x1, y1, x2, y2, cx, cy, radius)
    local dx = x2 - x1
    local dy = y2 - y1
    local fx = x1 - cx
    local fy = y1 - cy
    local a = dx * dx + dy * dy
    local b = 2 * (fx * dx + fy * dy)
    local c = (fx * fx + fy * fy) - radius * radius
    local discriminant = b * b - 4 * a * c

    if discriminant < 0 then
        return false, nil  -- No intersection.
    else
        discriminant = math.sqrt(discriminant)
        local t1 = (-b - discriminant) / (2 * a)
        local t2 = (-b + discriminant) / (2 * a)
        if (t1 >= 0 and t1 <= 1) then
            local intersectX = x1 + t1 * dx
            local intersectY = y1 + t1 * dy
            return true, {x = intersectX, y = intersectY}
        end
        if (t2 >= 0 and t2 <= 1) then
            local intersectX = x1 + t2 * dx
            local intersectY = y1 + t2 * dy
            return true, {x = intersectX, y = intersectY}
        end
        return false, nil
    end
end

return Collision
