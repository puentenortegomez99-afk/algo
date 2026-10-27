-- sigue_android.lua
-- Chunky Turtle seguidora para Advanced Androids

local CANAL_RADIO = 1234
local COMBUSTIBLE_MINIMO = 500
local DISTANCIA_SEGURIDAD = 3 -- Bloques de distancia máxima antes de moverse

-- Inicializar modem inalambrico
local modem = peripheral.find("wirelessModem") or peripheral.find("modem")
if not modem then
  error("Error: Se requiere un Wireless Modem equipado en la turtle.")
end
modem.open(CANAL_RADIO)

print("--- CHUNKY TURTLE SEGUIDORA ACTIVA ---")
print("Chunkloader de Advanced Peripherals en ejecución. Escuchando canal " .. CANAL_RADIO)

-- Autorefuel automático
local function verificarCombustible()
  if turtle.getFuelLevel() < COMBUSTIBLE_MINIMO then
    print("[Refuel] Combustible bajo (" .. turtle.getFuelLevel() .. "). Buscando en inventario...")
    for slot = 1, 16 do
      turtle.select(slot)
      if turtle.refuel(0) then
        turtle.refuel(64)
        print("[Refuel] ¡Recarga exitosa! Nivel: " .. turtle.getFuelLevel())
        turtle.select(1)
        return true
      end
    end
    print("[ADVERTENCIA] ¡La tortuga se ha quedado sin combustible!")
    turtle.select(1)
  end
end

-- Variables para control de orientación de la tortuga (0: +Z, 1: -X, 2: -Z, 3: +X)
local dirActual = 0

local function girarA(nuevaDir)
  while dirActual ~= nuevaDir do
    local diff = (nuevaDir - dirActual) % 4
    if diff == 3 then
      turtle.turnLeft()
      dirActual = (dirActual - 1) % 4
    else
      turtle.turnRight()
      dirActual = (dirActual + 1) % 4
    end
  end
end

-- Navegación paso a paso hacia las coordenadas del Android
local function moverA(targetX, targetY, targetZ)
  local x, y, z = gps.locate(2)
  if not x then return end

  -- Eje Y (Altura)
  while y < targetY do if turtle.up() then y = y + 1 else break end end
  while y > targetY do if turtle.down() then y = y - 1 else break end end

  -- Eje X
  if x < targetX then
    girarA(3)
    while x < targetX do if turtle.forward() then x = x + 1 else turtle.dig() end end
  elseif x > targetX then
    girarA(1)
    while x > targetX do if turtle.forward() then x = x - 1 else turtle.dig() end end
  end

  -- Eje Z
  if z < targetZ then
    girarA(0)
    while z < targetZ do if turtle.forward() then z = z + 1 else turtle.dig() end end
  elseif z > targetZ then
    girarA(2)
    while z > targetZ do if turtle.forward() then z = z - 1 else turtle.dig() end end
  end
end

-- Bucle Principal
while true do
  verificarCombustible()

  -- Escuchar la posición del Android
  local event, modemObj, senderChannel, replyChannel, message, distance = os.pullEvent("modem_message")

  if senderChannel == CANAL_RADIO and type(message) == "table" and message.x then
    local ax, ay, az = message.x, message.y, message.z
    
    local myX, myY, myZ = gps.locate(2)
    if myX then
      local dist = math.sqrt((ax - myX)^2 + (ay - myY)^2 + (az - myZ)^2)
      -- Si el androide avanza y se aleja, la tortuga se desplaza a su zaga
      if dist > DISTANCIA_SEGURIDAD then
        moverA(ax, ay, az - 1) -- Se coloca un bloque detrás del androide
      end
    end
  end
end
