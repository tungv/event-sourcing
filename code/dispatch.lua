local function identity(x) return x end;

local function handleActions(actions, initialState)
  return function (state, action)
    if state == nil then
      state = initialState;
    end

    local f = actions[action.type] or identity

    if type(f) == "function" then
      return f(state, action)
    else
      error("handler for "..tostring(action.type).." not a function")
    end
  end
end

local function concat(t1, t2)
  local r = { unpack(t1) }
  for i = 1, #t2 do
    r[#t1+i] = t2[i]
  end
  return r
end

local initialState = {
  list = { 1, 2, 3 },
  length = 3
}

local reducer = handleActions({
  PUSH = function (state, action)
    return { length = state.length + 1, list = concat(state.list, {action.payload}) }
  end
}, initialState)

local function dispatch (action)
  local storeKey = KEYS[1] .. '_test'
  local state = redis.call('GET', storeKey)
  if state == nil or state == false then
    state = nil
  else
    state = cjson.decode(state)
  end

  local nextState = reducer(state, action)
  local json = cjson.encode(nextState);
  redis.call('SET', storeKey, json)
  return json
end

local dispatchingAction = cjson.decode(ARGV[1])

return dispatch(dispatchingAction)
