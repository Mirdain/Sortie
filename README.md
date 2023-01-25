# Sortie
Addon to help keep track of objectives

How it works:

A display should pop up upon entering sortie if loaded prior to entering.

Select your zone by clicking on the [x] zone or typing //st x

Tracking enemies is done via a widescan packet request.

As such - you havae to be in the correct floor to track a mob.

A/B/C/D can be tracked anywhere "upstairs" but each basement must be entered before it can be tracked.

Bitzers are not mobs and thus can only be tracked with in 50 yalms.

Extra commands

//st save - saves profile information
//st debug
//st on/off
//st x - this is the floor you want to see the objectives of
//st track x - tracks the mob by sending a widescan request (Mob index)
//st scan x - tests to see if the mob is found (Mob index)
