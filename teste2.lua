-- Serviços Necessários
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Variáveis Globais
local flyEnabled = false
local aimbotEnabled = false
local speedEnabled = false
local hitboxEnabled = false
local espEnabled = false
local playerSpeed = 50
local flyConnection = nil
local aimbotConnection = nil
local hitboxSize = Vector3.new(5, 5, 5)
local espInstances = {}

-- Função Utilitária para Criar ESP com Diferenciação de Cores
local function createESP(player)
    if espInstances[player] then return end

    local highlight = Drawing.new("Box")
    highlight.Visible = true
    highlight.Outline = true
    highlight.Thickness = 2
    highlight.Color = player.Team == LocalPlayer.Team and Color3.fromRGB(0, 0, 255) or Color3.fromRGB(255, 0, 0)

    espInstances[player] = highlight

    RunService.RenderStepped:Connect(function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = player.Character.HumanoidRootPart
            local screenPosition, onScreen = workspace.CurrentCamera:WorldToViewportPoint(rootPart.Position)

            highlight.Visible = onScreen and espEnabled
            if highlight.Visible then
                highlight.Position = Vector2.new(screenPosition.X, screenPosition.Y)
                highlight.Size = Vector2.new(50, 50)
            end
        else
            highlight.Visible = false
        end
    end)
end

-- Função para Remover ESP
local function removeESP(player)
    if espInstances[player] then
        espInstances[player]:Remove()
        espInstances[player] = nil
    end
end

-- Função para Toggle Fly
local function toggleFly()
    flyEnabled = not flyEnabled
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    local rootPart = character.HumanoidRootPart
    if flyEnabled then
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(400000, 400000, 400000)
        bodyVelocity.Velocity = Vector3.zero
        bodyVelocity.Parent = rootPart

        flyConnection = RunService.RenderStepped:Connect(function()
            local direction = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += workspace.CurrentCamera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= workspace.CurrentCamera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= workspace.CurrentCamera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += workspace.CurrentCamera.CFrame.RightVector end

            bodyVelocity.Velocity = direction.Unit * 50
        end)
    else
        if flyConnection then flyConnection:Disconnect() flyConnection = nil end
        if rootPart:FindFirstChild("BodyVelocity") then
            rootPart.BodyVelocity:Destroy()
        end
    end
end

-- Função para Aimbot Suavizado
local function toggleAimbot()
    aimbotEnabled = not aimbotEnabled

    if aimbotEnabled then
        aimbotConnection = RunService.RenderStepped:Connect(function()
            local closestPlayer = nil
            local shortestDistance = math.huge

            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team and player.Character then
                    local torso = player.Character:FindFirstChild("UpperTorso") or player.Character:FindFirstChild("HumanoidRootPart")
                    if torso then
                        local screenPosition, onScreen = workspace.CurrentCamera:WorldToViewportPoint(torso.Position)
                        if onScreen then
                            local mousePosition = UserInputService:GetMouseLocation()
                            local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - mousePosition).Magnitude
                            if distance < shortestDistance then
                                closestPlayer = player
                                shortestDistance = distance
                            end
                        end
                    end
                end
            end

            if closestPlayer and closestPlayer.Character then
                local torsoPosition = closestPlayer.Character:FindFirstChild("UpperTorso") or closestPlayer.Character.HumanoidRootPart.Position
                local currentCFrame = workspace.CurrentCamera.CFrame
                local targetDirection = (torsoPosition - currentCFrame.Position).Unit
                local smoothDirection = currentCFrame.LookVector:Lerp(targetDirection, 0.1)

                workspace.CurrentCamera.CFrame = CFrame.new(currentCFrame.Position, currentCFrame.Position + smoothDirection)
            end
        end)
    else
        if aimbotConnection then aimbotConnection:Disconnect() aimbotConnection = nil end
    end
end

-- Função para Modificar Velocidade
local function toggleSpeed()
    speedEnabled = not speedEnabled
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.WalkSpeed = speedEnabled and playerSpeed or 16
    end
end

-- Função para Toggle Hitbox
local function toggleHitbox()
    hitboxEnabled = not hitboxEnabled

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = player.Character.HumanoidRootPart

            if hitboxEnabled then
                rootPart.Size = hitboxSize
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
            createESP(player)
        end
    end
end

-- Interface Gráfica
local screenGui = Instance.new("ScreenGui")
local mainFrame = Instance.new("Frame")
local buttons = {}

local function createButton(name, position, callback)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Text = name
    button.Size = UDim2.new(0, 180, 0, 30)
    button.Position = UDim2.new(0, 10, 0, position)
    button.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.MouseButton1Click:Connect(callback)
    button.Parent = mainFrame
    table.insert(buttons, button)
end

screenGui.Parent = game.CoreGui
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
mainFrame.Position = UDim2.new(0.5, -100, 0.5, -100)
mainFrame.Size = UDim2.new(0, 200, 0, 250)

createButton("Toggle Fly", 10, toggleFly)
createButton("Toggle Aimbot", 50, toggleAimbot)
createButton("Toggle Speed", 90, toggleSpeed)
createButton("Toggle Hitbox", 130, toggleHitbox)
createButton("Toggle ESP", 170, toggleESP)
