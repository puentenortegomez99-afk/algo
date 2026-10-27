-- granja.lua
-- CC:Androids 1.3.0 | Minecraft 1.20.1
-- Granjero Automatico con Autorecarga de Redstone y Organizacion de Cofres

local android = _G.android
local PAUSA = 0.5
local COMBUSTIBLE_MINIMO = 200

-- Coordenadas de tu cofre principal (ajustalas a las de tu base si es necesario)
local cofreX, cofreY, cofreZ = 2259, 63, -802

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

-- 1. SISTEMA DE AUTORECARGA ROBUSTO CON REDSTONE
local function comprobarYRecargar()
    local combustibleActual = android.fuelLevel()
    if combustibleActual and combustibleActual >= COMBUSTIBLE_MINIMO then
        return true
    end

    print(">> Combustible bajo. Buscando redstone en inventario...")
    local recargaExitosa = false

    for i = 0, 8 do
        local okEquip = pcall(android.equipSlot, i)
        if okEquip then
            pcall(android.refuel)
            local nuevoCombustible = android.fuelLevel()
            if nuevoCombustible and nuevoCombustible > combustibleActual then
                print(">> ¡Recarga de redstone exitosa desde el slot " .. i .. "!")
                recargaExitosa = true
                break
            end
        end
    end
    return recargaExitosa
end

-- 2. ORGANIZACION Y VACIADO DE COFRES (En vez de estar Idle)
local function organizarYGuardarEnCofre()
    print(">> Sin tareas de cultivo. Organizando y guardando en cofre...")
    
    -- Nos acercamos al cofre
    pcall(android.moveTo, cofreX, cofreY, cofreZ)
    esperarTarea()

    -- Recorremos el inventario del androide para vaciar recursos cosechados
    for slot = 0, 8 do
        local okInfo, info = pcall(android.getSlotInfo, slot)
        if okInfo and type(info) == "string" then
            -- Equipamos el slot
            pcall(android.equipSlot, slot)
            
            -- Intentamos meterlo en el cofre (slots del 0 al 26)
            for cSlot = 0, 26 do
                local okStore = pcall(android.storeHeldItemInContainer, cofreX, cofreY, cofreZ, cSlot)
                if okStore then
                    print(">> Objeto guardado en cofre desde slot " .. slot)
                    break
                end
            end
        end
    end
end

-- 3. BUCLE PRINCIPAL DE AGRICULTURA Y GESTION
local function main()
    print("=== GRANJERO INTELIGENTE ACTIVO ===")
    pcall(android.changeFace, "happy")

    while true do
        -- Verificar combustible primero
        if not comprobarYRecargar() then
            print(">> ERROR: No hay redstone disponible para combustible. Esperando...")
            sleep(5)
        else
            -- Buscar cultivos maduros para cosechar
            local okBloques, bloques = pcall(function() return android.getBlocksOfType("minecraft:wheat") end)
            local cosechoAlgo = false

            if okBloques and type(bloques) == "table" and #bloques > 0 then
                for _, b in ipairs(bloques) do
                    if b.x and b.y and b.z then
                        pcall(android.breakBlock, b.x, b.y, b.z)
                        esperarTarea()
                        pcall(android.pickup)
                        pcall(android.useBlock, b.x, b.y, b.z)
                        esperarTarea()
                        cosechoAlgo = true
                    end
                end
            end

            -- Si no hay cultivos que cosechar, pasa a organizar y guardar en el cofre
            if not cosechoAlgo then
                organizarYGuardarEnCofre()
            end
        end

        sleep(3)
    end
end

local ok, err = pcall(main)
if not ok then
    print("ERROR FATAL: " .. tostring(err))
end
