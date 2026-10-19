#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;

// ==========================================================
//  MAX AMMO ESTILO BLACK OPS 4
//  El Max Ammo normal de BO2 solo sube la reserva de munición.
//  Este script, además, llena el cargador (la recámara) de todas las
//  armas, así que ya no hace falta recargar antes de tomar el powerup.
//  No reemplaza el powerup: escucha la notificación que BO2 le envía
//  a cada jugador cuando recibe el Max Ammo ("zmb_max_ammo").
// ==========================================================

init()
{
    level thread on_player_connect();
}

on_player_connect()
{
    level endon("end_game");

    // Jugadores que ya estuvieran conectados
    if(isdefined(level.players))
    {
        foreach(player in level.players)
            player thread watch_max_ammo();
    }

    // Jugadores que se conecten después
    while(true)
    {
        level waittill("connecting", player);
        player thread watch_max_ammo();
    }
}

watch_max_ammo()
{
    self endon("disconnect");

    while(true)
    {
        self waittill("zmb_max_ammo");

        // El powerup notifica justo antes de repartir la munición;
        // esperamos un frame para llenar los cargadores DESPUÉS de que termine
        wait 0.05;

        self refill_all_clips();
    }
}

refill_all_clips()
{
    if(maps\mp\zombies\_zm_laststand::player_is_in_laststand())
        return;

    weapons = self GetWeaponsList(true);

    foreach(weapon in weapons)
    {
        if(!should_refill_clip(weapon))
            continue;

        self SetWeaponAmmoClip(weapon, WeaponClipSize(weapon));

        // Armas dual wield: rellenar también la mano izquierda
        dw_weapon = WeaponDualWieldWeaponName(weapon);
        if(isdefined(dw_weapon) && dw_weapon != "none" && dw_weapon != "" && self HasWeapon(dw_weapon))
            self SetWeaponAmmoClip(dw_weapon, WeaponClipSize(dw_weapon));
    }
}

// Mismas exclusiones que usa el Max Ammo vanilla, más granadas, minas, cuchillos y escudo
should_refill_clip(weapon)
{
    if(is_offhand_weapon(weapon))
        return false;

    if(issubstr(weapon, "shield"))
        return false;

    if(isdefined(level.zombie_include_equipment) && isdefined(level.zombie_include_equipment[weapon]))
        return false;

    if(isdefined(level.zombie_weapons_no_max_ammo) && isdefined(level.zombie_weapons_no_max_ammo[weapon]))
        return false;

    if(WeaponClipSize(weapon) <= 0)
        return false;

    return true;
}
