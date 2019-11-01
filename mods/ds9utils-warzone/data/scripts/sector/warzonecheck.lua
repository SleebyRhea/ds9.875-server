WarZoneCheck.data.warZoneThreshold = 100        --Threshold before zone is hazardous
WarZoneCheck.data.pacefulThreshold = 70         --Threshold before the score reaches peaceful levels

if onServer() then
        function WarZoneCheck.updateServer(timeStep)
                local sector = Sector()

                if sector:getValue("war_zone") and not sector:getValue("admin_war_zone") then
                        WarZoneCheck.undeclareWarZone()
                end
        end

        function WarZoneCheck.declareWarZone()
        end

        function WarZoneCheck.undeclareWarZone()
                local sector = Sector()

                -- if this is not a war zone, don't do anything
                if not sector:getValue("war_zone") then return end

                sector:setValue("war_zone", nil)
                self.data.score = math.min(self.data.score, self.data.pacefulThreshold) -- declaration of war zone: increase sector's score to avoid inconsistency

                WarZoneCheck.callOutPeaceZone()

                -- reinforcements are no longer necessary
                deferredCallback(5, "despawnReinforcements")
        end


        function WarZoneCheck.increaseScore()
        end


end

