function love.conf(t)
    t.identity = "guerrero_vs_zombies_tp3"
    t.version = "11.4"
    
    t.window.title     = "Guerrero Vs Zombies - TP3 (Eventos)"
    t.window.width     = 1040
    t.window.height    = 720
    t.window.resizable = false
    t.window.vsync     = 1
    
    t.modules.physics = false
    t.modules.joystick = false
end