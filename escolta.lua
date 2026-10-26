local android = _G.android
local PAUSA = 0.5
local modoActual = "seguir"
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

local function verificarCombate()
    for i = 0, 8 do
        local ok, info = pcall(android.getSlotInfo, i)
        if ok and type(info) == "string" and (string.find(string.lower(info), "sword") or string.find(string.lower(info), "axe")) then
            pcall(android.equipSlot, i)
            break
        end
    end
end

local function seguirObjetivo(nombre)
    local jugador = android.getPlayer(nombre)
    if jugador and jugador.posX then
        local distancia = math.abs(jugador.posX - android.getSelf().posX) + math.abs(jugador.posZ - android.getSelf().posZ)
        if distancia > 2 then
            pcall(android.moveTo, math.floor(jugador.posX), math.floor(jugador.posY), math.floor(jugador.posZ))
            esperarTarea()
        end
        return
    end

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

local function gestionarVehiculo()
    local ok, vehiculos = pcall(function() return android.getEntities("vehicle") or android.getEntities("plane") end)
    if ok and vehiculos and #vehiculos > 0 then
        local v = vehiculos[1]
        pcall(android.moveTo, math.floor(v.x), math.floor(v.y), math.floor(v.z))
        pcall(android.useBlock, math.floor(v.x), math.floor(v.y), math.floor(v.z))
    end
end

local function main()
    print("=== ANDROIDE TACTICO ACTIVO ===")
    print("Siguiendo por defecto a: chapelmussel0")

    local function leerConsola()
        while true do
            local linea = io.read()
            if linea then
                linea = string.lower(linea)
                if string.find(linea, "seguir ") then
                    objetivoActual = string.sub(linea, 8)
                    modoActual = "seguir"
                    print(">> Siguiendo a: " + objetivoActual)
                elseif linea == "parar" or linea == "para" then
                    modoActual = "esperar"
                    print(">> Androide detenido.")
                end
            end
        end
    end

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
    print("ERROR: " .. tostring(err))
end
