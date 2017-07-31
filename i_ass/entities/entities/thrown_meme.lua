AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.AutomaticFrameAdvance = true
ENT.AdminOnly = true


if CLIENT then
    function ENT:Draw()
        self:DrawModel()
    end

    function ENT:Initialize()
    end
else
    

    function ENT:Initialize()
        self:SetModel( "models/weapons/w_knife_t.mdl" )
        self:PhysicsInit( SOLID_VPHYSICS )
        self:SetSolid( SOLID_VPHYSICS )
        self:SetMoveType( MOVETYPE_VPHYSICS )
    end

    function ENT:Touch(ent)
        --self:EmitSound("weapons/crowbar/crowbar_impact2.wav")
        --self:SetMoveType(MOVETYPE_NONE)
    end

    function ENT:PhysicsCollide(data,b)
        if self.RemoveMe then SafeRemoveEntity(self) return end
        if self.DoThing then return end
        local ply = data.HitEntity
        if IsValid(ply) then
            if ply:IsPlayer() then
                local dmg = DamageInfo()
		        dmg:SetDamage(100)
		        dmg:SetAttacker(self.Owner)
                dmg:SetDamagePosition(data.HitPos)
                dmg:SetDamageForce(data.HitPos:Angle():Forward()*30)
                ply.ThrownDamage = true
		        ply:TakeDamageInfo(dmg)
                ply:EmitSound("Weapon_Crowbar.Melee_Hit")
                self.RemoveMe = true
            end
        end
        self.DoThing = true
    end

  /*  hook.Add("EntityTakeDamage","RealSnow",function(ent,dmg)
        if IsValid(ent) then
            if ent:IsPlayer() then
                if IsValid(dmg:GetAttacker()) then
                    if dmg:GetAttacker():GetClass() == "realsnow_snowball" then
                        if realsnow.Extra.snowballdamage then
                            ent:TakeDamage( realsnow.Extra.snowballdamage, dmg:GetAttacker().Owner, dmg:GetAttacker() )
                            return true
                        else
                            return true
                        end
                    end
                end
            end
        end
    end) */

end