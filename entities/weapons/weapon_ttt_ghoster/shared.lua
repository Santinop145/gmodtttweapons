---- Example TTT custom weapon

-- First some standard GMod stuff
if SERVER then
   AddCSLuaFile( "shared.lua" )
end

if CLIENT then
   SWEP.PrintName = "Invisibility Device"
   SWEP.Slot      = 7

   SWEP.ViewModelFOV  = 54
   SWEP.ViewModelFlip = false
end

-- Always derive from weapon_tttbase.
SWEP.Base				= "weapon_tttbase"

--- Standard GMod values

SWEP.HoldType			= "pistol"
SWEP.UseHands = true
SWEP.Primary.Delay       = 0
SWEP.Primary.Recoil      = 0
SWEP.Primary.Automatic   = false
SWEP.Primary.Damage      = 0
SWEP.Primary.Cone        = 0.005
SWEP.Primary.Ammo        = "none"
SWEP.Primary.ClipSize    = 1
SWEP.Primary.ClipMax     = 1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Sound       = Sound( "none" )
SWEP.HeadshotMultiplier = 1
SWEP.m_WeaponDeploySpeed = 2
SWEP.Used = false
SWEP.OwnerSet = false

SWEP.ViewModel  = "models/weapons/c_slam.mdl"
SWEP.WorldModel = "models/weapons/w_slam.mdl"

function SWEP:Initialize()
end

function SWEP:PrimaryAttack()
   if(SERVER) then
      if(self:GetOwner().ShouldBeInvisible) then return end

      if(self:GetOwner():IsValid() and not self.OwnerSet) then
         self.OwnerFallback = self:GetOwner()
      end

      if(self.OwnerFallback:Alive() and not self.Used) then
         self.OwnerFallback.ShouldBeInvisible = true
         self.OwnerBaseColor = self:GetOwner():GetColor()
         self.OwnerMaxSpeed = self.OwnerFallback:GetMaxSpeed()
         self.OwnerWalkSpeed = self.OwnerFallback:GetWalkSpeed()
         self.OwnerJumpPower = self.OwnerFallback:GetJumpPower()
         self.OwnerCrouchedWalkSpeed = self.OwnerFallback:GetCrouchedWalkSpeed()
         self.OwnerFallback:SetRenderMode( RENDERMODE_TRANSCOLOR )
         self.OwnerFallback:SetColor(Color(0,0,0,5))
         self.OwnerFallback:ScreenFade(SCREENFADE.IN, Color( 0, 0, 00, 220), 2, 6)
         self.OwnerFallback:EmitSound("weapons/physcannon/energy_bounce2.wav", 50, 150, 1, CHAN_AUTO)
         self.OwnerFallback:SetMaxSpeed(self.OwnerMaxSpeed*1.5)
         self.OwnerFallback:SetWalkSpeed(self.OwnerWalkSpeed*1.5)
         self.OwnerFallback:SetJumpPower(self.OwnerJumpPower*2)
         self.OwnerFallback:SetCrouchedWalkSpeed(0.9)
         self.Used = true
         timer.Create("InvisibilityDuration" .. self:EntIndex(), 8, 1, function()
            if(self.OwnerFallback:IsValid()) then
               self.OwnerFallback:SetColor(self.OwnerBaseColor)
               self.OwnerFallback:EmitSound("weapons/physcannon/physcannon_dryfire.wav", 50, 150, 1, CHAN_AUTO)
               self.OwnerFallback.ShouldBeInvisible = false
               self.OwnerFallback:SetMaxSpeed(self.OwnerMaxSpeed)
               self.OwnerFallback:SetWalkSpeed(self.OwnerWalkSpeed)
               self.OwnerFallback:SetJumpPower(self.OwnerJumpPower)
               self.OwnerFallback:SetCrouchedWalkSpeed(self.OwnerCrouchedWalkSpeed)
               if(self:IsValid()) then
                  self:Remove()
               end
            end
         end)
      end
   end
end

function SWEP:Think()
   self:CalcViewModel()

   if(timer.Exists("InvisibilityDuration" .. self:EntIndex())) then
      self.OwnerFallback:PrintMessage(HUD_PRINTCENTER, "Time left: " .. math.max(math.Round(timer.TimeLeft("InvisibilityDuration" .. self:EntIndex()), 1), 0))
   end
end

function SWEP:SecondaryAttack()
end
--- TTT config values

-- Kind specifies the category this weapon is in. Players can only carry one of
-- each. Can be: WEAPON_... MELEE, PISTOL, HEAVY, NADE, CARRY, EQUIP1, EQUIP2 or ROLE.
-- Matching SWEP.Slot values: 0      1       2     3      4      6       7        8
SWEP.Kind = WEAPON_EQUIP1

-- If AutoSpawnable is true and SWEP.Kind is not WEAPON_EQUIP1/2, then this gun can
-- be spawned as a random weapon. Of course this AK is special equipment so it won't,
-- but for the sake of example this is explicitly set to false anyway.
SWEP.AutoSpawnable = false

-- The AmmoEnt is the ammo entity that can be picked up when carrying this gun.
SWEP.AmmoEnt = "none"

-- CanBuy is a table of ROLE_* entries like ROLE_TRAITOR and ROLE_DETECTIVE. If
-- a role is in this table, those players can buy this.
SWEP.CanBuy = { ROLE_TRAITOR }

-- InLoadoutFor is a table of ROLE_* entries that specifies which roles should
-- receive this weapon as soon as the round starts. In this case, none.
SWEP.InLoadoutFor = "none"

-- If LimitedStock is true, you can only buy one per round.
SWEP.LimitedStock = false

-- If AllowDrop is false, players can't manually drop the gun with Q
SWEP.AllowDrop = true

-- If IsSilent is true, victims will not scream upon death.
SWEP.IsSilent = false

-- If NoSights is true, the weapon won't have ironsights
SWEP.NoSights = true

-- Equipment menu information is only needed on the client
if CLIENT then
   -- Path to the icon material
   SWEP.Icon = "VGUI/ttt/icon_myserver_ak47"

   -- Text shown in the equip menu
   SWEP.EquipMenuData = {
      type = "Weapon",
      desc = "Makes you invisible for 8 seconds.\nONE USE!"
   };
end

-- Tell the server that it should download our icon to clients.
if SERVER then
   -- It's important to give your icon a unique name. GMod does NOT check for
   -- file differences, it only looks at the name. This means that if you have
   -- an icon_ak47, and another server also has one, then players might see the
   -- other server's dumb icon. Avoid this by using a unique name.
   resource.AddFile("materials/VGUI/ttt/icon_myserver_ak47.vmt")
end