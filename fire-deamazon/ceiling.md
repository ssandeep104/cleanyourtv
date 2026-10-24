# The ceiling: what full ownership would need

## Short answer

Without an unlocked bootloader you cannot replace Fire OS. Every Fire TV Stick ships with a locked
bootloader and verified boot, and Amazon offers no official unlock for any consumer Fire TV (DOCUMENT:
[XDA, sheldon unlock](https://www.xda-developers.com/amazon-fire-tv-stick-3-lite-bootloader-unlock-android-11-lineageos-18-1/)).
A replacement OS is only possible on the few models where the community found a hardware or bootrom
exploit. Whether your stick is one of them depends on the codename from audit batch 0.1.

## Why the shell alone cannot get there (DOCUMENT, this repo's own Fire TV lists)

| Limit | Evidence |
|---|---|
| The ADB shell is user `shell`, not root or system. Fire OS marks some Amazon packages "protected", and `pm disable-user` refuses them. | `examples/amazon-fire-tv-stick-lite-2020`, `-4k-2018`, `-4k-2023`: metrics, logmanager, crashmanager, diode, usagestats proxy, ads deeplinking refused. |
| On some Fire OS 7 builds the OTA packages themselves are protected, so updates keep arriving. | `examples/amazon-fire-tv-afteu014`: `com.amazon.device.software.ota` and `.ota.override` refused. |
| Some disabled packages come back at every boot. | `-4k-2018` and `afteu014`: `com.amazon.vizzini` re-enabled at boot. |
| The sponsored hero banner and rows are the stock launcher's own feed; no package list removes them. | Every Fire TV list in `examples/`. Not visible to you day to day, since Couchy is your Home. |
| Amazon's piracy blocklist matches package names against a list Amazon controls; since late 2025 it blocks at launch and then at install, including sideloads. | DOCUMENT: [AFTVnews blacklist tag](https://www.aftvnews.com/tag/blacklist/), [9to5Google](https://9to5google.com/2025/11/12/amazon-fire-tv-piracy-apps-block-sideloading/). Stremio itself is not reported as blocked (UNRESOLVED, see the list). |

## The three tiers

| Tier | What you get | What it needs |
|---|---|---|
| 1. Shell only (this plan) | Unprotected Amazon packages uninstalled or disabled, background limits, update attempts that may or may not stick. | ADB, which you have. |
| 2. System-user exploit (optional, firmware dependent) | One-session `system` user: lets you disable protected packages, OTA updates and Amazon's app blacklist; changes survive reboot, the access does not. | Fire OS 7 at PS7704 or older, or Fire OS 8 at RS8149 or older. Patched in 7.7.0.6 and 8.1.5.3. Not Fire OS 6. A wrong step can boot-loop the stick. DOCUMENT: [AFTVnews](https://www.aftvnews.com/new-fire-tv-exploit-once-again-allows-custom-launchers-disabling-updates-disabling-amazons-app-blacklist-and-more/), [patch report](https://www.aftvnews.com/amazon-patches-fire-tv-exploit-that-allows-custom-launchers-disabling-updates-and-more/), [XDA thread](https://xdaforums.com/t/system-user-fire-cube-stick-tv-tablet-ps7704-fireos7-rs8149-fireos8.4759215/). |
| 3. Bootloader unlock, then root or a new OS | Real ownership: root (Magisk), or an unofficial LineageOS (Android TV) build with no Amazon code at all. | A model with a known exploit (table below), usually opening the case and shorting a test point. |

Tier 2 is not in any batch. It runs as an outside exploit, the official XDA steps assume a computer, and
it carries a boot-loop risk. It is worth a separate decision once we know your build. (DIRECT goal:
updates must not undo the setup; tier 2 is the only no-hardware route that fully gets there.)

## Known unlock paths by model (DOCUMENT, from XDA threads; check each thread's latest page before acting)

| Model | Codename | Known path | Notes |
|---|---|---|---|
| Fire TV Stick 4K (2018) | `mantis` | kamakiri bootrom exploit; unofficial LineageOS builds (14.1 "Revived" on XDA) | Units with serial starting VM190 or higher shipped with download mode disabled and cannot be unlocked. [XDA](https://xdaforums.com/t/unlock-root-twrp-unbrick-fire-tv-stick-4k-mantis.3978459/), [first-hand install write-up](https://neilzone.co.uk/2025/04/installing-lineage-os-on-an-amazon-fire-stick-4k/) |
| Fire TV Stick Lite / 3rd gen (2020) | `sheldon` / `sheldonp` | Exploit by k4y0z; unofficial LineageOS 18.1 and 20 | Never erase the preloader: hard brick with no recovery. [XDA](https://xdaforums.com/t/unlock-root-twrp-unbrick-fire-tv-stick-3-and-fire-tv-stick-lite-sheldon-p.4410297/) |
| Fire TV Stick 4K / 4K Max 2nd gen (2023) | `karat` / `mantra` | A separate exploit for the 2nd-gen family | Does not work on 1st-gen `kara` or `mantis`. [XDA](https://xdaforums.com/t/unlock-root-twrp-unbrick-fire-tv-stick-4k-2nd-gen-series-karat-mantra.4798951/) |
| Fire TV Stick 4K Max (2021) | `kara` | None found | UNRESOLVED: no unlock thread found in this research. |
| Fire TV Stick 2nd gen (2016) | `tank` | Old tooling exists (LineageOS 12.1) | UNRESOLVED: no current unlock thread found. [firestick-loader](https://github.com/esc0rtd3w/firestick-loader) |
| Fire TV Stick 1st gen (2014) | `montoya` | Old tooling exists | UNRESOLVED, same source. |

Your row: **waits for audit batch 0.1** (`ro.product.device`).

## What a new OS costs you (INFERENCE, to verify per build before any decision)

- Netflix and other DRM apps may drop to lower quality or refuse to run if the unofficial build lacks a
  certified Widevine L1. Netflix is on your keep list, so this matters.
- The Alexa remote's voice button and some remote features are Amazon software; on LineageOS the remote
  pairs as a plain Bluetooth remote.
- No more Fire OS security updates; you depend on one hobbyist maintainer.
- Opening the stick and shorting a test point can kill it.

Given your keep list, tier 1 plus (if your build allows) tier 2 is likely the better trade than tier 3.
That is a recommendation, not a decision; it is yours.
