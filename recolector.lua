-- recolector.lua
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

-- Depositar inventario en el cofre más cercano
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
    -- Como método alternativo seguro, revisamos el área o usamos comandos de succión si están disponibles,
    -- o barremos los bloques de items caídos si la API lo soporta.
    -- Si tu versión tiene una función específica de aspirado, la usaremos aquí:
    local ok, res = pcall(android.suction) -- O la función de recolección de zona de tu versión
    
    -- Si no existe suction, el androide se mantiene a la escucha y vacía al cofre cercano
    depositarLoot()
    
    sleep(3)
end
