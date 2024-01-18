-- i hate all of this code i hate all of it its the worst code i have ever written i wish to never write code again 1272316a
-- (continuation) im not even sure what 90% of this stuff does i just kinda keep it in because maybe somewhere in the code it is required to funtion its like that coconut from tf2 when you delete it but i guess that wasnt real i dont know im just mad.

--if not ConVarExists("lassoSwepStruggleTimes") then
	--CreateConVar("lassoSwepStruggleTimes", "5000", FCVAR_ARCHIVE)
--end

if ( SERVER ) then
	AddCSLuaFile( "shared.lua" )
	
	SWEP.HoldType			= "pistol"

	util.AddNetworkString("SendRaycastToServerLasso")
	util.AddNetworkString("SetLassoedState")
	util.AddNetworkString("LassoStrugglePressedServer")
	util.AddNetworkString("LassoStrugglePressedClient")
	util.AddNetworkString("ReleaseRagdollLassoServer")
	util.AddNetworkString("ReleaseRagdollLassoClients")
	util.AddNetworkString("SyncLassoCreateWithClient")
	
end

if ( CLIENT ) then 
	if not ConVarExists("lassoSwepKeyBind") then
		CreateClientConVar("lassoSwepKeyBind", "65", true, false)
	end
	SWEP.PrintName			= "Lasso"			
	SWEP.Author			= "Briann"

	SWEP.Slot			= 0
	SWEP.SlotPos			= 1
	SWEP.iconletter			= "l"
	
	local Color_Icon = Color( 255, 80, 0, 128 )

end

SWEP.Base			= "weapon_base"

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= true
SWEP.UseHands = true
SWEP.AdminOnly = false //IF ITS ADMIN ONLY CHANGE HERE!

SWEP.ViewModel			= "models/weapons/c_pistol.mdl"
SWEP.WorldModel			= "models/weapons/c_pistol.mdl"
SWEP.ViewModelFlip 		= false

SWEP.Weight			= 5
SWEP.AutoSwitchTo		= false
SWEP.AutoSwitchFrom		= false

SWEP.HoldType = "Pistol" // How the swep is hold Pistol smg greanade melee 
 
SWEP.FiresUnderwater = true // Does your swep fire under water ? 
 
SWEP.Weight = 5 // Chose the weight of the Swep 
 
SWEP.DrawCrosshair = true // Do you want it to have a crosshair ? 
 
SWEP.Category = "Lasso Mod" // Make your own catogory for the swep 
 
SWEP.DrawAmmo = false // Does the ammo show up when you are using it ? True / False 
 
SWEP.ReloadSound = "sound/weapons/alyxgun/alyx_gun_reload.wav" // Reload sound, you can use the default ones, or you can use your one; Example; "sound/myswepreload.waw" 
 
SWEP.base = "weapon_base" 

SWEP.CSMuzzleFlashes = true

local function switchLassoState(newState, ply)
	if not IsValid(ply) then
		return
	end
	if ply.ragdollType ~= nil then
		if ply.ragdollType == "player" then
			ply.playerLassoedDupe.canLassoSpawn = newState
		end
	end
end

function SWEP:PrimaryAttack() 
	print("ran1")
	 if CLIENT then
		print("ran")
		local tr = util.TraceHull( {

			start = LocalPlayer():GetShootPos(),
			endpos = LocalPlayer():GetShootPos() + LocalPlayer():GetAimVector() * 300,
			mins =  Vector(1,1,1) * -10,
			maxs =  Vector(1,1,1) * 10,
			filter =  function( ent ) return ( ent:GetClass() == "player" || ent:IsNPC() && ent ~= LocalPlayer()) end

		} )
		if not IsValid(tr.Entity) then
			return
		end
		net.Start("SendRaycastToServerLasso")
		net.WriteEntity(tr.Entity)
		net.WriteEntity(LocalPlayer())
		net.SendToServer()
	 end
end 
local function createRagdoll(hitEnt)
	rag = ents.Create("prop_ragdoll")
	rag:SetPos(hitEnt:GetPos())
	rag:SetAngles(hitEnt:GetAngles() - Angle(hitEnt:GetAngles().p,0,0))
	rag:SetModel(hitEnt:GetModel())
	rag:SetColor4Part(hitEnt:GetColor4Part())
	rag:SetMaterial(hitEnt:GetMaterial())
	rag:SetCreator(hitEnt)
	for k, v in ipairs(hitEnt:GetBodyGroups()) do
		rag:SetBodygroup( v.id, hitEnt:GetBodygroup(v.id) )
	end
	rag:Spawn()
	local plyvel = hitEnt:GetVelocity()
	for i = 0, rag:GetPhysicsObjectCount() - 1 do
		local bone = rag:GetPhysicsObjectNum(i)
		
		if bone and bone:IsValid() then
			local bonepos, boneang = hitEnt:GetBonePosition(rag:TranslatePhysBoneToBone(i))
			
			bone:SetPos(bonepos)
			bone:SetAngles(boneang)
			bone:SetVelocity(plyvel * 1)
		end	
	end
	return rag
end


net.Receive("SetLassoedState", function(length) //client bool junk idk
	-- remanantsnt nantna of an old thing but its still here and im not sure if i want to delete it yet becaues it could still be used somehwere and im scared 123231206a
	local state = net.ReadBool()
	local ply = net.ReadEntity()
	if state == true then
		ply.lassoStruggleNum = 0
	end
	ply.lassoState = state
end)

net.Receive("LassoStrugglePressedServer", function(length) //client bool junk idk
	net.Start("LassoStrugglePressedClient")
	net.WriteEntity(net.ReadEntity())
	net.Broadcast()
end) 
net.Receive("LassoStrugglePressedClient", function(length) //i have a feeling there is a different way to do it but as the famous saying goes if it works it works. 119231043a
	local ply = net.ReadEntity()
	ply.lassoStruggleNum = ply.lassoStruggleNum + 50
end)



net.Receive("SendRaycastToServerLasso", function(length)
	local hitEnt = net.ReadEntity()
	local ply = net.ReadEntity()
	if IsValid(ply.LassoRagdoll) then
		return
	end

	if hitEnt:IsPlayer() then
		ply.ragdollType = "player"
	elseif hitEnt:IsNPC() then
		ply.ragdollType = "npc"
	end

	rag = createRagdoll(hitEnt)
	ply.LassoRagdoll = rag
	if ply.ragdollType == "npc" then
		ply.playerLassoedDupe = duplicator.Copy(hitEnt)
		hitEnt:Remove()
	end
	if ply.ragdollType == "player" then
		hitEnt:Spectate( OBS_MODE_CHASE )
		hitEnt:SpectateEntity( rag )
		hitEnt:SetActiveWeapon( NULL )
		hitEnt.lassoedByPlayer = ply
		ply.playerLassoedDupe = hitEnt
		switchLassoState(true, ply)
		net.Start("SetLassoedState")
		net.WriteBool(true)
		net.WriteEntity(ply.playerLassoedDupe)
		net.Broadcast()
	end
	ply.lassoIsReleased = false

	net.Start("SyncLassoCreateWithClient")
	net.WriteEntity(ply)
	net.WriteEntity(hitEnt)
	net.WriteEntity(ply.ragdollType)
	net.WriteEntity(ply.LassoRagdoll)
	net.Broadcast()

	local constraintThing, RopeThing = constraint.Rope(
			ply, rag,
			0, 0,
			Vector(0, 0, 0), Vector(0, 0, 0),
			0, 0, 0.00, 2, "cable/rope", false
	)

end)

net.Receive("SyncLassoCreateWithClient", function(length) --sync the junk up xdddd0d;d0;dd0dl0d uygbghghujhyth 122231158p

	ply = net.ReadEntity()
	hitEnt = net.ReadEntity()
	UNragdollType = net.ReadEntity()
	UNlassoRagdoll = net.ReadEntity()
	ply.LassoRagdoll = UNlassoRagdoll
	ply.lassoIsReleased = false
	ply.ragdollType = UNragdollType
	if ply.ragdollType == "npc" then
		ply.playerLassoedDupe = duplicator.Copy(hitEnt)
	end
	if ply.ragdollType == "player" then
		hitEnt.lassoedByPlayer = ply
		ply.playerLassoedDupe = hitEnt
	end
	ply.lassoIsReleased = false
end)

function SWEP:SecondaryAttack() 
	if IsValid(self.Owner.LassoRagdoll) and self.Owner.lassoIsReleased == false then
		if SERVER then
			constraint.RemoveConstraints(self:GetOwner(), "Rope")
		end
		self.Owner.lassoIsReleased = true
		self.Owner.playerLassoedDupe.lassoState = false
		net.Start("SetLassoedState")
		net.WriteBool(false)
		net.WriteEntity(self.Owner.playerLassoedDupe)
		net.Broadcast()
		--clear the dang things
	else
		self.Owner.playerLassoedDupe = {}
		self.Owner.LassoRagdoll = nil
		self.Owner.ragdollType = nil
	end
end 

net.Receive("ReleaseRagdollLassoServer", function(length) --ok since this is going from client to server i need to do it again for the clients too because if i just do it from where this gets started it will only work from 1 client so i need to do server then broadcast (i think) 123231215a
	releasePly = net.ReadEntity()
	local ptable = player.GetAll()
	local torturer = nil
	for k, v in pairs(ptable) do
		if v:UserID() == releasePly:UserID() then
			torturer = v
			break
		end
	end
	torturer = releasePly.lassoedByPlayer
	if IsValid(torturer.LassoRagdoll) and torturer.lassoIsReleased == false then
		if SERVER then
			constraint.RemoveConstraints(torturer, "Rope")
		end
		torturer.lassoIsReleased = true
		--clear the dang things
	else
		torturer.lassoIsReleased = false
		torturer.playerLassoedDupe = {}
		torturer.LassoRagdoll = nil
		torturer.ragdollType = nil
	end
	net.Start("SetLassoedState")
	net.WriteBool(false)
	net.WriteEntity(torturer.playerLassoedDupe)
	net.Broadcast()
	net.Start("ReleaseRagdollLassoClients")
	net.WriteEntity(torturer)
	net.Broadcast()
end)

net.Receive("ReleaseRagdollLassoClients", function(length)
	torturer = net.ReadEntity()
	if IsValid(torturer.LassoRagdoll) and torturer.lassoIsReleased == false then
		torturer.lassoIsReleased = true
		--clear the dang things
	end
end)

hook.Add( "PlayerDeath", "LassoDeath", function( victim, inflictor, attacker )
		if IsValid(victim.lassoedByPlayer) then
			if SERVER then
				constraint.RemoveConstraints(victim.lassoedByPlayer, "Rope")
			end			
			victim.lassoedByPlayer.playerLassoedDupe.canLassoSpawn = false
			victim.lassoedByPlayer.playerLassoedDupe = {}
			victim.lassoedByPlayer.LassoRagdoll = nil 
			victim.lassoedByPlayer.ragdollType = nil
			victim.lassoedByPlayer = nil

			
		end
	if SERVER then
		if IsValid(victim.playerLassoedDupe) and victim.ragdollType == "player" then
			net.Start("SetLassoedState")
			net.WriteBool(false)
			net.WriteEntity(victim.playerLassoedDupe)
			net.Broadcast()
		end
		net.Start("SetLassoedState")
		net.WriteBool(false)
		net.WriteEntity(victim)
		net.Broadcast()
	end
	if IsValid(victim.LassoRagdoll) and victim.lassoIsReleased == false then
		if SERVER then
			constraint.RemoveConstraints(victim, "Rope")
		end
		victim.lassoIsReleased = true
		victim.playerLassoedDupe.lassoState = false
		net.Start("SetLassoedState")
		net.WriteBool(false)
		net.WriteEntity(victim.playerLassoedDupe)
		net.Broadcast()
		--clear the dang things
	else
		victim.playerLassoedDupe = {}
		victim.LassoRagdoll = nil
		victim.ragdollType = nil
	end
end )

hook.Add( "PlayerDisconnected", "Playerleave", function(victim) --yooiiiinnkkkk 12723110a
    if IsValid(victim.lassoedByPlayer) then
		if SERVER then
			constraint.RemoveConstraints(victim.lassoedByPlayer, "Rope")
		end			
		victim.lassoedByPlayer.playerLassoedDupe.canLassoSpawn = false
		victim.lassoedByPlayer.playerLassoedDupe = {}
		victim.lassoedByPlayer.LassoRagdoll = nil 
		victim.lassoedByPlayer.ragdollType = nil
		victim.lassoedByPlayer = nil

		
	end
if SERVER then
	if IsValid(victim.playerLassoedDupe) and victim.ragdollType == "player" then
		net.Start("SetLassoedState")
		net.WriteBool(false)
		net.WriteEntity(victim.playerLassoedDupe)
		net.Broadcast()
	end
	net.Start("SetLassoedState")
	net.WriteBool(false)
	net.WriteEntity(victim)
	net.Broadcast()
end
if IsValid(victim.LassoRagdoll) and victim.lassoIsReleased == false then
	if SERVER then
		constraint.RemoveConstraints(victim, "Rope")
	end
	victim.lassoIsReleased = true
	victim.playerLassoedDupe.lassoState = false
	net.Start("SetLassoedState")
	net.WriteBool(false)
	net.WriteEntity(victim.playerLassoedDupe)
	net.Broadcast()
	--clear the dang things
else
	victim.playerLassoedDupe = {}
	victim.LassoRagdoll = nil
	victim.ragdollType = nil
end
end )

hook.Add("Think", "LassoThinaaaakPlayers", function()
	if CLIENT then //just gonna slot this in here
		if input.IsKeyDown(LocalPlayer():GetInfoNum("lassoSwepKeyBind", "65")) and LocalPlayer().lassoState == true then
			if !LocalPlayer().lassoHeldDown then
				LocalPlayer().lassoHeldDown = true
				net.Start("LassoStrugglePressedServer")
				net.WriteEntity(LocalPlayer())
				net.SendToServer()
			end
		else
			if LocalPlayer().lassoHeldDown then 
				LocalPlayer().lassoHeldDown = false 
			end 
		end// also slot this in here 119231048a
		if LocalPlayer().lassoStruggleNum == 3000 then
			LocalPlayer().lassoStruggleNum = 0
			net.Start("ReleaseRagdollLassoServer")
			net.WriteEntity(LocalPlayer())
			net.SendToServer()
		end
	end

	local ptable = player.GetAll()
	for k, v in pairs(ptable) do
		if IsValid(v.LassoRagdoll) and v.lassoIsReleased == true then
			local mashVelocity = v.LassoRagdoll:GetVelocity().x + v.LassoRagdoll:GetVelocity().y + v.LassoRagdoll:GetVelocity().z
			if math.abs(mashVelocity) <= 5 then
				if SERVER then
					if v.ragdollType == "npc" then
						local spawnedGuy = duplicator.Paste(v, v.playerLassoedDupe.Entities, v.playerLassoedDupe.Constraints)
						local lassoPos = v.LassoRagdoll:GetPos()
						v.LassoRagdoll:Remove()
						for k2, v2 in pairs(spawnedGuy) do
							v2:SetPos(lassoPos)
						end
					end
					if v.ragdollType == "player" then
						v.playerLassoedDupe:UnSpectate()
						v.playerLassoedDupe:Spawn()
						v.playerLassoedDupe:SetPos(v.LassoRagdoll:GetPos())
						v.LassoRagdoll:Remove()
					end
				end
				v.playerLassoedDupe.lassoedByPlayer = nil
				v.playerLassoedDupe.canLassoSpawn = false
				v.playerLassoedDupe = {}
				v.LassoRagdoll = nil 
				v.ragdollType = nil
			end
		end
	end
end)

function lassoNoSpawn(ply)
	if ply.canLassoSpawn == true then
		return false
	end
end

hook.Add( "PlayerSpawnObject", "lassoShouldBeSpawn", lassoNoSpawn ) //imma be honest i took this from ulib 11923207a
hook.Add( "PlayerSpawnEffect", "lassoShouldBeSpawn", lassoNoSpawn )
hook.Add( "PlayerSpawnProp", "lassoShouldBeSpawn", lassoNoSpawn )
hook.Add( "PlayerSpawnNPC", "lassoShouldBeSpawn", lassoNoSpawn )
hook.Add( "PlayerSpawnVehicle", "lassoShouldBeSpawn", lassoNoSpawn )
hook.Add( "PlayerSpawnRagdoll", "lassoShouldBeSpawn", lassoNoSpawn )
hook.Add( "PlayerSpawnSENT", "lassoShouldBeSpawn", lassoNoSpawn )
hook.Add( "PlayerGiveSWEP", "lassoShouldBeSpawn", lassoNoSpawn )

//Ok its the hud part

if CLIENT then

	hook.Add( "HUDPaint", "HudPaintLassoMod", function()
		if LocalPlayer().lassoState == true then // i dont want to do this but i also dont want to make another variable. Its already being set at the right times. 11923250a
			draw.RoundedBox(4, ScrW()/2.37, ScrH()/1.05, ScrW()/5.12, ScrH()/24, Color(255, 48, 48, 255))
			draw.RoundedBox(4, ScrW()/2.1, ScrH()/1.1, ScrW()/11.64, ScrH()/36, Color(65, 65, 65, 255))

			--Layer: 2 uhm i used hud painter addon thing made by uhmmm hol up... exho its called hud designer its pretty sick check it out. it helped me it can help you. Brought to you byhud designer. (Making it off center since 1962) 11923300a
			-- i ended up making some of my own code anways eh also gm 119231012a
			draw.RoundedBox(4, ScrW()/2.37, ScrH()/1.05, ScrW() * 0.196 * (LocalPlayer().lassoStruggleNum / 3000), ScrH()/24, Color(50, 169, 255, 255)) //5.11 max 8.11
			draw.DrawText("Struggle Meter", "CloseCaption_Normal", ScrW()/2.02, ScrH()/1.09, Color(223, 223, 223, 255))
		end
	end )
end

hook.Add( "PopulateToolMenu", "lassoModSwepSettingsMenu", function()
	spawnmenu.AddToolMenuOption( "Utilities", "Lasso Swep", "LassoSwepSettings", "#Lasso Swep Settings", "", "", function( panel )
	panel:ControlHelp("")
	panel:ControlHelp("Client Settings")
	panel:AddControl( "Numpad", { Label = "Lasso Struggle", Command = "lassoSwepKeyBind" } )
	panel:ControlHelp("")
	--panel:ControlHelp("Server Settings")
	--panel:AddControl("Slider", { Label = "Lasso Struggle Times", Command = "lassoSwepStruggleTimes", Min = 1, Max = 10000 }) nope didnt work for some reason

	end )
end)