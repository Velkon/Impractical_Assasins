AddCSLuaFile()

if CLIENT then
    SWEP.DrawAmmo = false
    SWEP.DrawCrosshair = true
end

SWEP.PrintName = "Knife"
SWEP.Author = "Velkon"
SWEP.Contact = "steamcommunity.com/id/Velkon_gmod/"
SWEP.Purpose = "Kill people"
SWEP.IconLetter = ""
SWEP.ViewModelFOV = 55
SWEP.ViewModelFlip = false
SWEP.ViewModel = "models/weapons/v_knife_t.mdl"
SWEP.WorldModel = "models/weapons/w_knife_t.mdl"

--local throwing_sound = Sound()
--local make_snowball_sound = Sound()

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 0
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = ""

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 0
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = ""


function SWEP:Initialize()
end

function SWEP:Deploy()
    self:SetHoldType("knife")
    return true
end

function SWEP:SetupDataTables()
    --self:NetworkVar( "Bool", 0, "Snowball" )
end

function SWEP:Think()

end
function SWEP:OnDrop()
    self:Remove()
end

function SWEP:ViewModelDrawn(vm)
end

function SWEP:Holster()
    return false
end

function SWEP:OnRemove()

end

function SWEP:SecondaryAttack()
    self.Owner:SetAnimation( PLAYER_ATTACK1 )
    self.Weapon:SendWeaponAnim(ACT_VM_THROW)
    if SERVER then
        local a = ents.Create("thrown_meme")
        if not IsValid(a) then return end
        a:SetPos(self.Owner:EyePos()+(self.Owner:GetAimVector()*30))
        a:SetAngles( self.Owner:EyeAngles() )
        a:Spawn()
        a:Activate()
        util.SpriteTrail(a, 0, self.Owner:GetPlayerColor():ToColor(), true, 5, 5, 1, 1/(5+5)*0.5, "trails/smoke.vmt")
        a.Owner = self.Owner
        local phys = a:GetPhysicsObject()
        phys:Wake()
        phys:ApplyForceCenter(self.Owner:GetVelocity() + self.Owner:GetAimVector():GetNormalized() * (1000))
        phys:AddAngleVelocity(Vector(0,2000,0))
        self.Owner:EmitSound("weapons/slam/throw.wav")
        self:Remove()
        local ply = self.Owner
        ply.Knife = a
        ply.WaitingForKnife = CurTime() + GAMEMODE:Cvar("knife_respawn_time",3):GetInt()
        net.Start("KnifeTime")
        net.WriteInt(CurTime() + GAMEMODE:Cvar("knife_respawn_time",3):GetInt(),32)
        net.Send(ply)
    end
    return true
end

function SWEP:PrimaryAttack()
    self.Owner:SetAnimation( PLAYER_ATTACK1 )
    local vm = self.Owner:GetViewModel()
    vm:SendViewModelMatchingSequence(vm:LookupSequence("midslash" .. (math.random() > 0.5 and "1" or "2")))
    self:SetNextPrimaryFire(CurTime() + 0.5)
    if CLIENT then 
        self.Owner:EmitSound("Weapon_Crowbar.Single")
        local bullet = {}
        bullet.Num = 1
        bullet.HullSize = 10
        bullet.Src = self.Owner:GetShootPos()
        bullet.Dir = self.Owner:GetAimVector()
        bullet.Spread   = Vector(0,0, 0)
        bullet.Tracer = 0
        bullet.Distance = 50
        bullet.Force = 0
        bullet.Damage = 0
        self.Owner:FireBullets(bullet)
    return end
    local bullet = {}
	bullet.Num = 10
    bullet.HullSize = 10
	bullet.Src = self.Owner:GetShootPos()
	bullet.Dir = self.Owner:GetAimVector()
	bullet.Spread   = Vector(0.1,0.1, 0)
	bullet.Tracer = 0
    bullet.Distance = 50
	bullet.Force = 1
	bullet.Damage = 5000
	self.Owner:FireBullets(bullet)
end

function SWEP:Reload()
end
