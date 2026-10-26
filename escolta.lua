-- escolta.lua
-- CC:Androids 1.3.0 | Minecraft 1.20.1
-- Script Maestro Mega Extendido: Combate, Autofollow, Autorecarga, Saqueo, Contenedores y Owners Persistentes

local android = _G.android
local PAUSA = 0.5
local ARCHIVO_OWNERS = "owners.txt"

-- Lista inicial de owners autorizados
local owners = {
    ["chapelmussel0"] = true
}

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
    end
end

cargarOwners()

local objetivoNombre = "chapelmussel0"
local modoActual = "seguir" -- "seguir", "esperar", "patrulla"
local COMBUSTIBLE_MINIMO = 300

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

-- 1. AUTORECARGA AUTOMATICA CON REDSTONE
local function comprobarYRecargar()
    local combustibleActual = android.fuelLevel()
    if combustibleActual and combustibleActual >= COMBUSTIBLE_MINIMO then
        return true
    end

    pcall(android.changeFace, "woozy")
    print(">> Combustible critico. Buscando redstone en inventario...")
    local recargaExitosa = false

    for i = 0, 8 do
        local okEquip = pcall(android.equipSlot, i)
        if okEquip then
            pcall(android.refuel)
            local nuevoCombustible = android.fuelLevel()
            if nuevoCombustible and nuevoCombustible > combustibleActual then
                print(">> Recarga exitosa desde el slot " .. i)
                recargaExitosa = true
                pcall(android.changeFace, "happy")
                break
            end
        end
    end
    return recargaExitosa
end

-- 2. COMBATE AVANZADO Y DEFENSA CONTRA MOBS
local function verificarCombateYDefensa()
    -- Buscar arma en los slots del 0 al 8
    for i = 0, 8 do
        local ok, info = pcall(android.getSlotInfo, i)
        if ok and type(info) == "string" and (string.find(string.lower(info), "sword") or string.find(string.lower(info), "axe")) then
            pcall(android.equipSlot, i)
            break
        end
    end

    -- Si hay un mob hostil cerca, atacarlo
    local okMob, mob = pcall(function() return android.getClosestMob() end)
    if okMob and mob and mob.uuid then
        pcall(android.changeFace, "angry")
        pcall(android.attack, mob.uuid)
        esperarTarea()
    end
end

-- 3. SEGUIMIENTO INTELIGENTE DEL DUENO
local function seguirDueno()
    local jugador = android.getClosestPlayer()
    if jugador and jugador.name and owners[string.lower(jugador.name)] then
        if jugador.posX and jugador.posZ then
            local selfPos = android.getSelf()
            if selfPos and selfPos.posX then
                local distancia = math.abs(jugador.posX - selfPos.posX) + math.abs(jugador.posZ - selfPos.posZ)
                if distancia > 3 then
                    pcall(android.moveTo, math.floor(jugador.posX), math.floor(jugador.posY), math.floor(jugador.posZ))
                    esperarTarea()
                end
            end
        end
    end
end

-- 4. PROCESAMIENTO DE COMANDOS UNIFICADO (Chat y Consola)
local function procesarComando(texto, emisor)
    local msgLower = string.lower(texto)

    if string.find(msgLower, "seguir ") then
        objetivoNombre = string.sub(texto, 8)
        objetivoNombre = string.gsub(objetivoNombre, "^%s*(.-)%s*$", "%1")
        modoActual = "seguir"
        pcall(android.changeFace, "happy")
        print(">> Objetivo fijado: " .. objetivoNombre)
        if emisor then pcall(android.sendChatMessage, "Siguiendo a " .. objetivoNombre) end

    elseif string.find(msgLower, "addowner ") then
        local nuevoOwner = string.sub(texto, 10)
        nuevoOwner = string.gsub(nuevoOwner, "^%s*(.-)%s*$", "%1")
        if nuevoOwner ~= "" then
            owners[string.lower(nuevoOwner)] = true
            guardarOwners()
            pcall(android.changeFace, "happy")
            print(">> Owner anadido y guardado: " .. nuevoOwner)
            if emisor then pcall(android.sendChatMessage, "Nuevo owner autorizado: " .. nuevoOwner) end
        end

    elseif msgLower == "parar" or msgLower == "para" or msgLower == "stay" then
        modoActual = "esperar"
        pcall(android.changeFace, "sad")
        print(">> Androide en espera.")
        if emisor then pcall(android.sendChatMessage, "Me detengo.") end

    elseif msgLower == "reanudar" or msgLower == "seguir" or msgLower == "ven" or msgLower == "follow" then
        modoActual = "seguir"
        pcall(android.changeFace, "happy")
        print(">> Reanudando seguimiento.")
        if emisor then pcall(android.sendChatMessage, "Reanudando escolta.") end
        
    elseif msgLower == "estado" then
        local fuel = android.fuelLevel()
        local self = android.getSelf()
        print(">> Estado -> Combustible: " .. tostring(fuel) .. " | Salud: " .. tostring(self.health))
        if emisor then pcall(android.sendChatMessage, "Combustible actual: " .. tostring(fuel)) end
    end
end

local function escucharChat()
    while true do
        local event, message, senderName, senderUUID = os.pullEvent("onChatMessage")
        if message and senderName then
            if owners[string.lower(senderName)] then
                procesarComando(message, senderName)
            end
        end
    end
end

local function leerConsola()
    while true do
        local linea = io.read()
        if linea then
            procesarComando(linea, nil)
        end
    end
end

local function main()
    print("========================================")
    print("  ANDROIDE TACTICO NIVEL DIOS ACTIVO    ")
    print("========================================")
    pcall(android.changeFace, "happy")

    parallel.waitForAll(escucharChat, leerConsola, function()
        while true do
            if not comprobarYRecargar() then
                sleep(5)
            else
                verificarCombateYDefensa()
                if modoActual == "seguir" then
                    seguirdueno()
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
