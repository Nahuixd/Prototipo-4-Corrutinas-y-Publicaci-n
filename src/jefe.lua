local eventos = require("lib.eventos")

local Jefe = {}

-- CORRUTINA: wait con dt
local function wait(self, segundos)
    local t = 0
    while t < segundos do
        if self.hp <= 0 then return end
        t = t + (coroutine.yield() or 0)
    end
end

-- CORRUTINA: iterador de espiral
local function espiral(n, radio_max)
    local co = coroutine.wrap(function ()
        for i = 1, n do
            local ang = i * 0.7
            local r = (i / n) * radio_max
            coroutine.yield(math.cos(ang) * r, math.sin(ang) * r)
        end
    end)
    return co
end

function Jefe:init(x, y, sprite)
    self.x, self.y = x, y
    self.ancho, self.alto = 100, 100
    self.velocidad = 25
    self.hp = 150
    self.hp_maximo = 150
    self.activo = true
    self.visible = true
    self.sprite = sprite

    self.proyectiles = {}
    self.rutina = coroutine.create(function () self:ejecutar_patrones() end)
    self.fase_actual = 1
end

-- Lógica de las fases del jefe
function Jefe:ejecutar_patrones()
    wait(self, 1) -- Margen de inicio

    while self.hp > 0 do
        if self.hp > 75 then
            self.fase_actual = 1
            wait(self, 3)
            if self.hp > 0 then
                eventos.emitir("jefe_invoca_zombie", { x = self.x + self.ancho/2, y = self.y + self.alto/2 })
            end
        elseif self.hp > 25 then
            self.fase_actual = 2
            self.dash_tiempo = 0.6 -- Prepara el dash
            wait(self, 0.6)
            self.dash_tiempo = 0
            wait(self, 0.4)
            eventos.emitir("jefe_invoca_zombie", { x = self.x + self.ancho/2, y = self.y + self.alto/2 })
            wait(self, 1.2)
        else
            self.fase_actual = 3
            self:disparar_espiral(10)
            wait(self, 0.3)
            if self.hp > 0 then self:disparar_espiral(10) end
            wait(self, 1.0)
            eventos.emitir("jefe_invoca_zombie", { x = self.x + self.ancho/2, y = self.y + self.alto/2 })
            wait(self, 1.0)
        end
    end
end

function Jefe:disparar_espiral(n)
    local it = espiral(n, 1)
    for i = 1, n do
        local dx, dy = it()
        if dx then
            table.insert(self.proyectiles, {
                x = self.x + self.ancho/2,
                y = self.y + self.alto/2,
                vx = dx * 180,
                vy = dy * 180,
                vida = 3,
            })
        end
    end
end

function Jefe:update(dt, jugador)
    if not self.activo then return end

    -- Actualizar la FSM
    if self.rutina and coroutine.status(self.rutina) ~= "dead" then
        local ok, err = coroutine.resume(self.rutina, dt)
        if not ok then print("Error FSM jefe: " .. tostring(err)) end
    end

    -- Persecución
    if jugador then
        local dx = jugador.x - (self.x + self.ancho/2)
        local dy = jugador.y - (self.y + self.alto/2)
        local dist = math.sqrt(dx * dx + dy * dy)
        if dist > 0 then
            local vel = self.velocidad
            if self.dash_tiempo and self.dash_tiempo > 0 then
                vel = self.velocidad * 4
                self.dash_tiempo = self.dash_tiempo - dt
            end
            self.x = self.x + (dx / dist) * vel * dt
            self.y = self.y + (dy / dist) * vel * dt
        end
    end

    -- Actualizar proyectiles
    for i = #self.proyectiles, 1, -1 do
        local p = self.proyectiles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vida = p.vida - dt
        local fuera = p.x < -50 or p.x > love.graphics.getWidth() + 50 or p.y < -50 or p.y > love.graphics.getHeight() + 50
        if p.vida <= 0 or fuera then
            table.remove(self.proyectiles, i)
        end
    end
end

function Jefe:recibirDano(cantidad)
    if not self.activo then return end
    self.hp = math.max(0, self.hp - cantidad)
    eventos.emitir("jefe_recibe_dano", { hp = self.hp, hp_max = self.hp_maximo })

    if self.hp <= 0 then
        self.activo = false
        eventos.emitir("jefe_derrotado", {})
    end
end

function Jefe:draw()
    if not self.activo or not self.visible then return end

    if self.hp > 75 then love.graphics.setColor(1, 1, 1)
    else love.graphics.setColor(1, 0.5, 0.5) end

    if self.sprite then
        local sw, sh = self.sprite:getWidth(), self.sprite:getHeight()
        local escala = self.alto / sh
        love.graphics.draw(self.sprite, self.x + self.ancho/2, self.y + self.alto/2, 0, escala * 2, escala * 2, sw/2, sh/2)
    else
        love.graphics.rectangle("fill", self.x, self.y, self.ancho, self.alto)
    end

    love.graphics.setColor(1, 0.4, 0)
    for _, p in ipairs(self.proyectiles) do
        love.graphics.circle("fill", p.x, p.y, 6)
    end
    love.graphics.setColor(1, 1, 1)
end

return function(x, y, sprite)
    local instancia = setmetatable({}, { __index = Jefe })
    instancia:init(x, y, sprite)
    return instancia
end