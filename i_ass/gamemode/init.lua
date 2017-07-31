AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")
include("config.lua")

concommand.Add(GM.Name .. "_round_restart",function(ply)
    if IsValid(ply) then return end
    GAMEMODE.RoundState = 2
    GAMEMODE.RoundPrep = 1
end)

function GM:Cvar(name,value,help)
    help = help or ""
    if not ConVarExists((GM or GAMEMODE).Name .. "_" .. name) then
        return CreateConVar((GM or GAMEMODE).Name .. "_" .. name, value, FCVAR_ARCHIVE,help)
    end
    return GetConVar((GM or GAMEMODE).Name .. "_" .. name)
end
GM:Cvar("round_playing_time",30)
GM:Cvar("round_end_time",10)
GM:Cvar("round_prep_time",10)
GM:Cvar("wrongattack_waittime",10,"Seconds for how long someone must wait before they can attack again if they attacked the wrong person.")
GM:Cvar("knife_respawn_time",3,"Seconds on how long they must wait for their knife to come back.")

GM.UsedModels = {}

local PLAYER = FindMetaTable("Player")

util.AddNetworkString("GetRoundTime")
util.AddNetworkString("RoundStart")
util.AddNetworkString("RoundEnd")
util.AddNetworkString("RoundPrep")
util.AddNetworkString("GetTarget")
util.AddNetworkString("RoundWin")
util.AddNetworkString("WrongPerson")
util.AddNetworkString("KnifeTime")
util.AddNetworkString("KillStreak")
util.AddNetworkString("YouDied")

function PLAYER:StartSpectate(mode, ent)
    self:Spectate(mode)
    self.Specing = true
    if IsValid(ent) then
        self:SpectateEntity(ent)
        self.EntSpec = ent
    else
        self.EntSpec = nil
    end
    self.SpecCool = CurTime() + 0.2
end

function PLAYER:NextSpec(m)
    m = m or 1
    local p = {}
    local i = 0
    for k,v in pairs(player.GetAll()) do
        if v:Alive() then
            table.insert(p,v)
            if v == self.EntSpec then
                i = #p
            end
        end
    end

    i = i + m
    if #p > 0 then
        if not p[i] then
            i = 1
        end
        self:StartSpectate(OBS_MODE_CHASE,p[i])
        self.EntSpec = p[i  ]
    else
        self:StartSpectate(OBS_MODE_ROAMING)
        self.EntSpec = nil
    end

end

function PLAYER:SpectateThink()
    if not self.Specing then return end
    if self.SpecCool > CurTime() then return end
    local meme 
    if self:KeyDown(IN_ATTACK) then
        meme = 1
    elseif self:KeyDown(IN_ATTACK2) then
        meme = -1
    end
    if meme then
        self:NextSpec(meme)
    end

    if not IsValid(self.EntSpec) then
        self:NextSpec()
        return
    elseif not self.EntSpec:Alive() then
        self:NextSpec()
    end
end

function GM:CanPlayerSuicide(ply)
    return true
end

GM_Started = GM_Started or false

function GM:PlayerSpawn( ply )
    ply.Pursuers = {}
    ply.Target = nil
    if not ply.Streak then ply.Streak = 0 end
    if ply.Specing then
        ply.Streak = 0
        ply.Specing = false
    end
	--
	-- If the player doesn't have a team in a TeamBased game
	-- then spawn him as a spectator
	--
	if ( GAMEMODE.RoundState > 0 ) then

		self:PlayerSpawnAsSpectator( ply )
		return
	
	end

	-- Stop observer mode
	ply:UnSpectate()

	ply:SetupHands()

	player_manager.OnPlayerSpawn( ply )
	player_manager.RunClass( ply, "Spawn" )

	-- Call item loadout function
	hook.Call( "PlayerLoadout", GAMEMODE, ply )
	
	-- Set player model
	hook.Call( "PlayerSetModel", GAMEMODE, ply )

end


function GM:GetUniqueModel()
    local models = player_manager.AllValidModels()
    while true do
        local a = table.Random(models)
        if not self.UsedModels[a] then
            self.UsedModels[a] = true
            return a
        end
        if #self.UsedModels == #models then
            return a
        end
    end
end

function GM:PlayerLoadout(ply)
    ply.ThrownDamage = false
    ply:StripWeapons()
    ply:SetModel(self:GetUniqueModel())
    ply:SetPlayerColor( Vector( math.random(), math.random(), math.random() ) )
    -- If you want people to have custom player models and shit, just set their model later on.
end

function GM:Initialize()
    
end

function GM:GetTarget(ply)
    local p = {}
    for k,v in RandomPairs(player.GetAll()) do
        if not v:Alive() or v == ply then continue end
        if table.HasValue(v.Pursuers,ply) then continue end
        if ply.Target == v then continue end
        p[#p+1] = v
    end
    table.sort(p,function(a,b)
        return #a.Pursuers < #b.Pursuers 
    end)
    if IsValid(p[1]) then
        table.insert(p[1].Pursuers,ply)
        ply.Target = p[1]
        print(ply,"->",p[1])
        return p[1]
    else
        return nil
    end
end  

function GM:DoRoundStart()
    GAMEMODE.RoundState = 1
    local t = GAMEMODE:Cvar("round_playing_time",30):GetInt()
    net.Start("RoundStart")
    net.WriteInt(CurTime() + (t),32)
    net.Broadcast()
    GAMEMODE.RoundEnd = CurTime() + (t)
    GAMEMODE:Print("A new round has started..")
    for k,v in pairs(player.GetAll()) do
        if not v:Alive() then continue end
        v:Give("meme_knife")
        if not v.Target then
            local a = GAMEMODE:GetTarget(v)
            if IsValid(a) then
                net.Start("GetTarget")
                net.WriteEntity(a)
                net.Send(v)
            end
        end
    end
end
 
function GM:DoRoundEnd()
    GAMEMODE.RoundState = 2
    local t = GAMEMODE:Cvar("round_end_time",10):GetInt()
    net.Start("RoundEnd")
    net.WriteInt(CurTime() + (t),32)
    net.Broadcast()
    GAMEMODE.RoundPrep = CurTime() + t
    GAMEMODE:Print("Ending playing round..")
end

function GM:DoRoundPrep()
    self.UsedModels = {}
    GAMEMODE.RoundState = 0
    local t = GAMEMODE:Cvar("round_prep_time",10):GetInt()
    net.Start("RoundPrep")
    net.WriteInt(CurTime() + (t),32)
    net.Broadcast()
    GAMEMODE.RoundStart = CurTime() + t
    GAMEMODE:Print("Entering round prep..")
    for k,v in pairs(player.GetAll()) do
        if v.NotPlaying then continue end
        v:Spawn()
        local a = GAMEMODE:GetTarget(v)
        if IsValid(a) then
            net.Start("GetTarget")
            net.WriteEntity(a)
            net.Send(v)
        end
    end
end

function GM:PlayerDeathSound()
    return true
end

function GM:Think()
    if not GM_Started then return end
    if GAMEMODE.RoundState == 0 then
        for k,v in pairs(player.GetAll()) do
            if not v.Target and v:Alive() then
                local a = GAMEMODE:GetTarget(v)
                if IsValid(a) then
                    net.Start("GetTarget")
                    net.WriteEntity(a)
                    net.Send(v)
                end
            end
        end
        for k,v in pairs(ents.GetAll()) do
            if v:GetClass() == "thrown_meme" then
                SafeRemoveEntity(v)
            end
        end
    end
    local won
    if GAMEMODE.RoundState == 1 then
        local i = 0
        local p = nil
        for k,ply in ipairs(player.GetAll()) do
            if not ply:Alive() then continue end
            i = i + 1
            p = ply
            if ply.WrongTime then
                if ply.WrongTime < CurTime() then
                    ply:Give("meme_knife")
                    ply.WrongTime = nil
                end
            end

            if ply.WaitingForKnife then
                if GAMEMODE.RoundState > 0 and not ply:HasWeapon("meme_knife") and ply.WaitingForKnife < CurTime() then
                    if not ply.WrongTime then
                        ply:Give("meme_knife")
                        ply.WaitingForKnife = nil
                    end
                    if IsValid(ply.Knife) then
                        SafeRemoveEntity(ply.Knife)
                    end
                end
            end


        end
        if (i==1) then
            GAMEMODE:Print(p:Nick().. " is the last one standing!")
            GAMEMODE.RoundEnd = 1
            net.Start("RoundWin")
            net.WriteEntity(p)
            net.Broadcast()
            won = true
        end
    end
    if (GAMEMODE.RoundState == 0) and (GAMEMODE.RoundStart < CurTime()) then
        GAMEMODE:DoRoundStart()
    elseif (GAMEMODE.RoundState == 1) and (GAMEMODE.RoundEnd < CurTime()) then
        GAMEMODE:DoRoundEnd()
        if not won then
            for k,v in pairs(player.GetAll()) do
                v:ChatPrint("There are no winners! You ran out of time!")
            end
        end
    elseif (GAMEMODE.RoundState == 2) and (GAMEMODE.RoundPrep < CurTime()) then
        GAMEMODE:DoRoundPrep()
    end
end

function GM:PlayerDeathThink(ply)
    if GAMEMODE.RoundState == 0 then
        ply:Spawn()
    else
        ply:SpectateThink()
    end
end

function GM:PlayerInitialSpawn(ply)
    ply:SetCustomCollisionCheck(true)
    if #player.GetAll() < 2 then GM_Started = false return end
    if not GM_Started and #player.GetAll() > 1 then
        for k,v in pairs(player.GetAll()) do
            v:Spawn()
        end
        GAMEMODE.RoundStart = CurTime() + 45
        GAMEMODE:Print("Starting first round in 45 seconds..")
        GM_Started = true
        net.Start("GetRoundTime")
        net.WriteInt(GAMEMODE.RoundState,8)

        if GAMEMODE.RoundState == 0 then
            net.WriteInt(GAMEMODE.RoundStart,32)
        elseif GAMEMODE.RoundState == 1 then
            net.WriteInt(GAMEMODE.RoundEnd,32)
        elseif GAMEMODE.RoundState == 2 then
            net.WriteInt(GAMEMODE.RoundPrep,32)
        end

        net.Broadcast()
    else
        net.Start("GetRoundTime")
        net.WriteInt(GAMEMODE.RoundState,8)

        if GAMEMODE.RoundState == 0 then
            net.WriteInt(GAMEMODE.RoundStart,32)
        elseif GAMEMODE.RoundState == 1 then
            net.WriteInt(GAMEMODE.RoundEnd,32)
        elseif GAMEMODE.RoundState == 2 then
            net.WriteInt(GAMEMODE.RoundPrep,32)
        end

        net.Send(ply)
    end

end

function GM:ScalePlayerDamage( ply, hitgroup, dmginfo )
    dmginfo:ScaleDamage(500)
end

function GM:EntityTakeDamage(ply,dmg)
    if GAMEMODE.RoundState == 0 then return true end -- ??
    if GAMEMODE.RoundState ~= 1 then return end
    if not ply:IsPlayer() then return end
    if not dmg:GetAttacker():IsValid() then return true end
    if not dmg:GetAttacker():IsPlayer() then return true end
    if dmg:GetAttacker().Target == ply then
        return
    end
    if not table.HasValue(ply.Pursuers,dmg:GetAttacker()) and not table.HasValue(dmg:GetAttacker().Pursuers,ply) then 
        dmg:GetAttacker():ChatPrint("You attacked the wrong person!")
        local t = GAMEMODE:Cvar("wrongattack_waittime",4,"Seconds for how long someone must wait before they can attack again if they attacked the wrong person."):GetInt()
        dmg:GetAttacker().WrongTime = CurTime() + t
        dmg:GetAttacker():StripWeapons()
        net.Start("WrongPerson")
        net.WriteInt(t,32) -- This doesn't need to be networked like this but I'm lazy
        net.Send(dmg:GetAttacker())
        return true
    end
end

function GM:DoPlayerDeath(ply,killer)
    ply:CreateRagdoll()
    ply:StripWeapons()
    ply:StartSpectate(OBS_MODE_CHASE,killer)
end

function GM:PlayerDisconnected( ply )
    if GAMEMODE.RoundState ~= 1 then return end
    for k,v in pairs(ply.Pursuers) do
        if not IsValid(v) then continue end
        if not v:Alive() then continue end
        local a = GAMEMODE:GetTarget(v)
        if IsValid(a) then
            net.Start("GetTarget")
            net.WriteEntity(a)
            net.Send(v)
            v:ChatPrint("Your target disconnected!")
        end
    end
end

function GM:SendKiller(ply,killer)
    net.Start("YouDied")
    net.WriteEntity(killer)
    net.WriteBool(killer.Target == ply)
    net.WriteBool(ply.ThrownDamage == true)
    net.Send(ply)
    print("You died")
    print(killer)
    print(killer.Target == ply)
    print(ply.ThrownDamage == true)
    print("->",ply)
end

function GM:PlayerDeath(ply,inflictor,killer)
    if GAMEMODE.RoundState ~= 1 then return end
    if IsValid(killer) then
        if killer:IsPlayer() then
            self:SendKiller(ply,killer)
            if killer == ply then
                for k,v in pairs(ply.Pursuers) do
                    if not IsValid(v) then continue end
                    if not v:Alive() then continue end
                    local a = GAMEMODE:GetTarget(v)
                    if IsValid(a) then
                        net.Start("GetTarget")
                        net.WriteEntity(a)
                        net.Send(v)
                        v:ChatPrint("Your target died somehow!")
                    end
                end
                ply.Pursuers = {}
                return
            end
            if killer.Target == ply then
                killer:ChatPrint("Nice kill!")
                killer:Give("meme_knife")
                killer.Streak = killer.Streak + 1
                if killer.Streak > 1 then
                    net.Start("KillStreak")
                    net.WriteEntity(killer)
                    net.WriteInt(killer.Streak,32)
                    net.Broadcast()
                end
                local a = GAMEMODE:GetTarget(killer)
                if IsValid(a) then
                    net.Start("GetTarget")
                    net.WriteEntity(a)
                    net.Send(killer)
                end

                for k,v in pairs(ply.Pursuers) do
                    if not IsValid(v) then continue end
                    if not v:Alive() then continue end
                    if v == killer then continue end
                    local a = GAMEMODE:GetTarget(v)
                    if IsValid(a) then
                        net.Start("GetTarget")
                        net.WriteEntity(a)
                        net.Send(v)
                        v:ChatPrint("Your target was killed by someone else!")
                    end
                end
                ply.Pursuers = {}
                return
            elseif table.HasValue(killer.Pursuers,ply) then
                for k,v in pairs(ply.Pursuers) do
                    if not IsValid(v) then continue end
                    if not v:Alive() then continue end
                    if v == killer then continue end
                    local a = GAMEMODE:GetTarget(v)
                    if IsValid(a) then
                        net.Start("GetTarget")
                        net.WriteEntity(a)
                        net.Send(v)
                        v:ChatPrint("Your target was killed by someone else!")
                    end
                end
                ply.Pursuers = {}
                killer:ChatPrint("that was your pursuer!")
                killer:Give("meme_knife")
                killer.Streak = killer.Streak + 1
                if killer.Streak > 1 then
                    net.Start("KillStreak")
                    net.WriteEntity(killer)
                    net.WriteInt(killer.Streak,32)
                    net.Broadcast()
                end
                return
            end
        else
            for k,v in pairs(ply.Pursuers) do
                if not IsValid(v) then continue end
                if not v:Alive() then continue end
                local a = GAMEMODE:GetTarget(v)
                if IsValid(a) then
                    net.Start("GetTarget")
                    net.WriteEntity(a)
                    net.Send(v)
                    v:ChatPrint("Your target died somehow!")
                end
            end
            ply.Pursuers = {}
            return
            print(2)
        end
    else
        print(3)
        for k,v in pairs(ply.Pursuers) do
            if not IsValid(v) then continue end
            if not v:Alive() then continue end
            local a = GAMEMODE:GetTarget(v)
            if IsValid(a) then
                net.Start("GetTarget")
                net.WriteEntity(a)
                net.Send(v)
                v:ChatPrint("Your target died somehow!")
            end
        end
        ply.Pursuers = {}
        return
    end
    print(4)
end

GM:Print(GM.Name .. " loaded!")
GM:Print("Created by Velkon (http://steamcommunity.com/profiles/76561198154133184)")