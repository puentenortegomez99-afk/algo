-- granja.lua
-- CC:Androids 1.3.0 | Minecraft 1.20.1
-- Granjero Avanzado: Cosecha, Replantado Inteligente por Equipamiento y Cofres

local android = _G.android
local PAUSA = 0.5
local COMBUSTIBLE_MINIMO = 200

-- Coordenadas de tu cofre (ajustalas si es necesario)
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

-- Autorecarga robusta con redstone
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

-- Buscar semillas o papas en el inventario y equiparlas para plantar
local function equiparSemillaOPlanta()
    for i = 0, 8 do
        local ok, info = pcall(android.getSlotInfo, i)
        if ok and type(info) == "string" then
            local itemLower = string.lower(info)
            if string.find(itemLower, "seed") or string.find(itemLower, "potato") or string.find(itemLower, "carrot") then
                pcall(android.equipSlot, i)
                return true
            end
        end
    end
    return false
end

-- Organizar y guardar en el cofre
local function organizarYGuardarEnCofre()
    pcall(android.moveTo, cofreX, cofreY, cofreZ)
    esperarTarea()

    for slot = 0, 8 do
        local okInfo, info = pcall(android.getSlotInfo, slot)
        if okInfo and type(info) == "string" then
            pcall(android.equipSlot, i)
            for cSlot = 0, 26 do
                local okStore = pcall(android.storeHeldItemInContainer, cofreX, cofreY, cofreZ, cSlot)
                if okStore then break end
            end
        end
    end
end

-- Bucle principal de cultivo
local function main()
    print("=== GRANJERO INTELIGENTE ACTIVO ===")
    pcall(android.changeFace, "happy")

    while true do
        if not comprobarYRecargar() then
            sleep(5)
        else
            local cosechoAlgo = false
            
            -- Lista de cultivos a buscar
            local tiposCultivos = {"minecraft:wheat", "minecraft:potatoes"}

            for _, tipo in ipairs(tiposCultivos) do
                local okBloques, bloques = pcall(function() return android.getBlocksOfType(tipo) end)
                
                if okBloques and type(bloques) == "table" and #bloques > 0 then
                    for _, b in ipairs(bloques) do
                        if b.x and b.y and b.z then
                            -- 1. Romper cultivo maduro
                            pcall(android.breakBlock, b.x, b.y, b.z)
                            esperarTarea()
                            
                            -- 2. Recoger del suelo
                            pcall(android.pickup)
                            
                            -- 3. Equipar semilla/patata y replantar usando useBlock
                            equiparSemillaOPlanta()
                            pcall(android.useBlock, b.x, b.y, b.z)
                            esperarTarea()
                            
                            cosechoAlgo = true
                        end
                    end
                end
            end

            -- Si no hay nada que cosechar, organiza y guarda en el cofre
            if not cosechoAlgo then
                organizarYGuardarEnCofre()
            end
        end

        sleep(2)
    end
end

local ok, err = pcall(main)
if not ok then
    print("ERROR FATAL: " .. tostring(err))
end
