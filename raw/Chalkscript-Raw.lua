util.require_natives("1672190175")

PatchNoteFixed = "\tNone"
PatchNoteAdded = "\tB-11 'Fix'; Vehicle/Main/Aircraft/Jet/" 

local response = false
local localVersion = 5.40
local currentVersion
async_http.init("raw.githubusercontent.com", "/ViperOne1/Chalkscript/main/raw/version", function(output)
    currentVersion = tonumber(output)
    response = true
    if localVersion ~= currentVersion then
        util.toast("-Chalkscript-\n\nThere is a New Version of Chalkscript Available!\nClick 'UPDATE' in Chalkscript's Root to Update it.")
        menu.action(menu.my_root(), "UPDATE", {""}, "Update Chalkscript to the Latest Version Available", function(on_click)
            async_http.init('raw.githubusercontent.com','/ViperOne1/Chalkscript/main/raw/Chalkscript-Raw.lua',function(contents)
                local err = select(2,load(contents))
                if err then
                    util.toast("-Chalkscript-\n\nScript Failed to Download off Github.")
                return end
                local csLua = io.open(filesystem.scripts_dir()..SCRIPT_RELPATH, "wb")
                csLua:write(contents)
                csLua:close()
                util.toast("-Chalkscript\n\nSuccessfully Installed Chalkscript.\nHave Fun!")
                util.restart_script()
            end)
            async_http.dispatch()
        end)
    end
end, function() response = true end) 
async_http.dispatch()
repeat 
    util.yield()
until response



--[[ ||| DEFINE FUNCTIONS ||| ]]--

function Get_Waypoint_Pos2()
    if HUD.IS_WAYPOINT_ACTIVE() then
        local blip = HUD.GET_FIRST_BLIP_INFO_ID(8)
        local waypoint_pos = HUD.GET_BLIP_COORDS(blip)
        return waypoint_pos
    else
        util.toast("-Chalkscript-\n\nNo Waypoint Set!")
    end
end

STP_COORD_HEIGHT = 300
STP_SPEED_MODIFIER = 0.02
function SmoothTeleportToCord(v3coords, teleportFrame)
    local wppos = v3coords
    local localped = PLAYER.GET_PLAYER_PED(players.user())
    if wppos ~= nil then 
        if not CAM.DOES_CAM_EXIST(CCAM) then
            CAM.DESTROY_ALL_CAMS(true)
            CCAM = CAM.CREATE_CAM("DEFAULT_SCRIPTED_CAMERA", true)
            CAM.SET_CAM_ACTIVE(CCAM, true)
            CAM.RENDER_SCRIPT_CAMS(true, false, 0, true, true, 0)
        end
        if teleportFrame then
            util.create_tick_handler(function ()
                if CAM.DOES_CAM_EXIST(CCAM) then
                    local tickCamCoord = CAM.GET_CAM_COORD(CCAM)
                    if not PED.IS_PED_IN_ANY_VEHICLE(localped, true) then 
                        ENTITY.SET_ENTITY_COORDS(localped, tickCamCoord.x, tickCamCoord.y, tickCamCoord.z, false, false, false, false) 
                    else
                        local veh = PED.GET_VEHICLE_PED_IS_IN(localped, false)
                        ENTITY.SET_ENTITY_COORDS(veh, tickCamCoord.x, tickCamCoord.y, tickCamCoord.z, false, false, false, false) 
                    end
                else
                    return false
                end
            end)
        end
        local pc = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(players.user()))
        for i = 0, 1, STP_SPEED_MODIFIER do 
            CAM.SET_CAM_COORD(CCAM, pc.x, pc.y, pc.z + EaseOutCubic(i) * STP_COORD_HEIGHT)
            local White = {r = 1.0, g = 1.0, b = 1.0, a = 1.0}
            directx.draw_text(0.5, 0.5, tostring(EaseOutCubic(i) * STP_COORD_HEIGHT), 1, 0.6, White, false)
            local look = util.v3_look_at(CAM.GET_CAM_COORD(CCAM), pc)
            CAM.SET_CAM_ROT(CCAM, look.x, look.y, look.z, 2)
            util.yield()
        end
        local currentZ = CAM.GET_CAM_COORD(CCAM).z
        local coordDiffx = wppos.x - pc.x
        local coordDiffxy = wppos.y - pc.y
        for i = 0, 1, STP_SPEED_MODIFIER / 2 do
            CAM.SET_CAM_COORD(CCAM, pc.x + (EaseInOutCubic(i) * coordDiffx), pc.y + (EaseInOutCubic(i) * coordDiffxy), currentZ)
            util.yield()
        end
        local success, ground_z
        repeat
            STREAMING.REQUEST_COLLISION_AT_COORD(wppos.x, wppos.y, wppos.z)
            success, ground_z = util.get_ground_z(wppos.x, wppos.y)
            util.yield()
        until success
        if not PED.IS_PED_IN_ANY_VEHICLE(localped, true) then 
            ENTITY.SET_ENTITY_COORDS(localped, wppos.x, wppos.y, ground_z, false, false, false, false) 
        else
            local veh = PED.GET_VEHICLE_PED_IS_IN(localped, false)
            local v3Out = memory.alloc()
            local headOut = memory.alloc()
            PATHFIND.GET_CLOSEST_VEHICLE_NODE_WITH_HEADING(wppos.x, wppos.y, ground_z, v3Out, headOut, 1, 3.0, 0)
            local head = memory.read_float(headOut)
            memory.free(headOut)
            memory.free(v3Out)
            ENTITY.SET_ENTITY_COORDS(veh, wppos.x, wppos.y, ground_z, false, false, false, false)
            ENTITY.SET_ENTITY_HEADING(veh, head)
        end
        util.yield()
        local pc2 = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(players.user()))
        local coordDiffz = CAM.GET_CAM_COORD(CCAM).z - ground_z -2
        local camcoordz = CAM.GET_CAM_COORD(CCAM).z       
        for i = 0, 1, STP_SPEED_MODIFIER / 2 do
            local pc23 = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(players.user()))
            CAM.SET_CAM_COORD(CCAM, pc23.x, pc23.y, camcoordz - (EaseOutCubic(i) * coordDiffz))
            util.yield()
        end
        util.yield()
        CAM.RENDER_SCRIPT_CAMS(false, false, 0, true, true, 0)
        if CAM.IS_CAM_ACTIVE(CCAM) then
            CAM.SET_CAM_ACTIVE(CCAM, false)
        end
        CAM.DESTROY_CAM(CCAM, true)
    else
        util.toast("-Chalkscript-\n\nNo Waypoint Set!")
    end
end

function TurnCarOnInstantly()
    local localped = players.user_ped()
    if PED.IS_PED_GETTING_INTO_A_VEHICLE(localped) then
        local veh = PED.GET_VEHICLE_PED_IS_ENTERING(localped)
        if not VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(veh) then
            VEHICLE.SET_VEHICLE_FIXED(veh)
            VEHICLE.SET_VEHICLE_ENGINE_HEALTH(veh, 1000)
            VEHICLE.SET_VEHICLE_ENGINE_ON(veh, true, true, false)
        end
        if VEHICLE.GET_VEHICLE_CLASS(veh) == 15 then
            VEHICLE.SET_HELI_BLADES_FULL_SPEED(veh)
        end
    end
end

function EaseOutCubic(x)
    return 1 - ((1-x) ^ 3)
end

function EaseInCubic(x)
    return x * x * x
end

function EaseInOutCubic(x)
    if(x < 0.5) then
        return 4 * x * x * x;
    else
        return 1 - ((-2 * x + 2) ^ 3) / 2
    end
end

function UnlockVehicleGetIn()
    ::start::
    local localPed = players.user_ped()
    local veh = PED.GET_VEHICLE_PED_IS_TRYING_TO_ENTER(localPed)
    if PED.IS_PED_IN_ANY_VEHICLE(localPed, false) then
        local v = PED.GET_VEHICLE_PED_IS_IN(localPed, false)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED(v, 1)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(v, false)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(v, players.user(), false)
        util.yield()
    else
        if veh ~= 0 and VEHICLE.GET_PED_IN_VEHICLE_SEAT(veh, -1, false) == 0 or veh ~= 0 and VEHICLE.GET_PED_IN_VEHICLE_SEAT(veh, -1, false) == players.user_ped() then
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
            if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(veh) then
                for i = 1, 20 do
                    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                    util.yield(100)
                end
            end
            if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(veh) then
                util.toast("-Chalkscript-\n\nCould not get Control of Entity.")
                goto start
            else
                if SE_Notifications then
                    util.toast("-Chalkscript-\n\nGot Control of Entity.")
                end
            end
            VEHICLE.SET_VEHICLE_DOORS_LOCKED(veh, 1)
            VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(veh, false)
            VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(veh, players.user(), false)
            VEHICLE.SET_VEHICLE_HAS_BEEN_OWNED_BY_PLAYER(veh, false)
            util.yield(2500)
            if not PED.IS_PED_IN_VEHICLE(players.user(), veh) then
                PED.SET_PED_INTO_VEHICLE(players.user_ped(), veh, -1)
            end
        end
    end
end

function RemoveVehicleGodmodeForAll()
    for i = 0, 31 do
        if NETWORK.NETWORK_IS_PLAYER_CONNECTED(i) then
            local ped = PLAYER.GET_PLAYER_PED(i)
            if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
                local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
                ENTITY.SET_ENTITY_CAN_BE_DAMAGED(veh, true)
                ENTITY.SET_ENTITY_INVINCIBLE(veh, false)
            end
        end
    end
end

player_cur_car = 0
function OpenVehicleDoor_CurCar(open, doorIndex, loose, instant, force)
    if open then    
        VEHICLE.SET_VEHICLE_DOOR_OPEN(player_cur_car, doorIndex, loose, instant)
        if force then
            while force do
                VEHICLE.SET_VEHICLE_DOOR_OPEN(player_cur_car, doorIndex, LooseDoorBool, InstantDoorBool)
                util.yield()    
            end
        end
    elseif open == false then
        VEHICLE.SET_VEHICLE_DOOR_SHUT(player_cur_car, doorIndex, InstantDoorBool)
    end
end

function LowerVehicleWindow_CurCar(lower, windowIndex)
    if lower then 
        VEHICLE.ROLL_DOWN_WINDOW(player_cur_car, windowIndex)
    else
        VEHICLE.ROLL_UP_WINDOW(player_cur_car, windowIndex)
    end
end

local function bitTest(addr, offset)
    return (memory.read_int(addr) & (1 << offset)) ~= 0
end

local function clearBit(addr, bitIndex)
    memory.write_int(addr, memory.read_int(addr) & ~(1<<bitIndex))
end

function request_ptfx_asset(asset)
    local request_time = os.time()
    STREAMING.REQUEST_NAMED_PTFX_ASSET(asset)
    while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(asset) do
        if os.time() - request_time >= 10 then
            break
        end
        util.yield()
    end
end

local function raycast_gameplay_cam(flag, distance)
    local ptr1, ptr2, ptr3, ptr4 = memory.alloc(), memory.alloc(), memory.alloc(), memory.alloc()
    local cam_rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
    local cam_pos = CAM.GET_GAMEPLAY_CAM_COORD()
    local direction = v3.toDir(cam_rot)
    local destination = 
    { 
        x = cam_pos.x + direction.x * distance, 
        y = cam_pos.y + direction.y * distance, 
        z = cam_pos.z + direction.z * distance 
    }
    SHAPETEST.GET_SHAPE_TEST_RESULT(
        SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
            cam_pos.x, 
            cam_pos.y, 
            cam_pos.z, 
            destination.x, 
            destination.y, 
            destination.z, 
            flag, 
            players.user_ped(), 
            1
        ), ptr1, ptr2, ptr3, ptr4)
    local p1 = memory.read_int(ptr1)
    local p2 = memory.read_vector3(ptr2)
    local p3 = memory.read_vector3(ptr3)
    local p4 = memory.read_int(ptr4)
    return {p1, p2, p3, p4}
end

local function raycast_vehicle_heading(flag, distance, vehicle)
    local ptr1, ptr2, ptr3, ptr4 = memory.alloc(), memory.alloc(), memory.alloc(), memory.alloc()
    local veh_rot = ENTITY.GET_ENTITY_ROTATION(vehicle, 2)
    local veh_pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, 0, 0, 0)
    local direction = v3.toDir(veh_rot)
    local destination = 
    { 
        x = veh_pos.x + direction.x * distance, 
        y = veh_pos.y + direction.y * distance, 
        z = veh_pos.z + direction.z * distance 
    }
    SHAPETEST.GET_SHAPE_TEST_RESULT(
        SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
            veh_pos.x, 
            veh_pos.y, 
            veh_pos.z, 
            destination.x, 
            destination.y, 
            destination.z, 
            flag, 
            players.user_ped(), 
            1
        ), ptr1, ptr2, ptr3, ptr4)
    local p1 = memory.read_int(ptr1)
    local p2 = memory.read_vector3(ptr2)
    local p3 = memory.read_vector3(ptr3)
    local p4 = memory.read_int(ptr4)
    return {p1, p2, p3, p4}
end

function GetClosestPlayerWithRange(range)
    local pedPointers = entities.get_all_peds_as_pointers()
    local rangesq = range * range
    local ourCoords = ENTITY.GET_ENTITY_COORDS(players.user_ped())
    local tbl = {}
    local closest_player = 0
    for i = 1, #pedPointers do
        local tarcoords = entities.get_position(pedPointers[i])
        local vdist = SYSTEM.VDIST2(ourCoords.x, ourCoords.y, ourCoords.z, tarcoords.x, tarcoords.y, tarcoords.z)
        if vdist <= rangesq then
            tbl[#tbl+1] = entities.pointer_to_handle(pedPointers[i])
        end
    end
    if tbl ~= nil then
        local dist = 999999
        for i = 1, #tbl do
            if tbl[i] ~= players.user_ped() then
                if PED.IS_PED_A_PLAYER(tbl[i]) then
                    local tarcoords = ENTITY.GET_ENTITY_COORDS(tbl[i])
                    local e = SYSTEM.VDIST2(ourCoords.x, ourCoords.y, ourCoords.z, tarcoords.x, tarcoords.y, tarcoords.z)
                    if e < dist then
                        dist = e
                        closest_player = tbl[i]
                    end
                end
            end
        end
    end
    if closest_player ~= 0 then
        return closest_player
    else
        return nil
    end
end

AIM_WHITELIST = {}
function GetClosestPlayerWithRange_Whitelist(range, inair)
    local pedPointers = entities.get_all_peds_as_pointers()
    local rangesq = range * range
    local ourCoords = ENTITY.GET_ENTITY_COORDS(players.user_ped())
    local tbl = {}
    local closest_player = 0
    for i = 1, #pedPointers do
        local tarcoords = entities.get_position(pedPointers[i])
        local vdist = SYSTEM.VDIST2(ourCoords.x, ourCoords.y, ourCoords.z, tarcoords.x, tarcoords.y, tarcoords.z)
        if vdist <= rangesq then
            local handle = entities.pointer_to_handle(pedPointers[i])
            if (inair and (ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(handle) >= 9)) or (not inair) then --air check
                local playerID = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(handle)
                if not AIM_WHITELIST[playerID] then
                    tbl[#tbl+1] = handle
                end
            end
        end
    end
    if tbl ~= nil then
        local dist = 999999
        for i = 1, #tbl do
            if tbl[i] ~= players.user_ped() then
                if PED.IS_PED_A_PLAYER(tbl[i]) then
                    local tarcoords = ENTITY.GET_ENTITY_COORDS(tbl[i])
                    local e = SYSTEM.VDIST2(ourCoords.x, ourCoords.y, ourCoords.z, tarcoords.x, tarcoords.y, tarcoords.z)
                    if e < dist then
                        dist = e
                        closest_player = tbl[i]
                    end
                end
            end
        end
    end
    if closest_player ~= 0 then
        return closest_player
    else
        return nil
    end
end

function GetClosestVehicleNodeWithHeading(x, y, z, nodeType)
    local outpos = v3.new()
    local outHeading = memory.alloc()
    PATHFIND.GET_CLOSEST_VEHICLE_NODE_WITH_HEADING(x, y, z, outpos, outHeading, nodeType, 3.0, 0)
    local pos = GetTableFromV3Instance(outpos); local heading = memory.read_float(outHeading)
    memory.free(outHeading); v3.free(outpos); return pos, heading
end

function GetTableFromV3Instance(v3int)
    local tbl = {x = v3.getX(v3int), y = v3.getY(v3int), z = v3.getZ(v3int)}
    return tbl
end

function BlockSyncs(pid, callback)
    for _, i in ipairs(players.list(false, true, true)) do
        if i ~= pid then
            local outSync = menu.ref_by_rel_path(menu.player_root(i), "Outgoing Syncs>Block")
            menu.trigger_command(outSync, "on")
        end
    end
    util.yield(10)
    callback()
    for _, i in ipairs(players.list(false, true, true)) do
        if i ~= pid then
            local outSync = menu.ref_by_rel_path(menu.player_root(i), "Outgoing Syncs>Block")
            menu.trigger_command(outSync, "off")
        end
    end
end

function request_model(hash, timeout)
    timeout = timeout or 3
    STREAMING.REQUEST_MODEL(hash)
    local end_time = os.time() + timeout
    repeat
        util.yield()
    until STREAMING.HAS_MODEL_LOADED(hash) or os.time() >= end_time
    return STREAMING.HAS_MODEL_LOADED(hash)
end

spawned_objects = {}
get_vtable_entry_pointer = function(address, index)
    return memory.read_long(memory.read_long(address) + (8 * index))
end
get_sub_handling_types = function(vehicle, type)
    local veh_handling_address = memory.read_long(entities.handle_to_pointer(vehicle) + 0x918)
    local sub_handling_array = memory.read_long(veh_handling_address + 0x0158)
    local sub_handling_count = memory.read_ushort(veh_handling_address + 0x0160)
    local types = {registerd = sub_handling_count, found = 0}
    for i = 0, sub_handling_count - 1, 1 do
        local sub_handling_data = memory.read_long(sub_handling_array + 8 * i)
        if sub_handling_data ~= 0 then
            local GetSubHandlingType_address = get_vtable_entry_pointer(sub_handling_data, 2)
            local result = util.call_foreign_function(GetSubHandlingType_address, sub_handling_data)
            if type and type == result then return sub_handling_data end
            types[#types+1] = {type = result, address = sub_handling_data}
            types.found = types.found + 1
        end
    end
    if type then return nil else return types end
end
local thrust_offset = 0x8
local better_heli_handling_offsets = {
    ["fYawMult"] = 0x18,
    ["fYawStabilise"] = 0x20, 
    ["fSideSlipMult"] = 0x24, 
    ["fRollStabilise"] = 0x30, 
    ["fAttackLiftMult"] = 0x48, 
    ["fAttackDiveMult"] = 0x4C, 
    ["fWindMult"] = 0x58, 
    ["fPitchStabilise"] = 0x3C 
}

--Defining What is a Projectile
local function is_entity_a_projectile_all(hash)     -- All Projectile Offests
    local all_projectile_hashes = {
        util.joaat("w_ex_vehiclemissile_1"),
        util.joaat("w_ex_vehiclemissile_2"),
        util.joaat("w_ex_vehiclemissile_3"),
        util.joaat("w_ex_vehiclemissile_4"),
        util.joaat("w_ex_vehiclemortar"),
        util.joaat("w_ex_apmine"),
        util.joaat("w_ex_arena_landmine_01b"),
        util.joaat("w_ex_birdshat"),
        util.joaat("w_ex_grenadefrag"),
        util.joaat("xm_prop_x17_mine_01a"),
        util.joaat("xm_prop_x17_mine_02a"),
        util.joaat("w_ex_grenadesmoke"),
        util.joaat("w_ex_molotov"),
        util.joaat("w_ex_pe"),
        util.joaat("w_ex_pipebomb"),
        util.joaat("w_ex_snowball"),
        util.joaat("w_lr_rpg_rocket"),
        util.joaat("w_lr_homing_rocket"),
        util.joaat("w_lr_firework_rocket"),
        util.joaat("xm_prop_x17_silo_rocket_01"),
        util.joaat("w_ex_vehiclegrenade"),
        util.joaat("w_ex_vehiclemine"),
        util.joaat("w_lr_40mm"),
        util.joaat("w_smug_bomb_01"),
        util.joaat("w_smug_bomb_02"),
        util.joaat("w_smug_bomb_03"),
        util.joaat("w_smug_bomb_04"),
        util.joaat("w_am_flare"),
        util.joaat("w_arena_airmissile_01a"),
        util.joaat("w_pi_flaregun_shell"),
        util.joaat("w_smug_airmissile_01b"),
        util.joaat("w_smug_airmissile_02"),
        util.joaat("w_sr_heavysnipermk2_mag_ap2"),
        util.joaat("w_battle_airmissile_01"),
        util.joaat("gr_prop_gr_pmine_01a")
    }
    return table.contains(all_projectile_hashes, hash)
end

local function is_entity_a_missle(hash)     -- Missle Projectile Offsets
    local missle_hashes = {
        util.joaat("w_ex_vehiclemissile_1"),
        util.joaat("w_ex_vehiclemissile_2"),
        util.joaat("w_ex_vehiclemissile_3"),
        util.joaat("w_ex_vehiclemissile_4"),
        util.joaat("w_lr_rpg_rocket"),
        util.joaat("w_lr_homing_rocket"),
        util.joaat("w_lr_firework_rocket"),
        util.joaat("xm_prop_x17_silo_rocket_01"),
        util.joaat("w_arena_airmissile_01a"),
        util.joaat("w_smug_airmissile_01b"),
        util.joaat("w_smug_airmissile_02"),
        util.joaat("w_battle_airmissile_01"),
        util.joaat("h4_prop_h4_airmissile_01a")
    }
    return table.contains(missle_hashes, hash)
end

local function is_entity_a_grenade(hash)    -- Grenade Projectile Offsets
    local grenade_hashes = {
        util.joaat("w_ex_vehiclemortar"),
        util.joaat("w_ex_grenadefrag"),
        util.joaat("w_ex_grenadesmoke"),
        util.joaat("w_ex_molotov"),
        util.joaat("w_ex_pipebomb"),
        util.joaat("w_ex_snowball"),
        util.joaat("w_ex_vehiclegrenade"),
        util.joaat("w_lr_40mm")
    }
    return table.contains(grenade_hashes, hash)
end

local function is_entity_a_mine(hash)       -- Mine Projectile Offsets
    local mine_hashes = {
        util.joaat("w_ex_apmine"),
        util.joaat("w_ex_arena_landmine_01b"),
        util.joaat("w_ex_pe"),
        util.joaat("w_ex_vehiclemine"),
        util.joaat("xm_prop_x17_mine_01a"),
        util.joaat("xm_prop_x17_mine_02a"),
        util.joaat("gr_prop_gr_pmine_01a")
    }
    return table.contains(mine_hashes, hash)
end

local function is_entity_a_miscprojectile(hash)     -- Misc Projectile Offsets
    local miscproj_hashes = {
        util.joaat("w_ex_birdshat"),
        util.joaat("w_ex_snowball"),
        util.joaat("w_pi_flaregun_shell"),
        util.joaat("w_am_flare"),
        util.joaat("w_lr_ml_40mm"),
        util.joaat("w_sr_heavysnipermk2_mag_ap2")
    }
    return table.contains(miscproj_hashes, hash)
end

local function is_entity_a_bomb(hash)
   local bomb_hashes = {
        util.joaat("w_smug_bomb_01"),
        util.joaat("w_smug_bomb_02"),
        util.joaat("w_smug_bomb_03"),
        util.joaat("w_smug_bomb_04")
   } 
   return table.contains(bomb_hashes, hash)
end

function on_user_change_vehicle(vehicle)
    if vehicle ~= 0 then
        if initial_d_mode then 
            set_vehicle_into_drift_mode(vehicle)
        end
    end
end

function player_toggle_loop(root, pid, menu_name, command_names, help_text, callback)
    return menu.toggle_loop(root, menu_name, command_names, help_text, function()
        if not players.exists(pid) then util.stop_thread() end
        callback()
    end)
end

function getPlayerRegType(pid) --[[-1 = No Reg / 0 = CEO / 1 = MC]]
    local boss = players.get_boss(pid)
    if boss ~= -1 then
        return memory.read_int(memory.script_global(1892703+1+boss*599+(10+428)))
    end
    return -1
end

local function ls_log(content)
    if ls_debug then
        util.toast(content)
        util.log(translations.script_name_for_log .. content)
    end
end

function show_custom_rockstar_alert(l1)
    poptime = os.time()
    while true do
        if PAD.IS_CONTROL_JUST_RELEASED(18, 18) then
            if os.time() - poptime > 0.1 then
                break
            end
        end
        native_invoker.begin_call()
        native_invoker.push_arg_string("ALERT")
        native_invoker.push_arg_string("JL_INVITE_ND")
        native_invoker.push_arg_int(2)
        native_invoker.push_arg_string("")
        native_invoker.push_arg_bool(true)
        native_invoker.push_arg_int(-1)
        native_invoker.push_arg_int(-1)
        -- line here
        native_invoker.push_arg_string(l1)
        -- optional second line here
        native_invoker.push_arg_int(0)
        native_invoker.push_arg_bool(true)
        native_invoker.push_arg_int(0)
        native_invoker.end_call("701919482C74B5AB")
        util.yield()
    end
end

object_uses = 0
local function mod_uses(type, incr)
    if incr < 0 and is_loading then
        ls_log("Not incrementing use var of type " .. type .. " by " .. incr .. "- script is loading")
        return
    end
    ls_log("Incrementing use var of type " .. type .. " by " .. incr)
    if type == "vehicle" then
        if vehicle_uses <= 0 and incr < 0 then
            return
        end
        vehicle_uses = vehicle_uses + incr
    elseif type == "pickup" then
        if pickup_uses <= 0 and incr < 0 then
            return
        end
        pickup_uses = pickup_uses + incr
    elseif type == "ped" then
        if ped_uses <= 0 and incr < 0 then
            return
        end
        ped_uses = ped_uses + incr
    elseif type == "player" then
        if player_uses <= 0 and incr < 0 then
            return
        end
        player_uses = player_uses + incr
    elseif type == "object" then
        if object_uses <= 0 and incr < 0 then
            return
        end
        object_uses = object_uses + incr
    end
end




--[[ ||| MAIN  ROOTS ||| ]]--

--[[Self Menu]]--
MenuSelf = menu.list(menu.my_root(), "Self", {""}, "Self Options.") ; menu.divider(MenuSelf, "--- Self Options ---")
    --[[Self Menu Subcategories]]--
    MenuMovement = menu.list(MenuSelf, "Movement", {""}, "Movement Options.") ; menu.divider(MenuMovement, "--- Movement Options ---")
        MenuMainMovement = menu.list(MenuMovement, "Movement", {""}, "Main Movement Options.") ; menu.divider(MenuMainMovement, "--- Main Movement Options ---")
        MenuTeleport = menu.list(MenuMovement, "Teleport", {""}, "Teleportation Options.") ; menu.divider(MenuTeleport, "--- Teleport Options ---")
    MenuHealth = menu.list(MenuSelf, "Health", {""}, "Health Options.") ; menu.divider(MenuHealth, "--- Health Options ---")
    MenuWeapon = menu.list(MenuSelf, "Weapon", {""}, "Weapon Options.") ; menu.divider(MenuWeapon, "--- Weapon Options ---")
        MenuWeaponHotswap = menu.list(MenuWeapon, "Hotswap", {""}, "Weapon Hotswap Options.") ; menu.divider(MenuWeaponHotswap, "--- Hotswap Options ---")
        MenuWeaponQR = menu.list(MenuWeapon, "Quick Rocket", {""}, "Quick Rocket Options.") ; menu.divider(MenuWeaponQR, "--- Quick Rocket Options ---")
        MenuWeaponSRANP = menu.list(MenuWeapon, "SRANP", {""}, "Shoot Rocket at Nearest Player Options.") ; menu.divider(MenuWeaponSRANP, "--- SRANP Options ---")
        MenuWeaponGuidedM = menu.list(MenuWeapon, "Missle Guidance", {""}, "Missle Guidance Options.") ; menu.divider(MenuWeaponGuidedM, "--- Missle Guidance Options ---")
            MenuWeaponMA = menu.list(MenuWeaponGuidedM, "Missle Aimbot", {""}, "Missle Aimbot Options.") ; menu.divider(MenuWeaponMA, "--- Missle Aimbot Options ---")
            MenuWeaponMCLOS = menu.list(MenuWeaponGuidedM, "MCLOS", {""}, "MCLOS Guided Missle Options.") ; menu.divider(MenuWeaponMCLOS, "--- MCLOS Options ---")
            MenuWeaponSACLOS = menu.list(MenuWeaponGuidedM, "SACLOS", {""}, "SACLOS Guided Missle Options.") ; menu.divider(MenuWeaponSACLOS, "--- SACLOS Options ---")

--[[Vehicle Menu]]--
MenuVehicle = menu.list(menu.my_root(), "Vehicle", {""}, "Vehicle Options.") ; menu.divider(MenuVehicle, "--- Vehicle Options ---")
    --[[Vehicle Menu Subcategories]]--
    MenuVehicleMain = menu.list(MenuVehicle, "Main", {""}, "Main Vehicle Options.") ; menu.divider(MenuVehicleMain, "--- Main Vehicle Options ---")
        MenuVehMovement = menu.list(MenuVehicleMain, "Movement", {""}, "Vehicle Movement Options.") ; menu.divider(MenuVehMovement, "--- Vehicle Movement Options ---")
        MenuVehVisual = menu.list(MenuVehicleMain, "Visual", {""}, "Vehicle Visual Options.") ; menu.divider(MenuVehVisual, "--- Vehicle Visual Options ---")
            MenuVehVisualMain = menu.list(MenuVehVisual, "Visual", {""}, "Main Vehicle Visual Options.") ; menu.divider(MenuVehVisualMain, "--- Main Vehicle Visual Options ---")
            MenuVisualLights = menu.list(MenuVehVisual, "Vehicle Lights", {""}, "Vehicle Light Options.") ; menu.divider(MenuVisualLights, "--- Vehicle Light Options ---")
        MenuVehHealth = menu.list(MenuVehicleMain, "Health/Armour", {""}, "Vehicle Health/Armour Options.") ; menu.divider(MenuVehHealth, "--- Vehicle Health/Armour Options ---")
        MenuAircraft = menu.list(MenuVehicleMain, "Aircraft", {""}, "Aircraft Options.") ; menu.divider(MenuAircraft, "--- Aircraft Options ---")
            MenuJet = menu.list(MenuAircraft, "Jet", {""}, "Jet Options.") ; menu.divider(MenuJet, "--- Jet Options ---")
            MenuHeli = menu.list(MenuAircraft, "Helicopter", {""}, "Helicopter Options.") ; menu.divider(MenuHeli, "--- Helicopter Options ---")
            MenuAircraftUniversal = menu.list(MenuAircraft, "Universal", {""}, "Universal Aircraft Options.") ; menu.divider(MenuAircraftUniversal, "--- Universal Aircraft Options ---")
        MenuVehPersonal = menu.list(MenuVehicleMain, "Personal", {""}, "Personal Vehicle Options.") ; menu.divider(MenuVehPersonal, "--- Personal Vehicle Options ---")
    MenuVehicleOther = menu.list(MenuVehicle, "Other", {""}, "Other Vehicle Options.") ; menu.divider(MenuVehicleOther, "--- Other Vehicle Options ---")
        MenuVehDoors = menu.list(MenuVehicleOther, "Vehicle Doors", {""}, "Vehicle Door Options.") ; menu.divider(MenuVehDoors, "--- Vehicle Door Options ---")
            MenuVehOpenDoors = menu.list(MenuVehDoors, "Open/Close Doors", {""}, "Vehicle Open/Close Door Options.") ; menu.divider(MenuVehOpenDoors, "--- Vehicle Open/Close Door Options ---")
        MenuVehWindows = menu.list(MenuVehicleOther, "Vehicle Windows", {""}, "Vehicle Window Options.") ; menu.divider(MenuVehWindows, "--- Vehicle Window Options ---")
        MenuVehOtherCounterM = menu.list(MenuVehicleOther, "Countermeasures", {""}, "Vehicle Countermeasure Options.") ; menu.divider(MenuVehOtherCounterM, "--- Vehicle Countermeasure Options ---")
            MenuVehCounterFlare = menu.list(MenuVehOtherCounterM, "Flare", {""}, "Vehicle Flare Countermeasure Options.") ; menu.divider(MenuVehCounterFlare, "--- Vehicle Flare Countermeasure Options ---")
            MenuVehCounterChaff = menu.list(MenuVehOtherCounterM, "Chaff", {""}, "Vehicle Chaff Countermeasure Options.") ; menu.divider(MenuVehCounterChaff, "--- Vehicle Chaff Countermeasure Options ---")
            MenuCMAPS = menu.list(MenuVehOtherCounterM, "TROPHY APS", {""}, "TROPHY APS System Options.") ; menu.divider(MenuCMAPS, "--- Vehicle TROPHY APS Options ---")
        MenuVehOther = menu.list(MenuVehicleOther, "Miscellaneous", {""}, "Miscellaneous Vehicle Options.") ; menu.divider(MenuVehOther, "--- Miscellaneous Vehicle Options ---")

--[[Online Menu]]--
MenuOnline = menu.list(menu.my_root(), "Online", {""}, "Online Options.") ; menu.divider(MenuOnline, "--- Online Options ---")
    --[[Online Menu Subcategories]]--
    MenuOnlineAll = menu.list(MenuOnline, "All Players", {""}, "All Players Options.") ; menu.divider(MenuOnlineAll, "--- All Players Options ---")
    MenuOnlineTK = menu.list(MenuOnline, "Targeted Kick Options", {""}, "Targeted Kick Options.") ; menu.divider(MenuOnlineTK, "--- Targeted Kick Options ---")
    MenuProtection = menu.list(MenuOnline, "Protections", {""}, "Protection Options.") ; menu.divider(MenuProtection, "--- Protection Options ---")

--[[World Menu]]--
MenuWorld = menu.list(menu.my_root(), "World", {""}, "World Options.") ; menu.divider(MenuWorld, "--- World Options ---")
    --[[World Menu Subcategories]]--
    MenuWorldVeh = menu.list(MenuWorld, "Global Vehicle Options", {""}, "Global Vehicle Options.") ; menu.divider(MenuWorldVeh, "--- Global Vehicle Options ---")
    MenuWorldClear = menu.list(MenuWorld, "Clear", {""}, "World Clear Options.") ; menu.divider(MenuWorldClear, "--- World Clear Options ---")
        MenuWorldClearSpec = menu.list(MenuWorldClear, "Specific", {""}, "Specific Clear Options.") ; menu.divider(MenuWorldClearSpec, "--- Specific Clear Options ---")
    MenuWrldProj = menu.list(MenuWorld, "Projectile", {""}, "Projectile Options.") ; menu.divider(MenuWrldProj, " --- World Projectile Options ---")
        MenuWrldProjMarking = menu.list(MenuWrldProj, "Projectile Marking", {""}, "Projectile Marking Options.") ; menu.divider(MenuWrldProjMarking, "--- Projectile Marking Options ---")    
            MenuWrldProjOptions = menu.list(MenuWrldProjMarking, "Mark Projectiles", {""}, "Mark Projectile Options.") ; menu.divider(MenuWrldProjOptions, "--- Mark Projectile Options ---")
            MenuWrldProjColours = menu.list(MenuWrldProjMarking, "Mark Projectile Colours", {""}, "Mark Projectile Colour Options.") ; menu.divider(MenuWrldProjColours, "--- Mark Projectile Colour Options ---")
        MenuWrldProjMovement = menu.list(MenuWrldProj, "Projectile Movement", {""}, "Projectile Movement Options.") ; menu.divider(MenuWrldProjMovement, "--- Projectile Movement Options ---")

--[[Game Menu]]--
MenuGame = menu.list(menu.my_root(), "Game", {""}, "Game Options.") ; menu.divider(MenuGame, "--- Game Options ---")
    --[[Game Menu Subcategories]]
    MenuAlerts = menu.list(MenuGame, "Fake Alerts", {""}, "Fake Alert Options.") ; menu.divider(MenuAlerts, "--- Fake Alert Options ---")
    MenuGameMacros = menu.list(MenuGame, "Macro Options", {""}, "Similar to AHK Macros, just Running in the Game so there's Never any Input Lag.") ; menu.divider(MenuGameMacros, "--- Macro Options ---")
        MenuGameRunMacros = menu.list(MenuGameMacros, "Macros", {""}, "Different Types of Macros to Choose from. Highly Reccomended to Bind them.") ; menu.divider(MenuGameRunMacros, "--- Macros ---") 
            MenuGameRunMacrosReg = menu.list(MenuGameRunMacros, "Registration", {"csgamemacrosmacroreg"}, "Macros that have to do with Registering as CEO/MC President.") ; menu.divider(MenuGameRunMacrosReg, "--- Registration Macros ---")                        
            MenuGameRunMacrosSur = menu.list(MenuGameRunMacros, "Survivability", {"csgamemacrosmacrosur"}, "Macros that have to do with Health, like Armour and BST.") ; menu.divider(MenuGameRunMacrosSur, "--- Survivability Macros ---")                        
            MenuGameRunMacrosAbi = menu.list(MenuGameRunMacros, "Ability", {"csgamemacrosmacroabi"}, "Macros that have to do with CEO Abilities, like Ghost Organization.") ; menu.divider(MenuGameRunMacrosAbi, "--- Ability Macros ---")                        
            MenuGameRunMacrosVeh = menu.list(MenuGameRunMacros, "Vehicle", {"csgamemacrosmacroveh"}, "Macros that have to do with Calling Vehicles, like the CEO Buzzard.") ; menu.divider(MenuGameRunMacrosVeh, "--- Vehicle Macros ---")                        
            MenuGameRunMacrosPhone = menu.list(MenuGameRunMacros, "Phone", {"csgamemacrosmacrophone"}, "Macros that have to do with Quickly getting to Contacts in your Phone. These Automatically Start after you Close Stand if you've Clicked one, since the Phone Can't Open when Stand is Open.") ; menu.divider(MenuGameRunMacrosPhone, "--- Phone Macros ---")                        
            MenuGameRunMacrosServ = menu.list(MenuGameRunMacros, "Service", {"csgamemacrosmacroservice"}, "Macros that have to do with Calling Service Vehicles.") ; menu.divider(MenuGameRunMacrosServ, "--- Service Macros ---")      
            MenuGameRunMacrosMisc = menu.list(MenuGameRunMacros, "Other", {"csgamemacrosmacroother"}, "Macros that have to do with Miscellaneous things, like Activating Thermal Visor.") ; menu.divider(MenuGameRunMacrosMisc, "--- Other Macros ---") 
        
--[[Menu Chalkscript]]--
MenuMisc = menu.list(menu.my_root(), "Chalkscript", {""}, "Chalkscript Options.") ; menu.divider(MenuMisc, "--- Credits ---")
    --[[Menu Chalkscript Subcategories]]--
    MenuCredits = menu.list(MenuMisc, "Credits", {""}, "Credits for the Developers of Chalkscript.")




--[[ ||| THREADS ||| ]]--

rgb_thread = util.create_thread(function(thr)
    local r = 255
    local g = 0
    local b = 0
    rgb = {255, 0, 0}
    while true do  
        --Smooth RGB--
        if r > 0 and g < 255 and b == 0 then
            r = r - 1
            g = g + 1
        elseif r == 0 and g > 0 and b < 255 then
            g = g - 1
            b = b + 1
        elseif r < 255 and b > 0 then
            r = r + 1
            b = b - 1
        end
        randR = r
        randG = g
        randB = b

        --True RGB--
        tr, tg, tb = 0, 0, 0
        local timeToWait = 500 
        tr, tg, tb = 255, 0, 0 -- Red
        util.yield(timeToWait)
        tr, tg, tb = 255, 100, 20 -- Orange
        util.yield(timeToWait)
        tr, tg, tb = 255, 255, 0 -- Yellow
        util.yield(timeToWait)
        tr, tg, tb = 0, 255, 0 -- Green
        util.yield(timeToWait)
        tr, tg, tb = 0, 0, 255 -- Blue
        util.yield(timeToWait)
        tr, tg, tb = 70, 20, 255 -- Indigo / Purple
        util.yield(timeToWait)
        tr, tg, tb = 255, 0, 255 -- Violet / Pink
        util.yield(timeToWait)
        util.yield()
    end
end)

objects_thread = util.create_thread(function (thr)
    local projectile_blips = {}
    while true do
        for k,b in pairs(projectile_blips) do
            if HUD.GET_BLIP_INFO_ID_ENTITY_INDEX(b) == 0 then 
                util.remove_blip(b) 
                projectile_blips[k] = nil
            end
        end
        if object_uses > 0 then
            if show_updates then
                ls_log("-Chalkscript-\n\nObject Pool is being Updated")
            end
            all_objects = entities.get_all_objects_as_handles()
            for k,obj in pairs(all_objects) do
                if is_entity_a_projectile_all(ENTITY.GET_ENTITY_MODEL(obj)) then  --Edit Proj Offsets Here
                    if projectile_spaz then 
                        local strength = 20
                        ENTITY.APPLY_FORCE_TO_ENTITY(obj, 1, math.random(-strength, strength), math.random(-strength, strength), math.random(-strength, strength), 0.0, 0.0, 0.0, 1, true, false, true, true, true)
                    end
                    if slow_projectiles then
                        ENTITY.SET_ENTITY_MAX_SPEED(obj, 0.5)
                    end
                    if vehicle_APS then
                        local gce_all_objects = entities.get_all_objects_as_handles()
                        local Range = CountermeasureAPSrange
                        local RangeSq = Range * Range
                        local EntitiesToTarget = {}
                        for index, entity in pairs(gce_all_objects) do
                            if is_entity_a_missle(ENTITY.GET_ENTITY_MODEL(entity)) or is_entity_a_grenade(ENTITY.GET_ENTITY_MODEL(entity)) then
                                local EntityCoords = ENTITY.GET_ENTITY_COORDS(entity)
                                local LocalCoords = ENTITY.GET_ENTITY_COORDS(players.user_ped())
                                local VehCoords = ENTITY.GET_ENTITY_COORDS(player_cur_car)
                                local ObjPointers = entities.get_all_objects_as_pointers()
                                local vdist = SYSTEM.VDIST2(VehCoords.x, VehCoords.y, VehCoords.z, EntityCoords.x, EntityCoords.y, EntityCoords.z)
                                if vdist <= RangeSq then
                                    EntitiesToTarget[#EntitiesToTarget+1] = entities.pointer_to_handle(ObjPointers[index])
                                end
                                if EntitiesToTarget ~= nil then
                                    local dist = 999999
                                    for i = 1, #EntitiesToTarget do
                                        local tarcoords = ENTITY.GET_ENTITY_COORDS(EntitiesToTarget[index])
                                        local e = SYSTEM.VDIST2(VehCoords.x, VehCoords.y, VehCoords.z, EntityCoords.x, EntityCoords.y, EntityCoords.z)
                                        if e < dist then
                                            dist = e
                                            closest_entity = EntitiesToTarget[index]
                                            local closestEntity = entity
                                            local closestDist = distance
                                            local ProjLocation = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(closestEntity, 0, 0, 0)
                                            local ProjRotation = ENTITY.GET_ENTITY_ROTATION(closestEntity)
                                            local lookAtProj = v3.lookAt(VehCoords, EntityCoords)
                                            STREAMING.REQUEST_NAMED_PTFX_ASSET("scr_sm_counter")
                                            STREAMING.REQUEST_NAMED_PTFX_ASSET("core") 
                                            STREAMING.REQUEST_NAMED_PTFX_ASSET("weap_gr_vehicle_weapons")
                                            if STREAMING.HAS_NAMED_PTFX_ASSET_LOADED("scr_sm_counter") and STREAMING.HAS_NAMED_PTFX_ASSET_LOADED("core") and STREAMING.HAS_NAMED_PTFX_ASSET_LOADED("veh_xs_vehicle_mods") then
                                                ENTITY.SET_ENTITY_ROTATION(entity, lookAtProj.x - 180, lookAtProj.y, lookAtProj.z, 1, true)
                                                lookAtPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, 0, Range - 2, 0)
                                                GRAPHICS.USE_PARTICLE_FX_ASSET("scr_sm_counter")
                                                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("scr_sm_counter_chaff", ProjLocation.x, ProjLocation.y, ProjLocation.z, ProjRotation.x + 90, ProjRotation.y, ProjRotation.z, 1, 0, 0, 0)
                                                GRAPHICS.USE_PARTICLE_FX_ASSET("core")
                                                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("exp_grd_sticky", ProjLocation.x, ProjLocation.y, ProjLocation.z, ProjRotation.x - 90, ProjRotation.y, ProjRotation.z, 0.2, 0, 0, 0)
                                                GRAPHICS.USE_PARTICLE_FX_ASSET("weap_gr_vehicle_weapons")
                                                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("muz_mounted_turret_apc_missile", lookAtPos.x, lookAtPos.y, lookAtPos.z + .2, lookAtProj.x + 180, lookAtProj.y, lookAtProj.z, 1.3, 0, 0, 0)
                                                GRAPHICS.USE_PARTICLE_FX_ASSET("weap_gr_vehicle_weapons")
                                                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("muz_mounted_turret_apc", lookAtPos.x, lookAtPos.y, lookAtPos.z + .2, lookAtProj.x + 180, lookAtProj.y, lookAtProj.z, 1.3, 0, 0, 0)
                                                GRAPHICS.USE_PARTICLE_FX_ASSET("weap_gr_vehicle_weapons")
                                                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("muz_mounted_turret_apc_missile", lookAtPos.x, lookAtPos.y, lookAtPos.z + .2, lookAtProj.x + 180, lookAtProj.y, lookAtProj.z, 1.3, 0, 0, 0)
                                                GRAPHICS.USE_PARTICLE_FX_ASSET("weap_gr_vehicle_weapons")
                                                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("muz_mounted_turret_apc", lookAtPos.x, lookAtPos.y, lookAtPos.z + .2, lookAtProj.x + 180, lookAtProj.y, lookAtProj.z, 1.3, 0, 0, 0)
                                                entities.delete_by_handle(entity)
                                                APS_charges = APS_charges - 1
                                                util.toast("-Chalkscript-\n\nAPS Destroyed Incoming Projectile.\n"..APS_charges.."/"..CountermeasureAPSCharges.."  APS Shells Left.")
                                                if APS_charges == 0 then
                                                    util.toast("-Chalkscript-\n\nNo APS Shells Left. Reloading...")
                                                    util.yield(CountermeasureAPSTimeout)
                                                    APS_charges = CountermeasureAPSCharges
                                                    util.toast("-Chalkscript-\n\nAPS Ready.")
                                                end
                                            else
                                                for i = 0, 10, 1 do
                                                    STREAMING.REQUEST_NAMED_PTFX_ASSET("scr_sm_counter")
                                                    STREAMING.REQUEST_NAMED_PTFX_ASSET("core") 
                                                    STREAMING.REQUEST_NAMED_PTFX_ASSET("veh_xs_vehicle_mods")
                                                end
                                                if not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED("scr_sm_counter") or STREAMING.HAS_NAMED_PTFX_ASSET_LOADED("core") or STREAMING.HAS_NAMED_PTFX_ASSET_LOADED("veh_xs_vehicle_mods") then
                                                    util.toast("-Chalkscript-\n\nCould not Load Particle Effect.")
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if homing_missles then
                        local localped = players.user_ped()
                        local localcoords = ENTITY.GET_ENTITY_COORDS(players.user_ped())
                        local forOffset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(localped, 0, 5, 0)
                        RRocket = OBJECT.GET_CLOSEST_OBJECT_OF_TYPE(forOffset.x, forOffset.y, forOffset.z, 10, HomingM_SelectedMissle, false, true, true, true)
                        local p
                        p = GetClosestPlayerWithRange_Whitelist(homing_missle_range, false)
                        local ppcoords = ENTITY.GET_ENTITY_COORDS(p)
                        util.create_thread(function ()
                            local plocalized = p
                            local msl = RRocket
                            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(msl)
                            if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(msl) then
                                for i = 1, 10 do
                                    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(msl)
                                end
                            end
                            if not PED.IS_PED_DEAD_OR_DYING(plocalized) then
                                while ENTITY.DOES_ENTITY_EXIST(msl) do
                                    local pcoords2 = ENTITY.GET_ENTITY_COORDS(plocalized)
                                    local pcoords = GetTableFromV3Instance(pcoords2)
                                    local lc2 = ENTITY.GET_ENTITY_COORDS(msl)
                                    local lc = GetTableFromV3Instance(lc2)
                                    local look2 = v3.lookAt(lc2, pcoords2)
                                    local look = GetTableFromV3Instance(look2)
                                    local dir2 = v3.toDir(look2)
                                    local dir = GetTableFromV3Instance(dir2) 
                                    if ENTITY.DOES_ENTITY_EXIST(msl) then
                                        if (ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY(msl, plocalized, 17)) then
                                            ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(msl, 1, 0, 1, 0, true, true, false, true)
                                            ENTITY.SET_ENTITY_ROTATION(msl, look.x, look.y, look.z, 2, true)
                                        end
                                    end
                                    util.yield()
                                end  
                            end   
                        end)
                    end
                    if missle_MCLOS then
                        local localped = players.user_ped()
                        local localcoords = ENTITY.GET_ENTITY_COORDS(players.user_ped())
                        local forOffset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(localped, 0, 5, 0)
                        RRocket = OBJECT.GET_CLOSEST_OBJECT_OF_TYPE(forOffset.x, forOffset.y, forOffset.z, 10, MCLOS_SelectedMissle, false, true, true, true)
                        local mclos_msl_rot = ENTITY.GET_ENTITY_ROTATION(RRocket)
                        local mclos_look_r = mclos_msl_rot.x
                        local mclos_look_p = mclos_msl_rot.y
                        local mclos_look_y = mclos_msl_rot.z
                        util.create_thread(function ()
                            local msl = RRocket
                            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(msl)
                            if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(msl) then
                                for i = 1, 10 do
                                    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(msl)
                                end
                            end     
                            while ENTITY.DOES_ENTITY_EXIST(msl) do       
                                if ENTITY.GET_ENTITY_SPEED(msl) == 0 then
                                    local mclos_msl_rot = ENTITY.GET_ENTITY_ROTATION(RRocket)
                                    mclos_look_p = mclos_msl_rot.x
                                    mclos_look_r = mclos_msl_rot.y
                                    mclos_look_y = mclos_msl_rot.z
                                end  
                                if ENTITY.DOES_ENTITY_EXIST(msl) then
                                    if not MCLOS_mouseControl then
                                        if PAD.IS_CONTROL_PRESSED(MCLOS_controlModeU, MCLOS_controlModeU) then --Nmp 8
                                            mclos_look_p = mclos_look_p + MCLOS_TurnSpeed
                                            ENTITY.SET_ENTITY_ROTATION(msl, mclos_look_p, 0, mclos_look_y, 1, true)
                                        end
                                        if PAD.IS_CONTROL_PRESSED(MCLOS_controlModeD, MCLOS_controlModeD) then --Nmp 5
                                            mclos_look_p = mclos_look_p - MCLOS_TurnSpeed
                                            ENTITY.SET_ENTITY_ROTATION(msl, mclos_look_p, 0, mclos_look_y, 1, true)
                                        end
                                        if PAD.IS_CONTROL_PRESSED(MCLOS_controlModeL, MCLOS_controlModeL) then --Nmp 4
                                            mclos_look_y = mclos_look_y + MCLOS_TurnSpeed
                                            ENTITY.SET_ENTITY_ROTATION(msl, mclos_look_p, 0, mclos_look_y, 1, true)
                                        end
                                        if PAD.IS_CONTROL_PRESSED(MCLOS_controlModeR, MCLOS_controlModeR) then --Nmp 6
                                            mclos_look_y = mclos_look_y - MCLOS_TurnSpeed
                                            ENTITY.SET_ENTITY_ROTATION(msl, mclos_look_p, 0, mclos_look_y, 1, true)
                                        end
                                        ENTITY.SET_ENTITY_ROTATION(msl, mclos_look_p, 0, mclos_look_y, 1, true)
                                        ENTITY.APPLY_FORCE_TO_ENTITY(msl, 1, 0, 1, 0, 0, 0, 0, 1, true, false, false, true, true)
                                        ENTITY.SET_ENTITY_MAX_SPEED(msl, MCLOS_MaxSpeed)
                                        --ENTITY.APPLY_FORCE_TO_ENTITY(msl, 1, 0, 1, 0, true, true, false, true)
                                    else
                                        local MCOLS_mouseHorizontal = PAD.GET_CONTROL_NORMAL(1, 1)
                                        local MCOLS_mouseVertical = PAD.GET_CONTROL_NORMAL(2, 2)
                                        if MCOLS_mouseVertical < 0 then -- Mouse Up
                                            mclos_look_p = mclos_look_p + (MCLOS_TurnSpeed / 4)
                                            ENTITY.SET_ENTITY_ROTATION(msl, mclos_look_p, 0, mclos_look_y, 1, true)
                                        end
                                        if MCOLS_mouseVertical > 0 then --Mouse Down
                                            mclos_look_p = mclos_look_p - (MCLOS_TurnSpeed / 4)
                                            ENTITY.SET_ENTITY_ROTATION(msl, mclos_look_p, 0, mclos_look_y, 1, true)
                                        end
                                        if MCOLS_mouseHorizontal < 0 then -- Mouse Left
                                            mclos_look_y = mclos_look_y + (MCLOS_TurnSpeed / 4)
                                            ENTITY.SET_ENTITY_ROTATION(msl, mclos_look_p, 0, mclos_look_y, 1, true)
                                        end
                                        if MCOLS_mouseHorizontal > 0 then -- Mouse Right
                                            mclos_look_y = mclos_look_y - (MCLOS_TurnSpeed / 4)
                                            ENTITY.SET_ENTITY_ROTATION(msl, mclos_look_p, 0, mclos_look_y, 1, true)
                                        end
                                    end
                                end
                                util.yield()
                            end 
                        end)
                    end 
                    if missle_SACLOS then                                                       
                        local localped = players.user_ped()
                        local localcoords = ENTITY.GET_ENTITY_COORDS(players.user_ped())
                        local forOffset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(localped, 0, 5, 0)
                        RRocket = OBJECT.GET_CLOSEST_OBJECT_OF_TYPE(forOffset.x, forOffset.y, forOffset.z, 10, SACLOS_SelectedMissle, false, true, true)
                        util.create_thread(function ()
                            local msl = RRocket
                            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(msl)
                            if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(msl) then
                                for i = 1, 10 do
                                    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(msl)
                                end
                            end     
                            while ENTITY.DOES_ENTITY_EXIST(msl) do       
                                local rc = raycast_gameplay_cam(-1, 1000000.0)[2]
                                local lc2 = ENTITY.GET_ENTITY_COORDS(msl)
                                local lc = GetTableFromV3Instance(lc2)
                                local look2 = v3.lookAt(lc2, rc)
                                local look = GetTableFromV3Instance(look2)
                                if ENTITY.GET_ENTITY_SPEED(msl) == 0 then
                                    goto CONTINUE
                                end
                                if SACLOS_drawLaser then
                                    local LaserStartCoords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 0, 0, 0)
                                    GRAPHICS.DRAW_LINE(LaserStartCoords.x, LaserStartCoords.y, LaserStartCoords.z, rc.x, rc.y, rc.z, 0, 50, 255, 150)
                                    util.yield()
                                end
                                if ENTITY.DOES_ENTITY_EXIST(msl) then
                                    ENTITY.SET_ENTITY_ROTATION(msl, look.x, look.y, look.z, 1, true)
                                    ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(msl, 1, 0, 1, 0, true, true, false, true)
                                    ENTITY.SET_ENTITY_MAX_SPEED(msl, SACLOS_MaxSpeed)
                                end
                                ::CONTINUE::
                                util.yield()
                            end 
                        end)
                    end
                end
                if is_entity_a_missle(ENTITY.GET_ENTITY_MODEL(obj)) then --Mark Missles
                    if blip_projectiles then
                        if blip_proj_missles then   
                            if HUD.GET_BLIP_FROM_ENTITY(obj) == 0 then
                                local proj_blip_missle = HUD.ADD_BLIP_FOR_ENTITY(obj)
                                HUD.SET_BLIP_SPRITE(proj_blip_missle, 548) --Missle Icon ID
                                HUD.SET_BLIP_COLOUR(proj_blip_missle, proj_blip_missle_col)
                                projectile_blips[#projectile_blips + 1] = proj_blip_missle
                            end
                        end
                    end
                end
                if is_entity_a_bomb(ENTITY.GET_ENTITY_MODEL(obj)) then --Mark Bombs
                    if blip_projectiles then
                        if blip_proj_bombs then    
                            if HUD.GET_BLIP_FROM_ENTITY(obj) == 0 then
                                local proj_blip_bomb = HUD.ADD_BLIP_FOR_ENTITY(obj)
                                HUD.SET_BLIP_SPRITE(proj_blip_bomb, 368) --Bomb Icon ID
                                HUD.SET_BLIP_COLOUR(proj_blip_bomb, proj_blip_bomb_col)                                  
                                projectile_blips[#projectile_blips + 1] = proj_blip_bomb
                            end
                        end
                    end
                end
                if is_entity_a_grenade(ENTITY.GET_ENTITY_MODEL(obj)) then --Mark Grenades
                    if blip_projectiles then
                        if blip_proj_grenades then
                            if HUD.GET_BLIP_FROM_ENTITY(obj) == 0 then
                                local proj_blip_grenade = HUD.ADD_BLIP_FOR_ENTITY(obj)
                                HUD.SET_BLIP_SPRITE(proj_blip_grenade, 486) --Grenade Icon ID
                                HUD.SET_BLIP_COLOUR(proj_blip_grenade, proj_blip_grenade_col)
                                projectile_blips[#projectile_blips + 1] = proj_blip_grenade
                            end
                        end
                    end
                end
                if is_entity_a_mine(ENTITY.GET_ENTITY_MODEL(obj)) then --Mark Mines
                    if blip_projectiles then
                        if blip_proj_mines then    
                            if HUD.GET_BLIP_FROM_ENTITY(obj) == 0 then
                                local proj_blip_mine = HUD.ADD_BLIP_FOR_ENTITY(obj)
                                HUD.SET_BLIP_SPRITE(proj_blip_mine, 653) --Mine Icon ID
                                HUD.SET_BLIP_COLOUR(proj_blip_mine, proj_blip_mine_col)
                                projectile_blips[#projectile_blips + 1] = proj_blip_mine 
                            end
                        end
                    end
                end
                if is_entity_a_miscprojectile(ENTITY.GET_ENTITY_MODEL(obj)) then --Mark Misc Projectiles
                    if blip_projectiles then
                        if blip_proj_misc then
                            if HUD.GET_BLIP_FROM_ENTITY(obj) == 0 then
                                local proj_blip_misc = HUD.ADD_BLIP_FOR_ENTITY(obj)
                                HUD.SET_BLIP_SPRITE(proj_blip_misc, 364) --Misc Projectile Icon ID
                                HUD.SET_BLIP_COLOUR(proj_blip_misc, proj_blip_misc_col)
                                projectile_blips[#projectile_blips + 1] = proj_blip_misc 
                            end
                        end
                    end
                end
                if l_e_o_on then
                    local size = get_model_size(ENTITY.GET_ENTITY_MODEL(obj))
                    if size.x > l_e_max_x or size.y > l_e_max_y or size.z > l_e_max_y then
                        entities.delete_by_handle(obj)
                    end
                end
                if object_rainbow then
                    OBJECT._SET_OBJECT_LIGHT_COLOR(obj, 1, rgb[1], rgb[2], rgb[3])
                end
            end
        end
        util.yield()
    end
end)




--[[ ||| ALL ACTIONS ||| ]]--

--[[| Self/Movement/Main/ |]]--
menu.slider(MenuMainMovement, "Player Speed", {"csplayerspeed"}, "Sets your Walk, Run and Swim Speed Via a Multiplier.", -1000, 1000, 1, 1, function(value)
    local MultipliedValue = value * 100
    menu.set_value(menu.ref_by_path("Self>Movement>Swim Speed", 38), MultipliedValue)
    menu.set_value(menu.ref_by_path("Self>Movement>Walk And Run Speed", 38), MultipliedValue)
end)

menu.toggle(MenuMainMovement, "Super Jump", {"cssuperjump"}, "Makes you Jump very High. Detected by Most Menus.", function(on)
    menu.trigger_command(menu.ref_by_command_name("superjump"))
end)


--[[| Self/Movement/Teleport/ |]]--
tpf_units = 0.5
menu.action(MenuTeleport, "TP Forward", {"cstpforward"}, "Teleports you Forward the Selected Amount of Units. Goot for Going through Thin Objects like Walls or Doors.", function(on_click)
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.PLAYER_PED_ID(), 0, tpf_units, 0)
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PLAYER.PLAYER_PED_ID(), pos['x'], pos['y'], pos['z'], true, false, false)
end)

menu.slider(MenuTeleport, "TP Forward Units", {"cstpforwardunits"}, "Number of Units to Teleport when using 'TP Forward' Command.", 5, 100, 1, 1, function(s)
    tpf_units = s*0.1
end)

menu.action(MenuTeleport, "Teleport to Waypoint", {"cstpwaypoint"}, "Teleports you to the Waypoint you have set.", function(on_click)
    menu.trigger_command(menu.ref_by_command_name("tpwp"))
end)

menu.action(MenuTeleport, "Smooth Teleport", {"csstpwaypoint"}, "'Teleport to Waypoint' but with a Smooth Camera Transtiton in Between.", function ()
    SmoothTeleportToCord(Get_Waypoint_Pos2(), false)
end)
menu.slider(MenuTeleport, "Smooth Teleport Speed", {"csstpspeed"}, "Speed of the Camera Transition when Using Smooth Teleport.", 1, 100, 10, 1, function(value)
    local multiply = value / 10
    STP_SPEED_MODIFIER = 0.02
    STP_SPEED_MODIFIER = STP_SPEED_MODIFIER * multiply
end)
menu.slider(MenuTeleport, "Smooth Teleport Height", {"csstpheight"}, "Height of the Camera During the Transition.", 0, 10000, 300, 10, function (value)
    local height = value
    STP_COORD_HEIGHT = height
end)


--[[| Self/Health/ |]]--
menu.action(MenuHealth, "Full Health", {"csfullhealth"}, "Completely Refills your Health.", function()
	local maxHealth = PED.GET_PED_MAX_HEALTH(players.user_ped())
	ENTITY.SET_ENTITY_HEALTH(players.user_ped(), maxHealth, 0)
end)

menu.action(MenuHealth, "Full Armour", {"csfullarmour"}, "Completely Refills your Armour.", function()
	local armour = util.is_session_started() and 50 or 100
	PED.SET_PED_ARMOUR(players.user_ped(), armour)
end)


--[[| Self/Weapon/Hotswap/ |]]--
LegitRapidFire = false
LegitRapidMS = 100
menu.toggle(MenuWeaponHotswap, "Hotswap", {"cshotswap"}, "Quickly Switches to your C4 and Back to Shoot Certain Weapons Faster.\nMake sure to have C4/Sticky Bomb in your Inventory or this won't Work!", function(on)
    local localped = players.user_ped()
    if on then
        LegitRapidFire = true
        util.create_thread(function ()
            while LegitRapidFire do
                if PED.IS_PED_SHOOTING(localped) then
                    local curWepMem = memory.alloc()
                    WEAPON.GET_CURRENT_PED_WEAPON(localped, curWepMem, 1)
                    local currentWeapon = memory.read_int(curWepMem)
                    memory.free(curWepMem)
                    WEAPON.SET_CURRENT_PED_WEAPON(localped, 741814745, LegitSwitchA1) --741814745 is C4
                    util.yield(LegitRapidMS)
                    WEAPON.SET_CURRENT_PED_WEAPON(localped, currentWeapon, LegitSwitchA2)
                end
                util.yield()
            end
            util.stop_thread()
        end)
    else
        LegitRapidFire = false
    end
end)

menu.slider(MenuWeaponHotswap, "Hotswap Mode", {"cshotswapmode"}, "Wether to Skip the Weapon Switch Animation or to Play Through it.\\n\n1 - Non-Legit; Skip Both Animations\n2 - Semi-Legit; Skip One Animation\n3 - Full-Legit; Don't Skip any Animations", 1, 3, 1, 1, function(value)
    if value == 1 then LegitSwitchA1 = true ; LegitSwitchA2 = true
    elseif value == 2 then LegitSwitchA1 = false ; LegitSwitchA2 = true
    elseif value == 3 then LegitSwitchA1 = false ; LegitSwitchA2 = false end 
end)

menu.slider(MenuWeaponHotswap, "Hotswap Delay", {"cshotswapdelay"}, "The Delay Between Switching to C4 and Back.\nValues Under 200 won't Work if using Legit Mode, Due to being Too Fast!", 1, 1000, 100, 50, function(value)
    LegitRapidMS = value
end)


--[[| Self/Weapon/Quickrocket/ |]]--
menu.action(MenuWeaponQR, "Quick Rocket", {"csquickrocket"}, "This will Switch to the Homing Launcher, Wait until you Shoot, then Switch back.", function(on_click)
    local localped = players.user_ped()
    if on_click then
        util.create_thread(function ()
            local currentWpMem = memory.alloc()
            local junk = WEAPON.GET_CURRENT_PED_WEAPON(localped, currentWpMem, 1)
            local currentWP = memory.read_int(currentWpMem)
            memory.free(currentWpMem)
            WEAPON.SET_CURRENT_PED_WEAPON(localped, 1672152130, false) --1672152130 is Homing Launcher
            local WaitForShoot = true
            while WaitForShoot do
                if PED.IS_PED_SHOOTING(localped) then
                    WEAPON.SET_CURRENT_PED_WEAPON(localped, 741814745, LegitSwitchB1)
                    util.yield(200)
                    WEAPON.SET_CURRENT_PED_WEAPON(localped, currentWP,LegitSwitchB2)
                    WaitForShoot = false
                end
                util.yield()
            end
            util.stop_thread()
        end)
    end
end)

menu.slider(MenuWeaponQR, "Quick Rocket Mode", {"csquickrocketmode"}, "Wether to Skip the Weapon Switch Animation or to Play Through it.\\n\n1 - Non-Legit; Skib Both Animations\n2 - Semi-Legit; Skip One Animation\n3 - Full-Legit; Don't Skip any Animations", 1, 3, 1, 1, function(value)
    if value == 1 then LegitSwitchB1 = true ; LegitSwitchB2 = true
    elseif value == 2 then LegitSwitchB1 = false ; LegitSwitchB2 = true
    elseif value == 3 then LegitSwitchB1 = false ; LegitSwitchB2 = false end 
end)


--[[| Self/Weapon/SRANP/ |]]--
menu.action(MenuWeaponSRANP, "Shoot Rocket at Nearest Player", {"cssranp"}, "Spawns a Rocket near you that goes to the Nearest Player.\nLess Legit Alternative to 'Shoot Rocket'.", function(on_click)
    local UserPedOffset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 0, -1, .35)   
    local NearestPlayer = GetClosestPlayerWithRange(SRANP_Range)
    local TargetLead = 1.6 * ENTITY.GET_ENTITY_SPEED(NearestPlayer)  
    local NearestplayerCoord = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(NearestPlayer, 0, 0, 0)
    local NearestPlayerLeadCoord = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(NearestPlayer, 0, TargetLead, 0)
    if NearestPlayer ~= players.user_ped() then
        if ENTITY.GET_ENTITY_SPEED(NearestPlayer) > 1 then
            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(UserPedOffset['x'], UserPedOffset['y'], UserPedOffset['z'], NearestPlayerLeadCoord['x'], NearestPlayerLeadCoord['y'], NearestPlayerLeadCoord['z'], 100, true, 1672152130, players.user_ped(), true, false, 1000)
        else
            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(UserPedOffset['x'], UserPedOffset['y'], UserPedOffset['z'], NearestPlayerLeadCoord['x'], NearestPlayerLeadCoord['y'], NearestPlayerLeadCoord['z'], 100, true, 1672152130, players.user_ped(), true, false, 1000)
        end
    else
        util.toast("-Chalkscript-\n\nCould not find Nearest Target within the given Range.")
    end
end)

SRANP_Range = 500
menu.slider(MenuWeaponSRANP, "SRANP Range", {"cssranprange"}, "The Range at which 'SRANP' will Detect Players, and choose the Closest one out of them.", 50, 5000, 500, 10, function(value)
    SRANP_Range = value
end)


--[[| Self/Weapon/MissleGuidance/MA/ |]]--
homing_missles = false
menu.toggle(MenuWeaponMA, "Missle Aimbot", {"csmissleaimbot"}, "Rotates any Missle or Bomb Towards the Nearest player in the set Range. Aims a little Ahead, in Attempt to cut the Target off.", function(on)
    homing_missles = on
    mod_uses("object", if on then 1 else -1)
end)

HomingM_SelectedMissle = util.joaat("w_lr_homing_rocket")
menu.slider(MenuWeaponMA, "Missle Aimbot Selected Missle", {"csmissleaimbotmissle"}, "The Missle that will be used for 'Missle Aimbot'.\n\n1 - RPG\n2 - Homing Launcher\n3 - Oppressor Missle\n4 - B-11 Barrage\n5 - B-11 Homing\n6 - Chernobog Missle\n7 - Explosive Bomb\n8 - Incendiary Bomb\n9 - Gas Bomb\n10 - Cluster Bomb", 1, 10, 2, 1, function(value)
    if value == 1 then HomingM_SelectedMissle = util.joaat("w_lr_rpg_rocket")
    elseif value == 2 then HomingM_SelectedMissle = util.joaat("w_lr_homing_rocket")
    elseif value == 3 then HomingM_SelectedMissle = util.joaat("w_ex_vehiclemissile_3")
    elseif value == 4 then HomingM_SelectedMissle = util.joaat("w_smug_airmissile_01b")
    elseif value == 5 then HomingM_SelectedMissle = util.joaat("w_battle_airmissile_01")
    elseif value == 6 then HomingM_SelectedMissle = util.joaat("w_ex_vehiclemissile_4")
    elseif value == 7 then HomingM_SelectedMissle = util.joaat("w_smug_bomb_01")
    elseif value == 8 then HomingM_SelectedMissle = util.joaat("w_smug_bomb_02")
    elseif value == 9 then HomingM_SelectedMissle = util.joaat("w_smug_bomb_03")
    elseif value == 10 then HomingM_SelectedMissle = util.joaat("w_smug_bomb_04") end
end)

homing_missle_range = 1000
menu.slider(MenuWeaponMA, "Missle Aimbot Range", {"csmissleaimbotrange"}, "Range at which the Missle you Shoot will Track.", 50, 35000, 1000, 50, function(value)
    homing_missle_range = value
    homing_missle_range_org = value
end)


--[[| Self/Weapon/MissleGuidance/MCLOS/ |]]--
missle_MCLOS = false
menu.toggle(MenuWeaponMCLOS, "MCLOS", {"csmclos"}, "MCLOS is Manual Missle Guidance. Use the Numpad 4, 5, 6, 8 to Control any Missle you Fire Manually.", function(on)
    missle_MCLOS = on
    mod_uses("object", if on then 1 else -1)
end)

MCLOS_SelectedMissle = util.joaat("w_lr_homing_rocket")
menu.slider(MenuWeaponMCLOS, "MCLOS Selected Missle", {"csmclosmissle"}, "The Missle that will be used for MCLOS Guidance.\n\n1 - RPG\n2 - Homing Launcher\n3 - Oppressor Missle\n4 - B-11 Barrage\n5 - B-11 Homing\n6 - Chernobog Missle\n7 - Explosive Bomb\n8 - Incendiary Bomb\n9 - Gas Bomb\n10 - Cluster Bomb", 1, 10, 2, 1, function(value)
    if value == 1 then MCLOS_SelectedMissle = util.joaat("w_lr_rpg_rocket")
    elseif value == 2 then MCLOS_SelectedMissle = util.joaat("w_lr_homing_rocket")
    elseif value == 3 then MCLOS_SelectedMissle = util.joaat("w_ex_vehiclemissile_3")
    elseif value == 4 then MCLOS_SelectedMissle = util.joaat("w_smug_airmissile_01b")
    elseif value == 5 then MCLOS_SelectedMissle = util.joaat("w_battle_airmissile_01")
    elseif value == 6 then MCLOS_SelectedMissle = util.joaat("w_ex_vehiclemissile_4")
    elseif value == 7 then MCLOS_SelectedMissle = util.joaat("w_smug_bomb_01")
    elseif value == 8 then MCLOS_SelectedMissle = util.joaat("w_smug_bomb_02")
    elseif value == 9 then MCLOS_SelectedMissle = util.joaat("w_smug_bomb_03")
    elseif value == 10 then MCLOS_SelectedMissle = util.joaat("w_smug_bomb_04") end
end)

MCLOS_controlModeU = 111
MCLOS_controlModeD = 110
MCLOS_controlModeL = 108
MCLOS_controlModeR = 109
MCLOS_mouseControl = false
menu.slider(MenuWeaponMCLOS, "MCLOS Control Mode", {"csmcloscontrol"}, "What you use to Control the Missle.\n\n1 - Nmp; 8, 4, 5, 6\n2 - Mouse Control", 1, 2, 1, 1, function(value)
    if value == 1 then
        MCLOS_controlModeU = 111
        MCLOS_controlModeD = 110
        MCLOS_controlModeL = 108
        MCLOS_controlModeR = 109
        MCLOS_mouseControl = false
    elseif value == 2 then
        MCLOS_mouseControl = true
    end
end)

MCLOS_MaxSpeed = 50
menu.slider(MenuWeaponMCLOS, "MCLOS Missle Speed", {"csmclosspeed"}, "Speed Limit of the MCLOS Missle.", 10, 500, 50, 5, function(value)
    MCLOS_MaxSpeed = value
end)

MCLOS_TurnSpeed = 2
menu.slider(MenuWeaponMCLOS, "MCLOS Missle Turn Rate", {"csmclosturn"}, "Turn Rate of the MCLOS Missle.", 1, 10, 2, 1, function(value)
    MCLOS_TurnSpeed = value
end)


--[[| Self/Weapon/MissleGuidance/SACLOS/ |]]--
missle_SACLOS = false
menu.toggle(MenuWeaponSACLOS, "SACLOS", {"cssaclos"}, "SACLOS is Semi-Automatic Missle Guidance. The Missle will go to where your Cursor Points.", function(on)
    missle_SACLOS = on
    mod_uses("object", if on then 1 else -1)
end)

SACLOS_SelectedMissle = util.joaat("w_lr_homing_rocket")
menu.slider(MenuWeaponSACLOS, "SACLOS Selected Missle", {"cssaclosmissle"}, "The Missle that will be used for SACLOS Guidance.\n\n1 - RPG\n2 - Homing Launcher\n3 - Oppressor Missle\n4 - B-11 Barrage\n5 - B-11 Homing\n6 - Chernobog Missle\n7 - Explosive Bomb\n8 - Incendiary Bomb\n9 - Gas Bomb\n10 - Cluster Bomb", 1, 10, 2, 1, function(value)
    if value == 1 then SACLOS_SelectedMissle = util.joaat("w_lr_rpg_rocket")
    elseif value == 2 then SACLOS_SelectedMissle = util.joaat("w_lr_homing_rocket")
    elseif value == 3 then SACLOS_SelectedMissle = util.joaat("w_ex_vehiclemissile_3")
    elseif value == 4 then SACLOS_SelectedMissle = util.joaat("w_smug_airmissile_01b")
    elseif value == 5 then SACLOS_SelectedMissle = util.joaat("w_battle_airmissile_01")
    elseif value == 6 then SACLOS_SelectedMissle = util.joaat("w_ex_vehiclemissile_4")
    elseif value == 7 then SACLOS_SelectedMissle = util.joaat("w_smug_bomb_01")
    elseif value == 8 then SACLOS_SelectedMissle = util.joaat("w_smug_bomb_02")
    elseif value == 9 then SACLOS_SelectedMissle = util.joaat("w_smug_bomb_03")
    elseif value == 10 then SACLOS_SelectedMissle = util.joaat("w_smug_bomb_04") end
end)

SACLOS_MaxSpeed = 50
menu.slider(MenuWeaponSACLOS, "SACLOS Missle Speed", {"cssaclosspeed"}, "Speed Limit of the SACLOS Missle.", 10, 500, 50, 5, function(value)
    SACLOS_MaxSpeed = value
end)

SACLOS_drawLaser = false
menu.toggle(MenuWeaponSACLOS, "Laser", {"cssacloslaser"}, "Draws a Laser Straight in Front of you. Doesn't Affect the way the Missle Works, just Visual.", function(on)
    if on then SACLOS_drawLaser = true else SACLOS_drawLaser = false end
end)



--[[| Vehicle/Main/Movement/ |]]--
menu.toggle_loop(MenuVehMovement, "Shift to Drift", {"csshifttodrift"}, "This will Lower you Car's Traction when Holding Shift. I Reccomend Tapping Shift to Actually Drift, since you can Vary the Drift's Turn Rate that way.", function(on)    
    if PAD.IS_CONTROL_PRESSED(21, 21) then
        VEHICLE.SET_VEHICLE_REDUCE_GRIP(player_cur_car, true)
        VEHICLE.SET_VEHICLE_REDUCE_GRIP_LEVEL(player_cur_car, 0.0)
    else
        VEHICLE.SET_VEHICLE_REDUCE_GRIP(player_cur_car, false)
    end
end)

menu.toggle_loop(MenuVehMovement, "Horn Boost", {"cshornboost"}, "Use your Horn Button to Boost your Car Forwards.", function(on)    
    if player_cur_car ~= 0 then
        VEHICLE.SET_VEHICLE_ALARM(player_cur_car, false)
        if AUDIO.IS_HORN_ACTIVE(player_cur_car) then
            ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(player_cur_car, 1, 0.0, 1.0, 0.0, true, true, true, true)
        end
    end
end)

menu.toggle_loop(MenuVehMovement, "Downforce",{"csdownforce"}, "When Toggled, this Applies a Strong Downforce to you Car. It makes it Stick to Walls aswell.", function(on)    
    if player_cur_car ~= 0 then
        local vel = ENTITY.GET_ENTITY_VELOCITY(player_cur_car)
        vel['z'] = -vel['z']
        ENTITY.APPLY_FORCE_TO_ENTITY(player_cur_car, 2, 0, 0, -50 -vel['z'], 0, 0, 0, 0, true, false, true, false, true)
    end
end)

menu.toggle_loop(MenuVehMovement, "Instant Engine Start", {"csinstantcarengine"}, "Instantly Starts the Engine of a Vehicle when you get in it.", function(on)
    TurnCarOnInstantly()
end)

v_f_previous_car = 0
vflyspeed = 100
v_fly = false
v_f_plane = 0
local ls_vehiclefly = menu.toggle_loop(MenuVehMovement, "Vehicle Fly", {"csvehfly"}, "Makes your Vehicle Fly Wherever you Look. The Vehicle still has Collision though!", function(on) 
    if player_cur_car ~= 0 and PED.IS_PED_IN_ANY_VEHICLE(players.user_ped(), true) then
        ENTITY.SET_ENTITY_MAX_SPEED(player_cur_car, vflyspeed)
        local c = CAM.GET_GAMEPLAY_CAM_ROT(0)
        ENTITY.SET_ENTITY_ROTATION(player_cur_car, c.x, c.y, c.z, 0, true)
        any_c_pressed = false
        --W
        local x_vel = 0.0
        local y_vel = 0.0
        local z_vel = 0.0
        if PAD.IS_CONTROL_PRESSED(32, 32) then
            x_vel = vflyspeed
        end 
        --A
        if PAD.IS_CONTROL_PRESSED(63, 63) then
            y_vel = -vflyspeed
        end
        --S
        if PAD.IS_CONTROL_PRESSED(33, 33) then
            x_vel = -vflyspeed
        end
        --D
        if PAD.IS_CONTROL_PRESSED(64, 64) then
            y_vel = vflyspeed
        end
        if x_vel == 0.0 and y_vel == 0.0 and z_vel == 0.0 then
            ENTITY.SET_ENTITY_VELOCITY(player_cur_car, 0.0, 0.0, 0.0)
        else
            local angs = ENTITY.GET_ENTITY_ROTATION(player_cur_car, 0)
            local spd = ENTITY.GET_ENTITY_VELOCITY(player_cur_car)
            if angs.x > 1.0 and spd.z < 0 then
                z_vel = -spd.z 
            else
                z_vel = 0.0
            end
            ENTITY.APPLY_FORCE_TO_ENTITY(player_cur_car, 3, y_vel, x_vel, z_vel, 0.0, 0.0, 0.0, 0, true, true, true, false, true)
        end
    end
end, function()
    if player_cur_car ~= 0 then
        ENTITY.SET_ENTITY_HAS_GRAVITY(player_cur_car, true)
    end
end)

menu.slider(MenuVehMovement, "Vehicle Fly Speed", {"csvehflyspeed"}, "Set the Speed at which 'Vehicle Fly' will Fly at.", 1, 3000, 100, 50, function(s)
    vflyspeed = s
end)

menu.action(MenuVehMovement, "Flip Upside-Down", {"csflipupsidedown"}, "Flips your Current Car Upside-Down. Useful with the Oppressor MK2 for Flying Upside Down.", function(on_click)
    local veh = PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), false)
    local vv = ENTITY.GET_ENTITY_ROTATION(veh, 2)
    local vvYaw = v3.getZ(vv)
    ENTITY.SET_ENTITY_ROTATION(veh, 0, 179.5, vvYaw, 2, true)
end)


--[[| Vehicle/Main/Visual/Main/ |]]--
menu.click_slider(MenuVehVisualMain, "Suspension Height", {"cssuspensionheight"}, "Use this to set your Vehicle's Suspension Height.\nThis is only Client Side, and is on a Per-Car Basis, and will keep the Suspension Setting for that Car until you Restart your Game or Change it back.", -500, 500, 0, 5, function(value)
    SuspHeight = value
    SuspHeight = SuspHeight / 100
    local ped = players.user_ped()
    local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
    local VehicleHandle = PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), false)
    if VehicleHandle == 0 then return end
    local CAutomobile = entities.handle_to_pointer(VehicleHandle)
    local CHandlingData = memory.read_long(CAutomobile + 0x0938)
    memory.write_float(CHandlingData + 0x00D0, SuspHeight)
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(VehicleHandle, pos.x, pos.y, pos.z + 2.8, false, false, false)
end)

menu.click_slider(MenuVehVisualMain, "Vehicle Dirt Level", {"csdirtlevel"}, "Sets the Dirt Level on your Vehicle. Set to 0 to Completely Clean your Vehicle.", 0, 15, 0, 1, function(s)    
    if player_cur_car ~= 0 then
        VEHICLE.SET_VEHICLE_DIRT_LEVEL(player_cur_car, s)
    end
end)

menu.click_slider(MenuVehVisualMain, "Set Transform State", {"cstransformstate"}, "This lets you set the Transform State of the Deluxo and Oppressor. The Number is Divided by 10 Due to Sliders not being able to use Decimals. So 1 is .1, 10 is .1, etc. 0 is Hover off, 1 is hover on. Every Number in between will make it a Kind of Half Hover State. Any Value above 10 will Glitch the Wheels above the Deluxo.", 0, 100, 0, 1, function(value)
    local valueToDec = value / 10
    VEHICLE.SET_SPECIAL_FLIGHT_MODE_TARGET_RATIO(player_cur_car, valueToDec)
end)

menu.toggle_loop(MenuVehVisualMain, "True Rainbow Colours", {"cstruerainbow"}, "Makes your Car Switch through the Actual Colours of the Rainbow, not just Random ones.", function(on)    
    VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(player_cur_car, tr, tg, tb)
    VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(player_cur_car, tr, tg, tb)
    VEHICLE.SET_VEHICLE_NEON_COLOUR(player_cur_car, tr, tg, tb)
end)

menu.toggle_loop(MenuVehVisualMain, "Smooth True Rainbow", {"cssmoothrainbow"}, "Makes your Car Slowly Fade through Colours of the Rainbow.", function(on)    
    VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(player_cur_car, randR, randG, randB)
    VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(player_cur_car, randR, randG, randB)
    VEHICLE.SET_VEHICLE_NEON_COLOUR(player_cur_car, randR, randG, randB)
end)


--[[| Vehicle/Main/Visual/Lights/ |]]--
menu.toggle_loop(MenuVisualLights, "Turn Signals", {"csturnsignals"}, "Makes your Car's Turn Signals Blink when Holding the Cooresponding Direction (A/D).\nThis is Client-Sided Only, so Other Players won't See this!", function(on)    
    if player_cur_car ~= 0 then
        local left = PAD.IS_CONTROL_PRESSED(34, 34)
        local right = PAD.IS_CONTROL_PRESSED(35, 35)
        if left then
            VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(player_cur_car, 1, true)
        elseif right then
            VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(player_cur_car, 0, true)
        end
        if not left then
            VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(player_cur_car, 1, false)
        end
        if not right then
            VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(player_cur_car, 0, false)
        end
    end
end)

menu.toggle(MenuVisualLights, "Hazard Lights", {"cshazardlights"}, "While this is On, your Car's Hazard Lights will Blink.\nThis is Client-Sided Only, so Other Players won't See this!", function(on)    
    if player_cur_car ~= 0 then
        if on then
            VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(player_cur_car, 1, true)
            VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(player_cur_car, 0, true)
            util.yield(500)
        else
            VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(player_cur_car, 1, false)
            VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(player_cur_car, 0, false) 
        end
    end
end)

menu.toggle(MenuVisualLights, "Left Turn Signal", {"csleftturnsignal"}, "Turn on the Left Blinker", function(on)
    if on then
        VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(player_cur_car, 1, true)
    else
        VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(player_cur_car, 1, false)
    end
end)

menu.toggle(MenuVisualLights, "Right Turn Signal", {"csrightturnsignal"}, "Turn on the Right Blinker.", function(on)
    if on then
        VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(player_cur_car, 0, true)
    else
        VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(player_cur_car, 0, false)
    end
end)

menu.toggle(MenuVisualLights, "Brake Lights", {"csbrakelights"}, "Toggle your Vehicle's Brake Lights.", function(on)
    if on then VEHICLE.SET_VEHICLE_BRAKE_LIGHTS(player_cur_car, true) else VEHICLE.SET_VEHICLE_BRAKE_LIGHTS(player_cur_car, false) end
end)


--[[| Vehicle/Main/HealthArmour/ |]]--
menu.toggle_loop(MenuVehHealth, "Stealth Godmode", {"csvehstealthgm"}, "Most Menus won't Detect this as Vehicle Godmode.", function(on)
    ENTITY.SET_ENTITY_PROOFS(entities.get_user_vehicle_as_handle(), true, true, true, true, true, 0, 0, true)
    ENTITY.SET_ENTITY_PROOFS(PED.GET_VEHICLE_PED_IS_IN(players.user(), false), false, false, false, false, false, 0, 0, false)
end)

menu.toggle(MenuVehHealth, "Bulletproof", {"csvehiclebulletproof"}, "Makes the Windows on your Car Bulletproof. Does not Godmode your Car though, and Only Works for Some Cars!", function(on)
    if player_cur_car ~= 0 then
        if on then ENTITY.SET_ENTITY_PROOFS(player_cur_car, true, false, false, false, false, false, false, false) else ENTITY.SET_ENTITY_PROOFS(player_cur_car, false, false, false, false, false, false, false, false) end
    end
end)

menu.toggle_loop(MenuVehHealth, "No C4 on Vehicle", {"csnostickyonvehicle"}, "While Toggled, this will Automatically Remove any C4 that is Attatched to your Vehicle.", function(on)
    if player_cur_car ~= 0 then
        NETWORK.REMOVE_ALL_STICKY_BOMBS_FROM_ENTITY(player_cur_car, players.user_ped())
    end 
end)

menu.toggle_loop(MenuVehHealth, "Never Damaged", {"csvehneverdamaged"}, "Constantly Repairs your Vehicle so it doesn't get Damaged or Deformed. Can also be used to Rapid Fire Vehicle Weapons INSANELY Fast.", function(on)   
    if GET_VEHICLE_HEALTH_PERCENTAGE(player_cur_car, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0) < 100.0 then
        VEHICLE.SET_VEHICLE_FIXED(player_cur_car)
        VEHICLE.SET_VEHICLE_DEFORMATION_FIXED(player_cur_car)
    end
end)


--[[| Vehicle/Main/Aircraft/Jet/ |]]--
b11FixToggle = menu.toggle_loop(MenuJet, "B-11 'Fix'", {"csjetfix"}, "Only Works on the B-11. Makes the Cannon like how it is in Real Life; Insanely Fast.", function(on)
    if VEHICLE.IS_VEHICLE_MODEL(player_cur_car, 1692272545) then
        local playerA10 = player_cur_car
        local cannonBonePos = ENTITY.GET_ENTITY_BONE_POSTION(playerA10, ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(playerA10, "weapon_1a"))
        local target = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(playerA10, 0, 175, 0)
        if PAD.IS_CONTROL_PRESSED(114, 114) then
            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(cannonBonePos['x'], cannonBonePos['y'], cannonBonePos['z'], target['x']+math.random(-3,3), target['y']+math.random(-3,3), target['z']+math.random(-3,3), 100.0, true, 3800181289, players.user_ped(), true, false, 100.0)
        end
    else
        util.toast("-Chalkscript-\n\nYou have to be in a B-11 to use this!")
        menu.trigger_command(b11FixToggle, "off")
    end
end)


--[[| Vehicle/Main/Aircraft/Helicopter/ |]]--
menu.click_slider(MenuHeli, "Heli Power", {"cshelipower"}, "Increases or Decreased the Helicopter Thrust.\nDefault is 50", 0, 1000, 50, 10, function (value)
    if player_cur_car ~= 0 then
        local CflyingHandling = get_sub_handling_types(entities.get_user_vehicle_as_handle(), 1)
        if CflyingHandling then
            memory.write_float(CflyingHandling + thrust_offset, value * 0.01)
            util.toast("-Chalkscript-\n\nHelicopter Power set to "..value)
        else
            util.toast("-Chalkscript-\n\nCould not Change Thrust Power.\nGet in a Heli First!")
        end
    end
end)

menu.action(MenuHeli, "Disable Auto-Stabilization", {"csnohelistabalize"}, "Clicking this will Disable Helicopter Auto-Stabilization on a Per-Heli Basis.\nThis works for other Vehicles with VTOL Capabilities, but is a Little Glitchy.", function ()
    local CflyingHandling = get_sub_handling_types(entities.get_user_vehicle_as_handle(), 1)
    if CflyingHandling then
        for _, offset in pairs(better_heli_handling_offsets) do
            memory.write_float(CflyingHandling + offset, 0)
        end
        util.toast("-Chalkscript-\n\nHeli Auto-Stabilization has been Disabled.\nRelease your inner Battlefield 4!")
    else util.toast("-Chalkscript-\n\nCould not Disable Auto-Stabilization.\nGet in a Heli First!") end
end)

menu.toggle_loop(MenuHeli, "Instant Engine Startup", {"csinstantheliengine"}, "When Active, Helicopter Engines will Instantly Spin up to Full RPM.", function(on)
    if player_cur_car ~= 0 then
        VEHICLE.SET_HELI_BLADES_FULL_SPEED(player_cur_car)
    end
end)


--[[| Vehicle/Main/Aircraft/Universal/ |]]--
aircraftAimbotAnyVehicle = false
menu.toggle_loop(MenuAircraftUniversal, "Aircraft Aimbot", {"csaircraftaimbot"}, "Makes any Aircraft Snap Directly to the Nearest Person. Does not look Legit, as it uses 'SET_ENTITY_ROTATION' and isn't Smooth!", function ()
    local p = GetClosestPlayerWithRange_Whitelist(200)
    local localped = players.user_ped()
    local localcoords2 = ENTITY.GET_ENTITY_COORDS(localped)
    if p ~= nil and not PED.IS_PED_DEAD_OR_DYING(p) and ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY(localped, p, 17) and not AIM_WHITELIST[NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(p)] and (not players.is_in_interior(NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(p))) and (not players.is_godmode(NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(p))) then
        if PED.IS_PED_IN_ANY_VEHICLE(localped) then
            local veh = PED.GET_VEHICLE_PED_IS_IN(localped, false)
            if aircraftAimbotAnyVehicle == false then
                if VEHICLE.GET_VEHICLE_CLASS(veh) == 15 or VEHICLE.GET_VEHICLE_CLASS(veh) == 16 then
                    local pcoords2 = PED.GET_PED_BONE_COORDS(p, 24817, 0, 0, 0)
                    local look2 = v3.lookAt(localcoords2, pcoords2)
                    local look = GetTableFromV3Instance(look2)
                    ENTITY.SET_ENTITY_ROTATION(veh, look.x, look.y, look.z, 1, true)
                end
            else
                if veh ~= nil then
                    local pcoords2 = PED.GET_PED_BONE_COORDS(p, 24817, 0, 0, 0)
                    local look2 = v3.lookAt(localcoords2, pcoords2)
                    local look = GetTableFromV3Instance(look2)
                    ENTITY.SET_ENTITY_ROTATION(veh, look.x, look.y, look.z, 1, true)
                end
            end
        end
    end
end)

menu.toggle(MenuAircraftUniversal, "Aircraft Aimbot in Any Vehicle", {"csaircraftaimbotanyveh"}, "Lets you use Aircraft Aimbot not just for Aircrafts, but any Vehicle in the Game.", function(on)
    if on then aircraftAimbotAnyVehicle = true else aircraftAimbotAnyVehicle = false end
end)


--[[| Vehicle/Main/PersonalVehicle/ |]]--
exclusiveVehicle = 0
local setExclusiveVehicleToggle = menu.toggle(MenuVehPersonal, "Set Exclusive Vehicle", {"csvehicleexclusive"}, "Sets you as the Exclusive Driver of your Current Vehicle, making you the Only One able to Drive it.", function(on)
    local localped = players.user_ped()
    if on then 
        VEHICLE.SET_VEHICLE_EXCLUSIVE_DRIVER(player_cur_car, localped, 1) 
        exclusiveVehicle = player_cur_car
        util.toast("-Chalkscript-\n\nSuccessfully Set Current Vehicle as Exclusive Vehicle.")
        exclusiveVehBlip = HUD.ADD_BLIP_FOR_ENTITY(exclusiveVehicle)
        HUD.SET_BLIP_SPRITE(exclusiveVehBlip, 812) --Missle Icon ID
        HUD.SET_BLIP_COLOUR(exclusiveVehBlip, 29)
        while on do
            HUD.SET_BLIP_ROTATION(exclusiveVehBlip, math.ceil(ENTITY.GET_ENTITY_HEADING(exclusiveVehicle)))
            if not VEHICLE.IS_VEHICLE_DRIVEABLE(exclusiveVehicle, false) then
                HUD.SET_BLIP_COLOUR(exclusiveVehBlip, 1)
            elseif not VEHICLE.IS_VEHICLE_DRIVEABLE(exclusiveVehicle, true) then
                HUD.SET_BLIP_COLOUR(exclusiveVehBlip, 17)
            else
                HUD.SET_BLIP_COLOUR(exclusiveVehBlip, 29)
            end
            util.yield()
        end
    else 
        VEHICLE.SET_VEHICLE_EXCLUSIVE_DRIVER(player_cur_car, localped, 0)
        util.remove_blip(exclusiveVehBlip)
        exclusiveVehicle = 0
        util.toast("-Chalkscript-\n\nSuccessfully Removed Current Vehicle as Exclusive Vehicle.")
    end
end)

menu.toggle(MenuVehPersonal, "Lock Vehicle", {"csvehicleexclusivekickpassengers"}, "Locks your Exclusive Vehicle.", function(on)
    if on then 
        VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(exclusiveVehicle, true)
        util.toast("-Chalkscript-\n\nLocked your Exclusive Vehicle.") 
    else 
        VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(exclusiveVehicle, false) 
        util.toast("-Chalkscript-\n\nUnlocked your Exclusive Vehicle.")
    end
end)

menu.action(MenuVehPersonal, "Delete Exclusive Vehicle", {'csvehicledeleteexclusive'}, "Deletes your Current Exclusive Vehicle.", function(on_click)
    if not exclusiveVehicle then
        util.toast("-Chalkscript-\n\nNo Exclusive Vehicle Currently set!\nYou can Set One using the 'Set Exclusive Driver' Command Above.")
    end
    util.remove_blip(exclusiveVehBlip)
    menu.trigger_command(setExclusiveVehicleToggle, "off")
    entities.delete_by_handle(exclusiveVehicle)
    util.toast("-Chalkscript-\n\nExclusive Vehicle Deleted.")
end)

menu.action(MenuVehPersonal, "Explode Exclusive Vehicle", {"csvehicleexplodeexclusive"}, "Puts an Owned Explosion on your Current Exclusive Vehicle.", function(on_click)
    local localped = players.user_ped()
    local exclusiveVehVector = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(exclusiveVehicle, 0, 0, 0)
    if not exclusiveVehicle then
        util.toast("-Chalkscript-\n\nNo Exclusive Vehicle Currently set!\nYou can Set One using the 'Set Exclusive Driver' Command Above")
    end
    FIRE.ADD_OWNED_EXPLOSION(localped, exclusiveVehVector['x'], exclusiveVehVector['y'], exclusiveVehVector['z'], 4, 100, true, true, 1.0)
end)


--[[| Vehicle/Other/Doors/ |]]--
InstantDoorBool = false
menu.toggle(MenuVehDoors, "Instantly Open", {"csdoorinstantopen"}, "Wether the Door should go Straight to it's Open Position, or go through the whole Animation.", function(on)
    if on then InstantDoorBool = true else InstantDoorBool = false end
end)

LooseDoorBool = true
menu.toggle(MenuVehDoors, "Stay Open", {"csdoorstayopen"}, "Wether the Door should stay Open until Toggled off, or be able to Close if Pushed.", function(on)
    if on then LooseDoorBool = false else LooseDoorBool = true end
end)

DoorForceOpen = false
menu.toggle(MenuVehDoors, "Force Stay Open", {"csdoorforcestayopen"}, "This uses a Loop to Spam open Door so it Never even Moves.", function(on)
    if on then DoorForceOpen = true else DoorForceOpen = false end 
end)



--[[| Vehicle/Other/Doors/OpenClose/ |]]--
menu.toggle(MenuVehOpenDoors, "Front Left", {"csdoorfl"}, "Open the Front Left Door.", function(on) OpenVehicleDoor_CurCar(true, 0, LooseDoorBool, InstantDoorBool, DoorForceOpen) end)

menu.toggle(MenuVehOpenDoors, "Front Right", {"csdoorfr"}, "Open the Front Right Door.", function(on) OpenVehicleDoor_CurCar(true, 1, LooseDoorBool, InstantDoorBool, DoorForceOpen) end)

menu.toggle(MenuVehOpenDoors, "Back Left", {"csdoorrl"}, "Open the Back Left Door.", function(on) OpenVehicleDoor_CurCar(true, 2, LooseDoorBool, InstantDoorBool, DoorForceOpen) end)

menu.toggle(MenuVehOpenDoors, "Back Right", {"csdoorrr"}, "Open the Back Right Door.", function(on) OpenVehicleDoor_CurCar(true, 3, LooseDoorBool, InstantDoorBool, DoorForceOpen) end)

menu.toggle(MenuVehOpenDoors, "Hood", {"csdoorhood"}, "Open the Hood.", function(on) OpenVehicleDoor_CurCar(true, 4, LooseDoorBool, InstantDoorBool, DoorForceOpen) end)

menu.toggle(MenuVehOpenDoors, "Trunk", {"csdoortrunk"}, "Open the Trunk.", function(on) OpenVehicleDoor_CurCar(true, 5, LooseDoorBool, InstantDoorBool, DoorForceOpen) end)

menu.toggle(MenuVehOpenDoors, "Back", {"csdoorback"}, "Open the Back.", function(on) OpenVehicleDoor_CurCar(true, 6, LooseDoorBool, InstantDoorBool, DoorForceOpen) end)

menu.toggle(MenuVehOpenDoors, "Back 2", {"csdoorbackb"}, "Open the Second Back.", function(on) OpenVehicleDoor_CurCar(true, 7, LooseDoorBool, InstantDoorBool, DoorForceOpen) end)


--[[| Vehicle/Other/Windows/ |]]--
menu.toggle(MenuVehWindows, "Front Left", {"cswindowfl"}, "Roll the Front Left Window Up or Down.", function(on)
    if on then
        LowerVehicleWindow_CurCar(true, 0)
    else
        LowerVehicleWindow_CurCar(false, 0)
    end
end)

menu.toggle(MenuVehWindows, "Front Right", {"cswindowfr"}, "Roll the Front Right Window Up or Down.", function(on)
    if on then
        LowerVehicleWindow_CurCar(true, 1)
    else
        LowerVehicleWindow_CurCar(false, 1)
    end
end)

menu.toggle(MenuVehWindows, "Back Left", {"cswindowrl"}, "Roll the Back Left Window Up or Down.", function(on)
    if on then
        LowerVehicleWindow_CurCar(true, 2)
    else
        LowerVehicleWindow_CurCar(false, 2)
    end
end)

menu.toggle(MenuVehWindows, "Back Right", {"cswindowrr"}, "Roll the Back Right Window Up or Down.", function(on)
    if on then
        LowerVehicleWindow_CurCar(true, 3)
    else
        LowerVehicleWindow_CurCar(false, 3)
    end
end)


--[[| Vehicle/Other/Countermeasures/ |]]--
menu.toggle_loop(MenuVehOtherCounterM, "Infinite Countermeasures", {"csinfinitecountermeasures"}, "Gives any Vehicle that has Countermeasures Infinite Countermeasures. Has no corellation to 'Force Countermeasures'", function(on)    
    if VEHICLE.GET_VEHICLE_COUNTERMEASURE_AMMO(player_cur_car) < 100 then
        VEHICLE.SET_VEHICLE_COUNTERMEASURE_AMMO(player_cur_car, 100)
    end
end)

--[[| Vehicle/Other/Countermeasures/Flare/ |]]--
RealFlares = false
menu.toggle_loop(MenuVehCounterFlare, "Force Flares", {"csforceflares"}, "Spawns Flares Behind the Vehicle when the Horn Button is Pressed.", function(on)    
    if PAD.IS_CONTROL_PRESSED(46, 46) then
        if player_cur_car ~= 0 then
            if RealFlares == false then
                local target = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), -2, -2.0, 0)
                local target2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), -3, -25.0, 0)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(target['x'], target['y'], target['z'], target2['x'], target2['y'], target2['z'], 100.0, true, 1198879012, players.user_ped(), true, false, 25.0)
                local target = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 2, -2.0, 0)
                local target2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 3, -25.0, 0)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(target['x'], target['y'], target['z'], target2['x'], target2['y'], target2['z'], 100.0, true, 1198879012, players.user_ped(), true, false, 25.0)
                util.yield(350)
                local target = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), -4, -2.0, 0)
                local target2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), -10, -20.0, -1)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(target['x'], target['y'], target['z'], target2['x'], target2['y'], target2['z'], 100.0, true, 1198879012, players.user_ped(), true, false, 25.0)
                local target = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 4, -2.0, 0)
                local target2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 10, -20.0, -1)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(target['x'], target['y'], target['z'], target2['x'], target2['y'], target2['z'], 100.0, true, 1198879012, players.user_ped(), true, false, 25.0)
                util.toast("-Chalkscript-\n\nFlares Recharging...")
                util.yield(2000)
                util.toast("-Chalkscript-\n\nFlares Ready!")
            elseif RealFlares then
                for i = 0, 10, 1 do 
                    local target = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 0, -2, -1)
                    local target2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 0, -20, -15)
                    MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(target['x'], target['y'], target['z'], target2['x'], target2['y'], target2['z'], 100.0, true, 1198879012, players.user_ped(), true, false, 25.0)
                    util.yield(200)
                end
                util.toast("-Chalkscript-\n\nFlares Recharging...")
                util.yield(2000)
                util.toast("-Chalkscript-\n\nFlares Ready!")
            end
        else
            util.toast("-Chalkscript-\n\nPlease get in a Car before Activating this!")
        end
    end
end)

menu.toggle(MenuVehCounterFlare, "Realistic Flares", {"csforceflaresrealistic"}, "An Option for 'Force Flares' that will instead Shoot 10 Flares Down, like in Real Life Jets.", function(on)
    if on then RealFlares = true else RealFlares = false end
end)


--[[| Vehicle/Other/Countermeasures/Chaff/ |]]--
menu.toggle_loop(MenuVehCounterChaff, "Force Chaff", {"csforcechaff"}, "Spawns Chaff Particles on you and Disables Lock on for 6 Seconds.", function(on)
    --scr_sm_counter
    --scr_sm_counter_chaff
    STREAMING.REQUEST_NAMED_PTFX_ASSET("scr_sm_counter")
    GRAPHICS.USE_PARTICLE_FX_ASSET("scr_sm_counter")
    if STREAMING.HAS_NAMED_PTFX_ASSET_LOADED("scr_sm_counter") then
        if PAD.IS_CONTROL_PRESSED(46, 46) then
            if player_cur_car ~= 0 then
                local ChaffTarget = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(player_cur_car, 0, 0, -2.5)           
                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("scr_sm_counter_chaff", ChaffTarget['x'], ChaffTarget['y'], ChaffTarget['z'], 0, 0, 0, 10, 0, 0, 0)
                GRAPHICS.USE_PARTICLE_FX_ASSET("scr_sm_counter")
                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("scr_sm_counter_chaff", ChaffTarget['x'], ChaffTarget['y'], ChaffTarget['z'], 0, 0, 0, 10, 0, 0, 0)
                GRAPHICS.USE_PARTICLE_FX_ASSET("scr_sm_counter")
                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("scr_sm_counter_chaff", ChaffTarget['x'] + 2, ChaffTarget['y'], ChaffTarget['z'], 100, 0, 0, 10, 0, 0, 0)
                GRAPHICS.USE_PARTICLE_FX_ASSET("scr_sm_counter")
                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("scr_sm_counter_chaff", ChaffTarget['x'] + 2, ChaffTarget['y'], ChaffTarget['z'], 100, 0, 0, 10, 0, 0, 0)               
                GRAPHICS.USE_PARTICLE_FX_ASSET("scr_sm_counter")
                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("scr_sm_counter_chaff", ChaffTarget['x'] - 2, ChaffTarget['y'], ChaffTarget['z'], -100, 0, 0, 10, 0, 0, 0)
                GRAPHICS.USE_PARTICLE_FX_ASSET("scr_sm_counter")
                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("scr_sm_counter_chaff", ChaffTarget['x'] - 2, ChaffTarget['y'], ChaffTarget['z'], -100, 0, 0, 10, 0, 0, 0)                
                GRAPHICS.USE_PARTICLE_FX_ASSET("scr_sm_counter")
                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("scr_sm_counter_chaff", ChaffTarget['x'], ChaffTarget['y'] + 2, ChaffTarget['z'], 0, 100, 0, 10, 0, 0, 0)               
                GRAPHICS.USE_PARTICLE_FX_ASSET("scr_sm_counter")
                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("scr_sm_counter_chaff", ChaffTarget['x'], ChaffTarget['y'] - 2, ChaffTarget['z'], 0, -100, 0, 10, 0, 0, 0)           
                util.toast("-Chalkscript-\n\nChaff Recharging...")
                menu.trigger_command(menu.ref_by_command_name("nolockon"))
                util.yield(6000)
                menu.trigger_command(menu.ref_by_command_name("nolockon"))
                util.yield(2000)
                util.toast("-Chalkscript-\n\nChaff Ready!")
            end
        end
    else
        util.toast("-Chalkscript-\n\nWas not Able to Load Particle Effect.")
    end
end)


--[[| Vehicle/Other/Countermeasures/TROPHYAPS/ |]]--
menu.toggle(MenuCMAPS, "TROPHY APS", {"cstrophyaps"}, "APS (Active Protection System), is a System that will Defend your Vehicle from Missles by Shooting them out of the Sky before they Hit you.", function(on)
    APS_charges = CountermeasureAPSCharges
    vehicle_APS = on
    mod_uses("object", if on then 1 else -1)
end)

CountermeasureAPSrange = 10
menu.slider(MenuCMAPS, "APS Range", {"cstrophyapsrange"}, "The Range at which APS will Destroy Incoming Projectiles.", 5, 100, 10, 5, function(value)
    CountermeasureAPSrange = value
end)

CountermeasureAPSCharges = 8
menu.slider(MenuCMAPS, "APS Charges", {"cstrophyapscharges"}, "Set the Amount of Charges / Projectiles the APS can Destroy before having to Reload.", 1, 100, 8, 1, function(value)
    CountermeasureAPSCharges = value
end)

CountermeasureAPSTimeout = 8000
menu.slider(MenuCMAPS, "APS Reload Time", {"cstrophyapsreload"}, "Set the Time, in Seconds, for how Long it takes the APS to Reload after Depleting all of its Charges. This is not after every Shot, just the Reload after EVERY Charge has been used.", 1, 100, 8, 1, function(value)
    local MultipliedTime = value * 1000
    CountermeasureAPSTimeout = MultipliedTime
end)


--[[| Vehicle/Other/Miscellaneous/ |]]--
menu.toggle_loop(MenuVehOther, "Auto Claim MMI", {"csautommi"}, "Automatically Claims Destroyed Vehicles from MMI.", function()
    local count = memory.read_int(memory.script_global(1585857))
    for i = 0, count do
        local canFix = (bitTest(memory.script_global(1585857 + 1 + (i * 142) + 103), 1) and bitTest(memory.script_global(1585857 + 1 + (i * 142) + 103), 2))
        if canFix then
            clearBit(memory.script_global(1585857 + 1 + (i * 142) + 103), 1)
            clearBit(memory.script_global(1585857 + 1 + (i * 142) + 103), 3)
            clearBit(memory.script_global(1585857 + 1 + (i * 142) + 103), 16)
            util.toast("-Chalkscript-\n\nYour Personal Vehicle has been Destroyed. We have Claimed it Automatically.")
        end
    end
    util.yield(100)
end)

menu.toggle_loop(MenuVehOther, "Horn Annoy", {"cshornannoy"}, "Swaps through Random Horns and Spams then. You can use this to Annoy People in Passive.", function(toggle)    
    if player_cur_car ~= 0 and  PED.IS_PED_IN_ANY_VEHICLE(players.user_ped(), true) then
        VEHICLE.SET_VEHICLE_MOD(player_cur_car, 14, math.random(0, 51), false)
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 86, 1.0)
        util.yield(50)
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 86, 0.0)
    end
end)

menu.toggle_loop(MenuVehOther, "Enter any Car", {"csenteranycar"}, "This will Try to Unlock any Car you Try to get into, and if it doesn't Work, it will just Teleport you into the Driver's Seat.", function(on)
    UnlockVehicleGetIn()
end)

menu.toggle(MenuVehOther, "Vehicle Alarm", {"csvehiclealarm"}, "Turns on your Current Vehicle's Alarm.", function(on)
    if on then
        VEHICLE.SET_VEHICLE_ALARM(player_cur_car, true)
        VEHICLE.START_VEHICLE_ALARM(player_cur_car)
    else
        VEHICLE.SET_VEHICLE_ALARM(player_cur_car, false)
    end
end)

menu.toggle_loop(MenuVehOther, "Bike Safety Wheels", {"csbikesafetywheels"}, "Prevents Motorcycles from Tipping over. You can still Fall off However, it just won't Fall on its Side.", function(on)
    VEHICLE.SET_BIKE_ON_STAND(player_cur_car, 0, 0)
end)

menu.click_slider(MenuVehOther, "Switch Seats", {"csswitchseat"}, "Switches you through the Seats of the Current Car you're in. -1 is Always Driver.", -1, 8, -1, 1, function (value)
    local locped = players.user_ped()
    if PED.IS_PED_IN_ANY_VEHICLE(locped, false) then
        local veh = PED.GET_VEHICLE_PED_IS_IN(locped, false)
        PED.SET_PED_INTO_VEHICLE(locped, veh, value)
    else
        util.toast("-Chalkscript-\n\nCould not Switch Seats.\nGet in a Vehicle First!")
    end
end)



--[[| Online/AllPlayers/ |]]--
menu.action(MenuOnlineAll, "Kick All", {"cskickall"}, "Kicks every Player in the Session. Reccomended that you are the Host when using this.", function(on_click)
    for i = 0, 31, 1 do
        if players.exists(i) and i ~= players.user() then
            local string PlayerName = players.get_name(i)
            local string PlayerNameLower = PlayerName:lower()
            menu.trigger_command(menu.ref_by_command_name("kick"..PlayerNameLower))
        end
    end
end)

menu.action(MenuOnlineAll, "Crash All", {"cscrashall"}, "Crashes every Player in the Session.", function(on_click)
    for i = 0, 31, 1 do
        if players.exists(i) and i ~= players.user() then
            local string PlayerName = players.get_name(i)
            local string PlayerNameLower = PlayerName:lower()
            menu.trigger_command(menu.ref_by_command_name("crash"..PlayerNameLower))
            menu.trigger_command(menu.ref_by_command_name("ngcrash"..PlayerNameLower))
            menu.trigger_command(menu.ref_by_command_name("pipebomb"..PlayerNameLower))
            menu.trigger_command(menu.ref_by_command_name("steamroller"..PlayerNameLower))
        end
    end
end)


--[[| Online/TargetedKickOptions/ |]]--
menu.toggle_loop(MenuOnlineTK, "Auto Kick Host", {"csautokickhost"}, "Automatically Kicks the Host when you Join a New Session. Be careful with this, as you can get Karma'd if the Host is Modding.", function(on)
    local CurrentHostId = players.get_host()
    local CurrentHostName = players.get_name(CurrentHostId)
    local string CurrentHostNameLower = CurrentHostName:lower()
    if players.user() ~= CurrentHostId then
        menu.trigger_command(menu.ref_by_command_name("kick"..CurrentHostNameLower))
    end    
end)

menu.toggle_loop(MenuOnlineTK, "Auto Kick Modders", {"csautokickmodders"}, "Automatically Kicks any Players that get Marked as Modders. Highly Reccomended to be Host while using this, so as to not get Karma'd.", function(on)
    for i = 0, 31, 1 do
        if players.exists(i) and i ~= players.user() and players.is_marked_as_modder(i) then
            local PlayerName = players.get_name(i)
            local PlayerNameLower = PlayerName:lower()
            menu.trigger_command(menu.ref_by_command_name("kick"..PlayerNameLower))
        end
    end
end)

menu.action(MenuOnlineTK, "Kick Host", {"cskickhost"}, "Kicks the Host in your Current Session. Be careful with this, as you can get Karma'd if the Host is Modding.", function(on_click)
    local CurrentHostId = players.get_host()
    local CurrentHostName = players.get_name(CurrentHostId)
    local string CurrentHostNameLower = CurrentHostName:lower()
    if players.get_host() ~= players.user() then
        menu.trigger_command(menu.ref_by_command_name("kick"..CurrentHostNameLower))
    else
        util.toast("-Chalkscript-\n\nThis Command doesn't Work on yourself; You are already the Host!")
    end
end)

menu.action(MenuOnlineTK, "Kick Modders", {"cskickmodders"}, "Will use Smart Kick to use the Best Kick on all Modders. Being the Host is Highly Reccomended, so as to not get Karma'd.", function(on_click)
    for i = 0, 31, 1 do
        if players.exists(i) and i ~= players.user() and players.is_marked_as_modder(i) then
            local PlayerName = players.get_name(i)
            local PlayerNameLower = PlayerName:lower()
            menu.trigger_command(menu.ref_by_command_name("kick"..PlayerNameLower))
        end
    end  
end)



--[[| Online/Protections/ |]]--
menu.toggle_loop(MenuProtection, "Anti Tow-Truck", {"csprotectiontowtruck"}, "Prevents any Tow Truck from Towing you by Immediately Detaching the Hook from your Vehicle.", function(on)
    if PED.IS_PED_IN_ANY_VEHICLE(players.user_ped()) then
        VEHICLE.DETACH_VEHICLE_FROM_ANY_TOW_TRUCK(player_cur_car)
    end
end)



--[[| World/GlobalVehicleOptions/ |]]--
menu.toggle_loop(MenuWorldVeh, "Remove Vehicle Godmode", {"csremovevehgmforall"}, "Removes Vehicle Godmode for Everyone on the Map.", function(on_click)
    RemoveVehicleGodmodeForAll()
end)

local trafficBlips = {}
menu.toggle_loop(MenuWorldVeh, "Mark Traffic", {"csmarktraffic"}, "Puts a Green Dot on all AI Traffic.", function(on)
    for i,ped in pairs(entities.get_all_peds_as_handles()) do 
        if not PED.IS_PED_A_PLAYER(ped) and PED.IS_PED_IN_ANY_VEHICLE(ped) then
            pedVehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)
            if VEHICLE.IS_VEHICLE_DRIVEABLE(pedVehicle, false) and HUD.GET_BLIP_FROM_ENTITY(pedVehicle) == 0 then
                pedBlip = HUD.ADD_BLIP_FOR_ENTITY(pedVehicle)
                HUD.SET_BLIP_ROTATION(pedBlip, math.ceil(ENTITY.GET_ENTITY_HEADING(pedVehicle)))
                HUD.SET_BLIP_SPRITE(pedBlip, 286)
                HUD.SET_BLIP_SCALE_2D(pedBlip, .5, .5)
                HUD.SET_BLIP_COLOUR(pedBlip, 25)
                trafficBlips[#trafficBlips + 1] = pedBlip
            elseif VEHICLE.IS_VEHICLE_DRIVEABLE(pedVehicle, false) and HUD.GET_BLIP_FROM_ENTITY(pedVehicle) != 0 then
                local currentPedVehicleBlip = HUD.GET_BLIP_FROM_ENTITY(pedVehicle)
                HUD.SET_BLIP_ROTATION(currentPedVehicleBlip, math.ceil(ENTITY.GET_ENTITY_HEADING(pedVehicle)))
            end
        end
    end
    for i,b in pairs(trafficBlips) do
        if HUD.GET_BLIP_INFO_ID_ENTITY_INDEX(b) == 0 or not VEHICLE.IS_VEHICLE_DRIVEABLE(pedVehicle, false) then 
            util.remove_blip(b)
            trafficBlips[i] = nil
        end
    end
end, function(on_stop)
    for i,b in pairs(trafficBlips) do
        util.remove_blip(b) 
        trafficBlips[i] = nil
    end
end)

--[[| World/Clear/ |]]--
menu.action(MenuWorldClear, "Full Clear", {"csworldfullclear"}, "This clears any Entity that Exists. It can Break many things, since it Deletes EVERY Entity that is in Range.", function(on_click)
    local ct = 0
    for k,ent in pairs(entities.get_all_vehicles_as_handles()) do
        entities.delete_by_handle(ent)
        ct = ct + 1
    end
    for k,ent in pairs(entities.get_all_peds_as_handles()) do
        if not PED.IS_PED_A_PLAYER(ent) then
            entities.delete_by_handle(ent)
            ct = ct + 1
        end
    end
    for k,ent in pairs(entities.get_all_objects_as_handles()) do
        entities.delete_by_handle(ent)
        ct = ct + 1
    end
    util.toast("-Chalkscript-\n\nFull Clear Complete! Removed "..ct.." Entities in Total.")
end)

menu.action(MenuWorldClear, "Quick Clear", {"csworldquickclear"}, "Only Deletes Vehicles and Peds. Probably won't Break anything, unless a Mission Ped or Vehicle.", function(on_click)
    local ct = 0 
    for k, ent in pairs(entities.get_all_vehicles_as_handles()) do
        entities.delete_by_handle(ent)
        ct = ct + 1
    end
    for k, ent in pairs(entities.get_all_peds_as_handles()) do
        if not PED.IS_PED_A_PLAYER(ent) then
            entities.delete_by_handle(ent)
            ct = ct + 1
        end
    end
    util.toast("-Chalkscript-\n\nSuccessfully Deleted "..ct.." Entities.")
end)


--[[| World/Clear/Specific |]]--
menu.action(MenuWorldClearSpec, "Clear Vehicles", {"csworldclearvehicles"}, "Deletes all Vehicles.", function(on_click)
    local ct = 0
    for k,ent in pairs(entities.get_all_vehicles_as_handles()) do
        entities.delete_by_handle(ent)
        ct = ct + 1
    end
    util.toast("-Chalkscript-\n\nSuccessfully Deleted "..ct.." Vehicles.")
end)

menu.action(MenuWorldClearSpec, "Clear Peds", {"csworldclearpeds"}, "Deletes all Non-Player Peds.", function(on_click)
    local ct = 0
    for k,ent in pairs(entities.get_all_peds_as_handles()) do 
        if not PED.IS_PED_A_PLAYER(ent) then
            entities.delete_by_handle(ent)
            ct = ct + 1
        end
    end
    util.toast("-Chalkscript-\n\nSuccessfully Deleted "..ct.." Peds.")
end)

menu.action(MenuWorldClearSpec, "Clear Objects", {"csworldclearobjects"}, "Deletes all Objects. This can Break most Missions.", function(on_click)
    local ct = 0
    for k,ent in pairs(entities.get_all_objects_as_handles()) do
        entities.delete_by_handle(ent)
        ct = ct + 1
    end
    util.toast("-Chalkscript-\n\nSuccessfull Deleted "..ct.." Objects.")
end)

menu.action(MenuWorldClearSpec, "Clear Pickups", {"csworldclearpickups"}, "Deletes all Pickups.", function(on_click)
    local ct = 0
    for k,ent in pairs(entities.get_all_pickups_as_handles()) do
        entities.delete_by_handle(ent)
        util.toast("Successfully Deleted "..ct.." Pickups")
    end
end)


--[[| World/Projectile/ProjectileMarking/MarkProjectiles/ |]]--
blip_projectiles = false
blip_proj_missles = false
blip_proj_bombs = false
blip_proj_grenades = false
blip_proj_mines = false
blip_proj_misc = false
menu.toggle(MenuWrldProjOptions, "Mark Projectiles", {"csmarkprojectiles"}, "This puts a Red Marker on Basically anthing that can Hurt you, and Moves Slow enough to Detect. This Includes stuff like Rockets, C4, Mines, etc.\nWill also Mark People with an Explo Sniper!", function(on)
    blip_projectiles = on
    mod_uses("object", if on then 1 else -1)
end)

menu.toggle(MenuWrldProjOptions, "Mark Missles", {"csmarkmissles"}, "Wether to Mark Different types of Missles on the Map.", function(on)
    blip_proj_missles = on
    mod_uses("object", if on then 1 else -1)
end)

menu.toggle(MenuWrldProjOptions, "Mark Bombs", {"csmarkbombs"}, "Wether to Mark Bombs Dropped from Planes on the Map.", function(on)
    blip_proj_bombs = on
    mod_uses("object", if on then 1 else -1)
end)

menu.toggle(MenuWrldProjOptions, "Mark Grenades", {"csmarkgrenades"}, "Wether to Mark Different types of Grenades on the Map.", function(on)
    blip_proj_grenades = on
    mod_uses("object", if on then 1 else -1)
end)

menu.toggle(MenuWrldProjOptions, "Mark Mines", {"csmarkmines"}, "Wether to Mark Different types of Mines on the Map.", function(on)
    blip_proj_mines = on
    mod_uses("object", if on then 1 else -1)
end)

menu.toggle(MenuWrldProjOptions, "Mark Misc", {"csmarkmisc"}, "Wether to Mark Miscellaneous Projectiles like Flares on the Map.", function(on)
    blip_proj_misc = on
    mod_uses("object", if on then 1 else -1)
end)


--[[| World/Projectile/ProjectileMarking/MarkProjectileColours/ |]]--
menu.slider(MenuWrldProjColours, "Missle Colour", {"csmarkmisslecol"}, "What Colour Missle Markers should be on the Map.\n\n0 - White\n1 - Red\n2 - Orange\n3 - Yellow\n4 - Green\n5 - Light Blue\n6 - Dark Blue", 0, 6, 0, 1, function(value)
    proj_blip_missle_col = 75
    if value == 1 then proj_blip_missle_col = 75
    elseif value == 2 then proj_blip_missle_col = 47
    elseif value == 3 then proj_blip_missle_col = 46
    elseif value == 4 then proj_blip_missle_col = 69
    elseif value == 5 then proj_blip_missle_col = 77
    elseif value == 6 then proj_blip_missle_col = 78 end
end)

menu.slider(MenuWrldProjColours, "Bomb Colour", {"csmarkbombcol"}, "What Colour Bomb Markers should be on the Map.\n\n0 - White\n1 - Red\n2 - Orange\n3 - Yellow\n4 - Green\n5 - Light Blue\n6 - Dark Blue", 0, 6, 0, 1, function(value)
    proj_blip_bomb_col = 75
    if value == 1 then proj_blip_bomb_col = 75
    elseif value == 2 then proj_blip_bomb_col = 47
    elseif value == 3 then proj_blip_bomb_col = 46
    elseif value == 4 then proj_blip_bomb_col = 69
    elseif value == 5 then proj_blip_bomb_col = 77
    elseif value == 6 then proj_blip_bomb_col = 78 end
end)

menu.slider(MenuWrldProjColours, "Grenade Colour", {"csmarkgrenadecol"}, "What Colour Grenade Markers should be on the Map.\n\n0 - White\n1 - Red\n2 - Orange\n3 - Yellow\n4 - Green\n5 - Light Blue\n6 - Dark Blue", 0, 6, 0, 1, function(value)
    proj_blip_grenade_col = 75
    if value == 1 then proj_blip_grenade_col = 75
    elseif value == 2 then proj_blip_grenade_col = 47
    elseif value == 3 then proj_blip_grenade_col = 46
    elseif value == 4 then proj_blip_grenade_col = 69
    elseif value == 5 then proj_blip_grenade_col = 77
    elseif value == 6 then proj_blip_grenade_col = 78 end
end)

menu.slider(MenuWrldProjColours, "Mine Colour", {"csmarkminecol"}, "What Colour Mine Markers should be on the Map.\n\n0 - White\n1 - Red\n2 - Orange\n3 - Yellow\n4 - Green\n5 - Light Blue\n6 - Dark Blue", 0, 6, 0, 1, function(value)
    proj_blip_mine_col = 75
    if value == 1 then proj_blip_mine_col = 75
    elseif value == 2 then proj_blip_mine_col = 47
    elseif value == 3 then proj_blip_mine_col = 46
    elseif value == 4 then proj_blip_mine_col = 69
    elseif value == 5 then proj_blip_mine_col = 77
    elseif value == 6 then proj_blip_mine_col = 78 end
end)

menu.slider(MenuWrldProjColours, "Misc Colour", {"csmarkmisccol"}, "What Colour Misc Markers should be on the Map.\n\n0 - White\n1 - Red\n2 - Orange\n3 - Yellow\n4 - Green\n5 - Light Blue\n6 - Dark Blue", 0, 6, 0, 1, function(value)
    proj_blip_misc_col = 46
    if value == 1 then proj_blip_misc_col = 75
    elseif value == 2 then proj_blip_misc_col = 47
    elseif value == 3 then proj_blip_misc_col = 46
    elseif value == 4 then proj_blip_misc_col = 69
    elseif value == 5 then proj_blip_misc_col = 77
    elseif value == 6 then proj_blip_misc_col = 78 end
end)


--[[| World/Projectile/ProjectileMovement/ |]]--
projectile_spaz = false
menu.toggle(MenuWrldProjMovement, "Projectile Random", {"csprojectilerandom"}, "Applies Random Velocity to any Projectiles on the Map. Makes them Spaz out.", function(on)
    projectile_spaz = on
    mod_uses("object", if on then 1 else -1)
end)

slow_projectiles = false
menu.toggle(MenuWrldProjMovement, "Slow Projectiles", {"csprojectileslow"}, "Makes All Projectiles move Extremely Slow.", function(on)
    slow_projectiles = on
    mod_uses("object", if on then 1 else -1)
end)



--[[| Game/FakeAlerts/ |]]--
menu.action(MenuAlerts, "Ban Message", {"csfakeban"}, "A Fake Ban Message.", function(on_click)
    show_custom_rockstar_alert("You have been Banned from Grand Theft Auto Online Permanently.~n~Return to Grand Theft Auto V.")
end)

menu.action(MenuAlerts, "Services Unavailable", {"cafakeservicesunavailable"}, "A Fake 'Servives Unavailable' Message.", function(on_click)
    show_custom_rockstar_alert("The Rockstar Game Services are Unavailable right now.~n~Please Return to Grand Theft Auto V.")
end)

menu.action(MenuAlerts, "Custom Alert", {"csfakecustomalert"}, "Lets you input a Custom Alert to Show.", function(on_click)
    util.toast("-Chalkscript-\n\nType what you want the Alert to Say. Use '~n~' to make a Newline, like Pressing Enter.")
    menu.show_command_box("csfakecustomalert ")
end, function(on_command)
    show_custom_rockstar_alert(on_command)
end)


--[[| Game/MacroOptions/ |]]--
macroDelay = 50
macroRunDelay = 0
macroAnnounceEnds = false
menu.toggle(MenuGameMacros, "Announce Start and Finish", {"csmacroannouncestartfinish"}, "Toasts on Screen when the Macro youare Running has Started, and when it has Finished.", function(on)
    if on then macroAnnounceEnds = true else macroAnnounceEnds = false end
end)

menu.slider(MenuGameMacros, "Click Delay", {"csmacroclickdelay"}, "The Delay between Every Click the Macro does, in Milliseconds. 30ms is Often the Limit, and will Almost Always Fail. Increase beyond 50ms if the Macro is Missing off by one, or not Working.", 20, 1000, 50, 10, function(value)
    macroDelay = value
end)

menu.slider(MenuGameMacros, "Run Delay", {"csmacrorundelay"}, "The Time, in Milliseconds before the Macro will Run after you Click it.", 0, 10000, 0, 50, function(value)
    macroRunDelay = value
end)


--[[| Game/MacroOptions/Macros/ |]]--  
menu.action(MenuGameRunMacrosReg, "Register as CEO", {"csmacrosceo"}, "Runs a Macro that will Register you as a CEO.", function(on_click)
    local typeOfCEO = getPlayerRegType(players.user())
    if typeOfCEO == -1 then
        util.yield(macroRunDelay)
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Register as CEO' has Started.") end
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(244, 244, 1.0) ; util.yield(macroDelay) --Press 'M'
        for i=1, 6, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; if i ~= 7 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Down' 6 Times  
        for i=1, 2, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; if i ~= 3 then util.yield(macroDelay) else util.yield(10) end end --Press 'Enter' 2 Times, Yield 10ms on Last Iteration
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(201, 201, 1.0) --Press 'Enter' again Due to Popup
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Register as CEO' has Finished.") end
    else
        util.toast("-Chalkscript-\n\nYou are Already a CEO or VIP! If you are an MC President, then use 'Swap Registration' Macro.")
    end
end)

menu.action(MenuGameRunMacrosReg, "Register as MC", {"csmacrosmc"}, "Runs a Macro that will Register you as an MC President.", function(on_click)
    local typeOfCEO = getPlayerRegType(players.user())   
    if typeOfCEO == -1 then
        util.yield(macroRunDelay)
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Register as MC' has Started.") end
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(244, 244, 1.0) ; util.yield(macroDelay) --Press 'M'
        for i=1, 7, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; if i ~= 8 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Down' 7 Times  
        for i=1, 2, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; if i ~= 3 then util.yield(macroDelay) else util.yield(10) end end --Press 'Enter' 2 Times, Yield 10ms on Last Iteration
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(201, 201, 1.0) --Press 'Enter' again Due to Popup
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Register as MC' has Finished.") end
    else util.toast("-Chalkscript-\n\nYou are Already a MC President! If you are a CEO or VIP, then use 'Swap Registration' Macro.") end
end)

menu.action(MenuGameRunMacrosReg, "Swap Registration", {"csmacrossr"}, "Runs a Macro that will Change your Registration from CEO to MC or Vice Versa, based on which one you're on.", function(on_click)
    local typeOfCEO = getPlayerRegType(players.user())
    if typeOfCEO == 0 then
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Swap Registration' has Started.") end
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(244, 244, 1.0) ; util.yield(macroDelay) --Press 'M'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(172, 172, 1.0) ; util.yield(macroDelay) --Press 'Up'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(10) --Press 'Enter'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(201, 201, 1.0) ; util.yield(macroDelay + 100) --Press 'Enter' again Due to Popup
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(244, 244, 1.0) ; util.yield(macroDelay) --Press 'M'
        for i=1, 7, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; if i ~= 8 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Down' 7 Times  
        for i=1, 2, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; if i ~= 3 then util.yield(macroDelay) else util.yield(10) end end --Press 'Enter' 2 Times, Yield 10ms on Last Iteration
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(201, 201, 1.0) --Press 'Enter' again Due to Popup
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Swap Registration' has Finished.") end
    elseif typeOfCEO == 1 then
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Swap Registration' has Started.") end
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(244, 244, 1.0) ; util.yield(macroDelay) --Press 'M'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(172, 172, 1.0) ; util.yield(macroDelay) --Press 'Up'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(10) --Press 'Enter'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(201, 201, 1.0) ; util.yield(macroDelay + 100) --Press 'Enter' again Due to Popup
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(244, 244, 1.0) ; util.yield(macroDelay) --Press 'M'
        for i=1, 6, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; if i ~= 7 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Down' 6 Times  
        for i=1, 2, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; if i ~= 3 then util.yield(macroDelay) else util.yield(10) end end --Press 'Enter' 2 Times, Yield 10ms on Last Iteration
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(201, 201, 1.0) --Press 'Enter' again Due to Popup
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Swap Registration' has Finished.") end
    else util.toast("-Chalkscript-\n\nYou need to already be in a CEO or MC to use this. Register as One, then Try Again.") end
end)

menu.action(MenuGameRunMacrosSur, "Drop BST", {"csmacrosbst"}, "Runs a Macro that will Drop BST.", function(on_click)
    local typeOfCEO = getPlayerRegType(players.user())
    if typeOfCEO == 0 then
        util.yield(macroRunDelay)
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Drop BST' has Started.") end
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(244, 244, 1.0) ; util.yield(macroDelay) --Press 'M'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay) --Press 'Enter'
        for i=1, 3, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(172, 172, 1.0) ; if i ~= 4 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Up' 3 Times  
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; util.yield(macroDelay) --Press 'Down'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) --Press 'Enter'
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Drop BST' has Finished.") end
    else util.toast("-Chalkscript-\n\nYou need to be a CEO or VIP to Drop BST. Register as One, or use 'Swap Registration' Macro if you are an MC.") end
end)

menu.action(MenuGameRunMacrosSur, "Drop Armour", {"csmacrosarmour"}, "Runs a Macro that will Drop Armour.", function(on_click)
    local typeOfCEO = getPlayerRegType(players.user())
    if typeOfCEO == 0 then
        util.yield(macroRunDelay)
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Drop Armour' has Started.") end
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(244, 244, 1.0) ; util.yield(macroDelay) --Press 'M'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay) --Press 'Enter'
        for i=1, 3, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(172, 172, 1.0) ; if i ~= 4 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Up' 3 Times
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay) --Press 'Enter'
        for i=1, 3, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; if i ~= 4 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Down' 3 Times
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) --Press 'Enter'
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Drop Armour' has Finished.") end
    else util.toast("-Chalkscript-\n\nYou need to be a CEO or VIP to Drop Armour. Register as One, or use 'Swap Registration' Macro if you are an MC.") end
end)

menu.action(MenuGameRunMacrosSur, "Old EWO", {"csmacrosewo"}, "Runs a Macro that will use the Old GTAO Tryhard EWO Method.", function(on_click)
    util.yield(macroRunDelay)
    if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Old EWO' has Started.") end
    CAM.SET_FOLLOW_PED_CAM_VIEW_MODE(4)
    PAD.SET_CONTROL_VALUE_NEXT_FRAME(24, 24, 1.0) ; util.yield(macroDelay) --Press 'Left Click'
    PAD.SET_CONTROL_VALUE_NEXT_FRAME(244, 244, 1.0) ; util.yield(macroDelay) --Press 'M'
    for i=1, 2, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(172, 172, 1.0) ; if i ~= 3 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Up' 2 Times
    for i=1, 2, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(26, 26, 1.0) ; util.yield(5) end --Press 'C'
    PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) --Press 'Enter'
    if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Old EWO' has Finished.") end
end)

menu.action(MenuGameRunMacrosAbi, "Ghost Organization", {"csmacrosghost"}, "Runs a Macro that will Quickly put you in Ghost Organization.", function(on_click)
    local typeOfCEO = getPlayerRegType(players.user())
    if typeOfCEO == 0 then
        util.yield(macroRunDelay)
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Ghost Organization' has Started.") end
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(244, 244, 1.0) ; util.yield(macroDelay) --Press 'M'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay) --Press 'Enter'
        for i=1, 3, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(172, 172, 1.0) ; if i ~= 4 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Up' 3 Times 
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay) --Press 'Enter'
        for i=1, 3, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(172, 172, 1.0) ; if i ~= 4 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Up' 3 Times 
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) --Press 'Enter'
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Ghost Organization' has Finished.") end
    else util.toast("-Chalkscript-\n\nYou need to be a CEO or VIP to Ghost Organization. Register as One, or use 'Swap Registration' Macro if you are an MC.") end
end)

menu.action(MenuGameRunMacrosAbi, "Bribe Authorities", {"csmacrosbribe"}, "Runs a Macro that will Bribe Authorities.", function(on_click)
    local typeOfCEO = getPlayerRegType(players.user())
    if typeOfCEO == 0 then
        util.yield(macroRunDelay)
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Bribe Authorities' has Started.") end
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(244, 244, 1.0) ; util.yield(macroDelay) --Press 'M'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay) --Press 'Enter'
        for i=1, 3, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(172, 172, 1.0) ; if i ~= 4 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Up' 3 Times
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay) --Press 'Enter'
        for i=1, 2, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(172, 172, 1.0) ; if i ~= 3 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Up' 2 Times
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) --Press 'Enter'
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Bribe Authorities' has Finished.") end
    else util.toast("-Chalkscript-\n\nYou need to be a CEO or VIP to Bribe Authorities. Register as One, or use 'Swap Registration' Macro if you are an MC.") end
end)

menu.action(MenuGameRunMacrosVeh, "Spawn Buzzard", {"csmacrosbuzzard"}, "Runs a Macro that will Call a Buzzard.", function(on_click)
    local typeOfCEO = getPlayerRegType(players.user())
    if typeOfCEO == 0 then
        util.yield(macroRunDelay)
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Spawn Buzzard' has Started.") end
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(244, 244, 1.0) ; util.yield(macroDelay) --Press 'M'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay) --Press 'Enter'
        for i=1, 2, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(172, 172, 1.0) ; if i ~= 3 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Up' 2 Times
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay) --Press 'Enter'
        for i=1, 4, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; if i ~= 5 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Down' 4 Times
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) --Press 'Enter'
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Spawn Buzzard' has Finished.") end
    else util.toast("-Chalkscript-\n\nYou need to be a CEO or VIP to Call a Buzzard. Register as One, or use 'Swap Registration' Macro if you are an MC.") end
end)

menu.action(MenuGameRunMacrosVeh, "Spawn Sparrow", {"csmacrossparrow"}, "Runs a Macro that will Call a Sparrow.", function(on_click)
    local typeOfCEO = getPlayerRegType(players.user())
    if typeOfCEO == -1 then
        util.yield(macroRunDelay)
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Spawn Sparrow' has Started.") end
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(244, 244, 1.0) ; util.yield(macroDelay) --Press 'M'
        for i=1, 5, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; if i ~= 6 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Down' 5 Times
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(172, 172, 1.0) ; util.yield(macroDelay) -- Press 'Up'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; util.yield(macroDelay) -- Press 'Down'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) --Press 'Enter'
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Spawn Sparrow' has Finished.") end
    elseif typeOfCEO == 0 or typeOfCEO == 1 then
        util.yield(macroRunDelay)
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Spawn Sparrow' has Started.") end
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(244, 244, 1.0) ; util.yield(macroDelay) --Press 'M'
        for i=1, 6, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; if i ~= 7 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Down' 6 Times
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(172, 172, 1.0) ; util.yield(macroDelay) -- Press 'Up'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; util.yield(macroDelay) -- Press 'Down'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) --Press 'Enter'
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Spawn Sparrow' has Finished.") end
    end
end)

menu.action(MenuGameRunMacrosPhone, "Call Lamar", {"csmacrocalllamar"}, "Calls Lamar on your Phone.", function(on_click)
    util.yield(macroRunDelay)
    if menu.is_open() == true then
        util.toast("Macro is Ready. Close Stand and it will Immediately Run.")
        while menu.is_open ~= false do
            if menu.is_open() == false then
                if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Call Lamar' has Started.") end
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(27, 27, 1.0) ; util.yield(500) --Press 'Up' to Open Phone
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(172, 172, 1.0) ; util.yield(50) --Press 'Up'
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(175, 175, 1.0) ; util.yield(macroDelay) --Press 'Right'
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
                for i=1, 22, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(181, 181, 1.0) ; if i ~= 23 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Up' 22 Times
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) --Press 'Enter'    
                if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Call Lamar' has Finished.") end
                break
            end
            util.yield()
        end
    else
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Call Lamar' has Started.") end
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(27, 27, 1.0) ; util.yield(500) --Press 'Up' to Open Phone
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(172, 172, 1.0) ; util.yield(50) --Press 'Up'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(175, 175, 1.0) ; util.yield(macroDelay) --Press 'Right'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
        for i=1, 22, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(181, 181, 1.0) ; if i ~= 23 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Up' 22 Times
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) --Press 'Enter'    
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Call Lamar' has Finished.") end
    end
end)

menu.action(MenuGameRunMacrosPhone, "Call Lester", {"csmacrocalllester"}, "Calls Lester on your Phone.", function(on_click)
    util.yield(macroRunDelay)
    if menu.is_open() == true then
        util.toast("Macro is Ready. Close Stand and it will Immediately Run.")
        while menu.is_open ~= false do
            if menu.is_open() == false then
                if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Call Lester' has Started.") end
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(27, 27, 1.0) ; util.yield(500) --Press 'Up' to Open Phone
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(172, 172, 1.0) ; util.yield(50) --Press 'Up'
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(175, 175, 1.0) ; util.yield(macroDelay) --Press 'Right'
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
                for i=1, 20, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(181, 181, 1.0) ; if i ~= 21 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Up' 20 Times
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) --Press 'Enter'
                if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Call Lester' has Finished.") end
                break
            end
            util.yield()
        end
    else
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Call Lester' has Started.") end
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(27, 27, 1.0) ; util.yield(500) --Press 'Up' to Open Phone
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(172, 172, 1.0) ; util.yield(50) --Press 'Up'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(175, 175, 1.0) ; util.yield(macroDelay) --Press 'Right'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
        for i=1, 20, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(181, 181, 1.0) ; if i ~= 21 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Up' 20 Times
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) --Press 'Enter'
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Call Lester' has Finished.") end
    end
end)

menu.action(MenuGameRunMacrosPhone, "Call Mechanic", {"csmacrocallmechanic"}, "Calls the Mechanic on your Phone.", function(on_click)
    util.yield(macroRunDelay)
    if menu.is_open() == true then
        util.toast("Macro is Ready. Close Stand and it will Immediately Run.")
        while menu.is_open ~= false do
            if menu.is_open() == false then
                if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Call Mechanic' has Started.") end
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(27, 27, 1.0) ; util.yield(500) --Press 'Up' to Open Phone
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(172, 172, 1.0) ; util.yield(50) --Press 'Up'
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(175, 175, 1.0) ; util.yield(macroDelay) --Press 'Right'
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
                for i=1, 16, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(181, 181, 1.0) ; if i ~= 17 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Up' 16 Times
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) --Press 'Enter'
                if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Call Mechanic' has Finished.") end
                break
            end
            util.yield()
        end
    else
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Call Mechanic' has Started.") end
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(27, 27, 1.0) ; util.yield(500) --Press 'Up' to Open Phone
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(172, 172, 1.0) ; util.yield(50) --Press 'Up'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(175, 175, 1.0) ; util.yield(macroDelay) --Press 'Right'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
        for i=1, 16, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(181, 181, 1.0) ; if i ~= 17 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Up' 16 Times
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) --Press 'Enter'
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Call Mechanic' has Finished.") end
    end
end)

menu.action(MenuGameRunMacrosPhone, "Call Merrywether", {"csmacrocallmerrywether"}, "Calls Merrywether on your Phone.", function(on_click)
    util.yield(macroRunDelay)
    if menu.is_open() == true then
        util.toast("Macro is Ready. Close Stand and it will Immediately Run.")
        while menu.is_open ~= false do
            if menu.is_open() == false then
                if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Call Merrywether' has Started.") end
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(27, 27, 1.0) ; util.yield(500) --Press 'Up' to Open Phone
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(172, 172, 1.0) ; util.yield(50) --Press 'Up'
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(175, 175, 1.0) ; util.yield(macroDelay) --Press 'Right'
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
                for i=1, 15, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(181, 181, 1.0) ; if i ~= 16 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Up' 15 Times
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) --Press 'Enter'
                if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Call Merrywether' has Finished.") end
                break
            end
            util.yield()
        end
    else
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Call Merrywether' has Started.") end
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(27, 27, 1.0) ; util.yield(500) --Press 'Up' to Open Phone
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(172, 172, 1.0) ; util.yield(50) --Press 'Up'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(175, 175, 1.0) ; util.yield(macroDelay) --Press 'Right'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
        for i=1, 15, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(181, 181, 1.0) ; if i ~= 16 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Up' 15 Times
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) --Press 'Enter'
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Call Merrywether' has Finished.") end
    end
end)

menu.action(MenuGameRunMacrosPhone, "Call MMI", {"csmacrocallmmi"}, "Calls Mors Mutual Insurance on your Phone.", function(on_click)
    util.yield(macroRunDelay)
    if menu.is_open() == true then
        util.toast("Macro is Ready. Close Stand and it will Immediately Run.")
        while menu.is_open ~= false do
            if menu.is_open() == false then
                if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Call MMI' has Started.") end
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(27, 27, 1.0) ; util.yield(500) --Press 'Up' to Open Phone
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(172, 172, 1.0) ; util.yield(50) --Press 'Up'
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(175, 175, 1.0) ; util.yield(macroDelay) --Press 'Right'
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
                for i=1, 14, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(181, 181, 1.0) ; if i ~= 15 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Up' 14 Times
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) --Press 'Enter'
                if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Call MMI' has Finished.") end
                break
            end
            util.yield()
        end
    else
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Call MMI' has Started.") end
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(27, 27, 1.0) ; util.yield(500) --Press 'Up' to Open Phone
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(172, 172, 1.0) ; util.yield(50) --Press 'Up'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(175, 175, 1.0) ; util.yield(macroDelay) --Press 'Right'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
        for i=1, 14, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(181, 181, 1.0) ; if i ~= 15 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Up' 14 Times
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) --Press 'Enter'
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Call MMI' has Finished.") end
    end
end)

menu.action(MenuGameRunMacrosPhone, "Call Pegasus", {"csmacrocallpegasus"}, "Calls Pegasus on your Phone.", function(on_click)
    util.yield(macroRunDelay)
    if menu.is_open() == true then
        util.toast("Macro is Ready. Close Stand and it will Immediately Run.")
        while menu.is_open ~= false do
            if menu.is_open() == false then
                if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Call Pegasus' has Started.") end
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(27, 27, 1.0) ; util.yield(500) --Press 'Up' to Open Phone
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(172, 172, 1.0) ; util.yield(50) --Press 'Up'
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(175, 175, 1.0) ; util.yield(macroDelay) --Press 'Right'
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
                for i=1, 10, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(181, 181, 1.0) ; if i ~= 11 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Up' 10 Times
                PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) --Press 'Enter'
                if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Call Pegasus' has Finished.") end
                break
            end
            util.yield()
        end
    else
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Call Pegasus' has Started.") end
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(27, 27, 1.0) ; util.yield(500) --Press 'Up' to Open Phone
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(172, 172, 1.0) ; util.yield(50) --Press 'Up'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(175, 175, 1.0) ; util.yield(macroDelay) --Press 'Right'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
        for i=1, 10, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(181, 181, 1.0) ; if i ~= 11 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Up' 10 Times
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) --Press 'Enter'
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Call Pegasus' has Finished.") end
    end
end)

menu.action(MenuGameRunMacrosServ, "Request MOC", {"csmacrossmoc"}, "Runs a Macro that will Call your Mobile Operations Centre.", function(on_click)
    local typeOfCEO = getPlayerRegType(players.user())
    if typeOfCEO == -1 then
        util.yield(macroRunDelay)
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Request MOC' has Started.") end
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(244, 244, 1.0) ; util.yield(macroDelay) --Press 'M'
        for i=1, 5, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; if i ~= 6 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Down' 5 Times
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; util.yield(macroDelay) -- Press 'Down'
        for i=1, 2, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay) end --Press 'Enter' 2 Times
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Request MOC' has Finished.") end
    elseif typeOfCEO == 0 or typeOfCEO == 1 then
        util.yield(macroRunDelay)
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Request MOC' has Started.") end
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(244, 244, 1.0) ; util.yield(macroDelay) --Press 'M'
        for i=1, 6, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; if i ~= 7 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Down' 6 Times
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; util.yield(macroDelay) -- Press 'Down'
        for i=1, 2, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay) end --Press 'Enter' 2 Times
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Request MOC' has Finished.") end
    end
end)

menu.action(MenuGameRunMacrosServ, "Request Avenger", {"csmacrosavenger"}, "Rans a Macro that will Call your Avenger.", function(on_click)
    local typeOfCEO = getPlayerRegType(players.user())
    if typeOfCEO == -1 then
        util.yield(macroRunDelay)
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Request Avenger' has Started.") end
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(244, 244, 1.0) ; util.yield(macroDelay) --Press 'M'
        for i=1, 5, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; if i ~= 6 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Down' 5 Times
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
        for i=1, 2, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; if i ~= 3 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end -- Press 'Down' 2 Times
        for i=1, 2, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay) end --Press 'Enter' 2 Times
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Request Avenger' has Finished.") end
    elseif typeOfCEO == 0 or typeOfCEO == 1 then
        util.yield(macroRunDelay)
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Request Avenger' has Started.") end
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(244, 244, 1.0) ; util.yield(macroDelay) --Press 'M'
        for i=1, 6, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; if i ~= 7 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Down' 6 Times
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
        for i=1, 2, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; if i ~= 3 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end -- Press 'Down' 2 Times
        for i=1, 2, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay) end --Press 'Enter' 2 Times
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Request Avenger' has Finished.") end
    end
end)

menu.action(MenuGameRunMacrosServ, "Request Terrobyte", {"csmacrosterrobyte"}, "Rans a Macro that will Call your Terrobyte.", function(on_click)
    local typeOfCEO = getPlayerRegType(players.user())
    if typeOfCEO == -1 then
        util.yield(macroRunDelay)
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Request Terrobyte' has Started.") end
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(244, 244, 1.0) ; util.yield(macroDelay) --Press 'M'
        for i=1, 5, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; if i ~= 6 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Down' 5 Times
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
        for i=1, 3, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; if i ~= 4 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end -- Press 'Down' 3 Times
        for i=1, 2, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay) end --Press 'Enter' 2 Times
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Request Terrobyte' has Finished.") end
    elseif typeOfCEO == 0 or typeOfCEO == 1 then
        util.yield(macroRunDelay)
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Request Terrobyte' has Started.") end
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(244, 244, 1.0) ; util.yield(macroDelay) --Press 'M'
        for i=1, 6, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; if i ~= 7 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Down' 6 Times
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
        for i=1, 3, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; if i ~= 4 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end -- Press 'Down' 3 Times
        for i=1, 2, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay) end --Press 'Enter' 2 Times
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Request Terrobyte' has Finished.") end
    end
end)    

menu.action(MenuGameRunMacrosServ, "Request Kosatka", {"csmacroskosatka"}, "Runs a Macro that will Call your Kosatka.", function(on_click)
    local typeOfCEO = getPlayerRegType(players.user())
    if typeOfCEO == -1 then
        util.yield(macroRunDelay)
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Request Kosatka' has Started.") end
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(244, 244, 1.0) ; util.yield(macroDelay) --Press 'M'
        for i=1, 5, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; if i ~= 6 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Down' 5 Times
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(172, 172, 1.0) ; util.yield(macroDelay) -- Press 'Up'
        for i=1, 2, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay) end --Press 'Enter' 2 Times
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Request Kosatka' has Finished.") end
    elseif typeOfCEO == 0 or typeOfCEO == 1 then
        util.yield(macroRunDelay)
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Request Kosatka' has Started.") end
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(244, 244, 1.0) ; util.yield(macroDelay) --Press 'M'
        for i=1, 6, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; if i ~= 7 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Down' 6 Times
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(172, 172, 1.0) ; util.yield(macroDelay) -- Press 'Up'
        for i=1, 2, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay) end --Press 'Enter' 2 Times
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Request Kosatka' has Finished.") end
    end
end)

menu.action(MenuGameRunMacrosMisc, "Activate Thermal Helmet", {"csmacrosthermal"}, "Runs a Macro that will Activate the Thermal Helmet if it is Down.", function(on_click)
    local typeOfCEO = getPlayerRegType(players.user())
    if typeOfCEO == -1 then
        util.yield(macroRunDelay)
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Activate Thermal Helmet' has Started.") end
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(244, 244, 1.0) ; util.yield(macroDelay) --Press 'M'
        for i=1, 3, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; if i ~= 4 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Down' 3 Times  
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; util.yield(macroDelay) --Press 'Down'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay) --Press 'Enter'
        for i=1, 4, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; if i ~= 5 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Down' 4 Times 
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(179, 179, 1.0) ; util.yield(macroDelay) --Press 'Space'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(244, 244, 1.0) --Press 'M'
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Activate Thermal Helmet' has Finished.") end
    elseif typeOfCEO == 0 or 1 then
        util.yield(macroRunDelay)
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Activate Thermal Helmet' has Started.") end
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(244, 244, 1.0) ; util.yield(macroDelay) --Press 'M'
        for i=1, 4, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; if i ~= 5 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Down' 4 Times 
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay - 10) --Press 'Enter'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; util.yield(macroDelay) --Press 'Down'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(176, 176, 1.0) ; util.yield(macroDelay) --Press 'Enter'
        for i=1, 4, 1 do PAD.SET_CONTROL_VALUE_NEXT_FRAME(173, 173, 1.0) ; if i ~= 5 then util.yield(macroDelay - 20) else util.yield(macroDelay) end end --Press 'Down' 4 Times 
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(179, 179, 1.0) ; util.yield(macroDelay) --Press 'Space'
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(244, 244, 1.0) --Press 'M'
        if macroAnnounceEnds then util.toast("-Chalkscript-\n\nMacro 'Activate Thermal Helmet' has Finished.") end
    end
end)



--[[| Chalkscript/ |]]--
menu.divider(MenuCredits, "--- MAIN DEVELOPERS ---")

menu.action(MenuCredits, "Гадюка#3642", {"cscreditsviper"}, "This is Me, and I did Everything, from Scratch.", function(on_click)
    util.toast("- Гадюка#3642 -\n\nThis is Me, and I did Everything, from Scratch.")
end)

menu.divider(MenuCredits, "--- GAVE IDEAS ---")

menu.action(MenuCredits, "N0VA#0003", {"cscreditsnova"}, "My Best Friend, just Gave Me a Handful of Ideas to Add to the Script.", function(on_click)
    util.toast(" - N0VA#0003 -\n\nMy Best Friend, just Gave Me a Handful of Ideas to Add to the Script.")
end)

menu.action(MenuCredits, "Nekuuu#2010", {"cscreditsnekuuuuu"}, "Another Best Friend of Mine, also gave me some Ideas on what to Add to the Script.", function(on_click)
    util.toast(" - Nekuuu#2010 -\n\nAnother Best Friend of Mine, also gave me some Ideas on what to Add to the Script.")
end)


--[[| Chalkscript/Credits/ |]]--
menu.divider(MenuMisc, "--- Patch Notes ---")

menu.action(MenuMisc, "Patch Notes", {"cspatchnotes"}, "Toast Everything New that I've Added to the Script.", function(on_click)
    util.toast("-Chalkscript-\n\n-Fixed-\n"..PatchNoteFixed.."\n\n-Added-\n"..PatchNoteAdded)
end)




--[[ ||| PLAYER ROOT ||| ]]--
function PlayerAddRoot(csPID)
    menu.divider(menu.player_root(csPID), "============ Chalkscript ============")
    MenuPlayerRoot = menu.list(menu.player_root(csPID), "Chalkscript", {"csplayer"}, "Chalkscript Options for Selected Player.") ; menu.divider(MenuPlayerRoot, "--- Player Options ---")
    menu.divider(menu.player_root(csPID), "==========^^ Chalkscript ^^==========")
        
    MenuPlayerFriendly = menu.list(MenuPlayerRoot, "Friendly", {"csplayerfriendly"}, "Chalkscript Friendly Options for the Selected Player.") ; menu.divider(MenuPlayerFriendly, "--- Player Friendly Options ---") 
    MenuPlayerFun = menu.list(MenuPlayerRoot, "Fun", {"csplayerfun"}, "Chalkscript Fun Options for the Selected Player.") ; menu.divider(MenuPlayerFun, "--- Player Fun Options ---")    
    MenuPlayerTrolling = menu.list(MenuPlayerRoot, "Trolling", {"csplayertrolling"}, "Chalkscript Trolling Options for the Selected Player.") ; menu.divider(MenuPlayerTrolling, "--- Player Trolling Options ---")  
        MenuPlayerTrollingSpawn = menu.list(MenuPlayerTrolling, "Spawn Options", {"cstrolling"}, "Trolling Options that Involve Spawning things.") ; menu.divider(MenuPlayerTrollingSpawn, "--- Trolling Spawn Options ---")  
        MenuPlayerTrollingCage = menu.list(MenuPlayerTrolling, "Cage Options", {"csplayertrollingcage"}, "Different Types of Cages to put this Player in.") ; menu.divider(MenuPlayerTrollingCage, "--- Trolling Cage Options ---")
        MenuPlayerTrollingFreeze = menu.list(MenuPlayerTrolling, "Freeze Options", {"csplayertrollingfreeze"}, "Freeze Options for this Player.") ; menu.divider(MenuPlayerTrollingFreeze, "--- Trolling Freeze Options ---")
    MenuPlayerKilling = menu.list(MenuPlayerRoot, "Killing", {"csplayerkilling"}, "Chalkscript Killing Options for the Selected Player.") ; menu.divider(MenuPlayerKilling, "--- Player Killing Options ---")    
        MenuPlayerKillingOwned = menu.list(MenuPlayerKilling, "Owned", {"csplayerkillingowned"}, "Shows that you Killed them in the Killfeed.") ; menu.divider(MenuPlayerKillingOwned, "--- Owned Killing Options ---")
        MenuPlayerKillingAnon = menu.list(MenuPlayerKilling, "Anonymous", {"csplayerkillinganon"}, "Just says they Died in the Killfeed.") ; menu.divider(MenuPlayerKillingAnon, "--- Anonymous Killing Options ---")
    MenuPlayerRemoval = menu.list(MenuPlayerRoot, "Removal", {"csplayerremoval"}, "Chalkscript Removal Options for the Selected Player, like Kicks and Crashes.") ; menu.divider(MenuPlayerRemoval, "--- Player Removal Options ---")
        MenuPlayerRemovalKick = menu.list(MenuPlayerRemoval, "Kicks", {"csplayerremovalkick"}, "Kick Options for this Player.") ; menu.divider(MenuPlayerRemovalKick, "--- Player Kick Options ---")
        MenuPlayerRemovalCrash = menu.list(MenuPlayerRemoval, "Crashes", {"csplayerremovalcrash"}, "Crash Options for this Player.") ; menu.divider(MenuPlayerRemovalCrash, "--- Player Crash Options ---")
    


    --Player Root Friendly

    menu.toggle_loop(MenuPlayerFriendly, "Give Vehicle Stealth Godmode", {"csfriendlygivevehstealthgm"}, "Gives the Player Vehicle Godmode that won't be Detected by Most menus.", function()
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
        ENTITY.SET_ENTITY_PROOFS(PED.GET_VEHICLE_PED_IS_IN(pidPed), true, true, true, true, true, false, false, true)
        end, function() 
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
        ENTITY.SET_ENTITY_PROOFS(PED.GET_VEHICLE_PED_IS_IN(pidPed), false, false, false, false, false, false, false, false)
    end)


    --Player Root Fun

    menu.action(MenuPlayerFun, "Custom Job Invite", {"csfunjobinv"}, "Sends the Player a Notification that says you Started the a Job, with the Name of it being the Text you Input.", function(on_click)
        menu.show_command_box_click_based(on_click, "csfunjobinv "..players.get_name(csPID):lower().." ") end, function(input)
            local event_data = {0x8E38E2DF, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
            input = input:sub(1, 127)
            for i = 0, #input -1 do
                local slot = i // 8
                local byte = string.byte(input, i + 1)
                event_data[slot + 3] = event_data[slot + 3] | byte << ((i-slot * 8)* 8)
            end
            util.trigger_script_event(1 << csPID, event_data)
    end)

    menu.action(MenuPlayerFun, "Custom Text / Label", {"csfunlabel"}, "Sends the Person a Preset Text, since you can't just Send normal Texts on PC. Check the Hyperlink below for all Labels.", function() menu.show_command_box("csplayerfunct "..players.get_name(csPID).." ") end, function(label)
        local event_data = {0xD0CCAC62, players.user(), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
        local out = label:sub(1, 127)
        if HUD.DOES_TEXT_LABEL_EXIST(label) then
            for i = 0, #out -1 do
                local slot = i // 8
                local byte = string.byte(out, i + 1)
                event_data[slot + 3] = event_data[slot + 3] | byte << ( (i - slot * 8) * 8)
            end
            util.trigger_script_event(1 << csPID, event_data)
        else
            util.toast("-Chalkscript-\n\nThat is not a Valid Label. No Texts have been Sent.")
        end
    end)

    menu.hyperlink(MenuPlayerFun, "Text / Label List", "https://gist.githubusercontent.com/aaronlink127/afc889be7d52146a76bab72ede0512c7/raw")


    --Player Root Trolling

        --Trolling Spawn Options

    menu.action(MenuPlayerTrollingSpawn, "Drop Taco Truck", {"csplayertrollingspawndtt"}, "Drops a Taco Truck on the Player's Head.", function(on_click)
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
        local abovePidPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, 10)
        local vehHash = util.joaat("taco")
        STREAMING.REQUEST_MODEL(vehHash)
        while not STREAMING.HAS_MODEL_LOADED(vehHash) do util.yield() end
        local spawnedTruck = VEHICLE.CREATE_VEHICLE(vehHash, abovePidPed.x, abovePidPed.y, abovePidPed.z, 0, true, true, false)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(vehHash)
        util.yield(3000)
        entities.delete_by_handle(spawnedTruck)
    end)

        --Trolling Cage Options

    menu.action(MenuPlayerTrollingCage, "Electric Cage", {"csplayertrollingcageec"}, "A Cage made of Transistors, that will Taze the Player.", function(on_click)
        local number_of_cages = 6
        local elec_box = util.joaat("prop_elecbox_12")
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = ENTITY.GET_ENTITY_COORDS(ped)
        pos.z = pos.z - 0.5
        request_model(elec_box)
        local temp_v3 = v3.new(0, 0, 0)
        for i = 1, number_of_cages do
            local angle = (i / number_of_cages) * 360
            temp_v3.z = angle
            local obj_pos = temp_v3:toDir()
            obj_pos:mul(2.5)
            obj_pos:add(pos)
            for offs_z = 1, 5 do
                local electric_cage = entities.create_object(elec_box, obj_pos)
                spawned_objects[#spawned_objects + 1] = electric_cage
                ENTITY.SET_ENTITY_ROTATION(electric_cage, 90.0, 0.0, angle, 2, 0)
                obj_pos.z = obj_pos.z + 0.75
                ENTITY.FREEZE_ENTITY_POSITION(electric_cage, true)
            end
        end
    end)

    menu.action(MenuPlayerTrollingCage, "Coffin Cage", {"csplayertrollingcagecc"}, "Spawns 6 Coffins around the Player.", function(on_click)
        local number_of_cages = 6
        local coffin_hash = util.joaat("prop_coffin_02b")
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = ENTITY.GET_ENTITY_COORDS(ped)
        request_model(coffin_hash)
        local temp_v3 = v3.new(0, 0, 0)
        for i = 1, number_of_cages do
            local angle = (i / number_of_cages) * 360
            temp_v3.z = angle
            local obj_pos = temp_v3:toDir()
            obj_pos:mul(0.8)
            obj_pos:add(pos)
            obj_pos.z = obj_pos.z + 0.1
           local coffin = entities.create_object(coffin_hash, obj_pos)
           spawned_objects[#spawned_objects + 1] = coffin
           ENTITY.SET_ENTITY_ROTATION(coffin, 90.0, 0.0, angle,  2, 0)
           ENTITY.FREEZE_ENTITY_POSITION(coffin, true)
        end
    end)


    menu.action(MenuPlayerTrollingCage, "Shipping Container Cage", {"csplayertrollingcagescc"}, "Spawns a Shipping Container on the Player.", function(on_click)
        local container_hash = util.joaat("prop_container_ld_pu")
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = ENTITY.GET_ENTITY_COORDS(ped)
        request_model(container_hash)
        pos.z = pos.z - 1
        local container = entities.create_object(container_hash, pos, 0)
        spawned_objects[#spawned_objects + 1] = container
        ENTITY.FREEZE_ENTITY_POSITION(container, true)
    end)

    menu.action(MenuPlayerTrollingCage, "Box Truck Cage", {"csplayertrollingcagebtc"}, "Spawns a Box Truck on the Player.", function(on_click)
        local container_hash = util.joaat("boxville3")
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local pos = ENTITY.GET_ENTITY_COORDS(ped)
        request_model(container_hash)
        local container = entities.create_vehicle(container_hash, ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.0, 2.0, 0.0), ENTITY.GET_ENTITY_HEADING(ped))
        spawned_objects[#spawned_objects + 1] = container
        ENTITY.SET_ENTITY_VISIBLE(container, false)
        ENTITY.FREEZE_ENTITY_POSITION(container, true)
    end)

    menu.action(MenuPlayerTrollingCage, "Delete Spawned Cages", {"csplayertrollingcagedsc"}, "Deletes all the Cages that you have Spawned.", function(on_click)
        local entitycount = 0
        for i, object in ipairs(spawned_objects) do
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(object, false, false)
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(object)
            entities.delete_by_handle(object)
            spawned_objects[i] = nil
            entitycount = entitycount + 1
        end
        util.toast("-Chalkscript-\n\nCleared " .. entitycount .. " Cages that you have Sawned.")
    end) 

        --Trolling Freze Options

    player_toggle_loop(MenuPlayerTrollingFreeze, csPID, "Hard Freeze", {"csplayertrollingfreezehf"}, "Runs a Script Event that Freezes the Player Repeatedly.", function(on)
        util.trigger_script_event(1 << csPID, {0x4868BC31, csPID, 0, 0, 0, 0, 0})
        util.yield(500)
    end)

    player_toggle_loop(MenuPlayerTrollingFreeze, csPID, "Phase Freeze", {"csplayertrollingfreezepf"}, "Runs a On Tick Freeze Event, so the Person is still Able to Move a Little.", function(on)
        util.trigger_script_event(1 << csPID, {0x7EFC3716, csPID, 0, 1, 0, 0})
        util.yield(500)
    end)

    player_toggle_loop(MenuPlayerTrollingFreeze, csPID, "Clear Tasks", {"csplayertrollingfreezect"}, "Clears all Tasks from the Player Ped every Tick, which Results in a Freeze.", function(on)
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(pidPed)
    end)


    --Player Root Killing

        -- Owned Killing Options --

    menu.action(MenuPlayerKillingOwned, "Snipe Player", {"csplayerkillingownedsnipe"}, "Spawns a Bullet Right in Front of the Player. Can be used to 'Snipe' People out of Cars or Jets.", function(on_click)
        menu.trigger_command(menu.ref_by_path("Players>"..players.get_name_with_tags(csPID)..">Spectate>Legit Method", 33))
        util.yield(500)
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
        local onPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, .5)
        local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 5, 1)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 350, true, 205991906, players.user_ped(), true, false, 100) --205991906 is Heavy Sniper 
        menu.trigger_command(menu.ref_by_path("Players>"..players.get_name_with_tags(csPID)..">Spectate>Legit Method", 33))
        util.yield(500)
    end)

    menu.action(MenuPlayerKillingOwned, "Snipe Player V2", {"csplayerkillingownedsnipe2"}, "Spawns 10 Bullets almost in the Player in Slightly Incrementing Distances, so it Rarely Misses.", function(on_click)
        menu.trigger_command(menu.ref_by_path("Players>"..players.get_name_with_tags(csPID)..">Spectate>Legit Method", 33))
        util.yield(500)
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
        local onPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, .5)
        local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, .3, .9)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 350, true, 205991906, players.user_ped(), true, false, 100) --205991906 is Heavy Sniper 
        local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, .4, .8)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 350, true, 205991906, players.user_ped(), true, false, 100) --205991906 is Heavy Sniper 
        local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, .5, .7)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 350, true, 205991906, players.user_ped(), true, false, 100) --205991906 is Heavy Sniper 
        local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, .5, .6)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 350, true, 205991906, players.user_ped(), true, false, 100) --205991906 is Heavy Sniper 
        local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, .5, .5)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 350, true, 205991906, players.user_ped(), true, false, 100) --205991906 is Heavy Sniper 
        local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 1, .9)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 350, true, 205991906, players.user_ped(), true, false, 100) --205991906 is Heavy Sniper 
        local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 2, .8)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 350, true, 205991906, players.user_ped(), true, false, 100) --205991906 is Heavy Sniper 
        local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 3, .7)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 350, true, 205991906, players.user_ped(), true, false, 100) --205991906 is Heavy Sniper 
        local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 4, .6)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 350, true, 205991906, players.user_ped(), true, false, 100) --205991906 is Heavy Sniper 
        local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 5, .5)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 350, true, 205991906, players.user_ped(), true, false, 100) --205991906 is Heavy Sniper 
        menu.trigger_command(menu.ref_by_path("Players>"..players.get_name_with_tags(csPID)..">Spectate>Legit Method", 33))
        util.yield(500)
    end)

    menu.action(MenuPlayerKillingOwned, "Airstrike Player", {"csplayerkillingownedairstrike"}, "Shoots 8 Rockets at them from the Sky.", function(on_click)
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
        local abovePed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, 50)
        local abovePed2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, 15)
        local onPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, .5)
        local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 3, 1)
        local frontOfPed2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 5, 1)
        local backOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, -3, 1)
        local backOfPed2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, -5, 1)
        local rightOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 3, 0, 1)
        local rightOfPed2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 5, 0, 1)
        local leftOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, -3, 0, 1)
        local leftOfPed2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, -5, 0, 1)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed2.x, abovePed2.y, abovePed2.z, onPed.x, onPed.y, onPed.z, 100, true, 1233104067, players.user_ped(), true, false, 100) --1233104067 is Flare
        util.yield(5000)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, backOfPed.x, backOfPed.y, backOfPed.z, 100, true, 1752584910, players.user_ped(), true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, leftOfPed.x, leftOfPed.y, leftOfPed.z, 100, true, 1752584910, players.user_ped(), true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, frontOfPed.x, frontOfPed.y, frontOfPed.z, 100, true, 1752584910, players.user_ped(), true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, rightOfPed.x, rightOfPed.y, rightOfPed.z, 100, true, 1752584910, players.user_ped(), true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, backOfPed2.x, backOfPed2.y, backOfPed2.z, 100, true, 1752584910, players.user_ped(), true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, leftOfPed2.x, leftOfPed2.y, leftOfPed2.z, 100, true, 1752584910, players.user_ped(), true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, frontOfPed2.x, frontOfPed2.y, frontOfPed2.z, 100, true, 1752584910, players.user_ped(), true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, rightOfPed2.x, rightOfPed2.y, rightOfPed2.z, 100, true, 1752584910, players.user_ped(), true, false, 250) --1752584910 is Homing Missle
    end)
    

        -- Anonymous Killing Options --

    menu.action(MenuPlayerKillingAnon, "Snipe Player", {"csplayerkillinganonsnipe"}, "Spawns a Bullet Right in Front of the Player. Can be used to 'Snipe' People out of Cars or Jets.", function(on_click)
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
        for k, ent in pairs(entities.get_all_peds_as_handles()) do
            if not PED.IS_PED_A_PLAYER(ent) and ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY(ent, pidPed, 17) then
                local onPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, .5)
                local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 5, 1)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 3500, true, 205991906, ent, true, false, 100) --205991906 is Heavy Sniper 
                break
            end
        end
    end)

    menu.action(MenuPlayerKillingAnon, "Snipe Player V2", {"csplayerkillinganonsnipe2"}, "Spawns 10 Bullets almost in the Player in Slightly Incrementing Distances, so it Rarely Misses.", function(on_click)
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
        for k, ent in pairs(entities.get_all_peds_as_handles()) do
            if not PED.IS_PED_A_PLAYER(ent) and ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY(ent, pidPed, 17) then
                local onPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, .5)
                local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, .3, .9)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 3500, true, 205991906, ent, true, false, 100) --205991906 is Heavy Sniper 
                local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, .4, .8)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 3500, true, 205991906, ent, true, false, 100) --205991906 is Heavy Sniper 
                local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, .5, .7)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 3500, true, 205991906, ent, true, false, 100) --205991906 is Heavy Sniper 
                local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, .5, .6)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 3500, true, 205991906, ent, true, false, 100) --205991906 is Heavy Sniper 
                local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, .5, .5)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 3500, true, 205991906, ent, true, false, 100) --205991906 is Heavy Sniper 
                local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 1, .9)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 3500, true, 205991906, ent, true, false, 100) --205991906 is Heavy Sniper 
                local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 2, .8)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 3500, true, 205991906, ent, true, false, 100) --205991906 is Heavy Sniper 
                local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 3, .7)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 3500, true, 205991906, ent, true, false, 100) --205991906 is Heavy Sniper 
                local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 4, .6)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 3500, true, 205991906, ent, true, false, 100) --205991906 is Heavy Sniper 
                local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 5, .5)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 3500, true, 205991906, ent, true, false, 100) --205991906 is Heavy Sniper 
                break
            end
        end
    end)

    menu.action(MenuPlayerKillingAnon, "Airstrike Player", {"csplayerkillinganonairstrike"}, "Shoots 8 Rockets at them from the Sky.", function(on_click)
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
        local abovePed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, 50)
        local abovePed2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, 15)
        local onPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, .5)
        local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 3, 1)
        local frontOfPed2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 5, 1)
        local backOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, -3, 1)
        local backOfPed2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, -5, 1)
        local rightOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 3, 0, 1)
        local rightOfPed2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 5, 0, 1)
        local leftOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, -3, 0, 1)
        local leftOfPed2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, -5, 0, 1)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed2.x, abovePed2.y, abovePed2.z, onPed.x, onPed.y, onPed.z, 100, true, 1233104067, 0, true, false, 100) --1233104067 is Flare
        util.yield(5000)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, backOfPed.x, backOfPed.y, backOfPed.z, 100, true, 1752584910, 0, true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, leftOfPed.x, leftOfPed.y, leftOfPed.z, 100, true, 1752584910, 0, true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, frontOfPed.x, frontOfPed.y, frontOfPed.z, 100, true, 1752584910, 0, true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, rightOfPed.x, rightOfPed.y, rightOfPed.z, 100, true, 1752584910, 0, true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, backOfPed2.x, backOfPed2.y, backOfPed2.z, 100, true, 1752584910, 0, true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, leftOfPed2.x, leftOfPed2.y, leftOfPed2.z, 100, true, 1752584910, 0, true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, frontOfPed2.x, frontOfPed2.y, frontOfPed2.z, 100, true, 1752584910, 0, true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, rightOfPed2.x, rightOfPed2.y, rightOfPed2.z, 100, true, 1752584910, 0, true, false, 250) --1752584910 is Homing Missle
    end)


    --Player Root Removals

        --Player Removal Kicks

    menu.action(MenuPlayerRemovalKick, "Freemode Death Kick", {"csplayerremovalkickfd"}, "Kills their Freemode using a Script Event and sends them back to Story Mode.", function(on_click)
        util.trigger_script_event(1 << csPID, {111242367, csPID, memory.script_global(2689235 + 1 + (csPID * 453) + 318 + 7)})
    end)

    menu.action(MenuPlayerRemovalKick, "Network Bail Kick", {"csplayerremovalkicknb"}, "Uses Script Events to Initiate a Network Bail on their Game.", function(on_click)
        util.trigger_script_event(1 << csPID, {0x63D4BFB1, players.user(), memory.read_int(memory.script_global(0x1CE15F + 1 + (csPID * 0x257) + 0x1FE))})
    end)

    menu.action(MenuPlayerRemovalKick, "Invalid Collectible Kick", {"csplayerremovalkickic"}, "Spawns an Invalid Collectible which in turn, Kicks them.", function()
        util.trigger_script_event(1 << csPID, {0xB9BA4D30, csPID, 0x4, -1, 1, 1, 1})
    end)

    if menu.get_edition() >= 2 then 
        menu.action(MenuPlayerRemovalKick, "Adaptive Kick", {"csplayerremovalkickak"}, "Multiple Kicks in One. This has Breakup Kick added since you have Stand Regular!", function(on_click)
            util.trigger_script_event(1 << csPID, {0xB9BA4D30, csPID, 0x4, -1, 1, 1, 1})
            util.trigger_script_event(1 << csPID, {0x6A16C7F, csPID, memory.script_global(0x2908D3 + 1 + (csPID * 0x1C5) + 0x13E + 0x7)})
            util.trigger_script_event(1 << csPID, {0x63D4BFB1, players.user(), memory.read_int(memory.script_global(0x1CE15F + 1 + (csPID * 0x257) + 0x1FE))})
            menu.trigger_commands("breakup" .. players.get_name(csPID))
        end)
    else
        menu.action(MenuPlayerRemovalKick, "Adaptive Kick", {"csplayerremovalkickak"}, "Multiple Kicks in One.", function(on_click)
            util.trigger_script_event(1 << csPID, {0xB9BA4D30, csPID, 0x4, -1, 1, 1, 1})
            util.trigger_script_event(1 << csPID, {0x6A16C7F, csPID, memory.script_global(0x2908D3 + 1 + (csPID * 0x1C5) + 0x13E + 0x7)})
            util.trigger_script_event(1 << csPID, {0x63D4BFB1, csPIDyers.user(), memory.read_int(memory.script_global(0x1CE15F + 1 + (csPID * 0x257) + 0x1FE))})
        end)
    end

    if menu.get_edition() >= 2 then 
        menu.action(MenuPlayerRemovalKick, "Block Join Kick", {"csplayerremovalkickbj"}, "Breakup Kick them, then add 'Block Joins' to thim in your History, so they can Never Join your Game Again.", function(on_click)
            menu.trigger_commands("historyblock " .. players.get_name(csPID))
            menu.trigger_commands("breakup" .. players.get_name(csPID))
        end)
    end

        --Player Removal Crashes

    menu.action(MenuPlayerRemovalCrash, "Invalid Model Crash", {"csplayerremovalcrashim"}, "Does some Crazy things with a Poodle Model that Results in a Crash for that player.", function(on_click)
        local mdl = util.joaat('a_c_poodle')
        BlockSyncs(csPID, function()
            if request_model(mdl, 2) then
                local pos = players.get_position(csPID)
                util.yield(100)
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
                ped1 = entities.create_ped(26, mdl, ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.GET_PLAYER_PED(csPID), 0, 3, 0), 0) 
                local coords = ENTITY.GET_ENTITY_COORDS(ped1, true)
                WEAPON.GIVE_WEAPON_TO_PED(ped1, util.joaat('WEAPON_HOMINGLAUNCHER'), 9999, true, true)
                local obj
                repeat
                    obj = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(ped1, 0)
                until obj ~= 0 or util.yield()
                ENTITY.DETACH_ENTITY(obj, true, true) 
                util.yield(1500)
                FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, 0, 1.0, false, true, 0.0, false)
                entities.delete_by_handle(ped1)
                util.yield(1000)
            else
                util.toast("Failed to load model. :/")
            end
        end)
    end)

    menu.action(MenuPlayerRemovalCrash, "Fragment Crash", {"csplayerremovalcrashf"}, "Uses Function 'BREAK_OBJECT_FRAGMENT_CHILD' to Crash the Player.", function(on_click)
        BlockSyncs(csPID, function()
            local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)))
            OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
            util.yield(1000)
            entities.delete_by_handle(object)
        end)
    end)    

    menu.action(MenuPlayerRemovalCrash, "Script Event Overflow Crash", {"csplayerremovalcrashseo"}, "Spams the Player with Big Script Events a Ton which Crashes their Game.", function(on_click)
        local int_min = -2147483647
        local int_max = 2147483647
        for i = 1, 150 do
            util.trigger_script_event(1 << csPID, {2765370640, csPID, 3747643341, math.random(int_min, int_max), math.random(int_min, int_max), 
            math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max),
            math.random(int_min, int_max), csPID, math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max)})
        end
        util.yield()
        for i = 1, 15 do
            util.trigger_script_event(1 << csPID, {1348481963, csPID, math.random(int_min, int_max)})
        end
        menu.trigger_commands("givesh " .. players.get_name(csPID))                                                             
        util.yield(100)
        util.trigger_script_event(1 << csPID, {495813132, csPID, 0, 0, -12988, -99097, 0})
        util.trigger_script_event(1 << csPID, {495813132, csPID, -4640169, 0, 0, 0, -36565476, -53105203})
        util.trigger_script_event(1 << csPID, {495813132, csPID,  0, 1, 23135423, 3, 3, 4, 827870001, 5, 2022580431, 6, -918761645, 7, 1754244778, 8, 827870001, 9, 17})
    end)
end

players.on_join(PlayerAddRoot)
players.dispatch_on_join()




--  ||| MAIN TICK LOOP ||| --
local last_car = 0
while true do
    player_cur_car = entities.get_user_vehicle_as_handle()
    if last_car ~= player_cur_car and player_cur_car ~= 0 then 
        on_user_change_vehicle(player_cur_car)
        last_car = player_cur_car
    end
    util.yield()
end
util.keep_running()
