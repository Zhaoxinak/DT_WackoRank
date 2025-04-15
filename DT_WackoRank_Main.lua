local BASE_FRAME_HEIGHT = 400 -- 主框架基础高度

local contentFrame
local statsFrame
local scrollFrame
local searchBox
local statsText

-- 定义 WRMain 模块表
WRMain = AceLibrary("AceAddon-2.0"):new(
    "AceEvent-2.0",    -- 事件处理
    "AceComm-2.0",     -- 插件间通信
    "AceConsole-2.0",  -- 命令行接口
    "FuBarPlugin-2.0", -- FuBar 插件支持
    "AceHook-2.1"      -- 函数钩子
)

-- 获取本地化库实例
local L = AceLibrary("AceLocale-2.2"):new("WackoRank")

-- 初始化 WRMain 模块 (由 RaidBuff:OnInitialize 调用)
function WRMain:OnInitialize()
    -- 创建 UI 框架 (如果尚未创建)
    if not self.mf then self:SetUpMainFrame() end -- 主分配界面
end

-- 创建主分配界面 (mf: main frame)
function WRMain:SetUpMainFrame()
    if self.mf then return end -- 防止重复创建

    local f = CreateFrame("Frame", "WRMainFrame", UIParent)
    f:SetWidth(800)                                            -- 初始宽度，会动态调整
    f:SetHeight(BASE_FRAME_HEIGHT)                             -- 初始高度，会动态调整
    f:SetBackdrop({
        bgFile = "Interface\\RaidFrame\\UI-RaidFrame-GroupBg", -- 背景贴图
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",   -- 边框贴图
        edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }  -- 内边距
    })
    f:SetAlpha(0.7)                                            -- 透明度
    f:SetFrameStrata("LOW")                                    -- 框架层级

    -- 设置初始位置并允许拖动
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0) -- 默认居中
    f:EnableMouse(true)
    f:SetClampedToScreen(true)                     -- 限制在屏幕内
    f:RegisterForDrag("LeftButton")
    f:SetMovable(true)
    f:SetScript("OnDragStart", function() f:StartMoving() end)
    f:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
    end)

    -- === 创建界面元素 ===
    f.textures = {} -- 存储纹理
    f.fontStrs = {} -- 存储字体串
    f.buttons = {}  -- 存储按钮

    -- --- 顶部标题栏 ---
    local headerTexture = f:CreateTexture(nil, "ARTWORK")
    headerTexture:SetTexture("Interface\\QuestFrame\\UI-HorizontalBreak") -- 水平分割线纹理
    headerTexture:SetPoint("TOP", f, "TOP", 0, -10)
    f.textures["head"] = headerTexture

    local headerText = f:CreateFontString(nil, "OVERLAY")
    headerText:SetFontObject("GameFontNormal")
    headerText:SetPoint("TOP", f, "TOP", 0, -10)
    headerText:SetText(L["标题"]) -- 使用本地化标题
    f.fontStrs["head"] = headerText

    local headerLine = f:CreateTexture(nil, "ARTWORK")
    headerLine:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill") -- 细线纹理
    headerLine:SetWidth(f:GetWidth() - 10)                                        -- 动态宽度
    headerLine:SetHeight(4)
    headerLine:SetPoint("BOTTOM", headerTexture, "BOTTOM", 0, 0)
    f.textures["headLine"] = headerLine

    -- 关闭按钮
    local closeButton = CreateFrame("Button", "WRMainCloseButton", f, "UIPanelCloseButton") -- 使用标准关闭按钮模板
    closeButton:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -7)
    closeButton:SetScript("OnClick", function() f:Hide() end)
    f.buttons["closeButton"] = closeButton

    -- 一键通报按钮
    local reportButton = CreateFrame("Button", "WRMainReportButton", f, "UIPanelButtonTemplate")
    reportButton:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -7)
    reportButton:SetWidth(60)
    reportButton:SetHeight(25)
    reportButton:SetText(L["通报"])
    reportButton:SetScript("OnClick", function() self:ReportAll() end)
    f.buttons["reportButton"] = reportButton

    -- 添加统计数据展示区域
    statsFrame = CreateFrame("Frame", "WRStatsFrame", f)
    statsFrame:SetPoint("TOP", headerLine, "BOTTOM", 0, -10)
    statsFrame:SetWidth(f:GetWidth() - 20)
    statsFrame:SetHeight(50)

    statsText = statsFrame:CreateFontString(nil, "OVERLAY")
    statsText:SetFontObject("GameFontNormal")
    statsText:SetPoint("LEFT", statsFrame, "LEFT", 10, 0)
    statsText:SetText(L["玩家评分: 暂无"])
    statsFrame.text = statsText

    -- 创建表格头
    local headerFrame = CreateFrame("Frame", nil, f)
    headerFrame:SetPoint("TOP", statsFrame, "BOTTOM", 0, -10)
    headerFrame:SetWidth(f:GetWidth() - 40)
    headerFrame:SetHeight(30)

    for i = 1, 3 do
        local headerText = headerFrame:CreateFontString(nil, "OVERLAY")
        headerText:SetFontObject("GameFontNormal")
        headerText:SetPoint("LEFT", headerFrame, "LEFT", (i - 1) * (headerFrame:GetWidth() / 3) + 10, 0)
        headerText:SetWidth(100)
        headerText:SetHeight(30)
        if i == 1 then
            headerText:SetText(L["评论者"])
        elseif i == 2 then
            headerText:SetText(L["时间"])
        else
            headerText:SetText(L["评语"])
        end
    end


    -- 添加滚动框架用于展示评论
    scrollFrame = CreateFrame("ScrollFrame", "WRScrollFrame", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOP", headerFrame, "BOTTOM", 0, -10)
    scrollFrame:SetWidth(f:GetWidth() - 40)
    scrollFrame:SetHeight(BASE_FRAME_HEIGHT - 200)

    contentFrame = CreateFrame("Frame", "WRContentFrame", scrollFrame)
    contentFrame:SetWidth(scrollFrame:GetWidth())
    contentFrame:SetHeight(1) -- 动态调整高度
    scrollFrame:SetScrollChild(contentFrame)


    -- 左上角图标按钮 (点击自动分配/刷新)
    local autoAssignButton = CreateFrame("Button", "WRMainAutoAssignButton", f)
    autoAssignButton:SetPoint("TOPLEFT", headerLine, "BOTTOMLEFT", 0, -5)
    autoAssignButton:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Up")           -- 使用骰子图标
    autoAssignButton:SetPushedTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Down")
    autoAssignButton:SetHighlightTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Highlight") -- 添加高亮
    autoAssignButton:SetWidth(40)
    autoAssignButton:SetHeight(40)
    autoAssignButton:SetScript("OnClick", function(_, button)
        if button == "LeftButton" then

        elseif button == "RightButton" then

        end
    end)
    -- 添加 Tooltip
    autoAssignButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["自动分配"], 1, 1, 1)
        GameTooltip:AddLine(L["左键点击进行自动分配"], 0.8, 0.8, 0.8)
        GameTooltip:AddLine(L["右键点击重新扫描团队"], 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    autoAssignButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.buttons["autoAssignButton"] = autoAssignButton


    -- 队伍标题下的水平分割线
    local titleLine = f:CreateTexture(nil, "ARTWORK")
    titleLine:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill")
    titleLine:SetWidth(f:GetWidth() - 10) -- 动态宽度
    titleLine:SetHeight(4)
    titleLine:SetPoint("TOPLEFT", autoAssignButton, "BOTTOMLEFT", 4, 0)
    f.textures["titleLine"] = titleLine



    -- 创建搜索框
    searchBox = CreateFrame("EditBox", nil, f,
        "InputBoxTemplate")
    searchBox:SetPoint("BOTTOM", f, "BOTTOM", 10, 10)
    searchBox:SetWidth(200)
    searchBox:SetHeight(30)
    searchBox:SetAutoFocus(false)
    searchBox:SetText("输入玩家名字")

    -- 创建查询按钮
    local searchButton = CreateFrame("Button", nil, f,
        "UIPanelButtonTemplate")
    searchButton:SetPoint("LEFT", searchBox, "RIGHT", 10, 0)
    searchButton:SetWidth(80)
    searchButton:SetHeight(30)
    searchButton:SetText("查询")
    searchButton:SetScript("OnClick", function()
        local query = searchBox:GetText()
        WRMain:UpdateComments(query)
    end)

    -- 重置查询按钮
    local resetButton = CreateFrame("Button", nil, f,
        "UIPanelButtonTemplate")
    resetButton:SetPoint("LEFT", searchButton, "RIGHT", 10, 0)
    resetButton:SetWidth(80)
    resetButton:SetHeight(30)
    resetButton:SetText("重置")
    resetButton:SetScript("OnClick", function()
        searchBox:SetText("输入玩家名字")
        WRMain:UpdateComments()
    end)

    -- 关闭按钮
    closeButton = CreateFrame("Button", nil, f,
        "UIPanelButtonTemplate")
    closeButton:SetPoint("LEFT", resetButton, "RIGHT", 10, 0)
    closeButton:SetWidth(80)
    closeButton:SetHeight(30)
    closeButton:SetText("关闭")
    closeButton:SetScript("OnClick", function()
        WRMain:UpdateComments()
        f:Hide()
    end)


    self.mf = f -- 将创建好的框架赋值给 self.mf
end

-- 动态生成评论内容
function WRMain:UpdateComments(personName)
    if not personName or not DT_WackoRank_PersonList[personName] then
        contentFrame:Hide() -- 清空内容
        return
    end

    searchBox:SetText(personName)
    searchBox:ClearFocus() -- 清除焦点

    local totalPeople = 0
    local totalComments = 0
    local totalLikes = 0
    local totalDisLikes = 0

    local cmts = DT_WackoRank_PersonList[personName]

    local pComments = {}
    for _, value in pairs(cmts) do
        totalPeople = totalPeople + 1

        if value.updateLikes == 1 then
            totalLikes = totalLikes + 1
        end
        if value.updateLikes == -1 then
            totalDisLikes = totalDisLikes + 1
        end

        local cms = value.comments
        for _, cm in ipairs(cms) do
            totalComments = totalComments + 1
            table.insert(pComments,
                { commentName = value.commentName, commentTime = cm.commentTime, comment = cm.comment, likes = cm.likes })
        end
    end

    contentFrame:Hide() -- 清空内容

    local yOffset = 0
    for _, comment in ipairs(pComments) do
        -- 创建表格头
        local cellFrame = CreateFrame("Frame", nil, contentFrame)
        cellFrame:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 0, yOffset)
        cellFrame:SetWidth(contentFrame:GetWidth() - 20)
        cellFrame:SetHeight(30)

        for i = 1, 3 do
            local commentText = contentFrame:CreateFontString(nil, "OVERLAY")
            commentText:SetFontObject("GameFontNormal")
            commentText:SetPoint("TOPLEFT", cellFrame, "TOPLEFT", (i - 1) * (cellFrame:GetWidth() / 3), 0)
            commentText:SetWidth(cellFrame:GetWidth() / 3)
            commentText:SetHeight(30)
            if i == 1 then
                commentText:SetText(comment.commentName)
            elseif i == 2 then
                commentText:SetText(comment.commentTime)
            else
                commentText:SetText(comment.comment)
            end
        end

        yOffset = yOffset - 30
    end

    local height = math.abs(yOffset)
    scrollFrame:SetVerticalScroll(0)
    scrollFrame:UpdateScrollChildRect()
    contentFrame:SetHeight(height)
    contentFrame:Show()

    WRMain:UpdateStats(totalPeople, totalComments, totalLikes, totalDisLikes)
end

-- 更新统计数据
function WRMain:UpdateStats(totalPeople, totalComments, totalLikes, totalDisLikes)
    local avgLikes = totalPeople > 0 and (totalLikes / totalPeople * 100) or 0
    statsText:SetText(string.format("玩家评价: 共%d人, %d条评论, 平均点赞率 %.2f%%, 好评: %d个, 差评: %d个, 中立: %d个,", totalPeople,
        totalComments, avgLikes, totalLikes, totalDisLikes, totalPeople - totalLikes - totalDisLikes))
    statsFrame.text = statsText
end

-- 注册监听聊天事件
function WRMain:RegisterChatEvents()
    self:RegisterEvent("CHAT_MSG_RAID", "HandleChatMessage")
    self:RegisterEvent("CHAT_MSG_RAID_LEADER", "HandleChatMessage")
    self:RegisterEvent("CHAT_MSG_SYSTEM", "HandleChatMessage")
end

function WRMain:HandleChatMessage(msg, sender)
    -- 这里可以根据需要处理聊天消息
    DEFAULT_CHAT_FRAME:AddMessage("收到聊天消息: " .. tostring(msg) .. " 来自: " .. tostring(sender))

    if msg == "你加入了一个团队。" then
        C_Timer.NewTicker(1, function()
            -- 备份原始单位弹出窗口点击处理函数
            ori_unitpopup_dv = UnitPopup_OnClick;
            -- 替换单位弹出窗口点击处理函数
            UnitPopup_OnClick = ple_unitpopup_dv;
        end, 1)
    end
end
