-- escolta.lua
-- CC:Androids 1.3.0 | Minecraft 1.20.1
-- Script Maestro: API Oficial, Owners Persistentes, Autorecarga y Doble Control (Consola y Chat)

local android = _G.android
local PAUSA = 0.5
local ARCHIVO_OWNERS = "owners.txt"

-- Lista inicial de owners (con chapelmussel0 por defecto)
local owners = {
    ["chapelmussel0"] = true
}

-- 1. SISTEMA DE PERSISTENCIA DE OWNERS
local function cargarOwners()
    if fs.exists(ARCHIVO_OWNERS) then
        local file = io.open(ARCHIVO_OWNERS, "r")
        if file then
            local contenido = file:read("*a")
            file:close()
            for nombre in string.gmatch(contenido, "[^\r\n]+") do
                local limpio = string.gsub(nombre, "^%s*(.-)%s*$", "%1")
                if limpio ~= "" then
                    owners[string.lower(limpio)] = true
                end
            end
            print(">> Owners cargados desde disco correctamente.")
        end
    end
end

local function guardarOwners()
    local file = io.open(ARCHIVO_OWNERS, "w")
    if file then
        for nombre, _ in pairs(owners) do
            file:write(nombre .. "\n")
        end
        file:close()
        print(">> Lista de owners guardada en disco de forma permanente.")
    end
end

cargarOwners()

local objetivoNombre = "chapelmussel0"
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

-- 2. SISTEMA DE AUTORECARGA CON REDSTONE (API Oficial)
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
        print(">> ¡ADVERTENCIA! No hay redstone disponible en los slots 0-8.")
        return false
    end

    return true
end

-- 3. SISTEMA DE COMBATE DEFENSIVO
local function verificarCombate()
    for i = 0, 8 do
        local ok, info = pcall(android.getSlotInfo, i)
        if ok and type(info) == "string" and (string.find(string.lower(info), "sword") or string.find(string.lower(info), "axe")) then
            pcall(android.equipSlot, i)
            break
        end
    end
end

-- 4. SEGUIMIENTO USANDO getClosestPlayer() OFICIAL
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

-- 5. PROCESADOR UNIFICADO DE COMANDOS (Consola local y Chat)
local function procesarComando(texto)
    local msgLower = string.lower(texto)
    
    if string.find(msgLower, "seguir ") then
        objetivoNombre = string.sub(texto, 8)
        objetivoNombre = string.gsub(objetivoNombre, "^%s*(.-)%s*$", "%1")
        modoActual = "seguir"
        pcall(android.changeFace, "happy")
        print(">> Objetivo de seguimiento cambiado a: " .. objetivoNombre)
        
    elseif string.find(msgLower, "addowner ") then
        local nuevoOwner = string.sub(texto, 10)
        nuevoOwner = string.gsub(nuevoOwner, "^%s*(.-)%s*$", "%1")
        if nuevoOwner ~= "" then
            owners[string.lower(nuevoOwner)] = true
            guardarOwners() -- Guarda permanentemente en owners.txt
            pcall(android.changeFace, "happy")
            print(">> ¡Nuevo owner autorizado añadido y guardado: " .. nuevoOwner)
        end
        
    elseif msgLower == "parar" or msgLower == "para" or msgLower == "stay" then
        modoActual = "esperar"
        pcall(android.changeFace, "annoyed")
        print(">> Androide puesto en espera.")
        
    elseif msgLower == "reanudar" or msgLower == "seguir" or msgLower == "ven" or msgLower == "follow" then
        modoActual = "seguir"
        pcall(android.changeFace, "happy")
        print(">> Seguimiento reanudado.")
    end
end

-- Hilo para escuchar el chat oficial del mod (onChatMessage)
local function escucharChat()
    while true do
        local event, message, senderName, senderUUID = os.pullEvent("onChatMessage")
        if message and senderName then
            local senderLower = string.lower(senderName)
            -- Solo acepta comandos si el emisor es un owner registrado
            if owners[senderLower] then
                print("[CHAT] " .. senderName .. ": " .. message)
                procesarComando(message)
            end
        end
    end
end

-- Hilo para leer comandos desde la consola local del androide
local function leerConsola()
    while true do
        local linea = io.read()
        if linea then
            print("[CONSOLA]: " .. linea)
            procesarComando(linea)
        end
    end
end

-- 6. BUCLE PRINCIPAL MULTITAREA
local function main()
    print("========================================")
    print("   ANDROIDE TACTICO MAESTRO ACTIVO      ")
    print("========================================")
    print("Owner por defecto: chapelmussel0")
    print("Comandos: seguir [nombre], addowner [nombre], parar, reanudar")
    print("----------------------------------------")

    -- Ejecucion paralela: Chat oficial + Consola local + Rutinas del androide
    parallel.waitForAll(escucharChat, leerConsola, function()
        while true do
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
    print("ERROR FATAL EN SCRIPT: " .. tostring(err))
end
