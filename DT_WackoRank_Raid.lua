-- 定义 WRRaid 模块表
WRRaid = {}

-- 获取本地化库实例
local L = AceLibrary("AceLocale-2.2"):new("RaidBuff")

-- 初始化 WRRaid 模块 (由 RaidBuff:OnInitialize 调用)
function WRRaid:OnInitialize()
    -- 创建 UI 框架 (如果尚未创建)
    if not self.mf then self:SetUpRaidFrame() end -- 主分配界面

    -- 存储团队成员职业信息 { ["playerName"] = "CLASS", ... }
    self.raidMemberClasses = {}
end

-- 扫描团队成员信息，更新 raidStat, cdt, raidMemberClasses
function WRRaid:Scan()
    self:ResetALL() -- 开始扫描前先重置

    for i = 1, GetNumRaidMembers() do
        local name, _, _, _, _, className = GetRaidRosterInfo(i) -- className 是英文大写职业名

        if name and className then
            -- 记录成员职业
            self.raidMemberClasses[name] = className

            -- 其他职业，直接用 className 匹配 RBDatabase 的 key
            if RBDatabase[className] then
                if not tableContainsValue(self.cdt[className], name) then     -- 避免重复添加
                    tinsert(self.cdt[className], name)
                end
            end
        end
    end
end
