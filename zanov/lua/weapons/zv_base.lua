AddCSLuaFile()
include("zv_attachments.lua")
include("zv_viewmodel.lua")
include("zv_effects.lua")

SWEP.IsZv = true
SWEP.PrintName = "Zv Base"
SWEP.Category = "ZV"
SWEP.DrawWeaponInfoBox = false
SWEP.Spawnable = false
SWEP.AdminOnly = false
SWEP.ViewModelFOV = 55
SWEP.UseHands = true
SWEP.Slot = 1
SWEP.SlotPos = 1
SWEP.CSMuzzleFlashes = false
SWEP.IsShotgun = false
SWEP.ShellInsert = 0.5

SWEP.Primary.Sound = Sound("Weapon_Pistol.Single")
SWEP.Primary.Recoil = 0.8
SWEP.Primary.Damage = 5
SWEP.Primary.NumShots = 1
SWEP.Primary.Cone = 0.03
SWEP.Primary.Delay = 0.13
SWEP.Primary.Ammo = "pistol"
SWEP.Primary.Automatic = false
SWEP.Primary.ClipSize = 12
SWEP.Primary.DefaultClip = 12

SWEP.Secondary.Ammo = "none"
SWEP.Secondary.Automatic = false
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1

SWEP.EmptySound = Sound("Weapon_Pistol.Empty")
SWEP.WindUpSound = Sound("Weapon_AR2.Single")
SWEP.WindUpDuration = 2.0
SWEP.CanWindUp = false

SWEP.Spread = {
    Min = 0,
    Max = 0.1,
    IronsightsMod = 0.1,
    CrouchMod = 0.6,
    AirMod = 1.2,
    RecoilMod = 0.025,
    VelocityMod = 0.5
}

SWEP.IronsightsPos = Vector(-5.9613, -3.3101, 2.706)
SWEP.IronsightsAng = Angle(0, 0, 0)
SWEP.IronsightsFOV = 0.8
SWEP.IronsightsSensitivity = 0.8
SWEP.IronsightsCrosshair = false
SWEP.UseIronsightsRecoil = true
SWEP.CanRunGun = false
SWEP.ViewRollIntensity = 0.25
SWEP.ScreenShake = 0.25
SWEP.BulletForce = 1

SWEP.MuzzleEffects = {"muzzleflash", "muzzle_smoke"}

function SWEP:SetupDataTables()
    local netVars = {
        {"Bool", "Ironsights", 0},
        {"Bool", "Reloading", 1},
        {"Bool", "Bursting", 2},
        {"Bool", "WindingUp", 3},
        {"Bool", "ShotgunReloading", 4},
        {"String", "CurAttachment", 0},
        {"Float", "IronsightsRecoil", 1},
        {"Float", "Recoil", 2},
        {"Float", "ReloadTime", 3},
        {"Float", "NextIdle", 4},
        {"Float", "WindUpTime", 5},
        {"Float", "ShotgunReloadTime", 9},
        {"Vector", "BlowbackPos", 0},
        {"Angle", "BlowbackAng", 0},
        {"Float", "BlowbackTime", 6},
        {"Float", "BlowbackCurrent", 7},
        {"Float", "BlowbackRecoveryTime", 8},
    }
    for _, data in ipairs(netVars) do
        self:NetworkVar(data[1], data[3], data[2])
    end
    if self.ExtraDataTables then
        self.ExtraDataTables(self)
    end
end

function SWEP:Initialize()
    self.Blowback = self.Blowback or {
        Ang = Angle(-2, 0, 0),
        Amount = 0.3,
        Max = 3,
        Pos = Vector(0, 0, 0),
        Orientation = Angle(0, 0, 0),
        RecoveryTime = 1.5
    }
    
    self:SetIronsights(false)
    self:SetReloading(false)
    self:SetWindingUp(false)
    self:SetShotgunReloading(false)
    self:SetReloadTime(0)
    self:SetWindUpTime(0)
    self:SetShotgunReloadTime(0)
    self:SetRecoil(0)
    self:SetNextIdle(0)
    self.BlowbackCurrent = 0
    self:SetBlowbackCurrent(0)
    self:SetBlowbackRecoveryTime(self.Blowback.RecoveryTime)
    self:SetHoldType(self.HoldType)
    self.ShotgunReloadState = 0
    
    if SERVER and self.CustomMaterial then
        self:SetMaterial(self.CustomMaterial)
    end
    
    if CLIENT then
        self.ViewModelPos = Vector(0, 0, 0)
        self.ViewModelAngle = Angle(0, 0, 0)
    end
end

local function ResetHoldType(self)
    if IsValid(self) then
        self:SetHoldType(self.HoldType)
    end
end

function SWEP:OnReloaded()
    timer.Simple(0, ResetHoldType, self)
end

function SWEP:PlayAnim(act)
    if not IsValid(self.Owner) then return end
    local vmodel = self.Owner:GetViewModel()
    if not IsValid(vmodel) then return end
    
    local seq = vmodel:SelectWeightedSequence(act)
    if seq >= 0 then
        vmodel:SendViewModelMatchingSequence(seq)
    end
end

function SWEP:PlayAnimWorld(act)
    local seq = self:SelectWeightedSequence(act)
    if seq >= 0 then
        self:ResetSequence(seq)
    end
end

function SWEP:Deploy()
    if not IsValid(self.Owner) then return end
    
    if self:GetShotgunReloading() then
        self:SetShotgunReloading(false)
        self.ShotgunReloadState = 0
        self:SetShotgunReloadTime(0)
    end
    
    if CLIENT and self.CustomMaterial then
        local vm = self.Owner:GetViewModel()
        if IsValid(vm) then
            vm:SetMaterial(self.CustomMaterial)
            self.CustomMatSetup = true
        end
    end
    
    self:PlayAnim(ACT_VM_DRAW)
    self.Owner:GetViewModel():SetPlaybackRate(1)
    
    return true
end

function SWEP:ShootBullet(damage, num_bullets, aimcone)
    if not IsValid(self.Owner) then return end
    
    local bullet = {
        Num = num_bullets,
        Src = self.Owner:GetShootPos(),
        Dir = self.Owner:GetAimVector(),
        Spread = Vector(aimcone, aimcone, 0),
        Tracer = 1,
        Force = self.BulletForce,
        Damage = damage,
        AmmoType = ""
    }
    
    if self.Primary.Tracer then bullet.TracerName = self.Primary.Tracer end
    if self.Primary.Range then bullet.Distance = self.Primary.Range end

    self.Owner:FireBullets(bullet)
    self:ShootEffects()
end
function SWEP:ShootEffects()
    if not IsValid(self.Owner) then return end
    
    if not self:GetIronsights() or not self.UseIronsightsRecoil then
        self:PlayAnim(ACT_VM_PRIMARYATTACK)
        self:QueueIdle()
    else
        self:SetIronsightsRecoil(math.Clamp(7.5 * (self.IronsightsRecoilVisualMultiplier or 1) * self.Primary.Recoil, 0, 20))
    end
    
    local rollIntensity = (self.ViewRollIntensity or 3) * self.Primary.Recoil
    local viewPunch = Angle(0, 0, math.Rand(-1, 1) * rollIntensity)
    self.Owner:ViewPunch(viewPunch)

    if CLIENT then
        local ply = LocalPlayer()
        if ply == self.Owner then
            ply:SetViewPunchAngles(Angle(
                ply:GetViewPunchAngles().p, 
                ply:GetViewPunchAngles().y, 
                ply:GetViewPunchAngles().r + math.Rand(-1, 1) * rollIntensity
            ))
            
            if self.ScreenShake then
                util.ScreenShake(ply:GetPos(), self.ScreenShake, 0.1, 0.15, 45)
            end
        end
    end
    
    -- Play custom muzzle effects (CLIENT only)
    if CLIENT then
        self:PlayMuzzleEffects()
    end
    
    if SERVER and self.MuzzleLight then
        local attachment = self:LookupAttachment("muzzle")
        local posang = self:GetAttachment(attachment)
        local lightPos = posang and posang.Pos or (self.Owner:GetShootPos() + self.Owner:GetAimVector() * 20)
        
        local lightParams = self.MuzzleLight
        local light = ents.Create("light_dynamic")
        if IsValid(light) then
            light:SetPos(lightPos)
            light:SetKeyValue("brightness", lightParams.brightness or "2")
            light:SetKeyValue("distance", lightParams.size or "256")
            light:SetKeyValue("_light", string.format("%d %d %d 255", 
                lightParams.r or 255, 
                lightParams.g or 238, 
                lightParams.b or 185))
            light:SetKeyValue("style", "0")
            light:SetParent(self)
            light:Spawn()
            light:Fire("TurnOn", "", 0)
            timer.Simple(lightParams.duration or 0.05, function()
                if IsValid(light) then
                    light:Remove()
                end
            end)
        end
    end
    
    if CLIENT then
        local isThirdperson = hook.Run("ShouldDrawLocalPlayer", self.Owner)
        if not isThirdperson then
            local vm = self.Owner:GetViewModel()
            if IsValid(vm) then
                local attachment = vm:LookupAttachment("muzzle")
                local posang = vm:GetAttachment(attachment)
                
                if posang then
                    local ef = EffectData()
                    ef:SetOrigin(self.Owner:GetShootPos())
                    ef:SetStart(self.Owner:GetShootPos())
                    ef:SetNormal(self.Owner:EyeAngles():Forward())
                    ef:SetEntity(vm)
                    ef:SetAttachment(attachment)
                    ef:SetScale(self.IronsightsMuzzleFlashScale or 1)
                    util.Effect(self.IronsightsMuzzleFlash or "CS_MuzzleFlash", ef)
                    
                    if self.MuzzleLight then
                        local lightParams = self.MuzzleLight
                        local dlight = DynamicLight(self:EntIndex())
                        if dlight then
                            dlight.pos = posang.Pos
                            dlight.r = lightParams.r or 255
                            dlight.g = lightParams.g or 238
                            dlight.b = lightParams.b or 185
                            dlight.brightness = lightParams.brightness or 2
                            dlight.Decay = lightParams.decay or 1000
                            dlight.Size = lightParams.size or 256
                            dlight.DieTime = CurTime() + (lightParams.duration or 0.05)
                        end
                    end
                end
            end
        end
    end
    
    self.Owner:MuzzleFlash()
    self:PlayAnimWorld(ACT_VM_PRIMARYATTACK)
    self.Owner:SetAnimation(PLAYER_ATTACK1)
end
function SWEP:IsSprinting()
    if not IsValid(self.Owner) then return false end
    return (self.Owner:GetVelocity():Length2D() > self.Owner:GetRunSpeed() - 50) and self.Owner:IsOnGround()
end

function SWEP:StartWindUp()
    if not self.CanWindUp or self:GetWindingUp() then return end
    
    self:SetWindingUp(true)
    self:SetWindUpTime(CurTime() + self.WindUpDuration)
    
    if self.WindUpSound then
        self:EmitSound(self.WindUpSound)
    end
    
    self:SetNextPrimaryFire(CurTime() + self.WindUpDuration)
end

function SWEP:StartWindUp()
    if not self.CanWindUp or self:GetWindingUp() then return end
    
    self:SetWindingUp(true)
    self:SetWindUpTime(CurTime() + self.WindUpDuration)
    
    if self.WindUpSound then
        self:EmitSound(self.WindUpSound)
    end
    
    self:SetNextPrimaryFire(CurTime() + self.WindUpDuration)
end

function SWEP:PrimaryAttack()
    if self:GetShotgunReloading() then
        self:SetShotgunReloading(false)
        self.ShotgunReloadState = 0
        self:SetShotgunReloadTime(0)
        self:SetNextPrimaryFire(CurTime() + 0.5)
        return
    end
    
    if not self:CanShoot() then return end
    
    if self.CanWindUp and not self:GetWindingUp() and not self.WindUpComplete then
        self:StartWindUp()
        return
    end
    
    if self.CanWindUp and self:GetWindingUp() then
        return
    end
    
    local clip = self:Clip1()
    if self.Primary.Burst and clip >= 3 then
        self:SetBursting(true)
        self.Burst = 3
        local delay = CurTime() + ((self.Primary.Delay * 3) + (self.Primary.BurstEndDelay or 0.3))
        self:SetNextPrimaryFire(delay)
        self:SetReloadTime(delay)
    elseif clip >= 1 then
        self:TakePrimaryAmmo(1)
        self:EmitSound(self.Primary.Sound)
        self:ShootBullet(self.Primary.Damage, self.Primary.NumShots, self:CalculateSpread())
        self:AddRecoil()
        self:ViewPunch(self.Blowback.Ang)
        self.BlowbackCurrent = math.min(self.BlowbackCurrent + self.Blowback.Amount, self.Blowback.Max)
        self:SetBlowbackCurrent(self.BlowbackCurrent)
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    if CLIENT then
        self:PlayMuzzleEffects() -- Add this line
    end 
        self:SetReloadTime(CurTime() + self.Primary.Delay)
    else
        self:EmitSound(self.EmptySound)
        self:Reload()
        self:SetNextPrimaryFire(CurTime() + 1)
    end
end
function SWEP:SecondaryAttack() 
end

function SWEP:Holster()
    self:SetIronsights(false)
    self:SetIronsightsRecoil(0)
    self:SetReloading(false)
    self:SetWindingUp(false)
    self:SetShotgunReloading(false)
    self:SetReloadTime(0)
    self:SetWindUpTime(0)
    self:SetShotgunReloadTime(0)
    self:SetRecoil(0)
    self:SetNextIdle(0)
    self.WindUpComplete = false
    self.ShotgunReloadState = 0
    
    if CLIENT then
        self.ViewModelPos = Vector(0, 0, 0)
        self.ViewModelAngle = Angle(0, 0, 0)
        self.FOV = nil
        if self.CustomMaterial and IsValid(self.Owner) and self.Owner == LocalPlayer() and IsValid(self.Owner:GetViewModel()) then
            self.Owner:GetViewModel():SetMaterial("")
        end
        if self.AttachmentModels then
            for name, model in pairs(self.AttachmentModels) do
                if IsValid(model) then
                    model:SetNoDraw(true)
                end
            end
        end
    end
    
    if self.ExtraHolster then
        self.ExtraHolster(self)
    end
    
    return true
end
function SWEP:OnRemove()
    if CLIENT then
        if self.CustomMaterial and IsValid(self.Owner) and self.Owner == LocalPlayer() and IsValid(self.Owner:GetViewModel()) then
            self.Owner:GetViewModel():SetMaterial("")
        end
        
        if IsValid(self.AttachedCosmetic) then
            self.AttachedCosmetic:Remove()
        end
        
        if self.AttachmentModels then
            for name, model in pairs(self.AttachmentModels) do
                if IsValid(model) then
                    model:Remove()
                end
            end
            self.AttachmentModels = {}
        end
    end
end

function SWEP:QueueIdle()
    if not IsValid(self.Owner) then return end
    local vm = self.Owner:GetViewModel()
    if not IsValid(vm) then return end
    
    self:SetNextIdle(CurTime() + vm:SequenceDuration() + 0.1)
end

function SWEP:IdleThink()
    if self:GetNextIdle() == 0 then return end
    
    if CurTime() > self:GetNextIdle() then
        self:SetNextIdle(0)
        if self:Clip1() > 0 then
            self:SendWeaponAnim(ACT_VM_IDLE)
        else
            self:SendWeaponAnim(ACT_VM_IDLE_EMPTY)
        end
    end
end

function SWEP:WindUpThink()
    if not self:GetWindingUp() then 
        if self.WindUpComplete and not self.Owner:KeyDown(IN_ATTACK) then
            self.WindUpComplete = false
        end
        return 
    end
    
    if CurTime() >= self:GetWindUpTime() then
        self:SetWindingUp(false)
        self:SetWindUpTime(0)
        self.WindUpComplete = true
        
        if self.Owner:KeyDown(IN_ATTACK) then
            self:SetNextPrimaryFire(CurTime())
        end
    end
end

function SWEP:Think()
    if not IsValid(self.Owner) then return end
    
    self:IronsightsThink()
    self:RecoilThink()
    self:IdleThink()
    self:WindUpThink()
    
    if self:GetBursting() then self:BurstThink() end
    if self:GetReloading() then self:ReloadThink() end
    if self:GetShotgunReloading() then self:ShotgunReloadThink() end
    
    if CLIENT then
        local attach = self:GetCurAttachment()
        self.KnownAttachment = self.KnownAttachment or ""
        if self.KnownAttachment != attach then
            if self.Attachments and self.Attachments[attach] then
                self:SetupModifiers(attach)
            elseif attach == "" and self.Attachments and self.Attachments[self.KnownAttachment] then
                self:RollbackModifiers(self.KnownAttachment)
            end
            self.KnownAttachment = attach
        end
    end
end

function SWEP:AddRecoil()
    self:SetRecoil(math.Clamp(self:GetRecoil() + self.Primary.Recoil * 0.4, 0, 1))
end

function SWEP:RecoilThink()
    self:SetRecoil(math.Clamp(self:GetRecoil() - FrameTime() * 1.4, 0, 1))
end

function SWEP:BurstThink()
    if self.Burst and (self.nextBurst or 0) < CurTime() then
        self:TakePrimaryAmmo(1)
        self:ShootBullet(self.Primary.Damage, self.Primary.NumShots, self:CalculateSpread())
        self:AddRecoil()
        self:ViewPunch()
        self:EmitSound(self.Primary.Sound)
        self.Burst = self.Burst - 1
        
        if self.Burst < 1 then
            self:SetBursting(false)
            self.Burst = nil
        else
            self.nextBurst = CurTime() + self.Primary.Delay
        end    
    end
end

function SWEP:CanShoot()
    if not IsValid(self.Owner) then return false end
    
    local canShoot = self:CanPrimaryAttack() 
        and not self:GetBursting() 
        and not (self.LoweredPos and not self.CanRunGun and self:IsSprinting()) 
        and self:GetReloadTime() < CurTime()
        and not self:GetShotgunReloading()
    
    if self.CanWindUp then
        canShoot = canShoot and (not self:GetWindingUp() or CurTime() >= self:GetWindUpTime())
    end
    
    return canShoot
end

function SWEP:ViewPunch()
    if not IsValid(self.Owner) then return end
    
    local punch = Angle()
    local mul = self:GetIronsights() and 0.65 or 1
    
    punch.p = util.SharedRandom("ViewPunch", -1, 0.5) * self.Primary.Recoil * mul
    punch.y = util.SharedRandom("ViewPunch", -0.5, 0.5) * self.Primary.Recoil * mul
    punch.r = util.SharedRandom("ViewPunch", -0.5, 0.5) * self.ViewRollIntensity * mul
    self.Owner:ViewPunch(punch)
    
    if CLIENT or game.SinglePlayer() then
        local shake = self.Primary.Recoil * 0.2 * (self:GetIronsights() and 0.5 or 1)
        self.Owner:SetEyeAngles(self.Owner:EyeAngles() - Angle(shake * math.Rand(5, 1), shake * math.Rand(-1, 1), shake * math.Rand(-0.5, 0.5) * self.ViewRollIntensity * 0.1))
    end
end

function SWEP:CanIronsight()
    if not IsValid(self.Owner) then return false end
    
    local att = self:GetCurAttachment()
    if att != "" and self.Attachments and self.Attachments[att] and 
       self.Attachments[att].Behaviour == "sniper_sight" and 
       hook.Run("ShouldDrawLocalPlayer", self.Owner) then
        return false
    end
    
    return not self:IsSprinting() and self.Owner:IsOnGround()
end

function SWEP:IronsightsThink()
    if not IsValid(self.Owner) then return end
    
    self:SetIronsightsRecoil(math.Approach(self:GetIronsightsRecoil(), 0, FrameTime() * 100))
    self.BobScale = self:GetIronsights() and 0.1 or 1
    self.SwayScale = self:GetIronsights() and 0.1 or 1
    
    if not self:CanIronsight() then
        self:SetIronsights(false)
        return
    end
    
    if self.Owner:KeyDown(IN_ATTACK2) and not self:GetIronsights() then
        self:SetIronsights(true)
    elseif not self.Owner:KeyDown(IN_ATTACK2) and self:GetIronsights() then
        self:SetIronsights(false)
    end
end

function SWEP:CanReload()
    if self.IsShotgun then
        return self:Ammo1() > 0 
            and self:Clip1() < self.Primary.ClipSize
            and not self:GetShotgunReloading() 
            and self:GetNextPrimaryFire() < CurTime()
    else
        return self:Ammo1() > 0 
            and self:Clip1() < self.Primary.ClipSize
            and not self:GetReloading() 
            and self:GetNextPrimaryFire() < CurTime()
    end
end
function SWEP:Reload()
    if not self:CanReload() then return end
    if not IsValid(self.Owner) then return end
    
    if self.IsShotgun then
        if not self:GetShotgunReloading() then
            self:SetShotgunReloading(true)
            self.ShotgunReloadState = 1
            self:PlayAnim(ACT_SHOTGUN_RELOAD_START)
            self:SetShotgunReloadTime(CurTime() + 0.65)
            if self.ReloadStartSound then 
                self:EmitSound(self.ReloadStartSound)
            end
        end
    else
        self.Owner:DoReloadEvent()
        
        if not self.DoEmptyReloadAnim or self:Clip1() != 0 then
            self:PlayAnim(ACT_VM_RELOAD)
        else
            self:PlayAnim(ACT_VM_RELOAD_EMPTY)
        end
        
        self:QueueIdle() 
        
        if self.ReloadSound then 
            self:EmitSound(self.ReloadSound) 
        elseif self.OnReload then
            self.OnReload(self)
        end
        
        self:SetReloading(true)
        self:SetReloadTime(CurTime() + self.Owner:GetViewModel():SequenceDuration())
    end
end
function SWEP:StartShotgunReload()
    self:SetShotgunReloading(true)
    self:InsertShell()
end
function SWEP:InsertShell()
    if not IsValid(self.Owner) then return end
    
    self:PlayAnim(ACT_VM_RELOAD)
    
    if self.ReloadSound then 
        self:EmitSound(self.ReloadSound) 
    elseif self.OnReload then
        self.OnReload(self)
    end
    
    local amount = math.min(1, self:Ammo1())
    self:SetClip1(self:Clip1() + amount)
    self.Owner:RemoveAmmo(amount, self:GetPrimaryAmmoType())
    
    self.ShotgunReloadState = 2
    self:SetShotgunReloadTime(CurTime() + (self.ShellInsert or 0.68))
end
function SWEP:ShotgunReloadThink()
    if self:GetShotgunReloadTime() > CurTime() then return end
    
    if self.ShotgunReloadState == 1 then
        self:InsertShell()
    elseif self.ShotgunReloadState == 2 then
        if self:Clip1() < self.Primary.ClipSize and self:Ammo1() > 0 and self.Owner:KeyDown(IN_RELOAD) then
            self:InsertShell()
        else
            self:FinishShotgunReload()
        end
    elseif self.ShotgunReloadState == 3 then
        self:SetShotgunReloading(false)
        self.ShotgunReloadState = 0
        self:SetShotgunReloadTime(0)
        self:QueueIdle()
    end
end
function SWEP:FinishShellInsert()
    local amount = math.min(1, self:Ammo1())
    self:SetClip1(self:Clip1() + amount)
    self.Owner:RemoveAmmo(amount, self:GetPrimaryAmmoType())
    
    if self:Clip1() < self.Primary.ClipSize and self:Ammo1() > 0 and self.Owner:KeyDown(IN_RELOAD) then
        self:InsertShell()
    else
        self:FinishShotgunReload()
    end
end
function SWEP:FinishShotgunReload()
    self:PlayAnim(ACT_SHOTGUN_RELOAD_FINISH)
    self.ShotgunReloadState = 3
    self:SetShotgunReloadTime(CurTime() + 0.5)
end
function SWEP:ReloadThink()
    if self:GetReloadTime() < CurTime() then 
        self:FinishReload() 
    end
end

function SWEP:FinishReload()
    self:SetReloading(false)
    local amount = math.min(self:GetMaxClip1() - self:Clip1(), self:Ammo1())
    self:SetClip1(self:Clip1() + amount)
    self.Owner:RemoveAmmo(amount, self:GetPrimaryAmmoType())
end

function SWEP:CalculateSpread()
    if not IsValid(self.Owner) then return self.Primary.Cone end
    
    local spread = self.Primary.Cone
    local maxSpeed = self.LoweredPos and self.Owner:GetWalkSpeed() or self.Owner:GetRunSpeed()
    
    spread = spread + self.Primary.Cone * math.Clamp(self.Owner:GetVelocity():Length2D() / maxSpeed, 0, self.Spread.VelocityMod)
    spread = spread + self:GetRecoil() * self.Spread.RecoilMod
    
    if not self.Owner:IsOnGround() then
        spread = spread * self.Spread.AirMod
    end
    
    if self.Owner:IsOnGround() and self.Owner:Crouching() then
        spread = spread * self.Spread.CrouchMod
    end
    
    if self:GetIronsights() then
        spread = spread * self.Spread.IronsightsMod
    end
    
    return math.Clamp(spread, self.Spread.Min, self.Spread.Max)
end

function SWEP:HasAttachment(name)
    return (self:GetCurAttachment() or "") == name
end

function SWEP:SetupModifiers(name)
    if self.Attachments and self.Attachments[name] and self.Attachments[name].ModSetup then
        self.Attachments[name].ModSetup(self)
    end
end

function SWEP:RollbackModifiers(name)
    if self.Attachments and self.Attachments[name] and self.Attachments[name].ModCleanup then
        self.Attachments[name].ModCleanup(self)
    end
end

if CLIENT then
    hook.Add("Think", "SWEP_GlobalThink", function()
        local ply = LocalPlayer()
        if IsValid(ply) and ply:Alive() then
            local weapon = ply:GetActiveWeapon()
            if IsValid(weapon) and weapon.IsZv then
                weapon:Think()
            end
        end
    end)
end