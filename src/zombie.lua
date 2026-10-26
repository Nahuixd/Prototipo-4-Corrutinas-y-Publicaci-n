local Enemigo = require("src.enemigo")
local Zombie = setmetatable({}, { __index = Enemigo })

function Zombie:init(x, y, config)
    Enemigo.init(self, x, y, {
        ancho = 24, -- Hice la hitbox más chica que el jugador
        alto = 36, 
        velocidad = config.velocidad or 30,
        vida = 1, 
        sprite = config.sprite, 
        origen_x = 12, 
        origen_y = 18,
    })
end

function Zombie:update(dt, jugador)
    if not self.activo or not jugador then return end
    local dx = jugador.x - self.x
    local dy = jugador.y - self.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist > 0 then
        self.x = self.x + (dx / dist) * self.velocidad * dt
        self.y = self.y + (dy / dist) * self.velocidad * dt
    end
end

function Zombie:draw()
    if not self.activo then return end
    if self.sprite then
        local sw, sh = self.sprite:getWidth(), self.sprite:getHeight()
        -- Escala automática para que el zombie mida lo que dice su hitbox
        local escala = self.alto / sh
        love.graphics.draw(self.sprite, self.x, self.y, 0, escala, escala, self.origen_x, self.origen_y)
    else
        love.graphics.setColor(0.2, 0.8, 0.2)
        love.graphics.rectangle("fill", self.x - self.ancho/2, self.y - self.alto/2, self.ancho, self.alto)
        love.graphics.setColor(1, 1, 1)
    end
end

return function(x, y, config)
    local instancia = setmetatable({}, { __index = Zombie })
    instancia:init(x, y, config)
    return instancia
end