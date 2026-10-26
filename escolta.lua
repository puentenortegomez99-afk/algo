-- escolta.lua
-- CC:Androids 1.3.0 | Minecraft 1.20.1
-- Androide de Combate, Escolta, Autofollow y Control de Vehiculos

local android = _G.android

local PAUSA = 0.5
local modoActual = "esperar" -- "seguir", "escolta", "vehiculo"
local objetivoNombre = nil

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

-- 1. Sistema de combate y equipamiento
local function verificarCombate()
    for i = 0, 8 do
        local ok, info = pcall(android.getSlotInfo, i)
        if ok and type(info) == "string" and string.find(string.lower(info), "sword") then
            pcall(android.equipSlot, i)
            break
        end
    end
end

-- 2. Seguimiento automatico al jugador
local function seguirJugador(nombreJugador)
    local jugador = android.getPlayer(nombreJugador)
    if jugador and jugador.posX then
        local distancia = math.abs(jugador.posX - android.getSelf().posX) + math.abs(jugador.posZ - android.getSelf().posZ)
        if distancia > 3 then
            pcall(android.moveTo, math.floor(jugador.posX), math.floor(jugador.posY), math.floor(jugador.posZ))
            esperarTarea()
        end
    end
end

-- 3. Gestion de vehiculos (Aviones / Immersive Aircraft / Man of Many Planes)
local function gestionarVehiculo()
    local vehiculos = android.getEntities("vehicle") or android.getEntities("plane")
    if vehiculos and #vehiculos > 0 then
        local v = vehiculos[1]
        pcall(android.moveTo, math.floor(v.x), math.floor(v.y), math.floor(v.z))
        pcall(android.useBlock, math.floor(v.x), math.floor(v.y), math.floor(v.z))
        print("Intentando embarcar en el vehiculo...")
    end
end

-- 4. Escucha de comandos por chat local
local function escucharComandos()
    local event, player, message = os.pullEvent("chat")
    if event == "chat" and message then
        message = string.lower(message)
        
        if string.find(message, "ven") or string.find(message, "follow") then
            objetivoNombre = player
            modoActual = "seguir"
            print("Modo Autofollow activado para: " .. player)
            
        elseif string.find(message, "sube") or string.find(message, "mount") then
            modoActual = "vehiculo"
            print("Modo Automount en avion activado.")
            
        elseif string.find(message, "para") or string.find(message, "stay") then
            modoActual = "esperar"
            print("Androide en posicion de espera.")
            
        elseif string.find(message, "escolta") then
            objetivoNombre = player
            modoActual = "escolta"
            print("Modo Escolta defensiva activado para: " .. player)
        end
    end
end

local function main()
    print("=== ANDROIDE TACTICO INICIADO ===")
    print("Usa en el chat: 'ven', 'sube', 'escolta' o 'para'.")

    while true do
        verificarCombate()

        if modoActual == "seguir" and objetivoNombre then
            seguirJugador(objetivoNombre)
        elseif modoActual == "escolta" and objetivoNombre then
            seguirJugador(objetivoNombre)
        elseif modoActual == "vehiculo" then
            gestionarVehiculo()
        end

        sleep(0.5)
    end
end

local ok, err = pcall(main)
if not ok then
    print("ERROR FATAL: " .. tostring(err))
end
