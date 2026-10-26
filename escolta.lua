-- escolta.lua
local android = _G.android
local PAUSA = 0.5
local ARCHIVO_OWNERS = "owners.txt"

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
local modoActual = "seguir"
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

local function comprobarYRecargar()
    local combustibleActual = android.fuelLevel()
    if combustibleActual and combustibleActual >= COMBUSTIBLE_MINIMO then
        return true
    end

    local recargaExitosa = false
    for i = 0, 8 do
        local okEquip = pcall(android.equipSlot, i)
        if okEquip then
            pcall(android.refuel)
            local nuevoCombustible = android.fuelLevel()
            if nuevoCombustible and nuevoCombustible > combustibleActual then
                recargaExitosa = true
                break
            end
        end
    end
    return recargaExitosa
end

local function verificarCombate()
    for i = 0, 8 do
        local ok, info = pcall(android.getSlotInfo, i)
        if ok and type(info) == "string" and (string.find(string.lower(info), "sword") or string.find(string.lower(info), "axe")) then
            pcall(android.equipSlot, i)
            break
        end
    end
end

local function seguirDueno()
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

local function procesarComando(texto)
    local msgLower = string.lower(texto)
    if string.find(msgLower, "seguir ") then
        objetivoNombre = string.sub(texto, 8)
        objetivoNombre = string.gsub(objetivoNombre, "^%s*(.-)%s*$", "%1")
        modoActual = "seguir"
        pcall(android.changeFace, "happy")
    elseif string.find(msgLower, "addowner ") then
        local nuevoOwner = string.sub(texto, 10)
        nuevoOwner = string.gsub(nuevoOwner, "^%s*(.-)%s*$", "%1")
        if nuevoOwner ~= "" then
            owners[string.lower(nuevoOwner)] = true
            guardarOwners()
            pcall(android.changeFace, "happy")
        end
    elseif msgLower == "parar" or msgLower == "para" or msgLower == "stay" then
        modoActual = "esperar"
        pcall(android.changeFace, "annoyed")
    elseif msgLower == "reanudar" or msgLower == "seguir" or msgLower == "ven" or msgLower == "follow" then
        modoActual = "seguir"
        pcall(android.changeFace, "happy")
    end
end

local function escucharChat()
    while true do
        local event, message, senderName, senderUUID = os.pullEvent("onChatMessage")
        if message and senderName then
            if owners[string.lower(senderName)] then
                procesarComando(message)
            end
        end
    end
end

local function leerConsola()
    while true do
        local linea = io.read()
        if linea then
            procesarComando(linea)
        end
    end
end

local function main()
    print("=== ANDROIDE TACTICO ACTIVO ===")
    parallel.waitForAll(escucharChat, leerConsola, function()
        while true do
            if not comprobarYRecargar() then
                sleep(5)
            else
                verificarCombate()
                if modoActual == "seguir" then
                    seguirDueno()
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
