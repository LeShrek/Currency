-- Services
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

-- Modules
local Module = {}
Module.__index = Module

local CurrencyModule = {}
CurrencyModule.__index = CurrencyModule

local Types = require(script:WaitForChild("Types"))
local Instantiate = require(script:WaitForChild("Instantiate"))

-- Variables
local datastore = DataStoreService:GetDataStore("CurrencyModule")

-- Private functions
local function initialize(self: {Values: {[string]: Types.AddValue}})
    local function createLeaderboard(player: Player)
        if player:FindFirstChild("leaderstats") then return end
        if player:FindFirstChild("hiddenstats") then return end

        local leaderstats = nil
        local hiddenstats = nil

        if not self.Values then return end
        for _, valueInfo in self.Values do
            if valueInfo.HideValue and not hiddenstats then
                hiddenstats = Instantiate:CreateInstance("Folder", {
                    Name = "hiddenstats",
                    Parent = player
                })
            elseif not valueInfo.HideValue and not leaderstats then
                leaderstats = Instantiate:CreateInstance("Folder", {
                    Name = "leaderstats",
                    Parent = player
                })
            end

            local valueType = type(valueInfo.DefaultValue)
            local capitalized = string.upper(string.sub(valueType, 1, 1))..string.sub(valueType, 2, string.len(valueType))
            Instantiate:CreateInstance(capitalized.."Value", {
                Name = valueInfo.Name,
                Value = valueInfo.DefaultValue,
                Parent = valueInfo.HideValue and hiddenstats or leaderstats
            })
        end

        if self.Save then
            local success, errormessage = pcall(function()
                local savedData = datastore:GetAsync(player.UserId.."-playerData")
                if not savedData then return end
    
                for _, info in savedData do
                    local folderToSearch = info.Hide and "hiddenstats" or "leaderstats"
                    local folder = player:WaitForChild(folderToSearch, 2)
                    if not folder then continue end

                    local value = folder:WaitForChild(info.Name, 2)
                    if not value then continue end
                    if not Instantiate:HasProperty(value, "Value") then continue end

                    value.Value  = info.Value
                end
            end)
            if not success then warn(errormessage) end
        end
    end

    local function saveData(player: Player)
        if not self.Save then return end

        local dataToSave = {}
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            for _, child in leaderstats:GetChildren() do
                if not Instantiate:HasProperty(child, "Value") then continue end
                table.insert(dataToSave, {
                    Name = child.Name,
                    Value = child.Value,
                    Hide = false
                })
            end
        end

        local hiddenstats = player:FindFirstChild("hiddenstats")
        if hiddenstats then
            for _, child in hiddenstats:GetChildren() do
                if not Instantiate:HasProperty(child,"Value") then continue end
                table.insert(dataToSave, {
                    Name = child.Name,
                    Value = child.Value,
                    Hide = true
                })
            end
        end

        datastore:SetAsync(player.UserId.."-playerData", dataToSave)
    end

    Players.PlayerAdded:Connect(createLeaderboard)
    Players.PlayerRemoving:Connect(saveData)
    for _, player in Players:GetPlayers() do
        createLeaderboard(player)
    end
end

-- Public functions

-- #region CurrencyModule
function CurrencyModule:GetValue(player: Player, valueName: string): any
    local info = nil
    for _, currentInfo in self.Values do
        if currentInfo.Name ~= valueName then continue end
        info = currentInfo
    end
    if not info then return end

    local folderToSearch = info.HideValue and "hiddenstats" or "leaderstats"
    local folder = player:WaitForChild(folderToSearch, 2)
    if not folder then return end

    local val = folder:WaitForChild(valueName, 2)
    if not val then return end
    return val.Value
end

function CurrencyModule:SetValue(player: Player, valueName: string, value: any)
    local info = nil
    for _, currentInfo in self.Values do
        if currentInfo.Name ~= valueName then continue end
        info = currentInfo
    end
    if not info then return end

    local folderToSearch = info.HideValue and "hiddenstats" or "leaderstats"
    local folder = player:WaitForChild(folderToSearch, 2)
    if not folder then return end

    local val = folder:WaitForChild(valueName, 2)
    if not val then return end

    val.Value = value
end
-- #endregion

-- #region Module
function Module:AddValue(value: Types.AddValue)
    if not value.Name then warn("No Name value given") return end
    if not value.DefaultValue then warn("No DefaultValue given") return end
    if value.HideValue == nil then value.HideValue = Types.Default.AddValue.HideValue end
    if not Module.Values then Module.Values = {} end

    local hasValue = false
    for _, info in Module.Values do
        if info.Name ~= value.Name then continue end
        hasValue = true
        break
    end
    if hasValue then warn(`Value of name: {value.Name} already exists`) return end
    table.insert(Module.Values, value)
end

function Module.new(saveValues: boolean)
    local self = setmetatable({}, CurrencyModule)
    self.Values = Module.Values
    self.Save = saveValues == nil and true or saveValues 
    initialize(self)
    return self
end
-- #endregion

return Module