-- 添加菜单按钮
UnitPopupButtons["CHECK_WR"] = { text = "疯神查询", dist = 0, nested = 1 };

-- 添加子菜单按钮
UnitPopupButtons["CHECK_WR_1"] = { text = "查询此人", dist = 0 };
UnitPopupButtons["CHECK_WR_2"] = { text = "评价此人", dist = 0 };
UnitPopupButtons["CHECK_WR_3"] = { text = "拉入黑名单", dist = 0 };
UnitPopupButtons["CHECK_WR_4"] = { text = "疯神榜", dist = 0 };



-- 初始化函数
local function Initialize()
   
    -- 在单位弹出菜单中添加"风纪查询"按钮
    if UnitPopupMenus["PARTY"] then
        if not contain("CHECK_WR", UnitPopupMenus["PARTY"]) then
            table.insert(UnitPopupMenus["PARTY"], "CHECK_WR")
        end
    end

    -- 添加子菜单
    if not UnitPopupMenus["CHECK_WR"] then
        UnitPopupMenus["CHECK_WR"] = {
            "CHECK_WR_1",
            "CHECK_WR_2",
            "CHECK_WR_3",
            "CHECK_WR_4",
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

    if (button == "CHECK_WR") then
        DEFAULT_CHAT_FRAME:AddMessage("CHECK_WR")
      
        -- 处理的子菜单
    elseif button == "CHECK_WR_1" then
        DEFAULT_CHAT_FRAME:AddMessage("CHECK_WR_1")
        -- 查询此人
        WRMain.mf:Show()
        WRMain:UpdateComments(name)
    elseif button == "CHECK_WR_2" then
        DEFAULT_CHAT_FRAME:AddMessage("CHECK_WR_2")
        -- 评价此人
      
    elseif button == "CHECK_WR_3" then
        DEFAULT_CHAT_FRAME:AddMessage("CHECK_WR_3")
        -- 拉入黑名单
 
    elseif button == "CHECK_WR_4" then
        DEFAULT_CHAT_FRAME:AddMessage("CHECK_WR_4")
        -- 疯神榜
      
    else
        return ori_unitpopup_dv();
    end
end
