-- granja.lua
-- CC:Androids 1.3.0 | Minecraft 1.20.1

local android = _G.android
local PAUSA = 0.5
local COMBUSTIBLE_MINIMO = 200

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

local function equiparSemilla()
    for i = 0, 8 do
        local ok, info = pcall(android.getSlotInfo, i)
        if ok and type(info) == "string" then
            local infL = string.lower(info)
            if string.find(infL, "seed") or string.find(infL, "potato") or string.find(infL, "carrot") then
                pcall(android.equipSlot, i)
                return true
            end
        end
    end
    return false
end

local function guardarEnCofre()
    pcall(android.moveTo, cofreX, cofreY, cofreZ)
    esperarTarea()

    for slot = 0, 8 do
        local okInfo, info = pcall(android.getSlotInfo, slot)
        if okInfo and type(info) == "string" then
            pcall(android.equipSlot, slot)
            for cSlot = 0, 26 do
                local okStore = pcall(android.storeHeldItemInContainer, cofreX, cofreY, cofreZ, cSlot)
                if okStore then break end
            end
        end
    end
end

local function main()
    print("=== GRANJERO POR ESCANEO ACTIVO ===")
    pcall(android.changeFace, "happy")

    while true do
        if not comprobarYRecargar() then
            sleep(5)
        else
            local selfPos = android.getSelf()
            if selfPos and selfPos.posX then
                local cx = math.floor(selfPos.posX)
                local cy = math.floor(selfPos.posY)
                local cz = math.floor(selfPos.posZ)
                local hizoAlgo = false

                for dx = -4, 4 do
                    for dz = -4, 4 do
                        local tx = cx + dx
                        local tz = cz + dz
                        
                        local okBreak = pcall(android.breakBlock, tx, cy, tz)
                        if okBreak then
                            esperarTarea()
                            pcall(android.pickup)
                            equiparSemilla()
                            pcall(android.useBlock, tx, cy, tz)
                            esperarTarea()
                            hizoAlgo = true
                        end
                    end
                end

                if not hizoAlgo then
                    guardarEnCofre()
                end
            end
        end

        sleep(3)
    end
end

local ok, err = pcall(main)
if not ok then
    print("ERROR FATAL: " .. tostring(err))
end
