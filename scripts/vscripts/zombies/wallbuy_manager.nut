/*
	Zombies Gamemode v2.0

	Wall Buy manager.

	Initalizes wall buys to function properly.
	The goal is to make placing wall buys as simple as possible.
*/

/*
	tartgetname naming rules.



	Weapons:
		wallbuy_weapon_hkp2000 500

		Always start with wallbuy, followed by the weapon's name.
		If you want to change the price of the item, add a space, and put the price.

	Doors/debris:
		doorbuy_1000 The Catacombs

		Always start with doorbuy, followed by the unlock price, and name.
		Be sure to add a space before putting the name!

		When the door is bought:
			It will FireUser1 on the button if it succeeded.
			It will FireUser2 on the button if it failed.

	General:
		[trigger_multiple] generalbuy_250 This text will show up when the player walks in the trigger.
		[func_button] generalbuy_250 This text will show when the player succeeded in purchasing.

		When the button is bought:
			It will FireUser1 on the button if it succeeded.
			It will FireUser2 on the button if it failed.

		General buys can also be a negative number or zero, it will display accordingly.

	You'll have to do this for both the trigger and button. The model can be ignored.
*/

function InitScript(){
	local rTriggers = FindTriggers()
	local rButtons = FindButtons()

	local rWeaponTriggers = rTriggers[0]
	local rDoorTriggers = rTriggers[1]
	local rGeneralTriggers = rTriggers[2]

	local rWeaponButtons = rButtons[0]
	local rDoorButtons = rButtons[1]
	local rGeneralButtons = rButtons[2]

	TellDev("rTriggers: " + rTriggers.len() + "\nrButtons: " + rButtons.len())

	//Weapons
	foreach(idx, pTrigger in rWeaponTriggers){
		InitWeaponTrigger(pTrigger)
	}
	foreach(idx, pButton in rWeaponButtons){
		InitWeaponButton(pButton)
	}

	//Doors/debris
	foreach(idx, pTrigger in rDoorTriggers){
		InitDoorTrigger(pTrigger)
	}
	foreach(idx, pButton in rDoorButtons){
		InitDoorButton(pButton)
	}

	//General
	foreach(idx, pTrigger in rGeneralTriggers){
		InitGeneralTrigger(pTrigger)
	}
	foreach(idx, pButton in rGeneralButtons){
		InitGeneralButton(pButton)
	}

	TellDev("Wallbuys are now functional!")
}

function FindTriggers(){
	//Returns array of trigger_multiple entities.
	local rWeaponTriggers = []
	local rDoorTriggers = []
	local rGeneralTriggers = []

	local pTrigger = null
	while(pTrigger = Entities.FindByClassname(pTrigger, "trigger_multiple")){
		local strName = pTrigger.GetName()
		if(strName.find("wallbuy") == 0){
			//Weapon Buy
			rWeaponTriggers.append(pTrigger)
			continue
		}
		if(strName.find("doorbuy") == 0){
			rDoorTriggers.append(pTrigger)
			continue
		}
		if(strName.find("generalbuy") == 0){
			rGeneralTriggers.append(pTrigger)
			continue
		}
	}
	return [rWeaponTriggers, rDoorTriggers, rGeneralTriggers]
}

function FindButtons(){
	//Returns array of button entites.
	local rWeaponButtons = []
	local rDoorButtons = []
	local rGeneralButtons = []

	local pButton = null
	while(pButton = Entities.FindByClassname(pButton, "func_button")){
		local strName = pButton.GetName()
		if(strName.find("wallbuy") == 0){
			//Weapon buy
			rWeaponButtons.append(pButton)
			continue
		}
		if(strName.find("doorbuy") == 0){
			//Door Buy
			rDoorButtons.append(pButton)
			continue
		}
		if(strName.find("generalbuy") == 0){
			//General Buy
			rGeneralButtons.append(pButton)
			continue
		}
	}
	return [rWeaponButtons, rDoorButtons, rGeneralButtons]
}

function ParseWeaponName(strName){
	//strName: The targetname of the entity.
	//returns a tuple with the weapon data and price.
	local intPriceIdx = strName.find(" ")

	local pWeapon = null
	local intPrice = null
	local intPriceAmmo = null

	if(intPriceIdx){
		TellDev("Custom price!")
		intPrice = strName.slice(intPriceIdx + 1).tointeger()
		//Ammo should be 1/2 price, floored to the nearest 10's.
		intPriceAmmo = 10 * floor(intPrice / 20)
		strName = strName.slice(8, intPriceIdx)
		pWeapon = FindWeaponByClassname(strName)
	}
	else{
		strName = strName.slice(8)
		pWeapon = FindWeaponByClassname(strName)
		intPrice = pWeapon.GetPrice()
		intPriceAmmo = pWeapon.GetAmmoPrice()
	}

	TellDev(strName + ", Costs: " + intPrice)

	return [pWeapon, intPrice, intPriceAmmo]
}

function ParseDoorName(strName){
	//strName: The targetname of the entity.
	//Returns an array with the price and door's name (if apliciable)
	local intIgnoreIdx = strName.find("~")

	local strMessage = null
	local intPrice = null

	if(intIgnoreIdx){
		local intSpliceIdx = 1
		if(strName[intIgnoreIdx - 1] == " "){
			intSpliceIdx++
		}
		strName = strName.slice(0, intIgnoreIdx - intSpliceIdx)
	}

	local intNameIdx = strName.find(" ")
	TellDev(strName)

	if(intNameIdx){
		local intPrice = strName.slice(8, intNameIdx).tointeger()
		local strMessage = "Unlock " + strName.slice(intNameIdx + 1) + "\n" + "Costs " + intPrice

		return [intPrice, strMessage]
	}
	strMessage = "Clear Debris\nCosts " + intPrice

	local intPrice = strName.slice(8).tointeger()

	return [intPrice, strMessage]
}

function ParseGeneralName(strName){
	//strName: The targetname of the entity.
	//Returns an array with the price and message.
	local intMessageIdx = strName.find(" ")
	local intIgnoreIdx = strName.find("~")

	local strMessage = ""
	local intPrice = null

	if(intIgnoreIdx){
		local intSpliceIdx = 1
		if(strName[intIgnoreIdx - 1] == " "){
			intSpliceIdx++
		}
		strName = strName.slice(0, intIgnoreIdx - intSpliceIdx)
	}

	if(intMessageIdx){
		strMessage = strName.slice(intMessageIdx + 1)
		intPrice = strName.slice(11, intMessageIdx).tointeger()
	}
	else{
		intPrice = strName.slice(11).tointeger()
	}

	return [intPrice, strMessage]
}

function InitWeaponTrigger(pTrigger){
	//Set up trigger to tell the player how much the weapon is.

	pTrigger.ValidateScriptScope()
	local pScope = pTrigger.GetScriptScope()
	local rParsedInfo = ParseWeaponName(pTrigger.GetName())//[0]: Weapon instance, [1]: price

	pScope.pWeapon <- rParsedInfo[0]
	pScope.intPrice <- rParsedInfo[1]
	pScope.intPriceAmmo <- rParsedInfo[2]
	pScope.OnStartTouch <- function(){
		//Fired when a player walks into the trigger.

		if(activator.GetTeam() != 2){
			return
		}

		//Check to see if the player already owns the weapon.
		local pPlayerWeapon = Entities.FindByClassnameNearest(pWeapon.GetEntName(), activator.GetOrigin(), 64)
		if(pPlayerWeapon && pPlayerWeapon.GetOwner() == activator){
			//Player owns weapon.
			ShowHint(pWeapon.GetName() + "\nAmmo: " + intPriceAmmo, activator)
			return
		}

		ShowHint(pWeapon.GetName() + "\nCosts " + intPrice, activator)
	}

	pTrigger.ConnectOutput("OnStartTouch", "OnStartTouch")
}

function InitWeaponButton(pButton){
	//Set up button to allow player to purchase the weapon.

	local vectOrigin = pButton.GetOrigin()

	local pModel = Entities.FindByClassnameWithin(null, "prop_dynamic_override", vectOrigin, 16)

	if(!pModel){
		pModel = Entities.FindByClassnameWithin(null, "prop_dynamic", vectOrigin, 16)
		if(!pModel){
			TellDev("\n\nCouldn't find model!\n\n")
			return
		}
	}

	pButton.ValidateScriptScope()
	local pScope = pButton.GetScriptScope()
	local rParsedInfo = ParseWeaponName(pButton.GetName())

	pModel.SetModel(rParsedInfo[0].GetMdlName())

	pScope.pWeapon <- rParsedInfo[0]
	pScope.intPrice <- rParsedInfo[1]
	pScope.intPriceAmmo <- rParsedInfo[2]
	pScope.OnPressed <- function(){
		//Fired when a player presses the button.
		TellDev("Pressed!")

		if(activator.GetTeam() != 2){
			return
		}

		local pPlayerInstance = null

		try{
			pPlayerInstance = activator.GetScriptScope().GetInstance() //Returns the class instance of the player.
		}
		catch(e){
			TellDev("A player with no script scope tried to buy a weapon!")
			return
		}

		local bReloading = false

		//Check to see if the player is buying ammo instead
		local pPlayerWeapon = Entities.FindByClassnameNearest(pWeapon.GetEntName(), activator.GetOrigin(), 64)
		if(pPlayerWeapon && pPlayerWeapon.GetOwner() == activator){
			//Player owns weapon.
			bReloading = true
		}

		if(bReloading ? pPlayerInstance - intPriceAmmo : pPlayerInstance - intPrice){
			EquipWeapon(pWeapon, activator)
			if(bReloading){
				ShowHint(pWeapon.GetName() + " rearmed!", activator)
			}
			else{
				ShowHint(pWeapon.GetName() + " purchased!", activator)
			}
			if(RandomFloat(0, 1) < 0.1){
				pPlayerInstance.Command("cheer")
			}
			return
		}
		TellDev("Can't buy!")
		ShowHint("Not enough points!", activator)
	}

	pButton.ConnectOutput("OnPressed", "OnPressed")

	TellDev("Button Finished")
}

function InitDoorTrigger(pTrigger){
	//Sets up a trigger to tell the price of a door.

	pTrigger.ValidateScriptScope()
	local pScope = pTrigger.GetScriptScope()
	local rDoorInfo = ParseDoorName(pTrigger.GetName())

	pScope.intPrice <- rDoorInfo[0]
	pScope.strMessage <- rDoorInfo[1]

	pScope.OnStartTouch <- function(){
		if(activator.GetTeam() != 2){
			return
		}
		ShowHint(strMessage, activator)
	}

	pTrigger.ConnectOutput("OnStartTouch", "OnStartTouch")
}

function InitDoorButton(pButton){
	//Sets up a button to allow for the purchase of the door.

	pButton.ValidateScriptScope()
	local pScope = pButton.GetScriptScope()
	local rDoorInfo = ParseDoorName(pButton.GetName())

	pScope.intPrice <- rDoorInfo[0]

	pScope.OnPressed <- function(){
		if(activator.GetTeam() != 2){
			return
		}

		local pPlayerInstance = null

		try{
			pPlayerInstance = activator.GetScriptScope().GetInstance() //Returns the class instance of the player.
		}
		catch(e){
			TellDev("A player with no script scope tried to buy a weapon!")
			return
		}

		if(pPlayerInstance - intPrice){
			ShowHint("Unlocked!", activator)
			EntFireByHandle(self, "FireUser1", "", 0, null, null)
			EntFireByHandle(self, "kill", "", 0.1, null, null)
			return
		}
		ShowHint("Not enough points!", activator)
		EntFireByHandle(self, "FireUser2", "", 0, null, null)
		return
	}

	pButton.ConnectOutput("OnPressed", "OnPressed")
}

function InitGeneralTrigger(pTrigger){
	//Sets up a trigger for a general purchase.

	pTrigger.ValidateScriptScope()
	local pScope = pTrigger.GetScriptScope()
	local rGeneralInfo = ParseGeneralName(pTrigger.GetName())

	pScope.intPrice <- rGeneralInfo[0]
	pScope.strMessage <- rGeneralInfo[1]

	if(pScope.intPrice > 0){
		pScope.strMessage += "\nCosts " + pScope.intPrice
	}
	else if(pScope.intPrice < 0){
		pScope.strMessage += "\nRecieve " + (pScope.intPrice * -1)
	}

	pScope.OnStartTouch <- function(){
		if(activator.GetTeam() != 2){
			return
		}

		ShowHint(strMessage, activator)
	}

	pTrigger.ConnectOutput("OnStartTouch", "OnStartTouch")
}

function InitGeneralButton(pButton){
	//Sets up a button for a general purchase

	pButton.ValidateScriptScope()
	local pScope = pButton.GetScriptScope()
	local rGeneralInfo = ParseGeneralName(pButton.GetName())

	pScope.intPrice <- rGeneralInfo[0]
	pScope.strMessage <- rGeneralInfo[1]

	pScope.OnPressed <- function(){
		if(activator.GetTeam() != 2){
			return
		}

		local pPlayerInstance = null

		try{
			pPlayerInstance = activator.GetScriptScope().GetInstance() //Returns the class instance of the player.
		}
		catch(e){
			TellDev("A player with no script scope tried to buy a weapon!")
			return
		}

		if(pPlayerInstance - intPrice){
			if(strMessage != ""){
				ShowHint(strMessage, activator)
			}
			EntFireByHandle(self, "FireUser1", "", 0, null, null)
			return
		}
		ShowHint("Not enough points!", activator)
		EntFireByHandle(self, "FireUser2", "", 0, null, null)
	}

	pButton.ConnectOutput("OnPressed", "OnPressed")
}
InitScript()
