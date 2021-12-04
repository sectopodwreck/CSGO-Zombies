/*
	Zombies Gamemode v2.0

	Event Logic

	Deals with what to do when an event happens.
*/

//Keep in mind the kill rewards will be plus whatever HURT_REWARD is.
KILL_REWARD <- 50
HEADSHOT_REWARD <- 90
KNIFE_REWARD <- 120
HURT_REWARD <- 10

function PlayerDeath(event_data){
	
	TellDev("Death!")

	local pKilled = GetPlayer(event_data.userid)

	if(event_data.userid == event_data.attacker){
		//Player killed himself... dumbass.
		if(pKilled.GetTeam() == 3 && pKilled.InPlay()){
			//Is a zombie in bounds, continue.
			TellDev("Continuing...")
		}
		else{
			TellDev("Killed self!")
			return
		}
	}

	local pPlayer = GetPlayer(event_data.attacker)
	local pAssister = GetPlayer(event_data.assister)

	if(!pPlayer){
		TellDev("Killer does not have an account!")
		return
	}

	if(pKilled && pKilled.GetTeam() == 3){
		TellDev("Killed CT!!")
		//Killed player is a CT and has an account.
		pKilled.SetOutPlay()
		if(RandomInt(1, 50) < 3){
			local vectOrigin = pKilled.GetEnt().GetOrigin()
			vectOrigin -= Vector(0, 0, 16)
			TellDev("Dropping a powerup!")
			DropPowerup(vectOrigin)
		}
		WAVE_KILLED++
		WAVE_ACTIVE--
		CheckWaveStatus()
	}

	if(pPlayer.GetTeam() != 2){
		//We don't want the zombies to earn points.
		return
	}

	if(pAssister){
		//Reward players for assisting.
		pAssister + 30
	}

	if(event_data.headshot){
		pPlayer + HEADSHOT_REWARD
		return
	}
	if(event_data.weapon == "weapon_knife"){
		pPlayer + KNIFE_REWARD
		return
	}

	pPlayer + KILL_REWARD
	if(RandomFloat(0, 1) < 0.05){
		//5% of occuring.
		pPlayer.Command("enemydown")
	}
}

function PlayerHurt(event_data){

	if(event_data.attacker == event_data.userid){
		//Player is hurting himself... dumbass.
		return
	}

	local pPlayer = GetPlayer(event_data.attacker)

	if(!pPlayer){
		TellDev("Killer does not have an account!")
		return
	}

	if(pPlayer.GetTeam() != 2){
		TellDev("Killer is not on T (Survivor's) side!")
		return
	}

	pPlayer + HURT_REWARD
	return
}

function RoundEnd(){
	//Attempting to garbage collect by deleting the entire scope at the end of the round.
	TellDev("\n\nPre Restart!\n\n")
	try{
		//ServerCommand("bot_kick")
		foreach(intUserId, pPlayer in GetZombies()){
			EntFireByHandle(pPlayer.GetEnt(), "SetHealth", "0", 0, null, null)
		}
	}
	catch(e){
		//Just do nothing
		TellDev(e)
	}
}
