-- Serviços Necessários
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local deathPosition = nil -- Posição salva para reviver

-- Variáveis Globais
local noClipEnabled = false
local aimbotEnabled = false
local speedEnabled = false
local hitboxEnabled = false
local espEnabled = false
local playerSpeed = 50
local espInstances = {}
local flying = false
local flightSpeed = 50 -- Velocidade do voo
local connections = {} -- Para armazenar conexões e desativá-las quando necessário

-- Função para limpar conexões
local function clearConnections()
    for _, connection in pairs(connections) do
        if connection.Disconnect then
            connection:Disconnect()
        end
    end
    connections = {}
end

-- Função para reviver no mesmo local
local function reviveAtDeathPosition()
    if deathPosition and LocalPlayer.Character then
        local character = LocalPlayer.Character
        if character:FindFirstChild("Humanoid") then
            character:BreakJoints() -- Matar o personagem para renascer
            repeat wait() until not character.Parent
            wait(1)
            LocalPlayer:LoadCharacter()
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
            deathPosition = character.HumanoidRootPart.CFrame
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
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
                rootPart.CanCollide = false
                flying = true
            else
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
                rootPart.CanCollide = true
                flying = false
            end
        end
    end
end

-- Controlar voo
connections[#connections + 1] = RunService.RenderStepped:Connect(function()
    if noClipEnabled and flying then
        local character = LocalPlayer.Character
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            local moveDirection = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDirection = Vector3.new(0, 1, 0) * flightSpeed
            elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveDirection = Vector3.new(0, -1, 0) * flightSpeed
            end

            local forward = UserInputService:IsKeyDown(Enum.KeyCode.W) and Vector3.new(0, 0, -1) * flightSpeed or Vector3.new(0, 0, 0)
            local backward = UserInputService:IsKeyDown(Enum.KeyCode.S) and Vector3.new(0, 0, 1) * flightSpeed or Vector3.new(0, 0, 0)
            local left = UserInputService:IsKeyDown(Enum.KeyCode.A) and Vector3.new(-1, 0, 0) * flightSpeed or Vector3.new(0, 0, 0)
            local right = UserInputService:IsKeyDown(Enum.KeyCode.D) and Vector3.new(1, 0, 0) * flightSpeed or Vector3.new(0, 0, 0)

            moveDirection = moveDirection + forward + backward + left + right
            humanoidRootPart.Velocity = moveDirection
        end
    end
end)

-- Função para Aimbot
local function toggleAimbot()
    aimbotEnabled = not aimbotEnabled
    if aimbotEnabled then
        connections[#connections + 1] = RunService.RenderStepped:Connect(function()
            local closestPlayer = nil
            local shortestDistance = math.huge
            local camera = workspace.CurrentCamera
            local maxFov = 150

            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team and player.Character then
                    local torso = player.Character:FindFirstChild("UpperTorso") or player.Character:FindFirstChild("HumanoidRootPart")
                    if torso then
                        local ray = Ray.new(camera.CFrame.Position, (torso.Position - camera.CFrame.Position).unit * 500)
                        local hitPart = workspace:FindPartOnRay(ray, LocalPlayer.Character)

                        if hitPart and hitPart.Parent == player.Character then
                            local screenPosition, onScreen = camera:WorldToViewportPoint(torso.Position)
                            if onScreen then
                                local mousePosition = UserInputService:GetMouseLocation()
                                local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - mousePosition).Magnitude
                                if distance < shortestDistance and distance < maxFov then
                                    closestPlayer = player
                                    shortestDistance = distance
                                end
                            end
                        end
                    end
                end
            end

            if closestPlayer and closestPlayer.Character then
                local torsoPosition = closestPlayer.Character:FindFirstChild("UpperTorso") or closestPlayer.Character.HumanoidRootPart.Position
                local currentCFrame = camera.CFrame
                local targetDirection = (torsoPosition - currentCFrame.Position).Unit
                local smoothDirection = currentCFrame.LookVector:Lerp(targetDirection, 0.1)

                camera.CFrame = CFrame.new(currentCFrame.Position, currentCFrame.Position + smoothDirection)
            end
        end)
    else
        clearConnections()
    end
end

-- Funções auxiliares (ESP, Hitbox, Painel, etc.) combinadas e otimizadas
-- Outras funcionalidades seguirão lógica semelhante para otimizar integração
