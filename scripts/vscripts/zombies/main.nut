/*
	Zombies Gamemode v2.0
*/
printl("New Script!")

path <- "zombies/"

function Precache(){
	printl("Precache!")
	PrecacheSounds()
	IncludeScript(path + "utils.nut")
	IncludeScript(path + "entity_manager.nut")
	if(ScriptGetGameType() != 3){//Custom
		SendToConsole("sv_autoexec_mapname_cfg 1; game_type 3; changelevel " + GetMapName())
		return
	}
	IncludeScript(path + "player_manager.nut")
	IncludeScript(path + "event_logic.nut")
	local pSavedData = Entities.FindByClassname(null, "info_node") //We save the weapon's data through an entity that does not get deleted.
	try{
		local pScope = pSavedData.GetScriptScope()
		pWeaponMgr <- pScope.pWeaponMgr
		pPowerupMgr <- pScope.pPowerupMgr
		TellDev("Loaded an existing entity!")
	}
	catch(e){
		TellDev("Need to create an entity!")
		pSavedData = Entities.CreateByClassname("info_node")
		pSavedData.ValidateScriptScope()
		local pScope = pSavedData.GetScriptScope()
		foreach(key, val in pScope){
			printl(key + " : " + val)
		}

		pScope.pWeaponMgr <- {}
		pScope.pPowerupMgr <- {}

		IncludeScript(path + "weapons_manager.nut", pScope.pWeaponMgr) //Turn the entity's script scope into the weapon manager.
		IncludeScript(path + "powerup_manager.nut", pScope.pPowerupMgr) //Add the powerup manager to the entity's script scope.

		pWeaponMgr <- pScope.pWeaponMgr
		pPowerupMgr <- pScope.pPowerupMgr
	}
	IncludeScript(path + "wallbuy_manager.nut")
	IncludeScript(path + "case_manager.nut")
	IncludeScript(path + "wave_manager.nut")
	IncludeScript(path + "powerup_manager.nut")
}

function OnPostSpawn(){
	TellDev("Post Spawn!")
	//SendToConsoleServer("bot_quota 10")
	ValidatePlayerAccounts()

	//ListWeapons()
	//TellDev("rWeapon's length:" + rWeapons.len())
	//ParseName("wallbuy_weapon_hkp2000")
	ServerCommand("bot_join_team ct")
	ServerCommand("bot_quota " + BOT_MAX)
	ServerCommand("bot_knives_only 1")
	ServerCommand("mp_respawn_on_death_ct 1")

	self.ConnectOutput("OnUser1", "StartGame")
	self.ConnectOutput("OnUser2", "PauseWave")
	self.ConnectOutput("OnUser3", "ResumeWave")
}

function Think(){
	//As much as I fucking hate relying on a think method, it's badly needed!
	//This should only update 5 times a second.
	try{
		DisplayPoints()
		PowerupThink()
		WaveThink()
		CaseThink()
	}
	catch(e){
		TellDev(e)
	}

	return 0.2
}

function PrecacheSounds(){
	self.PrecacheScriptSound("UIPanorama.container_weapon_fall")
	self.PrecacheScriptSound("UIPanorama.container_weapon_open")
	self.PrecacheScriptSound("UIPanorama.container_weapon_purchaseKey")
	self.PrecacheScriptSound("UIPanorama.inventory_new_item")
	self.PrecacheScriptSound("UI.ArmsRace.Demoted")
	self.PrecacheScriptSound("Survival.BeaconGlobal")
	self.PrecacheScriptSound("UI.CoinLevelUp")
}

function ValidatePlayerAccounts(){
	TellDev("Validating Accounts!")
	local pPlayer = null
	local rQueue = []

	while(pPlayer = FindNextPlayerOrBot(pPlayer)){
		local pScope = pPlayer.GetScriptScope()
		try{
			if(pScope.ClassInstance){
				AddExistingPlayer(pScope.ClassInstance)
				continue
			}
		}
		catch(e){
			TellDev(e)
			rQueue.append(pPlayer)
		}
	}

	foreach(idx, pPlayer in rQueue){
		TellDev("Validate Player: " + pPlayer)
		EntFireByHandle(pConnectProxy, "GenerateGameEvent", "", 0.05 * idx, pPlayer, pPlayer)
	}
	printl("Created accounts for " + rQueue.len() + " players!")
}
