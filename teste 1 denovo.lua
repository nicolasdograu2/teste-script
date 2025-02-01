-- Serviços Necessários
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local deathPosition = nil  -- Posição salva para reviver

-- Variáveis Globais
local noClipEnabled = false
local speedEnabled = false
local hitboxEnabled = false
local espEnabled = false
local flyEnabled = false
local playerSpeed = 50
local espInstances = {}
local connections = {}

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

-- Função para Toggle Hitbox
local function toggleHitbox()
    hitboxEnabled = not hitboxEnabled
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = player.Character.HumanoidRootPart
            if hitboxEnabled then
                rootPart.Size = Vector3.new(5, 5, 5)
                rootPart.Transparency = 0.7
                rootPart.BrickColor = BrickColor.new("Bright red")
                rootPart.Material = Enum.Material.Neon
            else
                rootPart.Size = Vector3.new(2, 2, 1)
                rootPart.Transparency = 1
                rootPart.BrickColor = BrickColor.new("Medium stone grey")
                rootPart.Material = Enum.Material.Plastic
            end
        end
    end
end

-- Função para Toggle ESP
local function toggleESP()
    espEnabled = not espEnabled
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if espEnabled then
                createESP(player)
            else
                removeESP(player)
            end
        end
    end
end

-- Criando o Painel
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game.CoreGui
local mainFrame = Instance.new("Frame")
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.Size = UDim2.new(0, 250, 0, 350)
mainFrame.Position = UDim2.new(0.5, -125, 0.5, -175)
mainFrame.BorderSizePixel = 0
mainFrame.BackgroundTransparency = 0.2

-- Função para criar os botões
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

-- Adicionando todos os botões ao painel
createButton("No Clip", toggleNoClip, 10, noClipEnabled)
createButton("Speed", toggleSpeed, 60, speedEnabled)
createButton("Fly", toggleFly, 110, flyEnabled)
createButton("Hitbox", toggleHitbox, 160, hitboxEnabled)
createButton("ESP", toggleESP, 210, espEnabled)

-- Tecla para abrir/fechar o painel
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Home then
        mainFrame.Visible = not mainFrame.Visible
    end
end)
