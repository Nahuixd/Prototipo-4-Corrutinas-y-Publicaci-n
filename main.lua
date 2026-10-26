local eventos = require("lib.eventos")
local niveles = require("src.niveles")
local UI = require("src.ui")
local Jefe = require("src.jefe")
local Jugador = require("src.jugador")
local Zombie = require("src.zombie")
local Item = require("src.item")
local Obstaculo = require("src.obstaculo")

local function cargarImagen(ruta, r, g, b, w, h)
    if love.filesystem.getInfo(ruta) then return love.graphics.newImage(ruta) end
    w, h = w or 32, h or 32
    local canvas = love.graphics.newCanvas(w, h)
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    love.graphics.setColor(r, g, b)
    love.graphics.rectangle("fill", 0, 0, w, h)
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1)
    return canvas
end

local function cargarSonido(ruta, tipo)
    tipo = tipo or "static"
    if love.filesystem.getInfo(ruta) then
        local exito, source = pcall(love.audio.newSource, ruta, tipo)
        if exito then return source end
    end
    return nil
end

local imgJugador = cargarImagen("assets/jugador.png", 0.2, 0.8, 1.0, 32, 48)
local imgZombie  = cargarImagen("assets/zombie.png", 0.2, 0.8, 0.2, 32, 48)

local sfxDisparo = cargarSonido("Explosion.wav") 
local sfxEspada  = cargarSonido("espada.wav")
local sfxVictoria = cargarSonido("Efecto de sonido de trompetas HD.wav")
local sfxDerrota = cargarSonido("Explosion.wav") 

local juego = {
    ui = UI(),
    jugador = nil,
    enemigos = {},
    items = {},
    obstaculos = {},
    jefe = nil,
    nivelActual = 1
}

eventos.suscribirse("jefe_invoca_zombie", function(datos)
    if juego.jugador then
        local z = Zombie(datos.x, datos.y, { velocidad = 40, sprite = imgZombie })
        table.insert(juego.enemigos, z)
    end
end)

function juego:crearMapa(num)
    self.obstaculos = {}
    if num == 1 then
        table.insert(self.obstaculos, Obstaculo(200, 200, 60, 60, {0.2, 0.5, 0.2}))
        table.insert(self.obstaculos, Obstaculo(700, 400, 80, 80, {0.2, 0.5, 0.2}))
        table.insert(self.obstaculos, Obstaculo(500, 150, 100, 50, {0.2, 0.5, 0.2}))
    elseif num == 2 then
        for i = 1, 5 do
            table.insert(self.obstaculos, Obstaculo(math.random(100, 900), math.random(100, 500), 40, 60, {0.5, 0.5, 0.5}))
        end
    elseif num == 3 then
        table.insert(self.obstaculos, Obstaculo(150, 150, 150, 150, {0.6, 0.4, 0.2}))
        table.insert(self.obstaculos, Obstaculo(700, 150, 150, 150, {0.6, 0.4, 0.2}))
        table.insert(self.obstaculos, Obstaculo(400, 400, 200, 100, {0.6, 0.4, 0.2}))
    elseif num == 4 then
        table.insert(self.obstaculos, Obstaculo(100, 300, 100, 100, {0.2, 0.4, 0.8}))
        table.insert(self.obstaculos, Obstaculo(800, 300, 100, 100, {0.2, 0.4, 0.8}))
        table.insert(self.obstaculos, Obstaculo(450, 100, 100, 100, {0.2, 0.4, 0.8}))
    end
end

function juego:iniciarNivel(num)
    self.nivelActual = num
    local config = niveles[num]
    
    self.jugador = Jugador(love.graphics.getWidth()/2, love.graphics.getHeight() - 100)
    self.jugador.objetivo = config.objetivo
    self.jugador.vida = config.vidaJugador
    self.jugador.vida_max = config.vidaJugador
    self.jugador.sprite = imgJugador
    
    self.enemigos = {}
    self.items = {}
    
    self:crearMapa(num)
    
    self.spawnTimer = 0
    self.spawnInterval = 1 
    self.extraEnemiesSpawned = 0
    self.maxExtra = config.maxExtra
    self.velEnemigo = config.velEnemigo
    
    if config.jefe then
        self.jefe = Jefe(love.graphics.getWidth()/2 - 50, 50, imgZombie)
        self.jugador.objetivo = 0
    else
        self.jefe = nil
        for i = 1, 5 do self:crearEnemigo() end
    end
    
    for i = 1, 3 do self:crearItem("vida") end
    
    eventos.emitir("puntos_cambiados", { puntos = 0, objetivo = self.jugador.objetivo })
    eventos.emitir("vida_cambiada", { vidas = self.jugador.vida })
end

function juego:reiniciar()
    eventos.limpiar()
    self.jugador = nil
    self.enemigos = {}
    self.items = {}
    self.obstaculos = {}
    self.jefe = nil
    self.ui.pantalla = "menu"
end

function juego:crearEnemigo(x, y)
    x = x or math.random(50, love.graphics.getWidth() - 50)
    y = y or math.random(50, love.graphics.getHeight() - 200)
    local z = Zombie(x, y, { velocidad = self.velEnemigo, sprite = imgZombie })
    table.insert(self.enemigos, z)
end

function juego:crearItem(tipo)
    local x, y, colision
    local intentos = 0
    repeat
        intentos = intentos + 1
        x = math.random(50, love.graphics.getWidth() - 50)
        y = math.random(50, love.graphics.getHeight() - 100)
        colision = false
        for _, obs in ipairs(self.obstaculos) do
            if x > obs.x and x < obs.x + obs.ancho and y > obs.y and y < obs.y + obs.alto then
                colision = true
                break
            end
        end
    until not colision or intentos > 20
    
    table.insert(self.items, Item(x, y, tipo or "vida"))
end

function juego:chocaConObstaculo(x, y, w, h)
    for _, obs in ipairs(self.obstaculos) do
        if x < obs.x + obs.ancho and x + w > obs.x and y < obs.y + obs.alto and y + h > obs.y then
            return true
        end
    end
    return false
end

function juego:update(dt)
    self.ui:update(dt)
    if self.ui.pantalla ~= "juego" then return end
    
    if self.jugador then
        local oldX, oldY = self.jugador.x, self.jugador.y
        self.jugador:update(dt)
        if self:chocaConObstaculo(self.jugador.x - self.jugador.ancho/2, self.jugador.y - self.jugador.alto/2, self.jugador.ancho, self.jugador.alto) then
            self.jugador.x = oldX
            self.jugador.y = oldY
        end
    end
    
    if self.jugador then
        for i = #self.jugador.balas, 1, -1 do
            local b = self.jugador.balas[i]
            local bala_borrada = false
            for j = #self.enemigos, 1, -1 do
                local e = self.enemigos[j]
                local dist = math.sqrt((e.x - b.x)^2 + (e.y - b.y)^2)
                if dist < 20 + b.radio then
                    table.remove(self.enemigos, j)
                    table.remove(self.jugador.balas, i)
                    self.jugador.derrotados = self.jugador.derrotados + 1
                    eventos.emitir("puntos_cambiados", { puntos = self.jugador.derrotados, objetivo = self.jugador.objetivo })
                    if sfxDisparo then sfxDisparo:clone():play() end
                    bala_borrada = true
                    break
                end
            end
            if not bala_borrada and self.jefe and self.jefe.activo then
                local dist = math.sqrt((self.jefe.x + 50 - b.x)^2 + (self.jefe.y + 50 - b.y)^2)
                if dist < 50 + b.radio then
                    self.jefe:recibirDano(5)
                    table.remove(self.jugador.balas, i)
                    if sfxDisparo then sfxDisparo:clone():play() end
                end
            end
        end
    end
    
    for i = #self.enemigos, 1, -1 do
        local e = self.enemigos[i]
        local oldEx, oldEy = e.x, e.y
        e:update(dt, self.jugador)
        
        if self:chocaConObstaculo(e.x - e.ancho/2, e.y - e.alto/2, e.ancho, e.alto) then
            e.x = oldEx
            e.y = oldEy
        end

        if self.jugador and e.activo then
            local dist = math.sqrt((e.x - self.jugador.x)^2 + (e.y - self.jugador.y)^2)
            if dist < (e.ancho/2 + self.jugador.ancho/2) then
                self.jugador:recibirDano(1)
                table.remove(self.enemigos, i)
            end
        end
    end
    
    for i = #self.items, 1, -1 do
        local it = self.items[i]
        it:update(dt)
        if self.jugador then
            local dist = math.sqrt((it.x - self.jugador.x)^2 + (it.y - self.jugador.y)^2)
            if dist < 30 then
                if it.tipo == "vida" then self.jugador:curar() 
                else self.jugador:activarVelocidad() end
                table.remove(self.items, i)
            end
        end
    end
    
    if self.jefe then 
        self.jefe:update(dt, self.jugador) 
        if self.jefe.activo and self.jugador then
            local dist = math.sqrt((self.jefe.x + 50 - self.jugador.x)^2 + (self.jefe.y + 50 - self.jugador.y)^2)
            if dist < 50 then
                self.jugador:recibirDano(2) 
            end
        end

        -- NUEVO: Colisiones de los proyectiles del jefe con el jugador
        if self.jefe.proyectiles and self.jugador then
            for i = #self.jefe.proyectiles, 1, -1 do
                local p = self.jefe.proyectiles[i]
                local dist = math.sqrt((p.x - self.jugador.x)^2 + (p.y - self.jugador.y)^2)
                if dist < 20 then
                    self.jugador:recibirDano(1)
                    table.remove(self.jefe.proyectiles, i)
                end
            end
        end
    end
    
    if self.nivelActual < 5 then
        self.spawnTimer = self.spawnTimer + dt
        if self.spawnTimer >= self.spawnInterval then
            self.spawnTimer = 0
            if (self.jugador.derrotados + #self.enemigos) < self.jugador.objetivo then
                self:crearEnemigo()
            end
            if math.random() < 0.2 then
                local tipoItem = "vida"
                if math.random() < 0.5 then tipoItem = "velocidad" end
                self:crearItem(tipoItem)
            end
        end
    end
    
    if self.jugador and self.jugador.vida <= 0 then
        self.ui.pantalla = "derrota"
        if sfxDerrota then sfxDerrota:clone():play() end
    end

    if self.nivelActual < 5 and self.jugador and self.jugador.objetivo > 0 and self.jugador.derrotados >= self.jugador.objetivo then
        self.ui.pantalla = "victoria"
        if sfxVictoria then sfxVictoria:clone():play() end
    end
end

function juego:draw()
    love.graphics.clear(0.08, 0.08, 0.12)
    
    if self.ui.pantalla == "juego" or self.ui.pantalla == "cinematica" then
        for _, obs in ipairs(self.obstaculos) do obs:draw() end
        for _, it in ipairs(self.items) do it:draw() end
        if self.jugador then self.jugador:draw() end
        for _, e in ipairs(self.enemigos) do e:draw() end
        if self.jefe then self.jefe:draw() end
    end
    
    self.ui:draw()
end

function love.load()
    love.graphics.setBackgroundColor(0.08, 0.08, 0.12)
    love.graphics.setFont(love.graphics.newFont(20))
    love.math.setRandomSeed(os.time())
end

function love.update(dt) juego:update(dt) end
function love.draw() juego:draw() end

function love.keypressed(key)
    if key == "escape" then
        if juego.ui.pantalla == "juego" or juego.ui.pantalla == "derrota" or juego.ui.pantalla == "victoria" then
            juego:reiniciar() 
            return
        end
    end

    if juego.ui.pantalla == "juego" then
        if key == "e" and juego.jugador then
            juego.jugador:dispararFuego()
        end
        if key == "q" and juego.jugador then
            juego.jugador:espadazo(juego.enemigos, juego.jefe)
            if sfxEspada then sfxEspada:clone():play() end
        end
    end
    juego.ui:keypressed(key, juego)
end