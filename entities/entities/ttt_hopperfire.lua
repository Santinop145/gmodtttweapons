AddCSLuaFile()

ENT.Type = "anim"
ENT.Model = Model("models/weapons/w_slam.mdl")
ENT.Exploded = false

function ENT:Initialize() 
    self:SetModel(self.Model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_BBOX)
    self:SetRenderMode( RENDERMODE_TRANSCOLOR )
    self:SetColor(Color(200, 0, 100, 255))  

    if(SERVER) then
        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:ApplyForceCenter(self.Owner:GetAimVector() * 200)
        end
    end
end

if (SERVER) then
    function ENT:Think() 
        local explodeCheck = ents.FindInSphere(self:GetPos(), 150)

        for k, foundEntity in ipairs(explodeCheck) do
            if(foundEntity:IsValid() and foundEntity:IsPlayer() and foundEntity ~= self.Owner and not self.Exploded) then

                local tr1 = util.TraceLine({
                    start = self:GetPos()+ Vector(0, 0, 1),
                    endpos = foundEntity:GetPos() + Vector(0, 0, 50),
                    filter = self
                })
    
                local tr2 = util.TraceLine({
                    start = self:GetPos()+ Vector(0, 0, 1),
                    endpos = foundEntity:EyePos() + Vector(0, 0, 1),
                    filter = self
                })
    
                local tr3 = util.TraceLine({
                    start = self:GetPos()+ Vector(0, 0, 1),
                    endpos = foundEntity:GetPos() + Vector(0, 0, 35),
                    filter = self
                })

                if (tr1.Hit and tr1.Entity == foundEntity or tr2.Hit and tr2.Entity == foundEntity or tr3.Hit and tr3.Entity == foundEntity) then
                    local explode = ents.Create("env_explosion")
                    explode:SetPos(self:GetPos())
                    explode:SetOwner(self.Owner)
                    explode:Spawn()
                    explode:SetKeyValue("iMagnitude", "40")
                    explode:SetKeyValue("iRadiusOverride", "200")
                    explode:Fire("Explode", 0, 0)
                    explode:EmitSound("weapons/explode5.wav", 200, 200)
                    self.Exploded = true
                    timer.Simple(10, function() self:Remove() end)
                end
            end

            if(self.Exploded and foundEntity:IsPlayer() and foundEntity:IsValid()) then

                local tr1 = util.TraceLine({
                    start = self:GetPos()+ Vector(0, 0, 1),
                    endpos = foundEntity:GetPos() + Vector(0, 0, 50),
                    filter = self
                })
                
                local tr2 = util.TraceLine({
                    start = self:GetPos()+ Vector(0, 0, 1),
                    endpos = foundEntity:EyePos() + Vector(0, 0, 1),
                    filter = self
                })
            
                local tr3 = util.TraceLine({
                    start = self:GetPos()+ Vector(0, 0, 1),
                    endpos = foundEntity:GetPos() + Vector(0, 0, 35),
                    filter = self
                })

                if(tr1.Hit and tr1.Entity == foundEntity or tr2.Hit and tr2.Entity == foundEntity or tr3.Hit and tr3.Entity == foundEntity) then
                    foundEntity:Ignite(4, 100)
                    self:Ignite(10, 200)
                end
            end
        end

        local radiusCheck = ents.FindInSphere(self:GetPos(), 225)
        self.foundPlayers = {}

        for _, foundEntity in ipairs(radiusCheck) do
            if foundEntity:IsPlayer() and foundEntity:IsValid() then
                table.insert(self.foundPlayers, foundEntity)
            end
        end    

        self.transparency = self:GetColor()
        self.shouldFadeIn = false

        for _, foundPlayer in ipairs(self.foundPlayers) do
            local tr1 = util.TraceLine({
                start = self:GetPos()+ Vector(0, 0, 1),
                endpos = foundPlayer:GetPos() + Vector(0, 0, 50),
                filter = self
            })

            local tr2 = util.TraceLine({
                start = self:GetPos()+ Vector(0, 0, 1),
                endpos = foundPlayer:EyePos() + Vector(0, 0, 1),
                filter = self
            })

            local tr3 = util.TraceLine({
                start = self:GetPos()+ Vector(0, 0, 1),
                endpos = foundPlayer:GetPos() + Vector(0, 0, 35),
                filter = self
            })
    
            if (tr1.Hit and tr1.Entity == foundPlayer or tr2.Hit and tr2.Entity == foundPlayer or tr3.Hit and tr3.Entity == foundPlayer) then
                self.shouldFadeIn = true
                break
            end
        end

        if self.shouldFadeIn then
            self.transparency.a = math.min(self.transparency.a + 30, 255)
        else
            self.transparency.a = math.max(self.transparency.a - 80, 25)
        end
    
        self:SetColor(self.transparency)    
    end
end