---- Example TTT custom weapon

-- First some standard GMod stuff
if SERVER then
   AddCSLuaFile( "shared.lua" )
end

if CLIENT then
   SWEP.PrintName = "Taurus .410 Judge 12Gauge" -- i have no model for this yet
   SWEP.Slot      = 1

   SWEP.ViewModelFOV  = 54
   SWEP.ViewModelFlip = false
end

-- Always derive from weapon_tttbase.
SWEP.Base				= "weapon_tttbase"

--- Standard GMod values

SWEP.HoldType			= "revolver"
SWEP.UseHands = true
SWEP.Primary.Delay       = 1.2
SWEP.Primary.Recoil      = 2.2
SWEP.Primary.Automatic   = false
SWEP.Primary.Damage      = 9
SWEP.Primary.Cone        = 0.060
SWEP.Primary.Ammo        = "Buckshot"
SWEP.Primary.ClipSize    = 6
SWEP.Primary.ClipMax     = 6
SWEP.Primary.DefaultClip = 6
SWEP.Primary.Sound       = Sound( "weapon_357.Single" )
SWEP.HeadshotMultiplier = 2

SWEP.defaultPos = Vector(0,0,0)
SWEP.defaultAng = Vector(0,0,-2)
SWEP.IronSightsPos = Vector(0,0,0)
SWEP.IronSightsAng = Vector(0,0,0)

SWEP.ViewModel  = "gamemodes/terrortown/content/models/weapons/c_357.mdl"
SWEP.WorldModel = "models/weapons/w_357.mdl"

function SWEP:ShootBullet( dmg, recoil, numbul, cone )

   self:SendWeaponAnim(self.PrimaryAnim)
   self:GetOwner():MuzzleFlash()
   self:GetOwner():SetAnimation( PLAYER_ATTACK1 )

   local sights = self:GetIronsights()

   cone   = cone   or 0.01

   local bullet = {}
   bullet.Num    = 8
   bullet.Src    = self:GetOwner():GetShootPos()
   bullet.Dir    = self:GetOwner():GetAimVector()
   bullet.Spread = Vector( cone, cone, 0 )
   bullet.Tracer = 2
   bullet.TracerName = self.Tracer or "Tracer"
   bullet.Force  = 12
   bullet.Damage = dmg

   self:GetOwner():FireBullets( bullet )

   -- Owner can die after firebullets
   if (not IsValid(self:GetOwner())) or self:GetOwner():IsNPC() or (not self:GetOwner():Alive()) then return end

   if ((game.SinglePlayer() and SERVER) or
       ((not game.SinglePlayer()) and CLIENT and IsFirstTimePredicted())) then

      -- reduce recoil if ironsighting
      recoil = sights and (recoil * 0.5) or recoil

      self:GetOwner():ViewPunch(self.ViewPunch)

      local eyeang = self:GetOwner():EyeAngles()
      eyeang.pitch = eyeang.pitch - recoil
      eyeang.yaw = eyeang.yaw - math.Rand(-recoil, recoil)
      self:GetOwner():SetEyeAngles( eyeang )
   end
end

function SWEP:Think()
   self:CalcViewModel()

   if(self:GetIronsights()) then
      self.Primary.Delay       = 1.4
      self.Primary.Damage      = 11
      self.Primary.Cone        = 0.040
      self.ViewPunch = Angle(0,0,0)
      self:SetHoldType("revolver")
   else
      self.Primary.Delay       = 1.2
      self.Primary.Damage      = 9
      self.Primary.Cone        = 0.060
      self.ViewPunch = Angle(9,math.Rand(-7,7),math.Rand(-7,7))
      self:SetHoldType("pistol")
   end

   if self.Reloading and not self:GetIronsights() then
      self.defaultPos = LerpVector(0.1, self.defaultPos, Vector(-6, 2, -12))
      self.defaultAng = LerpVector(0.1, self.defaultAng, Vector(52, 0, 0))
   else
      self.defaultPos = LerpVector(0.1, self.defaultPos, Vector(0,0,0))
      self.defaultAng = LerpVector(0.1, self.defaultAng, Vector(0,0,0))
   end
end

function SWEP:GetViewModelPosition(pos, ang)
   local reloadOffset = self.defaultPos
   local reloadAngleOffset = self.defaultAng

   pos = pos + ang:Forward() * reloadOffset.x
   pos = pos + ang:Right() * reloadOffset.y
   pos = pos + ang:Up() * reloadOffset.z

   ang:RotateAroundAxis(ang:Right(), reloadAngleOffset.x)
   ang:RotateAroundAxis(ang:Up(), reloadAngleOffset.y)
   ang:RotateAroundAxis(ang:Forward(), reloadAngleOffset.z)

   if (not self.IronSightsPos) or (self.bIron == nil) then return pos, ang end

   local bIron = self.bIron
   local time = self.fCurrentTime + (SysTime() - self.fCurrentSysTime) * game.GetTimeScale()
   local ironsightTime = 0.25

   if bIron then
       self.SwayScale = 0.3
       self.BobScale = 0.1
   else
       self.SwayScale = 1.0
       self.BobScale = 1.0
   end

   local fIronTime = self.fIronTime
   if (not bIron) and fIronTime < time - ironsightTime then
       return pos, ang
   end

   local mul = 1.0
   if fIronTime > time - ironsightTime then
       mul = math.Clamp((time - fIronTime) / ironsightTime, 0, 1)
       if not bIron then mul = 1 - mul end
   end

   local offset = self.IronSightsPos

   if self.IronSightsAng then
       ang = ang * 1
       ang:RotateAroundAxis(ang:Right(), self.IronSightsAng.x * mul)
       ang:RotateAroundAxis(ang:Up(), self.IronSightsAng.y * mul)
       ang:RotateAroundAxis(ang:Forward(), self.IronSightsAng.z * mul)
   end

   pos = pos + offset.x * ang:Right() * mul
   pos = pos + offset.y * ang:Forward() * mul
   pos = pos + offset.z * ang:Up() * mul

   return pos, ang
end

function SWEP:Reload()
   if ( self:Clip1() == self.Primary.ClipSize or self:GetOwner():GetAmmoCount( self.Primary.Ammo ) <= 0 ) then return end
   
   if self:GetIronsights() then self:SetIronsights(not self:GetIronsights()) end

   self.Reloading = true

   timer.Simple(0.05, function()  if(self:IsValid()) then self.Reloading = false end end)
   timer.Simple(0.04, function()  if(self:IsValid()) then self:DefaultReload(ACT_VM_RELOAD) end end)
end

--- TTT config values

-- Kind specifies the category this weapon is in. Players can only carry one of
-- each. Can be: WEAPON_... MELEE, PISTOL, HEAVY, NADE, CARRY, EQUIP1, EQUIP2 or ROLE.
-- Matching SWEP.Slot values: 0      1       2     3      4      6       7        8
SWEP.Kind = WEAPON_PISTOL

-- If AutoSpawnable is true and SWEP.Kind is not WEAPON_EQUIP1/2, then this gun can
-- be spawned as a random weapon. Of course this AK is special equipment so it won't,
-- but for the sake of example this is explicitly set to false anyway.
SWEP.AutoSpawnable = false

-- The AmmoEnt is the ammo entity that can be picked up when carrying this gun.
SWEP.AmmoEnt = "item_box_buckshot_ttt"

-- CanBuy is a table of ROLE_* entries like ROLE_TRAITOR and ROLE_DETECTIVE. If
-- a role is in this table, those players can buy this.
SWEP.CanBuy = { ROLE_TRAITOR, ROLE_DETECTIVE }

-- InLoadoutFor is a table of ROLE_* entries that specifies which roles should
-- receive this weapon as soon as the round starts. In this case, none.
SWEP.InLoadoutFor = "none"

-- If LimitedStock is true, you can only buy one per round.
SWEP.LimitedStock = false

-- If AllowDrop is false, players can't manually drop the gun with Q
SWEP.AllowDrop = true

-- If IsSilent is true, victims will not scream upon death. :v
SWEP.IsSilent = false   

-- If NoSights is true, the weapon won't have ironsights 
SWEP.NoSights = false

-- Equipment menu information is only needed on the client
if CLIENT then
   -- Path to the icon material
   SWEP.Icon = "VGUI/ttt/icon_myserver_ak47"

   -- Text shown in the equip menu
   SWEP.EquipMenuData = {
      type = "Weapon",
      desc = "Taurus Judge revolver chambered in 12 gauge ammunition."
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