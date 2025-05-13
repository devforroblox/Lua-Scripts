--[[
    NotificationSystem.lua
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Configuration
local Config = {
    MAX_WIDTH = 300,
    MIN_WIDTH = 200,
    CORNER_RADIUS = 8,
    FONT = Enum.Font.GothamMedium,
    TITLE_SIZE = 18,
    MESSAGE_SIZE = 14,
    DEFAULT_DURATION = 4,
    FADE_TIME = 0.3,
    POSITION = "topRight",
    PADDING = 8,
    MARGIN = 8,
    SCREEN_PADDING = 16,
    MAX_NOTIFICATIONS = 5,
    DISMISS_ON_CLICK = true,
    COLORS = {
        INFO = {
            BACKGROUND = Color3.fromRGB(59, 130, 246),
            TEXT = Color3.fromRGB(255, 255, 255),
            ICON = Color3.fromRGB(255, 255, 255)
        },
        SUCCESS = {
            BACKGROUND = Color3.fromRGB(16, 185, 129),
            TEXT = Color3.fromRGB(255, 255, 255),
            ICON = Color3.fromRGB(255, 255, 255)
        },
        WARNING = {
            BACKGROUND = Color3.fromRGB(245, 158, 11),
            TEXT = Color3.fromRGB(255, 255, 255),
            ICON = Color3.fromRGB(255, 255, 255)
        },
        ERROR = {
            BACKGROUND = Color3.fromRGB(239, 68, 68),
            TEXT = Color3.fromRGB(255, 255, 255),
            ICON = Color3.fromRGB(255, 255, 255)
        }
    },
    ICONS = {
        INFO = "rbxassetid://6031071053",
        SUCCESS = "rbxassetid://6031068427",
        WARNING = "rbxassetid://6031071057",
        ERROR = "rbxassetid://6031071054"
    },
    SOUNDS = {
        INFO = "rbxassetid://6518811702",
        SUCCESS = "rbxassetid://6518811702",
        WARNING = "rbxassetid://6518812301",
        ERROR = "rbxassetid://6518812167"
    }
}

-- Internal variables
local NotificationSystem = {}
local activeNotifications = {}
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

-- Calculate notification position
local function getNotificationPosition(frame)
    local yOffset = 0
    
    for _, notification in ipairs(activeNotifications) do
        if notification.Frame.Visible then
            yOffset = yOffset + notification.Frame.Size.Y.Offset + Config.MARGIN
        end
    end
    
    local position = UDim2.new(
        1, 
        -Config.SCREEN_PADDING - frame.Size.X.Offset,
        0,
        Config.SCREEN_PADDING + yOffset
    )
    
    return position
end

-- Animate notification in
local function animateIn(notification)
    local frame = notification.Frame
    local originalPosition = frame.Position
    
    -- Set initial state
    frame.Position = UDim2.new(
        originalPosition.X.Scale,
        originalPosition.X.Offset + 20,
        originalPosition.Y.Scale,
        originalPosition.Y.Offset
    )
    frame.BackgroundTransparency = 1
    
    -- Create tweens
    local positionTween = TweenService:Create(
        frame,
        TweenInfo.new(Config.FADE_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Position = originalPosition, BackgroundTransparency = 0}
    )
    
    -- Animate all children
    for _, child in pairs(frame:GetDescendants()) do
        if child:IsA("TextLabel") then
            child.TextTransparency = 1
            TweenService:Create(
                child,
                TweenInfo.new(Config.FADE_TIME, Enum.EasingStyle.Quint),
                {TextTransparency = 0}
            ):Play()
        elseif child:IsA("ImageLabel") then
            child.ImageTransparency = 1
            TweenService:Create(
                child,
                TweenInfo.new(Config.FADE_TIME, Enum.EasingStyle.Quint),
                {ImageTransparency = 0}
            ):Play()
        end
    end
    
    positionTween:Play()
end

-- Animate notification out
local function animateOut(notification, callback)
    local frame = notification.Frame
    local currentPosition = frame.Position
    
    -- Calculate exit position
    local exitPosition = UDim2.new(
        currentPosition.X.Scale,
        currentPosition.X.Offset + 20,
        currentPosition.Y.Scale,
        currentPosition.Y.Offset
    )
    
    -- Create tweens
    local fadeTween = TweenService:Create(
        frame,
        TweenInfo.new(Config.FADE_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Position = exitPosition, BackgroundTransparency = 1}
    )
    
    -- Animate all children
    for _, child in pairs(frame:GetDescendants()) do
        if child:IsA("TextLabel") then
            TweenService:Create(
                child,
                TweenInfo.new(Config.FADE_TIME, Enum.EasingStyle.Quint),
                {TextTransparency = 1}
            ):Play()
        elseif child:IsA("ImageLabel") then
            TweenService:Create(
                child,
                TweenInfo.new(Config.FADE_TIME, Enum.EasingStyle.Quint),
                {ImageTransparency = 1}
            ):Play()
        end
    end
    
    fadeTween.Completed:Connect(function()
        if callback then callback() end
    end)
    
    fadeTween:Play()
end

-- Create notification UI
local function createNotification(options)
    local notificationType = options.type or "info"
    local message = options.message or ""
    local duration = options.duration or Config.DEFAULT_DURATION
    local title = options.title
    
    local colors = Config.COLORS[string.upper(notificationType)] or Config.COLORS.INFO
    
    -- Create main frame
    local frame = Instance.new("Frame")
    frame.Name = "Notification"
    frame.Size = UDim2.new(0, Config.MAX_WIDTH, 0, 0)
    frame.BackgroundColor3 = colors.BACKGROUND
    frame.BorderSizePixel = 0
    frame.BackgroundTransparency = 0
    
    -- Add corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, Config.CORNER_RADIUS)
    corner.Parent = frame
    
    -- Add shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    shadow.Size = UDim2.new(1, 24, 1, 24)
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.Image = "rbxassetid://6014054906"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.Parent = frame
    
    -- Create content container
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.BackgroundTransparency = 1
    content.Size = UDim2.new(1, -Config.PADDING * 2, 1, -Config.PADDING * 2)
    content.Position = UDim2.new(0, Config.PADDING, 0, Config.PADDING)
    content.Parent = frame
    
    -- Add icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.BackgroundTransparency = 1
    icon.Size = UDim2.new(0, 20, 0, 20)
    icon.Image = Config.ICONS[string.upper(notificationType)]
    icon.ImageColor3 = colors.ICON
    icon.Parent = content
    
    -- Add message
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"
    messageLabel.BackgroundTransparency = 1
    messageLabel.Position = UDim2.new(0, 28, 0, 0)
    messageLabel.Size = UDim2.new(1, -28, 1, 0)
    messageLabel.Font = Config.FONT
    messageLabel.TextSize = Config.MESSAGE_SIZE
    messageLabel.TextColor3 = colors.TEXT
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextWrapped = true
    messageLabel.Text = message
    messageLabel.Parent = content
    
    -- Add progress bar
    local progressBar = Instance.new("Frame")
    progressBar.Name = "ProgressBar"
    progressBar.BorderSizePixel = 0
    progressBar.BackgroundColor3 = colors.TEXT
    progressBar.BackgroundTransparency = 0.8
    progressBar.Size = UDim2.new(1, 0, 0, 2)
    progressBar.Position = UDim2.new(0, 0, 1, -2)
    progressBar.Parent = frame
    
    -- Calculate height based on text
    local textSize = game:GetService("TextService"):GetTextSize(
        message,
        Config.MESSAGE_SIZE,
        Config.FONT,
        Vector2.new(Config.MAX_WIDTH - Config.PADDING * 4 - 28, math.huge)
    )
    
    frame.Size = UDim2.new(0, Config.MAX_WIDTH, 0, textSize.Y + Config.PADDING * 2)
    frame.Position = getNotificationPosition(frame)
    frame.Parent = container
    
    -- Create notification object
    local notification = {
        Frame = frame,
        StartTime = tick(),
        Duration = duration
    }
    
    -- Add click to dismiss
    if Config.DISMISS_ON_CLICK then
        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                NotificationSystem.close(notification)
            end
        end)
    end
    
    -- Play sound
    local soundId = Config.SOUNDS[string.upper(notificationType)]
    if soundId then
        local sound = Instance.new("Sound")
        sound.SoundId = soundId
        sound.Volume = 0.5
        sound.Parent = frame
        sound:Play()
        game:GetService("Debris"):AddItem(sound, 1)
    end
    
    -- Animate progress bar
    TweenService:Create(
        progressBar,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        {Size = UDim2.new(0, 0, 0, 2)}
    ):Play()
    
    -- Add to active notifications
    table.insert(activeNotifications, notification)
    
    -- Animate in
    animateIn(notification)
    
    -- Auto close after duration
    task.delay(duration, function()
        NotificationSystem.close(notification)
    end)
    
    return notification
end

-- Update positions of all notifications
local function updatePositions()
    local yOffset = Config.SCREEN_PADDING
    
    for _, notification in ipairs(activeNotifications) do
        if notification.Frame.Visible then
            local targetPosition = UDim2.new(
                1,
                -Config.SCREEN_PADDING - notification.Frame.Size.X.Offset,
                0,
                yOffset
            )
            
            if notification.Frame.Position ~= targetPosition then
                TweenService:Create(
                    notification.Frame,
                    TweenInfo.new(0.2, Enum.EasingStyle.Quint),
                    {Position = targetPosition}
                ):Play()
            end
            
            yOffset = yOffset + notification.Frame.Size.Y.Offset + Config.MARGIN
        end
    end
end

-- Close notification
function NotificationSystem.close(notification)
    -- Remove from active notifications
    for i, activeNotification in ipairs(activeNotifications) do
        if activeNotification == notification then
            table.remove(activeNotifications, i)
            break
        end
    end
    
    -- Animate out
    animateOut(notification, function()
        notification.Frame:Destroy()
        updatePositions()
    end)
end

-- Clear all notifications
function NotificationSystem.clearAll()
    for _, notification in ipairs(activeNotifications) do
        NotificationSystem.close(notification)
    end
end

-- Initialize
function NotificationSystem.init()
    createContainer()
    return NotificationSystem
end

-- Main notification functions
function NotificationSystem.notify(options)
    if not container then NotificationSystem.init() end
    return createNotification(options)
end

function NotificationSystem.log(message, duration)
    return NotificationSystem.notify({
        type = "info",
        message = message,
        duration = duration
    })
end

function NotificationSystem.success(message, duration)
    return NotificationSystem.notify({
        type = "success",
        message = message,
        duration = duration
    })
end

function NotificationSystem.warn(message, duration)
    return NotificationSystem.notify({
        type = "warning",
        message = message,
        duration = duration
    })
end

function NotificationSystem.error(message, duration)
    return NotificationSystem.notify({
        type = "error",
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
