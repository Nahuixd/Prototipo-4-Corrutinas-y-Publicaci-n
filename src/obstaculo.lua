local eventos = require("lib.eventos")

local Jugador = {}

function Jugador:init(x, y)
    self.x, self.y = x, y
    self.ancho, self.alto = 32, 48
    self.velocidad = 250
    self.vida, self.vida_max = 3, 3
    self.derrotados = 0
    self.objetivo = 5
    self.invulnerable = 0
    self.sprite = nil
    
    self.balas = {}
    self.cooldown_disparo = 0
    self.cooldown_espada = 0
    self.espada_activa = 0
    
    -- Efecto de velocidad
    self.tiempo_velocidad = 0
    self.mensaje_tiempo = 0
    self.mensaje_texto = ""
end

function Jugador:update(dt)
    if self.cooldown_disparo > 0 then self.cooldown_disparo = self.cooldown_disparo - dt end
    if self.cooldown_espada > 0 then self.cooldown_espada = self.cooldown_espada - dt end
    if self.espada_activa > 0 then self.espada_activa = self.espada_activa - dt end
    if self.tiempo_velocidad > 0 then self.tiempo_velocidad = self.tiempo_velocidad - dt end
    if self.mensaje_tiempo > 0 then self.mensaje_tiempo = self.mensaje_tiempo - dt end

    local dx, dy = 0, 0
    if love.keyboard.isDown("a", "left")  then dx = dx - 1 end
    if love.keyboard.isDown("d", "right") then dx = dx + 1 end
    if love.keyboard.isDown("w", "up")    then dy = dy - 1 end
    if love.keyboard.isDown("s", "down")  then dy = dy + 1 end

    if dx ~= 0 and dy ~= 0 then
        local inv = 1 / math.sqrt(2)
        dx, dy = dx * inv, dy * inv
    end
    
    local vel_actual = self.velocidad
    if self.tiempo_velocidad > 0 then vel_actual = vel_actual * 1.6 end -- 60% más rápido
    
    self.x = self.x + dx * vel_actual * dt
    self.y = self.y + dy * vel_actual * dt

    self.x = math.max(self.ancho/2, math.min(love.graphics.getWidth() - self.ancho/2, self.x))
    self.y = math.max(self.alto/2, math.min(love.graphics.getHeight() - self.alto/2, self.y))

    if self.invulnerable > 0 then self.invulnerable = self.invulnerable - dt end

    for i = #self.balas, 1, -1 do
        local b = self.balas[i]
        b.x = b.x + b.vx * dt
        b.y = b.y + b.vy * dt
        b.vida = b.vida - dt
        if b.x < 0 or b.x > love.graphics.getWidth() or b.y < 0 or b.y > love.graphics.getHeight() or b.vida <= 0 then
            table.remove(self.balas, i)
        end
    end
end

function Jugador:dispararFuego()
    if self.cooldown_disparo > 0 then return end
    self.cooldown_disparo = 0.4
    
    local dirX, dirY = 0, -1
    if love.keyboard.isDown("a", "left") then dirX = -1; dirY = 0 end
    if love.keyboard.isDown("d", "right") then dirX = 1; dirY = 0 end
    if love.keyboard.isDown("w", "up") then dirX = 0; dirY = -1 end
    if love.keyboard.isDown("s", "down") then dirX = 0; dirY = 1 end

    table.insert(self.balas, { x = self.x, y = self.y, vx = dirX * 500, vy = dirY * 500, vida = 1.5, radio = 8 })
end

function Jugador:espadazo(enemigos, jefe)
    if self.cooldown_espada > 0 then return end
    self.cooldown_espada = 0.8
    self.espada_activa = 0.2
    
    local rango = 100
    for i = #enemigos, 1, -1 do
        local e = enemigos[i]
        local dist = math.sqrt((e.x - self.x)^2 + (e.y - self.y)^2)
        if dist < rango then
            e:recibirDano(1)
            if not e.activo then
                table.remove(enemigos, i)
                self.derrotados = self.derrotados + 1
                eventos.emitir("puntos_cambiados", { puntos = self.derrotados, objetivo = self.objetivo })
            end
        end
    end
    if jefe and jefe.activo then
        local dist = math.sqrt((jefe.x + 50 - self.x)^2 + (jefe.y + 50 - self.y)^2)
        if dist < rango + 30 then jefe:recibirDano(10) end
    end
end

-- Función para curarse
function Jugador:curar()
    if self.vida < self.vida_max then
        self.vida = self.vida + 1
        eventos.emitir("vida_cambiada", { vidas = self.vida })
        self.mensaje_texto = "¡+1 Vida!"
        self.mensaje_tiempo = 1.5
    else
        self.mensaje_texto = "¡Vida al Máximo!"
        self.mensaje_tiempo = 1.5
    end
end

-- Función para agarrar velocidad
function Jugador:activarVelocidad()
    self.tiempo_velocidad = 5.0 -- 5 segundos de velocidad
    self.mensaje_texto = "¡Velocidad Extra!"
    self.mensaje_tiempo = 1.5
end

function Jugador:recibirDano(cantidad)
    if self.invulnerable > 0 then return end
    self.vida = self.vida - cantidad
    self.invulnerable = 1.0
    eventos.emitir("vida_cambiada", { vidas = self.vida })
    if self.vida <= 0 then eventos.emitir("jugador_muerto", {}) end
end

function Jugador:draw()
    if self.invulnerable > 0 and math.floor(self.invulnerable * 10) % 2 == 0 then return end

    if self.sprite then
        local sw, sh = self.sprite:getWidth(), self.sprite:getHeight()
        local escala = self.alto / sh 
        love.graphics.draw(self.sprite, self.x, self.y, 0, escala, escala, sw/2, sh/2)
    else
        love.graphics.setColor(0.2, 0.8, 1.0)
        love.graphics.rectangle("fill", self.x - self.ancho/2, self.y - self.alto/2, self.ancho, self.alto)
        love.graphics.setColor(1, 1, 1)
    end

    if self.espada_activa > 0 then
        love.graphics.setColor(1, 1, 0, self.espada_activa * 5)
        love.graphics.circle("line", self.x, self.y, 100)
        love.graphics.setColor(1, 1, 1)
    end

    for _, b in ipairs(self.balas) do
        love.graphics.setColor(1, 0.4, 0)
        love.graphics.circle("fill", b.x, b.y, b.radio)
        love.graphics.setColor(1, 1, 0)
        love.graphics.circle("fill", b.x, b.y, b.radio * 0.5)
    end
    love.graphics.setColor(1, 1, 1)

    -- Dibujar el mensaje verde flotante (¡+1 Vida!)
    if self.mensaje_tiempo > 0 then
        love.graphics.setColor(0.2, 1, 0.2)
        love.graphics.printf(self.mensaje_texto, self.x - 50, self.y - 60, 100, "center")
        love.graphics.setColor(1, 1, 1)
    end
end

return function(x, y)
    local instancia = setmetatable({}, { __index = Jugador })
    instancia:init(x, y)
    return instancia
end