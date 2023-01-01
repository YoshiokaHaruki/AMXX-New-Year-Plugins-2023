/**
 * Weapon by xUnicorn (t3rkecorejz) 
 *
 * Thanks a lot:
 *
 * Chrescoe1 & batcoh (Phenix) — First base code
 * KORD_12.7 & 406 (Nightfury) — I'm taken some functions from this authors
 * D34, 404 & fl0wer — Some help
 * 
 * Download links:
 * 
 * api_muzzleflash.inc - https://github.com/YoshiokaHaruki/AMXX-API-Muzzle-Flash
 * api_smokewallpuff.inc - https://github.com/YoshiokaHaruki/AMXX-API-Smoke-WallPuff
 */

/* ~ [ Includes ] ~ */
#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <reapi>
#include <zombieplague>

#tryinclude <api_muzzleflash>
#tryinclude <api_smokewallpuff>

#if !defined _reapi_included
	#include <non_reapi_support>
#endif

/**
 * Automatically precache sounds from the model
 * 
 * If you have ReHLDS installed, you do not need this setting with a server cvar
 * `sv_auto_precache_sounds_in_models 1`
 */
#define PrecacheSoundsFromModel

/**
 * Use optimized sprites.
 * Implies to use sprites that are smaller, fewer extra/repeated frames.
 * Also, with these sprites, you are less likely to catch
 * the "Hunk_AllocName: failed on n bytes" error when starting the server.
 * Also use this setting if you can't set the '-heapsize' value for your server.
 */
#define UseOptimizedSprites

#if defined _zombieplague_included
	/* ~ [ Extra Item ] ~ */
	// If you need to remove weapon from Extra-Items, comment out this line
	new const ExtraItem_Name[ ] =			"SG552 Cerberus";
	const ExtraItem_Cost =					0;
#endif

/* ~ [ Weapon Settings ] ~ */
const WeaponUnicalIndex =					13122022;
new const WeaponReference[ ] =				"weapon_sg552";
// Comment 'WeaponListDir' if u dont need custom weapon list
new const WeaponListDir[ ] =				"x_re/weapon_buffsg552ex";
new const WeaponAnimation[ ] =				"rifle";
new const WeaponNative[ ] =					"zp_give_user_buffsg552ex";
new const WeaponModelView[ ] =				"models/x_re/v_buffsg552ex.mdl";
new const WeaponModelPlayer[ ] =			"models/x_re/p_buffsg552ex.mdl";
new const WeaponModelWorld[ ] =				"models/x_re/w_buffsg552ex.mdl";
// Comment 'WeaponModelShell' if u dont need eject brass (shell) 
new const WeaponModelShell[ ] =				"models/rshell.mdl"; 
new const WeaponSounds[ ][ ] = {
	"weapons/buffsg552ex-1.wav",
	"weapons/buffsg552ex_idle.wav",
	"weapons/buffsg552ex_claw_1.wav",
	"weapons/buffsg552ex_claw_2.wav",
	"weapons/buffsg552ex_claw_3.wav",
	"weapons/buffsg552ex_claw_4.wav"
};

const ModelWorldBody =						0; // Submodel of w_ model

const WeaponMaxClip =						50; // Max Clip
const WeaponDefaultAmmo =					150; // Give Ammo
const WeaponMaxAmmo =						250; // Max Ammo

#if defined _reapi_included
	new const WeaponDamage[ ] = {
		// Default, In ZOOM
		43, 39
	};
	const WeaponShotPenetration =			2;
	const Bullet: WeaponBulletType =		BULLET_PLAYER_556MM;
	const Float: WeaponShotDistance =		8192.0;
	const Float: WeaponRangeModifier =		0.955;
#else
	new const Float: WeaponDamageMultiplier[ ] = {
		// Default, In ZOOM
		1.303, 1.182
	};
#endif

const Float: WeaponAccuracy =				0.2; // Accuracy weapon (Now is original SG552 value)

// Shooting speed
new const Float: WeaponRate[ ] = {
	// Default, In ZOOM
	0.1, 0.3
};

/* ~ [ Mode: Charged ] ~ */
/**
 * In the original, if you didn't even shoot and
 * pressed the mode button again (Right Mouse Button), the mode was canceled
 */
// #define DontWasteModeIfDontShoots

const ChargedWeaponFOV =					75; // FOV in charged mode
const ChargedWeaponShoots =					40; // Count of shoots for ready mode
const ChargedWeaponBody =					2; // v_ model body if mode is ready
const Float: ChargedWeaponClawsRadius =		60.0; // Radius in mode (claws)
const Float: ChargedWeaponClawsDamage =		250.0; // Damage in mode (claws)
const Float: ChargedWeaponClawsPainShock =	1.0; // PainShock (1.0 - Enable / 0.0 - Disable)
const ChargedWeaponClawsDamageType =		DMG_BULLET|DMG_NEVERGIB; // Charged mode damage type

new const ChargedClawsSprites[ ][ ] = {
#if defined UseOptimizedSprites
	"sprites/x_re/ef_buffsg552ex_slash1_fx.spr",
	"sprites/x_re/ef_buffsg552ex_slash2_fx.spr",
	"sprites/x_re/ef_buffsg552ex_slash3_fx.spr"
#else
	"sprites/x_re/ef_buffsg552ex_slash1.spr",
	"sprites/x_re/ef_buffsg552ex_slash2.spr",
	"sprites/x_re/ef_buffsg552ex_slash3.spr"
#endif
};

/* ~ [ Muzzle Flash ] ~ */
#if defined _api_muzzleflash_included
	new const MuzzleFlashSprite[ ][ ] = {
		"sprites/x_re/muzzleflash205.spr",
	#if defined UseOptimizedSprites
		"sprites/x_re/muzzleflash206_fx.spr"
	#else
		"sprites/x_re/muzzleflash206.spr"
	#endif
	};
#endif

/* ~ [ Weapon Animations ] ~ */
enum {
	WeaponAnim_Idle = 0,
	WeaponAnim_Reload,
	WeaponAnim_Draw,
	WeaponAnim_Dummy,
#if defined _api_muzzleflash_included
	WeaponAnim_Shoot1 = 4,
#else
	WeaponAnim_Shoot1 = 7,
#endif
	WeaponAnim_Shoot2,
	WeaponAnim_Shoot3
};

const Float: WeaponAnim_Idle_Time = 		6.1;
const Float: WeaponAnim_Reload_Time = 		2.0;
const Float: WeaponAnim_Draw_Time = 		1.0;
const Float: WeaponAnim_Shoot_Time = 		2.0;

/* ~ [ Params ] ~ */
new gl_iMaxPlayers;

#if defined _zombieplague_included && defined ExtraItem_Name
	new gl_iItemId;
#endif

#if defined _api_muzzleflash_included
	enum eMuzzleFlashes {
		MuzzleFlash: Muzzle_Shoot,
		MuzzleFlash: Muzzle_ShootB
	};
	new MuzzleFlash: gl_iMuzzleId[ eMuzzleFlashes ];
#endif

#if defined WeaponModelShell
	new gl_iszModelIndex_Shell;
#endif

new gl_iClawsSprites = sizeof ChargedClawsSprites;
new gl_iszModelIndex[ sizeof ChargedClawsSprites ];

#if defined _reapi_included
	new HookChain: gl_HookChain_IsPenetrableEntity_Post;
#else
	new HamHook: gl_HamHook_TraceAttack[ 4 ];
#endif

enum {
	Sound_Shoot,
	Sound_Mode_Idle,
	Sound_Claw1,
	Sound_Claw2,
	Sound_Claw3,
	Sound_Claw4,
};

enum ( <<= 1 ) {
	WeaponState_HasMode = 1,
	WeaponState_OnMode,
#if defined DontWasteModeIfDontShoots
	WeaponState_UsedMode
#endif
};

/* ~ [ Macroses ] ~ */
#if !defined Vector3
	#define Vector3(%0)					Float: %0[ 3 ]
#endif

#define BIT_ADD(%0,%1)					( %0 |= %1 )
#define BIT_SUB(%0,%1)					( %0 &= ~%1 )
#define BIT_VALID(%0,%1)				( %0 & %1 )
#define BIT_VALID_BOOL(%0,%1)			( ( %0 & %1 ) ? true : false )

#define IsCustomWeapon(%0,%1)			bool: ( get_entvar( %0, var_impulse ) == %1 )
#define GetWeaponState(%0)				get_member( %0, m_Weapon_iWeaponState )
#define SetWeaponState(%0,%1)			set_member( %0, m_Weapon_iWeaponState, %1 )
#define GetWeaponClip(%0)				get_member( %0, m_Weapon_iClip )
#define SetWeaponClip(%0,%1)			set_member( %0, m_Weapon_iClip, %1 )
#define GetWeaponAmmoType(%0)			get_member( %0, m_Weapon_iPrimaryAmmoType )
#define GetWeaponAmmo(%0,%1)			get_member( %0, m_rgAmmo, %1 )
#define SetWeaponAmmo(%0,%1,%2)			set_member( %0, m_rgAmmo, %1, %2 )

#define WeaponOnMode(%0)				BIT_VALID_BOOL( %0, WeaponState_OnMode )
#define var_charged_mode				var_gaitsequence
#define var_next_sound 					var_impacttime

/* ~ [ AMX Mod X ] ~ */
public plugin_natives( ) register_native( WeaponNative, "native_give_user_weapon" );
public plugin_precache( ) 
{
	new i;

	/* -> Precache Models <- */
	engfunc( EngFunc_PrecacheModel, WeaponModelView );
	engfunc( EngFunc_PrecacheModel, WeaponModelPlayer );
	engfunc( EngFunc_PrecacheModel, WeaponModelWorld );
	
	/* -> Precache Sounds <- */
	for ( i = 0; i < sizeof WeaponSounds; i++ )
		engfunc( EngFunc_PrecacheSound, WeaponSounds[ i ] );

#if defined PrecacheSoundsFromModel
	UTIL_PrecacheSoundsFromModel( WeaponModelView );
#endif

#if defined WeaponListDir
	/* -> Hook Weapon <- */
	register_clcmd( WeaponListDir, "ClientCommand__HookWeapon" );

	UTIL_PrecacheWeaponList( WeaponListDir );
#endif

#if defined _api_muzzleflash_included
	/* -> MuzzleFlash <- */
	gl_iMuzzleId[ Muzzle_Shoot ] = zc_muzzle_init( );
	{
		zc_muzzle_set_property( gl_iMuzzleId[ Muzzle_Shoot ], ZC_MUZZLE_SPRITE, MuzzleFlashSprite[ 0 ] );
		zc_muzzle_set_property( gl_iMuzzleId[ Muzzle_Shoot ], ZC_MUZZLE_FRAMERATE_MLT, 0.35 );
	}

	gl_iMuzzleId[ Muzzle_ShootB ] = zc_muzzle_init( )
	{
		zc_muzzle_set_property( gl_iMuzzleId[ Muzzle_ShootB ], ZC_MUZZLE_SPRITE, MuzzleFlashSprite[ 1 ] );
		zc_muzzle_set_property( gl_iMuzzleId[ Muzzle_ShootB ], ZC_MUZZLE_SCALE, 0.035 );
		zc_muzzle_set_property( gl_iMuzzleId[ Muzzle_ShootB ], ZC_MUZZLE_FRAMERATE_MLT, 0.5 );
	}
#endif

	/* -> Model Index <- */
	for ( i = 0; i < sizeof ChargedClawsSprites; i++ )
		gl_iszModelIndex[ i ] = engfunc( EngFunc_PrecacheModel, ChargedClawsSprites[ i ] );

#if defined WeaponModelShell
	gl_iszModelIndex_Shell = engfunc( EngFunc_PrecacheModel, WeaponModelShell );
#endif
}

public plugin_init( ) 
{
	register_plugin( "[ZP] Weapon: SG552 Cerberus", "1.0", "Yoshioka Haruki" );

	/* -> Fakemeta <- */
	register_forward( FM_UpdateClientData, "FM_Hook_UpdateClientData_Post", true );

#if !defined _reapi_included
	register_forward( FM_SetModel, "FM_Hook_SetModel_Pre", false );
#else
	/* -> ReGameDLL <- */
	RegisterHookChain( RG_CWeaponBox_SetModel, "RG_CWeaponBox__SetModel_Pre", false );

	DisableHookChain( gl_HookChain_IsPenetrableEntity_Post = 
		RegisterHookChain( RG_IsPenetrableEntity, "RG_IsPenetrableEntity_Post", true ) );

	/* -> HamSandwich: Weapon <- */
	RegisterHam( Ham_Spawn, WeaponReference, "Ham_CWeapon_Spawn_Post", true );
#endif

	RegisterHam( Ham_Item_Deploy, WeaponReference, "Ham_CWeapon_Deploy_Post", true );
	RegisterHam( Ham_Item_Holster, WeaponReference, "Ham_CWeapon_Holster_Post", true );
#if defined WeaponListDir
	RegisterHam( Ham_Item_AddToPlayer, WeaponReference, "Ham_CWeapon_AddToPlayer_Post", true );
#endif
	RegisterHam( Ham_Item_PostFrame, WeaponReference, "Ham_CWeapon_PostFrame_Pre", false );
#if !defined _reapi_included
	RegisterHam( Ham_Weapon_Reload, WeaponReference, "Ham_CWeapon_Reload_Pre", false );
#else
	RegisterHam( Ham_Weapon_Reload, WeaponReference, "Ham_CWeapon_Reload_Post", true );
#endif
	RegisterHam( Ham_Weapon_WeaponIdle, WeaponReference, "Ham_CWeapon_WeaponIdle_Pre", false );
	RegisterHam( Ham_Weapon_PrimaryAttack, WeaponReference, "Ham_CWeapon_PrimaryAttack_Pre", false );
	RegisterHam( Ham_Weapon_SecondaryAttack, WeaponReference, "Ham_CWeapon_SecondaryAttack_Pre", false );

#if !defined _reapi_included
	/* -> Ham: Trace Attack -> */
	new const TraceAttack_CallBack[ ] = "Ham_CEntity_TraceAttack_Pre";

	gl_HamHook_TraceAttack[ 0 ] = RegisterHam( Ham_TraceAttack,	"func_breakable", TraceAttack_CallBack, false );
	gl_HamHook_TraceAttack[ 1 ] = RegisterHam( Ham_TraceAttack,	"info_target", TraceAttack_CallBack, false );
	gl_HamHook_TraceAttack[ 2 ] = RegisterHam( Ham_TraceAttack,	"player", TraceAttack_CallBack, false );
	gl_HamHook_TraceAttack[ 3 ] = RegisterHam( Ham_TraceAttack,	"hostage_entity", TraceAttack_CallBack, false );
	
	ToggleTraceAttack( false );
#endif

#if defined _zombieplague_included && defined ExtraItem_Name
	/* -> Register on Extra-Items <- */
	gl_iItemId = zp_register_extra_item( ExtraItem_Name, ExtraItem_Cost, ZP_TEAM_HUMAN );
#endif

	/* -> Other <- */
#if defined _reapi_included
	gl_iMaxPlayers = get_member_game( m_nMaxPlayers );
#else
	gl_iMaxPlayers = get_maxplayers( );
#endif
}

public bool: native_give_user_weapon( ) 
{
	enum { arg_player = 1 };

	new pPlayer = get_param( arg_player );
	if ( !CBasePlayer__GiveWeapon( pPlayer ) )
	{
		log_error( AMX_ERR_NATIVE, "Failed to issue a weapon to the player. (Id: %i)", pPlayer );
		return false;
	}

	return true;
}

#if defined WeaponListDir
	public ClientCommand__HookWeapon( const pPlayer ) 
	{
		engclient_cmd( pPlayer, WeaponReference );
		return PLUGIN_HANDLED;
	}
#endif

#if defined _zombieplague_included && defined ExtraItem_Name
	/* ~ [ Zombie Plague ] ~ */
	public zp_extra_item_selected( pPlayer, iItemId ) 
	{
		if ( iItemId != gl_iItemId )
			return PLUGIN_HANDLED;

		return CBasePlayer__GiveWeapon( pPlayer ) ? PLUGIN_CONTINUE : ZP_PLUGIN_HANDLED;
	}
#endif

/* ~ [ Fakemeta ] ~ */
public FM_Hook_UpdateClientData_Post( const pPlayer, const iSendWeapons, const CD_Handle ) 
{
	static iSpecMode, pTarget;
	pTarget = ( iSpecMode = get_entvar( pPlayer, var_iuser1 ) ) ? get_entvar( pPlayer, var_iuser2 ) : pPlayer;

	if ( !is_user_connected( pTarget ) )
		return;

	static pActiveItem; pActiveItem = get_member( pPlayer, m_pActiveItem );
	if ( is_nullent( pActiveItem ) || !IsCustomWeapon( pActiveItem, WeaponUnicalIndex ) )
		return;

	set_cd( CD_Handle, CD_flNextAttack, 2.0 );

	enum eSpecInfo {
		SPEC_MODE,
		SPEC_TARGET
	};
	static aSpecInfo[ MAX_PLAYERS + 1 ][ eSpecInfo ];

	if ( iSpecMode )
	{
		if ( aSpecInfo[ pPlayer ][ SPEC_MODE ] != iSpecMode )
		{
			aSpecInfo[ pPlayer ][ SPEC_MODE ] = iSpecMode;
			aSpecInfo[ pPlayer ][ SPEC_TARGET ] = 0;
		}

		if ( iSpecMode == OBS_IN_EYE && aSpecInfo[ pPlayer ][ SPEC_TARGET ] != pTarget )
			aSpecInfo[ pPlayer ][ SPEC_TARGET ] = pTarget;
	}

	static Float: flLastEventCheck; flLastEventCheck = get_member( pActiveItem, m_flLastEventCheck );
	if ( !flLastEventCheck )
	{
		set_cd( CD_Handle, CD_WeaponAnim, WeaponAnim_Dummy );
		return;
	}

	if ( flLastEventCheck <= get_gametime( ) )
	{
		UTIL_SendWeaponAnim( MSG_ONE, pTarget, pActiveItem, WeaponAnim_Draw );
		set_member( pActiveItem, m_flLastEventCheck, 0.0 );
	}
}

#if !defined _reapi_included
	public FM_Hook_SetModel_Pre( const pWeaponBox )
	{
		if ( !FClassnameIs( pWeaponBox, "weaponbox" ) )
			return FMRES_IGNORED;

		static pItem; pItem = UTIL_GetWeaponBoxItem( pWeaponBox );
		if ( pItem == NULLENT || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return FMRES_IGNORED;

		engfunc( EngFunc_SetModel, pWeaponBox, WeaponModelWorld );
		set_entvar( pWeaponBox, var_body, ModelWorldBody );

		return FMRES_SUPERCEDE;
	}

	public FM_Hook_PlaybackEvent_Pre( ) return FMRES_SUPERCEDE;
	public FM_Hook_TraceLine_Post( const Vector3( vecSrc ), Vector3( vecEnd ), const bitsFlags, const pAttacker, const pTrace )
	{
		if ( bitsFlags & IGNORE_MONSTERS )
			return;

		static Float: flFraction; get_tr2( pTrace, TR_flFraction, flFraction );
		if ( flFraction == 1.0 )
			return;

		get_tr2( pTrace, TR_vecEndPos, vecEnd );
		
		static iPointContents; iPointContents = engfunc( EngFunc_PointContents, vecEnd );
		if ( iPointContents == CONTENTS_SKY )
			return;

		new pHit = ( pHit = get_tr2( pTrace, TR_pHit ) ) == -1 ? 0 : pHit;
		if ( pHit && is_nullent( pHit ) || ( get_entvar( pHit, var_flags ) & FL_KILLME ) )
			return;

		CBasePlayerWeapon__ClawsDamage( pAttacker, pHit );

		if ( !ExecuteHam( Ham_IsBSPModel, pHit ) )
			return;

		UTIL_GunshotDecalTrace( pHit, vecEnd );

		if ( iPointContents == CONTENTS_WATER )
			return;

		static Vector3( vecPlaneNormal ); get_tr2( pTrace, TR_vecPlaneNormal, vecPlaneNormal );

	#if defined _api_smokewallpuff_included
		zc_smoke_wallpuff_draw( vecEnd, vecPlaneNormal );
	#endif

		xs_vec_mul_scalar( vecPlaneNormal, random_float( 25.0, 30.0 ), vecPlaneNormal );
		UTIL_TE_STREAK_SPLASH( MSG_PAS, vecEnd, vecPlaneNormal, 4, random_num( 10, 20 ), 3, 64 );
	}
#else
	/* ~ [ ReGameDLL ] ~ */
	public RG_CWeaponBox__SetModel_Pre( const pWeaponBox, const szModel[ ] ) 
	{
		new pItem = UTIL_GetWeaponBoxItem( pWeaponBox );
		if ( pItem == NULLENT || !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return HC_CONTINUE;

		SetHookChainArg( 2, ATYPE_STRING, WeaponModelWorld );
		set_entvar( pWeaponBox, var_body, ModelWorldBody );

		return HC_CONTINUE;
	}

	public RG_IsPenetrableEntity_Post( const Vector3( vecStart ), Vector3( vecEnd ), const pAttacker, const pHit )
	{
		static iPointContents; iPointContents = engfunc( EngFunc_PointContents, vecEnd );
		if ( iPointContents == CONTENTS_SKY )
			return;

		if ( pHit && is_nullent( pHit ) || ( get_entvar( pHit, var_flags ) & FL_KILLME ) )
			return;

		CBasePlayerWeapon__ClawsDamage( pAttacker, pHit );

		if ( !ExecuteHam( Ham_IsBSPModel, pHit ) )
			return;

		UTIL_GunshotDecalTrace( pHit, vecEnd );

		if ( iPointContents == CONTENTS_WATER )
			return;

		static Vector3( vecPlaneNormal ); global_get( glb_trace_plane_normal, vecPlaneNormal );

	#if defined _api_smokewallpuff_included
		zc_smoke_wallpuff_draw( vecEnd, vecPlaneNormal );
	#endif

		xs_vec_mul_scalar( vecPlaneNormal, random_float( 25.0, 30.0 ), vecPlaneNormal );
		UTIL_TE_STREAK_SPLASH( MSG_PAS, vecEnd, vecPlaneNormal, 4, random_num( 10, 20 ), 3, 64 );
	}
	 
	/* ~ [ HamSandwich ] ~ */
	public Ham_CWeapon_Spawn_Post( const pItem ) 
	{
		if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return;

		SetWeaponClip( pItem, WeaponMaxClip );

		set_member( pItem, m_Weapon_iDefaultAmmo, WeaponDefaultAmmo );

	#if defined WeaponListDir
		rg_set_iteminfo( pItem, ItemInfo_pszName, WeaponListDir );
	#endif
		rg_set_iteminfo( pItem, ItemInfo_iMaxClip, WeaponMaxClip );
		rg_set_iteminfo( pItem, ItemInfo_iMaxAmmo1, WeaponMaxAmmo );
	}
#endif

public Ham_CWeapon_Deploy_Post( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	new pPlayer = get_member( pItem, m_pPlayer );
	new bitsWeaponState = GetWeaponState( pItem );

	set_entvar( pPlayer, var_viewmodel, WeaponModelView );
	set_entvar( pPlayer, var_weaponmodel, WeaponModelPlayer );
	set_entvar( pItem, var_body, bitsWeaponState ? ChargedWeaponBody : 0 );

	if ( BIT_VALID( bitsWeaponState, WeaponState_HasMode ) )
		UTIL_PlayTimingSound( pPlayer, pItem, CHAN_STATIC, WeaponSounds[ Sound_Mode_Idle ], 9.0 );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Dummy );

	set_member( pItem, m_flLastEventCheck, get_gametime( ) + 0.1 );
	set_member( pItem, m_Weapon_flAccuracy, WeaponAccuracy );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Draw_Time + 0.1 );
	set_member( pPlayer, m_flNextAttack, WeaponAnim_Draw_Time );
#if defined _reapi_included
	set_member( pPlayer, m_szAnimExtention, WeaponAnimation );
#else
	set_pdata_string( pPlayer, m_szAnimExtention * 4, WeaponAnimation, -1, linux_diff_player * linux_diff_animating );
#endif
}

public Ham_CWeapon_Holster_Post( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return;

	new pPlayer = get_member( pItem, m_pPlayer );

#if defined _api_muzzleflash_included
	if ( is_user_connected( pPlayer ) && !is_user_bot( pPlayer ) )
		zc_muzzle_destroy( pPlayer );
#endif

	UTIL_ResetTimingSound( pPlayer, pItem, CHAN_STATIC, WeaponSounds[ Sound_Mode_Idle ] );

	CBasePlayerWeapon__ResetChargeMode( pItem, pPlayer );

	set_member( pItem, m_Weapon_flTimeWeaponIdle, 1.0 );
	set_member( pPlayer, m_flNextAttack, 1.0 );
}

#if defined WeaponListDir
	public Ham_CWeapon_AddToPlayer_Post( const pItem, const pPlayer ) 
	{
		if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return;

	#if defined _reapi_included
		UTIL_WeaponList( MSG_ONE, pPlayer, pItem );
	#else
		UTIL_WeaponList( MSG_ONE, pPlayer, WeaponListDir );
	#endif
	}
#endif

public Ham_CWeapon_PostFrame_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	static pPlayer; pPlayer = get_member( pItem, m_pPlayer );
	if ( BIT_VALID( GetWeaponState( pItem ), WeaponState_HasMode ) )
		UTIL_PlayTimingSound( pPlayer, pItem, CHAN_STATIC, WeaponSounds[ Sound_Mode_Idle ], 9.0 );

#if !defined _reapi_included
	if ( get_member( pItem, m_Weapon_fInReload ) )
	{
		new iClip = GetWeaponClip( pItem );
		new iAmmoType = GetWeaponAmmoType( pItem );
		new iAmmo = GetWeaponAmmo( pPlayer, iAmmoType );
		new iReloadClip = min( WeaponMaxClip - iClip, iAmmo );

		SetWeaponClip( pItem, iClip + iReloadClip );
		SetWeaponAmmo( pPlayer, iAmmo - iReloadClip, iAmmoType );
		set_member( pItem, m_Weapon_fInReload, false );
	}
#endif

	return HAM_IGNORED;
}

#if !defined _reapi_included
	public Ham_CWeapon_Reload_Pre( const pItem )
	{
		if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return HAM_IGNORED;

		new pPlayer = get_member( pItem, m_pPlayer );

		if ( !GetWeaponAmmo( pPlayer, GetWeaponAmmoType( pItem ) ) )
			return HAM_SUPERCEDE;

		new iClip = GetWeaponClip( pItem );
		if ( iClip >= WeaponMaxClip )
			return HAM_SUPERCEDE;

		SetWeaponClip( pItem, 0 );
		ExecuteHam( Ham_Weapon_Reload, pItem );
		SetWeaponClip( pItem, iClip );

		CBasePlayerWeapon__ResetChargeMode( pItem, pPlayer );
		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Reload );

		set_member( pItem, m_Weapon_fInReload, true );
		set_member( pPlayer, m_flNextAttack, WeaponAnim_Reload_Time );
		set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Reload_Time );

		return HAM_SUPERCEDE;
	}
#else
	public Ham_CWeapon_Reload_Post( const pItem ) 
	{
		if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
			return;

		new pPlayer = get_member( pItem, m_pPlayer );

		if ( !GetWeaponAmmo( pPlayer, GetWeaponAmmoType( pItem ) ) )
			return;

		if ( GetWeaponClip( pItem ) >= rg_get_iteminfo( pItem, ItemInfo_iMaxClip ) )
			return;

		CBasePlayerWeapon__ResetChargeMode( pItem, pPlayer );
		UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Reload );

		set_member( pPlayer, m_flNextAttack, WeaponAnim_Reload_Time );
		set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Reload_Time );
	}
#endif

public Ham_CWeapon_WeaponIdle_Pre( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	if ( Float: get_member( pItem, m_Weapon_flTimeWeaponIdle ) > 0.0 )
		return HAM_IGNORED;

	new pPlayer = get_member( pItem, m_pPlayer );

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponAnim_Idle );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Idle_Time );

	return HAM_SUPERCEDE;
}

public Ham_CWeapon_PrimaryAttack_Pre( const pItem ) 
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	if ( !CBasePlayerWeapon__Fire( pItem ) )
	{
		ExecuteHam( Ham_Weapon_PlayEmptySound, pItem );
		set_member( pItem, m_Weapon_flNextPrimaryAttack, 0.2 );
	}

	return HAM_SUPERCEDE;
}

public Ham_CWeapon_SecondaryAttack_Pre( const pItem )
{
	if ( !IsCustomWeapon( pItem, WeaponUnicalIndex ) )
		return HAM_IGNORED;

	new pPlayer = get_member( pItem, m_pPlayer );
	new bitsWeaponState = GetWeaponState( pItem );

	if ( get_member( pPlayer, m_iFOV ) == DEFAULT_NO_ZOOM )
	{
		// Block zoom if mode not ready
		if ( !BIT_VALID( bitsWeaponState, WeaponState_HasMode ) )
			return HAM_SUPERCEDE;

		set_member( pPlayer, m_iFOV, ChargedWeaponFOV );

		// Set mode
		BIT_ADD( bitsWeaponState, WeaponState_OnMode );
		SetWeaponState( pItem, bitsWeaponState );
	}
	else
	{
	#if defined DontWasteModeIfDontShoots
		if ( !BIT_VALID( bitsWeaponState, WeaponState_UsedMode ) )
		{
			BIT_SUB( bitsWeaponState, WeaponState_OnMode );
			SetWeaponState( pItem, bitsWeaponState );
		}
		else
	#endif
		{
			UTIL_ResetTimingSound( pPlayer, pItem, CHAN_STATIC, WeaponSounds[ Sound_Mode_Idle ] );

			// Reset mode
			CBasePlayerWeapon__ResetChargeMode( pItem, pPlayer );
			set_member( pItem, m_Weapon_flTimeWeaponIdle, 0.01 );
		}

		set_member( pPlayer, m_iFOV, DEFAULT_NO_ZOOM );
	}

	set_member( pItem, m_Weapon_flNextSecondaryAttack, 0.2 );

	return HAM_SUPERCEDE;
}

#if !defined _reapi_included
	public Ham_CEntity_TraceAttack_Pre( const pVictim, const pAttacker, const Float: flDamage )
	{
		if ( !is_user_connected( pAttacker ) )
			return;

		static pActiveItem; pActiveItem = get_member( pAttacker, m_pActiveItem );
		if ( is_nullent( pActiveItem ) || !IsCustomWeapon( pActiveItem, WeaponUnicalIndex ) )
			return;

		SetHamParamFloat( 3, flDamage * WeaponDamageMultiplier[ WeaponOnMode( GetWeaponState( pActiveItem ) ) ] );
	}
#endif

/* ~ [ Other ] ~ */
public bool: CBasePlayer__GiveWeapon( const pPlayer )
{
	if ( !is_user_alive( pPlayer ) )
		return false;

	new pItem = rg_give_custom_item( pPlayer, WeaponReference, GT_DROP_AND_REPLACE, WeaponUnicalIndex );
	if ( is_nullent( pItem ) )
		return false;

	new iAmmoType = GetWeaponAmmoType( pItem );
	if ( GetWeaponAmmo( pPlayer, iAmmoType ) < WeaponDefaultAmmo )
		SetWeaponAmmo( pPlayer, WeaponDefaultAmmo, iAmmoType );

#if !defined _reapi_included
	SetWeaponClip( pItem, WeaponMaxClip );
#endif

	return true;
}

public bool: CBasePlayerWeapon__Fire( const pItem )
{
	new iClip = GetWeaponClip( pItem );
	if ( !iClip )
		return false;

	new pPlayer = get_member( pItem, m_pPlayer );
	new bitsFlags = get_entvar( pPlayer, var_flags );
	new Vector3( vecVelocity ); get_entvar( pPlayer, var_velocity, vecVelocity );

	new bitsWeaponState = GetWeaponState( pItem );
	CBasePlayerWeapon__CheckCharge( pItem, pPlayer, bitsWeaponState );

#if defined DontWasteModeIfDontShoots
	if ( WeaponOnMode( bitsWeaponState ) && !BIT_VALID( bitsWeaponState, WeaponState_UsedMode ) )
		SetWeaponState( pItem, bitsWeaponState|WeaponState_UsedMode );
#endif

#if defined _reapi_included
	new Float: flAccuracy = get_member( pItem, m_Weapon_flAccuracy );
	new Float: flSpread;

	if ( ~bitsFlags & FL_ONGROUND )
		flSpread = 0.035 + ( 0.45 * flAccuracy );
	else if ( xs_vec_len_2d( vecVelocity ) > 140.0 )
		flSpread = 0.035 + ( 0.75 * flAccuracy );
	else flSpread = 0.02 * flAccuracy;

	new iShotsFired = get_member( pItem, m_Weapon_iShotsFired ); iShotsFired++;
	if ( flAccuracy ) 
		flAccuracy = floatmin( ( ( iShotsFired * iShotsFired * iShotsFired ) / 220.0 ) + 0.3, 1.0 );

	new Vector3( vecSrc ); UTIL_GetEyePosition( pPlayer, vecSrc );
	new Vector3( vecAiming ); UTIL_GetVectorAiming( pPlayer, vecAiming );

	rg_set_animation( pPlayer, PLAYER_ATTACK1 );

	EnableHookChain( gl_HookChain_IsPenetrableEntity_Post );
	rg_fire_bullets3( pItem, pPlayer, vecSrc, vecAiming, flSpread, WeaponShotDistance, WeaponShotPenetration, WeaponBulletType, WeaponDamage[ WeaponOnMode( bitsWeaponState ) ], WeaponRangeModifier, false, get_member( pPlayer, random_seed ) );
	DisableHookChain( gl_HookChain_IsPenetrableEntity_Post );

	SetWeaponClip( pItem, --iClip );
	set_member( pItem, m_Weapon_flAccuracy, flAccuracy );
	set_member( pItem, m_Weapon_iShotsFired, iShotsFired );
#else
	static _FM_Hook_PlayBackEvent_Pre; _FM_Hook_PlayBackEvent_Pre = register_forward( FM_PlaybackEvent, "FM_Hook_PlaybackEvent_Pre", false );
	static _FM_Hook_TraceLine_Post; _FM_Hook_TraceLine_Post = register_forward( FM_TraceLine, "FM_Hook_TraceLine_Post", true );
	ToggleTraceAttack( true );

	ExecuteHam( Ham_Weapon_PrimaryAttack, pItem );

	unregister_forward( FM_PlaybackEvent, _FM_Hook_PlayBackEvent_Pre );
	unregister_forward( FM_TraceLine, _FM_Hook_TraceLine_Post, true );
	ToggleTraceAttack( false );
#endif

	UTIL_SendWeaponAnim( MSG_ONE, pPlayer, pItem, WeaponOnMode( bitsWeaponState ) ? random_num( WeaponAnim_Shoot2, WeaponAnim_Shoot3 ) : WeaponAnim_Shoot1 );
	rh_emit_sound2( pPlayer, 0, CHAN_WEAPON, WeaponSounds[ Sound_Shoot ] );

#if defined _api_muzzleflash_included
	zc_muzzle_draw( pPlayer, gl_iMuzzleId[ WeaponOnMode( bitsWeaponState ) ? Muzzle_ShootB : Muzzle_Shoot ] );
#endif

	if ( xs_vec_len_2d( vecVelocity ) > 0.0 )
		UTIL_WeaponKickBack( pItem, pPlayer, 1.0, 0.45, 0.28, 0.04, 4.25, 2.5, 7 );
	else if ( ~bitsFlags & FL_ONGROUND )
		UTIL_WeaponKickBack( pItem, pPlayer, 1.25, 0.45, 0.22, 0.18, 6.0, 4.0, 5 );
	else if ( bitsFlags & FL_DUCKING )
		UTIL_WeaponKickBack( pItem, pPlayer, 0.6, 0.35, 0.2, 0.0125, 3.7, 2.0, 10 );
	else
		UTIL_WeaponKickBack( pItem, pPlayer, 0.625, 0.375, 0.25, 0.0125, 4.0, 2.25, 9 );

#if defined WeaponModelShell
	set_member( pItem, m_Weapon_iShellId, gl_iszModelIndex_Shell );
	set_member( pPlayer, m_flEjectBrass, get_gametime( ) );
#endif

	set_member( pItem, m_Weapon_flNextPrimaryAttack, WeaponRate[ WeaponOnMode( bitsWeaponState ) ] );
	set_member( pItem, m_Weapon_flNextSecondaryAttack, WeaponRate[ WeaponOnMode( bitsWeaponState ) ] );
	set_member( pItem, m_Weapon_flTimeWeaponIdle, WeaponAnim_Shoot_Time );

	return true;
}

public CBasePlayerWeapon__CheckCharge( const pItem, const pPlayer, &bitsWeaponState )
{
	if ( bitsWeaponState )
		return;

	new iChargedMode = get_entvar( pItem, var_charged_mode );
	if ( ++iChargedMode && iChargedMode >= ChargedWeaponShoots )
	{
		iChargedMode = 0;
		BIT_ADD( bitsWeaponState, WeaponState_HasMode );

		UTIL_PlayTimingSound( pPlayer, pItem, CHAN_STATIC, WeaponSounds[ Sound_Mode_Idle ], 9.0 );

		SetWeaponState( pItem, bitsWeaponState );
		set_entvar( pItem, var_body, ChargedWeaponBody );
	}

	set_entvar( pItem, var_charged_mode, iChargedMode );
}

public CBasePlayerWeapon__ResetChargeMode( const pItem, const pPlayer )
{
	new bitsWeaponState = GetWeaponState( pItem );
	if ( !WeaponOnMode( bitsWeaponState ) )
		return;

#if defined DontWasteModeIfDontShoots
	if ( !BIT_VALID( bitsWeaponState, WeaponState_UsedMode ) )
		return;
#endif

	SetWeaponState( pItem, 0 );

	set_entvar( pItem, var_body, 0 );
	set_entvar( pItem, var_charged_mode, 0 );
}

public CBasePlayerWeapon__ClawsDamage( const pAttacker, pVictim )
{
	static pActiveItem; pActiveItem = get_member( pAttacker, m_pActiveItem );
	if ( is_nullent( pActiveItem ) || !IsCustomWeapon( pActiveItem, WeaponUnicalIndex ) )
		return;

	if ( !WeaponOnMode( GetWeaponState( pActiveItem ) ) )
		return;

	if ( !is_user_alive( pVictim ) )
		return;

#if defined _zombieplague_included
	if ( !zp_get_user_zombie( pVictim ) )
#else
	if ( IsSimilarPlayersTeam( pVictim, pAttacker ) )
#endif
		return;

	static Vector3( vecOrigin ); get_entvar( pVictim, var_origin, vecOrigin );

	UTIL_TE_EXPLOSION( MSG_PVS, gl_iszModelIndex[ random( gl_iClawsSprites ) ], vecOrigin, 0.0, 8, 12 );
	rh_emit_sound2( pVictim, 0, CHAN_STATIC, WeaponSounds[ random_num( Sound_Claw1, Sound_Claw4 ) ] );

	static Vector3( vecVictimOrigin );

	for ( pVictim = 1; pVictim <= gl_iMaxPlayers; pVictim++ )
	{
		if ( !is_user_alive( pVictim ) )
			continue;

	#if defined _zombieplague_included
		if ( !zp_get_user_zombie( pVictim ) )
	#else
		if ( IsSimilarPlayersTeam( pVictim, pAttacker ) )
	#endif
			continue;

		if ( get_entvar( pVictim, var_takedamage ) == DAMAGE_NO )
			continue;

		get_entvar( pVictim, var_origin, vecVictimOrigin );
		if ( xs_vec_distance( vecOrigin, vecVictimOrigin ) > ChargedWeaponClawsRadius )
			continue;

		set_member( pVictim, m_LastHitGroup, HIT_GENERIC );
		ExecuteHamB( Ham_TakeDamage, pVictim, pActiveItem, pAttacker, ChargedWeaponClawsDamage, ChargedWeaponClawsDamageType );
	
		set_member( pVictim, m_flVelocityModifier, ChargedWeaponClawsPainShock );
	}
}

/* ~ [ Stocks ] ~ */
#if !defined _reapi_included
	ToggleTraceAttack( const bool: bEnabled )
	{
		for ( new i; i < sizeof gl_HamHook_TraceAttack; i++ )
			bEnabled ? EnableHamForward( gl_HamHook_TraceAttack[ i ] ) : DisableHamForward( gl_HamHook_TraceAttack[ i ] );
	}
#endif

#if !defined _zombieplague_included
	stock bool: IsSimilarPlayersTeam( const pPlayer, const pTarget )
	{
		return bool: ( get_member( pPlayer, m_iTeam ) == get_member( pTarget, m_iTeam ) );
	}
#endif

#if defined PrecacheSoundsFromModel
	/* -> Automaticly precache Sounds from Model <- */
	/**
	 * This stock is not needed if you use ReHLDS
	 * with this console command 'sv_auto_precache_sounds_in_models 1'
	 **/
	stock UTIL_PrecacheSoundsFromModel( const szModelPath[ ] )
	{
		new pFile;
		if ( !( pFile = fopen( szModelPath, "rt" ) ) )
			return;
		
		new szSoundPath[ 64 ];
		new iNumSeq, iSeqIndex;
		new iEvent, iNumEvents, iEventIndex;
		
		fseek( pFile, 164, SEEK_SET );
		fread( pFile, iNumSeq, BLOCK_INT );
		fread( pFile, iSeqIndex, BLOCK_INT );
		
		for ( new i = 0; i < iNumSeq; i++ )
		{
			fseek( pFile, iSeqIndex + 48 + 176 * i, SEEK_SET );
			fread( pFile, iNumEvents, BLOCK_INT );
			fread( pFile, iEventIndex, BLOCK_INT );
			fseek( pFile, iEventIndex + 176 * i, SEEK_SET );
			
			for ( new k = 0; k < iNumEvents; k++ )
			{
				fseek( pFile, iEventIndex + 4 + 76 * k, SEEK_SET );
				fread( pFile, iEvent, BLOCK_INT );
				fseek( pFile, 4, SEEK_CUR );
				
				if ( iEvent != 5004 )
					continue;
				
				fread_blocks( pFile, szSoundPath, 64, BLOCK_CHAR );
				
				if ( strlen( szSoundPath ) )
				{
					strtolower( szSoundPath );

				#if AMXX_VERSION_NUM < 190
					format( szSoundPath, charsmax( szSoundPath ), "sound/%s", szSoundPath );
					engfunc( EngFunc_PrecacheGeneric, szSoundPath );
				#else
					engfunc( EngFunc_PrecacheGeneric, fmt( "sound/%s", szSoundPath ) );
				#endif
				}
			}
		}
		
		fclose( pFile );
	}
#endif

#if defined WeaponListDir
	/* -> Automaticly precache WeaponList <- */
	stock UTIL_PrecacheWeaponList( const szWeaponList[ ] )
	{
		new szBuffer[ 128 ], pFile;

		format( szBuffer, charsmax( szBuffer ), "sprites/%s.txt", szWeaponList );
		engfunc( EngFunc_PrecacheGeneric, szBuffer );

		if ( !( pFile = fopen( szBuffer, "rb" ) ) )
			return;

		new szSprName[ 64 ], iPos;
		while ( !feof( pFile ) ) 
		{
			fgets( pFile, szBuffer, charsmax( szBuffer ) );
			trim( szBuffer );

			if ( !strlen( szBuffer ) ) 
				continue;

			if ( ( iPos = containi( szBuffer, "640" ) ) == -1 )
				continue;
					
			format( szBuffer, charsmax( szBuffer ), "%s", szBuffer[ iPos + 3 ] );		
			trim( szBuffer );

			strtok( szBuffer, szSprName, charsmax( szSprName ), szBuffer, charsmax( szBuffer ), ' ', 1 );
			trim( szSprName );

		#if AMXX_VERSION_NUM < 190
			format( szSprName, charsmax( szSprName ), "sprites/%s.spr", szSprName );
			engfunc( EngFunc_PrecacheGeneric, szSprName );
		#else
			engfunc( EngFunc_PrecacheGeneric, fmt( "sprites/%s.spr", szSprName ) );
		#endif
		}

		fclose( pFile );
	}

	/* -> Weapon List <- */
	#if defined _reapi_included
		stock UTIL_WeaponList( const iDest, const pReceiver, const pItem, szWeaponName[ MAX_NAME_LENGTH ] = "", const iPrimaryAmmoType = -2, iMaxPrimaryAmmo = -2, iSecondaryAmmoType = -2, iMaxSecondaryAmmo = -2, iSlot = -2, iPosition = -2, iWeaponId = -2, iFlags = -2 ) 
		{
			if ( szWeaponName[ 0 ] == EOS )
				rg_get_iteminfo( pItem, ItemInfo_pszName, szWeaponName, charsmax( szWeaponName ) )

			static iMsgId_Weaponlist; if ( !iMsgId_Weaponlist ) iMsgId_Weaponlist = get_user_msgid( "WeaponList" );

			message_begin( iDest, iMsgId_Weaponlist, .player = pReceiver );
			write_string( szWeaponName );
			write_byte( ( iPrimaryAmmoType <= -2 ) ? GetWeaponAmmoType( pItem ) : iPrimaryAmmoType );
			write_byte( ( iMaxPrimaryAmmo <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iMaxAmmo1 ) : iMaxPrimaryAmmo );
			write_byte( ( iSecondaryAmmoType <= -2 ) ? get_member( pItem, m_Weapon_iSecondaryAmmoType ) : iSecondaryAmmoType );
			write_byte( ( iMaxSecondaryAmmo <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iMaxAmmo2 ) : iMaxSecondaryAmmo );
			write_byte( ( iSlot <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iSlot ) : iSlot );
			write_byte( ( iPosition <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iPosition ) : iPosition );
			write_byte( ( iWeaponId <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iId ) : iWeaponId );
			write_byte( ( iFlags <= -2 ) ? rg_get_iteminfo( pItem, ItemInfo_iFlags ) : iFlags );
			message_end( );
		}
	#else
		stock UTIL_WeaponList( const iDist, const pReceiver, const szWeaponName[ ], const iPrimaryAmmoType = -2, iMaxPrimaryAmmo = -2, iSecondaryAmmoType = -2, iMaxSecondaryAmmo = -2, iSlot = -2, iPosition = -2, iWeaponId = -2, iFlags = -2 ) 
		{
			static iMsgId_Weaponlist; if ( !iMsgId_Weaponlist ) iMsgId_Weaponlist = get_user_msgid( "WeaponList" );
			static const iWeaponList[ ] = {
				4, 90, -1, -1, 0, 10,27, 0 // weapon_sg552
			};

			message_begin( iDist, iMsgId_Weaponlist, .player = pReceiver );
			write_string( szWeaponName );
			write_byte( ( iPrimaryAmmoType <= -2 ) ? iWeaponList[ 0 ] : iPrimaryAmmoType );
			write_byte( ( iMaxPrimaryAmmo <= -2 ) ? iWeaponList[ 1 ] : iMaxPrimaryAmmo );
			write_byte( ( iSecondaryAmmoType <= -2 ) ? iWeaponList[ 2 ] : iSecondaryAmmoType );
			write_byte( ( iMaxSecondaryAmmo <= -2 ) ? iWeaponList[ 3 ] : iMaxSecondaryAmmo );
			write_byte( ( iSlot <= -2 ) ? iWeaponList[ 4 ] : iSlot );
			write_byte( ( iPosition <= -2 ) ? iWeaponList[ 5 ] : iPosition );
			write_byte( ( iWeaponId <= -2 ) ? iWeaponList[ 6 ] : iWeaponId );
			write_byte( ( iFlags <= -2 ) ? iWeaponList[ 7 ] : iFlags );
			message_end( );
		}
	#endif
#endif

/* -> Weapon Animation <- */
stock UTIL_SendWeaponAnim( const iDest, const pReceiver, const pItem, const iAnim ) 
{
	static iBody; iBody = get_entvar( pItem, var_body );
	set_entvar( pReceiver, var_weaponanim, iAnim );

	message_begin( iDest, SVC_WEAPONANIM, .player = pReceiver );
	write_byte( iAnim );
	write_byte( iBody );
	message_end( );

	if ( get_entvar( pReceiver, var_iuser1 ) )
		return;

	static i, iCount, pSpectator, aSpectators[ MAX_PLAYERS ];
	get_players( aSpectators, iCount, "bch" );

	for ( i = 0; i < iCount; i++ )
	{
		pSpectator = aSpectators[ i ];

		if ( get_entvar( pSpectator, var_iuser1 ) != OBS_IN_EYE )
			continue;

		if ( get_entvar( pSpectator, var_iuser2 ) != pReceiver )
			continue;

		set_entvar( pSpectator, var_weaponanim, iAnim );

		message_begin( iDest, SVC_WEAPONANIM, .player = pSpectator );
		write_byte( iAnim );
		write_byte( iBody );
		message_end( );
	}
}

/* -> Get Weapon Box Item <- */
stock UTIL_GetWeaponBoxItem( const pWeaponBox )
{
	for ( new iSlot, pItem; iSlot < MAX_ITEM_TYPES; iSlot++ )
	{
		if ( !is_nullent( ( pItem = get_member( pWeaponBox, m_WeaponBox_rgpPlayerItems, iSlot ) ) ) )
			return pItem;
	}
	return NULLENT;
}

/* -> Gunshot Decal Trace <- */
stock UTIL_GunshotDecalTrace( const pEntity, const Vector3( vecOrigin ) )
{	
	new iDecalId = UTIL_DamageDecal( pEntity );
	if ( iDecalId == -1 )
		return;

	UTIL_TE_GUNSHOTDECAL( MSG_PAS, vecOrigin, pEntity, iDecalId );
}

stock UTIL_DamageDecal( const pEntity )
{
	new iRenderMode = get_entvar( pEntity, var_rendermode );
	if ( iRenderMode == kRenderTransAlpha )
		return -1;

	static iGlassDecalId; if ( !iGlassDecalId ) iGlassDecalId = engfunc( EngFunc_DecalIndex, "{bproof1" );
	if ( iRenderMode != kRenderNormal )
		return iGlassDecalId;

	static iShotDecalId; if ( !iShotDecalId ) iShotDecalId = engfunc( EngFunc_DecalIndex, "{shot1" );
	return ( iShotDecalId - random_num( 0, 4 ) );
}

/* -> TE_GUNSHOTDECAL <- */
stock UTIL_TE_GUNSHOTDECAL( const iDest, const Vector3( vecOrigin ), const pEntity, const iDecalId )
{
	message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin );
	write_byte( TE_GUNSHOTDECAL );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] );
	write_short( pEntity );
	write_byte( iDecalId );
	message_end( );
}

/* -> TE_STREAK_SPLASH <- */
stock UTIL_TE_STREAK_SPLASH( const iDest, const Vector3( vecOrigin ), const Vector3( vecDirection ), const iColor, const iCount, const iSpeed, const iNoise )
{
	message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin );
	write_byte( TE_STREAK_SPLASH );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] );
	write_coord_f( vecDirection[ 0 ] );
	write_coord_f( vecDirection[ 1 ] );
	write_coord_f( vecDirection[ 2 ] );
	write_byte( iColor );
	write_short( iCount );
	write_short( iSpeed );
	write_short( iNoise );
	message_end( );
}

/* -> TE_EXPLOSION <- */
stock UTIL_TE_EXPLOSION( const iDest, const iszModelIndex, const Vector3( vecOrigin ), const Float: flUp, const iScale, const iFramerate, const bitsFlags = TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES )
{
	message_begin_f( iDest, SVC_TEMPENTITY, vecOrigin );
	write_byte( TE_EXPLOSION );
	write_coord_f( vecOrigin[ 0 ] );
	write_coord_f( vecOrigin[ 1 ] );
	write_coord_f( vecOrigin[ 2 ] + flUp );
	write_short( iszModelIndex );
	write_byte( iScale ); // Scale
	write_byte( iFramerate ); // Framerate
	write_byte( bitsFlags ); // Flags
	message_end( );
}

/* -> Get player eye position <- */
stock UTIL_GetEyePosition( const pPlayer, Vector3( vecEyeLevel ) )
{
	static Vector3( vecOrigin ); get_entvar( pPlayer, var_origin, vecOrigin );
	static Vector3( vecViewOfs ); get_entvar( pPlayer, var_view_ofs, vecViewOfs );

	xs_vec_add( vecOrigin, vecViewOfs, vecEyeLevel );
}

/* -> Get Player vector Aiming <- */
stock UTIL_GetVectorAiming( const pPlayer, Vector3( vecAiming ) ) 
{
	static Vector3( vecViewAngle ); get_entvar( pPlayer, var_v_angle, vecViewAngle );
	static Vector3( vecPunchAngle ); get_entvar( pPlayer, var_punchangle, vecPunchAngle );

	xs_vec_add( vecViewAngle, vecPunchAngle, vecViewAngle );
	angle_vector( vecViewAngle, ANGLEVECTOR_FORWARD, vecAiming );
}

/* -> Weapon Kick Back <- */
stock UTIL_WeaponKickBack( const pItem, const pPlayer, Float: flUpBase, Float: flLateralBase, Float: flUpModifier, Float: flLateralModifier, Float: flUpMax, Float: flLateralMax, iDirectionChange ) 
{
	new Float: flKickUp, Float: flKickLateral;
	new iShotsFired = get_member( pItem, m_Weapon_iShotsFired );
	new iDirection = get_member( pItem, m_Weapon_iDirection );
	new Vector3( vecPunchAngle ); get_entvar( pPlayer, var_punchangle, vecPunchAngle );

	if ( iShotsFired == 1 ) 
	{
		flKickUp = flUpBase;
		flKickLateral = flLateralBase;
	}
	else
	{
		flKickUp = iShotsFired * flUpModifier + flUpBase;
		flKickLateral = iShotsFired * flLateralModifier + flLateralBase;
	}

	vecPunchAngle[ 0 ] -= flKickUp;

	if ( vecPunchAngle[ 0 ] < -flUpMax ) 
		vecPunchAngle[ 0 ] = -flUpMax;

	if ( iDirection ) 
	{
		vecPunchAngle[ 1 ] += flKickLateral;
		if ( vecPunchAngle[ 1 ] > flLateralMax ) 
			vecPunchAngle[ 1 ] = flLateralMax;
	}
	else
	{
		vecPunchAngle[ 1 ] -= flKickLateral;
		if ( vecPunchAngle[ 1 ] < -flLateralMax ) 
			vecPunchAngle[ 1 ] = -flLateralMax;
	}

	if ( !random_num( 0, iDirectionChange ) ) 
		set_member( pItem, m_Weapon_iDirection, !iDirection );

	set_entvar( pPlayer, var_punchangle, vecPunchAngle );
}

stock UTIL_ResetTimingSound( const pPlayer, const pEntity, const iChannel = CHAN_WEAPON, const szSound[ ] )
{
	set_entvar( pEntity, var_next_sound, get_gametime( ) );
	rh_emit_sound2( pPlayer, 0, iChannel, szSound, .flags = SND_STOP );
}

stock bool: UTIL_PlayTimingSound( const pPlayer, const pEntity, const iChannel = CHAN_WEAPON, const szSound[ ], const Float: flSoundTime )
{
	static Float: flGameTime; flGameTime = get_gametime( );
	static Float: flNextSound; get_entvar( pEntity, var_next_sound, flNextSound );
	if ( flNextSound > flGameTime )
		return false;

	rh_emit_sound2( pPlayer, 0, iChannel, szSound );
	set_entvar( pEntity, var_next_sound, flGameTime + flSoundTime );

	return true;
}