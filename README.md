# Survivor ARPG — co-op setup

A custom add-on for **Project Zomboid Build 42.21** and **Survivor PDA**: three attribute points per level, separate special skills, ammo scavenging, auto-bandaging and persistent RPG progression.

**Joining the co-op game? Follow [START HERE](SETUP.md).** No Git, coding or terminal commands needed.

[Download the co-op ZIP](https://github.com/anderote/survivor-arpg/releases/latest) — choose **SurvivorARPG-Coop-0.2.0.zip** under Assets. This includes our add-on and the exact Respawn version used by the host. Other mods download from Steam Workshop.

## What it adds

- PDA **Home → Attributes**: carrying capacity, firearms, health regeneration, melee strength, endurance, temperature resilience and ammo luck. Starts with 3 attribute points; earns 3 per level.
- PDA **Home → Skills**: Ammo Magnet, Field Medic, Bite Ward and Second Wind. These use the existing PDA skill-point pool, separate from attributes. Original tree resets do not refund these permanent purchases.
- Multiplayer purchases, ranks, awards and cooldowns are server-controlled. RPG progression is saved per server world and username and restored for replacement characters and reconnects.
- Single-player restoration uses the Respawn profession. Multiplayer RPG restoration is automatic; Respawn's separate vanilla-skill/inventory recovery retains its own behavior.

## Current status

**0.2.0 is a multiplayer test build.** Automated progression, isolated server/client, replay-protection and persistence tests pass. A native Build 42.21 server on macOS starts with the co-op mod list. Connected-player UI, combat, loot and respawn playtesting is still pending; full pack stability is not yet established. One local player per client; split-screen is unverified.

## Files

- `mods/SurvivorARPG`: our source and installable mod.
- `mods/Respawn`: pinned, MIT-licensed dependency; source and attribution inside.
- `SETUP.md`: player instructions and Workshop links.
- `workshop-mods.json`: exact mod IDs for this co-op setup.
- `THIRD_PARTY.md`: credits and licensing.

Only our code and the MIT-licensed Respawn dependency are distributed here. No game files or other Workshop mods are bundled.

## Development checks

With Python installed, create a virtual environment, install `requirements-dev.txt`, then run:

```sh
python tests/test_mod.py
python tests/test_multiplayer.py
```

These execute Lua code in engine mocks and separate server/client VMs. They do not replace a two-player game test.
