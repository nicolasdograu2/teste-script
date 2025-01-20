local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local deathPosition = nil  -- Posição salva para reviver

local noClipEnabled = false
local aimbotEnabled = false
local speedEnabled = false
local hitboxEnabled = false
local espEnabled = false
local silentAimEnabled = false
local noRecoilEnabled = false  -- Variável para controlar o no recoil
local playerSpeed = 50
local espInstances = {}
local flying = false
local flightSpeed = 50  -- Velocidade do voo

-- Função para reviver na posição da morte
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

-- Conectar à adição de personagem para salvar a posição da morte
LocalPlayer.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.HealthChanged:Connect(function(health)
        if health <= 0 then
            deathPosition = character.HumanoidRootPart.CFrame  -- Salvar posição ao morrer
        end
    end)
end)

-- Função para alternar o no clip
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

-- Função para a movimentação no clip e voo
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

    -- Aplicar no recoil, se habilitado
    if noRecoilEnabled then
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            -- Remover ou ajustar o recuo aqui
            -- Por exemplo, modificar a força aplicada ao disparo da arma
            -- Se a arma estiver com uma propriedade de recuo, podemos zerá-la ou ajustá-la
            local tool = character:FindFirstChildOfClass("Tool")
            if tool and tool:FindFirstChild("Recoil") then
                tool.Recoil = 0  -- Defina o valor que neutraliza o recuo
            end
        end
    end
end)

-- Função para alternar o aimbot
local function toggleAimbot()
    aimbotEnabled = not aimbotEnabled
    if aimbotEnabled then
        RunService.RenderStepped:Connect(function()
            local closestPlayer = nil
            local shortestDistance = math.huge
            local camera = workspace.CurrentCamera
            local maxFov = 150  -- Diminuindo o FOV para pegar apenas inimigos mais próximos

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

-- Função para alternar o silent aim
local function toggleSilentAim()
    silentAimEnabled = not silentAimEnabled
    if silentAimEnabled then
        -- Lógica do silent aim
        -- Esta função deve garantir que os tiros acertem o alvo
        -- mesmo que o jogador não esteja mirando diretamente nele
    end
end

-- Função para alternar a hitbox
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

-- Função para alternar o ESP
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

-- Função para criar o ESP (melhorado)
local function createESP(player)
    if espInstances[player] then return end
    local highlight = Instance.new("Highlight")
    highlight.Parent = player.Character
    highlight.Adornee = player.Character
    highlight.FillColor = player.Team == LocalPlayer.Team and Color3.fromRGB(0, 0, 255) or Color3.fromRGB(255, 0, 0)  
    highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
    highlight.OutlineTransparency = 0.5  -- Adicionando transparência ao contorno
    highlight.FillTransparency = 0.6  -- Transparência para o fundo

    -- Salvando a instância de ESP para remoção posterior
    espInstances[player] = highlight
end

-- Função para remover o ESP
local function removeESP(player)
    if espInstances[player] then
        espInstances[player]:Destroy()
        espInstances[player] = nil
    end
end
