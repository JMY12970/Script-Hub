local Players = game:GetService("Players")
local player = Players.LocalPlayer

if not player then
    return
end

local guiParent = player:WaitForChild("PlayerGui")
pcall(function()
    guiParent = game:GetService("CoreGui")
end)

local previousGui = guiParent:FindFirstChild("PandaAuthScriptHub")
if previousGui then
    previousGui:Destroy()
end

local SCRIPTS = {
    {
        name = "YouTube Music Player",
        description = "Your PandaAuth-protected Roblox audio player.",
        loaderUrl = "https://pandaauth.xyz/loader/e4e8e62d-3c2a-4760-b336-adc545d378a4",
    },
}

local colors = {
    background = Color3.fromRGB(20, 22, 21),
    panel = Color3.fromRGB(30, 33, 31),
    raised = Color3.fromRGB(42, 46, 43),
    text = Color3.fromRGB(242, 245, 242),
    muted = Color3.fromRGB(158, 166, 159),
    accent = Color3.fromRGB(79, 211, 139),
    warning = Color3.fromRGB(247, 191, 90),
}

local gui = Instance.new("ScreenGui")
gui.Name = "PandaAuthScriptHub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = guiParent

local function make(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function corner(parent, radius)
    make("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, parent)
end

local function label(parent, text, size, color, properties)
    local defaults = {
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or colors.text,
        Font = Enum.Font.Gotham,
        TextSize = size or 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }
    for key, value in pairs(properties or {}) do
        defaults[key] = value
    end
    return make("TextLabel", defaults, parent)
end

local window = make("Frame", {
    Name = "Window",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(0, 620, 0, 430),
    BackgroundColor3 = colors.background,
    BorderSizePixel = 0,
}, gui)
corner(window, 10)
make("UISizeConstraint", {
    MinSize = Vector2.new(330, 360),
    MaxSize = Vector2.new(620, 430),
}, window)

local header = make("Frame", {
    Position = UDim2.fromOffset(20, 18),
    Size = UDim2.new(1, -40, 0, 48),
    BackgroundTransparency = 1,
}, window)
label(header, "SCRIPT HUB", 18, colors.text, {
    Size = UDim2.new(0.6, 0, 0, 25),
    Font = Enum.Font.GothamBold,
})
label(header, "PANDAAUTH PROTECTED", 9, colors.accent, {
    Position = UDim2.fromOffset(0, 27),
    Size = UDim2.new(0.6, 0, 0, 16),
    Font = Enum.Font.GothamMedium,
})

local keyInput = make("TextBox", {
    Position = UDim2.fromOffset(20, 78),
    Size = UDim2.new(1, -40, 0, 38),
    BackgroundColor3 = colors.panel,
    Text = "",
    PlaceholderText = "PandaAuth license key",
    PlaceholderColor3 = colors.muted,
    TextColor3 = colors.text,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    ClearTextOnFocus = false,
    BorderSizePixel = 0,
}, window)
corner(keyInput, 7)

local status = label(window, "Enter your PandaAuth license key, then choose a script.", 10, colors.muted, {
    Position = UDim2.fromOffset(20, 122),
    Size = UDim2.new(1, -40, 0, 20),
})

local scriptList = make("ScrollingFrame", {
    Position = UDim2.fromOffset(20, 151),
    Size = UDim2.new(1, -40, 1, -171),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = colors.muted,
    CanvasSize = UDim2.new(),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, window)
make("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, scriptList)

local function launch(entry, button)
    local accessKey = string.gsub(keyInput.Text, "^%s*(.-)%s*$", "%1")
    if accessKey == "" then
        status.Text = "Enter your PandaAuth license key first."
        status.TextColor3 = colors.warning
        return
    end
    if type(entry.loaderUrl) ~= "string"
        or not string.match(entry.loaderUrl, "^https://[^%s]+$") then
        status.Text = "Set this entry to its generated PandaAuth loader URL in SCRIPTS."
        status.TextColor3 = colors.warning
        return
    end
    if type(loadstring) ~= "function" then
        status.Text = "This executor does not provide loadstring."
        status.TextColor3 = colors.warning
        return
    end

    button.Text = "LOADING..."
    button.Active = false
    status.Text = "Requesting the PandaAuth loader..."
    status.TextColor3 = colors.muted

    task.spawn(function()
        local requestOk, source = pcall(function()
            return game:HttpGet(entry.loaderUrl)
        end)
        if not requestOk or type(source) ~= "string" then
            status.Text = "Could not download the PandaAuth loader. Check the URL and executor HTTP access."
            status.TextColor3 = colors.warning
            button.Text = "LAUNCH"
            button.Active = true
            return
        end

        local compileOk, loader = pcall(loadstring, source)
        if not compileOk or type(loader) ~= "function" then
            status.Text = "PandaAuth returned a loader that could not be compiled."
            status.TextColor3 = colors.warning
            button.Text = "LAUNCH"
            button.Active = true
            return
        end

        local sharedEnvironment = _G
        if type(getgenv) == "function" then
            local envOk, executorEnvironment = pcall(getgenv)
            if envOk and type(executorEnvironment) == "table" then
                sharedEnvironment = executorEnvironment
            end
        end

        sharedEnvironment.PandaAuthKey = accessKey
        local executeOk = pcall(loader)
        if sharedEnvironment.PandaAuthKey == accessKey then
            sharedEnvironment.PandaAuthKey = nil
        end

        if executeOk then
            status.Text = "Loader started. PandaAuth checks the license key."
            status.TextColor3 = colors.accent
        else
            status.Text = "Loader failed. Verify the license key and generated loader URL."
            status.TextColor3 = colors.warning
        end
        button.Text = "LAUNCH"
        button.Active = true
    end)
end

for index, entry in ipairs(SCRIPTS) do
    local card = make("Frame", {
        Size = UDim2.new(1, -6, 0, 70),
        BackgroundColor3 = colors.panel,
        BorderSizePixel = 0,
        LayoutOrder = index,
    }, scriptList)
    corner(card, 7)

    label(card, entry.name, 13, colors.text, {
        Position = UDim2.fromOffset(12, 12),
        Size = UDim2.new(1, -126, 0, 20),
        Font = Enum.Font.GothamMedium,
    })
    label(card, entry.description, 10, colors.muted, {
        Position = UDim2.fromOffset(12, 35),
        Size = UDim2.new(1, -126, 0, 18),
    })

    local button = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(96, 34),
        BackgroundColor3 = colors.accent,
        Text = "LAUNCH",
        TextColor3 = colors.background,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = true,
        BorderSizePixel = 0,
    }, card)
    corner(button, 6)
    button.Activated:Connect(function()
        launch(entry, button)
    end)
end