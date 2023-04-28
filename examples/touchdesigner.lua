local state = {
  min = {
    0, 0, 0, 0
  },
  max = {
    1, 1, 1, 1
  },
  step = {
    0.01, 0.01, 0.01, 0.01
  },
  data = {
    0, 0, 0, 0
  }
}

local touchdesigner = {
  delta = function(n, d)
    local new = state.data[n] + d * state.step[n]
    if new > state.max[n] then
      new = state.max[n]
    elseif new < state.min[n] then
      new = state.min[n]
    end
    state.data[n] = new
    return new
  end,
  redraw = function(n, datum)
    if datum > state.max[n] then
      datum = state.max[n]
    elseif datum < state.min[n] then
      datum = state.min[n]
    end
    local center = 60 * (datum - state.min[n]) / (state.max[n] - state.min[n]) + 2
    local ret = {}
    for i = 1, 64 do
      local led = (i - 32) % 64 + 1
      if -2 > center - i or center - i > 2 then
        ret[led] = 0
      else
        ret[led] = 15
      end
    end
    return ret
  end,
  configure = function(msg)
    if msg[1] == 'min' then
      for i = 1,4 do
        state.min[i] = msg[i+1]
      end
    elseif msg[1] == 'max' then
      for i = 1,4 do
        state.max[i] = msg[i+1]
      end
    elseif msg[1] == 'step' then
      for i=1,4 do
        state.step[i] = msg[i+1]
      end
    end
  end
}

return touchdesigner
