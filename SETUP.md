# Join our Project Zomboid co-op game

You need Project Zomboid on Steam. The host runs the server; **you do not need to create or configure a server**.

## 1. Match the game version

Launch Zomboid and check the version shown on its main menu. This pack was prepared for **42.21.0**. Both players must use the same version. If yours differs, check with the host before changing branches or updating an existing save. Close the game before installing the files below.

## 2. Subscribe to the Steam mods

Open each link below while signed into Steam and click **Subscribe**. Let Steam finish the downloads. Detailed Models supplies both DetailedModels and DetailedModelsALICE.

- [ZombieBuddy](https://steamcommunity.com/sharedfiles/filedetails/?id=3619862853)
- [Survivor PDA](https://steamcommunity.com/sharedfiles/filedetails/?id=3826426915)
- [Skully’s Zombie Collision](https://steamcommunity.com/sharedfiles/filedetails/?id=3778511497)
- [Real Limbs](https://steamcommunity.com/sharedfiles/filedetails/?id=3827957976)
- [More Damaged Objects](https://steamcommunity.com/sharedfiles/filedetails/?id=3413150945)
- [Knox Packs](https://steamcommunity.com/sharedfiles/filedetails/?id=3822813865)
- [Detailed Models + ALICE](https://steamcommunity.com/sharedfiles/filedetails/?id=3825976597)
- [Detailed Models Tools](https://steamcommunity.com/sharedfiles/filedetails/?id=3827956263)
- [GarageWorks](https://steamcommunity.com/sharedfiles/filedetails/?id=3827271522)
- [Toot’s Base Defense](https://steamcommunity.com/sharedfiles/filedetails/?id=3825722984)
- [Gunworks Framework](https://steamcommunity.com/sharedfiles/filedetails/?id=3722064198)
- [Guns of Marz](https://steamcommunity.com/sharedfiles/filedetails/?id=3722134990)
- [Project A-Life](https://steamcommunity.com/sharedfiles/filedetails/?id=3803984183)

Do not add Escape From Zomboid, Viewpoint, the old MarzGuns version or WW1Weapons to this co-op setup. Guns of Marz uses **Gunworks → Guns of Marz** load order. Hot Brass is optional according to the Guns of Marz author and is not part of this host profile.

## 3. Install our two local mods

1. Open [the download page](https://github.com/anderote/survivor-arpg/releases/tag/v0.2.0).
2. Under **Assets**, download **SurvivorARPG-Coop-0.2.0.zip**. Use this file, not GitHub's automatically generated “Source code” downloads.
3. Extract/unzip it. Inside `mods`, you will find two folders: **SurvivorARPG** and **Respawn**.
4. Copy those two folders into your Zomboid **mods** folder:

| Computer | Folder |
|---|---|
| Windows | `%USERPROFILE%\Zomboid\mods` — paste this into File Explorer's address bar |
| Mac | `~/Zomboid/mods` — Finder → Go → Go to Folder |
| Linux | `~/Zomboid/mods` |

Create `mods` if it does not exist. This is the **Zomboid folder in your user/home folder**, not the game installation inside Steam. If you already have either mod, move its old folder somewhere safe first, then copy in this version; don't mix versions. Don't also subscribe to a different Respawn version with the same mod ID.

Check these files exist after copying:

```text
Zomboid/mods/SurvivorARPG/42/mod.info
Zomboid/mods/Respawn/42/mod.info
```

If you see `mods/mods/` or an extra ZIP-name folder in the path, move the two mod folders up one level.

## 4. Set up ZombieBuddy once

Real Limbs needs this extra step. **Subscribing on Steam is not enough.** Use the [author's installation instructions](https://steamcommunity.com/sharedfiles/filedetails/?id=3619862853).

### Windows

The easiest method is the author's **ZombieBuddyInstaller.exe**, linked under “Automated Installer” on the Workshop page. Run it, choose **Install or update ZombieBuddy**, and patch **Both** launch modes. Review its changes before applying them; it may ask you to close Steam.

For manual setup, follow the same author's page: copy `ZombieBuddy.jar` and `zbNative.dll` from the downloaded mod's `libs` folder into the Project Zomboid game folder, then set Steam launch options to:

```text
-agentlib:zbNative --
```

### Mac

In your Steam library folder, find:

```text
steamapps/workshop/content/108600/3619862853/mods/ZombieBuddy/libs/ZombieBuddy.jar
```

Copy `ZombieBuddy.jar` into:

```text
steamapps/common/ProjectZomboid/Project Zomboid.app/Contents/Java/
```

In Finder, right-click **Project Zomboid.app → Show Package Contents** to get inside it. In Steam, right-click Project Zomboid → **Properties → General → Launch Options**, and enter:

```text
-javaagent:ZombieBuddy.jar --
```

### Linux

Follow the author's page: copy `ZombieBuddy.jar` to the game's `projectzomboid/` directory and use `-javaagent:ZombieBuddy.jar --` in Steam launch options.

The trailing **`--` is required**. These examples assume an otherwise empty launch-options field. If you already use custom launch options, have the host help combine them. On first launch, ZombieBuddy may ask you to approve the Real Limbs Java mod; check that its name and path match the mod you subscribed to.

## 5. Restart and join

1. Launch Zomboid again. In **Mods**, confirm Survivor ARPG and Respawn appear and enable them with their dependencies. The server chooses the co-op session's active mod list.
2. Wait for the host to start **SurvivorARPG-Coop**, then accept the Steam invitation. Let Steam download any remaining Workshop dependencies when prompted.
3. Create your character and enter the world. Use the same server account/username each time so your RPG progress stays attached to you.
4. Press **K** to open Survivor PDA (unless you changed that key), then go to **Home → Attributes** or **Home → Skills**.

You should see **3 starting attribute points**. Skill points are a separate pool. In multiplayer, RPG upgrades and level are restored automatically on the same server when you respawn; inventory recovery is controlled separately by Respawn.

## If something goes wrong

- **Missing SurvivorARPG or Respawn:** check the folder paths in step 3 and restart the game.
- **Different Lua files / checksum mismatch:** both players need the same game and mod versions. Close the game, let Steam update, and reinstall the exact local ZIP. Don't disable checksum checking.
- **ZombieBuddy not loaded:** revisit step 4. Make sure the JAR/DLL is in the game folder, not only the Workshop folder, and the correct launch option ends in `--`.
- **Waiting for server sync:** allow a few seconds. If it stays there, send the host the error text; the host needs the same add-on enabled in the server profile.
- **Crash:** send the error and the last part of `Zomboid/console.txt` to the host. Don't delete your saves.

This is a test build. Server startup and automated tests pass; our first real co-op session will verify the gameplay pieces together.
