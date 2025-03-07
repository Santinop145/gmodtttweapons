---- Example TTT custom weapon

-- First some standard GMod stuff
if SERVER then
   AddCSLuaFile( "shared.lua" )
end

if CLIENT then
   SWEP.PrintName = "Prototype MP5"
   SWEP.Slot      = 6

   SWEP.ViewModelFOV  = 64
   SWEP.ViewModelFlip = false
end

-- Always derive from weapon_tttbase.
SWEP.Base				= "weapon_tttbase"

--- Standard GMod values

SWEP.HoldType			= "smg"
SWEP.UseHands = true
SWEP.Primary.Delay       = 0.09
SWEP.Primary.Recoil      = 1.1
SWEP.Primary.Automatic   = true
SWEP.Primary.Damage      = 5
SWEP.Primary.Cone        = 0.045
SWEP.Primary.Ammo        = "smg1"
SWEP.Primary.ClipSize    = 30
SWEP.Primary.ClipMax     = 90
SWEP.Primary.DefaultClip = 60
SWEP.Primary.Sound       = Sound( "weapon_smg1.Single" )
SWEP.HeadshotMultiplier = 1.35

SWEP.IronSightsPos = Vector( -6.4335, -7.5311, 1.0547 )
SWEP.IronSightsAng = Vector( -0.0664, -0.3223, -5.1457 )

SWEP.ViewModel  = "models/weapons/c_smg1.mdl"
SWEP.WorldModel = "models/weapons/w_smg1.mdl"

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
   bullet.Callback = function(att, tr, dmginfo)
      if SERVER or (CLIENT and IsFirstTimePredicted()) then
         local ent = tr.Entity
         if (not tr.HitWorld) and IsValid(ent) then
            local edata = EffectData()

            edata:SetEntity(ent)
            edata:SetMagnitude(3)
            edata:SetScale(2)

            util.Effect("TeslaHitBoxes", edata)

            if SERVER and ent:IsPlayer() then
               local eyeang = ent:EyeAngles()

               local j = math.Rand(-5, 5)
               eyeang.pitch = math.Clamp(eyeang.pitch + math.Rand(-j, j), -90, 90)
               eyeang.yaw = math.Clamp(eyeang.yaw + math.Rand(-j, j), -90, 90)
               ent:SetEyeAngles(eyeang)
            end
         end
      end
      local effectdata = EffectData()
      effectdata:SetEntity(self)
      effectdata:SetOrigin(tr.HitPos)
      util.Effect("cball_explode", effectdata)
  end

   self:GetOwner():FireBullets( bullet )

   -- Owner can die after firebullets
   if (not IsValid(self:GetOwner())) or self:GetOwner():IsNPC() or (not self:GetOwner():Alive()) then return end

   if ((game.SinglePlayer() and SERVER) or
       ((not game.SinglePlayer()) and CLIENT and IsFirstTimePredicted())) then

      -- reduce recoil if ironsighting
      if(self:GetOwner():Crouching()) then
         recoil = sights and (recoil * 0.3) or recoil
      else
         recoil = sights and (recoil * 0.7) or recoil
      end

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
      self.Primary.Delay       = 0.16
      self.Primary.Recoil      = 1.0
      self.Primary.Damage      = 7
      self.Primary.Cone        = 0.015
      self.ViewPunch = Angle(0.2,math.Rand(-0.4,0.4),math.Rand(-0.4,0.4))
   else
      self.Primary.Delay       = 0.09
      self.Primary.Recoil      = 1.1
      self.Primary.Damage      = 5
      self.Primary.Cone        = 0.045
      self.ViewPunch = Angle(0.8,math.Rand(-1.2,1.2),math.Rand(-1.2,1.2))
   end
end


--- TTT config values

-- Kind specifies the category this weapon is in. Players can only carry one of
-- each. Can be: WEAPON_... MELEE, PISTOL, HEAVY, NADE, CARRY, EQUIP1, EQUIP2 or ROLE.
-- Matching SWEP.Slot values: 0      1       2     3      4      6       7        8
SWEP.Kind = WEAPON_EQUIP1

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
SWEP.InLoadoutFor = "none"

-- If LimitedStock is true, you can only buy one per round.
SWEP.LimitedStock = false

-- If AllowDrop is false, players can't manually drop the gun with Q
SWEP.AllowDrop = true

-- If IsSilent is true, victims will not scream upon death.
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
      desc = "A more docile version of the Prototype UMP. \nTraitors can buy it too! \n\nShooting makes a noticeable effect \nMake sure not to be too obvious."
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