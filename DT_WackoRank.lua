--[[---------------------------------------------------------------------------
  DT_WackoRank 主文件
  - 注册聊天命令和选项菜单
---------------------------------------------------------------------------]]

-- 插件对象定义，继承 Ace 库功能
WackoRank = AceLibrary("AceAddon-2.0"):new(
    "AceConsole-2.0",    -- 命令行接口
    "FuBarPlugin-2.0",    -- FuBar 插件支持
    "AceDB-2.0"       -- 数据库 (保存配置)
)

-- 获取本地化库实例
local L = AceLibrary("AceLocale-2.2"):new("WackoRank")

-- FuBar 或类似插件显示的图标
WackoRank.hasIcon = "Interface\\Icons\\Spell_nature_forceofnature"

-- === 插件生命周期函数 ===

-- 插件初始化 (仅执行一次)
function WackoRank:OnInitialize()
    -- 聊天框输出前缀
    self.Prefix = "|cffF5F54A[疯神榜]|r|cff9482C9角色笔记|r"

    -- 注册数据库 "WackoRankDB"
    self:RegisterDB("WackoRankDB")
    -- 注册默认配置结构
    self:RegisterDefaults("profile", {})

    -- 初始化选项菜单
    self:InitializeOptions()
    self.OnMenuRequest = self.options -- 用于 FuBar 等插件显示菜单

    -- 注册聊天命令
    self:RegisterChatCommand({"/WackoRank", "/WR"}, self.options)

    DEFAULT_CHAT_FRAME:AddMessage(self.Prefix .. L["已加载"])
end

-- === 选项菜单 ===

-- 初始化插件选项菜单
function WackoRank:InitializeOptions()
    self.options = {
        type = "group",
        args = {
            openFrame = {
                type = "execute",
                name = L["打开界面"],
                desc = L["打开界面描述"],
                order = 1,
                func = function()
                    if WRMain and WRMain.mf then
                        WRMain.mf:Show()
                    else
                        self:Print("错误：无法打开界面，WRMain 或其界面未初始化。")
                    end
                end
            },
        }
    }
end