require 'lib.moonloader'
script_version('4')

local ffi = require("ffi")
local memory = require 'memory'
local imgui = require 'mimgui'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8
local inicfg = require 'inicfg'
local directIni = 'VisualTestDriveV41.ini'
local ini = inicfg.load(inicfg.load({
    main = {
        preview_rot_x = -20,
        preview_rot_y = 0,
        preview_rot_z = 40,
        preview_color1 = 1,
        preview_color2 = 1
    },
    VEH = {
        alarm = false,
        doors = false,
        bonnet = false,
        boot = false,
        objective = false,
    }
}, directIni))
inicfg.save(ini, directIni)

ffi.cdef[[
struct CTextDrawData {
        float          m_fLetterWidth;
        float          m_fLetterHeight;
        unsigned long  m_letterColor;
        unsigned char  unknown;
        unsigned char  m_bCenter;
        unsigned char  m_bBox;
        float          m_fBoxSizeX;
        float          m_fBoxSizeY;
        unsigned long  m_boxColor;
        unsigned char  m_nProportional;
        unsigned long  m_backgroundColor;
        unsigned char  m_nShadow;
        unsigned char  m_nOutline;
        unsigned char  m_bLeft;
        unsigned char  m_bRight;
        int            m_nStyle;
        float          m_fX;
        float          m_fY;
        unsigned char  pad_[8];
        unsigned long  field_99B;
        unsigned long  field_99F;
        unsigned long  m_nIndex;
        unsigned char  field_9A7;
        unsigned short m_nModel;
        float          m_rotation[3];
        float          m_fZoom;
        unsigned short m_aColor[2];
        unsigned char  field_9BE;
        unsigned char  field_9BF;
        unsigned char  field_9C0;
        unsigned long  field_9C1;
        unsigned long  field_9C5;
        unsigned long  field_9C9;
        unsigned long  field_9CD;
        unsigned char  field_9D1;
        unsigned long  field_9D2;
}__attribute__ ((packed));

struct CTextDraw {
    char m_szText[801];
    char m_szString[1602];
    struct CTextDrawData m_data;
}__attribute__ ((packed));

struct CTextDrawPool {
    int       m_bNotEmpty[2048 + 256];
    struct CTextDraw* m_pObject[2048 + 256];
}__attribute__ ((packed));

typedef unsigned char RwUInt8;
typedef int RwInt32;
typedef short RwInt16;

struct RwRaster
{
    struct RwRaster             *parent; 
    RwUInt8                     *cpPixels;
    RwUInt8                     *palette;
    RwInt32                     width, height, depth;
    RwInt32                     stride;
    RwInt16                     nOffsetX, nOffsetY;
    RwUInt8                     cType;
    RwUInt8                     cFlags;
    RwUInt8                     privateFlags;
    RwUInt8                     cFormat;

    RwUInt8                     *originalPixels;
    RwInt32                      originalWidth;
    RwInt32                      originalHeight;
    RwInt32                      originalStride;
    
    void* texture_ptr;
};

struct RwTexture {
    struct RwRaster* raster;
};
]]

local samp_textdraw_pool = nil 
local textdraw_texture_pool = nil 
local ADDRESS = {
    ['r1'] = 0x216058,
    ['r3'] = 0x26B2B8,
}
local MEM_ADD = ADDRESS[getGameGlobal(707) <= 21 and 'r1' or 'r3']

local vehs = {
    ['game'] = {
        {"Landstalker", 400},{"Bravura", 401},{"Buffalo", 402},{"Linerunner", 403},{"Perennial", 404},{"Sentinel", 405},{"Dumper", 406},{"Firetruck", 407},{"Trashmaster", 408},{"Stretch", 409},{"Manana", 410},{"Infernus", 411},{"Voodoo", 412},{"Pony", 413},{"Mule", 414},{"Cheetah", 415},{"Ambulance", 416},{"Leviathan", 417},{"Moonbeam", 418},{"Esperanto", 419},{"Taxi", 420},{"Washington", 421},{"Bobcat", 422},{"Mr. Whoopee", 423},{"BF Injection", 424},{"Hunter", 425},{"Premier", 426},{"Enforcer", 427},{"Securicar", 428},{"Banshee", 429},{"Predator", 430},{"Bus", 431},{"Rhino", 432},{"Barracks", 433},{"Hotknife", 434},{"Article Trailer", 435},{"Previon", 436},{"Coach", 437},{"Cabbie", 438},{"Stallion", 439},{"Rumpo", 440},{"RC Bandit", 441},{"Romero", 442},{"Packer", 443},{"Monster", 444},{"Admiral", 445},{"Squallo", 446},{"Seaspamrow", 447},{"Pizzaboy", 448},{"Tram", 449},{"Article Trailer 2", 450},{"Turismo", 451},{"Speeder", 452},{"Reefer", 453},{"Tropic", 454},{"Flatbed", 455},{"Yankee", 456},{"Caddy", 457},{"Solair", 458},{"Topfun Van", 459},{"Skimmer", 460},{"PCJ-600", 461},{"Faggio", 462},{"Freeway", 463},{"RC Baron", 464},{"RC Raider", 465},{"Glendale", 466},{"Oceanic", 467},{"Sanchez", 468},{"Spamrow", 469},{"Patriot", 470},{"Quad", 471},{"Coastguard", 472},{"Dinghy", 473},{"Hermes", 474},{"Sabre", 475},{"Rustler", 476},{"ZR-350", 477},{"Walton", 478},{"Regina", 479},{"Comet", 480},{"BMX", 481},{"Burrito", 482},{"Camper", 483},{"Marquis", 484},{"Baggage", 485},{"Dozer", 486},{"Maverick", 487},{"News Maverick", 488},{"Rancher", 489},{"FBI Rancher", 490},{"Virgo", 491},{"Greenwood", 492},{"Jetmax", 493},{"Hotring Racer", 494},{"Sandking", 495},{"Blista Compact", 496},{"Police Maverick", 497},{"Boxville", 498},{"Benson", 499},{"Mesa", 500},{"RC Goblin", 501},{"Hotring Racer A", 502},{"Hotring Racer B", 503},{"Bloodring Banger", 504},{"Rancher", 505},{"Super GT", 506},{"Elegant", 507},{"Journey", 508},{"Bike", 509},{"Mountain Bike", 510},{"Beagle", 511},{"Cropduster", 512},{"Stuntplane", 513},{"Tanker", 514},{"Roadtrain", 515},{"Nebula", 516},{"Majestic", 517},{"Buccaneer", 518},{"Shamal", 519},{"Hydra", 520},{"FCR-900", 521},{"NRG-500", 522},{"HPV1000", 523},{"Cement Truck", 524},{"Towtruck", 525},{"Fortune", 526},{"Cadrona", 527},{"FBI Truck", 528},{"Willard", 529},{"Forklift", 530},{"Tractor", 531},{"Combine", 532},{"Feltzer", 533},{"Remington", 534},{"Slamvan", 535},{"Blade", 536},{"Train", 537},{"Train", 538},{"Vortex", 539},{"Vincent", 540},{"Bullet", 541},{"Clover", 542},{"Sadler", 543},{"Firetruck", 544},{"Hustler", 545},{"Intruder", 546},{"Primo", 547},{"Cargobob", 548},{"Tampa", 549},{"Sunrise", 550},{"Merit", 551},{"Utility Van", 552},{"Nevada", 553},{"Yosemite", 554},{"Windsor", 555},{"Monster A", 556},{"Monster B", 557},{"Uranus", 558},{"Jester", 559},{"Sultan", 560},{"Stratum", 561},{"Elegy", 562},{"Raindance", 563},{"RC Tiger", 564},{"Flash", 565},{"Tahoma", 566},{"Savanna", 567},{"Bandito", 568},{"Train", 569},{"Train", 570},{"Kart", 571},{"Mower", 572},{"Dune", 573},{"Sweeper", 574},{"Broadway", 575},{"Tornado", 576},{"AT400", 577},{"DFT-30", 578},{"Huntley", 579},{"Stafford", 580},{"BF-400", 581},{"Newsvan", 582},{"Tug", 583},{"Petrol Trailer", 584},{"Emperor", 585},{"Wayfarer", 586},{"Euros", 587},{"Hotdog", 588},{"Club", 589},{"Train", 590},{"Article Trailer 3", 591},{"Andromada", 592},{"Dodo", 593},{"RC Cam", 594},{"Launch", 595},{"Police Car LS", 596},{"Police Car SF", 597},{"Police Car LV", 598},{"Police Ranger", 599},{"Picador", 600},{"S.W.A.T.", 601},{"Alpha", 602},{"Phoenix", 603},{"Glendale", 604},{"Sadler", 605},{"Baggage Trailer", 606},{"Baggage Trailer", 607},{"Tug Stairs Trailer", 608},{"Boxville", 609},{"Farm Trailer", 610},{"Utility Trailer", 611}
    },
    ['arz'] = {}
    --{'ALPHA', 602},{'HUSTLER', 545},{'BLISTAC', 496},{'MAJESTC', 517},{'BRAVURA', 401},{'MANANA', 410},{'BUCCANE', 518},{'PICADOR', 600},{'CADRONA', 527},{'PREVION', 436},{'CLUB', 589},{'STAFFRD', 580},{'ESPERAN', 419},{'STALION', 439},{'FELTZER', 533},{'TAMPA', 549},{'FORTUNE', 526},{'VIRGO', 491},{'HERMES', 474},{'ADMIRAL', 445},{'OCEANIC', 467},{'GLENSHI', 604},{'PREMIER', 426},{'ELEGANT', 507},{'PRIMO', 547},{'EMPEROR', 585},{'SENTINL', 405},{'EUROS', 587},{'STRETCH', 409},{'GLENDAL', 466},{'SUNRISE', 550},{'GREENWO', 492},{'TAHOMA', 566},{'INTRUDR', 546},{'VINCENT', 540},{'MERIT', 551},{'WASHING', 421},{'NEBULA', 516},{'WILLARD', 529},{'ANDROM', 592},{'NEVADA', 553},{'AT400', 577},{'SANMAV', 488},{'BEAGLE', 511},{'POLMAV', 497},{'CARGOBB', 548},{'RAINDNC', 563},{'CROPDST', 512},{'RUSTLER', 476},{'DODO', 593},{'SEASPAR', 447},{'HUNTER', 425},{'SHAMAL', 519},{'HYDRA', 520},{'SKIMMER', 460},{'LEVIATH', 417},{'SPARROW', 469},{'MAVERIC', 487},{'STUNT', 513},{'BF400', 581},{'MTBIKE', 510},{'BIKE', 509},{'NRG500', 522},{'BMX', 481},{'PCJ600', 461},{'FAGGIO', 462},{'PIZZABO', 448},{'FCR900', 521},{'SANCHEZ', 468},{'FREEWAY', 463},{'WAYFARE', 586},{'COASTG', 472},{'DINGHY', 473},{'JETMAX', 493},{'LAUNCH', 595},{'MARQUIS', 484},{'PREDATR', 430},{'REEFER', 453},{'SPEEDER', 452},{'SQUALO', 446},{'TROPIC', 454},{'BAGGAGE', 485},{'UTILITY', 552},{'BUS', 431},{'CABBIE', 438},{'COACH', 437},{'SWEEPER', 574},{'TAXI', 420},{'TOWTRUK', 525},{'TRASHM', 408},{'AMBULAN', 416},{'POLICAR LS', 596},{'BARRCKS', 433},{'POLICAR SF', 597},{'ENFORCR', 427},{'RANGER', 599},{'FBIRANC', 490},{'RHINO', 432},{'FBITRUK', 528},{'SWATVAN', 601},{'FIRETRK', 407},{'SECURI', 428},{'FIRELA', 544},{'HPV1000', 523},{'PATRIOT', 470},{'POLICAR LV', 598},{'BENSON', 499},{'HOTDOG', 588},{'BOXBURG', 609},{'LINERUN', 403},{'BOXVILL', 498},{'PETROL', 514},{'CEMENT', 524},{'WHOOPEE', 423},{'COMBINE', 532},{'MULE', 414},{'DFT30', 578},{'PACKER', 443},{'DOZER', 486},{'RDTRAIN', 515},{'DUMPER', 406},{'TRACTOR', 531},{'DUNE', 573},{'YANKEE', 456},{'FLATBED', 455},{'TOPFUN', 459},{'SADLER', 543},{'BOBCAT', 422},{'TUG', 583},{'BURRITO', 482},{'WALTON', 478},{'SADLSHI', 605},{'YOSEMIT', 554},{'FORKLFT', 530},{'MOONBM', 418},{'MOWER', 572},{'NEWSVAN', 582},{'PONY', 413},{'RUMPO', 440},{'BLADE', 536},{'BROADWY', 575},{'REMING', 534},{'SAVANNA', 567},{'SLAMVAN', 535},{'TORNADO', 576},{'VOODOO', 412},{'BUFFALO', 402},{'CLOVER', 542},{'PHOENIX', 603},{'SABRE', 475},{'TRAM', 449},{'FREIGHT', 537},{'STREAK', 538},{'STREAKC', 570},{'RCBANDT', 441},{'RCBARON', 464},{'RCGOBLI', 501},{'RCRAIDE', 465},{'RCTIGER', 564},{'BANDITO', 568},{'MONSTB', 557},{'BFINJC', 424},{'QUAD', 471},{'BLOODRA', 504},{'SANDKIN', 495},{'CADDY', 457},{'VORTEX', 539},{'CAMPER', 483},{'JOURNEY', 508},{'KART', 571},{'MESAA', 500},{'MONSTER', 444},{'MONSTA', 556},{'BANSHEE', 429},{'INFERNU', 411},{'BULLET', 541},{'JESTER', 559},{'CHEETAH', 415},{'STRATUM', 561},{'COMET', 480},{'SULTAN', 560},{'ELEGY', 562},{'SUPERGT', 506},{'FLASH', 565},{'TURISMO', 451},{'HOTKNIF', 434},{'URANUS', 558},{'HOTRING', 494},{'WINDSOR', 555},{'HOTRINA', 502},{'ZR350', 477},{'HOTRINB', 503},{'HUNTLEY', 579},{'LANDSTK', 400},{'PEREN', 404},{'RANCHER', 489},{'RANCHER', 505},{'REGINA', 479},{'ROMERO', 442},{'SOLAIR', 458},{'BAGBOXA', 606},{'BAGBOXB', 607},{'FARMTR1', 610},{'FRBOX', 590},{'FRFLAT', 569},{'UTILTR1', 611},{'PETROTR', 584},{'TUGSTAI', 608},{'ARTICT1', 435},{'ARTICT2', 450},{'ARTICT3', 591},{'RCCAM', 594},
}



local renderWindow = imgui.new.bool(false)

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    imgui.SpotifyTheme()
end)

local tag = '{ff004d}[TestDriveByChapo]:{ffffff} '
local search = imgui.new.char[128]('')
local preview = {
    td = 8,
    model = 411,
    rot = {
        x = imgui.new.int(ini.main.preview_rot_x), 
        y = imgui.new.int(ini.main.preview_rot_y),
        z = imgui.new.int(ini.main.preview_rot_z)
    },
    zoom = imgui.new.int(1),
    color1 = imgui.new.int(ini.main.preview_color1),
    color2 = imgui.new.int(ini.main.preview_color2)
}
local VEH = {
    engine = imgui.new.bool(true),
    lights = imgui.new.bool(true),
    alarm = imgui.new.bool(ini.VEH.alarm),
    doors = imgui.new.bool(ini.VEH.doors),
    bonnet = imgui.new.bool(ini.VEH.bonnet),
    boot = imgui.new.bool(ini.VEH.boot),
    objective = imgui.new.bool(ini.VEH.objective),
    doors = {imgui.new.bool(false), imgui.new.bool(false), imgui.new.bool(false), imgui.new.bool(false)},
    windows = {imgui.new.bool(false), imgui.new.bool(false), imgui.new.bool(false), imgui.new.bool(false)}
}

function save()
    ini.main.preview_rot_x = preview.rot.x[0]
    ini.main.preview_rot_y = preview.rot.y[0]
    ini.main.preview_rot_z = preview.rot.z[0]
    ini.main.preview_color1 = preview.color1[0]
    ini.main.preview_color2 = preview.color2[0]

    ini.VEH.alarm = VEH.alarm[0]
    ini.VEH.doors = VEH.doors[0]
    ini.VEH.bonnet = VEH.bonnet[0]
    ini.VEH.boot = VEH.boot[0]
    ini.VEH.objective = VEH.objective[0]

    inicfg.save(ini, directIni)
end

function updatePreview()
    if sampTextdrawIsExists(preview.td) then
        sampTextdrawSetModelRotationZoomVehColor(preview.td, preview.model, preview.rot.x[0], preview.rot.y[0], preview.rot.z[0], preview.zoom[0], preview.color1[0], preview.color2[0])
        --save()
    end
end

local active = false
local CAR_ID = 888
local car = nil
local savedCoords = {x = 0, y = 0, z = 0, heading = 0}


function onSendPacket(id) 
    if active then 
        return false 
    end 
end

function onSendRpc(id) 
    if active then 
        return false 
    end 
end

function onScriptTerminate(s, q)
    if s == thisScript() then
        if active then
            toggle()
        end
    end
end

local font = renderCreateFont('Trebuchet MS', 15, 1)
local font_ = renderCreateFont('Trebuchet MS', 13, 1)
local hfont = renderCreateFont('Trebuchet MS', 10, 5)
local speed_font = renderCreateFont('Trebuchet MS', 20, 5)

function toggle()
    if active then
        if isCharInAnyCar(PLAYER_PED) then
            warpCharFromCarToCoord(PLAYER_PED, savedCoords.x, savedCoords.y, savedCoords.z)
        end
        vehicle(CAR_ID):delete()
        setCharCoordinates(PLAYER_PED, savedCoords.x, savedCoords.y, savedCoords.z)
        active = false
        if not renderWindow[0] then 
            renderWindow[0] = true
        end
    else
        active = true
        savedCoords.x, savedCoords.y, savedCoords.z = getCharCoordinates(PLAYER_PED)
        savedCoords.heading = getCharHeading(PLAYER_PED)
        VEH.engine[0], VEH.lights[0] = true, true
        vehicle(CAR_ID):create(preview.model, savedCoords.x, savedCoords.y, savedCoords.z, preview.color1[0], preview.color1[0], 10000)
        vehicle(CAR_ID):SetCarSettings()
        local result, car = sampGetCarHandleBySampVehicleId(CAR_ID)
        if result then
            setCarHeading(car, savedCoords.heading)
            warpCharIntoCar(PLAYER_PED, car)
            setCarEngineOn(car, false)
            setCarLightsOn(car, true)
            if renderWindow[0] then 
                renderWindow[0] = false 
            end
        end
    end
end

local selected = 0
local description = 'Название: infernus\nМодель: 411, infernu.txd\nМакс. скорость: ~999 км/ч'

local newFrame = imgui.OnFrame(
    function() return renderWindow[0] end,
    function(player)
        local resX, resY = getScreenResolution()
        local sizeX, sizeY = 500, 500
        imgui.SetNextWindowPos(imgui.ImVec2(resX / 2, resY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(sizeX, sizeY), imgui.Cond.FirstUseEver)
        imgui.BeginCustomTitle('Visual Test Drive by chapo ( vk.com/chaposcripts )', 30, renderWindow, imgui.WindowFlags.NoResize)
        -- WINDOW CODE     

        if not active then
            local listSize = imgui.ImVec2(200, sizeY - 65)

            --==[ VEHS LIST ]==--
            imgui.SetCursorPos(imgui.ImVec2(5, 35))
            imgui.PushItemWidth(listSize.x) 
            imgui.InputText('##search', search, 128) 
            if not imgui.IsItemActive() and #ffi.string(search) == 0 then
                imgui.SameLine(10)
                imgui.TextDisabled(u8'Поиск')
            end
            imgui.PopItemWidth()

            imgui.SetCursorPos(imgui.ImVec2(5, 60))
            imgui.BeginChild('vehs', listSize, true)
                for k, v in ipairs(vehs.game) do
                    local t = v[1]..' ('..tostring(v[2])..')'
                    if #ffi.string(search) == 0 or t:lower():find(ffi.string(search):lower(), nil, true) then
                        if imgui.Selectable(t, selected == k) then 
                            selected = k 
                            local maxSpeed = getVehicleMaxSpeed(v[1]) or getVehicleMaxSpeed(v[1])
                            description = 'Название: '..v[1]..'\nМодель: '..v[2]..', '..(getNameOfVehicleModel(v[2]) or 'UNKNOWN')..'.txd\nМакс. скорость: ~'..(maxSpeed or '-')..' км/ч'
                            preview.model = v[2]
                            sampTextdrawDelete(preview.td)
                        end
                    end
                end
            imgui.EndChild()

            --==[ PREVIEW ]==--
            imgui.SetCursorPos(imgui.ImVec2(5 + listSize.x + 5, 35))
            local previewSize = imgui.ImVec2(sizeX - 15 - listSize.x, sizeX - 15 - listSize.x)
            --imgui.Button('PREVIEW', previewSize)
            imgui.Object(preview.td, preview.model, preview.rot.x[0], preview.rot.y[0], preview.rot.z[0], preview.zoom[0], preview.color1[0], preview.color2[0], previewSize)
            
            imgui.PushStyleVarVec2(imgui.StyleVar.FramePadding, imgui.ImVec2(0, 0))
            imgui.PushItemWidth(previewSize.x)
            imgui.SetCursorPos(imgui.ImVec2(5 + listSize.x + 5 , 35 + previewSize.y-10))
            --if imgui.SliderInt('##ROT Z', preview.rot.z, -180, 180) then updatePreview() end
            imgui.SetCursorPos(imgui.ImVec2(5 + listSize.x + 5 + previewSize.x - 15, 35))
            --if imgui.VSliderInt('##ROT Y', imgui.ImVec2(15, previewSize.y - 10), preview.rot.x, -180, 180) then updatePreview() end
            imgui.PopItemWidth()
            imgui.PopStyleVar()

            imgui.SetCursorPos(imgui.ImVec2(5 + listSize.x + 5, 35 + previewSize.y + 5))
            imgui.Text(u8(description))

            imgui.SetCursorPos(imgui.ImVec2(5 + listSize.x + 5, sizeY - 90))
            imgui.PushItemWidth(100)
            imgui.InputInt(u8'Цвет #1', preview.color1)-- then sampTextdrawDelete(preview.td) end
            imgui.SetCursorPos(imgui.ImVec2(5 + listSize.x + 5, sizeY - 65))
            imgui.InputInt(u8'Цвет #2', preview.color2)-- then sampTextdrawDelete(preview.td) end
            imgui.PopItemWidth()

            imgui.SetCursorPos(imgui.ImVec2(5 + listSize.x + 5, sizeY - 115))
            if imgui.Button(u8'Настроить', imgui.ImVec2(100, 20)) then
                imgui.OpenPopup(u8'Настройка т/с')
            end
            if imgui.BeginPopup(u8'Настройка т/с') then
                --imgui.Checkbox('engine', VEH.engine)
                --imgui.Checkbox('lights', VEH.lights)
                imgui.Checkbox(u8'Сигнализация', VEH.alarm)
                imgui.Checkbox(u8'не ебу что это (bonnet)', VEH.bonnet)
                imgui.Checkbox(u8'это тоже хз (boot)', VEH.boot)
                imgui.Checkbox(u8'Метка над т/с', VEH.objective)
                imgui.EndPopup()
            end

            imgui.SetCursorPos(imgui.ImVec2(5 + listSize.x + 5, sizeY - 35))
            if imgui.Button(u8'Начать', imgui.ImVec2(previewSize.x, 30)) then 
                toggle()
            end
        else
            imgui.SetCursorPosY(sizeY / 2 - 25 - 80)
            imgui.CenterText(u8'Вы в режиме тест-драйва\n\n'..u8(description))
            
            imgui.SetCursorPos(imgui.ImVec2(5, sizeY / 2 - 25 + 20))
            if imgui.Button(u8'Выйти из тест-драйва', imgui.ImVec2(sizeX - 10, 50)) then
                toggle()
            end
        end
        imgui.End()
    end
)

function SetNumberPlateText(id, text)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt16(bs, id) -- wVehicleID
    raknetBitStreamWriteInt8(bs, #text) -- PlateLength
    raknetBitStreamWriteString(bs, text) -- PlateText
    raknetEmulRpcReceiveBitStream(123, bs)
    raknetDeleteBitStream(bs)
end

function vehicle(id)
    local class = {}
    function class:SetCarSettings()
        local bs = raknetNewBitStream()
        
        raknetBitStreamWriteInt16(bs, id) -- id
        raknetBitStreamWriteInt8(bs, VEH.engine[0] and 1 or 0) -- engine
        raknetBitStreamWriteInt8(bs, VEH.lights[0] and 1 or 0) -- lights
        raknetBitStreamWriteInt8(bs, VEH.alarm[0] and 1 or 0) -- alarm
        raknetBitStreamWriteInt8(bs, VEH.doors[0] and 1 or 0) -- doors
        raknetBitStreamWriteInt8(bs, VEH.bonnet[0] and 1 or 0) -- bonnet
        raknetBitStreamWriteInt8(bs, VEH.boot[0] and 1 or 0) -- boot
        raknetBitStreamWriteInt8(bs, VEH.objective[0] and 1 or 0) -- objective
        raknetBitStreamWriteInt8(bs, VEH.doors[0] and 1 or 0) -- doors
        raknetBitStreamWriteInt8(bs, VEH.windows[0] and 1 or 0) -- windows
        
        raknetBitStreamWriteInt8(bs, VEH.doors[1][0] and 1 or 0) -- door - driver
        raknetBitStreamWriteInt8(bs, VEH.doors[2][0] and 1 or 0) -- door - passenger
        raknetBitStreamWriteInt8(bs, VEH.doors[3][0] and 1 or 0) -- door - backleft
        raknetBitStreamWriteInt8(bs, VEH.doors[4][0] and 1 or 0) -- door - backright
    
        raknetBitStreamWriteInt8(bs, VEH.windows[1][0] and 1 or 0) -- window - driver
        raknetBitStreamWriteInt8(bs, VEH.windows[2][0] and 1 or 0) -- window - passenger
        raknetBitStreamWriteInt8(bs, VEH.windows[3][0] and 1 or 0) -- window - backleft
        raknetBitStreamWriteInt8(bs, VEH.windows[4][0] and 1 or 0) -- window - backright
    
        raknetEmulRpcReceiveBitStream(24, bs)
        raknetDeleteBitStream(bs)
    end

    function class:create(model, x, y, z, color_1, color_2, health)
        local bs = raknetNewBitStream()
        raknetBitStreamWriteInt16(bs, id) -- Server ID
        raknetBitStreamWriteInt32(bs, model) -- Model ID
        raknetBitStreamWriteFloat(bs, x) -- Pos X
        raknetBitStreamWriteFloat(bs, y) -- Pos Y
        raknetBitStreamWriteFloat(bs, z) -- Pos Z
        raknetBitStreamWriteFloat(bs, 0) -- Angle (Rotation)
        raknetBitStreamWriteInt8(bs, color_1) -- First (main) color
        raknetBitStreamWriteInt8(bs, color_2) -- Secondary color
        raknetBitStreamWriteFloat(bs, health) -- Health
        raknetBitStreamWriteInt8(bs, 0) -- Interior
        raknetBitStreamWriteInt32(bs, 0) -- Door status
        raknetBitStreamWriteInt32(bs, 0) -- Panel status
        raknetBitStreamWriteInt8(bs, 0) -- Light status
        raknetBitStreamWriteInt8(bs, 0) -- Tire status
        raknetBitStreamWriteInt8(bs, 0) -- Siren
        for i = 1, 14 do
            raknetBitStreamWriteInt8(bs, 0) -- Customisation
        end
        raknetBitStreamWriteInt8(bs, 0) -- Paint job
        raknetBitStreamWriteInt32(bs, -1) -- Body color 1
        raknetBitStreamWriteInt32(bs, -1) -- Body color 2
        raknetEmulRpcReceiveBitStream(164, bs) -- WorldVehicleAdd
        raknetDeleteBitStream(bs)
        SetNumberPlateText(id, 'by chapo')
    end

    function class:delete()
        --[[
            WorldVehicleRemove - ID: 165
            Parameters: UINT16 wVehicleID
        ]]
        local bs = raknetNewBitStream()
        raknetBitStreamWriteInt16(bs, id)
        raknetEmulRpcReceiveBitStream(165, bs)
        raknetDeleteBitStream(bs)
    end

    return class
end

function imgui.CenterText(text)
    imgui.SetCursorPosX(imgui.GetWindowSize().x / 2 - imgui.CalcTextSize(text).x / 2)
    imgui.Text(text)
end

function main()
    while not isSampAvailable() do wait(0) end
    if isArizonaLauncher() then
        getArzContent()
    end
    sampRegisterChatCommand('srv_veh', function()
        local x, y, z = getCharCoordinates(PLAYER_PED)
       -- vehicle():create(411, preview.model, x, y, z, preview.color1[0], preview.color1[0], 10000)
    end)
    nitro()
    sampAddChatMessage(tag..'загружен. Активация: /testdrive', -1)
    sampAddChatMessage(tag..'машины с лаунчера: '..(isArizonaLauncher() and 'доступны' or 'недоступны')..'. Автор: vk.com/chaposcripts', -1)
    samp_textdraw_pool = ffi.cast("struct CTextDrawPool*", sampGetTextdrawPoolPtr())
    textdraw_texture_pool = ffi.cast("struct RwTexture**", getModuleHandle("samp.dll") + MEM_ADD)
    sampRegisterChatCommand('testdrive', function()
        renderWindow[0] = not renderWindow[0]
    end)
    while true do
        wait(0)
        if active then
            local resX, resY = getScreenResolution()
            local text = 'Visual Test Drive v'..thisScript().version..' by chapo ( vk.com/chaposcripts )'
            renderFontDrawText(font_, text, resX / 2 - renderGetFontDrawTextLength(font_, text) / 2, resY - renderGetFontDrawHeight(font_), 0xFFFFFFFF, 0x90000000)

            if isButtonPressed(Player, 15)then
                toggle()
            end

            if isCharInAnyCar(PLAYER_PED) then
                local car = storeCarCharIsInNoSave(PLAYER_PED)
                setCharProofs(PLAYER_PED, true, true, true, true, true)
                setCarHealth(storeCarCharIsInNoSave(PLAYER_PED), 10000)
                
                if not sampIsCursorActive() then
                    if wasKeyPressed(VK_N) then
                        VEH.engine[0] = not VEH.engine[0]
                        vehicle(CAR_ID):SetCarSettings()
                        sampAddChatMessage(tag..'двигатель '..(VEH.engine and 'включен' or 'выключен'), -1)
                    end
                    if wasKeyPressed(VK_LCONTROL) then
                        VEH.lights[0] = not VEH.lights[0]
                        vehicle(CAR_ID):SetCarSettings()
                        sampAddChatMessage(tag..'фары '..(VEH.lights and 'включены' or 'выключены'), -1)
                        setCarLightsOn(storeCarCharIsInNoSave(PLAYER_PED), VEH.lights)
                    end
                    if wasKeyPressed(VK_L) then
                        if isCharInAnyCar(PLAYER_PED) and storeCarCharIsInNoSave(PLAYER_PED) == car then
                            setCarCoordinates(car, getCarCoordinates(car))
                        end
                    end
                    if wasKeyPressed(VK_K) then
                        if isCharInAnyCar(PLAYER_PED) and storeCarCharIsInNoSave(PLAYER_PED) == car then
                            setCarCoordinates(car, savedCoords.x, savedCoords.y, savedCoords.z)
                        end
                    end
                end
                renderFontDrawText(speed_font, math.floor(getCarSpeed(storeCarCharIsInNoSave(PLAYER_PED)) * 3.6)..' км/ч', resX - 300, resY - 130, 0xFFFFFFFF, 0x90000000)
                local posX, posY = resX - 300, resY - 100
                renderFontDrawText(hfont, 'F - выйти из тест-драйва', posX, posY , 0xFFFFFFFF, 0x90000000)
                renderFontDrawText(hfont, 'N - '..(VEH.engine and 'выключить' or 'включить')..' двигатель', posX, posY + 15, 0xFFFFFFFF, 0x90000000)
                renderFontDrawText(hfont, 'CTRL - '..(VEH.lights and 'выключить' or 'включить')..' фары', posX, posY + 30, 0xFFFFFFFF, 0x90000000)
                renderFontDrawText(hfont, 'SHIFT - нитро', posX, posY + 45, 0xFFFFFFFF, 0x90000000)
                renderFontDrawText(hfont, 'L - останововка/перевернуть машину', posX, posY + 60, 0xFFFFFFFF, 0x90000000)
                renderFontDrawText(hfont, 'K - вернуться на место создания т/с', posX, posY + 75, 0xFFFFFFFF, 0x90000000)
            end
        end
    end
end

function nitro()
    local mem = require('memory')
    lua_thread.create(function()
        while true do
            wait(0)
            if active then
                if isCharInAnyCar(PLAYER_PED) then
                    local veh = storeCarCharIsInNoSave(PLAYER_PED)
                    giveNonPlayerCarNitro(storeCarCharIsInNoSave(PLAYER_PED))
                    while isKeyDown(VK_SHIFT) do
                        wait(0)
                        if isCharInAnyCar(PLAYER_PED) then
                            mem.setfloat(getCarPointer(storeCarCharIsInNoSave(PLAYER_PED)) + 0x08A4, -0.5)
                        end
                    end
                    if isCharInAnyCar(PLAYER_PED) then
                        removeVehicleMod(storeCarCharIsInNoSave(PLAYER_PED), 1008)
                        removeVehicleMod(storeCarCharIsInNoSave(PLAYER_PED), 1009)
                        removeVehicleMod(storeCarCharIsInNoSave(PLAYER_PED), 1010)
                    end
                end
            end
        end
    end)
end

--==[ ImGui Snippets ]==--
function imgui.Object(uniqueId, model, rotX, rotY, rotZ, zoom, color1, color2, size)
    if samp_textdraw_pool ~= nil and textdraw_texture_pool ~= nil then
        if not isGamePaused() then
            if sampTextdrawIsExists(uniqueId) then
                if samp_textdraw_pool ~= nil and textdraw_texture_pool ~= nil then
                    local index = samp_textdraw_pool.m_pObject[uniqueId].m_data.m_nIndex
                    local rwtex = textdraw_texture_pool[index]
                    imgui.Image(rwtex.raster.texture_ptr, size)
                end
            else
                sampTextdrawCreate(uniqueId, _, 1000, 1000)
                sampTextdrawSetStyle(uniqueId, 5)
                sampTextdrawSetBoxColorAndSize(uniqueId, 0, 0, 50, 50)
                sampTextdrawSetModelRotationZoomVehColor(uniqueId, model, rotX, rotY, rotZ, zoom, color1, color2)
            end
        end
    end
end

function isArizonaLauncher()
    return doesFileExist(getGameDirectory()..'\\_CoreGame.asi') or doesFileExist(getGameDirectory()..'\\_ci.asi')
end 

function getArzContent()
    local t = {}
    if doesDirectoryExist(getGameDirectory()..'\\arizona') then
        local ide_file = getGameDirectory()..'\\arizona\\vehicles.ide'
        local file = getGameDirectory()..'\\arizona\\vehicles.txt'
        if doesFileExist(ide_file) and not doesFileExist(file) then
            infile = io.open(ide_file, "r")
            instr = infile:read("*a")
            infile:close()
    
            outfile = io.open(file, "w")
            outfile:write(instr)
            outfile:close()
        end
        if doesFileExist(file) then
            sampAddChatMessage('scanning', -1)
            lua_thread.create(function()
                local pattern = '(%d+),(.+),(.+),(.+),(.+),(.+),(.+),(.+),(.+),(.+),(.+),(.+),(.+),(.+),(.+)'
                local lineIndex = 1
                for line in io.lines(file) do 
                    lineIndex = lineIndex + 1
                    if line:find(pattern) then
                        local id, modelname = line:match(pattern)
                        if getNameOfVehicleModel(id) == nil then
                            
                            table.insert(vehs['game'], {'ARZ '..modelname:gsub('%s+', ''), id})
                            
                        end
                    end
                end
                print('Найдено '..#t..' лаунчерных машин!')
            end)  
            os.remove(file)
        else
            print('[ОШИБКА] невозможно получить список машин лаунчера, файл не найден :(')          
        end
    end
    arzcars = t
end

function getVehicleMaxSpeed(model)
    --local model = model:lower()
    local retSpeed = -1
    local TEMP_checkingModel = 'none'
    local VEHDATA = {}
    local handling_file = getGameDirectory()..(isArizonaLauncher() and '\\arizona\\handling.cfg' or '\\data\\handling.cfg')
    if doesFileExist(handling_file) then
        for line in io.lines(handling_file) do 
            local lineIndex = 0
            local line = line:gsub('%s+', '\n')
            for v in string.gmatch(line, '[^\n]+') do
                lineIndex = lineIndex + 1
                if lineIndex == 1 then
                    TEMP_checkingModel = v:lower()
                elseif lineIndex == 13 then
                    if TEMP_checkingModel:find(model:lower()) or model:lower():find(TEMP_checkingModel, nil, true) then
                        retSpeed = v
                    end
                end
            end            
        end
    end
    return retSpeed
end

function imgui.BeginCustomTitle(title, titleSizeY, var, flags)
    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(0, 0))
    imgui.PushStyleVarFloat(imgui.StyleVar.WindowBorderSize, 0)
    imgui.Begin(title, var, imgui.WindowFlags.NoTitleBar + (flags or 0))
    imgui.SetCursorPos(imgui.ImVec2(0, 0))
    local p = imgui.GetCursorScreenPos()
    imgui.GetWindowDrawList():AddRectFilled(p, imgui.ImVec2(p.x + imgui.GetWindowSize().x, p.y + titleSizeY), imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.TitleBgActive]), imgui.GetStyle().WindowRounding, 1 + 2)
    imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowSize().x / 2 - imgui.CalcTextSize(title).x / 2, titleSizeY / 2 - imgui.CalcTextSize(title).y / 2))
    imgui.Text(title)
    imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowSize().x - (titleSizeY - 10) - 5, 5))
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, imgui.GetStyle().WindowRounding)
    if imgui.Button('X##CLOSEBUTTON.WINDOW.'..title, imgui.ImVec2(titleSizeY - 10, titleSizeY - 10)) then var[0] = false end
    imgui.SetCursorPos(imgui.ImVec2(5, titleSizeY + 5))
    imgui.PopStyleVar(3)
    imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(5, 5))
end

function imgui.ButtonWithSettings(text, settings, size)
    --[[
        Доступные настройки:
           rounding - закругление
           color - цвет
           color_hovered - цвет при наведении
           color_active - цвет при клике
           color_text - цвет текста

        параметры которые необходимо изменить нужно вписывать в качестве "ключа" в массиве, который передается через 2 параметр
    ]]
    imgui.PushStyleVarFloat(imgui.StyleVar.FrameRounding, settings.rounding or imgui.GetStyle().FrameRounding)
    imgui.PushStyleColor(imgui.Col.Button, settings.color or imgui.GetStyle().Colors[imgui.Col.Button])
    imgui.PushStyleColor(imgui.Col.ButtonHovered, settings.color_hovered or imgui.GetStyle().Colors[imgui.Col.ButtonHovered])
    imgui.PushStyleColor(imgui.Col.ButtonActive, settings.color_active or imgui.GetStyle().Colors[imgui.Col.ButtonActive])
    imgui.PushStyleColor(imgui.Col.Text, settings.color_text or imgui.GetStyle().Colors[imgui.Col.Text])
    local click = imgui.Button(text, size)
    imgui.PopStyleColor(4)
    imgui.PopStyleVar()
    return click
end

function imgui.SpotifyTheme()
    -- 121212 - 0.07, 0.07, 0.07

    
    imgui.SwitchContext()
    --==[ STYLE ]==--
    imgui.GetStyle().WindowPadding = imgui.ImVec2(5, 5)
    imgui.GetStyle().FramePadding = imgui.ImVec2(5, 5)
    imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
    imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(4, 4)
    imgui.GetStyle().TouchExtraPadding = imgui.ImVec2(5, 5)
    imgui.GetStyle().IndentSpacing = 5
    imgui.GetStyle().ScrollbarSize = 10
    imgui.GetStyle().GrabMinSize = 10

    --==[ BORDER ]==--
    imgui.GetStyle().WindowBorderSize = 0
    imgui.GetStyle().ChildBorderSize = 1
    imgui.GetStyle().PopupBorderSize = 0
    imgui.GetStyle().FrameBorderSize = 0
    imgui.GetStyle().TabBorderSize = 0

    --==[ ROUNDING ]==--
    imgui.GetStyle().WindowRounding = 5
    imgui.GetStyle().ChildRounding = 5
    imgui.GetStyle().FrameRounding = 5
    imgui.GetStyle().PopupRounding = 5
    imgui.GetStyle().ScrollbarRounding = 5
    imgui.GetStyle().GrabRounding = 5
    imgui.GetStyle().TabRounding = 5

    --==[ ALIGN ]==--
    imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    imgui.GetStyle().ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    imgui.GetStyle().SelectableTextAlign = imgui.ImVec2(0.5, 0.5)

    --==[ COLORS ]==--
    imgui.GetStyle().Colors[imgui.Col.Text]                   = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TextDisabled]           = imgui.ImVec4(0.50, 0.50, 0.50, 1.00)
    imgui.GetStyle().Colors[imgui.Col.WindowBg]               = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ChildBg]                = imgui.ImVec4(0.09, 0.09, 0.09, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PopupBg]                = imgui.ImVec4(0.09, 0.09, 0.09, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Border]                 = imgui.ImVec4(0, 0, 0, 0.5)
    imgui.GetStyle().Colors[imgui.Col.BorderShadow]           = imgui.ImVec4(0.00, 0.00, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBg]                = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBgHovered]         = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBgActive]          = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)

    imgui.GetStyle().Colors[imgui.Col.TitleBg]                = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBgActive]          = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBgCollapsed]       = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)

    imgui.GetStyle().Colors[imgui.Col.MenuBarBg]              = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarBg]            = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab]          = imgui.ImVec4(0.00, 0.00, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabHovered]   = imgui.ImVec4(0.41, 0.41, 0.41, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabActive]    = imgui.ImVec4(0.51, 0.51, 0.51, 1.00)
    
    imgui.GetStyle().Colors[imgui.Col.CheckMark]              = imgui.ImVec4(0.11, 0.73, 0.33, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SliderGrab]             = imgui.ImVec4(0.11, 0.73, 0.33, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SliderGrabActive]       = imgui.ImVec4(0.12, 0.84, 0.38, 1.00)

    imgui.GetStyle().Colors[imgui.Col.Button]                 = imgui.ImVec4(0.11, 0.73, 0.33, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ButtonHovered]          = imgui.ImVec4(0.12, 0.84, 0.38, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ButtonActive]           = imgui.ImVec4(0.12, 0.84, 0.38, 1.00)

    imgui.GetStyle().Colors[imgui.Col.Header]                 = imgui.ImVec4(0.11, 0.73, 0.33, 1.00)
    imgui.GetStyle().Colors[imgui.Col.HeaderHovered]          = imgui.ImVec4(0.12, 0.84, 0.38, 1.00)
    imgui.GetStyle().Colors[imgui.Col.HeaderActive]           = imgui.ImVec4(0.12, 0.84, 0.38, 1.00)

    imgui.GetStyle().Colors[imgui.Col.Separator]              = imgui.ImVec4(0.11, 0.73, 0.33, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SeparatorHovered]       = imgui.ImVec4(0.11, 0.73, 0.33, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SeparatorActive]        = imgui.ImVec4(0.11, 0.73, 0.33, 1.00)

    imgui.GetStyle().Colors[imgui.Col.ResizeGrip]             = imgui.ImVec4(0.11, 0.73, 0.33, 0.25)
    imgui.GetStyle().Colors[imgui.Col.ResizeGripHovered]      = imgui.ImVec4(0.12, 0.84, 0.38, 0.67)
    imgui.GetStyle().Colors[imgui.Col.ResizeGripActive]       = imgui.ImVec4(0.12, 0.84, 0.38, 0.95)

    imgui.GetStyle().Colors[imgui.Col.Tab]                    = imgui.ImVec4(0.11, 0.73, 0.33, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabHovered]             = imgui.ImVec4(0.12, 0.84, 0.38, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabActive]              = imgui.ImVec4(0.12, 0.84, 0.38, 1.00)

    imgui.GetStyle().Colors[imgui.Col.TabUnfocused]           = imgui.ImVec4(0.07, 0.10, 0.15, 0.97)
    imgui.GetStyle().Colors[imgui.Col.TabUnfocusedActive]     = imgui.ImVec4(0.14, 0.26, 0.42, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotLines]              = imgui.ImVec4(0.61, 0.61, 0.61, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotLinesHovered]       = imgui.ImVec4(1.00, 0.43, 0.35, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotHistogram]          = imgui.ImVec4(0.90, 0.70, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotHistogramHovered]   = imgui.ImVec4(1.00, 0.60, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TextSelectedBg]         = imgui.ImVec4(1.00, 0.00, 0.00, 0.35)
    imgui.GetStyle().Colors[imgui.Col.DragDropTarget]         = imgui.ImVec4(1.00, 1.00, 0.00, 0.90)
    imgui.GetStyle().Colors[imgui.Col.NavHighlight]           = imgui.ImVec4(0.26, 0.59, 0.98, 1.00)
    imgui.GetStyle().Colors[imgui.Col.NavWindowingHighlight]  = imgui.ImVec4(1.00, 1.00, 1.00, 0.70)
    imgui.GetStyle().Colors[imgui.Col.NavWindowingDimBg]      = imgui.ImVec4(0.80, 0.80, 0.80, 0.20)
    imgui.GetStyle().Colors[imgui.Col.ModalWindowDimBg]       = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
end