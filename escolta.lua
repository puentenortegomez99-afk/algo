-- escolta.lua
-- CC:Androids 1.3.0 | Minecraft 1.20.1
-- Androide Táctico Multiuso: Multi-owner, Escolta de NPCs/Androids/Jugadores y Combate

local android = _G.android
local PAUSA = 0.5

-- Lista de owners permitidos (con chapelmussel0 por defecto)
local owners = {
    ["chapelmussel0"] = true
}

local modoActual = "seguir" -- "seguir", "escolta", "vehiculo", "esperar"
local objetivoActual = "chapelmussel0"

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

-- Sistema de combate defensivo automatico
local function verificarCombate()
    for i = 0, 8 do
        local ok, info = pcall(android.getSlotInfo, i)
        if ok and type(info) == "string" and (string.find(string.lower(info), "sword") or string.find(string.lower(info), "axe")) then
            pcall(android.equipSlot, i)
            break
        end
    end
end

-- Sistema inteligente para seguir jugadores, NPCs u otros androides
local function seguirObjetivo(nombre)
    -- 1. Intentar buscar si es un jugador conectado
    local jugador = android.getPlayer(nombre)
    if jugador and jugador.posX then
        local distancia = math.abs(jugador.posX - android.getSelf().posX) + math.abs(jugador.posZ - android.getSelf().posZ)
        if distancia > 2 then
            pcall(android.moveTo, math.floor(jugador.posX), math.floor(jugador.posY), math.floor(jugador.posZ))
            esperarTarea()
        end
        return
    end

    -- 2. Si no es jugador, buscar entidades (NPCs u otros androides) de forma segura
    local ok, entidades = pcall(function() return android.getEntities() end)
    if ok and entidades then
        for _, ent in ipairs(entidades) do
            if ent and (ent.name == nombre or ent.type == nombre or ent.id == nombre) and ent.x then
                local distancia = math.abs(ent.x - android.getSelf().posX) + math.abs(ent.z - android.getSelf().posZ)
                if distancia > 2 then
                    pcall(android.moveTo, math.floor(ent.x), math.floor(ent.y), math.floor(ent.z))
                    esperarTarea()
                end
                return
            end
        end
    end
end

-- Gestion de vehiculos (Immersive Aircraft / Man of Many Planes)
local function gestionarVehiculo()
    local ok, vehiculos = pcall(function() return android.getEntities("vehicle") or android.getEntities("plane") end)
    if ok and vehiculos and #vehiculos > 0 then
        local v = vehiculos[1]
        pcall(android.moveTo, math.floor(v.x), math.floor(v.y), math.floor(v.z))
        pcall(android.useBlock, math.floor(v.x), math.floor(v.y), math.floor(v.z))
        print("Intentando embarcar en el vehiculo...")
    end
end

local function main()
    print("=== ANDROIDE TACTICO INICIADO ===")
    print("Owner principal activo: chapelmussel0")
    print("Comandos disponibles en esta terminal:")
    print(" - seguir [nombre]  -> Sigue a un jugador, NPC o androide.")
    print(" - escolta [nombre] -> Modo escolta defensiva.")
    print(" - vehiculo         -> Sube al avion/vehiculo.")
    print(" - parar            -> Detiene al androide.")
    print(" - addowner [nombre]-> Añade un nuevo owner autorizado.")

    -- Hilo de comandos por texto en la consola (100% fiable)
    local function leerConsola()
        while true do
            local linea = io.read()
            if linea then
                linea = string.lower(linea)
                
                if string.find(linea, "seguir ") then
                    objetivoActual = string.sub(linea, 8)
                    modoActual = "seguir"
                    print(">> Siguiendo a: " .. objetivoActual)
                    
                elseif string.find(linea, "escolta ") then
                    objetivoActual = string.sub(linea, 9)
                    modoActual = "escolta"
                    print(">> Escoltando a: " .. objetivoActual)
                    
                elseif linea == "vehiculo" or linea == "sube" then
                    modoActual = "vehiculo"
                    print(">> Buscando vehiculo para embarcar...")
                    
                elseif linea == "parar" or linea == "para" then
                    modoActual = "esperar"
                    print(">> Androide detenido en posicion.")
                    
                elseif string.find(linea, "addowner ") then
                    local nuevoOwner = string.sub(linea, 10)
                    owners[nuevoOwner] = true
                    print(">> Nuevo owner autorizado: " .. nuevoOwner)
                else
                    print(">> Comando no reconocido.")
                end
            end
        end
    end

    -- Ejecucion paralela entre la consola y las tareas del androide
    parallel.waitForAll(leerConsola, function()
        while true do
            verificarCombate()

            if modoActual == "seguir" or modoActual == "escolta" then
                seguirObjetivo(objetivoActual)
            elseif modoActual == "vehiculo" then
                gestionarVehiculo()
            end

            sleep(0.5)
        end
    end)
end

local ok, err = pcall(main)
if not ok then
    print("ERROR FATAL: " .. tostring(err))
end
