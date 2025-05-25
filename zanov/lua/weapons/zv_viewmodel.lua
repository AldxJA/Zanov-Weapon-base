SWEP.CanRunGun = false
SWEP.LoweredPos = Vector(0, 0, 0)
SWEP.LoweredAng = Angle(0, 0, 0)
SWEP.ViewModelPos = Vector(0, 0, 0)
SWEP.ViewModelAngle = Angle(0, 0, 0)

SWEP.SwaySettings = {
    IntensityX = -3,
    IntensityY = -3,
    IntensityZ = 2,
    SmoothFactor = 12,
    MaxSwayAngle = 155
}

SWEP.MovementSettings = {
    BobFrequency = 16.5,
    BobMultiplier = 3.5,
    RunningPositionOffset = Vector(0, -5, -0.52),
    JumpIntensity = 3.5,
    LandingIntensity = 6,
    LandingRecoveryRate = 1
}

SWEP.IdleSettings = {
    Intensity = 0.5,
    BreathingFrequency = 0.5,
    SwayFrequency = 0.85
}

local sway = 0
local lastAng = Angle(0, 0, 0)
local cacheAng = Angle(0, 0, 0)
local c_jump = 0
local c_landing = 0
local c_move = 0
local c_sight = 0
local lastOnGround = true
local lastZVelocity = 0
local breathCycle = 0

function SWEP:GetOffset() 
    if self.LoweredPos and self:IsSprinting() and not self.CanRunGun then
        return self.LoweredPos, self.LoweredAng
    end
    
    if self:GetIronsights() then
        return self.IronsightsPos + Vector(0, -self:GetIronsightsRecoil(), 0), self.IronsightsAng
    end

    return Vector(0, 0, 0), Angle(0, 0, 0)
end

function SWEP:OffsetThink()
    local offset_pos, offset_ang = self:GetOffset()
    offset_pos = offset_pos or Vector(0, 0, 0)
    offset_ang = offset_ang or Angle(0, 0, 0)
    
    if self.ViewModelOffset then
        offset_pos = offset_pos + self.ViewModelOffset
    end
    
    if self.ViewModelOffsetAng then
        offset_ang = offset_ang + self.ViewModelOffsetAng
    end
    
    if self:IsSprinting() and not self.CanRunGun then
        offset_ang = self.LoweredAng
    end
    
    self.ViewModelPos = LerpVector(FrameTime() * 6.0, self.ViewModelPos, offset_pos)
    self.ViewModelAngle = LerpAngle(FrameTime() * 2.60, self.ViewModelAngle, offset_ang)
end

function SWEP:PreDrawViewModel(vm)
    if CLIENT then
        if self.CustomMaterial and not self.CustomMatSetup then
            self.Owner:GetViewModel():SetMaterial(self.CustomMaterial)
            self.CustomMatSetup = true
        end
        
        self:OffsetThink()
    end
    return self.scopedIn
end

function SWEP:GetViewModelPosition(pos, ang)
    if not IsValid(self.Owner) then return pos, ang end
    
    ang:RotateAroundAxis(ang:Right(), self.ViewModelAngle.p)
    ang:RotateAroundAxis(ang:Up(), self.ViewModelAngle.y)
    ang:RotateAroundAxis(ang:Forward(), self.ViewModelAngle.r)
    
    pos = pos + ang:Right() * self.ViewModelPos.x
    pos = pos + ang:Forward() * self.ViewModelPos.y
    pos = pos + ang:Up() * self.ViewModelPos.z
    
    local ft = FrameTime()
    local ct = CurTime()
    local rt = RealTime()
    
    local eyeAngles = self.Owner:EyeAngles()
    local aDelta = eyeAngles - (lastAng or eyeAngles)
    aDelta.y = math.NormalizeAngle(aDelta.y)
    
    local maxSwayAngle = self.SwaySettings.MaxSwayAngle or 5
    aDelta.p = math.Clamp(aDelta.p, -maxSwayAngle, maxSwayAngle)
    aDelta.y = math.Clamp(aDelta.y, -maxSwayAngle, maxSwayAngle)
    aDelta.r = math.Clamp(aDelta.r, -maxSwayAngle, maxSwayAngle)
    
    if self:GetIronsights() or self:GetReloading() then
        aDelta = aDelta * 0.5
    end
    
    local smoothFactor = self.SwaySettings.SmoothFactor or 15
    cacheAng = LerpAngle(math.Clamp(ft * smoothFactor, 0, 1), cacheAng, aDelta)
    
    lastAng = eyeAngles
    
    local swayX = self.SwaySettings.IntensityX or 2
    local swayY = self.SwaySettings.IntensityY or 2
    local swayZ = self.SwaySettings.IntensityZ or 1.8
    
    ang:RotateAroundAxis(ang:Right(), -cacheAng.p * swayY)
    ang:RotateAroundAxis(ang:Up(), cacheAng.y * swayX)
    ang:RotateAroundAxis(ang:Forward(), cacheAng.r * (swayZ * 20.5))
    
    pos = pos + ang:Right() * cacheAng.y * (swayX * 0.6)
    pos = pos + ang:Up() * cacheAng.p * (swayZ * -0.5)
    
    if self.BlowbackCurrent and self.BlowbackCurrent > 0 then
        local blowback = self.Blowback
        if blowback then
            pos = pos + blowback.Pos.x * ang:Right() * self.BlowbackCurrent
            pos = pos + blowback.Pos.y * ang:Forward() * self.BlowbackCurrent
            pos = pos + blowback.Pos.z * ang:Up() * self.BlowbackCurrent
            
            ang:RotateAroundAxis(ang:Right(), blowback.Orientation.p * self.BlowbackCurrent)
            ang:RotateAroundAxis(ang:Up(), blowback.Orientation.y * self.BlowbackCurrent)
            ang:RotateAroundAxis(ang:Forward(), blowback.Orientation.r * self.BlowbackCurrent)
            
            local recoveryTime = blowback.RecoveryTime or 1.5
            self.BlowbackCurrent = math.max(self.BlowbackCurrent - ft * (1 / recoveryTime), 0)
        end
    end
    
    local vel = self.Owner:GetVelocity()
    local moveSpeed = vel:Length2D()
    local maxSpeed = self.Owner:GetRunSpeed()
    local movePercent = math.Clamp(moveSpeed / maxSpeed, 0, 1)
    local onGround = self.Owner:OnGround()
    
    local sideMove = self.Owner:GetVelocity():Dot(self.Owner:GetRight())
    local strafeRollIntensity = 2
    local strafeRoll = sideMove / maxSpeed * strafeRollIntensity
    c_strafe = Lerp(ft * 8, c_strafe or 0, onGround and strafeRoll or 0)
    
    c_move = Lerp(ft * 8, c_move, onGround and movePercent or 0)
    c_sight = Lerp(ft * 8, c_sight, self:GetIronsights() and onGround and not self:GetReloading() and 0.1 or 1)
    
    local zVel = vel.z
    if not lastOnGround and onGround then
        local landImpact = math.abs(lastZVelocity) / 400 * self.MovementSettings.LandingIntensity
        c_landing = math.min(landImpact, 1)
    end
    
    if c_landing > 0 then
        c_landing = math.max(c_landing - ft * self.MovementSettings.LandingRecoveryRate, 0)
    end
    
    c_jump = Lerp(ft * 8, c_jump, not onGround and zVel / 200 * self.MovementSettings.JumpIntensity or 0)
    
    lastOnGround = onGround
    lastZVelocity = zVel
    
    breathCycle = (breathCycle + ft * self.IdleSettings.BreathingFrequency) % (math.pi * 2)
    
    pos = pos + ang:Up() * c_jump * 1.5
    ang.p = ang.p + c_jump * 6
    
    if c_landing > 0 then
        ang.p = ang.p + c_landing * -5
        pos = pos - ang:Up() * c_landing * 2
    end
    
    if c_strafe ~= 0 then
        ang.r = ang.r + c_strafe * 3
        pos = pos + ang:Right() * c_strafe * 0.15
    end
    
    if c_move > 0 then
        local bobScale = c_move * c_sight * self.MovementSettings.BobMultiplier
        local runOffset = self.MovementSettings.RunningPositionOffset
        
        pos = pos + ang:Right() * runOffset.x * c_move
        pos = pos + ang:Forward() * runOffset.y * c_move
        pos = pos + ang:Up() * runOffset.z * c_move
        
        local bobFreq = self.MovementSettings.BobFrequency
        ang.y = ang.y + math.sin(ct * bobFreq) * bobScale * -0.25
        ang.p = ang.p + math.cos(ct * bobFreq) * bobScale * -0.42
        ang.r = ang.r + math.cos(ct * bobFreq) * bobScale * 0.58
        pos = pos + ang:Up() * math.sin(ct * bobFreq) * -0.2 * bobScale
    end
    
    local idleScale = (1 - c_move) * c_sight * self.IdleSettings.Intensity
    if idleScale > 0 then
        local swayFreq = self.IdleSettings.SwayFrequency
        
        ang.p = ang.p + math.sin(breathCycle) * idleScale
        ang.y = ang.y + math.sin(ct * swayFreq) * idleScale * 0.5
        ang.r = ang.r + math.sin(ct * swayFreq * 1.5) * idleScale * 0.3 
        pos = pos + ang:Forward() * math.sin(breathCycle) * idleScale * 0.1
    end
    
    return pos, ang
end

SWEP.FOVMultiplier = 1
SWEP.LastFOVUpdate = 0

function SWEP:TranslateFOV(fov)
    local curTime = CurTime()
    
    if self.LastFOVUpdate < curTime then
        self.FOVMultiplier = Lerp(FrameTime() * 15, self.FOVMultiplier, self:GetIronsights() and self.IronsightsFOV or 1)
        self.LastFOVUpdate = curTime
    end
    
    if self.scopedIn then
        return fov * (self.FOVScoped or 0.25)
    end 
    
    return fov * self.FOVMultiplier
end

function SWEP:AdjustMouseSensitivity()
    if self:GetIronsights() then return self.IronsightsSensitivity end
    return nil
end

function SWEP:CanIronsight()
    local att = self:GetCurAttachment()
    if att != "" and self.Attachments and self.Attachments[att] and 
       self.Attachments[att].Behaviour == "sniper_sight" and 
       hook.Run("ShouldDrawLocalPlayer", self.Owner) then
        return false
    end
    
    return not (self:IsSprinting() and not self.CanRunGun) and 
           not self:GetReloading() and 
           self.Owner:IsOnGround()
end

function SWEP:IronsightsThink()
    if CLIENT then
        self:SetIronsightsRecoil(math.Approach(self:GetIronsightsRecoil(), 0, FrameTime() * 100))
        self.BobScale = self:GetIronsights() and 1
        self.SwayScale = self:GetIronsights() and 1
    end
    
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

function SWEP:Think()
    if IsValid(self.Owner) then
        self:IronsightsThink()
    end
end

function SWEP:ShouldDrawCrosshair()
    if self.NoCrosshair then return false end
    if hook.Run("ShouldDrawLocalPlayer", self.Owner) then return true end
    if self:GetReloading() or (self:IsSprinting() and self.LoweredPos and not self.CanRunGun) then return false end
    if self:GetIronsights() and not self.IronsightsCrosshair then return false end
    return true
end
function SWEP:ViewModelDrawn()
    if not CLIENT then return end
    
    local vm = self.Owner:GetViewModel()
    if not IsValid(vm) then return end

    if self.AttachmentModels and self.Attachments then
        for attachName, model in pairs(self.AttachmentModels) do
            if IsValid(model) and self.Attachments[attachName] and self.Attachments[attachName].Cosmetic then
                local c = self.Attachments[attachName].Cosmetic
                
                local pos, ang
                
                if c.Bone then
                    local bone = vm:LookupBone(c.Bone)
                    if bone then
                        local matrix = vm:GetBoneMatrix(bone)
                        if matrix then
                            pos, ang = matrix:GetTranslation(), matrix:GetAngles()
                        end
                    end
                end
                
                -- fallback if bone/matrix not found
                if not pos or not ang then
                    pos = vm:GetPos()
                    ang = vm:GetAngles()
                end

                -- apply positional offset relative to the base pos/ang
                pos = pos + ang:Forward() * c.Pos.x + ang:Right() * c.Pos.y + ang:Up() * c.Pos.z
                
                -- apply angular rotation offset
                ang:RotateAroundAxis(ang:Up(), c.Ang.y)
                ang:RotateAroundAxis(ang:Right(), c.Ang.p)
                ang:RotateAroundAxis(ang:Forward(), c.Ang.r)

                -- set model position and angles, then draw
                model:SetPos(pos)
                model:SetAngles(ang)
                model:DrawModel()
            end
        end
    end
end
if CLIENT then
    hook.Add("Think", "SWEP_ViewModelThink", function()
        local ply = LocalPlayer()
        if IsValid(ply) and ply:Alive() then
            local weapon = ply:GetActiveWeapon()
            if IsValid(weapon) and weapon.IronsightsThink then
                weapon:IronsightsThink()
            end
        end
    end)
end