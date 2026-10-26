-- lib/eventos.lua
local eventos = {}
local listeners = {}

function eventos.suscribirse(nombre, funcion)
    if not listeners[nombre] then listeners[nombre] = {} end
    table.insert(listeners[nombre], funcion)
end

function eventos.emitir(nombre, datos)
    if listeners[nombre] then
        for _, f in ipairs(listeners[nombre]) do f(datos or {}) end
    end
end

function eventos.limpiar()
    listeners = {}
end

return eventos