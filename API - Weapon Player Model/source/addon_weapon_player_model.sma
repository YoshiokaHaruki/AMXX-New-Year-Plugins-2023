new const PluginName[ ] =				"[API] Addon: Weapon Player Model";
new const PluginVersion[ ] =			"1.0";
new const PluginAuthor[ ] =				"Yoshioka Haruki";

/* ~ [ Includes ] ~ */
#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <reapi>

#if !defined _reapi_included
	#include <non_reapi_support>
#endif

/* ~ [ Plugin Settings ] ~ */
/**
 * Hide the Weapon Player Model if the player is dead
 */
#define HidePlayerModelWhenDie

new const PluginPrefix[ ] =				"[API:WPM]";
new const EntityReference[ ] =			"info_target";
new const EntityClassName[ ] =			"ent_weapon_pmodel";

/* ~ [ Params ] ~ */
new gl_pWeaponPlayerModel[ MAX_PLAYERS + 1 ];

/* ~ [ Macroses ] ~ */
#if !defined MAX_RESOURCE_PATH_LENGTH
	#define MAX_RESOURCE_PATH_LENGTH	64
#endif

#define IsNullString(%0)				bool: ( %0[ 0 ] == EOS )

/* ~ [ AMX Mod X ] ~ */
public plugin_natives( )
{
	register_native( "api_wpn_player_model_set",	"native_wpn_player_model_set" );
	register_native( "api_wpn_player_model_get",	"native_wpn_player_model_get" );
	register_native( "api_wpn_player_model_hide",	"native_wpn_player_model_hide" );
	register_native( "api_wpn_player_model_remove",	"native_wpn_player_model_remove" );
}

public plugin_init( )
{
	register_plugin( PluginName, PluginVersion, PluginAuthor );

#if defined _reapi_included
	/* -> ReGameDLL <- */
	RegisterHookChain( RG_CBasePlayerWeapon_DefaultDeploy, "CWeapon__Deploy_Pre", false );

	#if defined HidePlayerModelWhenDie
		RegisterHookChain( RG_CBasePlayer_Killed, "CPlayer__Killed_Post", true );
	#endif
#else
	/* -> HamSandwich <- */
	new WeaponReferences[ ][ ] = {
		"weapon_p228", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4",
		"weapon_mac10", "weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", 
		"weapon_ump45", "weapon_sg550", "weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", 
		"weapon_awp", "weapon_mp5navy", "weapon_m249", "weapon_m3", "weapon_m4a1", "weapon_tmp", 
		"weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552", "weapon_ak47", 
		"weapon_knife", "weapon_p90"
	};

	for ( new i = 0, iIterations = sizeof WeaponReferences; i < iIterations; i++ )
		RegisterHam( Ham_Item_Deploy, WeaponReferences[ i ], "CWeapon__Deploy_Pre", false );

	#if defined HidePlayerModelWhenDie
		RegisterHam( Ham_Killed, "player", "CPlayer__Killed_Post", true );
	#endif
#endif
}

public client_putinserver( pPlayer ) CBasePlayer__InitPlayerModel( pPlayer );
public client_disconnected( pPlayer ) CBasePlayer__RemovePlayerModel( pPlayer );

/* ~ [ ReGameDLL / HamSandwich ] ~ */
public CWeapon__Deploy_Pre( const pItem )
{
	new pPlayer = get_member( pItem, m_pPlayer );
	if ( !is_user_alive( pPlayer ) )
		return;

	CBasePlayer__WeaponPlayerModel( pPlayer );
}

#if defined HidePlayerModelWhenDie
	public CPlayer__Killed_Post( const pVictim ) CBasePlayer__WeaponPlayerModel( pVictim );
#endif

/* ~ [ Other ] ~ */
public CBasePlayer__InitPlayerModel( const pPlayer )
{
	gl_pWeaponPlayerModel[ pPlayer ] = rg_create_entity( EntityReference );

	if ( !is_nullent( gl_pWeaponPlayerModel[ pPlayer ] ) )
	{
		set_entvar( gl_pWeaponPlayerModel[ pPlayer ], var_classname, EntityClassName );
		set_entvar( gl_pWeaponPlayerModel[ pPlayer ], var_movetype, MOVETYPE_FOLLOW );
		set_entvar( gl_pWeaponPlayerModel[ pPlayer ], var_owner, pPlayer );
		set_entvar( gl_pWeaponPlayerModel[ pPlayer ], var_aiment, pPlayer );
	}
}

bool: CBasePlayer__WeaponPlayerModel( const pPlayer, const szModel[ ] = "", const iBody = 0, const iSkin = 0, const iSequence = 0 )
{
	if ( is_nullent( gl_pWeaponPlayerModel[ pPlayer ] ) )
	{
		if ( CBasePlayer__InitPlayerModel( pPlayer ) && is_nullent( gl_pWeaponPlayerModel[ pPlayer ] ) )
			return false;
	}

	new bitsEffects = get_entvar( gl_pWeaponPlayerModel[ pPlayer ], var_effects );
	if ( IsNullString( szModel ) )
		bitsEffects |= EF_NODRAW;
	else
	{
		bitsEffects &= ~EF_NODRAW;
		engfunc( EngFunc_SetModel, gl_pWeaponPlayerModel[ pPlayer ], szModel );
	}

	set_entvar( gl_pWeaponPlayerModel[ pPlayer ], var_body, iBody );
	set_entvar( gl_pWeaponPlayerModel[ pPlayer ], var_skin, iSkin );
	set_entvar( gl_pWeaponPlayerModel[ pPlayer ], var_effects, bitsEffects );

	UTIL_SetEntityAnim( gl_pWeaponPlayerModel[ pPlayer ], iSequence );

	return true;
}

public CBasePlayer__GetPlayerModel( const pPlayer ) return gl_pWeaponPlayerModel[ pPlayer ];

public bool: CBasePlayer__RemovePlayerModel( const pPlayer )
{
	if ( !is_nullent( gl_pWeaponPlayerModel[ pPlayer ] ) )
	{
		UTIL_KillEntity( gl_pWeaponPlayerModel[ pPlayer ] );
		return true;
	}

	gl_pWeaponPlayerModel[ pPlayer ] = NULLENT;
	return false;
}

/* ~ [ Stocks ] ~ */
/* -> Destroy Entity <- */
stock UTIL_KillEntity( const pEntity )
{
	set_entvar( pEntity, var_flags, FL_KILLME );
	set_entvar( pEntity, var_nextthink, get_gametime( ) );
}

/* -> Entity Animation <- */
stock UTIL_SetEntityAnim( const pEntity, const iSequence = 0, const Float: flFrame = 0.0, const Float: flFrameRate = 1.0 )
{
	set_entvar( pEntity, var_frame, flFrame );
	set_entvar( pEntity, var_framerate, flFrameRate );
	set_entvar( pEntity, var_animtime, get_gametime( ) );
	set_entvar( pEntity, var_sequence, iSequence );
}

/* ~ [ Natives ] ~ */
public bool: native_wpn_player_model_set( const iPlugin, const iParams )
{
	enum { arg_player = 1, arg_model, arg_body, arg_skin, arg_sequence };

	new pPlayer = get_param( arg_player );
	if ( !is_user_alive( pPlayer ) )
	{
		log_error( AMX_ERR_NATIVE, "%s Invalid Player (Id: %i)", PluginPrefix, pPlayer );
		return false;
	}

	new szModel[ MAX_RESOURCE_PATH_LENGTH ];
	get_string( arg_model, szModel, charsmax( szModel ) );

	return CBasePlayer__WeaponPlayerModel( pPlayer, szModel, get_param( arg_body ), get_param( arg_skin ), get_param( arg_sequence ) );
}

public native_wpn_player_model_get( const iPlugin, const iParams )
{
	enum { arg_player = 1 };

	new pPlayer = get_param( arg_player );
	if ( !is_user_alive( pPlayer ) )
	{
		log_error( AMX_ERR_NATIVE, "%s Invalid Player (Id: %i)", PluginPrefix, pPlayer );
		return -1;
	}

	return gl_pWeaponPlayerModel[ pPlayer ];
}

public bool: native_wpn_player_model_hide( const iPlugin, const iParams )
{
	enum { arg_player = 1 };

	new pPlayer = get_param( arg_player );
	if ( !is_user_alive( pPlayer ) )
	{
		log_error( AMX_ERR_NATIVE, "%s Invalid Player (Id: %i)", PluginPrefix, pPlayer );
		return false;
	}

	return CBasePlayer__WeaponPlayerModel( pPlayer );
}

public bool: native_wpn_player_model_remove( const iPlugin, const iParams )
{
	enum { arg_player = 1 };

	new pPlayer = get_param( arg_player );
	if ( !is_user_alive( pPlayer ) )
	{
		log_error( AMX_ERR_NATIVE, "%s Invalid Player (Id: %i)", PluginPrefix, pPlayer );
		return false;
	}

	return CBasePlayer__RemovePlayerModel( pPlayer );
}
