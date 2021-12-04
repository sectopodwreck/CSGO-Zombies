/*
	Zombies Gamemode v2.0
	
	Wave Manager
	
	Calculates the amount/health of zombies for each wave.
*/

function InitScript(){
	::WAVE <- 0
	WAVE_COOLDOWN <- 10 //Time after last wave until the next one starts.
	WAVE_NEXT <- 0 //Time when next wave starts.
	WAVE_AMOUNT <- 0 //Amount of zombies for this wave.
	WAVE_REMAINING <- 0 //Amount of zombies that remain for the round. (amount - killed)
	WAVE_HEALTH <- 0 //Zombie health for this wave.
	WAVE_ARMOR <- "" //Should be item_kevlar or item_assaultsuit when it's unlocked.
	WAVE_ACTIVE <- 0 //Amount of zombies in the play area.
	WAVE_KILLED <- 0 //Amount of killed zombies for this wave.
	WAVE_OVER <- true //Don't spawn zombies when true.
	WAVE_PAUSED <- false //Allows for the pausing of the game.

	ZOMBIES_QUEUE <- [] //Used when wanting to spawn zombies into the play area.

	ZOMBIES_BASE <- 10
	ZOMBIES_MULTIPLIER <- 0.25

	ZOMBIES_HEALTH_BASE <- 50
	ZOMBIES_HEALTH_MULTIPLIER <- 0.75
	ZOMBIES_HEALTH_MAX <- 500
	ZOMBIES_ARMOR_ROUND <- 10 //Which round to give zombies normal armor.
	ZOMBIES_ASSAULTSUIT_ROUND <- 20 //Which round to give zombies armor/helmet
	
	BOT_MAX <- 20 //Limit the amount of bots in the game.
	
	InitTeleporter()
	//InitSpawns()
}

function WaveThink(){
	//Think Function.
	
	if(WAVE == 0 || WAVE_PAUSED){
		//Game hasn't started or is paused, do nothing.
		return
	}
	
	if(WAVE_OVER){
		if(Time() > WAVE_NEXT){
			StartNextWave()
		}
		return
	}
	SpawnZombies()
}

function StartGame(){
	if(WAVE > 0){
		//This command is only to START the game. (Not during warmup tho.)
		return
	}
	if(ScriptIsWarmupPeriod()){
		WAVE = "(Warmup)"
		PauseWave()
		return
	}
	StartNextWave()
}

function StartNextWave(){
	//Calculates the next wave and start spawning.
	WAVE += 1
	WAVE_ACTIVE = 0
	WAVE_KILLED = 0
	CalculateWave(WAVE)
	WAVE_REMAINING = WAVE_AMOUNT
	PlayRoundStart()
	
	WAVE_OVER = false
	foreach(intUserId, pPlayer in GetSurvivors()){
		local intMaxHealth = pPlayer.GetEnt().GetMaxHealth()
		local intRegenedHealth = floor(intMaxHealth/2)
		local intHealth = pPlayer.GetEnt().GetHealth()
		pPlayer.GetEnt().SetHealth(min(intHealth + intRegenedHealth, intMaxHealth))
		GiveWeapon("item_kevlar", pPlayer.GetEnt())
	}
}

function EndWave(){
	//Respawn survivors.
	WAVE_OVER = true
	ServerCommand("mp_respawn_on_death_t 1")
	ServerCommand("mp_respawn_on_death_t 0", WAVE_COOLDOWN)
	WAVE_NEXT <- Time() + WAVE_COOLDOWN
	PlayRoundEnd()
}

function PauseWave(){
	WAVE_PAUSED = true
}

function ResumeWave(){
	WAVE_PAUSED = false
}

function CheckWaveStatus(){
	//Fired every time a zombie dies.
	TellDev("Amount killed in this wave: " + WAVE_KILLED)
	TellDev("Amount in action: " + WAVE_ACTIVE)
	WAVE_REMAINING = WAVE_AMOUNT - WAVE_KILLED
	if(WAVE_REMAINING < 1){
		EndWave()
	}
}

function CalculateWave(intWave){
	//Calculates the amount/health for the wave, and assigns the variables as such.
	WAVE_AMOUNT <- floor(pow(intWave - 1, (1 + (0.5 * ZOMBIES_MULTIPLIER)*intSurvivors)) * pow(intWave - 1, ZOMBIES_MULTIPLIER) + ZOMBIES_BASE)
	WAVE_HEALTH <- min(floor(pow(intWave - 1, 1 + ZOMBIES_HEALTH_MULTIPLIER) + ZOMBIES_HEALTH_BASE), ZOMBIES_HEALTH_MAX)
	if(intWave >= ZOMBIES_ASSAULTSUIT_ROUND){
		WAVE_ARMOR = "item_assaultsuit"
	}
	else if(intWave >= ZOMBIES_ARMOR_ROUND){
		WAVE_ARMOR = "item_kevlar"
	}
	else{
		WAVE_ARMOR = ""
	}
	
	printl("Round: " + intWave + "\nZombies: " + WAVE_AMOUNT + "\nHealth: " + WAVE_HEALTH + "\nArmor: " + WAVE_ARMOR)
}

function PlayRoundStart(){
	foreach(idx, pPlayer in GetSurvivors()){
		if(pPlayer.GetTeam() == 2){
			ClientCommand("playvol survival/RocketAlarm.wav 1", pPlayer.GetEnt())
		}
	}
}

function PlayRoundEnd(){
	foreach(idx, pPlayer in GetSurvivors()){
		if(pPlayer.GetTeam() == 2){
			pPlayer.Command("playvol UI/achievement_earned.wav 1")
		}
	}
}

function InitSpawns(){
	//Counts and creates the CT's spawnpoints. This keeps the game from
	//Spawning in more zombies than the level creator wanted.

	local intSpawns = 0
	local pEnt = null
	local rQueuedDestroy = []

	while(pEnt = Entities.FindByClassname(pEnt, "info_player_counterterrorist")){
		intSpawns++
		TellDev(intSpawns)
		
		if(intSpawns > BOT_MAX){
			//Too many spawns!
			rQueuedDestroy.append(pEnt)
		}
	}

	foreach(idx, pEnt in rQueuedDestroy){
		TellDev("Destroying spawn!")
		pEnt.Destroy()
	}

	//We may need to make more.
	local intDiff = BOT_MAX - intSpawns
	local vectOrigin = Entities.FindByName(null, "zombies_spawnpoint").GetOrigin()

	TellDev(intDiff)

	for(local i = 0; i < intDiff; i++){
		printl("Spawning")
		//pEnt = Entities.CreateByClassname("info_player_counterterrorist")
		//pEnt.SetOrigin(vectOrigin)
	}
}

function SpawnZombies(){
	//Takes zombies from the queue, gives them the correct health, and teleports
	//them to "zombies_destination" on the play area.
	
	if(WAVE_OVER){
		//Not in a wave.
		return
	}
	
	if(!Entities.FindByName(null, "zombies_destination")){
		//There are no active teleport destinations.
		return
	}

	foreach(userId, pPlayer in GetSurvivors()){
		//Go through each player and spawn one zombie.
		
		if(WAVE_ACTIVE >= WAVE_REMAINING){
			//Too many zombies in the field.
			break
		}

		try{
			local rDestinations = GetClosestDestinations(pPlayer.GetEnt())
			foreach(idx, pDestination in rDestinations){
				if(WAVE_ACTIVE >= WAVE_REMAINING){
					break
				}
				SpawnZombie(pDestination)
			}
			
		}
		catch(e)
		{
			//Player was not close to a spawn point! Loop through again!
			//TellDev(e)
			continue
		}
	}
}

function SpawnZombie(pDestination){
	//Spawns a singular zombie at the given destination.
	local pZombie = ZOMBIES_QUEUE.pop()
	pZombie.SetMaxHealth(WAVE_HEALTH) //Set the zombie to the wave's health.
	pZombie.SetHealth(WAVE_HEALTH)
	if(WAVE_ARMOR){ //Check for armor.
		GiveWeapon(WAVE_ARMOR, pZombie)
	}
	try{
		pZombie.GetScriptScope().ClassInstance.SetInPlay() //Attempt to set their instance into play if it exists.
	}
	catch(e){
		//zombie doesn't have an account.
	}

	pZombie.SetOrigin(pDestination.GetOrigin())
	pZombie.SetAngles(0, pDestination.GetAngles().y, 0)

	WAVE_ACTIVE++
}

function GetClosestDestinations(pPlayer){
	//Returns Array
	//Find the closest entity witht the targetname "zombies_destination" to the given player.
	local vectOrigin = pPlayer.GetOrigin()
	local pDestination = null
	local rDestinations = []
	
	while(pDestination = Entities.FindByNameWithin(pDestination, "zombies_destination", vectOrigin, 2048)){
		rDestinations.append(pDestination)
	}
	
	return rDestinations
}

function InitTeleporter(){
	//Gives a trigger_multiple with the targetname "zombies_spawnpoint" a script scope.
	local pTrigger = Entities.FindByName(null, "zombies_spawnpoint")
	
	try{
		if(pTrigger.GetClassname() != "trigger_multiple"){
			TellDev("Couldn't find trigger_multiple!")
			return
		}
		pTrigger.ValidateScriptScope()
	}
	catch(e){
		TellDev("Couldn't find zombies_spawnpoint!")
		return
	}
	
	local pScope = pTrigger.GetScriptScope()
	
	//Trigger's script scope \|/
	pScope.pScript <- this
	
	pScope.OnStartTouch <- function(){
		if(activator.GetTeam() != 3){
			//Activator MUST be CT!
			TellDev("There's a T in the teleport room!")
			return
		}
		TellDev("Touch!")
		pScript.AppendToQueue(activator)
		try{
			//Make sure they are OUT of play!
			local pScope = activator.GetScriptScope().ClassInstance
			pScope.SetOutPlay()
		}
		catch(e){
			//Do nothing.
		}
	}
	
	pTrigger.ConnectOutput("OnStartTouch", "OnStartTouch")
}

function AppendToQueue(pZombie){
	//pZombie: A CT player instance pointer.
	
	if(pZombie.GetTeam() != 3){
		//Must be CT!
		return
	}
	
	//Check to see if the zombie is already in the queue.
	foreach(idx, pExistingZombie in ZOMBIES_QUEUE){
		if(pExistingZombie == pZombie){
			TellDev("An existing zombie is trying to append into the queue!")
			return
		}
	}
	//Zombie is not already in queue.
	ZOMBIES_QUEUE.append(pZombie)
}

InitScript()