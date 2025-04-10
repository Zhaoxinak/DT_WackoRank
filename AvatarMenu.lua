-- 添加菜单按钮
UnitPopupButtons["CHECK_DV"] = { text = "风纪查询", dist = 0, nested = 1 };

-- 添加子菜单按钮
UnitPopupButtons["CHECK_DV_1"] = { text = "查询此人", dist = 0 };
UnitPopupButtons["CHECK_DV_2"] = { text = "查询此人公会", dist = 0 };
UnitPopupButtons["CHECK_DV_3"] = { text = "推荐此人", dist = 0 };
UnitPopupButtons["CHECK_DV_4"] = { text = "拉入黑名单", dist = 0 };
UnitPopupButtons["CHECK_DV_5"] = { text = "红黑榜", dist = 0 };
UnitPopupButtons["CHECK_DV_6"] = { text = "记事本", dist = 0 };



-- 初始化函数
local function Initialize()
    DEFAULT_CHAT_FRAME:AddMessage("初始化界面")

    -- 在单位弹出菜单中添加"风纪查询"按钮
    if UnitPopupMenus["PARTY"] then
        if not contain("CHECK_DV", UnitPopupMenus["PARTY"]) then
            table.insert(UnitPopupMenus["PARTY"], "CHECK_DV")
        end
    end

    -- 添加子菜单
    if not UnitPopupMenus["CHECK_DV"] then
        UnitPopupMenus["CHECK_DV"] = {
            "CHECK_DV_1",
            "CHECK_DV_2",
            "CHECK_DV_3",
            "CHECK_DV_4",
            "CHECK_DV_5",
            "CHECK_DV_6"
        };
    end
end

-- 调用初始化函数
Initialize()

-- 替换后的单位弹出窗口点击处理函数
function ple_unitpopup_dv()
    local dropdownFrame = getglobal(UIDROPDOWNMENU_INIT_MENU);
    local button = this.value;
    local unit = dropdownFrame.unit;
    local name = dropdownFrame.name;
    local server = dropdownFrame.server;

    DEFAULT_CHAT_FRAME:AddMessage(tostring(button))
    DEFAULT_CHAT_FRAME:AddMessage(tostring(unit))
    DEFAULT_CHAT_FRAME:AddMessage(tostring(name))
    DEFAULT_CHAT_FRAME:AddMessage(tostring(server))

    if (button == "CHECK_DV") then
        DEFAULT_CHAT_FRAME:AddMessage("CHECK_DV")
        DisciplinaryVillageFrame:Show()
        RefreshRaidData()
        -- 处理的子菜单
    elseif button == "CHECK_DV_1" then
        DEFAULT_CHAT_FRAME:AddMessage("CHECK_DV_1")
        -- 查询此人
        DisciplinaryVillageFrame:Show()
        FilterRaidData(name)
    elseif button == "CHECK_DV_2" then
        DEFAULT_CHAT_FRAME:AddMessage("CHECK_DV_2")
        -- 查询此人公会
        DisciplinaryVillageFrame:Show()
        local guildName = playerGuildData[name] or "无公会"
        FilterRaidData(guildName)
    elseif button == "CHECK_DV_3" then
        DEFAULT_CHAT_FRAME:AddMessage("CHECK_DV_3")
        -- 推荐该人
        -- XyAddDkp(name, 3);
    elseif button == "CHECK_DV_4" then
        DEFAULT_CHAT_FRAME:AddMessage("CHECK_DV_4")
        -- 拉入黑名单
        -- XyAddDkp(name, 4);
    elseif button == "CHECK_DV_5" then
        DEFAULT_CHAT_FRAME:AddMessage("CHECK_DV_5")
        -- 红黑榜
        -- XyAddDkp(name, 5);
    elseif button == "CHECK_DV_6" then
        DEFAULT_CHAT_FRAME:AddMessage("CHECK_DV_6")
        -- 记事本
        -- XyAddDkp(name, 6);
    else
        return ori_unitpopup_dv();
    end
end
