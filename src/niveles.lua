local niveles = {
    -- Aumenté los maxExtra para asegurar que aparezcan suficientes para el objetivo
    { nombre = "Nivel 1: El Bosque", objetivo = 10, maxExtra = 15, velEnemigo = 40, vidaJugador = 3, jefe = false },
    { nombre = "Nivel 2: El Cementerio", objetivo = 15, maxExtra = 20, velEnemigo = 50, vidaJugador = 3, jefe = false },
    { nombre = "Nivel 3: La Ciudad", objetivo = 20, maxExtra = 25, velEnemigo = 60, vidaJugador = 4, jefe = false },
    { nombre = "Nivel 4: El Laboratorio", objetivo = 25, maxExtra = 35, velEnemigo = 70, vidaJugador = 4, jefe = false },
    { nombre = "Nivel 5: El Jefe Final", objetivo = 0, maxExtra = 0, velEnemigo = 0, vidaJugador = 5, jefe = true },
}
return niveles