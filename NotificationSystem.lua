--[[
    NotificationSystem.lua
    A sleek, modern notification system with centered design, smooth animations,
    animated bright pink glowing border effect, and lowered position.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Configuration
local Config = {
    MAX_WIDTH = 300,
    MIN_WIDTH = 200,
    CORNER_RADIUS = 30,
    FONT = Enum.Font.GothamBold,
    TITLE_SIZE = 21,
    MESSAGE_SIZE = 15.5,
    DEFAULT_DURATION = 3.5,
    FADE_TIME = 0.755,
    PADDING = 16,
    MARGIN = 8,
    COLORS = {
        BACKGROUND = Color3.fromRGB(32, 34, 37),
        TEXT = Color3.fromRGB(255, 255, 255),
        ACCENT = Color3.fromRGB(255, 0, 255), -- Unused, but more vibrant (magenta)
        PROGRESS = Color3.fromRGB(255, 255, 255),
        -- Brighter pink for the glow
        GLOW = Color3.fromRGB(255, 40, 180),
        BRIGHT_GLOW = Color3.fromRGB(255, 0, 255) -- Full bright magenta for moving light
    },
    SOUNDS = {
        SHOW = "rbxassetid://6518811702",
        HIDE = "rbxassetid://6518812167"
    }
}

-- Internal variables
local NotificationSystem = {}
local activeNotification = nil
local container = nil

-- Initialize container
local function createContainer()
    if container then return container end
    
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NotificationSystem"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui
    
    container = Instance.new("Frame")
    container.Name = "NotificationContainer"
    container.BackgroundTransparency = 1
    container.Size = UDim2.new(1, 0, 1, 0)
    container.Parent = screenGui
    
    return container
end

-- Animate notification in
local function animateIn(notification)
    local frame = notification.Frame
    local messageLabel = frame:WaitForChild("Message")
    
    -- Wait for text to wrap and calculate proper size
    RunService.Heartbeat:Wait()
    local height = messageLabel.AbsoluteSize.Y + Config.PADDING * 2
    
    -- Set initial state
    frame.Size = UDim2.new(0, Config.MAX_WIDTH, 0, 0)
    frame.Position = UDim2.new(0.5, -Config.MAX_WIDTH/2, 0.7, 0)
    frame.BackgroundTransparency = 1
    
    -- Animate frame
    TweenService:Create(
        frame,
        TweenInfo.new(Config.FADE_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = UDim2.new(0, Config.MAX_WIDTH, 0, height),
            Position = UDim2.new(0.5, -Config.MAX_WIDTH/2, 0.7, -height/2),
            BackgroundTransparency = 0
        }
    ):Play()
    
    -- Animate children
    for _, child in pairs(frame:GetDescendants()) do
        if child:IsA("TextLabel") then
            child.TextTransparency = 1
            TweenService:Create(
                child,
                TweenInfo.new(Config.FADE_TIME, Enum.EasingStyle.Quint),
                {TextTransparency = 0}
            ):Play()
        elseif child:IsA("Frame") and child.Name == "ProgressBar" then
            child.BackgroundTransparency = 1
            TweenService:Create(
                child,
                TweenInfo.new(Config.FADE_TIME, Enum.EasingStyle.Quint),
                {BackgroundTransparency = 0.8}
            ):Play()
        elseif child:IsA("Frame") and child.Name:sub(1,4) == "Glow" then
            child.BackgroundTransparency = 1
            TweenService:Create(
                child,
                TweenInfo.new(Config.FADE_TIME, Enum.EasingStyle.Quint),
                {BackgroundTransparency = 0.4}
            ):Play()
        elseif child:IsA("Frame") and child.Name:sub(1,13) == "MovingBright" then
            child.BackgroundTransparency = 1
            TweenService:Create(
                child,
                TweenInfo.new(Config.FADE_TIME, Enum.EasingStyle.Quint),
                {BackgroundTransparency = 0}
            ):Play()
        end
    end

    -- Start animating moving bright glow
    if notification.AnimateBrightGlow then
        notification.AnimateBrightGlow()
    end
end

-- Animate notification out
local function animateOut(notification, callback)
    local frame = notification.Frame
    
    -- Animate frame
    TweenService:Create(
        frame,
        TweenInfo.new(Config.FADE_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {
            Size = UDim2.new(0, Config.MAX_WIDTH, 0, 0),
            Position = UDim2.new(0.5, -Config.MAX_WIDTH/2, 0.7, 0),
            BackgroundTransparency = 1
        }
    ):Play()
    
    -- Animate children
    for _, child in pairs(frame:GetDescendants()) do
        if child:IsA("TextLabel") then
            TweenService:Create(
                child,
                TweenInfo.new(Config.FADE_TIME, Enum.EasingStyle.Quint),
                {TextTransparency = 1}
            ):Play()
        elseif child:IsA("Frame") and child.Name == "ProgressBar" then
            TweenService:Create(
                child,
                TweenInfo.new(Config.FADE_TIME, Enum.EasingStyle.Quint),
                {BackgroundTransparency = 1}
            ):Play()
        elseif child:IsA("Frame") and child.Name:sub(1,4) == "Glow" then
            TweenService:Create(
                child,
                TweenInfo.new(Config.FADE_TIME, Enum.EasingStyle.Quint),
                {BackgroundTransparency = 1}
            ):Play()
        elseif child:IsA("Frame") and child.Name:sub(1,13) == "MovingBright" then
            TweenService:Create(
                child,
                TweenInfo.new(Config.FADE_TIME, Enum.EasingStyle.Quint),
                {BackgroundTransparency = 1}
            ):Play()
        end
    end
    
    -- Cleanup after animation
    task.delay(Config.FADE_TIME, function()
        if callback then callback() end
    end)
end

-- Create notification UI
local function createNotification(options)
    local message = options.message or ""
    local duration = options.duration or Config.DEFAULT_DURATION

    -- Create main frame
    local frame = Instance.new("Frame")
    frame.Name = "Notification"
    frame.BackgroundColor3 = Config.COLORS.BACKGROUND
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true

    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, Config.CORNER_RADIUS)
    corner.Parent = frame

    -- Add bright pink glowing outline using UIStroke
    local outline = Instance.new("UIStroke")
    outline.Color = Config.COLORS.GLOW
    outline.Thickness = 6
    outline.Transparency = 0.15
    outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    outline.Parent = frame

    -- Add four pink glowing frames for glow offset (0.15 studs away)
    local function createGlowEdge(name, size, pos)
        local edge = Instance.new("Frame")
        edge.Name = name
        edge.BackgroundColor3 = Config.COLORS.GLOW
        edge.BackgroundTransparency = 0.4
        edge.BorderSizePixel = 0
        edge.Size = size
        edge.Position = pos
        edge.ZIndex = 3
        edge.Parent = frame
        -- Give rounded corners to the edges as well
        local edgeCorner = Instance.new("UICorner")
        edgeCorner.CornerRadius = UDim.new(0, Config.CORNER_RADIUS + 6)
        edgeCorner.Parent = edge
        -- Simulate blur by duplicating and layering
        for i = 1, 2 do
            local blurLayer = Instance.new("Frame")
            blurLayer.Name = name.."_Blur"..i
            blurLayer.BackgroundColor3 = Config.COLORS.GLOW
            blurLayer.BackgroundTransparency = 0.7 + 0.07*i
            blurLayer.BorderSizePixel = 0
            blurLayer.Size = size + UDim2.new(0, i*4, 0, i*4)
            blurLayer.Position = pos + UDim2.new(0, -2*i, 0, -2*i)
            blurLayer.ZIndex = 2
            blurLayer.Parent = frame
            local blurCorner = Instance.new("UICorner")
            blurCorner.CornerRadius = UDim.new(0, Config.CORNER_RADIUS + 8 + i*2)
            blurCorner.Parent = blurLayer
        end
        return edge
    end
    local offset = math.floor(0.15 * 36) -- 5 pixels
    -- Top
    createGlowEdge("GlowTop", UDim2.new(1, offset*2, 0, 8), UDim2.new(0, -offset, 0, -offset-8))
    -- Bottom
    createGlowEdge("GlowBottom", UDim2.new(1, offset*2, 0, 8), UDim2.new(0, -offset, 1, offset))
    -- Left
    createGlowEdge("GlowLeft", UDim2.new(0, 8, 1, offset*2), UDim2.new(0, -offset-8, 0, -offset))
    -- Right
    createGlowEdge("GlowRight", UDim2.new(0, 8, 1, offset*2), UDim2.new(1, offset, 0, -offset))

    -- Animated moving bright pink glow (using a "runner" frame for each edge)
    local AnimateBrightGlow
    do
        -- Top edge animation
        local movingBrightTop = Instance.new("Frame")
        movingBrightTop.Name = "MovingBrightTop"
        movingBrightTop.BackgroundColor3 = Config.COLORS.BRIGHT_GLOW
        movingBrightTop.BackgroundTransparency = 1
        movingBrightTop.BorderSizePixel = 0
        movingBrightTop.Size = UDim2.new(0, 60, 0, 8)
        movingBrightTop.Position = UDim2.new(0, -offset, 0, -offset-10)
        movingBrightTop.ZIndex = 5
        local mbtCorner = Instance.new("UICorner")
        mbtCorner.CornerRadius = UDim.new(0, Config.CORNER_RADIUS + 8)
        mbtCorner.Parent = movingBrightTop
        movingBrightTop.Parent = frame

        -- Bottom edge animation
        local movingBrightBottom = Instance.new("Frame")
        movingBrightBottom.Name = "MovingBrightBottom"
        movingBrightBottom.BackgroundColor3 = Config.COLORS.BRIGHT_GLOW
        movingBrightBottom.BackgroundTransparency = 1
        movingBrightBottom.BorderSizePixel = 0
        movingBrightBottom.Size = UDim2.new(0, 60, 0, 8)
        movingBrightBottom.Position = UDim2.new(0, -offset, 1, offset)
        movingBrightBottom.ZIndex = 5
        local mbbCorner = Instance.new("UICorner")
        mbbCorner.CornerRadius = UDim.new(0, Config.CORNER_RADIUS + 8)
        mbbCorner.Parent = movingBrightBottom
        movingBrightBottom.Parent = frame

        -- Left edge animation
        local movingBrightLeft = Instance.new("Frame")
        movingBrightLeft.Name = "MovingBrightLeft"
        movingBrightLeft.BackgroundColor3 = Config.COLORS.BRIGHT_GLOW
        movingBrightLeft.BackgroundTransparency = 1
        movingBrightLeft.BorderSizePixel = 0
        movingBrightLeft.Size = UDim2.new(0, 8, 0, 60)
        movingBrightLeft.Position = UDim2.new(0, -offset-10, 0, -offset)
        movingBrightLeft.ZIndex = 5
        local mblCorner = Instance.new("UICorner")
        mblCorner.CornerRadius = UDim.new(0, Config.CORNER_RADIUS + 8)
        mblCorner.Parent = movingBrightLeft
        movingBrightLeft.Parent = frame

        -- Right edge animation
        local movingBrightRight = Instance.new("Frame")
        movingBrightRight.Name = "MovingBrightRight"
        movingBrightRight.BackgroundColor3 = Config.COLORS.BRIGHT_GLOW
        movingBrightRight.BackgroundTransparency = 1
        movingBrightRight.BorderSizePixel = 0
        movingBrightRight.Size = UDim2.new(0, 8, 0, 60)
        movingBrightRight.Position = UDim2.new(1, offset, 0, -offset)
        movingBrightRight.ZIndex = 5
        local mbrCorner = Instance.new("UICorner")
        mbrCorner.CornerRadius = UDim.new(0, Config.CORNER_RADIUS + 8)
        mbrCorner.Parent = movingBrightRight
        movingBrightRight.Parent = frame

        -- Animate all runners in a loop
        local runners = {
            Top = movingBrightTop,
            Bottom = movingBrightBottom,
            Left = movingBrightLeft,
            Right = movingBrightRight
        }
        local animating = true

        AnimateBrightGlow = function()
            animating = true
            -- Top and Bottom runners: left to right
            coroutine.wrap(function()
                while animating and frame.Parent do
                    -- Top
                    movingBrightTop.BackgroundTransparency = 0
                    movingBrightBottom.BackgroundTransparency = 0
                    local tw1 = TweenService:Create(
                        movingBrightTop,
                        TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                        {Position = UDim2.new(1, offset-60, 0, -offset-10)}
                    )
                    local tw2 = TweenService:Create(
                        movingBrightBottom,
                        TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                        {Position = UDim2.new(1, offset-60, 1, offset)}
                    )
                    tw1:Play() tw2:Play()
                    tw1.Completed:Wait()
                    -- Hide briefly
                    movingBrightTop.BackgroundTransparency = 1
                    movingBrightBottom.BackgroundTransparency = 1
                    movingBrightTop.Position = UDim2.new(0, -offset, 0, -offset-10)
                    movingBrightBottom.Position = UDim2.new(0, -offset, 1, offset)
                    wait(0.1)
                end
            end)()
            -- Left and Right runners: top to bottom
            coroutine.wrap(function()
                while animating and frame.Parent do
                    movingBrightLeft.BackgroundTransparency = 0
                    movingBrightRight.BackgroundTransparency = 0
                    local tw3 = TweenService:Create(
                        movingBrightLeft,
                        TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                        {Position = UDim2.new(0, -offset-10, 1, offset-60)}
                    )
                    local tw4 = TweenService:Create(
                        movingBrightRight,
                        TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                        {Position = UDim2.new(1, offset, 1, offset-60)}
                    )
                    tw3:Play() tw4:Play()
                    tw3.Completed:Wait()
                    movingBrightLeft.BackgroundTransparency = 1
                    movingBrightRight.BackgroundTransparency = 1
                    movingBrightLeft.Position = UDim2.new(0, -offset-10, 0, -offset)
                    movingBrightRight.Position = UDim2.new(1, offset, 0, -offset)
                    wait(0.1)
                end
            end)()
        end

        -- Clean up animation when notification closes
        frame.AncestryChanged:Connect(function(_, parent)
            if not parent then
                animating = false
            end
        end)
    end

    -- Create message
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"
    messageLabel.BackgroundTransparency = 1
    messageLabel.Size = UDim2.new(1, -Config.PADDING * 2, 0, 0)
    messageLabel.Position = UDim2.new(0, Config.PADDING, 0, Config.PADDING)
    messageLabel.Font = Config.FONT
    messageLabel.TextSize = Config.MESSAGE_SIZE
    messageLabel.TextColor3 = Config.COLORS.TEXT
    messageLabel.TextWrapped = true
    messageLabel.AutomaticSize = Enum.AutomaticSize.Y
    messageLabel.Text = message
    messageLabel.ZIndex = 4
    messageLabel.Parent = frame

    -- Add progress bar
    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.BorderSizePixel = 0
    progressBar.BackgroundColor3 = Config.COLORS.PROGRESS
    progressBar.BackgroundTransparency = 0.8
    progressBar.Size = UDim2.new(1, 0, 0, 2)
    progressBar.Position = UDim2.new(0, 0, 1, -2)
    progressBar.ZIndex = 4
    progressBar.Parent = frame

    frame.ZIndex = 3
    frame.Parent = container

    -- Create notification object
    local notification = {
        Frame = frame,
        StartTime = tick(),
        Duration = duration,
        AnimateBrightGlow = AnimateBrightGlow,
    }

    -- Play show sound
    local sound = Instance.new("Sound")
    sound.SoundId = Config.SOUNDS.SHOW
    sound.Volume = 0.5
    sound.Parent = frame
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 1)

    -- Animate progress bar
    TweenService:Create(
        progressBar,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        {Size = UDim2.new(0, 0, 0, 2)}
    ):Play()

    if activeNotification then
        NotificationSystem.close(activeNotification)
    end
    activeNotification = notification

    animateIn(notification)
    task.delay(duration, function()
        NotificationSystem.close(notification)
    end)

    return notification
end

-- Close notification
function NotificationSystem.close(notification)
    if notification ~= activeNotification then return end

    -- Play hide sound
    local sound = Instance.new("Sound")
    sound.SoundId = Config.SOUNDS.HIDE
    sound.Volume = 0.5
    sound.Parent = notification.Frame
    sound:Play()

    -- Animate out
    animateOut(notification, function()
        notification.Frame:Destroy()
        activeNotification = nil
    end)
end

-- Initialize
function NotificationSystem.init()
    createContainer()
    return NotificationSystem
end

-- Main notification function
function NotificationSystem.notify(options)
    if not container then NotificationSystem.init() end
    return createNotification(options)
end

-- Shorthand functions
function NotificationSystem.log(message, duration)
    return NotificationSystem.notify({
        message = message,
        duration = duration
    })
end

-- Allow calling the module directly as a function
return setmetatable(NotificationSystem, {
    __call = function(_, ...)
        return NotificationSystem.log(...)
    end
})
