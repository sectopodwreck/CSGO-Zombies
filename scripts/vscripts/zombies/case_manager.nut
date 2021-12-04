/*
	Zombies Gamemode v2.0

	Mystery case manager.

	Initalizes mystery cases to function properly.
	The goal is to make cases "place and forget".
*/

function InitScript(){
	::pActiveCase <- null
	local rRawCases = GetCases()
	local pCase = null

	foreach(idx, pButton in rRawCases){
		pCase = InitCase(pButton)
	}
	local rCases = GameCase.rOtherCases

	SetActiveCase(rCases[RandomInt(0, rCases.len() - 1)])

	TellDev(rRawCases.len().tostring() + " cases are now functional!")
}

function GetCases(){
	//Returns Array
	//Finds every instance of func_buttons with the targetname "randombox_main"
	local rRawCases = []
	local pCase = null

	while(pCase = Entities.FindByName(pCase, "randombox_main")){
		if(pCase.GetClassname() != "func_button"){
			//We want to make sure it's a button.
			continue
		}
		rRawCases.append(pCase)
	}

	return rRawCases
}

function CaseThink(){
	//Fired every think.
	try{
		pActiveCase.Think()
	}
	catch(e){
		//No cases on map.
	}
}

function InitCase(pButton){
	//pButton: Pointer to a func_button instance.
	//Finds all of the entities linked to the case and creates
	//a GameCase instance!

	local pTrigger = null
	local pCase = null
	local pWeapon = null
	local pExplode = null
	local vectPos = pButton.GetOrigin()
	local intDist = 24

	pTrigger = Entities.FindByNameWithin(null, "randombox_trigger", vectPos, intDist)
	pCase = Entities.FindByNameWithin(null, "randombox_case", vectPos, intDist)
	pWeapon = Entities.FindByNameWithin(null, "randombox_weapon", vectPos, intDist)
	pExplode = Entities.FindByNameWithin(null, "randombox_explosion", vectPos, intDist)

	if(pTrigger && pCase && pWeapon && pExplode){
		//All of these entities have been found!
		return GameCase(pButton, pTrigger, pCase, pWeapon, pExplode)
	}
	TellDev("Couldn't find every entity!")
	TellDev("pTrigger: " + pTrigger)
	TellDev("pCase: " + pCase)
	TellDev("pWeapon: " + pWeapon)
	TellDev("pExplode: " + pExplode)
}

::SetActiveCase <- function(pCase){
	//pCase: GameCase instance.
	pCase.EnableCase()
	::pActiveCase = pCase.weakref()
}

class GameCase{
	/*
		A button is given this class.
		It houses everything needed to turn it, and it's surrounding entities into
		a mystery box!
	*/

	intPrice = 950
	flMoveChance = 0.1
	rOtherCases = [] //Store the other case instances in here in order to keep the script scope from preserving it on round reset hopefully.
	rCaseMdls = ["armsdeal1", "armsdeal2", "armsdeal3", "bloodhound", "bravo", "breakout", "chroma", "chroma2", "chroma3", "clutch", "community_22", "community_23", "community_24", "community_25", "community_26", "dangerzone", "gamma", "gamma2", "glove", "horizon", "huntsman", "hydra", "phoenix", "revolver", "shadow", "spectrum", "spectrum2", "vanguard", "wildfire", "winteroffensive"]

	pButton = null
	pTrigger = null
	pCase = null
	pWeapon = null
	pExplode = null
	intTimesUsed = 0 //Affects the chance for the box moving.
	flNextInteration = 0 //Used when the case it being unboxed, keeps the player from instantly grabbing the weapon.
	flTimeout = 0 //Case resets after Time() passes this number.
	bActive = false //Is this case active.

	intTimeoutDelay = 10 //How many seconds before the case resets.

	pBuyer = null //Used to determine who bought the case, null if it's not occupied.
	pBuyerInstance = null //The Player()'s class instance.
	pSelectedWeapon = null //Points to a Weapon class instance, null after the item has been recieved/timedout.

	constructor(button, trigger, caseprop, weaponprop, explode){
		pButton = button
		pTrigger = trigger
		pCase = caseprop
		pWeapon = weaponprop
		pExplode = explode

		intTimesUsed = 0
		flNextInteration = 0
		flTimeout = 0
		bActive = false
		pBuyer = null
		pBuyerInstance = null
		pSelectedWeapon = null

		rOtherCases.append(this)
		InitEntities()
		DisableCase()
	}

	function InitEntities(){
		//Gives the button and trigger their script scope.
		//Make sure the functions POINT to this class instance specifcally.

		//pCase has a script scope to fire after unbox.

		pButton.ValidateScriptScope()
		pTrigger.ValidateScriptScope()
		pCase.ValidateScriptScope()

		local pButtonScope = pButton.GetScriptScope()
		pButtonScope.CaseInstance <- this
		pButtonScope.OnPressed <- function(){
			//Fires ButtonPressed()
			CaseInstance.ButtonPressed(activator)
		}

		local pTriggerScope = pTrigger.GetScriptScope()
		pTriggerScope.CaseInstance <- this
		pTriggerScope.OnStartTouch <- function(){
			//Fires TriggerEntered()
			CaseInstance.TriggerEntered(activator)
		}

		local pCaseScope = pCase.GetScriptScope()
		pCaseScope.CaseInstance <- this
		pCaseScope.OnUser1 <- function(){
			CaseInstance.Unboxed()
		}

		pButton.ConnectOutput("OnPressed", "OnPressed")
		pTrigger.ConnectOutput("OnStartTouch", "OnStartTouch")
		pCase.ConnectOutput("OnUser1", "OnUser1")
	}

	function ButtonPressed(activator){
		//activator: Entity Instance Pointer.
		//Player has hit use on the mystery box's button.

		if(activator.GetTeam() != 2){//Only T's can use the box!
			return
		}

		local pPlayerInstance = null

		try{
			//Get the player's Player() instance.
			pPlayerInstance = activator.GetScriptScope().GetInstance()
		}
		catch(e){
			//Activator does not have a player instance.
			return
		}

		if(!pBuyer){
			//The case is unoccupied.

			if(Time() < flNextInteration){
				pPlayerInstance.TellPlayer("Please wait a moment before unboxing.")
				return
			}

			if(pPlayerInstance - intPrice){
				pBuyer = activator
				if(rOtherCases.len() > 1 && (intTimesUsed * flMoveChance) > RandomFloat(0.1, 1)){
					pSelectedWeapon = null //Move box.
				}
				else{
					TellDev("Selecting a weapon!")
					pSelectedWeapon = GetRandomWeapon(["weapon_shield", "weapon_taser", "weapon_breachcharge"]) //These weapons spawn more than one for some reason.
				}
				flNextInteration = Time() + 2.1 //Time it takes for the weapon to unbox.
				flTimeout = Time() + intTimeoutDelay
				pPlayerInstance.TellPlayer("Unboxing!")
				intTimesUsed += 1

				pBuyer = activator
				pBuyerInstance = pPlayerInstance

				DoUnbox()
				return
			}
			pPlayerInstance.TellPlayer("Not enough points!")
			return
		}
		//The case is occupied by someone.

		if(activator != pBuyer){
			pPlayerInstance.TellPlayer("The case is being used right now.\nTry again later.")
			return
		}

		if(Time() < flNextInteration){
			pPlayerInstance.TellPlayer("The case is still unboxing.\nWait a bit longer.")
			return
		}

		//Player is the buyer, and it's past the next interaction time.
		EquipWeapon(pSelectedWeapon, pBuyer)
		if(RandomFloat(0, 1) < 0.2){
			pPlayerInstance.Command("cheer")
		}
		ResetCase()
		return
	}

	function TriggerEntered(activator){
		//activator: Entity Instance Pointer.
		//Player has entered the mystery box's trigger.

		if(activator.GetTeam() != 2){//Only T's should trigger this!
			return
		}

		local pPlayerInstance = null

		try{
			//Get the player's Player() instance.
			pPlayerInstance = activator.GetScriptScope().GetInstance()
		}
		catch(e){
			//Activator does not have a player instance.
			return
		}

		if(!pBuyer){
			//The case is unoccupied.
			pPlayerInstance.TellPlayer("Get a random weapon!\nCosts: " + intPrice)
			return
		}
		//The case is occupied.

		if(activator != pBuyer){
			//Player isn't the buyer, do nothing.
			return
		}

		if(Time() < flNextInteration){
			pPlayerInstance.TellPlayer("Unboxing!")
			return
		}

		//Player is buyer and it's past the next interaction time.
		pPlayerInstance.TellPlayer("Come and pick up your " + pSelectedWeapon.GetName() + "!")
		return
	}

	function Think(){
		//Fired every Think().
		if(pBuyer && (Time() >= flTimeout)){
			// Has the player taken too long to take his weapon?
			local pScope = null
			try{
				pScope = pBuyer.GetScriptScope().ClassInstance
			}
			catch(e){
				//Doesn't have an instance!
				TellDev("No instance!")
				return
			}
			pScope.TellPlayer("Your new " + pSelectedWeapon.GetName() + " has vanished!")
			ResetCase()
		}
	}

	function EnableCase(){
		//Allows for the case to be used.
		bActive = true
		EntFireByHandle(pButton, "Unlock", "", 0, null, null)
		EntFireByHandle(pTrigger, "Enable", "", 0, null, null)
		ResetCase()
	}

	function DisableCase(){
		//Disables the button and trigger.
		bActive = false
		EntFireByHandle(pButton, "Lock", "", 0, null, null)
		EntFireByHandle(pTrigger, "Disable", "", 0, null, null)
		ResetCase()
	}

	function Unboxed(){
		//Fired when the case is opened.

		EntFireByHandle(pCase, "Disable", "", 0, null, null)
		DoExplosion()

		if(!pSelectedWeapon){
			//The weapon was null, move the case.
			pCase.EmitSound("UI.ArmsRace.Demoted")
			pBuyerInstance.TellPlayer("Unlucky!\nThe case has moved!")
			pBuyerInstance + intPrice
			intTimesUsed = 0
			DisableCase()
			MoveCase()
			return
		}

		pCase.EmitSound("UIPanorama.inventory_new_item")
		pWeapon.SetModel(pSelectedWeapon.GetMdlName())
		EntFireByHandle(pWeapon, "Enable", "", 0, null, null)
	}

	function DoUnbox(){
		//Plays the animations/sounds for an unbox.
		//Only deals with cosmetic.

		EntFireByHandle(pCase, "SetAnimation", "open", 0, null, null)
		EntFireByHandle(pCase, "FireUser1", "", 2, null, null)
		pCase.EmitSound("UIPanorama.container_weapon_purchaseKey")
		pCase.EmitSound("UIPanorama.container_weapon_open")
	}

	function DoExplosion(flDelay = 0){
		//flDelay: how long of a delay there should be for the explosion.
		//Fires the env_explosion, and also FireUser1 to allow for custom effects.
		EntFireByHandle(pExplode, "Explode", "", flDelay, null, null)
		EntFireByHandle(pExplode, "FireUser1", "", flDelay, null, null)
	}

	function ResetCase(){
		//Resets the case to allow another player to open it.
		TellDev("Resetting case!")
		pBuyer = null
		pBuyerInstance = null
		pSelectedWeapon = null
		flTimeout = 0

		if(!bActive){
			//Case is disabled.
			EntFireByHandle(pCase, "Disable", "", 0, null, null)
			EntFireByHandle(pWeapon, "Disable", "", 0, null, null)
			return
		}
		EntFireByHandle(pWeapon, "Disable", "", 0, null, null)
		NewCase()
		flNextInteration = Time() + 2
	}

	function NewCase(){
		//Picks a new model for the case and drops it.
		TellDev("New Case!")
		pCase.SetModel(GetCaseMdl())

		EntFireByHandle(pCase, "Enable", "", 0, null, null)
		EntFireByHandle(pCase, "SetAnimation", "fall", 0, null, null)
		pCase.EmitSound("UIPanorama.container_weapon_fall")
		EntFireByHandle(pCase, "SetAnimation", "idle", 2, null, null)
	}

	function GetCaseMdl(){
		//Selects a new case model to use.
		local strSelectedCase = rCaseMdls[RandomInt(0, rCaseMdls.len() - 1)]

		return "models/props/crates/csgo_drop_crate_" + strSelectedCase + ".mdl"
	}

	function MoveCase(){
		//Selects a new case in the level to use.
		local rNewLocations = []
		foreach(idx, pOtherCase in rOtherCases){
			if(pOtherCase != this){
				rNewLocations.append(pOtherCase)
			}
		}

		local pNewLocation = rNewLocations[RandomInt(0, rNewLocations.len() - 1)]
		SetActiveCase(pNewLocation)
	}
}

InitScript()
