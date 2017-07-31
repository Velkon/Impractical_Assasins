GM.Name = "Impractical Assassins"
-- Impractical Assassins ?

GM.Author = "Velkon / Kevlon"
GM.Email = "http://steamcommunity.com/profiles/76561198154133184"
GM.Website = "http://steamcommunity.com/profiles/76561198154133184"
GM.RoundState = 0
-- 0 = Round prep
-- 1 = Playing
-- 2 = After round
GM.RoundStart = 0


function GM:Print(...)
    MsgC(Color(255,255,255),"[",Color(0,255,0),(GM or GAMEMODE).Name,Color(255,255,255),"] ",Color(240,240,240),...,"\n")
end 

function GM:StartCommand( ply, cmd )
    if not ply.WrongTime then return end
    if ply.WrongTime > CurTime() then
        cmd:RemoveKey(IN_ATTACK)
        cmd:RemoveKey(IN_ATTACK2)
    end
end

function GM:ShouldCollide(a,b)
    if a:IsPlayer() and b:IsPlayer() and GAMEMODE.RoundState == 0 then
        return false
    end
    return true
end

if CLIENT then
    function GM:CreateMove(cmd)
        if not LocalPlayer().WrongTime then return end
        if LocalPlayer().WrongTime > CurTime() then
            cmd:RemoveKey(IN_ATTACK)
            cmd:RemoveKey(IN_ATTACK2)
        end
    end
end