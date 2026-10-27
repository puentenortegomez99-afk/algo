-- granja.lua
-- CC:Androids 1.3.0 | Minecraft 1.20.1
-- Script de Agricultura Automatizada, Cosecha, Plantacion y Cofres

local android = _G.android
local PAUSA = 0.5

-- Coordenadas de tu cofre de almacenamiento (cambialas por las de tu cofre real)
local cofreX, cofreY, cofreZ = 0, 63, 0 

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

-- Guardar inventario en el cofre cercano usando la API oficial
local function guardarEnCofre()
    print(">> Guardando recursos en el cofre...")
    for slot = 0, 8 do
        local okInfo, info = pcall(android.getSlotInfo, slot)
        if okInfo and type(info) == "string" then
            -- Equipar el slot para poder guardarlo
            pcall(android.equipSlot, slot)
            -- Intentar almacenar en las primeras ranuras del cofre (0 al 26)
            for cSlot = 0, 26 do
                local okStore = pcall(android.storeHeldItemInContainer, cofreX, cofreY, cofreZ, cSlot)
                if okStore then break end
            end
        end
    end
end

-- Sistema de recoleccion de objetos del suelo
local function recogerSuelo()
    pcall(android.pickup)
end

-- Funcion principal de agricultura
local function automatizarGranja()
    print("=== GRANJERO AUTOMATICO ACTIVO ===")
    pcall(android.changeFace, "happy")

    while true do
        -- 1. Buscar bloques de cultivo cercanos (ej: trigo, patatas, zanahorias)
        local okBloques, bloques = pcall(function() return android.getBlocksOfType("minecraft:wheat") end)
        
        if okBloques and type(bloques) == "table" and #bloques > 0 then
            for _, b in ipairs(bloques) do
                if b.x and b.y and b.z then
                    -- Cosechar (romper cultivo maduro)
                    pcall(android.breakBlock, b.x, b.y, b.z)
                    esperarTarea()
                    
                    -- Recoger del suelo
                    recogerSuelo()
                    
                    -- Replantar usando la semilla en la mano o usando el bloque de tierra inferior
                    pcall(android.useBlock, b.x, b.y, b.z)
                    esperarTarea()
                end
            end
        end

        -- 2. Autorevision de combustible basica
        local fuel = android.fuelLevel()
        if fuel and fuel < 100 then
            print(">> Alerta: Combustible bajo en el granjero.")
        end

        sleep(2)
    end
end

local ok, err = pcall(automatizarGranja)
if not ok then
    print("ERROR FATAL: " .. tostring(err))
end
