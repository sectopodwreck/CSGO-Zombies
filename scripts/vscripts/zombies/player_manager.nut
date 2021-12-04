/*
	Zombies Gamemode v2.0
	
	Entity manager.
	
	Houses player info and creates player accounts.
*/

class Player{
	strName = null
	intEntIdx = null
	intUserId = null
	intTeam = null
	pPlayer = null
	pScope = null
	pText = null //GameEntity, not pointer to actual entity!
	
	bIsBot = null
	bInPlay = null //ZOMBIES, Are they queued to spawn, or already in?
	
	intPoints = null
	
	constructor(event_data){
		strName = event_data.name
		intEntIdx = event_data.index + 1
		intUserId = event_data.userid
		pPlayer = FindPlayer()
		if(!pPlayer){
			//Player somehow disconnected before their entity appeared.
			//This instance will be garbage collected on round restart.
			return
		}
		
		InitScriptScope()
		if(event_data.networkid != "BOT"){
			TellDev("Found a player, creating a game_text!")
			bIsBot = false
			pText = MakeGameText()
		}
		else{
			bIsBot = true
			bInPlay = false
		}
		
		intPoints = 0
		intTeam = pPlayer.GetTeam()
		TellPlayer("Welcome " + GetName() + "!")
	}
	
	function InitScriptScope(){
		pPlayer.ValidateScriptScope()
		
		pScope = pPlayer.GetScriptScope()
		pScope.ClassInstance <- this
		
		pScope.GetUserId <- function(){
			return ClassInstance.GetUserId()
		}
		
		pScope.GetName <- function(){
			return ClassInstance.GetName()
		}
		
		pScope.GetInstance <- function(){
			return ClassInstance
		}
		
	}
	
	function FindPlayer(){
		//Finds the player by using intEntIdx
		local pEnt = Entities.First()
		while(pEnt.entindex() <= intEntIdx){
			//TellDev("Target index: " + intEntIdx + " Current index: " + pEnt.entindex())
			if(pEnt.entindex() == intEntIdx){
				print(pEnt.GetClassname())
				TellDev("Found player!")
				return pEnt
			}
			pEnt = FindNextPlayerOrBot(pEnt)
		}
		printl(pEnt.entindex())
		TellDev("Couldn't find player!")
		return null
	}
	
	function Command(strCommand, flDelay = 0){
		//Fires a clientcommand using this player as the activator.
		ClientCommand(strCommand, pPlayer, flDelay)
	}
	
	function ResetRound(){
		//Called when a new round starts.
		intPoints = 0
		
		if(!bIsBot){
			TellDev("Found a player, creating a game_text!")
			pText = MakeGameText()
		}
	}
	
	function _add(Points){
		intPoints += Points
		return
	}
	
	function Buy(Points){
		return this - Points
	}
	
	function _sub(Points){
		//Cheat
		if(GetDeveloperLevel() > 0){
			return true
		}
		if(intPoints >= Points){
			intPoints -= Points
			return true
		}
		return false
	}
	
	function TellPlayer(strMessage){
		ShowHint(strMessage, pPlayer)
	}
	
	//game_text methods
	
	function ShowPoints(){
		//Updates the amount of points the player owns, and displays it.
		EntFireByHandle(pText.GetEnt(), "AddOutput", "message " + GetPoints() + "\nRound " + WAVE.tostring(), 0, null, null)
		EntFireByHandle(pText.GetEnt(), "Display", "", 0.01, pPlayer, pPlayer) //Make sure to have a slight delay so the message can update!
	}
	
	//game_text methods

	function SetInPlay(){
		TellDev("Setting Into play!")
		bInPlay = true
	}

	function SetOutPlay(){
		TellDev("Setting out of play!")
		bInPlay = false
	}
	
	function GetName(){
		return strName
	}
	
	function GetTeam(){
		return GetEnt().GetTeam()
	}
	
	function GetEntIdx(){
		return intEntIdx
	}
	
	function GetUserId(){
		return intUserId
	}
	
	function GetEnt(){
		return pPlayer
	}
	
	function GetPoints(){
		return intPoints
	}
	
	function GetScriptScope(){
		return pScope
	}
	
	function IsValid(){
		//Used when a new player's userID's superseeding this player.
		try{
			return pPlayer.IsValid()
		}
		catch(e){
			return false
		}
	}

	function InPlay(){
		return bInPlay
	}
}

function InitScript(){
	dictPlayers <- {}
	::dictSurvivors <- {}//HashTable of pointers for only the survivors.
	::dictZombies <- {}//HashTable of pointers for only the zombies.
	intSurvivors <- 0 //# of T's
	
	TellDev("Player Manager Initalized!")
}

function AddPlayer(event_data){
	//Should be fired by a logic_eventlistener with player_connect
	//Checks to see if there is an open slot, and adds the player based on their userID

	local intUserId = event_data.userid

	foreach(key, val in event_data){
		TellDev(key + " : " + val)
	}
	/*
	if(event_data.networkid == "BOT"){
		TellDev("Attempted to add a bot, ignoring!")
		return
	}
	*/
	try{
		print(dictPlayers.rawget(intUserId))

		//Player exists!
		TellDev("Player with a UserID " + intUserId + " exists! Ignoring new user.")
		return
	}
	catch(e){
		//Player doesn't exists
		
	}

	local pPlayer = Player(event_data)

	if(!pPlayer.IsValid()){
		//Player is somehow invalid.
		return
	}

	dictPlayers.rawset(intUserId, pPlayer)

	if(pPlayer.GetTeam() == 2){
		//On survivors team.
		dictSurvivors.rawset(intUserId, pPlayer)
	}
	else{
		dictZombies.rawset(intUserId, pPlayer)
	}
	TellDev("Adding new player!")
}

function AddExistingPlayer(pPlayer){
	//On round reset, use this to remake the array.
	//pPlayer should be the CLASS INSTANCE, not the entity instance.
	local intUserId = pPlayer.GetUserId()
	
	dictPlayers.rawset(intUserId, pPlayer)

	if(pPlayer.GetTeam() == 2){
		dictSurvivors.rawset(intUserId, pPlayer)
	}
	else{
		dictZombies.rawset(intUserId, pPlayer)
	}
	
	pPlayer.ResetRound()
	
	TellDev("Added existing player!")
	
}

function RemovePlayer(event_data){
	//Should be called by a logic_eventlistener with player_disconnect
	//Makes sure that the player's entity is invalid, redistributes their points, and removes the instance.

	local intUserId = event_data.userid
	local pPlayer = GetPlayer(intUserId)
	printl(pPlayer)
	if(!pPlayer || !pPlayer.IsValid()){
		//Player for some reason does not have an account!
		TellDev("Player doesn't exist!")
		return
	}

	dictPlayers.rawdelete(intUserId)

	if(pPlayer.GetTeam() == 2){
		//Player is also a survivor.
		dictSurvivors.rawdelete(intUserId)
	}
	
	local intSparePoints = pPlayer.GetPoints()
	local strName = pPlayer.GetName()
	local intPlayerTeam = pPlayer.GetTeam()
	
	local rActivePlayers = []
	foreach(UserId, pEnt in dictPlayers){
		if(pEnt && pEnt.GetTeam() == intPlayerTeam){ //We want to make sure points are only distributed to teammates.
			rActivePlayers.append(pEnt)
		}
	}
	
	local intPlayers = rActivePlayers.len()
	local intCashAmount = 0
	try{
		intCashAmount = floor((intSparePoints / 10) / intPlayers) * 10
	}
	catch(x){
		
	}
	
	foreach(idx, pEnt in rActivePlayers){
		pEnt + intCashAmount
		pEnt.TellPlayer("You have been awarded " + intCashAmount + " for the disconnect of " + strName + "!")
	}
}

function GetPlayer(UserId){
	//Use userid to get player.
	
	try{
		return dictPlayers.rawget(UserId)
	}
	catch(e){
		return null
	}
}

function PlayerExists(UserId){
	//Checks to make sure there isn't an active player in a slot.
	//Will disregard invalid players.
	try{
		local pPlayer = GetPlayer(UserId)
		return pPlayer.IsValid()
	}
	catch(e){
		return false
	}
}

function DisplayPoints(){
	//Fires ShowPoints() for each player.
	foreach(idx, pPlayer in dictSurvivors){
		try{
			pPlayer.ShowPoints()
		}
		catch(e){
			//Just in case the player does not have an ent text (bot), don't whine about it.
		}
	}
}

::ListPlayers <- function(){
	//Prints out dictPlayers
	foreach(UserId, pPlayer in dictPlayers){
		TellDev(UserId.tostring() + ": " + pPlayer)
	}
}

::GetSurvivors <- function(){
	return dictSurvivors
}

::GetZombies <- function(){
	return dictZombies
}

InitScript()