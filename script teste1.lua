-- Serviços Necessários
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- Variáveis Globais
local flyEnabled = false
local aimbotEnabled = false
local speedEnabled = false
local hitboxEnabled = false
local playerSpeed = 50
local flyConnection = nil
local aimbotConnection = nil
local hitboxSize = Vector3.new(5, 5, 5) -- Tamanho da hitbox
local espInstances = {}

-- Função Utilitária para Criar ESP com Drawing
local function createESP(player)
    if espInstances[player] then return end

    local highlight = Drawing.new("Box")
    highlight.Visible = true
    highlight.Outline = true
    highlight.Color = Color3.fromRGB(255, 0, 0)  -- Red color for enemies
    highlight.Thickness = 2
    highlight.Size = Vector2.new(5, 5)

    espInstances[player] = highlight

    RunService.RenderStepped:Connect(function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = player.Character.HumanoidRootPart
            local screenPosition, onScreen = workspace.CurrentCamera:WorldToViewportPoint(rootPart.Position)

            if onScreen and player.Team ~= LocalPlayer.Team then
                highlight.Position = Vector2.new(screenPosition.X, screenPosition.Y)
                highlight.Size = Vector2.new(rootPart.Size.X, rootPart.Size.Y)
                highlight.Visible = true
            else
                highlight.Visible = false
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

            -- Loop para encontrar o jogador adversário mais próximo
            for _, player in pairs(Players:GetPlayers()) do
                -- Garantir que não é o próprio jogador e que o personagem está carregado
                if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team and player.Character then
                    local torso = player.Character:FindFirstChild("UpperTorso") or player.Character:FindFirstChild("HumanoidRootPart")
                    if torso then
                        -- Calcula a posição na tela do jogador
                        local screenPosition, onScreen = workspace.CurrentCamera:WorldToViewportPoint(torso.Position)

                        -- Verifica se o jogador está na tela
                        if onScreen then
                            -- Calcula a distância até o mouse do jogador
                            local mousePosition = UserInputService:GetMouseLocation()
                            local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - mousePosition).Magnitude

                            -- Verifica se a distância é a menor encontrada até agora
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
                -- Suaviza a direção da câmera em direção ao alvo
                local currentCFrame = workspace.CurrentCamera.CFrame
                local targetDirection = (torsoPosition - currentCFrame.Position).Unit
                local smoothDirection = currentCFrame.LookVector:Lerp(targetDirection, 0.1)  -- "0.1" controla a suavização da transição

                -- Ajusta a câmera para olhar no jogador mais próximo
                workspace.CurrentCamera.CFrame = CFrame.new(currentCFrame.Position, currentCFrame.Position + smoothDirection)
            end
        end)
    else
        -- Desconectar a conexão quando o aimbot for desativado
        if aimbotConnection then
            aimbotConnection:Disconnect()
            aimbotConnection = nil
        end
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
                rootPart.Transparency = 0.7 -- Transparência para facilitar a visualização
                rootPart.BrickColor = BrickColor.new("Bright red") -- Cor vermelha para destaque
                rootPart.Material = Enum.Material.Neon -- Material neon para brilho
            else
                rootPart.Size = Vector3.new(2, 2, 1) -- Tamanho original
                rootPart.Transparency = 1 -- Invisível
                rootPart.BrickColor = BrickColor.new("Medium stone grey") -- Cor original
                rootPart.Material = Enum.Material.Plastic -- Material original
            end
        end
    end
end

-- Comandos de Chat para Ativar Recursos
LocalPlayer.Chatted:Connect(function(msg)
    local command, arg = msg:match("^(%S+)%s*(.-)$")
    if command then
        command = command:lower()
        if command == "fly" then
            toggleFly()
        elseif command == "aimbot" then
            toggleAimbot()
        elseif command == "speed" then
            playerSpeed = tonumber(arg) or 50
            toggleSpeed()
        elseif command == "esp" then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    createESP(player)
                end
            end
        elseif command == "hitbox" then
            toggleHitbox()
        end
    end
end)

-- Eventos para Gerenciar ESP
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if player ~= LocalPlayer then
            createESP(player)
        end
    end)

    player.CharacterRemoving:Connect(function()
        removeESP(player)
    end)
end)
