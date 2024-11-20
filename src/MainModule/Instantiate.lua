local Instantiate = {}

function Instantiate:HasProperty(instance: Instance, propertyName: string): boolean
    local success = pcall(function()
        instance[propertyName] = instance[propertyName]
    end)
    return success
end

function Instantiate:SetProperties(instance: Instance, properties: {[string]: any})
    for property, value in properties do
        if not self:HasProperty(instance, property) then continue end
        instance[property] = value
    end
end

function Instantiate:CreateInstance(className: string, properties: {[string]: any}): Instance
    local instance = Instance.new(className)
    self:SetProperties(instance, properties)
    return instance
end

return Instantiate