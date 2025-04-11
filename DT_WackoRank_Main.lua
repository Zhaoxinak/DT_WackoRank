local BASE_FRAME_HEIGHT = 400 -- 主框架基础高度

-- 定义 WRMain 模块表
WRMain = {}

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
    f:SetWidth(800) -- 初始宽度，会动态调整
    f:SetHeight(BASE_FRAME_HEIGHT) -- 初始高度，会动态调整
    f:SetBackdrop({
        bgFile = "Interface\\RaidFrame\\UI-RaidFrame-GroupBg", -- 背景贴图
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", -- 边框贴图
        edgeSize = 16,
        insets = {left = 5, right = 5, top = 5, bottom = 5} -- 内边距
    })
    f:SetAlpha(0.7) -- 透明度
    f:SetFrameStrata("LOW") -- 框架层级

    -- 设置初始位置并允许拖动
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0) -- 默认居中
    f:EnableMouse(true)
    f:SetClampedToScreen(true) -- 限制在屏幕内
    f:RegisterForDrag("LeftButton")
    f:SetMovable(true)
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- 保存拖动后的位置到配置
        local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
        if WackoRank and RaidBuff.opt then
            WackoRank.opt.point["MainFrame"] = point
            WackoRank.opt.relativePoint["MainFrame"] = relativePoint
            WackoRank.opt.xOfs["MainFrame"] = xOfs
            WackoRank.opt.yOfs["MainFrame"] = yOfs
        end
    end)

    -- === 创建界面元素 ===
    f.textures = {} -- 存储纹理
    f.fontStrs = {} -- 存储字体串
    f.buttons = {} -- 存储按钮

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
    headerLine:SetWidth(f:GetWidth() - 10) -- 动态宽度
    headerLine:SetHeight(4)
    headerLine:SetPoint("BOTTOM", headerTexture, "BOTTOM", 0, 0)
    f.textures["headLine"] = headerLine

    -- 关闭按钮
    local closeButton = CreateFrame("Button", "WRMainCloseButton", f, "UIPanelCloseButton") -- 使用标准关闭按钮模板
    closeButton:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -7)
    closeButton:SetScript("OnClick", function() f:Hide() end)
    f.buttons["closeButton"] = closeButton

    -- 清除按钮
    local clearButton = CreateFrame("Button", "WRMainClearButton", f, "UIPanelButtonTemplate") -- 标准按钮模板
    clearButton:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -7)
    clearButton:SetWidth(60)
    clearButton:SetHeight(25)
    clearButton:SetText(L["清除"])
    clearButton:SetScript("OnClick", function()
        -- 清除所有 Buff 的分配
        for class, _ in pairs(RBDatabase) do self:ResetClass(class) end
        self:Flush() -- 刷新界面
    end)
    f.buttons["clearButton"] = clearButton

    -- 一键通报按钮
    local reportButton = CreateFrame("Button", "WRMainReportButton", f, "UIPanelButtonTemplate")
    reportButton:SetPoint("LEFT", clearButton, "RIGHT", 5, 0)
    reportButton:SetWidth(60)
    reportButton:SetHeight(25)
    reportButton:SetText(L["通报"])
    reportButton:SetScript("OnClick", function() self:ReportAll() end)
    f.buttons["reportButton"] = reportButton

    -- 添加统计数据展示区域
    local statsFrame = CreateFrame("Frame", "WRStatsFrame", f)
    statsFrame:SetPoint("TOP", headerLine, "BOTTOM", 0, -10)
    statsFrame:SetWidth(f:GetWidth() - 20)
    statsFrame:SetHeight(50)

    local statsText = statsFrame:CreateFontString(nil, "OVERLAY")
    statsText:SetFontObject("GameFontNormal")
    statsText:SetPoint("LEFT", statsFrame, "LEFT", 10, 0)
    statsText:SetText(L["统计数据"])
    statsFrame.text = statsText

    -- 添加滚动框架用于展示评论
    local scrollFrame = CreateFrame("ScrollFrame", "WRScrollFrame", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOP", statsFrame, "BOTTOM", 0, -10)
    scrollFrame:SetWidth(f:GetWidth() - 40)
    scrollFrame:SetHeight(BASE_FRAME_HEIGHT - 150)

    local contentFrame = CreateFrame("Frame", "WRContentFrame", scrollFrame)
    contentFrame:SetWidth(scrollFrame:GetWidth())
    contentFrame:SetHeight(1) -- 动态调整高度
    scrollFrame:SetScrollChild(contentFrame)

    -- 动态生成评论内容
    function WRMain:UpdateComments(personName, comments)
        contentFrame:Hide() -- 清空内容
        for i, child in ipairs({contentFrame:GetChildren()}) do
            child:Hide()
        end

        local yOffset = -10
        for i, comment in ipairs(comments) do
            local commentText = contentFrame:CreateFontString(nil, "OVERLAY")
            commentText:SetFontObject("GameFontNormal")
            commentText:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 10, yOffset)
            commentText:SetWidth(contentFrame:GetWidth() - 20)
            commentText:SetText(string.format("[%s] %s (Likes: %d)", comment.commentTime, comment.comment, comment.likes))
            yOffset = yOffset - 20
        end

        contentFrame:SetHeight(math.abs(yOffset))
        contentFrame:Show()
    end

    -- 更新统计数据
    function WRMain:UpdateStats(totalPeople, totalComments, totalLikes)
        statsFrame.text:SetText(string.format(L["统计数据格式"], totalPeople, totalComments, totalLikes))
    end

    -- --- 队伍标题行 ---
    -- 左上角图标按钮 (点击自动分配/刷新)
    local autoAssignButton = CreateFrame("Button", "WRMainAutoAssignButton", f)
    autoAssignButton:SetPoint("TOPLEFT", headerLine, "BOTTOMLEFT", 0, -5)
    autoAssignButton:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Up") -- 使用骰子图标
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

    -- -- 队伍编号标题按钮 (1-8)
    -- f.buttons["title"] = {}
    -- local lastTitleButton = autoAssignButton
    -- for i = 1, 8 do
    --     local titleButton = CreateFrame("Button", "WRMainTitleButton" .. i, f)
    --     titleButton:SetPoint("LEFT", lastTitleButton, "RIGHT", 4, 0)
    --     titleButton:SetWidth(90)
    --     titleButton:SetHeight(40)

    --     local fontStr = titleButton:CreateFontString(nil, "OVERLAY")
    --     fontStr:SetAllPoints(titleButton)
    --     fontStr:SetFontObject("GameFontNormal")
    --     fontStr:SetText(L["队伍"] .. i)
    --     titleButton.text = fontStr

    --     -- 垂直分割线
    --     local lineTexture = titleButton:CreateTexture(nil, "ARTWORK")
    --     lineTexture:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill")
    --     lineTexture:SetWidth(4)
    --     lineTexture:SetHeight(BASE_FRAME_HEIGHT - 80) -- 动态调整高度?
    --     lineTexture:SetPoint("TOPRIGHT", titleButton, "TOPLEFT", 0, 10) -- 调整位置
    --     titleButton.lineTexture = lineTexture -- 重命名避免与按钮自身冲突

    --     f.buttons["title"][i] = titleButton
    --     lastTitleButton = titleButton
    -- end

    -- 队伍标题下的水平分割线
    local titleLine = f:CreateTexture(nil, "ARTWORK")
    titleLine:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-BarFill")
    titleLine:SetWidth(f:GetWidth() - 10) -- 动态宽度
    titleLine:SetHeight(4)
    titleLine:SetPoint("TOPLEFT", autoAssignButton, "BOTTOMLEFT", 4, 0)
    f.textures["titleLine"] = titleLine

    self.mf = f -- 将创建好的框架赋值给 self.mf
end