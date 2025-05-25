AddCSLuaFile()

SWEP.Base = "zv_base" -- Inherits from the base weapon

SWEP.PrintName = "SPAS-12"
SWEP.Category = "Zanov Weaponry"
SWEP.Spawnable = true -- Players can spawn this weapon
SWEP.AdminOnly = false

-- Weapon appearance and behavior
SWEP.ViewModel = "models/weapons/tfa_ins2/c_spas12_bri.mdl"
SWEP.WorldModel = "models/weapons/w_shotgun.mdl"
SWEP.HoldType = "shotgun" -- How player holds the weapon
SWEP.ViewModelFOV = 60
SWEP.UseHands = true
-- Primary fire settings
SWEP.Primary.Sound = Sound("weapons/tfa_ins2/spas12/fire.wav")
SWEP.Primary.Recoil = 6 -- Higher = more recoil
SWEP.Primary.Damage = 12 -- Damage per bullet
SWEP.Primary.NumShots = 12 -- Bullets per shot
SWEP.Primary.Cone = 0.1 -- Base accuracy (lower = more accurate)
SWEP.Primary.Delay = 0.8 -- Fire rate delay between shots
SWEP.Primary.Ammo = "buckshot" -- Ammo type
SWEP.Primary.Automatic = true -- This makes gun full auto
SWEP.Primary.ClipSize = 8 -- Magazine size
SWEP.Primary.DefaultClip = 8 -- Starting ammo in mag

-- Reload sound
SWEP.ReloadSound = Sound("Weapon_AK47.Reload")

-- Ironsights (ADS) configuration
SWEP.IronsightsPos = Vector(-2.62, 2, 0.8) -- Viewmodel position when aiming
SWEP.IronsightsAng = Angle(0, 0, 0) -- Viewmodel angle when aiming
SWEP.IronsightsFOV = 0.9 -- Zoom level when aiming (lower = more zoom)
SWEP.IronsightsSensitivity = 0.8 -- Mouse sensitivity when aiming

-- Spread modifiers - affects accuracy in different situations
SWEP.Spread = {
    Min = 0, -- Minimum spread
    Max = 0.3, -- Maximum spread
    IronsightsMod = 0.3, -- Multiply spread by this when aiming (more accurate on lower values)
    CrouchMod = 0.6, -- Multiply spread by this when crouching (more accurate on lower values)
    AirMod = 2.0, -- Multiply spread by this when airborne (less accurate)
    RecoilMod = 0.03, -- How much recoil affects spread
    VelocityMod = 1 -- How much movement affects spread
}

-- Visual effects
SWEP.ViewRollIntensity = 1 -- Screen roll when firing
SWEP.ScreenShake = 0.5 -- Screen shake intensity
SWEP.BulletForce = 2 -- Physics force applied to hit objects

-- Muzzle flash light effect
SWEP.MuzzleLight = {
    r = 255, -- Red component
    g = 200, -- Green component  
    b = 100, -- Blue component
    brightness = 3,
    size = 300,
    duration = 0.08 -- How long light lasts
}

SWEP.Blowback = { -- Viewmodel blowback (basically makes shooting more cooler yk)
    Ang = Angle(2, 0, 0),
    Amount = 2,
    Max = 2,
    Pos = Vector(0, -8, -2.5),
    Orientation = Angle(7.5, 0, -0.5),
    RecoveryTime = 0.3
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
SWEP.IsShotgun = true -- Enables shell-by-shell reloading
SWEP.ShellInsert = 0.26 -- Time per shell reload
-- SWEP.Primary.NumShots = 8 -- Multiple pellets per shot
-- SWEP.Primary.Damage = 15 -- Lower damage per pellet