---- Example TTT custom weapon

-- First some standard GMod stuff
if SERVER then
   AddCSLuaFile( "shared.lua" )
end

if CLIENT then
   SWEP.PrintName = "Silenced P90"
   SWEP.Slot      = 2

   SWEP.ViewModelFOV  = 64
   SWEP.ViewModelFlip = false
end

-- Always derive from weapon_tttbase.
SWEP.Base				= "weapon_tttbase"

--- Standard GMod values

SWEP.HoldType			= "smg"
SWEP.UseHands = true
SWEP.Primary.Delay       = 0.08
SWEP.Primary.Recoil      = 1.2
SWEP.Primary.Automatic   = true
SWEP.Primary.Damage      = 8
SWEP.Primary.Cone        = 0.060
SWEP.Primary.Ammo        = "smg1"
SWEP.Primary.ClipSize    = 50
SWEP.Primary.ClipMax     = 100
SWEP.Primary.DefaultClip = 50
SWEP.Primary.Sound       = Sound( "Weapon_USP.SilencedShot" )
SWEP.HeadshotMultiplier = 2.5
SWEP.defRecoil = SWEP.Primary.Recoil

SWEP.IronSightsPos = Vector( -5.6348, -5.7425, 1.0578 )
SWEP.IronSightsAng = Vector( 0.9642, 0.1826, -1.0845 )
SWEP.defAng = SWEP.IronSightsAng

SWEP.ViewModel  = "models/weapons/cstrike/c_smg_p90.mdl"
SWEP.WorldModel = "models/weapons/w_smg_p90.mdl"

function SWEP:ShootBullet( dmg, recoil, numbul, cone )

   self:SendWeaponAnim(self.PrimaryAnim)
   self:GetOwner():MuzzleFlash()
   self:GetOwner():SetAnimation( PLAYER_ATTACK1 )

   local sights = self:GetIronsights()

   numbul = numbul or 1
   cone   = cone   or 0.01

   local bullet = {}
   bullet.Num    = numbul
   bullet.Src    = self:GetOwner():GetShootPos()
   bullet.Dir    = self:GetOwner():GetAimVector()
   bullet.Spread = Vector( cone, cone, 0 )
   bullet.Tracer = 4
   bullet.TracerName = self.Tracer or "Tracer"
   bullet.Force  = 10
   bullet.Damage = dmg

   self:GetOwner():FireBullets( bullet )

   -- Owner can die after firebullets
   if (not IsValid(self:GetOwner())) or self:GetOwner():IsNPC() or (not self:GetOwner():Alive()) then return end

   if ((game.SinglePlayer() and SERVER) or
       ((not game.SinglePlayer()) and CLIENT and IsFirstTimePredicted())) then

      -- reduce recoil if ironsighting
      if(self:GetOwner():Crouching() and not (self:GetOwner():GetVelocity():LengthSqr() > 0)) then
         recoil = sights and (recoil * 0.4) or recoil * 0.6
      elseif(self:GetOwner():Crouching()) then
         recoil = sights and (recoil * 0.8) or recoil * 0.9
      elseif(not (self:GetOwner():GetVelocity():LengthSqr() > 0)) then
         recoil = sights and (recoil * 0.7) or recoil
      else
         recoil = sights and (recoil * 1.2) or recoil * 1.3
      end

      self:GetOwner():ViewPunch(self.ViewPunch)

      self.IronSightsAng = Vector(math.Clamp(self.IronSightsAng.x + math.Rand(-recoil*1.3,recoil*1.3), -1.9, 3), math.Clamp(self.IronSightsAng.y + math.Rand(-recoil*1.3,recoil*1.3), -1.2, 1.2), math.Clamp(self.IronSightsAng.z + math.Rand(-recoil*1.7,recoil*1.7), -6, 6))

      local eyeang = self:GetOwner():EyeAngles()
      eyeang.pitch = eyeang.pitch - recoil
      eyeang.yaw = eyeang.yaw - math.Rand(-recoil, recoil)
      self:GetOwner():SetEyeAngles( eyeang )
   end
end

function SWEP:Think()
   self:CalcViewModel()

   self.IronSightsAng = Vector(math.Approach(self.IronSightsAng.x, self.defAng.x, 0.5), math.Approach(self.IronSightsAng.y, self.defAng.y, 0.5), math.Approach(self.IronSightsAng.z, self.defAng.z, 0.5))

   if(self:GetIronsights()) then
      self.Primary.Delay       = 0.1
      self.Primary.Damage      = 9
      self.Primary.Cone        = 0.020
      self.ViewPunch = Angle(0.1,math.Rand(-0.3,0.3),math.Rand(-0.3,0.3))
   else
      self.Primary.Delay       = 0.08
      self.Primary.Damage      = 8
      self.Primary.Cone        = 0.060
      self.ViewPunch = Angle(0.8,math.Rand(-1.2,1.2),math.Rand(-1.2,1.2))
      self.IronSightsAng = self.defAng
   end
end


--- TTT config values

-- Kind specifies the category this weapon is in. Players can only carry one of
-- each. Can be: WEAPON_... MELEE, PISTOL, HEAVY, NADE, CARRY, EQUIP1, EQUIP2 or ROLE.
-- Matching SWEP.Slot values: 0      1       2     3      4      6       7        8
SWEP.Kind = WEAPON_HEAVY

-- If AutoSpawnable is true and SWEP.Kind is not WEAPON_EQUIP1/2, then this gun can
-- be spawned as a random weapon. Of course this AK is special equipment so it won't,
-- but for the sake of example this is explicitly set to false anyway.
SWEP.AutoSpawnable = true

-- The AmmoEnt is the ammo entity that can be picked up when carrying this gun.
SWEP.AmmoEnt = "item_ammo_smg1_ttt"

-- CanBuy is a table of ROLE_* entries like ROLE_TRAITOR and ROLE_DETECTIVE. If
-- a role is in this table, those players can buy this.
SWEP.CanBuy = { ROLE_TRAITOR, ROLE_DETECTIVE }

-- InLoadoutFor is a table of ROLE_* entries that specifies which roles should
-- receive this weapon as soon as the round starts. In this case, none.
SWEP.InLoadoutFor = ROLE_DETECTIVE

-- If LimitedStock is true, you can only buy one per round.
SWEP.LimitedStock = true

-- If AllowDrop is false, players can't manually drop the gun with Q
SWEP.AllowDrop = true

-- If IsSilent is true, victims will not scream upon death.
SWEP.IsSilent = true

-- If NoSights is true, the weapon won't have ironsights
SWEP.NoSights = false

-- Equipment menu information is only needed on the client
if CLIENT then
   -- Path to the icon material
   SWEP.Icon = "VGUI/ttt/icon_myserver_ak47"

   -- Text shown in the equip menu
   SWEP.EquipMenuData = {
      type = "Weapon",
      desc = "The powerful P90, customized with an integrated silencer.\nDon't ask how."
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