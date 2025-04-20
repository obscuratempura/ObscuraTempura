-- settings.lua

local Settings = {
    resolution = {width = 800, height = 600},
    fullscreen = false,
    musicVolume = 1.0,
    effectsVolume = 1.0,
    controls = {
        esc = "escape",
        talents = "t",
        equipment = "e",
        up = "w",
        down = "s",
        left = "a",
        right = "d",
        confirm = "return"
    },

    availableResolutions = {
        {width = 800, height = 600},
        {width = 1024, height = 768},
        {width = 1280, height = 720},
        {width = 1280, height = 800},
        {width = 1366, height = 768},
        {width = 1440, height = 900},
        {width = 1600, height = 900},
        {width = 1920, height = 1080}
    }
}

local previousResolution = {
    width = Settings.resolution.width,
    height = Settings.resolution.height,
    fullscreen = Settings.fullscreen
}

function Settings.setResolution(width, height, fullscreen)
    previousResolution.width = Settings.resolution.width
    previousResolution.height = Settings.resolution.height
    previousResolution.fullscreen = Settings.fullscreen

    Settings.resolution.width = width
    Settings.resolution.height = height
    Settings.fullscreen = fullscreen

    love.window.setMode(width, height, {fullscreen = fullscreen})
    print("Resolution changed to:", width.."x"..height, "Fullscreen:", fullscreen)
end

function Settings.revertResolution()
    Settings.resolution.width = previousResolution.width
    Settings.resolution.height = previousResolution.height
    Settings.fullscreen = previousResolution.fullscreen
    love.window.setMode(Settings.resolution.width, Settings.resolution.height, {fullscreen = Settings.fullscreen})
    print("Resolution reverted to:", Settings.resolution.width.."x"..Settings.resolution.height, "Fullscreen:", Settings.fullscreen)
end

function Settings.confirmResolution()
    previousResolution.width = Settings.resolution.width
    previousResolution.height = Settings.resolution.height
    previousResolution.fullscreen = Settings.fullscreen
    print("Resolution confirmed.")
end

function Settings.setMusicVolume(vol)
    Settings.musicVolume = math.max(0, math.min(vol, 1))
    print("Music volume set to:", math.floor(Settings.musicVolume * 100).."%")
    if sounds and sounds.musicSources then
        for _, src in ipairs(sounds.musicSources) do
            src:setVolume(Settings.musicVolume)
        end
    end
end

function Settings.setEffectsVolume(vol)
    Settings.effectsVolume = math.max(0, math.min(vol, 1))
    print("Effects volume set to:", math.floor(Settings.effectsVolume * 100).."%")
    if sounds and sounds.effectSources then
        for _, src in ipairs(sounds.effectSources) do
            src:setVolume(Settings.effectsVolume)
        end
    end
end

function Settings.rebindControl(action, newKey)
    if Settings.controls[action] then
        print("Rebound", action, "from", Settings.controls[action], "to", newKey)
        Settings.controls[action] = newKey
    end
end

return Settings
