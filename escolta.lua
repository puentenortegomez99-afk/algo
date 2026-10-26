-- escolta.lua
-- CC:Androids 1.3.0 | Minecraft 1.20.1
-- Script Maestro Oficial: Combate, Autofollow por getClosestPlayer(), Owners por Texto y Autorecarga

local android = _G.android
local PAUSA = 0.5

-- Lista de owners autorizados
local owners = {
    ["chapelmussel0"] = true
}

local modoActual = "seguir" -- "seguir", "esperar"
local COMBUSTIBLE_MINIMO = 200

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

-- 1. AUTORECARGA AUTOMATICA CON REDSTONE (Basado en refuel() y fuelLevel())
local function comprobarYRecargar()
    local combustibleActual = android.fuelLevel()
    if combustibleActual and combustibleActual >= COMBUSTIBLE_MINIMO then
        return true
    end

    print(">> Combustible bajo. Buscando redstone...")
    local recargaExitosa = false

    for i = 0, 8 do
        local okEquip = pcall(android.equipSlot, i)
        if okEquip then
            pcall(android.refuel)
            local nuevoCombustible = android.fuelLevel()
            if nuevoCombustible and nuevoCombustible > combustibleActual then
                print(">> ¡Recarga exitosa desde el slot " .. i .. "!")
                recargaExitosa = true
                break
            end
        end
    end

    return recargaExitosa
end

-- 2. SISTEMA DE COMBATE DEFENSIVO
local function verificarCombate()
    for i = 0, 8 do
        local ok, info = pcall(android.getSlotInfo, i)
        if ok and type(info) == "string" and (string.find(string.lower(info), "sword") or string.find(string.lower(info), "axe")) then
            pcall(android.equipSlot, i)
            break
        end
    end
end

-- 3. SEGUIMIENTO OFICIAL USANDO getClosestPlayer()
local function seguirDueño()
    local jugador = android.getClosestPlayer()
    if jugador and jugador.name and owners[string.lower(jugador.name)] then
        if jugador.posX and jugador.posZ then
            local selfPos = android.getSelf()
            if selfPos and selfPos.posX then
                local distancia = math.abs(jugador.posX - selfPos.posX) + math.abs(jugador.posZ - selfPos.posZ)
                if distancia > 2 then
                    pcall(android.moveTo, math.floor(jugador.posX), math.floor(jugador.posY), math.floor(jugador.posZ))
                    esperarTarea()
                end
            end
        end
    end
end

-- 4. ESCUCHA DE EVENTOS DE CHAT OFICIALES (onChatMessage)
local function escucharChat()
    while true do
        local event, message, senderName, senderUUID = os.pullEvent("onChatMessage")
        if message and senderName then
            local msgLower = string.lower(message)
            local senderLower = string.lower(senderName)

            -- Verificar si quien manda el mensaje es un owner autorizado
            if owners[senderLower] then
                if msgLower == "ven" or msgLower == "follow" or msgLower == "seguir" then
                    modoActual = "seguir"
                    android.changeFace("happy")
                    print(">> Modo seguimiento activado por " .. senderName)
                    
                elseif msgLower == "para" or msgLower == "stay" or msgLower == "parar" then
                    modoActual = "esperar"
                    android.changeFace("annoyed")
                    print(">> Androide detenido por " .. senderName)
                    
                elseif string.find(msgLower, "addowner ") then
                    local nuevoOwner = string.sub(message, 10)
                    owners[string.lower(nuevoOwner)] = true
                    android.changeFace("happy")
                    print(">> ¡Nuevo owner añadido al sistema: " .. nuevoOwner)
                end
            end
        end
    end
end

-- 5. BUCLE PRINCIPAL
local function main()
    print("========================================")
    print("   ANDROIDE TACTICO API OFICIAL ACTIVO  ")
    print("========================================")
    print("Owner por defecto: chapelmussel0")
    print("Escuchando chat y comandos locales...")

    parallel.waitForAll(escucharChat, function()
        while true do
            -- Comprobar combustible antes de actuar
            if not comprobarYRecargar() then
                sleep(5)
            else
                verificarCombate()

                if modoActual == "seguir" then
                    seguirDueño()
                end
            end

            sleep(0.5)
        end
    end)
end

local ok, err = pcall(main)
if not ok then
    print("ERROR FATAL: " .. tostring(err))
end
