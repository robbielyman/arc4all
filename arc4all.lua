local osc = require('losc')
local plugin = require('losc.plugins.udp-socket')
local err, handler = pcall(require, arg[1])

local function validate(b, x)
  if not b then return false end
  if not x then return false end
  if not x.delta or type(x.delta) ~= 'function' then return false end
  if not x.redraw or type(x.redraw) ~= 'function' then return false end
  if not x.configure or type(x.configure) ~= 'function' then return false end
  return true
end

if not validate(err, handler) then
  print('bad handler argument')
  return
end

local serialosc = osc.new {
  plugin = plugin.new {
    sendAddr = 'localhost',
    sendPort = 12002,
    recvAddr = 'localhost',
    recvPort = 8000
  }
}

local arc
local prefix = '/monome'
local broadcast = osc.new {
  plugin = plugin.new {
    sendAddr = 'localhost',
    sendPort = 9000
  }
}

local function lotsofis()
  local ret = ''
  for i = 1, 65 do
    ret = ret .. 'i'
  end
  return ret
end

local function start_arc(port)
  arc = osc.new {
    plugin = plugin.new {
      sendAddr = 'localhost',
      sendPort = port,
      recvAddr = 'localhost',
      recvPort = 8000
    }
  }
  arc:add_handler('/sys/prefix', function(data)
    local msg = data.message
    prefix = msg[1]
    msg = arc.new_message {
      address = '/sys/port',
      types = 'i',
      8000
    }
    arc:send(msg)
    arc:add_handler(prefix .. '/enc/delta', function(data)
      local msg = data.message
      local ring = msg[1] + 1
      local delta = msg[2]
      local response = handler.delta(ring, delta)
      if response then
        local message = broadcast.new_message {
          address = '/val' .. ring,
          types = 'f',
          response
        }
        broadcast:send(message)
      end
    end)
    arc:add_handler('/redraw', function(data)
      local msg = data.message
      local ring = msg[1]
      local datum = msg[2]
      local leds = handler.redraw(ring, datum)
      local message = arc.new_message {
        address = prefix .. '/ring/map',
        types = lotsofis(),
        ring, table.unpack(leds)
      }
      arc:send(message)
    end)
    for i = 1,4 do
      arc:add_handler('/redraw' .. i, function (data)
        local msg = data.message
        local datum = msg[1]
        local leds = handler.redraw(i, datum)
        local message = arc.new_message {
          address = prefix .. '/ring/map',
          types = lotsofis(),
          i - 1, table.unpack(leds)
        }
        arc:send(message)
      end)
    end
  end)
  arc:add_handler('/configure', function (data)
    local msg = data.message
    handler.configure(msg)
  end)
  local message = arc.new_message {
    address = '/sys/info',
    types = 'si',
    'localhost', 8000
  }
  arc:send(message)
  arc:open()
end

serialosc:add_handler('/serialosc/device', function(data)
  local msg = data.message
  if not string.find(msg[2], 'arc') then
    print('device is not an arc!')
    return
  end
  local send_port = msg[3]
  print('found arc on port: ' .. send_port)
  print('closing connection to serialosc')
  serialosc:close()
  print('starting arc connection')
  start_arc(send_port)
end)

local message = serialosc.new_message {
  address = '/serialosc/list',
  types = 'si',
  'localhost', 8000
}
print('starting serialosc')
serialosc:send(message)
serialosc:open()
