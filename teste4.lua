-- Serviços Necessários
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local deathPosition = nil  -- Posição salva para reviver

-- Variáveis Globais
local flyEnabled = false
local aimbotEnabled = false
local speedEnabled = false
local hitboxEnabled = false
local espEnabled = false
local playerSpeed = 50
local espInstances = {}

-- Função para reviver no mesmo local
local function reviveAtDeathPosition()
    if deathPosition and LocalPlayer.Character then
        local character = LocalPlayer.Character
        if character:FindFirstChild("Humanoid") then
            character:BreakJoints()  -- Matar o personagem para renascer
            -- Esperar até que o personagem tenha morrido
            repeat wait() until not character.Parent
            wait(1)  -- Esperar um pouco para o personagem carregar novamente
            LocalPlayer:LoadCharacter()  -- Carregar o personagem
            -- Teleportar o jogador para a posição salva
            local humanoidRootPart = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
            humanoidRootPart.CFrame = deathPosition
        end
    end
end

-- Detectar a morte e salvar a posição
LocalPlayer.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.HealthChanged:Connect(function(health)
        if health <= 0 then
            deathPosition = character.HumanoidRootPart.CFrame  -- Salvar posição ao morrer
        end
    end)
end)

-- Função para Toggle Fly (Simplesmente usa BodyVelocity para voo)
local function toggleFly()
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        local rootPart = character.HumanoidRootPart
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(400000, 400000, 400000)
        bodyVelocity.Velocity = Vector3.zero
        bodyVelocity.Parent = rootPart
        bodyVelocity.Name = "FlyVelocity"

        RunService.RenderStepped:Connect(function()
            local direction = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction = direction + workspace.CurrentCamera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction = direction - workspace.CurrentCamera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction = direction - workspace.CurrentCamera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction = direction + workspace.CurrentCamera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction = direction + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then direction = direction - Vector3.new(0, 1, 0) end

            bodyVelocity.Velocity = direction.Unit * 50  -- Ajuste a velocidade de voo
        end)

        -- Se o voo for desativado, removemos a BodyVelocity
        LocalPlayer.CharacterRemoving:Connect(function()
            if bodyVelocity.Parent then
                bodyVelocity:Destroy()
            end
        end)
    end
end

-- Função para Aimbot Suavizado
local function toggleAimbot()
    aimbotEnabled = not aimbotEnabled
    if aimbotEnabled then
        RunService.RenderStepped:Connect(function()
            local closestPlayer = nil
            local shortestDistance = math.huge

            -- Loop para encontrar o jogador adversário mais próximo
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

            -- Se um jogador mais próximo for encontrado, suaviza a mira para ele
            if closestPlayer and closestPlayer.Character then
                local torsoPosition = closestPlayer.Character:FindFirstChild("UpperTorso") or closestPlayer.Character.HumanoidRootPart.Position
                local currentCFrame = workspace.CurrentCamera.CFrame
                local targetDirection = (torsoPosition - currentCFrame.Position).Unit
                local smoothDirection = currentCFrame.LookVector:Lerp(targetDirection, 0.1)

                workspace.CurrentCamera.CFrame = CFrame.new(currentCFrame.Position, currentCFrame.Position + smoothDirection)
            end
        end)
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

-- Função Utilitária para Criar ESP
local function createESP(player)
    if espInstances[player] then return end
    local highlight = Instance.new("Highlight")
    highlight.Parent = player.Character
    highlight.Adornee = player.Character
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
    espInstances[player] = highlight
end

-- Função para Remover ESP
local function removeESP(player)
    if espInstances[player] then
        espInstances[player]:Destroy()
        espInstances[player] = nil
    end
end

-- Criando o Painel
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = game.CoreGui
local mainFrame = Instance.new("Frame")
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
mainFrame.Size = UDim2.new(0, 250, 0, 300)
mainFrame.Position = UDim2.new(0.5, -125, 0.5, -150)

local function createButton(name, func, yPos)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 220, 0, 40)
    button.Position = UDim2.new(0.5, -110, 0, yPos)
    button.Text = name
    button.BackgroundColor3 = Color3.fromRGB(0, 128, 255)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Parent = mainFrame
    button.MouseButton1Click:Connect(func)
end

createButton("Fly", toggleFly, 10)
createButton("Reviver", reviveAtDeathPosition, 60)
createButton("Aimbot", toggleAimbot, 110)
createButton("Speed", toggleSpeed, 160)
createButton("Hitbox", toggleHitbox, 210)
createButton("ESP", toggleESP, 260)

-- Função para Mover o Painel
local function dragPanel(panel)
    local dragging = false
    local dragInput, dragStart, startPos

    panel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = panel.Position
        end
    end)

    panel.InputChanged:Connect(function(input)
        if dragging then
            local delta = input.Position - dragStart
            panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    panel.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- Ativar movimentação do painel
dragPanel(mainFrame)

-- Tecla para abrir/fechar o painel
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Home then
        mainFrame.Visible = not mainFrame.Visible
    end
end)
