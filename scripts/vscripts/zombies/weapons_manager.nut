/*
	Zombies Gamemode v2.0

	Weapons manager.

	Creates and houses information on all available weapons/items.
*/

class Weapon{
	strName = null
	strEntName = null
	strMdlName = null
	intPrice = null
	intPriceAmmo = null
	intTeam = null
	bNeedsFixup = null

	constructor(name, entName, mdlName, price, team = 1, needsFixup = false){
		strName = name
		strEntName = entName
		strMdlName = mdlName
		intPrice = price
		intPriceAmmo = InitAmmoPrice()
		intTeam = team //1 = All, 2 = T, 3 = CT
		bNeedsFixup = needsFixup
	}

	function InitAmmoPrice(){
		//Should be Half of the price, and floored to the nearest 10's.
		return 10 * floor(intPrice / 20)
	}

	function GetName(){
		//Front end name (AK-47)
		return strName
	}

	function GetEntName(){
		//Entity name (weapon_ak47)
		return strEntName
	}

	function GetMdlName(){
		//Model name (rif_ak47)
		return "models/weapons/w_" + strMdlName + ".mdl"
	}

	function GetPrice(){
		return intPrice
	}

	function GetAmmoPrice(){
		return intPriceAmmo
	}

	function GetTeam(){
		return intTeam
	}

	function NeedsFixup(){
		return bNeedsFixup
	}

}

function InitScript(){
	::rWeapons <- []
	InitDefaultWeapons()
}

function InitDefaultWeapons(){
	//Adds csgo's default weapons.
	//Append to this if there have been more added.

	///
	///	Rifles
	///

	AddWeapon("AK-47", "weapon_ak47", "rif_ak47", 2000, 2)
	AddWeapon("G3SG1", "weapon_g3sg1", "snip_g3sg1", 1800, 2)
	AddWeapon("Galil", "weapon_galilar", "rif_galilar", 2000, 2)
	AddWeapon("SG553", "weapon_sg556", "rif_sg556", 2200, 2)

	AddWeapon("AUG", "weapon_aug", "rif_aug", 2200, 3)
	AddWeapon("Famas", "weapon_famas", "rif_famas", 1200, 3)
	AddWeapon("M4A4", "weapon_m4a1", "rif_m4a1", 2000, 3)
	AddWeapon("M4A1-S", "weapon_m4a1_silencer", "rif_m4a1_s", 1900, 3)
	AddWeapon("Scar-20", "weapon_scar20", "snip_scar20", 2000, 3)

	AddWeapon("AWP", "weapon_awp", "snip_awp", 1000)
	AddWeapon("SSG08", "weapon_ssg08", "snip_ssg08", 900)

	///
	/// SMGs
	///

	AddWeapon("Mac-10", "weapon_mac10", "smg_mac10", 1500, 2)

	AddWeapon("MP9", "weapon_mp9", "smg_mp9", 1700, 3)

	AddWeapon("PP-Bizon", "weapon_bizon", "smg_bizon", 1300)
	AddWeapon("MP7", "weapon_mp7", "smg_mp7", 1500)
	AddWeapon("P90", "weapon_p90", "smg_p90", 1700)
	AddWeapon("UMP45", "weapon_ump45", "smg_ump45", 1200)
	AddWeapon("MP5", "weapon_mp5sd", "smg_mp5sd", 1500)

	///
	/// Heavies
	///

	AddWeapon("Sawed-Off", "weapon_sawedoff", "shot_sawedoff", 1100, 2)

	AddWeapon("Mag-7", "weapon_mag7", "shot_mag7", 1500, 3)

	AddWeapon("M249", "weapon_m249", "mach_m249", 2500)
	AddWeapon("Negev", "weapon_negev", "mach_negev", 2500)
	AddWeapon("Nova", "weapon_nova", "shot_nova", 1600)
	AddWeapon("XM1014", "weapon_xm1014", "shot_xm1014", 1800)

	///
	/// Pistols
	///

	AddWeapon("Glock-18", "weapon_glock", "pist_glock18", 200, 2)
	AddWeapon("Tec-9", "weapon_tec9", "pist_tec9", 300, 2)

	AddWeapon("Five-Seven", "weapon_fiveseven", "pist_fiveseven", 300, 3)
	AddWeapon("P2000", "weapon_hkp2000", "pist_hkp2000", 300, 2)
	AddWeapon("USP-S", "weapon_usp_silencer", "pist_223", 200, 3)

	AddWeapon("CZ-75", "weapon_cz75a", "pist_cz_75", 200)
	AddWeapon("Desert Eagle", "weapon_deagle", "pist_deagle", 700)
	AddWeapon("Dual Berettas", "weapon_elite", "pist_elite", 400)
	AddWeapon("P250", "weapon_p250", "pist_p250", 300)
	AddWeapon("R-8 Revolver", "weapon_revolver", "pist_revolver", 600)

	///
	/// Grenades
	///

	AddWeapon("Decoy Grenade", "weapon_decoy", "eq_decoy", 100)
	AddWeapon("Flashbang Grenade", "weapon_flashbang", "eq_flashbang", 100)
	AddWeapon("High Explosive Grenade", "weapon_hegrenade", "eq_fraggrenade", 100)
	AddWeapon("Incendiary Grenade", "weapon_incgrenade", "eq_incendiarygrenade", 300)
	AddWeapon("Molotov Cocktail", "weapon_molotov", "eq_molotov", 300)
	AddWeapon("Smoke Grenade", "weapon_smokegrenade", "eq_smokegrenade", 100)
	AddWeapon("Tactical Awareness Grenade", "weapon_tagrenade", "eq_sensorgrenade", 100)

	///
	/// Specials
	///

	AddWeapon("Health Shot", "weapon_healthshot", "eq_healthshot", 3000)
	AddWeapon("Zeus x27", "weapon_taser", "eq_taser", 900)
	AddWeapon("Breach Charge", "weapon_breachcharge", "eq_charge_dropped", 1000)
	AddWeapon("Tactical Shield", "weapon_shield", "eq_shield", 3000)

	TellDev("Initalized standard weapons!")
}

function AddWeapon(name, entName, mdlName, price, team = 1){
	rWeapons.append(Weapon(name, entName, mdlName, price, team))
}

::FindWeaponByClassname <- function(strWeapon){
	//strWeapon: the classname of the weapon you are trying to find.
	//Attempts to find a Weapon class with the given classname.

	foreach(idx, pWeapon in rWeapons){
		if(pWeapon.GetEntName() == strWeapon){
			return pWeapon
		}
	}
	return null
}

::GetRandomWeapon <- function(rExceptions = []){
	//rExceptions: Keep certain weapons from being picked. Should be the entity name. ["weapon_ak47", "weapon_m4a1"]
	local pWeapon = null
	local intTimes = 0

	while(!pWeapon){
		if(intTimes > 5){
			return rWeapons[0]
		}

		pWeapon = rWeapons[RandomInt(0, (rWeapons.len() - 1))]
		foreach(idx, strWeapon in rExceptions){
			if(pWeapon.GetEntName() == strWeapon){
				intTimes += 1
				pWeapon = null
				TellDev("Got a banned weapon, retrying!")
				break
			}
		}
	}
	return pWeapon
}

::ListWeapons <- function(){
	//Prints out every item of rWeapons
	TellDev("Weapons available:")
	foreach(idx, pWeapon in rWeapons){
		TellDev(idx.tostring() + ": " + pWeapon.GetName())
	}
}

InitScript()
