local eventos = require("lib.eventos")

local Enemigo = {}

function Enemigo:init(x, y, config)
    self.x = x
    self.y = y
    self.ancho = config.ancho or 40
    self.alto = config.alto or 40
    self.velocidad = config.velocidad or 30
    self.vida = config.vida or 1
    self.sprite = config.sprite
    self.origen_x = config.origen_x or self.ancho / 2
    self.origen_y = config.origen_y or self.alto / 2
    self.activo = true
end

function Enemigo:recibirDano(cantidad)
    self.vida = self.vida - cantidad
    if self.vida <= 0 then
        self.activo = false
        eventos.emitir("enemigo_muerto", { x = self.x, y = self.y })
    end
end

function Enemigo:getHitbox()
    return { x = self.x - self.origen_x, y = self.y - self.origen_y, ancho = self.ancho, alto = self.alto }
end

function Enemigo:draw()
    if self.sprite then
        love.graphics.draw(self.sprite, self.x, self.y, 0, 1, 1, self.origen_x, self.origen_y)
    end
end

return Enemigo