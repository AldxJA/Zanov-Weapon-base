function SWEP:SetupAttachments()
    self.Attachments = self.Attachments or {}
    self.AvailableAttachments = self.AvailableAttachments or {}
    self.OriginalStats = {
        IronsightsPos = Vector(self.IronsightsPos.x, self.IronsightsPos.y, self.IronsightsPos.z),
        IronsightsFOV = self.IronsightsFOV,
        IronsightsSensitivity = self.IronsightsSensitivity,
        Spread = {
            IronsightsMod = self.Spread and self.Spread.IronsightsMod or 1,
            VelocityMod = self.Spread and self.Spread.VelocityMod or 1
        }
    }
end

function SWEP:RegisterAttachment(name, attachmentData)
    self.AvailableAttachments = self.AvailableAttachments or {}
    self.AvailableAttachments[name] = attachmentData
end

function SWEP:EquipAttachment(name)
    if not self.AvailableAttachments or not self.AvailableAttachments[name] then
        print("[ZV Attachments] Attachment not found: " .. tostring(name))
        return false
    end
    if not self.OriginalStats then
        self:SetupAttachments()
    end
    local attachmentData = self.AvailableAttachments[name]
    self:RemoveAttachment(name)
    self.Attachments[name] = table.Copy(attachmentData)
    if CLIENT and attachmentData.Cosmetic then
        self.AttachmentModels = self.AttachmentModels or {}
        
        if IsValid(self.AttachmentModels[name]) then
            self.AttachmentModels[name]:Remove()
        end
        
        local c = attachmentData.Cosmetic
        local model = ClientsideModel(c.Model, RENDERGROUP_BOTH)
        if IsValid(model) then
            model:SetParent(self.Owner:GetViewModel())
            model:SetNoDraw(true)
            if c.Scale then
                model:SetModelScale(c.Scale)
            end
            if c.Skin then
                model:SetSkin(c.Skin)
            end
            self.AttachmentModels[name] = model
        else
            print("[ZV Attachments] Failed to create model for: " .. name)
        end
    end
    if attachmentData.ModSetup then
        attachmentData.ModSetup(self)
    end
    return true
end

function SWEP:RemoveAttachment(name)
    local attachment = self.Attachments and self.Attachments[name]
    if not attachment then return false end
    if attachment.ModCleanup then
        attachment.ModCleanup(self)
    end
    if CLIENT and self.AttachmentModels and IsValid(self.AttachmentModels[name]) then
        self.AttachmentModels[name]:Remove()
        self.AttachmentModels[name] = nil
    end
    self.Attachments[name] = nil
    return true
end

function SWEP:DefineAttachments()
    self:SetupAttachments()
    self:RegisterAttachment("zv_scope", {
        Cosmetic = {
            Model = "models/props_combine/combine_binocular01.mdl",
            Bone = "Base",
            Pos = Vector(-0.38, 2, 7.791),
            Ang = Angle(90, -12.858, -90),
            Scale = 0.26,
            Skin = 0
        },
        ModSetup = function(wep)
            wep.ScopeOriginalFOV = wep.IronsightsFOV
            wep.ScopeOriginalPos = Vector(wep.IronsightsPos.x, wep.IronsightsPos.y, wep.IronsightsPos.z)
            wep.ScopeOriginalSensitivity = wep.IronsightsSensitivity
            wep.IronsightsPos = Vector(-4.624, -17.286, 0.201)
            wep.IronsightsFOV = 0.3
            wep.IronsightsSensitivity = 0.2
            wep.Spread.IronsightsMod = 0.4
            wep.Spread.VelocityMod = 1.1
        end,
        ModCleanup = function(wep)
            wep.IronsightsPos = wep.ScopeOriginalPos
            wep.IronsightsFOV = wep.ScopeOriginalFOV
            wep.IronsightsSensitivity = wep.ScopeOriginalSensitivity
            wep.Spread.IronsightsMod = 6
            wep.Spread.VelocityMod = 0.4
        end
    })
end

function SWEP:Initialize()
    self.BaseClass.Initialize(self)
    self:DefineAttachments()
end

if CLIENT then
    concommand.Add("zv_equip_attachment", function(ply, cmd, args)
        local attachName = args[1] or ""
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep.IsZv and wep.EquipAttachment then
            if wep:EquipAttachment(attachName) then
                wep.CurrentAttachment = attachName
                print("[ZV Attachments] Equipped: " .. attachName)
            else
                print("[ZV Attachments] Failed to equip: " .. attachName)
            end
        end
    end)
    
    concommand.Add("zv_remove_attachment", function(ply, cmd, args)
        local attachName = args[1] or ""
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep.IsZv and wep.RemoveAttachment then
            if wep:RemoveAttachment(attachName) then
                wep.CurrentAttachment = ""
                print("[ZV Attachments] Removed: " .. attachName)
            else
                print("[ZV Attachments] Failed to remove: " .. attachName)
            end
        end
    end)
end