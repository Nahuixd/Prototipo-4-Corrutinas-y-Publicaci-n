local eventos = require("lib.eventos")
local niveles = require("src.niveles")
local dialogos = require("src.dialogos")

local function cargarImagenSegura(ruta)
    -- Comprobación segura para WebGL/HTML5
    local exito_check, tiene_archivo = pcall(function() 
        return love.filesystem and love.filesystem.getInfo and love.filesystem.getInfo(ruta) 
    end)
    
    if exito_check and tiene_archivo then
        local exito, imagen = pcall(love.graphics.newImage, ruta)
        if exito then return imagen end
    end
    return nil
end

local imgVictoria = cargarImagenSegura("assets/victory.png")
local imgDerrota  = cargarImagenSegura("assets/derrota.png")

local UI = {}

-- CORRUTINA: DIÁLOGO DE INTRO
local corrutina_dialogo = nil
local texto_dialogo = ""
local esperando_enter = false

local function iniciar_dialogo_nivel(num)
    local lineas = dialogos[num] or { "NIVEL " .. num }
    corrutina_dialogo = coroutine.create(function ()
        for _, linea in ipairs(lineas) do
            coroutine.yield(linea)
        end
    end)
    local ok, linea = coroutine.resume(corrutina_dialogo)
    if ok and linea then
        texto_dialogo = linea
        esperando_enter = true
    else
        texto_dialogo = ""
        esperando_enter = false
    end
end

local function avanzar_dialogo()
    if coroutine.status(corrutina_dialogo) == "dead" then
        texto_dialogo = ""
        esperando_enter = false
        return false
    end
    local ok, linea = coroutine.resume(corrutina_dialogo)
    if not ok then
        print("Error diálogo: " .. tostring(linea))
        texto_dialogo = ""
        esperando_enter = false
        return false
    end
    if linea then
        texto_dialogo = linea
        esperando_enter = true
        return true
    else
        texto_dialogo = ""
        esperando_enter = false
        return false
    end
end

-- CORRUTINA: CINEMÁTICA DEL JEFE
local corrutina_cinematica = nil
local texto_cinematica = ""
local en_cinematica = false

local function iniciar_cinematica_jefe(juego)
    en_cinematica = true
    texto_cinematica = ""
    corrutina_cinematica = coroutine.create(function ()
        juego.jefe.x = love.graphics.getWidth() / 2 - 50
        juego.jefe.y = -150
        juego.jefe.visible = true

        texto_cinematica = "Algo se acerca..."
        coroutine.yield(1.5)

        texto_cinematica = "¡EL MAESTRO ZOMBIE!"
        while juego.jefe.y < 50 do
            local dt = coroutine.yield()
            juego.jefe.y = juego.jefe.y + 200 * (dt or 0)
            if juego.jefe.y > 50 then juego.jefe.y = 50 end
        end
        texto_cinematica = "¡Prepárate para la batalla!"
        coroutine.yield(1.5)

        texto_cinematica = ""
        en_cinematica = false
    end)
    coroutine.resume(corrutina_cinematica)
end

function UI:init()
    self.pantalla = "menu"
    self.menuOpcion = 1
    self.nivelSeleccionado = 1
    self.vidas = 3
    self.puntos = 0
    self.objetivo = 5
    self.hpJefe = 150
    self.hpJefeMax = 150
    self.tiempo = 0
    self.nivelActualTexto = "NIVEL 1"

    eventos.suscribirse("vida_cambiada", function(d) self.vidas = d.vidas end)
    eventos.suscribirse("puntos_cambiados", function(d) self.puntos = d.puntos; self.objetivo = d.objetivo end)
    eventos.suscribirse("jefe_recibe_dano", function(d) self.hpJefe = d.hp; self.hpJefeMax = d.hp_max end)
    eventos.suscribirse("jefe_derrotado", function() self.pantalla = "victoria" end)
end

function UI:update(dt)
    self.tiempo = self.tiempo + dt
    if en_cinematica and corrutina_cinematica and coroutine.status(corrutina_cinematica) ~= "dead" then
        local ok, err = coroutine.resume(corrutina_cinematica, dt)
        if not ok then
            print("Error cinemática: " .. tostring(err))
            en_cinematica = false
        end
    end
end

function UI:draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    if self.pantalla == "menu" then
        local pulso = 0.8 + 0.2 * math.sin(self.tiempo * 3)
        love.graphics.setColor(1, pulso, 0.2)
        love.graphics.printf("GUERRERO VS ZOMBIES", 0, 100, w, "center")
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Jugar", 0, 250, w, "center")
        love.graphics.printf("Instrucciones", 0, 290, w, "center")
        love.graphics.printf("Salir", 0, 330, w, "center")
        love.graphics.setColor(1, 0.8, 0.2)
        love.graphics.printf(">", w/2 - 100, 250 + (self.menuOpcion - 1) * 40, w, "center")

    elseif self.pantalla == "instrucciones" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("INSTRUCCIONES", 0, 80, w, "center")
        love.graphics.print("Moverse: W, A, S, D o Flechas", 100, 200)
        love.graphics.print("Espadazo (Q): Ataque en área", 100, 240)
        love.graphics.print("Bola de fuego (E): Disparo a distancia", 100, 280)
        love.graphics.print("Botiquines (Rojo): Recupera 1 vida", 100, 320)
        love.graphics.print("Velocidad (Amarillo): +60% Vel por 5s", 100, 360)
        love.graphics.print("ESC: Volver al menú en cualquier momento", 100, 400)
        love.graphics.printf("Presiona ESC o ENTER para volver", 0, h - 100, w, "center")

    elseif self.pantalla == "seleccion_nivel" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("SELECCIONA UN NIVEL", 0, 80, w, "center")
        for i, n in ipairs(niveles) do
            if i == self.nivelSeleccionado then love.graphics.setColor(1, 0.85, 0.2) else love.graphics.setColor(1, 1, 1) end
            love.graphics.printf(n.nombre, 0, 180 + (i * 40), w, "center")
        end

    elseif self.pantalla == "dialogo" then
        love.graphics.setColor(0, 0, 0, 0.65)
        love.graphics.rectangle("fill", 0, 0, w, h)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(self.nivelActualTexto, 0, 80, w, "center")
        love.graphics.setColor(1, 0.95, 0.7)
        love.graphics.printf(texto_dialogo or "", 80, h/2 - 20, w - 160, "center")
        if esperando_enter then
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.printf("[ENTER] continuar", 0, h - 80, w, "center")
        end

    elseif self.pantalla == "cinematica" then
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.rectangle("fill", 0, 0, w, h)
        love.graphics.setColor(1, 0.3, 0.3)
        love.graphics.printf(texto_cinematica or "", 0, h/2 - 20, w, "center")

    elseif self.pantalla == "juego" then
        love.graphics.setColor(1, 0.8, 0.2)
        love.graphics.print(self.nivelActualTexto, 20, 20)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Vidas: " .. self.vidas, 20, 50)
        love.graphics.print("Derrotados: " .. self.puntos .. "/" .. self.objetivo, 20, 80)

        if self.objetivo == 0 then
            love.graphics.setColor(0.2, 0.2, 0.2)
            love.graphics.rectangle("fill", w/2 - 150, 30, 300, 20)
            love.graphics.setColor(0.8, 0.2, 0.2)
            love.graphics.rectangle("fill", w/2 - 150, 30, (self.hpJefe / self.hpJefeMax) * 300, 20)
            love.graphics.setColor(1, 1, 1)
            love.graphics.rectangle("line", w/2 - 150, 30, 300, 20)
            love.graphics.printf("JEFE FINAL", 0, 10, w, "center")
        end

    elseif self.pantalla == "derrota" then
        if imgDerrota then
            local iw, ih = imgDerrota:getDimensions()
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(imgDerrota, w/2 - iw/2, h/2 - ih/2 - 50)
        else
            love.graphics.setColor(0.8, 0.1, 0.1)
            love.graphics.printf("¡HAS SIDO DEVORADO!", 0, h/2 - 50, w, "center")
        end
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Presiona R para reintentar o ESC para el Menú", 0, h/2 + 100, w, "center")

    elseif self.pantalla == "victoria" then
        if imgVictoria then
            local iw, ih = imgVictoria:getDimensions()
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(imgVictoria, w/2 - iw/2, h/2 - ih/2 - 70)
        else
            love.graphics.setColor(0.2, 1, 0.2)
            love.graphics.printf("¡NIVEL COMPLETADO!", 0, h/2 - 50, w, "center")
        end
        love.graphics.setColor(1, 1, 1)
        if self.nivelSeleccionado < #niveles then
            love.graphics.printf("Presiona ENTER para ir al SIGUIENTE NIVEL", 0, h/2 + 50, w, "center")
        else
            love.graphics.printf("¡FELICIDADES! Completaste el juego", 0, h/2 + 50, w, "center")
        end
        love.graphics.printf("Presiona R para reintentar o ESC para el Menú", 0, h/2 + 80, w, "center")
    end
end

function UI:keypressed(key, juego)
    if self.pantalla == "menu" then
        if key == "up" then self.menuOpcion = math.max(1, self.menuOpcion - 1)
        elseif key == "down" then self.menuOpcion = math.min(3, self.menuOpcion + 1)
        elseif key == "return" then
            if self.menuOpcion == 1 then self.pantalla = "seleccion_nivel"
            elseif self.menuOpcion == 2 then self.pantalla = "instrucciones"
            elseif self.menuOpcion == 3 then love.event.quit() end
        end

    elseif self.pantalla == "instrucciones" then
        if key == "return" or key == "escape" then self.pantalla = "menu" end

    elseif self.pantalla == "seleccion_nivel" then
        if key == "up" then self.nivelSeleccionado = math.max(1, self.nivelSeleccionado - 1)
        elseif key == "down" then self.nivelSeleccionado = math.min(#niveles, self.nivelSeleccionado + 1)
        elseif key == "return" then
            self.hpJefe = 150
            self.nivelActualTexto = "NIVEL " .. self.nivelSeleccionado
            juego:iniciarNivel(self.nivelSeleccionado)
            self.pantalla = "dialogo"
            iniciar_dialogo_nivel(self.nivelSeleccionado)
        elseif key == "escape" then self.pantalla = "menu" end

    elseif self.pantalla == "dialogo" then
        if key == "return" and esperando_enter then
            local sigue = avanzar_dialogo()
            if not sigue then
                if juego.nivelActual == 5 and juego.jefe then
                    self.pantalla = "cinematica"
                    iniciar_cinematica_jefe(juego)
                else
                    self.pantalla = "juego"
                end
            end
        end

    elseif self.pantalla == "cinematica" then
        if not en_cinematica then
            self.pantalla = "juego"
        end

    elseif self.pantalla == "derrota" then
        if key == "r" then
            self.pantalla = "juego"
            juego:iniciarNivel(juego.nivelActual)
        end

    elseif self.pantalla == "victoria" then
        if key == "r" then
            self.pantalla = "juego"
            juego:iniciarNivel(juego.nivelActual)
        elseif key == "return" then
            if self.nivelSeleccionado < #niveles then
                self.nivelSeleccionado = self.nivelSeleccionado + 1
                self.hpJefe = 150
                self.nivelActualTexto = "NIVEL " .. self.nivelSeleccionado
                juego:iniciarNivel(self.nivelSeleccionado)
                self.pantalla = "dialogo"
                iniciar_dialogo_nivel(self.nivelSeleccionado)
            else
                self.pantalla = "menu"
            end
        end
    end
end

return function()
    local instancia = setmetatable({}, { __index = UI })
    instancia:init()
    return instancia
end