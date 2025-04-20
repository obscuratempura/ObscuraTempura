-- ai.lua

local AI = {}

-- Normalize a value between min and max to a 0-1 scale
function normalize(value, min, max)
    if max - min == 0 then return 0 end
    local norm = (value - min) / (max - min)
    return math.min(math.max(norm, 0), 1)  -- Clamp between 0 and 1
end

-- Main AI update function for a character
-- Check if an enemy is too close (overlapping the character)
function AI.isEnemyOverlapping(character, enemies)
    local overlapDistance = character.radius + 10  -- Adjust overlap distance as needed
    for _, enemy in ipairs(enemies) do
        local dx = enemy.x - character.x
        local dy = enemy.y - character.y
        local distanceSquared = dx * dx + dy * dy
        if distanceSquared <= overlapDistance * overlapDistance then
            return true, enemy  -- Return true and the overlapping enemy
        end
    end
    return false, nil
end

-- Main AI update function for a character
function AI.update(character, dt, context)
    -- Initialize decisionTimer if it doesn't exist
    character.decisionTimer = (character.decisionTimer or 0) - dt

    -- Detect overlapping enemies
    local isOverlapping, overlappingEnemy = AI.isEnemyOverlapping(character, context.enemies)
    if isOverlapping then
        -- Set flee behavior
        AI.moveAwayFromEnemy(character, overlappingEnemy)
        return  -- Prioritize fleeing and skip other actions
    end

    -- Predictive movement: Commit to action for a short time
    if character.currentAction == "retreat" then
        if not character.commitTimer then
            character.commitTimer = 1  -- Commit to retreating for 1 second
        end
        character.commitTimer = character.commitTimer - dt
        if character.commitTimer > 0 then
            -- Continue current retreat action
            AI.maintainOptimalDistance(character, context.teammates, context.enemies)
            return
        else
            character.commitTimer = nil  -- Reset commit timer after duration
        end
    end

    if character.decisionTimer <= 0 then
        -- Reset decision timer
        character.decisionTimer = character.decisionCooldown or 0.7  -- Increased to 0.7 seconds

        -- Gather contextual data
        local nearestEnemy = AI.findNearestEnemy(character, context.enemies)
        local nearestItem = AI.findNearestItem(character, context.items)
        local teammates = context.teammates

        -- Calculate utilities for possible actions
        local utilities = {}

        utilities.approachEnemy = AI.calculateApproachEnemyUtility(character, nearestEnemy)
        utilities.retreat = AI.calculateRetreatUtility(character, nearestEnemy)
        utilities.explore = AI.calculateExploreUtility(character, context.enemies)
        utilities.collectItem = nearestItem and AI.calculateCollectItemUtility(character, nearestItem) or 0
        utilities.assistTeammate = AI.calculateAssistTeammateUtility(character, teammates)

        -- Choose the best action based on utilities
        local bestAction = AI.selectBestAction(utilities)
        character.currentAction = bestAction
    end

    -- Execute the current action and pass context
    local nearestEnemy = AI.findNearestEnemy(character, context.enemies)
    local nearestItem = AI.findNearestItem(character, context.items)
    local teammates = context.teammates

    AI.executeAction(character, character.currentAction, nearestEnemy, nearestItem, teammates, context)
end

-- Execute the chosen action
function AI.executeAction(character, action, enemy, item, teammates, context)
    if action == "retreat" then
        AI.maintainOptimalDistance(character, teammates, context.enemies)
    elseif action == "approachEnemy" and enemy then
        AI.moveToAttackRange(character, enemy)
    elseif action == "explore" then
        AI.explore(character)
    elseif action == "collectItem" and item then
        AI.moveToItem(character, item)
    elseif action == "assistTeammate" then
        AI.moveToTeammate(character, teammates)
    else
        -- Idle or default behavior
        character.destination = nil
        character.isMoving = false  -- Indicate that character is idle
    end
end


-- Retreat logic using weighted average direction
function AI.maintainOptimalDistance(character, teammates, enemies)
    local dangerRadius = 150
    local retreatDirection = AI.calculateRetreatDirection(character, enemies, dangerRadius)

    if retreatDirection then
        AI.avoidTeammates(character, teammates, retreatDirection)
        character.destination = {
            x = character.x + retreatDirection.x * character.speed * 0.5,
            y = character.y + retreatDirection.y * 0.5
        }
    else
        -- Default to maintaining optimal distance from the nearest enemy
        local nearestEnemy = AI.findNearestEnemy(character, enemies)
        if nearestEnemy then
            AI.moveAwayFromEnemy(character, nearestEnemy)
        end
    end
end

-- Calculate weighted retreat direction
function AI.calculateRetreatDirection(character, enemies, dangerRadius)
    local totalDX, totalDY, count = 0, 0, 0

    for _, enemy in ipairs(enemies) do
        local dx = character.x - enemy.x
        local dy = character.y - enemy.y
        local distanceSquared = dx * dx + dy * dy

        if distanceSquared < dangerRadius * dangerRadius then
            local weight = 1 / (distanceSquared + 1)  -- Inverse weighting
            totalDX = totalDX + dx * weight
            totalDY = totalDY + dy * weight
            count = count + 1
        end
    end

    if count > 0 then
        local length = math.sqrt(totalDX * totalDX + totalDY * totalDY)
        return { x = totalDX / length, y = totalDY / length }  -- Normalize
    end

    return nil  -- No close threats
end

-- Avoid teammates during retreat
function AI.avoidTeammates(character, teammates, retreatDirection)
    local repulsionRadius = 30
    for _, teammate in pairs(teammates) do
        if teammate ~= character and teammate.health > 0 then
            local dx = character.x - teammate.x
            local dy = character.y - teammate.y
            local distanceSquared = dx * dx + dy * dy

            if distanceSquared < repulsionRadius * repulsionRadius then
                local repulsionFactor = 1 - math.sqrt(distanceSquared) / repulsionRadius
                retreatDirection.x = retreatDirection.x + dx * repulsionFactor
                retreatDirection.y = retreatDirection.y + dy * repulsionFactor
            end
        end
    end

    local length = math.sqrt(retreatDirection.x^2 + retreatDirection.y^2)
    if length > 0 then
        retreatDirection.x = retreatDirection.x / length
        retreatDirection.y = retreatDirection.y / length
    end
end

-- Find the nearest enemy
function AI.findNearestEnemy(character, enemies)
    local nearestEnemy = nil
    local nearestDistanceSq = math.huge

    for _, enemy in ipairs(enemies) do
        local dx = enemy.x - character.x
        local dy = enemy.y - character.y
        local distanceSq = dx * dx + dy * dy

        if distanceSq < nearestDistanceSq then
            nearestDistanceSq = distanceSq
            nearestEnemy = enemy
        end
    end

    return nearestEnemy, math.sqrt(nearestDistanceSq)
end

-- Find the nearest item
function AI.findNearestItem(character, items)
    if not items or #items == 0 then
        return nil, math.huge  -- No items found
    end

    local nearestItem = nil
    local nearestDistanceSq = math.huge

    for _, item in ipairs(items) do
        local dx = item.x - character.x
        local dy = item.y - character.y
        local distanceSq = dx * dx + dy * dy

        if distanceSq < nearestDistanceSq then
            nearestDistanceSq = distanceSq
            nearestItem = item
        end
    end

    return nearestItem, math.sqrt(nearestDistanceSq)
end

-- Calculate approach enemy utility
function AI.calculateApproachEnemyUtility(character, enemy)
    if not enemy then return 0 end

    local dx = enemy.x - character.x
    local dy = enemy.y - character.y
    local distance = math.sqrt(dx * dx + dy * dy)

    local optimalDistance = character.attackRange * 0.9
    if distance < optimalDistance then return 0 end

    local normalizedDistance = 1 - normalize(distance, optimalDistance, 500)
    local aggressionFactor = character.stats.aggression
    local healthFactor = character.health / character.maxHealth

    return normalizedDistance * aggressionFactor * healthFactor
end

-- Calculate retreat utility
function AI.calculateRetreatUtility(character, enemy)
    if not enemy then return 0 end

    local dx = enemy.x - character.x
    local dy = enemy.y - character.y
    local distance = math.sqrt(dx * dx + dy * dy)

    local dangerousDistance = 150
    local maxRetreatDistance = character.attackRange * 2
    if distance > maxRetreatDistance then return 0 end

    local normalizedDistance = 1 - normalize(distance, dangerousDistance, maxRetreatDistance)
    local healthFactor = 1 - (character.health / character.maxHealth) + 0.2
    local aggressionFactor = 1 - character.stats.aggression

    return normalizedDistance * healthFactor * aggressionFactor
end

-- Calculate exploration utility
function AI.calculateExploreUtility(character, enemies)
    local enemyProximityFactor = (#enemies == 0) and 1 or 0
    local curiosityFactor = character.stats.curiosity

    return curiosityFactor * enemyProximityFactor
end

-- Calculate collect item utility
function AI.calculateCollectItemUtility(character, item)
    if not item then return 0 end

    local dx = item.x - character.x
    local dy = item.y - character.y
    local distance = math.sqrt(dx * dx + dy * dy)
    local normalizedDistance = 1 - normalize(distance, 0, 500)
    local resourcefulnessFactor = character.stats.resourcefulness

    return normalizedDistance * resourcefulnessFactor
end

-- Calculate assist teammate utility
function AI.calculateAssistTeammateUtility(character, teammates)
    local nearestTeammate = nil
    local nearestDistanceSq = math.huge

    for _, teammate in pairs(teammates) do
        if teammate ~= character and teammate.health > 0 then
            local dx = teammate.x - character.x
            local dy = teammate.y - character.y
            local distanceSq = dx * dx + dy * dy

            if distanceSq < nearestDistanceSq then
                nearestDistanceSq = distanceSq
                nearestTeammate = teammate
            end
        end
    end

    if not nearestTeammate then return 0 end

    local distance = math.sqrt(nearestDistanceSq)
    local minAssistDistance = 200
    local maxAssistDistance = 1000

    if distance < minAssistDistance or distance > maxAssistDistance then return 0 end

    local normalizedDistance = normalize(distance, minAssistDistance, maxAssistDistance)
    local teamworkFactor = character.stats.teamwork

    return normalizedDistance * teamworkFactor
end

-- Select the best action
function AI.selectBestAction(utilities)
    local bestAction = nil
    local highestUtility = -math.huge

    for action, utility in pairs(utilities) do
        if utility > highestUtility then
            highestUtility = utility
            bestAction = action
        end
    end

    return bestAction
end

-- Move to attack range
function AI.moveToAttackRange(character, enemy)
    local dx = enemy.x - character.x
    local dy = enemy.y - character.y
    local distance = math.sqrt(dx * dx + dy * dy)
    local desiredDistance = character.attackRange * 0.9

    if distance > desiredDistance then
        local angle = math.atan2(dy, dx)
        character.destination = {
            x = enemy.x - math.cos(angle) * desiredDistance,
            y = enemy.y - math.sin(angle) * desiredDistance
        }
    else
        character.destination = nil
    end
end

-- Move away from enemy
function AI.moveAwayFromEnemy(character, enemy)
    local dx = character.x - enemy.x
    local dy = character.y - enemy.y
    local distance = math.sqrt(dx * dx + dy * dy)
    local desiredDistance = character.attackRange * 0.9

    if distance < desiredDistance then
        local angle = math.atan2(dy, dx)
        local moveDistance = character.speed * 0.5

        character.destination = {
            x = character.x + math.cos(angle) * moveDistance,
            y = character.y + math.sin(angle) * moveDistance
        }
    else
        character.destination = nil
    end
end

-- Explore logic
function AI.explore(character)
    if character.destination and not character.reachedDestination then
        return
    end

    local explorePoint = character.owner.explorationPoint
    character.destination = {
        x = explorePoint.x + math.random(-20, 20),
        y = explorePoint.y + math.random(-20, 20)
    }
    character.reachedDestination = false
end

-- Move to item
function AI.moveToItem(character, item)
    character.destination = {
        x = item.x,
        y = item.y
    }
end

-- Move to teammate
function AI.moveToTeammate(character, teammates)
    local nearestTeammate = nil
    local nearestDistanceSq = math.huge

    for _, teammate in pairs(teammates) do
        if teammate ~= character and teammate.health > 0 then
            local dx = teammate.x - character.x
            local dy = teammate.y - character.y
            local distanceSq = dx * dx + dy * dy

            if distanceSq < nearestDistanceSq then
                nearestDistanceSq = distanceSq
                nearestTeammate = teammate
            end
        end
    end

    if nearestTeammate then
        local distance = math.sqrt(nearestDistanceSq)
        local minAssistDistance = 200

        if distance > minAssistDistance then
            character.destination = {
                x = nearestTeammate.x,
                y = nearestTeammate.y
            }
        else
            character.destination = nil
        end
    else
        character.destination = nil
    end
end

return AI
