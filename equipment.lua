-- Equipment.lua
local Equipment = {}
Equipment.__index = Equipment
local talentSystem = require("talentSystem")

function Equipment.new()
    local self = setmetatable({}, Equipment)
    self.inventory = {}
    self.equipped = {
        chest = nil
    }
    return self
end

function Equipment:addItem(item)
    item.isNew = true  -- Mark the item as new
    if #self.inventory < 20 then
        table.insert(self.inventory, item)
    else
        -- Remove the oldest item (first in the list)
        local removedItem = table.remove(self.inventory, 1)
        table.insert(self.inventory, item)
    end
end

-- The helper function applyItemAffixes is now obsolete since all bonuses are applied via recalc.
--[[
local function applyItemAffixes(item, char, isEquipping)
    -- No longer used.
end
]]

function Equipment:equipItem(item)
    if item.slot ~= "chest" then
        return
    end

    -- Unequip existing chest item:
    if self.equipped.chest then
        self:unequipItem("chest")
    end

    self.equipped.chest = item
    print("Equipped chest item:", item.name)
    
    -- Update player's equipment reference:
    Overworld.player.equipment = self

    -- Recalculate all stats (health, speed, etc.) via recalc.
    if Overworld.player then
        Overworld.player:recalculateStats()
        if Overworld.statsWindow then
            Overworld.statsWindow:updateFromPlayer(Overworld.player)
        end
    end
end

function Equipment:unequipItem(slot)
    if slot == "chest" and self.equipped.chest then
        local item = self.equipped.chest
        self.equipped.chest = nil
        print("Unequipped chest item:", item.name)

        if Overworld.player then
            local p = Overworld.player
            p:recalculateStats()
            talentSystem.applyTalentsToPlayer(p)
            if Overworld.statsWindow and Overworld.statsWindow.visible then
                Overworld.statsWindow:updateFromPlayer(p)
            end
        end
    else
        print("Warning: No item equipped in slot:", slot)
    end
end

return Equipment
