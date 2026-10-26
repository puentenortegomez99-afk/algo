-- recolector.lua
-- CC:Androids 1.3.0 | Minecraft 1.20.1

local android = _G.android
local PAUSA = 2.0

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

-- Función para depositar los ítems recolectados en el cofre cercano
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
    -- El androide revisa y vacía su inventario periódicamente en el cofre
    depositarLoot()
    sleep(3)
end
