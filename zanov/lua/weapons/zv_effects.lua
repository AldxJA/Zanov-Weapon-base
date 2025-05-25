AddCSLuaFile()

ZV_EFFECTS = {}

ZV_EFFECTS["muzzle_smoke"] = {
    material = "particle/smokesprites_000" .. string.format("%1d", math.random(1, 6)),
    startsize = math.random(4, 7),
    endsize = math.random(30, 70),
    startAlpha = math.random(20, 110),
    endAlpha = 0,
    lifetime = math.random(2.0, 7.0),
    color = Color(80, 80, 80),
    velocity = {
        min = Vector(-10, -10, 20),
        max = Vector(10, 10, 50)
    },
    gravity = Vector(0, 0, math.random(40, 80)),
    airresistance = 200,
    roll = {min = -math.random(90, 180), max = math.random(90, 180)},
    rollDelta = {min = -5, max = 5},
    count = 1,
    spread = 11
}

ZV_EFFECTS["muzzleflash"] = {
    material = "effects/muzzleflash" .. math.random(1, 4) .. "_noz",
    startsize = math.random(8, 12),
    endsize = math.random(0, 4),
    startAlpha = math.random(100, 255),
    endAlpha = 0,
    lifetime = 0.2,
    color = Color(255, 200, 100),
    velocity = {
        min = Vector(50, -20, -20),
        max = Vector(200, 20, 20)
    },
    gravity = Vector(0, 0, 0),
    airresistance = 50,
    roll = {min = 0, max = 360},
    rollDelta = {min = -10, max = 10},
    count = 6,
    spread = 25
}

ZV_EFFECTS["plasma_flash"] = {
     material = "effects/muzzleflash" .. math.random(1, 4) .. "_noz",
    startsize = 12,
    endsize = 3,
    startAlpha = 255,
    endAlpha = 0,
    lifetime = 0.2,
    color = Color(0, 150, 255),
    velocity = {
        min = Vector(100, -15, -15),
        max = Vector(300, 15, 15)
    },
    gravity = Vector(0, 0, 0),
    airresistance = 100,
    roll = {min = 0, max = 0},
    rollDelta = {min = 0, max = 0},
    count = 6,
    spread = 20
}

ZV_EFFECTS["shell_eject"] = {
    material = "models/weapons/shell",
    startsize = 2,
    endsize = 2,
    startAlpha = 255,
    endAlpha = 255,
    lifetime = 3.0,
    color = Color(200, 180, 120),
    velocity = {
        min = Vector(20, 80, 50),
        max = Vector(50, 120, 100)
    },
    gravity = Vector(0, 0, -600),
    airresistance = 5,
    roll = {min = 0, max = 360},
    rollDelta = {min = -20, max = 20},
    count = 1,
    spread = 10,
    bounce = 0.3
}

ZV_EFFECTS["fire_sparks"] = {
    material = "effects/spark",
    startsize = 1,
    endsize = 0,
    startAlpha = 255,
    endAlpha = 0,
    lifetime = 1.0,
    color = Color(255, 100, 0),
    velocity = {
        min = Vector(-30, -30, -50),
        max = Vector(30, 30, 20)
    },
    gravity = Vector(0, 0, -400),
    airresistance = 20,
    roll = {min = 0, max = 0},
    rollDelta = {min = 0, max = 0},
    count = 12,
    spread = 45
}

function ZV_CreateEffect(effectName, pos, ang, owner)
    if not ZV_EFFECTS[effectName] then return end
    if not CLIENT then return end
    
    local effect = ZV_EFFECTS[effectName]
    local emitter = ParticleEmitter(pos, false)
    if not emitter then return end
    
    local forward = ang:Forward()
    local right = ang:Right()
    local up = ang:Up()
    
    for i = 1, effect.count do
        local particle = emitter:Add(effect.material, pos)
        if particle then
            -- Size
            particle:SetStartSize(effect.startsize)
            particle:SetEndSize(effect.endsize)
            
            -- Alpha
            particle:SetStartAlpha(effect.startAlpha)
            particle:SetEndAlpha(effect.endAlpha)
        
            particle:SetDieTime(effect.lifetime)
            particle:SetColor(effect.color.r, effect.color.g, effect.color.b)
            
            local vel = Vector(
                math.Rand(effect.velocity.min.x, effect.velocity.max.x),
                math.Rand(effect.velocity.min.y, effect.velocity.max.y),
                math.Rand(effect.velocity.min.z, effect.velocity.max.z)
            )
            local worldVel = forward * vel.x + right * vel.y + up * vel.z

            if effect.spread > 0 then
                local spread = effect.spread
                worldVel:Add(VectorRand() * spread)
            end
            
            particle:SetVelocity(worldVel)

            particle:SetGravity(effect.gravity)
            particle:SetAirResistance(effect.airresistance)

            if effect.roll then
                particle:SetRoll(math.Rand(effect.roll.min, effect.roll.max))
            end
            if effect.rollDelta then
                particle:SetRollDelta(math.Rand(effect.rollDelta.min, effect.rollDelta.max))
            end

            if effect.bounce then
                particle:SetBounce(effect.bounce)
            end

            if effect.collision then
                particle:SetCollide(true)
                particle:SetCollideCallback(function(part, hitPos, hitNormal)
                    part:SetVelocity(part:GetVelocity() * 0.3)
                end)
            end
        end
    end
    
    emitter:Finish()
end

function SWEP:CreateMuzzleEffect(effectName)
    if not CLIENT then return end
    if not IsValid(self.Owner) then return end

    local vm = self.Owner:GetViewModel()
    if not IsValid(vm) then return end

    -- Try multiple common attachment names
    local attachmentNames = {
        "muzzle",
        "muzzle_flash",
        "muzzleflash",
        "muzzle_flash1",
        "muzzle1",
        "Muzzle",
        "MuzzleFlash",
        "Muzzle_Flash",
        "1", -- Some models use numbered attachment names
    }

    local attachmentID, muzzle
    for _, name in ipairs(attachmentNames) do
        local id = vm:LookupAttachment(name)
        if id and id > 0 then
            local attach = vm:GetAttachment(id)
            if attach then
                attachmentID = id
                muzzle = attach
                break
            end
        end
    end

    if not muzzle then
        -- Fallback to eye position
        local eyePos = self.Owner:EyePos()
        local eyeAng = self.Owner:EyeAngles()
        local forward = eyeAng:Forward() * 50
        local right = eyeAng:Right() * 15
        local up = eyeAng:Up() * -5
        local fallbackPos = eyePos + forward + right + up
        ZV_CreateEffect(effectName, fallbackPos, eyeAng, self.Owner)
        return
    end

    -- Muzzle attachment found
    ZV_CreateEffect(effectName, muzzle.Pos, muzzle.Ang, self.Owner)
end


function SWEP:PlayMuzzleEffects()
    if CLIENT then
        if self.MuzzleEffects then
            for _, effectName in ipairs(self.MuzzleEffects) do
                self:CreateMuzzleEffect(effectName)
            end
        end
    end
end