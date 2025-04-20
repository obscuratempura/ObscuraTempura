local fadeTransition = {
    active = false,
    alpha = 0,
    duration = 0.3 -- 300ms transition
}

function fadeTransition.startTransition(callback)
    if fadeTransition.active then return end
    fadeTransition.active = true
    fadeTransition.alpha = 0
    fadeTransition.fadeIn = false
    fadeTransition.callback = callback
end

function fadeTransition.update(dt)
    if not fadeTransition.active then return end
    
    if fadeTransition.fadeIn then
        fadeTransition.alpha = fadeTransition.alpha - (dt * (1 / fadeTransition.duration))
        if fadeTransition.alpha <= 0 then
            fadeTransition.active = false
            fadeTransition.alpha = 0
        end
    else
        fadeTransition.alpha = fadeTransition.alpha + (dt * (1 / fadeTransition.duration))
        if fadeTransition.alpha >= 1 then
            if fadeTransition.callback then
                fadeTransition.callback()
                fadeTransition.callback = nil
            end
            fadeTransition.fadeIn = true
        end
    end
end

function fadeTransition.draw()
    if fadeTransition.active then
        love.graphics.setColor(0, 0, 0, fadeTransition.alpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1, 1)
    end
end

return fadeTransition