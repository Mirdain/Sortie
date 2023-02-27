_addon.name = 'Sortie'
_addon.author = 'Mirdain'
_addon.version = '2.1 Windower'
_addon_description = 'Helps complete objectives in Sortie'
_addon.commands = {'sortie','st'}

packets = require 'packets'
config = require 'config'
res = require 'resources'
texts = require 'texts'

require 'tables'
require 'strings'


default = {
    debug = false,
    Tracking_Box = {text={size=10,font='Consolas',red=255,green=255,blue=255,alpha=255},pos={x=1313,y=623},bg={visible=true,red=0,green=0,blue=0,alpha=102},},
    Floor = {text={size=13,font='Consolas',red=255,green=255,blue=255,alpha=255},pos={x=1313,y=595},bg={visible=true,red=0,green=0,blue=0,alpha=102},},
    }

-- Loads the default settings (Display.lua)
settings = config.load(default)
mob_tracking = {}
interval = .25
enabled = false
UpdateTime = os.clock()
location = "A"

gears = {'|','/','-','\\\\'} 
gear = 1

tracking_window = texts.new("",settings.Tracking_Box)
floor_window = texts.new("[A] [B] [C] [D] [E] [F] [G] [H]",settings.Floor)

windower.register_event('prerender',function()
    local now = os.clock()
    if now - UpdateTime > interval and enabled then
        UpdateTime = now
        tracking_box_update() -- Update UI
    end
end)

--Commands recieved and sent to addon
windower.register_event('addon command', function(input, ...)
    local args = L{...}
    commands(input,args)
end)

windower.register_event('zone change', function()
    local world = windower.ffxi.get_info()
    initalize()
    if world.zone == 133 or world.zone == 189 then
        coroutine.sleep(4)
        show_UI()
        enabled = true
        log('Zoned into Outer Ra\'Kaznar [U2]')
    else
        hide_UI()
        enabled = false
        log('Wrong Zone (Sortie)')
    end
end)

windower.register_event('load', function()
    local world = windower.ffxi.get_info()
    initalize()
    if world.zone == 133 or world.zone == 189 then
        enabled = true
        show_UI()
        log('Zoned is Outer Ra\'Kaznar [U2]')
    else
        hide_UI()
        enabled = false
        log('Wrong Zone (Sortie)')
    end
end)

windower.register_event('incoming chunk', function(id, original, modified, injected, blocked)
    if id == 0x0F4 and enabled then -- widescan Mob (not used now)
        local packet = packets.parse('incoming', original)
        log('Target ['..packet['Index']..']')
        for index, target in ipairs(mob_tracking) do
            if target.index == packet['Index'] then
                local distance = round((packet['X Offset']^2+packet['Y Offset']^2):sqrt(),1)
                if mob_tracking[index].distance ~= 'Dead' then
                    local enemy = windower.ffxi.get_mob_by_index(packet['Index'])
                    if enemy and (enemy.status == 2 or enemy.status == 3) then
                        log('Enemy dead')
                        mob_tracking[index].distance = 'Dead'
                    else
                        mob_tracking[index].distance = distance
                        windower.add_to_chat(8,'Targeting '..mob_tracking[index].name..' ['..packet['Index']..'] with range of ['..mob_tracking[index].distance..'] - Starting to track!')
                        track_on(packet['Index'])
                    end
                end
            end
        end
    elseif id == 0x0F5 and enabled then -- Widescan tracking packet received
        local packet = packets.parse('incoming', original)
        local player = windower.ffxi.get_mob_by_target('me')
        if packet['X'] and packet['Y'] and player then
            local distance = round(((player.x - packet['X'])^2 + (player.y - packet['Y'])^2):sqrt(),1)
            if packet['Index'] ~= 0 then
                log('Track: ['..packet['Index']..'] - ['..packet['X']..'] , ['..packet['Y']..'] and distance of ['..distance..']')
                for index, target in pairs(mob_tracking) do
                    if target.index == packet['Index'] then
                        if mob_tracking[index].distance ~= 'Dead' then
                            local enemy = windower.ffxi.get_mob_by_index(packet['Index'])
                            if enemy and (enemy.status == 2 or enemy.status == 3) then
                                mob_tracking[index].distance = 'Dead'
                                log('Enemy dead')
                            else
                                mob_tracking[index].distance = distance
                                --log('Distance updated')
                            end
                        end
                    end
                end
            else
                log('Packet was ['..packet['Index']..'] with distance of ['..distance..'] and is from server.')
            end
        else
            log("Enemy not found")
        end
    elseif id == 0x0F6 then -- Widescan Mark
        --log('widescan mark')
    end
end)

windower.register_event('outgoing chunk', function(id, original, modified, injected, blocked)
    if id == 0x0F4 then -- Widescan Request
        --log('widescan request')
   elseif id == 0x0F5 then -- Widescan Track
        --log('widescan track on')
   elseif id == 0x0F6 then -- Widescan Cancel
        --log('widescan Cancel')
    end
end)

-- Used to track mobs
function tracking_box_update()
    lines = T{}
    gear_update()
    -- Bizters are 806, 807, 808, and 809
    local bitzer_status = {}
    local maxWidth = 41
    local bitzer_distance = 0
    local player = windower.ffxi.get_mob_by_target('me')
    lines:insert("            Current Area ["..location.."]")
    lines:insert("")
    if location == "A" then
        --Top Floor A
        lines:insert(mob_tracking[1].name ..string.format('[%s]',tostring(mob_tracking[1].distance)):lpad(' ',maxWidth - string.len(mob_tracking[1].name)))
        lines:insert("")
        lines:insert("Casket #A1")
        lines:insert("  Kill 5x enemies")
        lines:insert("Casket #A2")
        lines:insert("  /heal past the #A1 gate")
        lines:insert("Coffer #A")
        lines:insert("  Kill Abject Obdella")
        lines:insert("Shard #A")
        lines:insert("  Magic kill 3x")
    elseif location == 'B' then
        -- Top Floor B
        lines:insert(mob_tracking[2].name ..string.format('[%s]',tostring(mob_tracking[2].distance)):lpad(' ',maxWidth - string.len(mob_tracking[2].name)))
        lines:insert("")
        lines:insert("Casket #B1")
        lines:insert("  Kill 3x Biune < 30 sec")
        lines:insert("Casket #B2")
        lines:insert("  Open a #B locked Gate")
        lines:insert("Coffer #B")
        lines:insert("  Kill Porxie after opening Casket #B1")
        lines:insert("Shard #B")
        lines:insert("  Kill 3x elementals in < 30 sec")
    elseif location == 'C' then
        -- Top Floor C
        lines:insert(mob_tracking[3].name ..string.format('[%s]',tostring(mob_tracking[3].distance)):lpad(' ',maxWidth - string.len(mob_tracking[3].name)))
        lines:insert("")
        lines:insert("Casket #C1")
        lines:insert("  Kill 3x enemies < 30 sec")
        lines:insert("Casket #C2")
        lines:insert("  Kill all enemies")
        lines:insert("Coffer #C")
        lines:insert("  Kill Cachaemic Bhoot < 5 min")
        lines:insert("Chest #C")
        lines:insert("  Do 3x Magic Bursts")
    elseif location == 'D' then
        -- Top Floor D
        lines:insert(mob_tracking[4].name ..string.format('[%s]',tostring(mob_tracking[4].distance)):lpad(' ',maxWidth - string.len(mob_tracking[4].name)))
        lines:insert("")
        lines:insert("Casket #D1")
        lines:insert("  Kill 6x Demisang of different jobs")
        lines:insert("Casket #D2")
        lines:insert("  WAR->MNK->WHM->BLM->RDM->THF")
        lines:insert("Coffer #D")
        lines:insert("  Kill 3x enemies after NM")
        lines:insert("Chest #D")
        lines:insert("  Do a 4-step skillchain 3x times")
    elseif location == 'E' then
        -- E Basement
        bitzer_status = windower.ffxi.get_mob_by_index(836)
        lines:insert(mob_tracking[5].name ..string.format('[%s]',tostring(mob_tracking[5].distance)):lpad(' ',maxWidth - string.len(mob_tracking[5].name)))
        if bitzer_status then
            bitzer_distance = round(((player.x - bitzer_status.x)^2 + (player.y - bitzer_status.y)^2):sqrt(),1)
            lines:insert(bitzer_status.name ..string.format('[%s]',tostring(bitzer_distance)):lpad(' ',maxWidth - string.len(bitzer_status.name)))
        end
        lines:insert("")
        lines:insert("Casket #E1")
        lines:insert("  All foes around bitzer (12x)")
        lines:insert("Casket #E2")
        lines:insert("  All flan (15x)")
        lines:insert("Coffer #E")
        lines:insert("  Kill all Naakuals")
        lines:insert("Chest #E")
        lines:insert("  Kill with WS from behind")
    elseif location == 'F' then
        -- F Basement
        bitzer_status = windower.ffxi.get_mob_by_index(837)
        lines:insert(mob_tracking[6].name ..string.format('[%s]',tostring(mob_tracking[6].distance)):lpad(' ',maxWidth - string.len(mob_tracking[6].name)))
        if bitzer_status then
            bitzer_distance = round(((player.x - bitzer_status.x)^2 + (player.y - bitzer_status.y)^2):sqrt(),1)
            lines:insert(bitzer_status.name ..string.format('[%s]',tostring(bitzer_distance)):lpad(' ',maxWidth - string.len(bitzer_status.name)))
        end
        lines:insert("")
        lines:insert("Casket #F1")
        lines:insert("  5/5 Empy gear at bitzer")
        lines:insert("Casket #F2")
        lines:insert("  Defeat all Veela")
        lines:insert("Coffer #F")
        lines:insert("  Kill all Naakuals")
        lines:insert("Chest #F")
        lines:insert("  ???")
    elseif location == 'G' then
        -- G Basement
        bitzer_status = windower.ffxi.get_mob_by_index(838)
        lines:insert(mob_tracking[7].name ..string.format('[%s]',tostring(mob_tracking[7].distance)):lpad(' ',maxWidth - string.len(mob_tracking[7].name)))
        if bitzer_status then
            bitzer_distance = round(((player.x - bitzer_status.x)^2 + (player.y - bitzer_status.y)^2):sqrt(),1)
            lines:insert(bitzer_status.name ..string.format('[%s]',tostring(bitzer_distance)):lpad(' ',maxWidth - string.len(bitzer_status.name)))
        end
        lines:insert("")
        lines:insert("Casket #G1")
        lines:insert("  Target the Bizter for 30 sec ")
        lines:insert("Casket #G2")
        lines:insert("  Kill all vamps")
        lines:insert("Coffer #G")
        lines:insert("  Bee->Shark->T-Rex->Bird->Tree->Lion")
        lines:insert("Chest #G")
        lines:insert("  Kill Gyvewrapped Naraka")
    elseif location == 'H' then
        -- H Basement
        bitzer_status = windower.ffxi.get_mob_by_index(839)
        lines:insert(mob_tracking[8].name ..string.format('[%s]',tostring(mob_tracking[8].distance)):lpad(' ',maxWidth - string.len(mob_tracking[8].name)))
        if bitzer_status then
            bitzer_distance = round(((player.x - bitzer_status.x)^2 + (player.y - bitzer_status.y)^2):sqrt(),1)
            lines:insert(bitzer_status.name ..string.format('[%s]',tostring(bitzer_distance)):lpad(' ',maxWidth - string.len(bitzer_status.name)))
        end
        lines:insert("")
        lines:insert("Casket #H1")
        lines:insert("  Leave then enter")
        lines:insert("Casket #H2")
        lines:insert("  Kill all of one Job")
        lines:insert("Coffer #H")
        lines:insert("  Bee->Lion->T-Rex->Shark->Bird->Tree")
        lines:insert("Chest #H")
        lines:insert("  Kill the NM next to a defated Formor")
    end
    lines:insert("")
    lines:insert('Running....                           ['..gears[gear]..']')
    for i,line in ipairs(lines) do lines[i] = lines[i]:rpad(' ', maxWidth) end
    tracking_window:text(lines:concat('\n'))
    if settings.debug then
        local test_target = windower.ffxi.get_mob_by_target('t')
        if test_target then
            log("["..test_target.name.."] at ["..round(test_target.x,2).."], ["..round(test_target.y,2).."] with a id of ["..test_target.id.."] and an index of ["..test_target.index.."]")
        end
    end
end

function scan_request() -- requests a widescan
  packet = packets.new('outgoing', 0x0F4, {
    ['Flags'] = 1,
    ['_unknown1'] = 0,
    ['_unknown2'] = 0,
  })
  packets.inject(packet)
end

function track_on(index) -- start tracking a NM
  packet = packets.new('outgoing', 0x0F5, {
    ['Index'] = index,
    ['_junk1'] = 0,
  })
  packets.inject(packet)
  log('track request for enemy ['..index..']')
end

function track_off() -- stop tracking a NM
  packet = packets.new('outgoing', 0x0F6, {
    ['_junk1'] = 0,
  })
  packets.inject(packet)
  log('tracking stopped')
end

function gear_update()
    gear = gear +1
    if gear > 4 then
        gear = 1
    end
end

function commands(input, args)
    if input ~= nil then
        local cmd = string.lower(input)
        if cmd == 'save' then
            config.save(settings, windower.ffxi.get_player().name:lower())
            log('Sortie Settings Saved')
        elseif cmd == 'on' then
            local index = 0
            if location == "A" then
                index = 1
            elseif location == "B" then
                index = 2
            elseif location == "C" then
                index = 3
            elseif location == "D" then
                index = 4
            elseif location == "E" then
                index = 5
            elseif location == "F" then
                index = 6
            elseif location == "G" then
                index = 7
            elseif location == "H" then
                index = 8
            end
            show_UI()
            enabled = true
            log('Sortie on')
        elseif cmd == 'off' then
            hide_UI()
            enabled = false
            track_off() 
            log('Sortie off')
        elseif cmd == 'a' then
            location = "A"
            track_on(mob_tracking[1].index)
            log('Sortie zone set to A')
        elseif cmd == 'b' then
            location = "B"
            track_on(mob_tracking[2].index)
            log('Sortie zone set to B')
        elseif cmd == 'c' then
            location = "C"
            track_on(mob_tracking[3].index)
            log('Sortie zone set to C')
        elseif cmd == 'd' then
            location = "D"
            track_on(mob_tracking[4].index)
            log('Sortie zone set to D')
        elseif cmd == 'e' then
            location = "E"
            track_on(mob_tracking[5].index)
            log('Sortie zone set to E')
        elseif cmd == 'f' then
            location = "F"
            track_on(mob_tracking[6].index)
            log('Sortie zone set to F')
        elseif cmd == 'g' then
            location = "G"
            track_on(mob_tracking[7].index)
            log('Sortie zone set to G')
        elseif cmd == 'h' then
            location = "H"
            track_on(mob_tracking[8].index)
            log('Sortie zone set to H')
        elseif cmd == 'zone' then
            local world = windower.ffxi.get_info()
            log('Zone ['..world.zone..']')
        elseif cmd == 'track' then
            track_on(tonumber(args[1]))
            log('Track request ['..args[1]..']')
        elseif cmd == 'scan' then
            if args[1] then
                if args[1] == "index" and args[2] then
                    log("Sent get_mob_by_index ["..args[2].."]")
                    windower.get_mob_by_index(tonumber(args[2]))
                else
                    local test_target = windower.ffxi.get_mob_by_index(args[1])
                    if test_target then
                        log("Get mob by index - passed value")
                        local player = windower.ffxi.get_mob_by_target('me')
                        local distance = round(((player.x - test_target.x)^2 + (player.y - test_target.y)^2):sqrt(),1)
                        log("["..test_target.name.."] at ["..round(test_target.x,2).."], ["..round(test_target.y,2).."] with a id of ["..test_target.id.."] and an index of ["..test_target.index.."]")
                        log("Distance of ["..distance.."]")
                        --track_on(test_target.index)
                    end
                end
            end
        elseif cmd == 'debug' then
            if settings.debug then
                settings.debug = false
                log('Debug off')
            else
                settings.debug = true
                log('Debug on')
            end
        end
    end
end

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function show_UI()
    tracking_window:show()
    floor_window:show()
end

function hide_UI()
    tracking_window:hide()
    floor_window:hide()
end

function log (msg)
    if settings.debug then
        if msg == nil then
            windower.add_to_chat(80,'----Value is Nil----')
        elseif type(msg) == "table" then
            for index, value in pairs(msg) do
                windower.add_to_chat(80,'----'..tostring(value)..'----')
            end
        elseif type(msg) == "number" then
            windower.add_to_chat(80,'----'..tostring(msg)..'----')
        elseif type(msg) == "string" then
            windower.add_to_chat(80,'----'..msg..'----')
        elseif type(msg) == "boolean" then
            windower.add_to_chat(80,'----'..tostring(msg)..'----')
        else
            windower.add_to_chat(80,'----Unknown Debug Message----')
        end
    end
end

function initalize()
    -- 144, 223, 285, 373, 427, 498, 552, 622
    mob_tracking = 
    {
         [1] = {name = 'Abject Obdella', index = 144, distance = 0},
         [2] = {name = 'Biune Porxie', index = 223, distance = 0},
         [3] = {name = 'Cachaemic Bhoot', index = 285, distance = 0},
         [4] = {name = 'Demisang Deleterious', index = 373, distance = 0},
         [5] = {name = 'Esurient Botulus', index = 427, distance = 0},
         [6] = {name = 'Fetid Ixion', index = 498, distance = 0},
         [7] = {name = 'Gyvewrapped Naraka', index = 552, distance = 0},
         [8] = {name = 'Haughty Tulittia', index = 622, distance = 0},
    }
end

windower.register_event('mouse', function (type, x, y, delta, blocked)
    if floor_window:hover(x, y) then
        if type == 2 then
            local window_x = tonumber(settings.Floor.pos.x)
            log("X["..tostring(x).."], Y["..tostring(y).."]")
            log("Window location ["..window_x.."]")
            --Set the floor
            if x > window_x + 40*0 and x < window_x + 40*1 then
                location = "A"
                log("Set to A")
            elseif x > window_x + 40*1 and x < window_x + 40*2 then
                location = "B"
                log("Set to B")
            elseif x > window_x + 40*2 and x < window_x + 40*3 then
                location = "C"
                log("Set to C")
            elseif x > window_x + 40*3 and x < window_x + 40*4 then
                location = "D"
                log("Set to D")
            elseif x > window_x + 40*4 and x < window_x + 40*5 then
                location = "E"
                log("Set to E")
            elseif x > window_x + 40*5 and x < window_x + 40*6 then
                location = "F"
                log("Set to F")
            elseif x > window_x + 40*6 and x < window_x + 40*7 then
                location = "G"
                log("Set to G")
            elseif x > window_x + 40*7 and x < window_x + 40*8 then
                location = "H"
                log("Set to H")
            end
            --Set the NM to track
            if location == "A" then
                index = 1
            elseif location == "B" then
                index = 2
            elseif location == "C" then
                index = 3
            elseif location == "D" then
                index = 4
            elseif location == "E" then
                index = 5
            elseif location == "F" then
                index = 6
            elseif location == "G" then
                index = 7
            elseif location == "H" then
                index = 8
            end
            windower.add_to_chat(8,'The Hunt begins for the ['..mob_tracking[index].name..']....')
            track_on(mob_tracking[index].index)
            return true
        end
    end
end)