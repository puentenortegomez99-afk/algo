-- escolta.lua
-- CC:Androids 1.3.0 | Minecraft 1.20.1

local android = _G.android

local PAUSA = 0.5
local modoActual = "esperar"
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

local function verificarCombate()
    for i = 0, 8 do
        local ok, info = pcall(android.getSlotInfo, i)
        if ok and type(info) == "string" and string.find(string.lower(info), "sword") then
            pcall(android.equipSlot, i)
            break
        end
    end
end

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

local function gestionarVehiculo()
    local vehiculos = android.getEntities("vehicle") or android.getEntities("plane")
    if vehiculos and #vehiculos > 0 then
        local v = vehiculos[1]
        pcall(android.moveTo, math.floor(v.x), math.floor(v.y), math.floor(v.z))
        pcall(android.useBlock, math.floor(v.x), math.floor(v.y), math.floor(v.z))
        print("Intentando embarcar no vehiculo...")
    end
end

local function main()
    print("=== ANDROIDE TACTICO INICIADO ===")
    print("Usa no chat: 'ven', 'sube', 'escolta' ou 'para'.")

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
