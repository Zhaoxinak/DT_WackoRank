-- 定义 WRMain 模块表
WRMain = {}

-- 获取本地化库实例
local L = AceLibrary("AceLocale-2.2"):new("RaidBuff")

-- 初始化 WRMain 模块 (由 RaidBuff:OnInitialize 调用)
function WRMain:OnInitialize()
    -- 创建 UI 框架 (如果尚未创建)
    if not self.mf then self:SetUpMainFrame() end -- 主分配界面

end

