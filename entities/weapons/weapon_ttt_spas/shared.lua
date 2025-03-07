---- Example TTT custom weapon

-- First some standard GMod stuff
if SERVER then
   AddCSLuaFile( "shared.lua" )
end

if CLIENT then
   SWEP.PrintName = "Spas-12"
   SWEP.Slot      = 2

   SWEP.ViewModelFOV  = 64
   SWEP.ViewModelFlip = false
end

-- Always derive from weapon_tttbase.
SWEP.Base				= "weapon_tttbase"
DEFINE_BASECLASS("weapon_tttbase")

--- Standard GMod values

SWEP.HoldType			= "shotgun"
SWEP.UseHands = true
SWEP.Primary.Delay       = 1.5
SWEP.Primary.Recoil      = 4
SWEP.Primary.Automatic   = true
SWEP.Primary.Damage      = 15
SWEP.Primary.Cone        = 0.075
SWEP.Primary.Ammo        = "Buckshot"
SWEP.Primary.ClipSize    = 6
SWEP.Primary.ClipMax     = 12
SWEP.Primary.DefaultClip = 12
SWEP.Primary.Sound       = Sound( "weapon_shotgun.single" )
SWEP.HeadshotMultiplier = 4
SWEP.firstDeploy = true
SWEP.InterruptReload = false

SWEP.reloadpos = Vector(-3.4223, 4.2281, 4.139)
SWEP.reloadang = Vector(-7.8738, 24.9489, 8.8707)
SWEP.IronSightsPos = Vector( -7.1312, -14.7644, 2.8136 )
SWEP.IronSightsAng = Vector( 0.0115, -0.0468, 4.8856 )
SWEP.defAng = SWEP.IronSightsAng

SWEP.ViewModel  = "gamemodes/terrortown/content/models/weapons/c_shotgun.mdl"
SWEP.WorldModel = "models/weapons/w_shotgun.mdl"

function SWEP:ShootBullet( dmg, recoil, numbul, cone )

   self:SendWeaponAnim(self.PrimaryAnim)
   if(self:IsValid() and not self.Reloading) then
      timer.Simple(0.4, function()
         self.Pump = true
      end)
   end
   timer.Simple(0.6, function() 
      if(self:IsValid() and not self.Reloading) then 
         timer.Simple(0.4, function()
            self.Pump = false
         end)
         if(self:GetOwner():Alive() and self:GetOwner():IsValid()) then
            self:GetOwner():ViewPunch(Angle(1,-2,-1))
            self:EmitSound("weapons/shotgun/shotgun_cock.wav", 70, 100, 1, CHAN_AUTO) self:SendWeaponAnim(ACT_SHOTGUN_PUMP) 
         end
      end
   end)
   self:GetOwner():MuzzleFlash()
   self:GetOwner():SetAnimation( PLAYER_ATTACK1 )

   local sights = self:GetIronsights()

   numbul = 6
   cone   = cone   or 0.01

   local bullet = {}
   bullet.Num    = numbul
   bullet.Src    = self:GetOwner():GetShootPos()
   bullet.Dir    = self:GetOwner():GetAimVector()
   bullet.Spread = Vector( cone, cone, 0 )
   bullet.Tracer = 2
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

      self.IronSightsAng = Vector(math.Clamp(self.IronSightsAng.x + math.Rand(-recoil*1.7,recoil*1.7), -1.9, 3), math.Clamp(self.IronSightsAng.y + math.Rand(-recoil*1.7,recoil*1.7), -1.2, 1.2), math.Clamp(self.IronSightsAng.z + math.Rand(-recoil*2.1,recoil*2.1), -6, 6))

      local eyeang = self:GetOwner():EyeAngles()
      eyeang.pitch = eyeang.pitch - recoil
      eyeang.yaw = eyeang.yaw - math.Rand(-recoil, recoil)
      self:GetOwner():SetEyeAngles( eyeang )
   end
end

function SWEP:Deploy()
   if(self.firstDeploy) then
      self:SetNextPrimaryFire( CurTime() + 1)
      self:EmitSound("weapons/shotgun/shotgun_deploy.wav", 80, 100, 1, CHAN_AUTO)
      timer.Simple(0.4, function() 
         if(self:IsValid() and not self.Reloading) then 
            if(self:GetOwner():IsValid() and self:GetOwner():Alive()) then
               self:GetOwner():ViewPunch(Angle(1,2,1))
            end
            self:EmitSound("weapons/shotgun/shotgun_cock.wav", 70, 100, 1, CHAN_AUTO) self:SendWeaponAnim(ACT_SHOTGUN_PUMP) 
         end
      end)
   end
   self.firstDeploy = false
   self.Reloading = false
   self.ReloadTimer = 0
end

function SWEP:Reload()

   if self.Reloading then return end

   if self:GetOwner():KeyDown(1) then
      self.InterruptReload = true
   else
      self.InterruptReload = false
   end

   if self:Clip1() < self.Primary.ClipSize and self:GetOwner():GetAmmoCount( self.Primary.Ammo ) > 0 then

      if self:StartReload() then
         return
      end
   end

end

function SWEP:StartReload()
   if self.Reloading or self.InterruptReload then
      return false
   end
   

   self:SetIronsights( false )

   self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )

   local ply = self:GetOwner()

   if not ply or ply:GetAmmoCount(self.Primary.Ammo) <= 0 then
      return false
   end

   local wep = self

   if wep:Clip1() >= self.Primary.ClipSize then
      return false
   end

   self:EmitSound("weapons/movement/weapon_movement1.wav", 80, 100, 1, CHAN_AUTO)
   wep:SendWeaponAnim(ACT_SHOTGUN_RELOAD_START)

   self.ReloadTimer = CurTime() + 0.8

   self.Reloading = true

   if(self:GetOwner():IsValid() and self:GetOwner():Alive()) then
      self:GetOwner():ViewPunch(Angle(0.5,-1,0.5))
   end

   return true
end

function SWEP:PerformReload()
   if self.InterruptReload then return end

   local ply = self:GetOwner()

   -- prevent normal shooting in between reloads
   self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )

   if not ply or ply:GetAmmoCount(self.Primary.Ammo) <= 0 then return end

   if self:Clip1() >= self.Primary.ClipSize then return end

   self:GetOwner():RemoveAmmo( 1, self.Primary.Ammo, false )
   self:SetClip1( self:Clip1() + 1 )
   local i = math.random(1, 6)
   self:EmitSound("weapons/shotgun/shotgun_reload" .. i .. ".wav", 70, 100, 1, CHAN_AUTO, 0, 0, self:GetOwner())
   if(self:GetOwner():IsValid() and self:GetOwner():Alive()) then
      self:GetOwner():ViewPunch(Angle(-2,1,0))
   end

   self:SendWeaponAnim(ACT_VM_RELOAD)
   self:GetOwner():SetAnimation( PLAYER_RELOAD )

   self.ReloadTimer = CurTime() + 0.8
end

function SWEP:FinishReload()
   self.Reloading = false
   self.InterruptReload = true

   self.Pump = false
   self:SendWeaponAnim(ACT_SHOTGUN_RELOAD_FINISH)
   self:EmitSound("weapons/movement/weapon_movement2.wav", 80, 100, 1, CHAN_AUTO)

   self.ReloadTimer = CurTime() + 0.8
end

function SWEP:Think()
   self:CalcViewModel()

   if(not self.Reloading) then
      self.IronSightsAng = Vector(math.Approach(self.IronSightsAng.x, self.defAng.x, 0.5), math.Approach(self.IronSightsAng.y, self.defAng.y, 0.5), math.Approach(self.IronSightsAng.z, self.defAng.z, 0.5))
   end

   if(self:GetIronsights()) then
      self.Primary.Damage      = 16
      self.Primary.Cone        = 0.050
      self.ViewPunch = Angle(-0.2,math.Rand(-0.3,0.3),math.Rand(-0.3,0.3))
      self:SetHoldType("ar2")
   else
      self.Primary.Damage      = 15
      self.Primary.Cone        = 0.075
      self.ViewPunch = Angle(-1,math.Rand(-1.3,1.3),math.Rand(-1.3,1.3))
      self.IronSightsAng = self.defAng
      self:SetHoldType("shotgun")
   end

   if self.Reloading and not self:GetIronsights() then
      self.reloadpos = LerpVector(0.1, self.reloadpos, Vector(-5, 0, -2))
      self.reloadang = LerpVector(0.1, self.reloadang, Vector(-10, 5, -30))
   elseif self.Pump and not self:GetIronsights() then
      self.reloadpos = LerpVector(0.1, self.reloadpos, Vector(-2,15,0))
      self.reloadang = LerpVector(0.1, self.reloadang, Vector(8,35,40))
   else
      self.reloadpos = LerpVector(0.1, self.reloadpos, Vector(0, 0, 0))
      self.reloadang = LerpVector(0.1, self.reloadang, Vector(0, 0, 0))
   end

   if self.Reloading then
      if self:GetOwner():KeyDown(IN_ATTACK) then
         self.InterruptReload = true
         self:FinishReload()
         return
      end

      if self.ReloadTimer <= CurTime() then

         if self:GetOwner():GetAmmoCount(self.Primary.Ammo) <= 0 then
            self:FinishReload()
         elseif self:Clip1() < self.Primary.ClipSize then
            self:PerformReload()
         else
            self:FinishReload()
         end
         return
      end
   end
end

function SWEP:GetViewModelPosition(pos, ang)
   local reloadOffset = self.reloadpos
   local reloadAngleOffset = self.reloadang

    -- Apply positional offset
   pos = pos + ang:Forward() * reloadOffset.x
   pos = pos + ang:Right() * reloadOffset.y
   pos = pos + ang:Up() * reloadOffset.z

    -- Apply angular offset
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

function SWEP:SecondaryAttack()
   if self.NoSights or (not self.IronSightsPos) or self.Reloading then return end

   self:SetIronsights(not self:GetIronsights())
   self:EmitSound("weapons/movement/weapon_movement3.wav", 60, 100, 1, CHAN_AUTO)

   self:SetNextSecondaryFire(CurTime() + 0.3)
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
SWEP.AmmoEnt = "item_box_buckshot_ttt"

-- CanBuy is a table of ROLE_* entries like ROLE_TRAITOR and ROLE_DETECTIVE. If
-- a role is in this table, those players can buy this.
SWEP.CanBuy = { ROLE_TRAITOR, ROLE_DETECTIVE }

-- InLoadoutFor is a table of ROLE_* entries that specifies which roles should
-- receive this weapon as soon as the round starts. In this case, none.
SWEP.InLoadoutFor = "none"

-- If LimitedStock is true, you can only buy one per round.
SWEP.LimitedStock = true

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
      desc = "Classic Spas-12\nNo, no double fire mode.\nChambered in Magnum Buckshot\nPacks a big punch."
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