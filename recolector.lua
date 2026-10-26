-- collector.lua
-- CC:Androids 1.3.0 | Minecraft 1.20.1

local android = _G.android
local PAUSA = 1.0

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

-- Buscar cofres cercanos para vaciar el inventario
local function depositarLoot()
    local cofres = android.getBlocksOfType("chest")
    if cofres and #cofres > 0 then
        local cofre = cofres[1]
        print("Vaciando inventario en cofre: " .. cofre.x .. ", " .. cofre.y .. ", " .. cofre.z)
        
        for i = 0, 8 do
            pcall(android.equipSlot, i)
            pcall(android.storeHeldItemInContainer, cofre.x, cofre.y, cofre.z, 0)
        end
    end
end

print("=== RECOLECTOR INICIADO ===")

while true do
    -- Busca ítems en el suelo (entidades de tipo item)
    local items = android.getEntities("item")
    
    if items and #items > 0 then
        for _, item in ipairs(items) do
            if item and item.x and item.y and item.z then
                -- Se mueve hacia donde está el ítem en el suelo para recogerlo
                pcall(android.moveTo, math.floor(item.x), math.floor(item.y), math.floor(item.z))
                esperarTarea()
            end
        end
    else
        -- Si no hay ítems, espera un momento antes de volver a escanear
        sleep(2)
    end

    -- Cada cierto tiempo o si el inventario se llena, busca un cofre y lo deposita
    depositarLoot()
end
