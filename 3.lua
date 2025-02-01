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
local connections = {}

-- Criar Painel
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game.CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.Size = UDim2.new(0, 260, 0, 400)
mainFrame.Position = UDim2.new(0.5, -130, 0.5, -200)
mainFrame.BorderSizePixel = 0
mainFrame.BackgroundTransparency = 0.2

-- Título do Painel
local title = Instance.new("TextLabel")
title.Parent = mainFrame
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "ModMenu"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.TextSize = 22

title.Font = Enum.Font.GothamBold

title.TextStrokeTransparency = 0.5

-- Criar botões dinâmicos
local function createButton(name, func, yPos, toggleVar)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 220, 0, 40)
    button.Position = UDim2.new(0.5, -110, 0, yPos)
    button.Text = name
    button.BackgroundColor3 = Color3.fromRGB(0, 128, 255)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Parent = mainFrame
    button.Font = Enum.Font.Gotham
    button.TextSize = 18
    
    button.MouseButton1Click:Connect(function()
        func()
        if toggleVar then
            if _G[toggleVar] then
                button.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
            else
                button.BackgroundColor3 = Color3.fromRGB(0, 128, 255)
            end
        end
    end)
end

-- Função para No Clip
local function toggleNoClip()
    noClipEnabled = not noClipEnabled
    connections["noClip"] = RunService.Stepped:Connect(function()
        if LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = not noClipEnabled
                end
            end
        end
    end)
    if not noClipEnabled and connections["noClip"] then
        connections["noClip"]:Disconnect()
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

-- Função ESP com linha entre jogadores
local function toggleESP()
    espEnabled = not espEnabled
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = player.Character.HumanoidRootPart
            if espEnabled then
                local line = Drawing.new("Line")
                line.Thickness = 2
                line.Color = Color3.fromRGB(255, 0, 0)
                connections[player.Name] = RunService.RenderStepped:Connect(function()
                    local rootPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(rootPart.Position)
                    local myPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and workspace.CurrentCamera:WorldToViewportPoint(LocalPlayer.Character.HumanoidRootPart.Position)
                    if onScreen and myPos then
                        line.From = Vector2.new(myPos.X, myPos.Y)
                        line.To = Vector2.new(rootPos.X, rootPos.Y)
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                end)
            else
                if connections[player.Name] then connections[player.Name]:Disconnect() end
            end
        end
    end
end

-- Adicionando todos os botões ao painel
createButton("No Clip", toggleNoClip, 40, "noClipEnabled")
createButton("Speed", toggleSpeed, 90, "speedEnabled")
createButton("Fly", toggleFly, 140, "flyEnabled")
createButton("ESP", toggleESP, 190, "espEnabled")

-- Tecla para abrir/fechar o painel
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Home then
        mainFrame.Visible = not mainFrame.Visible
    end
end)
