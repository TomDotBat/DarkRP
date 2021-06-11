include("shared.lua")

PIXEL.RegisterFontUnscaled("Tipjar.Overhead", "Open Sans Bold", 50)
PIXEL.RegisterFontUnscaled("Tipjar.Anim", "Open Sans Bold", 150)

function ENT:Initialize()
    self:initVars()
    self:initVarsClient()
end

function ENT:initVarsClient()
    self.colorBackground = Color(140, 0, 0, 100)
    self.colorText = Color(255, 255, 255, 255)
    self.donateAnimColor = Color(20, 100, 20)

    self.rotationSpeed = 130
    self.rotationOffset = 0
    self:InitCsModel()

    self.firstDonateAnimation = nil
    self.lastDonateAnimation = nil
    self.donateAnimSpeed = 0.3
end

function ENT:InitCsModel()
    self.csModel = ClientsideModel(self.model)
    self.csModel:SetPos(self:GetPos())
    self.csModel:SetParent(self)
    self.csModel:SetModelScale(1.5, 0)
    self.csModel:SetNoDraw(true)
    self:CallOnRemove("csModel", fp{SafeRemoveEntity, self.csModel})
end

local localPly
local bgColor = PIXEL.CopyColor(PIXEL.Colors.Background)
bgColor.a = 245

function ENT:Draw()
    if not IsValid(localPly) then localPly = LocalPlayer() end
    if PIXEL.checkDistance(self) then return end

    local Pos = self:GetPos()
    local Ang = self:GetAngles()
    local sysTime = SysTime()
    local eyepos = EyePos()
    local planeNormal = Ang:Up()

    local rotAng = Angle(Ang)
    self.rotationOffset = sysTime % 360 * self.rotationSpeed
    rotAng:RotateAroundAxis(planeNormal, self.rotationOffset)

    -- Something about cs models getting removed on their own...
    if not IsValid(self.csModel) then
        self:InitCsModel()
    end
    self.csModel:SetPos(Pos)
    self.csModel:SetAngles(rotAng)
    if not self:IsDormant() then
        self.csModel:DrawModel()
    end


    local owner = self:Getowning_ent()
    owner = (IsValid(owner) and owner:Nick()) or DarkRP.getPhrase("unknown")
    local title = DarkRP.getPhrase("tip_jar")

    Ang:RotateAroundAxis(Ang:Forward(), 90)

    local relativeEye = eyepos - Pos
    local relativeEyeOnPlane = relativeEye - planeNormal * relativeEye:Dot(planeNormal)
    local textAng = relativeEyeOnPlane:AngleEx(planeNormal)

    textAng:RotateAroundAxis(textAng:Up(), 90)
    textAng:RotateAroundAxis(textAng:Forward(), 90)

    cam.Start3D2D(Pos - Ang:Right() * 11.5 , textAng, 0.05)
        local name = PIXEL.EllipsesText(owner, 320, "Tipjar.Overhead")
        PIXEL.DrawRoundedBox(6, -170, -180, 350, 130, bgColor)
        PIXEL.DrawSimpleText(name, "Tipjar.Overhead", -0, -120, PIXEL.Colors.PrimaryText, TEXT_ALIGN_CENTER)
        PIXEL.DrawSimpleText(title, "Tipjar.Overhead", -0, -170, PIXEL.Colors.PrimaryText, TEXT_ALIGN_CENTER)
        self:DrawAnims(sysTime)
    cam.End3D2D()
end

function ENT:DrawAnims(sysTime)
    local anim = self.firstDonateAnimation

    while anim do
        if anim.progress > 1 then
            anim = anim.nextDonateAnimation
            self.firstDonateAnimation = anim
            continue
        end

        PIXEL.DrawSimpleText(anim.amount, "Tipjar.Anim", -anim.textWidth / 2, -100 - anim.progress * 200, ColorAlpha(self.donateAnimColor, Lerp(anim.progress, 1024, 0)), 0)

        anim.progress = (sysTime - anim.start) * self.donateAnimSpeed

        anim = anim.nextDonateAnimation
    end

    if not self.firstDonateAnimation then
        self.lastDonateAnimation = nil
    end
end

function ENT:Donated(ply, amount)
    local txtAmount = DarkRP.formatMoney(amount)

    surface.SetFont("DarkRP_tipjar")

    local anim = {
        amount = txtAmount,
        start = SysTime(),
        textWidth = surface.GetTextSize(txtAmount),
        progress = 0,
        nextDonateAnimation = nil,
    }

    if self.lastDonateAnimation then
        self.lastDonateAnimation.nextDonateAnimation = anim
    else
        self.firstDonateAnimation = anim
    end

    self.lastDonateAnimation = anim

    self:AddDonation(ply:Nick(), amount)
end

-- Disable halos
function ENT:Think() end
