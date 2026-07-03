-- AIBot Recorder - 记录身上所有物品（修复 GetPercent 错误）

local json = GLOBAL.json

local function log(msg)
    print("[AIBotRecorder] " .. tostring(msg))
end

-- 安全获取玩家位置
local function get_player_pos(player)
    if not player or not player.Transform then 
        return {x=0, y=0, z=0} 
    end
    local x, y, z = player.Transform:GetWorldPosition()
    x = x or 0
    y = y or 0
    z = z or 0
    return {x = x, y = y, z = z}
end

-- 获取附近实体
local function get_nearby_entities(player)
    local entities = {}
    if not player or not player.Transform then 
        return entities 
    end
    
    local x, y, z = player.Transform:GetWorldPosition()
    x = x or 0
    y = y or 0
    z = z or 0
    
    if not x then
        return entities
    end
    
    local all_entities = GLOBAL.TheSim:FindEntities(x, y, z, 15)
    if not all_entities then return entities end
    
    local count = 0
    local important = {
        "grass", "twig", "flint", "rock", "berry", 
        "carrot", "log", "tree", "pig", "spider", 
        "fire", "chest", "campfire", "rabbit",
        "flower", "butterfly", "bee", "honey", 
        "rabbit", "bird", "frog", "fish"
    }
    
    for _, ent in ipairs(all_entities) do
        if count >= 10 then break end
        if ent and ent.prefab and ent ~= player then
            local prefab = ent.prefab
            for _, name in ipairs(important) do
                if string.find(prefab, name) then
                    local ex, ey, ez = ent.Transform:GetWorldPosition()
                    ex = ex or 0
                    ey = ey or 0
                    ez = ez or 0
                    
                    local dist = math.sqrt((ex - x)^2 + (ez - z)^2)
                    table.insert(entities, {
                        prefab = prefab,
                        dist = math.floor(dist * 100) / 100,
                        x = ex,
                        z = ez
                    })
                    count = count + 1
                    break
                end
            end
        end
    end
    return entities
end

-- ⭐ 获取单个物品的详细信息（修复所有 nil 调用）
local function get_item_details(item, slot, slot_type)
    if not item then
        return nil
    end
    
    -- 即使没有组件，也记录基本信息和名称
    local details = {
        prefab = item.prefab or "unknown",
        slot = slot or -1,
        slot_type = slot_type or "inventory",
        count = 1  -- 默认数量
    }
    
    -- ⭐ 尝试获取显示名称（更易读）
    if item.name then
        details.display_name = item.name
    elseif item.prefab then
        -- 将prefab转换为更可读的名称
        local name_map = {
            ["grass"] = "草",
            ["twig"] = "树枝",
            ["flint"] = "燧石",
            ["rock"] = "石头",
            ["log"] = "木头",
            ["charcoal"] = "木炭",
            ["cutstone"] = "石砖",
            ["boards"] = "木板",
            ["rope"] = "绳子",
            ["goldnugget"] = "金块",
            ["nitre"] = "硝石",
            ["ash"] = "灰烬",
            ["petals"] = "花瓣",
            ["petals_evil"] = "恶魔花瓣",
            ["silk"] = "蜘蛛丝",
            ["honey"] = "蜂蜜",
            ["butter"] = "黄油",
            ["egg"] = "蛋",
            ["meat"] = "大肉",
            ["drumstick"] = "鸡腿",
            ["fish"] = "鱼",
            ["froglegs"] = "蛙腿",
            ["berry"] = "浆果",
            ["carrot"] = "胡萝卜",
            ["corn"] = "玉米",
            ["pumpkin"] = "南瓜",
            ["durian"] = "榴莲",
            ["dragonfruit"] = "火龙果",
            ["eggplant"] = "茄子",
            ["onion"] = "洋葱",
            ["pomegranate"] = "石榴",
            ["watermelon"] = "西瓜",
            ["cactus_flower"] = "仙人掌花",
            ["cactus_flesh"] = "仙人掌肉",
            ["red_cap"] = "红蘑菇",
            ["green_cap"] = "绿蘑菇",
            ["blue_cap"] = "蓝蘑菇",
            ["beefalowool"] = "牛毛",
            ["houndstooth"] = "犬牙",
            ["pigskin"] = "猪皮",
            ["feather_crow"] = "乌鸦羽毛",
            ["feather_robin"] = "红雀羽毛",
            ["feather_robin_winter"] = "雪雀羽毛",
            ["stinger"] = "蜂刺",
            ["tentaclespots"] = "触手皮",
            ["spidergland"] = "蜘蛛腺体",
            ["mosquitosack"] = "蚊子血囊",
            ["slurtle_shellpiece"] = "蜗牛壳片",
            ["snurtle_shellpiece"] = "甲壳碎片",
            ["spear"] = "长矛",
            ["axe"] = "斧头",
            ["pickaxe"] = "镐",
            ["shovel"] = "铲子",
            ["hammer"] = "锤子",
            ["razor"] = "剃刀",
            ["bugnet"] = "捕虫网",
            ["fishingrod"] = "鱼竿",
            ["trap"] = "陷阱",
            ["birdtrap"] = "捕鸟陷阱",
            ["tooth_trap"] = "犬牙陷阱",
            ["bedroll_straw"] = "草席卷",
            ["bedroll_furry"] = "毛皮铺盖",
            ["campfire"] = "营火",
            ["firepit"] = "火坑",
            ["tent"] = "帐篷",
            ["siestahut"] = "凉棚",
            ["cookpot"] = "烹饪锅",
            ["icebox"] = "冰箱",
            ["chest"] = "箱子",
            ["treasurechest"] = "宝藏箱",
            ["sculpture"] = "雕塑",
            ["sign"] = "路牌",
            ["torch"] = "火炬",
            ["lantern"] = "提灯",
            ["minerhat"] = "矿工帽",
            ["armorwood"] = "木盔甲",
            ["armor_sanity"] = "夜魔盔甲",
            ["footballhat"] = "猪皮头盔",
            ["beekeeperhat"] = "养蜂帽",
            ["eyebrellahat"] = "眼球伞",
            ["tophat"] = "高礼帽",
            ["flowerhat"] = "花环",
            ["garland"] = "花环",
            ["strawhat"] = "草帽",
            ["sweatervest"] = "毛衣背心",
            ["earmuffshat"] = "耳罩",
            ["beardhair"] = "胡须",
            ["livinglog"] = "活木",
            ["nightmarefuel"] = "噩梦燃料",
            ["yellowgem"] = "黄宝石",
            ["redgem"] = "红宝石",
            ["bluegem"] = "蓝宝石",
            ["purplegem"] = "紫宝石",
            ["orangegem"] = "橙宝石",
            ["greengem"] = "绿宝石",
            ["opalpreciousgem"] = "蛋白石",
            ["thulecite"] = "铥矿",
            ["thulecite_pieces"] = "铥矿碎片",
            ["marble"] = "大理石",
            ["moondust"] = "月尘",
            ["moonrock"] = "月岩",
            ["glassshard"] = "玻璃碎片",
        }
        details.display_name = name_map[item.prefab] or item.prefab
    end
    
    -- 获取堆叠数量（使用pcall保护）
    if item.components and item.components.stackable then
        local success, count = GLOBAL.pcall(function()
            return item.components.stackable:StackSize()
        end)
        if success and count then
            details.count = count
        end
    end
    
    -- ⭐ 获取耐久度
    if item.components and item.components.tool then
        if item.components.tool.GetPercent then
            local success, percent = GLOBAL.pcall(function()
                return item.components.tool:GetPercent()
            end)
            if success and percent then
                details.durability = math.floor(percent * 100)
            end
        end
    end
    
    if item.components and item.components.armor then
        if item.components.armor.GetPercent then
            local success, percent = GLOBAL.pcall(function()
                return item.components.armor:GetPercent()
            end)
            if success and percent then
                details.durability = math.floor(percent * 100)
            end
        end
    end
    
    -- ⭐ 获取新鲜度（食物）
    if item.components and item.components.perishable then
        if item.components.perishable.GetPercent then
            local success, percent = GLOBAL.pcall(function()
                return item.components.perishable:GetPercent()
            end)
            if success and percent then
                details.freshness = math.floor(percent * 100)
            end
        end
    end
    
    -- 获取燃料值
    if item.components and item.components.fuel then
        if item.components.fuel.GetCurrentFuel then
            local success, value = GLOBAL.pcall(function()
                return item.components.fuel:GetCurrentFuel()
            end)
            if success and value then
                details.fuel_value = value
            end
        end
    end
    
    -- 获取发光值
    if item.components and item.components.light then
        details.has_light = true
    end
    
    -- 是否可装备
    if item.components and item.components.equippable then
        details.equippable = true
        if item.components.equippable.equipslot then
            details.equip_slot = item.components.equippable.equipslot or "unknown"
        end
    end
    
    -- ⭐ 是否可食用
    if item.components and item.components.edible then
        details.edible = true
        if item.components.edible.GetHealth then
            local success, val = GLOBAL.pcall(function()
                return item.components.edible:GetHealth()
            end)
            if success and val then details.health_gain = val end
        end
        if item.components.edible.GetHunger then
            local success, val = GLOBAL.pcall(function()
                return item.components.edible:GetHunger()
            end)
            if success and val then details.hunger_gain = val end
        end
        if item.components.edible.GetSanity then
            local success, val = GLOBAL.pcall(function()
                return item.components.edible:GetSanity()
            end)
            if success and val then details.sanity_gain = val end
        end
    end
    
    -- ⭐ 标记是否为材料（用于显示）
    details.is_material = true
    
    return details
end

-- 获取玩家手上拿的物品
local function get_hand_item(player)
    if not player or not player.components.inventory then
        return nil
    end
    
    local active_item = player.components.inventory:GetActiveItem()
    if active_item and active_item.prefab then
        local details = get_item_details(active_item, 0, "hand")
        if details then
            details.in_hand = true
            return details
        end
    end
    return nil
end

-- 获取玩家身上装备的物品
local function get_equipped_items(player)
    local items = {}
    if not player or not player.components.inventory then
        return items
    end
    
    local inventory = player.components.inventory
    
    local equip_slots = {
        {name = "body", slot_type = "body", label = "盔甲"},
        {name = "head", slot_type = "head", label = "头盔"},
        {name = "neck", slot_type = "necklace", label = "护符"},
        {name = "hands", slot_type = "hands", label = "武器"},
        {name = "back", slot_type = "backpack", label = "背包"}
    }
    
    for _, slot_info in ipairs(equip_slots) do
        if inventory.GetEquippedItem then
            local success, item = GLOBAL.pcall(function()
                return inventory:GetEquippedItem(slot_info.name)
            end)
            if success and item and item.prefab then
                local details = get_item_details(item, 0, slot_info.slot_type)
                if details then
                    details.equipped = true
                    details.equip_slot_name = slot_info.name
                    table.insert(items, details)
                    log("🛡️ 装备: " .. item.prefab .. " (" .. slot_info.label .. ")")
                end
            end
        end
    end
    
    return items
end

-- ⭐ 改进：获取背包物品（确保所有物品都被记录）
local function get_inventory_items(player)
    local items = {}
    if not player then 
        return items 
    end
    
    if not player.components.inventory then
        return items
    end
    
    -- 方法1：通过 GetItems 获取
    local inv = nil
    if player.components.inventory.GetItems then
        local success, result = GLOBAL.pcall(function()
            return player.components.inventory:GetItems()
        end)
        if success and result then
            inv = result
        end
    end
    
    -- 方法2：直接读取 items 列表
    if not inv and player.components.inventory.items then
        local success, result = GLOBAL.pcall(function()
            return player.components.inventory.items
        end)
        if success and result then
            inv = result
        end
    end
    
    -- 方法3：遍历所有背包槽位
    if (not inv or #inv == 0) and player.components.inventory.GetItemInSlot then
        inv = {}
        for slot = 1, 30 do
            local success, item = GLOBAL.pcall(function()
                return player.components.inventory:GetItemInSlot(slot)
            end)
            if success and item then
                table.insert(inv, item)
            end
        end
    end
    
    if inv and #inv > 0 then
        for i = 1, math.min(#inv, 30) do
            local item = inv[i]
            if item then
                local item_details = get_item_details(item, i, "inventory")
                if item_details then
                    table.insert(items, item_details)
                    -- 记录每种物品，方便调试
                    log("📦 背包物品: " .. item_details.prefab .. " x" .. item_details.count)
                end
            end
        end
    else
        log("⚠️ 背包为空或无法获取")
    end
    
    return items
end

-- 获取身上所有物品
local function get_all_items(player)
    local all_items = {}
    
    -- 1. 背包物品
    local inventory_items = get_inventory_items(player)
    for _, item in ipairs(inventory_items) do
        table.insert(all_items, item)
    end
    
    -- 2. 手上物品
    local hand_item = get_hand_item(player)
    if hand_item then
        table.insert(all_items, hand_item)
        log("🖐️ 手上: " .. hand_item.prefab)
    end
    
    -- 3. 装备物品
    local equipped_items = get_equipped_items(player)
    for _, item in ipairs(equipped_items) do
        table.insert(all_items, item)
    end
    
    log("📊 总共记录物品: " .. #all_items .. " 个")
    return all_items
end

-- 获取游戏时间
local function get_game_time()
    if not GLOBAL.TheWorld or not GLOBAL.TheWorld.state then
        return 0
    end
    return (GLOBAL.TheWorld.state.cycles or 0) * 480 + (GLOBAL.TheWorld.state.time or 0)
end

-- 获取动作的详细信息
local function get_action_details(player, data)
    if not data then
        return {type = "unknown", target = "unknown"}
    end
    
    local action_type = data.action
    local target = data.target
    
    local action_name = tostring(action_type or "unknown")
    local target_name = "none"
    local target_info = {}
    
    -- 优化建造动作显示
    if action_type and string.find(tostring(action_type), "Recipe") then
        local recipe_str = tostring(action_type)
        local recipe_name = recipe_str:match("Recipe:%s*(%S+)")
        if recipe_name then
            action_name = "建造 " .. recipe_name
        end
    end
    
    -- 优化采集动作显示
    if action_type and string.find(tostring(action_type), "采集") then
        if target and target.prefab then
            action_name = "采集"
            target_name = target.prefab
        end
    end
    
    -- 优化拾取动作显示
    if action_type and string.find(tostring(action_type), "拾起") then
        if target and target.prefab then
            action_name = "拾取"
            target_name = target.prefab
        end
    end
    
    -- 优化攻击动作显示
    if action_type and string.find(tostring(action_type), "攻击") then
        if target and target.prefab then
            action_name = "攻击"
            target_name = target.prefab
        end
    end
    
    if target then
        if target.prefab then
            target_name = target.prefab
        end
        
        if target.Transform then
            local tx, ty, tz = target.Transform:GetWorldPosition()
            target_info.x = math.floor((tx or 0) * 100) / 100
            target_info.y = math.floor((ty or 0) * 100) / 100
            target_info.z = math.floor((tz or 0) * 100) / 100
        end
        
        if target:IsValid() then
            target_info.is_valid = true
        end
        
        if target.components and target.components.pickable then
            target_info.pickable = true
            if target.components.pickable.CanBePicked then
                local success, ready = GLOBAL.pcall(function()
                    return target.components.pickable:CanBePicked()
                end)
                if success then
                    target_info.ready = ready
                end
            end
        end
        
        if target.components and target.components.health then
            if target.components.health.GetPercent then
                local success, health = GLOBAL.pcall(function()
                    return target.components.health:GetPercent()
                end)
                if success and health then
                    target_info.health = math.floor(health * 100)
                end
            end
        end
        
        if target.components and target.components.stackable then
            if target.components.stackable.StackSize then
                local success, count = GLOBAL.pcall(function()
                    return target.components.stackable:StackSize()
                end)
                if success and count then
                    target_info.count = count
                end
            end
        end
    end
    
    local action_details = {
        type = action_name,
        target = target_name,
        target_info = target_info,
        player_pos = get_player_pos(player),
        timestamp = get_game_time()
    }
    
    return action_details
end

-- 保存数据到游戏存档
local function save_game_data(key, data)
    local safe_key = "AIBotRecorder." .. key
    GLOBAL.TheSim:SetPersistentString(safe_key, data, false)
end

-- 从游戏存档读取数据
local function load_game_data(key, callback)
    local safe_key = "AIBotRecorder." .. key
    GLOBAL.TheSim:GetPersistentString(safe_key, callback)
end

-- ⭐ 记录玩家状态（改进：更详细的日志）
local function record_player_state(player, action_data)
    if not player then 
        return 
    end
    
    local success, err = GLOBAL.pcall(function()
        local pos = get_player_pos(player)
        
        local state = {
            timestamp = get_game_time(),
            phase = GLOBAL.TheWorld and GLOBAL.TheWorld.state.phase or "unknown",
            day = GLOBAL.TheWorld and GLOBAL.TheWorld.state.day or 0,
            player_pos = pos,
            inventory = get_all_items(player),
            nearby = get_nearby_entities(player),
            health = 100,
            hunger = 100,
            sanity = 100,
            action = action_data or {type = "unknown", target = "unknown"}
        }
        
        if player.components.health and player.components.health.GetPercent then
            local success, health = GLOBAL.pcall(function()
                return player.components.health:GetPercent()
            end)
            if success and health then
                state.health = math.floor(health * 100)
            end
        end
        
        if player.components.hunger and player.components.hunger.GetPercent then
            local success, hunger = GLOBAL.pcall(function()
                return player.components.hunger:GetPercent()
            end)
            if success and hunger then
                state.hunger = math.floor(hunger * 100)
            end
        end
        
        if player.components.sanity and player.components.sanity.GetPercent then
            local success, sanity = GLOBAL.pcall(function()
                return player.components.sanity:GetPercent()
            end)
            if success and sanity then
                state.sanity = math.floor(sanity * 100)
            end
        end
        
        local data = json.encode(state)
        
        save_game_data("player_state", data)
        
        if action_data and action_data.type and action_data.type ~= "init" then
            local target_str = action_data.target or "none"
            log("🎯 动作: " .. action_data.type .. " | 目标: " .. target_str)
        end
        
        -- ⭐ 详细显示背包物品信息
        local item_count = #state.inventory
        if item_count > 0 then
            local item_names = {}
            for _, item in ipairs(state.inventory) do
                local display = item.display_name or item.prefab
                table.insert(item_names, display .. "x" .. item.count)
            end
            log("✅ 状态保存成功 | 物品: " .. table.concat(item_names, ", "))
        else
            log("✅ 状态保存成功 | 背包为空")
        end
    end)
    
    if not success then
        log("❌ 记录状态失败: " .. tostring(err))
    end
end

-- 读取Python命令
local function read_python_command()
    GLOBAL.TheWorld:DoTaskInTime(0, function()
        local success = GLOBAL.pcall(function()
            load_game_data("python_cmd", function(data)
                if not data or data == "" then 
                    return 
                end
                
                local parse_success, cmd = GLOBAL.pcall(json.decode, data)
                if not parse_success or not cmd then
                    log("解析命令失败")
                    return
                end
                
                log("收到命令: " .. tostring(cmd.action))
                
                if cmd.action == "click" then
                    GLOBAL.pcall(function()
                        if GLOBAL.ThePlayer and GLOBAL.ThePlayer.components.playercontroller then
                            local cam = GLOBAL.TheCamera
                            if cam and cmd.x and cmd.y then
                                local ray = cam:ScreenPointToRay(cmd.x, cmd.y)
                                GLOBAL.ThePlayer.components.playercontroller:ClickWorld(ray)
                                log("执行点击")
                            end
                        end
                    end)
                elseif cmd.action == "move" then
                    GLOBAL.pcall(function()
                        if GLOBAL.ThePlayer and GLOBAL.ThePlayer.components.playercontroller then
                            if cmd.x and cmd.z then
                                GLOBAL.ThePlayer.components.playercontroller:MoveToPoint(cmd.x, 0, cmd.z)
                                log("移动到: " .. cmd.x .. ", " .. cmd.z)
                            end
                        end
                    end)
                elseif cmd.action == "collect" then
                    GLOBAL.pcall(function()
                        if GLOBAL.ThePlayer then
                            local x, y, z = GLOBAL.ThePlayer.Transform:GetWorldPosition()
                            x = x or 0
                            z = z or 0
                            local ents = GLOBAL.TheSim:FindEntities(x, y or 0, z, 5)
                            for _, ent in ipairs(ents) do
                                if ent and ent.components.pickable then
                                    ent.components.pickable:Pickup(GLOBAL.ThePlayer)
                                    log("收集: " .. ent.prefab)
                                    break
                                end
                            end
                        end
                    end)
                elseif cmd.action == "attack" then
                    GLOBAL.pcall(function()
                        if GLOBAL.ThePlayer then
                            local x, y, z = GLOBAL.ThePlayer.Transform:GetWorldPosition()
                            x = x or 0
                            z = z or 0
                            local ents = GLOBAL.TheSim:FindEntities(x, y or 0, z, 5)
                            for _, ent in ipairs(ents) do
                                if ent and ent.components.combat and ent ~= GLOBAL.ThePlayer then
                                    GLOBAL.ThePlayer.components.combat:DoAttack(ent)
                                    log("攻击: " .. ent.prefab)
                                    break
                                end
                            end
                        end
                    end)
                end
                
                GLOBAL.pcall(function()
                    save_game_data("python_cmd", "")
                    log("命令已清除")
                end)
            end)
        end)
        
        if not success then
            log("读取命令失败")
        end
    end)
end

-- 监听玩家动作
AddPlayerPostInit(function(player)
    if not player then return end
    
    player:DoTaskInTime(2, function()
        log("🚀 AIBot Recorder 启动")
        record_player_state(player, {type = "init", target = "none"})
    end)
    
    player:ListenForEvent("performaction", function(inst, data)
        if not inst or not data then return end
        
        local action_details = get_action_details(inst, data)
        
        GLOBAL.TheWorld:DoTaskInTime(0, function()
            if not inst or not inst.Transform then return end
            
            record_player_state(inst, action_details)
            read_python_command()
        end)
        
        if data.action then
            local target_name = data.target and data.target.prefab or "无目标"
            log("🎯 动作触发: " .. tostring(data.action) .. " | 目标: " .. target_name)
        end
    end)
end)

log("AIBot Recorder 加载完成")