# Audit log (AUDIT: pasted from the owner's stick)

Raw findings per batch, kept short. The gap analysis (`01-gap-analysis.md`) is written from this once
batch 0.9 is in.

## 0.1 Device identity

AFTSS (Fire TV Stick Lite 2020), `sheldon`, `mt8695`, Fire OS 7.7.1.7 (PS7717/5741, `PS7717.5741N`),
Android 9 / SDK 28, security patch 2026-03-01, verified boot `green`. Verdict in [ceiling.md](ceiling.md).

## 0.2 Memory and storage

- RAM: 922,268 kB total, 157,924 kB available (about 17%). Tight for a 1 GB stick.
- `/data`: 4.9 GB, 2.4 GB free.

Biggest processes at the time (PSS), grouped:

| Group | Processes | PSS |
|---|---|---|
| YouTube, open in front at the time (DIRECT) | `com.amazon.firetv.youtube` 106 MB | 106 MB |
| Netflix, no activity listed (not on screen) | `com.netflix.ninja` 81 MB | 81 MB |
| Your always-on apps (keep) | `com.nordvpn.android` 104 MB, `com.conreo.couchytv` 28 MB, `io.github.toolicious.homeonfire` 18 MB | 150 MB |
| Prime Video | `com.amazon.firebat` 97 MB | 97 MB |
| Alexa and its media stack | `com.amazon.aca` 39 MB, `com.amazon.vizzini` 23 MB, `com.amazon.alexamediaplayer.runtime.ftv` (+`:smbs`) 21 MB, `com.amazon.whad` 7 MB, `com.amazon.tcomm` 6 MB | 96 MB |
| Stock launcher (escape hatch, keep) | `com.amazon.tv.launcher` 36 MB | 36 MB |
| Amazon background services seen running | `device.services`, `whisperlink.core.android`, `imp`, `device.software.ota`, `device.messaging`, `whisperjoin.middleware.np`, `systemnotices`, `connectivitycontroller`, `identity.auth.device.authorization`, `device.rdmapplication`, `neo.minerva`, `accessoryconfigservice`, `device.blepa` | about 70 MB |
| atvTools' own helper (needed while you work) | `dev.vodik7.atvtoolsserver` and `:i` | 11 MB |

What it already shows (INFERENCE, to confirm against 0.4 to 0.9):

- YouTube's 106 MB is the open app (DIRECT: it was reopened and paused when 0.2 ran). 0.2 is **not**
  evidence that YouTube lingers after you leave it. That needs a post-exit measurement, taken in the
  lifecycle stage (see [lifecycle.md](lifecycle.md), "Baseline measurement").
- Netflix was resident with no `/ activities` tag, so its process stayed in memory without a screen.
  That alone does not show it was doing work: Android keeps cached processes until it needs the RAM.
  Same baseline measurement applies.
- Prime Video (`firebat`) is running although it is not on the keep list. Question for the owner.
- Alexa is about 96 MB. Whether voice search is used decides that group. Question for the owner.
- `com.amazon.device.software.ota` is alive, so update machinery is active on this build.
- `com.amazon.neo.minerva` (telemetry) is running; it was disabled successfully on the same build in
  `examples/amazon-fire-tv-stick-lite-2020/` (DOCUMENT).
- Not candidates, whatever they look like: `com.amazon.device.blepa` and `com.amazon.accessoryconfigservice`
  (remote and Bluetooth pairing; INFERENCE from the names, kept out regardless), `com.amazon.tv.ime` (keyboard), `com.amazon.identity.auth.device.authorization`
  (Amazon sign-in that apps rely on), `com.android.*` system processes.

## 0.3 Backup

First run (AUDIT): only `getprop.txt` was real; the seven `pm` and `settings` files held
`cmd: Failure calling service package: Failed transaction (2147483646)` (confirmed word for word with `cat`).
Discriminator (AUDIT): `pm list packages -3` printed to the terminal works perfectly, so the failure is only
in redirecting `pm`/`settings` output straight to a file. Redesigned 0.3 (pipe through `cat`) is committed.

Rerun (AUDIT): **success, backup complete.** No file failed.

| File | Lines |
|---|---|
| `getprop.txt` | 462 |
| `pkgs-all-incl-uninstalled.txt` | 255 |
| `pkgs-installed.txt` | 255 |
| `pkgs-disabled.txt` | 9 |
| `pkgs-thirdparty.txt` | 18 (matches 0.4) |
| `settings-global.txt` | 170 |
| `settings-secure.txt` | 215 |
| `settings-system.txt` | 338 |

What the counts already say (INFERENCE, 0.6 confirms or corrects):

- **The two package lists are the same length, so nothing is uninstalled for user 0 right now.**
  `pm list packages -u` adds packages that are still in the system image but removed for your user; there
  are none. Your earlier removals (DIRECT: you used ADB to uninstall some Amazon apps) were then one of:
  Amazon apps installed on `/data` (from the Appstore, not the system image), which an uninstall removes
  completely, so no list shows them any more; or system apps whose `pm uninstall --user 0` did not take
  on this build; or something since brought them back (a factory reset or an update). Which one matters
  for stage A: if `pm uninstall --user 0` is refused on this firmware, stage A becomes disables.
- **Only 9 packages are disabled.** Fewer than a typical debloat; the gap analysis will be most of the list.

## 0.4 Third-party apps (AUDIT, from the discriminator run)

18 packages. None of them goes into a change batch: third-party apps are yours, and the plan only touches
Amazon packages.

| Package | What it is | Status |
|---|---|---|
| `com.conreo.couchytv` | Couchy launcher | Off limits (DIRECT) |
| `io.github.toolicious.homeonfire` | Home On Fire | Off limits (DIRECT) |
| `com.stremio.one` | Stremio | Keep (DIRECT) |
| `com.amazon.firetv.youtube` | YouTube for Fire TV (confirms the name in lifecycle.md) | Keep (DIRECT) |
| `com.esaba.downloader` | Downloader | Keep (DIRECT) |
| `com.netflix.ninja` | Netflix | Keep (DIRECT) |
| `com.instagram.airwave` | Instagram for TV | Keep (DIRECT) |
| `com.nordvpn.android` | NordVPN | Keep (DIRECT) |
| `dev.vodik7.atvtoolsserver` | atvTools' helper on the stick: your only shell | Keep, never touch (INFERENCE: needed for every batch) |
| `org.videolan.vlc` | VLC | Yours, not in the brief: kept |
| `link.unlinked` | Unlinked (app store) | Yours, not in the brief: kept |
| `com.streamdev.aiostreamer` | AIO Streamer | Yours, not in the brief: kept |
| `com.amhkor.voltratv` | VoltraTV | Yours, not in the brief: kept |
| `com.firesend.cleaner` | FireSend Cleaner | Yours, not in the brief: kept. May overlap with the lifecycle stage (U11) |
| `dev.app1.xyz` | Unknown from the name | Yours: kept. UNRESOLVED (U12) |
| `com.amazon.tv.legal.notices.overlay.localisation.common` | Amazon resource overlay (legal notices) | Not a candidate: overlays for Settings screens, near the protected list |
| `com.amazon.tv.settings.v2.overlay.localisation.common` | Amazon resource overlay (Settings) | Not a candidate: Settings |
| `com.amazon.tv.parentalcontrols.overlay.localisation.common` | Amazon resource overlay (parental controls) | Not a candidate: leave alone |

Silk is not in this list, so it is a system package (`com.amazon.cloud9`, INFERENCE, checked in 0.5).
Note for the plan: `examples/amazon-fire-tv-stick-lite-2020/` disables Silk; you keep it, so that line is
not copied.

## 0.5 System packages (AUDIT, summary only so far)

237 system packages (237 + 18 third-party = 255, matching the backup). The owner's summary names the full
Amazon stack still installed: `aca`, `adep`, `firebat`, `firehomestarter`, `hedwig`, `hybridadidservice`,
`logan`, `media.recommendations`, `minitv`, `neo.minerva`, `sneakpeek`, `tahoe`, `tigris`, `tv.acr`,
`tv.forcedotaupdater.v2`, `venezia`, `vizzini`, `device.software.ota`, `device.software.ota.override`,
`device.metrics`, `dp.logger`, `client.metrics.api`, `tv.fw.metrics`, `wirelessmetrics.service`,
`usagestats.proxy`. Full list relayed afterwards: [audit-0.5-system-packages.txt](audit-0.5-system-packages.txt)
(sorted, `package:` prefix stripped). **It has 236 names, one short of the 237 the stick counted**: one
line was lost in the relay. Batch 0.5c locates it. Until then, a package absent from the file is
"unknown", not "absent".

Compared with the same-build list `examples/amazon-fire-tv-stick-lite-2020/` (DOCUMENT):

- 50 of that list's 51 packages are on this stick (`com.amazon.tv.releasenotes` is not, or is the lost line).
- Its 5 commented-out protected packages are all here: `device.crashmanager`, `device.logmanager`, `diode`,
  `fireos.usagestats.proxy` (protected), and `tv.oobe` (kept for factory reset).
- About 130 Amazon and Fire OS packages here are not in that list at all; each needs a verdict in the gap
  analysis (keep, candidate with evidence, or unresolved).
- `com.amazon.application.compatibility.enforcer` (+ `.sdk.library`) is on this stick. Its name points at
  app enforcement (U2). Community Fire TV guides disable it with `pm disable-user`, but none documents what
  it does or what breaks (DOCUMENT: [JLCareglio guide](https://gist.github.com/JLCareglio/881ab7feaa8013f838bec02c706b47a3),
  [ungeskriptet debloater, Fire OS 7.6.2.4](https://gist.github.com/ungeskriptet/256819b3d328a1df364222579608fc59)).
  It stays out of batches until a read-only `dumpsys package` look at it.
- The file has `com.amazon.platform.fdrw`, not `fdra` as on Fire OS 8.

## 0.6 Disabled and uninstalled-for-user (AUDIT)

Disabled (9): `com.amazon.bueller.music`, `com.amazon.hedwig`, `com.amazon.media.recommendations`,
`com.amazon.minitv.android.app`, `com.amazon.ods.kindleconnect`, `com.amazon.shoptv.client`,
`com.amazon.shoptv.firetv.client`, `com.amazon.tahoe`, `com.android.nfc`.

Uninstalled for user 0: none.

Reading (DIRECT from the owner, consistent with the counts): the earlier removals were these disables plus
full uninstalls of downloaded apps. No system package has been through `pm uninstall --user 0` on this
stick, so whether this firmware accepts it is untested: stage A opens with a one-package test and its
restore line.

Notes for the plan (DOCUMENT):

- `com.android.nfc` disabled is harmless on a stick with no NFC; it stays as it is.
- On a Fire OS 8 stick in this repo, disabling `com.amazon.imp` together with the shopping and recommendation
  packages left the stock Home black (`examples/amazon-fire-tv-stick-4k-2023/`). Here `media.recommendations`
  and both `shoptv` packages are already off; `imp` stays enabled and out of every batch, so the stock
  launcher keeps working as your escape hatch. To verify in each check step: long-press Home still opens it.


## 0.7 Home, accessibility, verifier (AUDIT, identical on two runs)

| Item | Value | Reading |
|---|---|---|
| Default HOME | `com.amazon.tv.launcher/.ui.HomeActivity_vNext`, priority 950, `isDefault=true` | Stock launcher is still the system Home. Couchy reaches the screen through Home On Fire. Matches the brief; nothing to change. |
| `HomeActivity_vNext` shows `enabled=false` | from `ActivityInfo` | INFERENCE: that field is the manifest default; the resolver still returns the activity, so its runtime state is on. Not touched either way. A read-only check is U13. |
| `enabled_accessibility_services` | `io.github.toolicious.homeonfire/.HijackService` | Home On Fire's service is on. Off limits. Note: any `am force-stop` of Home On Fire would switch it off, so no batch ever does that. |
| `package_verifier_enable` | `1` | Install-time verifier is on. Candidate for stage C, but its link to Amazon's blocklist is not established (U2). |
| `verifier_verify_adb_installs` | `null` (default) | Unchanged. |
| `install_non_market_apps` | `1` | Sideloading allowed. |
| `always_finish_activities` | `null` ("Don't keep activities" off) | Stays off (rejected in lifecycle.md). |

## 0.8 Amazon processes (AUDIT, RSS in KB, snapshot)

RSS counts shared memory in every process, so it runs higher than 0.2's PSS; compare within one batch only.
`firebat` (Prime Video) and `aca` (Alexa hints) were not running at this moment, so they start on demand.

Top Amazon processes and what this repo already knows about each on **the same build**
(`examples/amazon-fire-tv-stick-lite-2020/`, AFTSS PS7717/5741, DOCUMENT):

| Process | RSS | Same-build record |
|---|---|---|
| `com.amazon.tv.ffsprovisioneeclient` | 89,628 | Disabled there (frustration-free setup) |
| `com.amazon.tv.easyupgrade` | 86,404 | Disabled there ("upgrade your Fire TV" promos) |
| `com.amazon.diode` | 80,456 | **Protected** there: `pm disable-user` refused |
| `com.amazon.vizzini` | 78,144 | Kept there (Alexa voice search); comes back at boot on other Fire builds |
| `com.amazon.device.services`, `com.amazon.device.messaging` | 41,388 / 39,812 | Not in that list (kept) |
| `com.amazon.alexamediaplayer.runtime.ftv` | 39,584 | Disabled there (Alexa media) |
| `com.amazon.imp` | 34,368 | Kept; out of every batch here (black Home risk, see 0.6) |
| `com.amazon.whisperjoin.middleware.np` | 23,056 | Disabled there |
| `com.amazon.device.software.ota` | 19,916 | Kept there; stage C attempt here |
| `com.amazon.whad` | 18,832 | Disabled there |
| `com.amazon.systemnotices` | 18,564 | Disabled there |
| `com.amazon.neo.minerva`, `.logcat` | 4,428 / 2,252 | Disabled there |
| `com.amazon.tv.developer.dataservice` | 1,944 | Disabled there |
| `com.amazon.dialservice` | 2,072 | Kept there (casting) |

Not candidates (input, remote, Bluetooth, keyboard, sign-in, Wi-Fi, HDMI and hardware services): `tv.ime`,
`device.blepa`, `accessoryconfigservice`, `identity.auth.device.authorization`, `connectivitycontroller`,
`tv.devicecontrol` (HDMI-CEC TV control, INFERENCE from the name), `amazonfiled`, every `fireos.hardware.*`
service. `tcomm`, `whisperlink.core.android`, `device.rdmapplication` and `tv.launcher` are not candidates
either: `tcomm` and `whisperlink` back voice and casting, `rdmapplication` is unclear (left alone), and the
launcher is off limits.

### 0.8 second snapshot (AUDIT; 0.7 rerun identical)

- `com.amazon.ftv.screensaver` at 143,668 KB RSS: the screensaver had started between runs. It is the
  single largest Amazon process seen so far.
- `ffsprovisioneeclient`, `easyupgrade` and `diode` (the first snapshot's top three) are gone: they wake,
  work and exit. A one-off `ps` cannot measure their total cost; disabling them stops the wake-ups.
- Still resident in both snapshots: `vizzini`, `device.services`, `device.messaging`, `imp`,
  `alexamediaplayer.runtime.ftv`, `tcomm`, `whisperlink.core.android`, `whisperjoin.middleware.np`,
  `device.software.ota`, `systemnotices`, `whad`, `neo.minerva`, `neo.minerva.logcat`,
  `tv.developer.dataservice`, `dialservice`.

For the plan (INFERENCE): the screensaver is kept as a package on the same-build list (DOCUMENT), and
whether it runs at all is a menu setting, not a package question. The plan will offer Settings > Display &
Sounds > Screensaver > Start Time > Never, with no package change, if the owner wants it.

## CHECK baseline, before stage A (AUDIT)

All 13 kept apps `ok`; HOME `com.amazon.tv.launcher.ui.HomeActivity_vNext`; A11Y
`io.github.toolicious.homeonfire/.HijackService`; disabled count 9. The full line (about 680 characters)
ran to completion, so lines of that length work in atvTools (U16 resolved).

## 0.5c checkpoints (AUDIT)

Lines 20 to 160 match the file; at 180 the stick has `com.amazon.whad` where the file has
`com.amazon.whasettings`. So the one missing name sorts between `com.amazon.tv.ottssocompanionapp` (160) and
`com.amazon.whad` (file line 179). `com.amazon.tv.releasenotes` fits that window (between
`tv.quicksettings.ui.sheldon.overlay` and `tv.resolutioncycler`) and is on the same-build list, but the
checkpoints alone do not name it: any name in that range could be the one. Batch 0.5d prints the 20 lines to
settle it. `com.amazon.device.services` (my earlier guess) is ruled out: it would sort near line 58, and
checkpoint 60 matches. The `com.amazon.device.services` process in 0.2 and 0.8 therefore runs inside another
package (INFERENCE: a shared process of an Amazon system package).

## 0.5d window (AUDIT)

Lines 161 to 180 on the stick match the file plus one name: `com.amazon.tv.releasenotes` at line 164.
Added to [audit-0.5-system-packages.txt](audit-0.5-system-packages.txt), now 237 lines, matching the stick.
It joins stage B3: the same-build list disabled it ("what's new" release notes) without harm (DOCUMENT).

## Stage A1, first run (AUDIT)

`pm uninstall -k --user 0 com.amazon.tmm.tutorial` returned `Failure [DELETE_FAILED_INTERNAL_ERROR]`; STATE
stayed `installed=true enabled=0`, so nothing changed. This firmware does not take uninstall-for-user (the same
error as the Fire TV Box in `docs/TROUBLESHOOTING.md` and the Hisense Fire TV list, DOCUMENT). Stage A is
rewritten as disables in [02-plan.md](02-plan.md).
