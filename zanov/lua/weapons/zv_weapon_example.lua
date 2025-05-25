AddCSLuaFile()

SWEP.Base = "zv_base" -- Inherits from the base weapon

SWEP.PrintName = "AK-47"
SWEP.Category = "Zanov Weaponry"
SWEP.Spawnable = true -- Players can spawn this weapon
SWEP.AdminOnly = false

-- Weapon appearance and behavior
SWEP.ViewModel = "models/weapons/v_akm_inss.mdl"
SWEP.ViewModelOffset = Vector(0, 0, 0)
SWEP.WorldModel = "models/weapons/w_rif_ak47.mdl"
SWEP.HoldType = "ar2" -- How player holds the weapon
SWEP.ViewModelFOV = 60
SWEP.UseHands = true
-- Primary fire settings
SWEP.Primary.Sound = Sound("weapons/ins_ak47.wav")
SWEP.Primary.Recoil = 1.6 -- Higher = more recoil
SWEP.Primary.Damage = 35 -- Damage per bullet
SWEP.Primary.NumShots = 1 -- Bullets per shot
SWEP.Primary.Cone = 0.02 -- Base accuracy (lower = more accurate)
SWEP.Primary.Delay = 0.1 -- Fire rate delay between shots
SWEP.Primary.Ammo = "ar2" -- Ammo type
SWEP.Primary.Automatic = true -- This makes gun full auto
SWEP.Primary.ClipSize = 30 -- Magazine size
SWEP.Primary.DefaultClip = 30 -- Starting ammo in mag

-- Reload sound
SWEP.ReloadSound = Sound("Weapon_AK47.Reload")

-- Ironsights (ADS) configuration
SWEP.IronsightsPos = Vector(-2.79, 2, 0.35) -- Viewmodel position when aiming
SWEP.IronsightsAng = Angle(0, 0, 0) -- Viewmodel angle when aiming
SWEP.IronsightsFOV = 0.9 -- Zoom level when aiming (lower = more zoom)
SWEP.IronsightsSensitivity = 0.8 -- Mouse sensitivity when aiming

-- Spread modifiers - affects accuracy in different situations
SWEP.Spread = {
    Min = 0, -- Minimum spread
    Max = 0.3, -- Maximum spread
    IronsightsMod = 0.3, -- Multiply spread by this when aiming (more accurate)
    CrouchMod = 0.7, -- Multiply spread by this when crouching (more accurate)
    AirMod = 2.0, -- Multiply spread by this when airborne (less accurate)
    RecoilMod = 0.03, -- How much recoil affects spread
    VelocityMod = 1.0 -- How much movement affects spread
}

-- Visual effects
SWEP.ViewRollIntensity = 1 -- Screen roll when firing
SWEP.ScreenShake = 0.5 -- Screen shake intensity
SWEP.BulletForce = 2 -- Physics force applied to hit objects
SWEP.LoweredPos = Vector(0, -2.5, -1.0) --pos when running
SWEP.LoweredAng = Angle(-20, 10, 0) --angle when running

SWEP.CanRunGun = false --can shoot when running. if not it would do the lowered shit mentioned ontop
SWEP.MuzzleEffects = {"muzzleflash", "muzzle_smoke"}
-- Muzzle flash light effect
SWEP.MuzzleLight = {
    r = 255, -- Red component
    g = 200, -- Green component  
    b = 100, -- Blue component
    brightness = 3,
    size = 85,
    duration = 0.1 -- How long light lasts
}

SWEP.Blowback = { -- Viewmodel blowback (basically makes shooting more cooler yk)
    Ang = Angle(2, 0, 0),
    Amount = 2,
    Max = 2,
    Pos = Vector(0, -3.5, -1.5),
    Orientation = Angle(5, 0, -0.5),
    RecoveryTime = 0.1
}

-- Weapon slot and position
SWEP.Slot = 2 -- Weapon category slot
SWEP.SlotPos = 1 -- Position within slot

-- Custom material (optional)
-- SWEP.CustomMaterial = "models/weapons/shared/stainless"

-- Burst fire example (uncomment to enable 3-round burst)
-- SWEP.Primary.Burst = true -- Enables burst fire
-- SWEP.Primary.BurstEndDelay = 0.2 -- Delay after burst completes

-- Wind-up weapon example (like minigun - uncomment to enable)
-- SWEP.CanWindUp = true -- Enables wind-up mechanic
-- SWEP.WindUpSound = Sound("Weapon_AR2.Special1") -- Sound during wind-up
-- SWEP.WindUpDuration = 1.5 -- Time to wind up before firing

-- Shotgun example settings (uncomment for shotgun behavior)
-- SWEP.IsShotgun = true -- Enables shell-by-shell reloading
-- SWEP.ShellInsert = 0.8 -- Time per shell reload
-- SWEP.Primary.NumShots = 8 -- Multiple pellets per shot
-- SWEP.Primary.Damage = 15 -- Lower damage per pellet

function SWEP:DefineAttachments()
    self:SetupAttachments()
    
    self:RegisterAttachment("red_dot", {
        PrintName = "Red dot",
        Description = "Provides improved accuracy and zoom",
		Cosmetic = {
			Model = "models/weapons/tfa_ins2/upgrades/a_optic_eotech_l.mdl",
			Bone = "AK_Body",
			Pos = Vector(0, 0, 1.75),
			Ang = Angle(0, 90, 0),
			Scale = 0.5,
			Skin = 0
            --			Bone = "Base",
			--Pos = Vector(12, 2.75, -1.2), --old pos. couldnt find the bone before
		},
        ModSetup = function(wep)
            -- Store original values
            wep.ScopeOriginalFOV = wep.IronsightsFOV
            wep.ScopeOriginalPos = Vector(wep.IronsightsPos.x, wep.IronsightsPos.y, wep.IronsightsPos.z)
            wep.ScopeOriginalSpreadMod = wep.Spread.IronsightsMod

            wep.IronsightsPos = Vector(-2.79, 2, 0.35)
            wep.IronsightsFOV = 0.85  -- Tighter FOV
            wep.Spread.IronsightsMod = -0
        end,
        ModCleanup = function(wep)

            wep.IronsightsPos = wep.ScopeOriginalPos
            wep.IronsightsFOV = wep.ScopeOriginalFOV
            wep.Spread.IronsightsMod = wep.ScopeOriginalSpreadMod
        end
    })
end
function SWEP:Initialize()
    self.BaseClass.Initialize(self)
    self:DefineAttachments()
end