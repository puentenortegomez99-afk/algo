-- escolta.lua
-- CC:Androids 1.3.0 | Minecraft 1.20.1
-- Script Maestro: Combate, Autofollow Inteligente, Vehiculos, Owners Dinámicos y Autorecarga

local android = _G.android
local PAUSA = 0.5

-- Lista de owners permitidos (con chapelmussel0 por defecto)
local owners = {
    ["chapelmussel0"] = true
}

local objetivoNombre = "chapelmussel0"
local modoActual = "seguir" -- Modos: "seguir", "vehiculo", "esperar"
local COMBUSTIBLE_MINIMO = 200

-- Funcion auxiliar para esperar tareas del androide
local function esperarTarea()
    sleep(PAUSA)
    local inicio = os.clock()
    while true do
        local tarea = android.currentTask()
        if tarea == "idle" then break end
        if os.clock() - inicio > 10 then break end
        sleep(PAUSA)
    end
end

-- 1. SISTEMA DE AUTORECARGA DE COMBUSTIBLE CON REDSTONE
local function comprobarYRecargar()
    local combustibleActual = android.fuelLevel()
    if combustibleActual and combustibleActual >= COMBUSTIBLE_MINIMO then
        return true
    end

    print(">> Combustible bajo (" .. tostring(combustibleActual) .. "). Buscando redstone...")

    local recargaExitosa = false
    for i = 0, 8 do
        local okEquip = pcall(android.equipSlot, i)
        if okEquip then
            pcall(android.refuel)
            local nuevoCombustible = android.fuelLevel()
            if nuevoCombustible and nuevoCombustible > combustibleActual then
                print(">> ¡Recarga exitosa desde el slot " .. i .. "! Combustible: " .. tostring(nuevoCombustible))
                recargaExitosa = true
                break
            end
        end
    end

    if not recargaExitosa then
        print(">> ¡ADVERTENCIA! No hay redstone disponible para recargar.")
        return false
    end

    return true
end

-- 2. SISTEMA DE COMBATE DEFENSIVO AVANZADO
local function verificarCombate()
    for i = 0, 8 do
        local ok, info = pcall(android.getSlotInfo, i)
        if ok and type(info) == "string" and (string.find(string.lower(info), "sword") or string.find(string.lower(info), "axe")) then
            pcall(android.equipSlot, i)
            break
        end
    end
end

-- 3. SISTEMA DE SEGUIMIENTO SEGURO POR ENTIDADES (Follow)
local function seguirObjetivoSeguro()
    local ok, entidades = pcall(function() return android.getEntities() end)
    if ok and type(entidades) == "table" then
        for _, ent in ipairs(entidades) do
            if ent and (ent.name == objetivoNombre or ent.type == "player" or ent.id == objetivoNombre) and ent.x then
                local selfPos = android.getSelf()
                if selfPos and selfPos.posX then
                    local distancia = math.abs(ent.x - selfPos.posX) + math.abs(ent.z - selfPos.posZ)
                    if distancia > 2 then
                        pcall(android.moveTo, math.floor(ent.x), math.floor(ent.y), math.floor(ent.z))
                        esperarTarea()
                    end
                end
                return
            end
        end
    end
end

-- 4. GESTION DE VEHICULOS (Immersive Aircraft / Man of Many Planes)
local function gestionarVehiculo()
    local ok, vehiculos = pcall(function() return android.getEntities("vehicle") or android.getEntities("plane") end)
    if ok and vehiculos and #vehiculos > 0 then
        local v = vehiculos[1]
        pcall(android.moveTo, math.floor(v.x), math.floor(v.y), math.floor(v.z))
        pcall(android.useBlock, math.floor(v.x), math.floor(v.y), math.floor(v.z))
        print(">> Intentando embarcar en el vehiculo...")
    else
        print(">> No hay vehiculos cercanos detectados.")
    end
end

-- 5. BUCLE PRINCIPAL Y CONSOLA DE COMANDOS INTERACTIVA
local function main()
    print("========================================")
    print("   ANDROIDE TACTICO INTELIGENTE ACTIVO  ")
    print("========================================")
    print("Owner activo por defecto: " .. objetivoNombre)
    print("Comandos disponibles en esta consola:")
    print(" - seguir [nombre]   -> Cambia de objetivo.")
    print(" - addowner [nombre] -> Añade un nuevo owner autorizado.")
    print(" - vehiculo          -> Sube a un avion/transporte.")
    print(" - parar / para      -> Detiene al androide.")
    print(" - reanudar          -> Vuelve a seguir al objetivo.")
    print("----------------------------------------")

    -- Hilo independiente para leer la consola local
    local function leerConsola()
        while true do
            local linea = io.read()
            if linea then
                linea = string.lower(linea)
                
                if string.find(linea, "seguir ") then
                    objetivoNombre = string.sub(linea, 8)
                    modoActual = "seguir"
                    print(">> Nuevo objetivo asignado: " + objetivoNombre)
                    
                elseif string.find(linea, "addowner ") then
                    local nuevoOwner = string.sub(linea, 10)
                    owners[nuevoOwner] = true
                    print(">> ¡Nuevo owner autorizado añadido: " + nuevoOwner)
                    
                elseif linea == "vehiculo" or linea == "sube" then
                    modoActual = "vehiculo"
                    print(">> Modo vehiculo activado.")
                    
                elseif linea == "parar" or linea == "para" then
                    modoActual = "esperar"
                    print(">> Androide puesto en espera.")
                    
                elseif linea == "reanudar" then
                    modoActual = "seguir"
                    print(">> Seguimiento reanudado.")
                else
                    print(">> Comando no reconocido.")
                end
            end
        end
    end

    -- Ejecucion paralela multitarea
    parallel.waitForAll(leerConsola, function()
        while true do
            -- Gestion previa de combustible
            if not comprobarYRecargar() then
                sleep(5)
            else
                -- Revision de combate y acciones
                verificarCombate()

                if modoActual == "seguir" then
                    seguirObjetivoSeguro()
                elseif modoActual == "vehiculo" then
                    gestionarVehiculo()
                end
            end

            sleep(0.5)
        end
    end)
end

-- Lanzador protegido contra fallos
local ok, err = pcall(main)
if not ok then
    print("ERROR FATAL EN SCRIPT: " .. tostring(err))
end
