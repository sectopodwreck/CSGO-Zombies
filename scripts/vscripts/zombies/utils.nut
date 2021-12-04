::TellDev <- function(strMessage){
	if(GetDeveloperLevel() > 0){
		printl(strMessage)
	}
}

::FindNextPlayerOrBot <- function(pEnt){
	local pNextPlayer = Entities.FindByClassname(pEnt, "player")
	local pNextBot = Entities.FindByClassname(pEnt, "cs_bot")
	
	if(!pNextPlayer || !pNextBot){
		if(pNextPlayer){
			return pNextPlayer
		}
		return pNextBot
	}
	
	
	if(pNextPlayer.entindex() < pNextBot.entindex()){
		return pNextPlayer
	}
	return pNextBot
}

::min <- function(intOne, intTwo){
	if(intOne < intTwo){
		return intOne
	}
	return intTwo
}

::max <- function(intOne, intTwo){
	if(intOne > intTwo){
		return intOne
	}
	return intTwo
}