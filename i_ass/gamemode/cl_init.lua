include("shared.lua")
local states = {
    [-1] = "Waiting for more players..",
    [0] = "Getting knife in..",
    [1] = "Kill your targets and pursuers!",
    [2] = "Ending current round.."
} 

state = state or -1
time = time or 0
target = target or nil
knifetime = knifetime or 0
net.Receive("GetTarget",function()
    target = net.ReadEntity()
    print("Got targeT: " .. target:Nick())
end)

net.Receive("GetRoundTime",function()
    state = net.ReadInt(8)
    time = net.ReadInt(32)
    print("Received time: " .. time )
end)

net.Receive("RoundStart",function()
    state = 1
    time = net.ReadInt(32)
end)

net.Receive("RoundEnd",function()
    state = 2
    time = net.ReadInt(32)
    target = nil
end)

net.Receive("RoundPrep",function()
    state = 0
    time = net.ReadInt(32)
end)

net.Receive("WrongPerson",function()
    local t = net.ReadInt(32)
    LocalPlayer().TotalWrong = t
    LocalPlayer().WrongTime = CurTime() + t
end)

net.Receive("KnifeTime",function()
    knifetime = net.ReadInt(32)
    totalknife = knifetime - CurTime()
end)

net.Receive("RoundWin",function()
    local p = net.ReadEntity()
    chat.AddText(Color(255,255,255),p:Nick(),Color(255,0,0)," has won as the last one standing!")
end)

net.Receive("KillStreak",function()
    local ply = net.ReadEntity()
    local s = net.ReadInt(32)
    chat.AddText(Color(0,255,0),ply:Nick(),Color(255,255,255)," is on a ",Color(255,0,0),tostring(s),Color(255,255,255)," player kill streak!")
end)

net.Receive("YouDied",function()
    local ply = net.ReadEntity()
    local target = net.ReadBool()
    local thrown = net.ReadBool()
    print("You where killer by ",ply)
    local s = (target and "you were his target" or "you were his pursuer")
    print(s)
    print("Killed by thrown knife: " .. thrown)
end)

local function ts(t,f)
    surface.SetFont(f)
    return surface.GetTextSize(t)
end


surface.CreateFont("TimeFont",{
    font = "Roboto",
    antialias = true,
    size = ScreenScale(15)
})

surface.CreateFont("TimeID",{
    font = "Roboto",
    antialias = true,
    size = ScreenScale(10)
})
function GM:InitPostEntity()
    if not GAMEMODE.AvatarP then
        GAMEMODE.AvatarP = vgui.Create("DModelPanel")
        GAMEMODE.AvatarP:SetSize(ScreenScale(30),ScreenScale(30))
        function GAMEMODE.AvatarP:LayoutEntity( Entity ) return end
    end
end

local black = {
    CHudAmmo = true,
    CHudBattery = true,
    CHudHealth = true,
    CHudWeaponSelection = true
}

function GM:HUDShouldDraw( name )
    return not black[name]
end

function GM:EntityFireBullets( ent, data )
    data.Num = 1
    return true
end

matproxy.Add( {
	name = "PlayerColor",
	init = function( self, mat, values )
		-- Store the name of the variable we want to set
		self.ResultTo = values.resultvar
	end,
	bind = function( self, mat, ent )
		-- If the target ent has a function called GetPlayerColor then use that
		-- The function SHOULD return a Vector with the chosen player's colour.

		-- In sandbox this function is created as a network function,
		-- in player_sandbox.lua in SetupDataTables
		if ( ent.GetPlayerColor ) then
            if isvector(ent:GetPlayerColor()) then
			    mat:SetVector( self.ResultTo, ent:GetPlayerColor() )
            end
		end
        if (ent.PlayerColor) then
            mat:SetVector(self.ResultTo, ent.PlayerColor)
        end
	end
} )
local lastnick = ""
local nicktime = 0
local nickcolor = Color(0,0,0)
local black = Color(0,0,0)
function GM:HUDPaint()
    if not LocalPlayer().SpecMode then LocalPlayer().SpecMode = OBS_MODE_NONE end
    local t = LocalPlayer():GetEyeTrace()
    for k,v in pairs(player.GetAll()) do
        draw.DrawText(v:Nick(),"TargetID",v:GetPos():ToScreen().x,v:GetPos():ToScreen().y)
    end
    if IsValid(t.Entity) and (LocalPlayer():Alive() or LocalPlayer().SpecMode == OBS_MODE_ROAMING) then
        if t.Entity:IsPlayer() then
            lastnick = t.Entity:Nick()
            nicktime = CurTime() + 1
            nickcolor = t.Entity:GetPlayerColor():ToColor()
        end
    end

    if nicktime > CurTime() then
        nickcolor.a = (nicktime - CurTime()) * 255
        local b = black
        b.a = (nicktime - CurTime()) * 255
        draw.SimpleTextOutlined(lastnick, "TimeID", ScrW()/2, ScrH()*0.53, nickcolor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, black)
    end

    if IsValid(LocalPlayer():GetObserverTarget()) then
        local ply = LocalPlayer():GetObserverTarget()
        local w,h = ts(ply:Nick(),"TimeFont")
        draw.SimpleTextOutlined(ply:Nick(), "TimeFont", ScrW()/2, 0, ply:GetPlayerColor():ToColor(), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, Color(0,0,0))
    end
    if LocalPlayer().WrongTime then
        if LocalPlayer().WrongTime > CurTime() then
            local w = ScreenScale(20)
            local c = LocalPlayer():GetPlayerColor():ToColor()
            c.a = 200
            local x = ( (LocalPlayer().WrongTime - CurTime()) / (LocalPlayer().TotalWrong) ) * w
            draw.RoundedBox(0,ScrW()/2-w/2,ScrH()*0.46-12,x,12,c)
            surface.SetDrawColor(255, 0, 0, 255)
            surface.DrawOutlinedRect(ScrW()/2-w/2,ScrH()*0.46-12,w, 12)
        end
    end
    if knifetime > CurTime() and not LocalPlayer():HasWeapon("meme_knife") then
        local w = ScreenScale(20)
        local c = LocalPlayer():GetPlayerColor():ToColor()
        c.a = 200
        local x = ( (knifetime - CurTime()) / (totalknife) ) * w
        draw.RoundedBox(0,ScrW()/2-w/2,ScrH()*0.54,x,12,c)
        surface.SetDrawColor(0, 255, 0, 255)
        surface.DrawOutlinedRect(ScrW()/2-w/2,ScrH()*0.54,w, 12)
    end
    local t = time - CurTime()
    if t < 0 then t = 0 end
    local s = string.FormattedTime(t)
    local ss = s.s
    if tostring(s.s):len() == 1 then
        s.s = "0" .. s.s
    end
    s = s.m .. ":" .. s.s -- Lazy
    local w,hh = ts(s,"TimeFont")
    draw.SimpleTextOutlined(s, "TimeFont", ScrW()/2, ScrH()-(hh+5), LocalPlayer():GetPlayerColor():ToColor(), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, Color(0,0,0))
    local w,h = ts(states[state],"TimeFont")
    draw.SimpleTextOutlined(states[state], "TimeFont", ScrW()/2, ScrH()-(hh+h+5), LocalPlayer():GetPlayerColor():ToColor(), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, Color(0,0,0))

    if not IsValid(target) then GAMEMODE.AvatarP:SetPos(-1000,-1000) return end
    if not target:Alive() then GAMEMODE.AvatarP:SetPos(-1000,-1000) return end
    if not LocalPlayer():Alive() then GAMEMODE.AvatarP:SetPos(-1000,-1000) return end

    local w,h = ts(target:Nick(),"TimeFont")
    draw.SimpleTextOutlined(target:Nick(), "TimeFont", ScrW()/2-w + ScreenScale(30) + 10, ScrH() * 0.101, target:GetPlayerColor():ToColor(), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0,0,0))
    draw.RoundedBox(0,ScrW()/2 - (w/2) - ScreenScale(30) - 5,ScrH()*0.1 - ScreenScale(8) ,ScreenScale(30) + w*2 ,ScreenScale(30) + 5,Color(0,0,0,100))
    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawOutlinedRect(ScrW()/2 - (w/2) - ScreenScale(30) - 5,ScrH()*0.1 - ScreenScale(8) ,ScreenScale(30) + w*2 ,ScreenScale(30) + 5)
    if IsValid(GAMEMODE.AvatarP) and LocalPlayer():Alive() then
        GAMEMODE.AvatarP:SetModel(target:GetModel())
        GAMEMODE.AvatarP.Entity.PlayerColor = target:GetPlayerColor()
      --  GAMEMODE.AvatarP:SetPlayerColor(target:GetPlayerColor())
        GAMEMODE.AvatarP:SetPos(ScrW()/2 - (w/2) - ScreenScale(30),ScrH()*0.1 - h/2)
        if not GAMEMODE.AvatarP.Entity:LookupBone( "ValveBiped.Bip01_Head1" ) then return end
        local pos = GAMEMODE.AvatarP.Entity:GetBonePosition( GAMEMODE.AvatarP.Entity:LookupBone( "ValveBiped.Bip01_Head1" ) )
        GAMEMODE.AvatarP:SetLookAt( pos )
        GAMEMODE.AvatarP:SetCamPos( pos - Vector( -15, 0, 0 ) )
    elseif not LocalPlayer():Alive() then
        GAMEMODE.AvatarP:SetPos(-1000,-1000)
    end
end

GM:Print(GM.Name .. " loaded!")
GM:Print("Created by Velkon (http://steamcommunity.com/profiles/76561198154133184)")