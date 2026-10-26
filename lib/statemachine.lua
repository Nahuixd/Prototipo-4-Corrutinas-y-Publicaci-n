local StateMachine = {}
StateMachine.__index = StateMachine

function StateMachine.new()
    return setmetatable({ states = {}, current = nil, name = nil }, StateMachine)
end

function StateMachine:add(name, state)
    state.name = name
    state.machine = self
    self.states[name] = state
    return state
end

function StateMachine:switch(name, ...)
    assert(self.states[name], "Estado inexistente: " .. tostring(name))
    if self.current and self.current.leave then self.current:leave() end
    self.current = self.states[name]
    self.name = name
    if self.current.enter then self.current:enter(...) end
end

function StateMachine:update(dt)
    if self.current and self.current.update then self.current:update(dt) end
end

function StateMachine:draw()
    if self.current and self.current.draw then self.current:draw() end
end

function StateMachine:keypressed(key)
    if self.current and self.current.keypressed then self.current:keypressed(key) end
end

return StateMachine