function love.conf(t)
    t.console = true  -- Enables a separate console window on Windows

    -- Set the window properties
    t.window = {
        title = "Vector Souls",  -- Title of the game window
        width = 1200,            -- Initial width of the window
        height = 720,           -- Initial height of the window
        resizable = true,       -- Allow window resizing
        fullscreen = false,     -- Start in fullscreen mode (optional)
        vsync = 1,              -- Enable vertical sync (1 = enabled, 0 = disabled)
        minwidth = 800,         -- Minimum window width
        minheight = 600         -- Minimum window height
    }
end
