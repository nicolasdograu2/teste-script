-- Serviços Necessários
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local deathPosition = nil  -- Posição salva para reviver

-- Variáveis Globais
local noClipEnabled = false
local aimbotEnabled = false
local speedEnabled = false
local hitboxEnabled = false
local espEnabled = false
local playerSpeed = 50
local espInstances = {}
local flying = false
local flightSpeed = 50  -- Velocidade do voo

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
            -- Esperar o personagem carregar e teleportar para a posição salva
            LocalPlayer.CharacterAdded:Wait()
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

-- Função para No Clip
local function toggleNoClip()
    noClipEnabled = not noClipEnabled
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoid and rootPart then
            if noClipEnabled then
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)  -- Desativa a física do corpo
                rootPart.CanCollide = false  -- Ativa o no clip
                flying = true  -- Permite o voo
            else
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)  -- Restaura a física
                rootPart.CanCollide = true  -- Desativa o no clip
                flying = false  -- Desativa o voo
            end
        end
    end
end

-- Função para controlar o voo
RunService.RenderStepped:Connect(function()
    if noClipEnabled and flying then
        local character = LocalPlayer.Character
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            local moveDirection = Vector3.new(0, 0, 0)

            -- Controlando a altura (subir/descer)
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDirection = Vector3.new(0, 1, 0) * flightSpeed
            elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveDirection = Vector3.new(0, -1, 0) * flightSpeed
            end

            -- Controlando o movimento horizontal
            local forward = UserInputService:IsKeyDown(Enum.KeyCode.W) and Vector3.new(0, 0, -1) * flightSpeed or Vector3.new(0, 0, 0)
            local backward = UserInputService:IsKeyDown(Enum.KeyCode.S) and Vector3.new(0, 0, 1) * flightSpeed or Vector3.new(0, 0, 0)
            local left = UserInputService:IsKeyDown(Enum.KeyCode.A) and Vector3.new(-1, 0, 0) * flightSpeed or Vector3.new(0, 0, 0)
            local right = UserInputService:IsKeyDown(Enum.KeyCode.D) and Vector3.new(1, 0, 0) * flightSpeed or Vector3.new(0, 0, 0)

            -- Movimentação total
            moveDirection = moveDirection + forward + backward + left + right
            humanoidRootPart.Velocity = moveDirection
        end
    end
end)

-- Função para Aimbot (somente nos inimigos, mais próximo, dentro da linha de visão)
local function toggleAimbot()
    aimbotEnabled = not aimbotEnabled
    if aimbotEnabled then
        RunService.RenderStepped:Connect(function()
            local closestPlayer = nil
            local shortestDistance = math.huge
            local camera = workspace.CurrentCamera
            local maxFov = 150  -- Diminuindo o FOV para pegar apenas inimigos mais próximos

            -- Loop para encontrar o jogador adversário mais próximo
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team and player.Character then
                    local torso = player.Character:FindFirstChild("UpperTorso") or player.Character:FindFirstChild("HumanoidRootPart")
                    if torso then
                        -- Verificar se o jogador está na linha de visão
                        local ray = Ray.new(camera.CFrame.Position, (torso.Position - camera.CFrame.Position).unit * 500)
                        local hitPart, hitPosition = workspace:FindPartOnRay(ray, LocalPlayer.Character)

                        if hitPart and hitPart.Parent == player.Character then
                            local screenPosition, onScreen = camera:WorldToViewportPoint(torso.Position)
                            if onScreen then
                                local mousePosition = UserInputService:GetMouseLocation()
                                local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - mousePosition).Magnitude
                                if distance < shortestDistance and distance < maxFov then  -- Ajustando o FOV
                                    closestPlayer = player
                                    shortestDistance = distance
                                end
                            end
                        end
                    end
                end
            end

            -- Se um jogador mais próximo for encontrado, suaviza a mira para ele
            if closestPlayer and closestPlayer.Character then
                local torsoPosition = closestPlayer.Character:FindFirstChild("UpperTorso") or closestPlayer.Character.HumanoidRootPart.Position
                local currentCFrame = camera.CFrame
                local targetDirection = (torsoPosition - currentCFrame.Position).Unit
                local smoothDirection = currentCFrame.LookVector:Lerp(targetDirection, 0.1)

                camera.CFrame = CFrame.new(currentCFrame.Position, currentCFrame.Position + smoothDirection)
            end
        end)
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
    highlight.FillColor = player.Team == LocalPlayer.Team and Color3.fromRGB(0, 0, 255) or Color3.fromRGB(255, 0, 0)  -- Aliados em azul, inimigos em vermelho
    highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
    highlight.OutlineTransparency = 0.5  -- Adicionando transparência para o contorno
    espInstances[player] = highlight
end

-- Função para Remover ESP
local function removeESP(player)
    if espInstances[player] then
        espInstances[player]:Destroy()
        espInstances[player] = nil
    end
end

-- Função para Reiniciar o Script
local function restartScript()
    -- O método mais simples de reiniciar o script é matar o jogador e recarregar o personagem
    LocalPlayer:LoadCharacter()
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

-- Adicionando bordas e sombras para melhorar a estética
local shadow = Instance.new("ImageLabel")
shadow.Parent = mainFrame
shadow.Size = UDim2.new(1, 10, 1, 10)
shadow.Position = UDim2.new(0, -5, 0, -5)
shadow.Image = "rbxassetid://266362248" -- Imagem de sombra
shadow.ImageTransparency = 0.7
shadow.BackgroundTransparency = 1

-- Função para criar os botões
local function createButton(name, func, yPos)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 220, 0, 40)
    button.Position = UDim2.new(0.5, -110, 0, yPos)
    button.Text = name
    button.BackgroundColor3 = Color3.fromRGB(0, 128, 255)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Parent = mainFrame
    button.MouseButton1Click:Connect(func)

    -- Alterar a cor do botão de acordo com o estado da função
    button.BackgroundColor3 = noClipEnabled and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 128, 255)

    -- Estilizando o botão
    button.BorderSizePixel = 0
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 18
    button.BackgroundTransparency = 0.2
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
    end)
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(0, 128, 255)
    end)
end

-- Adicionando todos os botões ao painel
createButton("No Clip", toggleNoClip, 10)
createButton("Reviver", reviveAtDeathPosition, 60)
createButton("Aimbot", toggleAimbot, 110)
createButton("Speed", toggleSpeed, 160)
createButton("Hitbox", toggleHitbox, 210)
createButton("ESP", toggleESP, 260)
createButton("Restart", restartScript, 310)

-- Tecla para abrir/fechar o painel
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Home then
        mainFrame.Visible = not mainFrame.Visible
    end
    -- Tecla "0" para reiniciar
    if input.KeyCode == Enum.KeyCode.Zero then
        restartScript()
    end
end)

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

dragPanel(mainFrame)
