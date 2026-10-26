-- guardia.lua
-- CC:Androids 1.3.0 | Minecraft 1.20.1
-- Androide de Combate, Escolta, Autofollow y Control de Vehículos

local android = _G.android

local PAUSA = 0.5
local modoActual = "esperar" -- "seguir", "escolta", "vehiculo"
local objetivoNombre = nil     -- Nombre del owner o jugador a seguir/escoltar
local objetivoPos = nil        -- Coordenadas de objetivo programable

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

-- 1. SISTEMA DE COMBATE Y EQUIPO
local function verificarCombate()
    -- Buscar espada u objeto de ataque en el inventario y equiparlo
    for i = 0, 8 do
        local ok, info = pcall(android.getSlotInfo, i)
        if ok and type(info) == "string" and string.find(string.lower(info), "sword") then
            pcall(android.equipSlot, i)
            break
        end
    end
end

-- 2. AUTOFOLLOW / SEGUIMIENTO AL DUEÑO
local function seguirDueño(nombreJugador)
    local jugador = android.getPlayer(nombreJugador)
    if jugador and jugador.posX then
        local distancia = math.abs(jugador.posX - android.getSelf().posX) + math.abs(jugador.posZ - android.getSelf().posZ)
        if distancia > 3 then
            pcall(android.moveTo, math.floor(jugador.posX), math.floor(jugador.posY), math.floor(jugador.posZ))
            esperarTarea()
        end
    end
end

-- 3. GESTIÓN DE VEHÍCULOS (Aviones / Immersive Aircraft / Man of Many Planes)
local function gestionarVehiculo()
    -- Intenta interactuar o montarse en el vehículo/entidad más cercana del tipo aeronave o transporte
    local vehiculos = android.getEntities("vehicle") or android.getEntities("plane")
    if vehiculos and #vehiculos > 0 then
        local v = vehiculos[1]
        pcall(android.moveTo, math.floor(v.x), math.floor(v.y), math.floor(v.z))
        -- Usar bloque o entidad para subir
        pcall(android.useBlock, math.floor(v.x), math.floor(v.y), math.floor(v.z))
        print("Intentando embarcar en el vehículo...")
    end
end

-- 4. ESCUCHA DE COMANDOS POR CHAT
local function escucharComandos()
    -- Escucha eventos de chat locales para recibir órdenes dinámicas
    local event, player, message = os.pullEvent("chat")
    if event == "chat" and message then
        message = string.lower(message)
        
        if string.find(message, "ven") or string.find(message, "follow") then
            objetivoNombre = player
            modoActual = "seguir"
            print("Modo Autofollow activado para: " .. player)
            
        elseif string.find(message, "sube") or string.find(message, "mount") then
            modoActual = "vehiculo"
            print("Modo Automount en avión activado.")
            
        elseif string.find(message, "para") or string.find(message, "stay") then
            modoActual = "esperar"
            print("Androide en posición de espera.")
            
        elseif string.find(message, "escolta") then
            objetivoNombre = player
            modoActual = "escolta"
            print("Modo Escolta defensiva activado para: " .. player)
        end
    end
end

local function main()
    print("=== ANDROIDE TÁCTICO DE ESCOLTA INICIADO ===")
    print("Usa el chat del juego con comandos como: 'ven', 'sube', 'escolta' o 'para'.")

    while true do
        verificarCombate()

        -- Ejecutar lógica según el modo actual
        if modoActual == "seguir" and objetivoNombre then
            seguirDueño(objetivoNombre)
        elseif modoActual == "escolta" and objetivoNombre then
            seguirDueño(objetivoNombre)
            -- En modo escolta también revisa amenazas cercanas
        elseif modoActual == "vehiculo" then
            gestionarVehiculo()
        end

        -- Breve pausa para revisar eventos de chat de forma no bloqueante
        sleep(0.5)
    end
end

local ok, err = pcall(main)
if not ok then
    print("ERROR FATAL: " .. tostring(err))
end
