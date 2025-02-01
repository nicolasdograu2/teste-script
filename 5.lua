-- Serviços Necessários
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Variáveis Globais
local noClipEnabled = false
local speedEnabled = false
local hitboxEnabled = false
local espEnabled = false
local flyEnabled = false
local farmTycoonEnabled = false
local playerSpeed = 50
local espInstances = {}
local connections = {}

-- Criar Painel
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game.CoreGui
local mainFrame = Instance.new("Frame")
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.Size = UDim2.new(0, 250, 0, 400)
mainFrame.Position = UDim2.new(0.5, -125, 0.5, -200)
mainFrame.BorderSizePixel = 0
mainFrame.BackgroundTransparency = 0.2

-- Título do Painel
local title = Instance.new("TextLabel")
title.Parent = mainFrame
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "ModMenu"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.TextSize = 20

-- Criar botões dinâmicos
local function createButton(name, func, yPos, toggleVar)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 220, 0, 40)
    button.Position = UDim2.new(0.5, -110, 0, yPos)
    button.Text = name
    button.BackgroundColor3 = Color3.fromRGB(0, 128, 255)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Parent = mainFrame
    
    button.MouseButton1Click:Connect(function()
        func()
        button.BackgroundColor3 = toggleVar and Color3.fromRGB(50, 150, 255) or Color3.fromRGB(0, 128, 255)
    end)
end

-- Função para No Clip
local function toggleNoClip()
    noClipEnabled = not noClipEnabled
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoid and rootPart then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, not noClipEnabled)
            rootPart.CanCollide = not noClipEnabled
        end
    end
end

-- Função para Modificar Velocidade
local function toggleSpeed()
    speedEnabled = not speedEnabled
    if speedEnabled then
        connections["speed"] = RunService.Stepped:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.WalkSpeed = 100
            end
        end)
    else
        if connections["speed"] then connections["speed"]:Disconnect() end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 16
        end
    end
end

-- Função para Toggle Fly
local function toggleFly()
    flyEnabled = not flyEnabled
    if flyEnabled then
        connections["fly"] = RunService.RenderStepped:Connect(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0, 50, 0)
            end
        end)
    else
        if connections["fly"] then connections["fly"]:Disconnect() end
    end
end

-- Função para Farm de Tycoon
toggleFarmTycoon = function()
    farmTycoonEnabled = not farmTycoonEnabled
    if farmTycoonEnabled then
        connections["farmTycoon"] = RunService.RenderStepped:Connect(function()
            for _, tycoonPart in pairs(workspace:GetDescendants()) do
                if tycoonPart:IsA("TouchTransmitter") and tycoonPart.Parent then
                    firetouchinterest(LocalPlayer.Character.HumanoidRootPart, tycoonPart.Parent, 0)
                    wait(0.1)
                    firetouchinterest(LocalPlayer.Character.HumanoidRootPart, tycoonPart.Parent, 1)
                end
            end
        end)
    else
        if connections["farmTycoon"] then connections["farmTycoon"]:Disconnect() end
    end
end

-- Adicionando todos os botões ao painel
createButton("No Clip", toggleNoClip, 40, noClipEnabled)
createButton("Speed", toggleSpeed, 90, speedEnabled)
createButton("Fly", toggleFly, 140, flyEnabled)
createButton("Farm Tycoon", toggleFarmTycoon, 190, farmTycoonEnabled)

-- Tecla para abrir/fechar o painel
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Home then
        mainFrame.Visible = not mainFrame.Visible
    elseif input.KeyCode == Enum.KeyCode.Zero then
        -- Fechar o script completamente
        screenGui:Destroy()
        connections = {}  -- Desconectar todas as conexões
    end
end)
