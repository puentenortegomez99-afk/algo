local android = _G.android
local PAUSA = 0.5
local modoActual = "seguir"
local objetivoNombre = "chapelmussel0"

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

local function seguirObjetivoSeguro(nombre)
    local ok, entidades = pcall(function() return android.getEntities() end)
    if ok and type(entidades) == "table" then
        for _, ent in ipairs(entidades) do
            if ent and (ent.name == nombre or ent.type == "player" or ent.id == nombre) and ent.x then
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
    print("Siguiendo a: " .. objetivoNombre)

    local function leerConsola()
        while true do
            local linea = io.read()
            if linea then
                linea = string.lower(linea)
                if string.find(linea, "seguir ") then
                    objetivoNombre = string.sub(linea, 8)
                    print(">> Objetivo cambiado a: " .. objetivoNombre)
                elseif linea == "parar" or linea == "para" then
                    modoActual = "esperar"
                    print(">> Androide detenido.")
                elseif linea == "seguir" then
                    modoActual = "seguir"
                    print(">> Reanudando seguimiento.")
                end
            end
        end
    end

    parallel.waitForAll(leerConsola, function()
        while true do
            verificarCombate()
            if modoActual == "seguir" then
                seguirObjetivoSeguro(objetivoNombre)
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
