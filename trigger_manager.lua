local TriggerManager = {}
TriggerManager.__index = TriggerManager

local Dialog = require("dialog")

function TriggerManager.new(gameState)
    local self = setmetatable({}, TriggerManager)
    self.gameState = gameState

    -- Table of event names to dialog lines.
    self.events = {
        ----------------------------------------------------------------
        startTutorial = {
            { speaker = "Stormlich",  text = "Behold. With W A S D you steer our dark procession across this realm." },
            { speaker = "Stormlich",  text = "Press SPACE to dash. The spell needs a short pause before you may dash again." },
            { speaker = "Stormlich",  text = "Press E to drink from the potion. Each vanquished foe offers a fresh drop." },
        },
    
        ----------------------------------------------------------------
        autoAttack = {
            { speaker = "Grimreaper", text = "We do the slaying dear traveler. You need only lead our path." },
            { speaker = "Grimreaper", text = "When foes collapse they scatter bright candy. Collect every sweet. Diabetes for the soul." },
        },
    
        ----------------------------------------------------------------
        levelUpExplanation = {
            { speaker = "Stormlich",  text = "Your chosen ability now rests inside the reels at the top of the screen." },
            { speaker = "Emberfiend", text = "Those slots spin all the time my friend. When they land on that shiny icon it erupts without mercy." },
            { speaker = "Grimreaper", text = "There are three ability reels and one buff reel. The gray diamond in the buff reel is a hollow promise and nothing more." },
            { speaker = "Emberfiend", text = "Wildcard links tumbling into the reels can twist the slots into wild combinations. Chase the madness and enjoy the fireworks." },
            { speaker = "Stormlich",  text = "Every second level grants a passive ability. A passive is always active even when the reels show something else." },
        },
    
        ----------------------------------------------------------------
        levelUp = {
            { speaker = "Emberfiend", text = "Ability locked in. Sit back and let the reels decide who burns next." },
        },
    
        ----------------------------------------------------------------
        chestExplanation = {
            { speaker = "Grimreaper", text = "Chests shimmer in and out of existence. Unseal them and relish whatever curiosities leap forth." },
        },
    
        ----------------------------------------------------------------
        soulExplanation = {
            { speaker = "Stormlich",  text = "Souls are a deeper currency than candy. Each soul you gather lifts your soul level higher." },
            { speaker = "Stormlich",  text = "Rise in soul level to unlock talents permanent power and portals to new arenas beyond this shadowed land." },
        },
    
        ----------------------------------------------------------------
        bossExplanation = {
            { speaker = "Emberfiend", text = "The boss awakens from the first heartbeat and grows nastier with every passing moment. Strike before this place starts screaming back." },
            { speaker = "Grimreaper", text = "Defeat the monstrous host to end the level. Fail and your final sigh will echo through eternity." },
        },
    
        ----------------------------------------------------------------
        bossSpawns = {
            { speaker = "Grimreaper", text = "The master of this domain steps onto the stage. Polish your courage or pen your epitaph." },
        },
    }
    
    

    -- Table to record events that have already fired.
    self.fired = {}

    return self
end

-- Public API: try(eventName)
-- If the event has not fired yet and there's dialog for it, start the dialog, pause the game, and mark it fired.
-- Returns true if a dialog began, false otherwise.
function TriggerManager:try(eventName)
    if self.fired[eventName] then
        print("[TriggerManager] Event '" .. eventName .. "' already fired. Skipping.") -- Debug print
        return false
    end

    local dialogLines = self.events[eventName]
    if dialogLines then
        print("[TriggerManager] Firing event '" .. eventName .. "'.") -- Debug print
        self.fired[eventName] = true
        local d = Dialog.new(self.gameState)
        d:start(dialogLines)
        _G.dialog = d  -- Make dialog global so the game loop can update/draw it.
        return true
    else
        print("[TriggerManager] Event '" .. eventName .. "' not found.") -- Debug print
    end

    return false
end

return TriggerManager
