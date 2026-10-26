local Item = {}

function Item:init(x, y, tipo)
    self.x, self.y = x, y
    self.ancho, self.alto = 24, 24
    self.tipo = tipo or "vida" -- "vida" o "velocidad"
    self.activo = true
    self.tiempo = 0
end

function Item:update(dt)
    self.tiempo = self.tiempo + dt * 5
end

function Item:draw()
    if not self.activo then return end
    local flote = math.sin(self.tiempo) * 5
    
    if self.tipo == "vida" then
        -- Botiquín rojo con cruz blanca
        love.graphics.setColor(0.8, 0.1, 0.1)
        love.graphics.rectangle("fill", self.x - 12, self.y - 12 + flote, 24, 24)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", self.x - 3, self.y - 8 + flote, 6, 16)
        love.graphics.rectangle("fill", self.x - 8, self.y - 3 + flote, 16, 6)
    else
        -- Poción de velocidad (Rayo amarillo)
        love.graphics.setColor(0.9, 0.8, 0.1)
        love.graphics.rectangle("fill", self.x - 10, self.y - 12 + flote, 20, 24)
        love.graphics.setColor(0.1, 0.1, 0.1)
        -- Un dibujito de rayo
        love.graphics.polygon("fill", 
            self.x + 2, self.y - 8 + flote, 
            self.x - 6, self.y + 2 + flote, 
            self.x - 1, self.y + 2 + flote, 
            self.x - 4, self.y + 10 + flote, 
            self.x + 6, self.y - 2 + flote, 
            self.x + 1, self.y - 2 + flote
        )
    end
end

return function(x, y, tipo)
    local instancia = setmetatable({}, { __index = Item })
    instancia:init(x, y, tipo)
    return instancia
end