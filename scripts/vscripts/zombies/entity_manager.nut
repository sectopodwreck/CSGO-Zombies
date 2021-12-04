/*
	Zombies Gamemode v2.0

	Entity manager.

	Initalizes entities.
*/



::GameEntity <- class{
	/*
		Creates an entity with given keyvalues.

		WARNING: Does not work on every entity. :(

		dictKeyValues should be
		{
			targetname = "poo poo",
			origin = Vector(Yada, Yada, Yada)
		}
		MAKE SURE YOU USE VECTOR, NO A TUPLE!
	*/

	pEnt = null

	constructor(strClass, dictKeyValues = null){
		pEnt = Entities.CreateByClassname(strClass)
		if(dictKeyValues){
			InitKeyValues(dictKeyValues)
		}
	}

	function GetEnt(){
		//Returns the entity when this class is -> called()
		return pEnt
	}

	function InitKeyValues(dictKeyValues){
		foreach(key, value in dictKeyValues){
			local strValueType = type(value)
			if(strValueType == "integer"){
				pEnt.__KeyValueFromInt(key, value)
				continue
			}
			else if(strValueType == "float"){
				pEnt.__KeyValueFromFloat(key, value)
				continue
			}
			else if(strValueType == "string"){
				pEnt.__KeyValueFromString(key, value)
				continue
			}
			else if(strValueType == "instance"){
				pEnt.__KeyValueFromVector(key, value)
				continue
			}
		}
	}

	function EditInteger(strKey, intValue){
		//Change the value of an int key.
		pEnt.__KeyValueFromInt(strKey, intValue)
	}

	function EditFloat(strKey, flValue){
		//Change the value of a float key.
		pEnt.__KeyValueFromFloat(strKey, flValue)
	}

	function EditString(strKey, strValue){
		//Change the value of a string key.
		pEnt.__KeyValueFromString(strKey, strValue)
	}

	function EditVector(strKey, vectValue){
		pEnt.__KeyValueFromVector(strKey, vectValue)
	}
}

::GameProp <-class extends GameEntity{
	/*
		Creates a prop.

		Extended from GameEntity, as there is a different method for
		creating props which has a different mehtod.
	*/

	pEnt = null

	constructor(strClass, vectOrigin, strMdl, intAnimation = 0, dictKeyValues = null){
		pEnt = CreateProp(strClass, vectOrigin, strMdl, intAnimation)
		if(dictKeyValues){
			InitKeyValues(dictKeyValues)
		}
	}
}

function InitScript(){
	::pClientCommand <- GameEntity("point_clientcommand")
	::pServerCommand <- GameEntity("point_servercommand")
	::pPlayerEquip <- GameEntity("game_player_equip", {spawnflags = 5})

	//Allow for pPlayerEquip to clean up weapons which spawn more than one. (taser)
	/*
	pPlayerEquip.ValidateScriptScope()
	local pEquipScope = pPlayerEquip.GetScriptScope()
	pEquipScope.OnUserOne <- function(){

		//Fires when FireUser1 is called.

		//Activator should be the player.
		//Caller should be the weapon entity.
	}
	*/


	/*
	Disabled while I test out player personal game_text

	::pGameText <- GameEntity("game_text", {
		color = Vector(245, 56, 10),
		channel = 3,
		effect = 2,
		holdtime = 5,
		y = 0.92,
		x = 0.23,
		fadein = 0.5
	})
	*/
	pPlayerConnect <- EntityGroup[0]
	pPlayerDisconnect <- EntityGroup[1]
	pConnectProxy <- EntityGroup[2]
	pPlayerDeath <- EntityGroup[3]
	pPlayerHurt <- EntityGroup[4]

	InitEventEntities()

	TellDev("Entity Manager Initalized!")
}

function InitEventEntities(){
	foreach(idx, pEnt in EntityGroup){
	local pScope  = pEnt.GetScriptScope()

	pScope.pScript <- this
	}

	local pScope = null

	pScope = pPlayerConnect.GetScriptScope()
	pScope.AddPlayer <- function(){
		foreach(key, val in event_data){
			printl(key + " : " + val)
		}
		pScript.AddPlayer(event_data)
	}

	pScope = pPlayerDisconnect.GetScriptScope()
	pScope.RemovePlayer <- function(){
		pScript.RemovePlayer(event_data)
	}

	pScope = pPlayerDeath.GetScriptScope()
	pScope.PlayerDeath <- function(){
		pScript.PlayerDeath(event_data)
	}

	pScope = pPlayerHurt.GetScriptScope()
	pScope.PlayerHurt <- function(){
		pScript.PlayerHurt(event_data)
	}
}

::ClientCommand <- function(strCommand, pPlayer = null, flDelay = 0){
	//pPlayer allows you to make changes to a specific player.
	EntFireByHandle(pClientCommand.GetEnt(), "command", strCommand, flDelay, pPlayer, pPlayer)
}

::ServerCommand <- function(strCommand, flDelay = 0){
	//Allows for server convars to be used.
	EntFireByHandle(pServerCommand.GetEnt(), "command", strCommand, flDelay, null, null)
}

::EquipWeapon <- function(pWeapon, pPlayer){
	//pWeapon should be a weapon instance!
	local strWeapon = pWeapon.GetEntName()
	local intWeaponTeam = pWeapon.GetTeam()
	local intPlayerTeam = pPlayer.GetTeam()

	if(intPlayerTeam != intWeaponTeam){
		if(intWeaponTeam == 1){
			//If the weapon is for both teams, chose a random team. (Some players have different skins equipped for the same weapon.)
			intWeaponTeam = RandomInt(2,3)
		}
		EntFireByHandle(pPlayer, "AddOutput", "teamnumber " + intWeaponTeam, 0, null, null)
		GiveWeapon(strWeapon, pPlayer)
		EntFireByHandle(pPlayer, "AddOutput", "teamnumber " + intPlayerTeam, 0, null, null)
		return
	}
	GiveWeapon(strWeapon, pPlayer)
	//TellDev(Entities.FindByClassname(null, strWeapon))

}

::GiveWeapon <- function(strWeapon, pPlayer){
	//A more primitive version of EquipWeapon for more flexable purposes.
	EntFireByHandle(pPlayerEquip.GetEnt(), "TriggerForActivatedPlayer", strWeapon, 0, pPlayer, pPlayer)
}

::ShowHint <- function(strMessage, pPlayer){
	local pHudHint = Entities.CreateByClassname("env_hudhint")

	EntFireByHandle(pHudHint, "AddOutput", "message " + strMessage, 0, null, null)
	EntFireByHandle(pHudHint, "ShowHudHint", "", 0.01, pPlayer, pPlayer)
	EntFireByHandle(pHudHint, "kill", "", 0.02, null, null)
}

::MakeGameText <- function (dictKeyValues = null){
	//Creates a game_text instance, and returns a GameEntity pointer.

	if(!dictKeyValues){
		//Defaults
		dictKeyValues = {
			color = Vector(245, 56, 10),
			channel = 3,
			effect = 2,
			holdtime = 5,
			y = 0.92,
			x = 0.23,
			fadein = 0.5
		}
	}

	local pEnt = GameEntity("game_text", dictKeyValues)

	return pEnt
}

InitScript()
