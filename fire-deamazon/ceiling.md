# The ceiling: what full ownership would need

## Your stick (AUDIT, batch 0.1)

| Property | Value |
|---|---|
| Model | `AFTSS`: Fire TV Stick Lite, 1st gen (2020) |
| Codename | `sheldon` |
| SoC | MediaTek `mt8695` |
| Fire OS | 7.7.1.7 (PS7717/5741), build `PS7717.5741N` |
| Android | 9, SDK 28 |
| Security patch | 2026-03-01 |
| Verified boot | `green` (locked bootloader, stock image intact) |

## Verdict: shell-only on this build

**No bootloader unlock and no system-user path applies to your stick as it stands. We are shell-only
(tier 1).** A true replacement OS is not possible on this firmware with any method we can verify.

Why, one path at a time:

1. **Bootloader unlock for sheldon: closed on PS7717.** The sheldon unlock (k4y0z, kamakiri tooling)
   needs Fire OS older than 7.2.7.3; later updates shipped a preloader patch that fixed the exploit.
   Posts disagree on the exact cutoff (7.2.7.3 or 7.2.8.5), but both are far below your 7.7.1.7.
   DOCUMENT: [root guide, "Require FireOS < 7.2.7.3"](https://github.com/emtee40/root-firestick-sheldon-sheldondp),
   [same limit, second guide](https://github.com/daboynb/Root_firestick),
   [XDA unlock thread](https://xdaforums.com/t/unlock-root-twrp-unbrick-fire-tv-stick-3-and-fire-tv-stick-lite-sheldon-p.4410297/page-3).
   `verifiedbootstate = green` confirms the stick has never been unlocked.
2. **Downgrading to an unlockable build: not possible from the shell.** Installing older firmware needs
   root or an unlocked bootloader first, the same lock we are trying to get past (INFERENCE, consistent
   with every source above; none describes a shell-only downgrade on Fire OS 7.7).
3. **Hardware test-point route: unverified on patched firmware.** XDA describes wiring eMMC test points
   to an FT232H adapter. No source found says it gets past the preloader patch on newer builds, and it
   means opening the stick, soldering, and a computer, which is outside this project. UNRESOLVED (U10),
   kept out of the plan.
4. **System-user exploit: closed.** It works only up to PS7704 on Fire OS 7 and was patched in 7.7.0.6.
   Your PS7717 is newer. DOCUMENT: [patch report](https://www.aftvnews.com/amazon-patches-fire-tv-exploit-that-allows-custom-launchers-disabling-updates-and-more/).

What shell-only means for your goals, plainly:

- Protected Amazon packages stay. This repo already has a list for **your exact build**
  (`examples/amazon-fire-tv-stick-lite-2020/`, AFTSS, PS7717/5741): `pm disable-user` refused
  `com.amazon.minerva.client.api`, `com.amazon.device.logmanager`, `com.amazon.device.crashmanager`,
  `com.amazon.diode` and `com.fireos.usagestats.proxy` there. Expect the same here (DOCUMENT).
- Updates: we try to disable the OTA packages; if Fire OS refuses, updates keep arriving and may
  re-enable packages. Batch 0.9 tells us which case applies.
- Amazon's app blacklist: cannot be switched off with confidence from the shell (U2).
- **Uninstall for user 0 is refused** on this build (AUDIT, stage A1: `DELETE_FAILED_INTERNAL_ERROR`). Amazon
  packages can be disabled, not removed for your user; a disabled package cannot run, but stays listed.
- **Alexa voice core cannot stay off:** `com.amazon.vizzini` was disabled in B7 and Fire OS re-enabled it at the
  next boot (AUDIT). It stays, at about 23 MB resident.
- Everything else in the goal (disable, background limits) is reachable.

## General background

Every Fire TV Stick ships with a locked bootloader and verified boot, and Amazon offers no official unlock
for any consumer Fire TV (DOCUMENT:
[XDA, sheldon unlock](https://www.xda-developers.com/amazon-fire-tv-stick-3-lite-bootloader-unlock-android-11-lineageos-18-1/)).
A replacement OS is only possible where the community found a hardware or bootrom exploit, and only on the
firmware that exploit works on.

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
| 1. Shell only (this plan; **your stick**) | Unprotected Amazon packages uninstalled or disabled, background limits, update attempts that may or may not stick. | ADB, which you have. |
| 2. System-user exploit (**closed on PS7717**) | One-session `system` user: lets you disable protected packages, OTA updates and Amazon's app blacklist; changes survive reboot, the access does not. | Fire OS 7 at PS7704 or older, or Fire OS 8 at RS8149 or older. Patched in 7.7.0.6 and 8.1.5.3. Not Fire OS 6. A wrong step can boot-loop the stick. DOCUMENT: [AFTVnews](https://www.aftvnews.com/new-fire-tv-exploit-once-again-allows-custom-launchers-disabling-updates-disabling-amazons-app-blacklist-and-more/), [patch report](https://www.aftvnews.com/amazon-patches-fire-tv-exploit-that-allows-custom-launchers-disabling-updates-and-more/), [XDA thread](https://xdaforums.com/t/system-user-fire-cube-stick-tv-tablet-ps7704-fireos7-rs8149-fireos8.4759215/). |
| 3. Bootloader unlock, then root or a new OS (**closed on PS7717**) | Real ownership: root (Magisk), or an unofficial LineageOS (Android TV) build with no Amazon code at all. | A model with a known exploit (table below), usually opening the case and shorting a test point. |

Tiers 2 and 3 are not in any batch: neither works on your build (see the verdict above).

## Known unlock paths by model (DOCUMENT, from XDA threads; check each thread's latest page before acting)

| Model | Codename | Known path | Notes |
|---|---|---|---|
| Fire TV Stick 4K (2018) | `mantis` | kamakiri bootrom exploit; unofficial LineageOS builds (14.1 "Revived" on XDA) | Units with serial starting VM190 or higher shipped with download mode disabled and cannot be unlocked. [XDA](https://xdaforums.com/t/unlock-root-twrp-unbrick-fire-tv-stick-4k-mantis.3978459/), [first-hand install write-up](https://neilzone.co.uk/2025/04/installing-lineage-os-on-an-amazon-fire-stick-4k/) |
| Fire TV Stick Lite / 3rd gen (2020) | `sheldon` / `sheldonp` | Exploit by k4y0z; unofficial LineageOS 18.1 and 20 | **Only on Fire OS older than 7.2.7.3** (preloader patch after that). Never erase the preloader: hard brick with no recovery. [XDA](https://xdaforums.com/t/unlock-root-twrp-unbrick-fire-tv-stick-3-and-fire-tv-stick-lite-sheldon-p.4410297/) |
| Fire TV Stick 4K / 4K Max 2nd gen (2023) | `karat` / `mantra` | A separate exploit for the 2nd-gen family | Does not work on 1st-gen `kara` or `mantis`. [XDA](https://xdaforums.com/t/unlock-root-twrp-unbrick-fire-tv-stick-4k-2nd-gen-series-karat-mantra.4798951/) |
| Fire TV Stick 4K Max (2021) | `kara` | None found | UNRESOLVED: no unlock thread found in this research. |
| Fire TV Stick 2nd gen (2016) | `tank` | Old tooling exists (LineageOS 12.1) | UNRESOLVED: no current unlock thread found. [firestick-loader](https://github.com/esc0rtd3w/firestick-loader) |
| Fire TV Stick 1st gen (2014) | `montoya` | Old tooling exists | UNRESOLVED, same source. |

Your row: **`sheldon` on 7.7.1.7, past the cutoff. No path.**

## What a new OS costs you (INFERENCE, to verify per build before any decision)

- Netflix and other DRM apps may drop to lower quality or refuse to run if the unofficial build lacks a
  certified Widevine L1. Netflix is on your keep list, so this matters.
- The Alexa remote's voice button and some remote features are Amazon software; on LineageOS the remote
  pairs as a plain Bluetooth remote.
- No more Fire OS security updates; you depend on one hobbyist maintainer.
- Opening the stick and shorting a test point can kill it.

This section only matters if a future exploit reopens tier 3 for sheldon on newer firmware. Even then,
given your keep list (Netflix in particular), staying on Fire OS may be the better trade. That call is yours.
