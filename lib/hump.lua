local hump = {}

function hump.class(attributes)
    local new_class = {}
    new_class.__index = new_class
    
    if attributes then
        for k, v in pairs(attributes) do
            new_class[k] = v
        end
    end
    
    new_class.extend = function(self, sub_class)
        sub_class = sub_class or {}
        sub_class.__index = sub_class
        setmetatable(sub_class, { __index = self })
        sub_class.extend = self.extend
        return sub_class
    end
    
    return new_class
end

return hump