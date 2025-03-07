---- Example TTT custom weapon

-- First some standard GMod stuff
if SERVER then
   AddCSLuaFile( "shared.lua" )
end

if CLIENT then
   SWEP.PrintName = "Mine Placer"
   SWEP.Slot      = 7

   SWEP.ViewModelFOV  = 54
   SWEP.ViewModelFlip = false
end

-- Always derive from weapon_tttbase.
SWEP.Base				= "weapon_tttbase"

--- Standard GMod values

SWEP.HoldType			= "revolver"
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
SWEP.m_WeaponDeploySpeed = 10000
SWEP.PlantedMines = 0
SWEP.MineType = 0

SWEP.ViewModel  = "models/weapons/c_slam.mdl"
SWEP.WorldModel = "models/weapons/w_slam.mdl"

function SWEP:PrimaryAttack()
   if(SERVER) then
      if(self.PlantedMines < 3) then
         self.PlantedMines = self.PlantedMines+1
         if(self.MineType == 0) then
            self.CurrentType = "ttt_hoppermine"
         elseif(self.MineType == 1) then
            self.CurrentType = "ttt_hopperfire"
         else
            self.CurrentType = "ttt_hopperice"
         end
         local mine = ents.Create(self.CurrentType)
         mine:SetPos(self:GetOwner():EyePos() + (self.Owner:GetAimVector()*24))
         local mineAngle = Angle(self:GetOwner():EyeAngles().pitch, self:GetOwner():EyeAngles().yaw, 0)
         mine:SetAngles(mineAngle)
         mine.Owner = self:GetOwner()
         mine:Spawn()
      end
  end
end

function SWEP:Think()
   self:CalcViewModel()
end

function SWEP:SecondaryAttack()
   if(self.MineType < 2) then
      self.MineType = self.MineType+1
      self:EmitSound("weapons/grenade/tick1.wav", 60, 100, 1, CHAN_WEAPON)
   else
      self.MineType = 0
      self:EmitSound("weapons/grenade/tick1.wav", 60, 100, 1, CHAN_WEAPON)
   end
end
--- TTT config values

-- Kind specifies the category this weapon is in. Players can only carry one of
-- each. Can be: WEAPON_... MELEE, PISTOL, HEAVY, NADE, CARRY, EQUIP1, EQUIP2 or ROLE.
-- Matching SWEP.Slot values: 0      1       2     3      4      6       7        8
SWEP.Kind = WEAPON_EQUIP2

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
SWEP.LimitedStock = true

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
      desc = "It's a mine you can place. \nGoes kaboom when nearby other players. \nCould be triggered by other traitors!"
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