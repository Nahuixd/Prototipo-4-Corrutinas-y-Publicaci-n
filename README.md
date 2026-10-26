--README.md

# Guerrero vs Zombies — TP3 con corrutinas

Juego de acción 2D con LÖVE 11.4. Se añadieron **cuatro patrones de corrutina** sobre el juego base:

| Patrón | Archivo | Descripción |
|---|---|---|
| Productor-consumidor | `src/ui.lua` | Diálogo de intro por nivel: la corrutina produce líneas, ENTER las consume. |
| Guion temporal | `src/ui.lua` | Cinemática de aparición del jefe en el nivel 5. |
| FSM con `wait(dt)` | `src/jefe.lua` | El jefe alterna 3 fases según su HP, con esperas basadas en `dt`. |
| Iterador `coroutine.wrap` | `src/jefe.lua` | Espiral de proyectiles en fase 3. |

## Controles
- WASD / Flechas: mover
- Q: espadazo
- E: bola de fuego
- ENTER: avanzar diálogo
- ESC: menú

## Referencias
- Manual de Referencia de Lua 5.1, §2.11 (co-rutinas)
- Programming in Lua, cap. 9.1–9.3