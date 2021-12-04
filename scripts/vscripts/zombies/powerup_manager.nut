/*
	Zombies Gamemode v2.0

	Wave Manager

	Creates the instances of powerups, and makes sure they are removed properly.
*/

class GamePowerup{
    //The physical entity that will show up in-game.
    pEnt = null
    pSprite = null
    vectOrigin = null
    vectColor = null

    strPowerup = null

    flCreationTime = null
    flTimeout = null

    intTimeoutDelay = 20

    OnTouch = null

    constructor(dictPowerup, Origin){
        flCreationTime = Time()
        flTimeout = flCreationTime + intTimeoutDelay
        vectOrigin = Origin
        vectColor = dictPowerup.color
        strPowerup = dictPowerup.name

        printl(dictPowerup.model)
        pEnt = CreateProp("prop_dynamic", vectOrigin, dictPowerup.model, 0)
        pEnt.__KeyValueFromInt("body", dictPowerup.bodygroup)
        pEnt.__KeyValueFromVector("rendercolor", dictPowerup.color)
        //pEnt.__KeyValueFromString("DefaultAnim", "idle")

		pSprite = GameEntity("env_lightglow", {
			VerticalGlowSize = 16,
			HorizontalGlowSize = 16,
			GlowProxySize = 64,
			MinDist = 0,
			MaxDist = 3,
			rendercolor = dictPowerup.color,
			})

		pSprite.GetEnt().SetOrigin(vectOrigin)

        OnTouch = dictPowerup.logic
    }

    function Think(){
        //Fired every Think()
        //Returns True when it has been activated or timed out.
        //Returns False when it's still waiting to activate.

        if(Time() > flTimeout){
            //Times up!
            Destroy()
            return true
        }

        local flRatio = (Time() - flCreationTime) / (flTimeout - flCreationTime)
        local vectNewColor = GradientColor(vectColor, Vector(0, 0, 0), flRatio)

        SetColor(vectNewColor)

        local pPlayer = Entities.FindByClassnameWithin(null, "player", vectOrigin, 16)

        if(!pPlayer || pPlayer.GetTeam() != 2){
            //There is either no player or a CT touching.
            return false
        }

        //Player has touched it!
        TellDev(strPowerup)
        OnTouch(pPlayer)
        Destroy()
        return true
    }

    function Destroy(){
        //Kill this instance!
        pEnt.Destroy()
        pSprite.GetEnt().Destroy()
    }

    function SetColor(vectCol){
        pEnt.__KeyValueFromVector("rendercolor", vectCol)
        pSprite.EditVector("rendercolor", vectCol)
    }

    function GradientColor(vectStartCol, vectEndCol, flRatio){
        //Returns a vector of the color that is between the two colors depending on the ratio.
        //vectStartCol: What should the color start as. Full at 0
        //vectEndCol: What should the color end as. Full at 1
        //flRatio: What part of the gradient are we calculating?
        return Vector(
			vectStartCol.x + flRatio * (vectEndCol.x - vectStartCol.x),
			vectStartCol.y + flRatio * (vectEndCol.y - vectStartCol.y),
			vectStartCol.z + flRatio * (vectEndCol.z - vectStartCol.z)
		)
    }

}

function InitScript(){
    rPowerups <- []
    rActivePowerups <- []//Instances of powerups in the field.

    InitStandardPowerups()
}

function InitStandardPowerups(){
    //Create the original 4 powerups, you can add more if you know what you are doing.
    self.PrecacheModel("models/zombies/powerup.mdl")

    ::pNukeFlash <- GameEntity("env_fade", {
        duration = 0.2,
        rendercolor = Vector(252, 236, 205),
        ReverseFadeDuration = 0.1
    })
    ::pNukeShake <- GameEntity("env_shake", {
        amplitude = 8,
        duration = 3,
        spawnflags = 5
    })
    ::pAmmoReloader <- GameEntity("point_give_ammo")
    AddPowerup({
        name = "Heal Up",
        color = Vector(0, 164, 0),
        model = "models/zombies/powerup.mdl",
        bodygroup = 0,
        logic = function(activator= null){
            //activator: Player who first entered the trigger.
            foreach(idx, pPlayer in GetSurvivors()){
                local pEnt = pPlayer.GetEnt()
                pEnt.SetHealth(pEnt.GetMaxHealth())
                pPlayer.Command("playvol items/healthshot_success_01.wav 1")
            }
            ScriptPrintMessageCenterTeam(2, "Healed Up!")
            if(RandomInt(1, 20) == 1){
                ClientCommand("cheer", activator, 1)
            }
        }
    })
    AddPowerup({
        name = "Nuke",
        color = Vector(255, 0, 0),
        model = "models/zombies/powerup.mdl",
        bodygroup = 2,
        logic = function(activator= null){
            EntFireByHandle(pNukeShake.GetEnt(), "StartShake", "", 0 , null, null)
            foreach(userId, pPlayer in GetSurvivors()){
                local pEnt = pPlayer.GetEnt()
                pPlayer.Command("playvol weapons/c4/c4_explode1.wav 1")
                EntFireByHandle(pNukeFlash.GetEnt(), "Fade", "", 0, pEnt, pEnt)
                pPlayer + 400
            }
            local i = 0 //This is needed in case more than one drop at the same time. It can fuck up badly.
            foreach(userId, pPlayer in GetZombies()){
                local pEnt = pPlayer.GetEnt()
                if(!pPlayer.InPlay()){
                    //Zombie isn't in play. Ignore.
                    TellDev("Not in play, ignoring.")
                    continue
                }
                EntFireByHandle(pEnt, "SetHealth", "0", 0.3 + (0.03 * i), null, null)
                i++
            }
            ScriptPrintMessageCenterTeam(2, "Kaboom!")
            if(RandomInt(1, 20) == 1){
                ClientCommand("enemydown", activator, 1)
            }
        }
    })
    AddPowerup({
        name = "Revive",
        color = Vector(255, 255, 255),
        model = "models/zombies/powerup.mdl",
        bodygroup = 3,
        logic = function(activator= null){
            ServerCommand("mp_respawn_on_death_t 1")
            ServerCommand("mp_respawn_on_death_t 0", 5)
            foreach(userId, pPlayer in GetSurvivors()){
                pPlayer.Command("playvol player/pl_respawn.wav 1")
                if(RandomInt(1, 20) == 1){
                    pPlayer.Command("thanks", 2)
                }
            }
            ScriptPrintMessageCenterTeam(2, "The Dead Rise!")
        }
    })
    AddPowerup({
        name = "Max Ammo",
        color = Vector(255, 156, 0),
        model = "models/zombies/powerup.mdl",
        bodygroup = 1,
        logic = function(activator = null){
            foreach(userId, pPlayer in GetSurvivors()){
                local pEnt = pPlayer.GetEnt()
                EntFireByHandle(pAmmoReloader.GetEnt(), "GiveAmmo", "", 0, pEnt, pEnt)
                pPlayer.Command("playvol weapons/m249/m249_pump.wav 1")
            }
            ScriptPrintMessageCenterTeam(2, "Max Ammo!")
            if(RandomInt(1, 20) == 1){
                ClientCommand("cheer", activator, 2)
            }
        }
    })
}

function AddPowerup(dictData){
    rPowerups.append(dictData)
}

function DropPowerup(vectOrigin){
    local pPowerup = rPowerups[RandomInt(0, rPowerups.len() - 1)]
    rActivePowerups.append(GamePowerup(pPowerup, vectOrigin))
}

function CleanupPowerup(pPowerup){
    foreach(idx, pCompare in rActivePowerups){
        if(pCompare == pPowerup){
            rActivePowerups.remove(idx)
        }
    }
}

function PowerupThink(){
    //Fired every think.
    //Fires think for every powerup.
    local rCleanup = []
    foreach(idx, pPowerup in rActivePowerups){
        if(pPowerup.Think()){
            //True, want's to destroy!
            TellDev("Destroying powerup!")
            rCleanup.append(pPowerup)
        }
    }
    foreach(idx, pPowerup in rCleanup){
        CleanupPowerup(pPowerup)
    }
}

InitScript()
