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

## Stage A1, disable test (AUDIT)

`com.amazon.tmm.tutorial: Package com.amazon.tmm.tutorial new state: disabled-user`; STATE
`installed=true enabled=3`. `pm disable-user --user 0` works on this build, so stage B's method is confirmed.
Restore proof (AUDIT): `pm enable --user 0` gave `new state: enabled`, STATE `installed=true enabled=1`. The way
back works. Pending: disable again, CHECK, hand checks, reboot.
Re-disable (AUDIT): `disabled-user`, `enabled=3`. CHECK after it: all 13 kept apps `ok`, HOME and A11Y
unchanged, disabled count 10.
STATE the next day, after an overnight pause (AUDIT): `installed=true enabled=3`, so the disable holds. Not yet
known: whether the stick rebooted before this reading, the post-reboot CHECK, and the hand checks.
Reboot (DIRECT): the owner restarted the stick twice the evening before, then shut it down overnight; the
`enabled=3` reading was taken after that, so the disable survives reboots. Hand checks (DIRECT): Couchy on Home,
stock launcher on long-press Home, apps and NordVPN fine. Remote volume and power not mentioned.
Post-reboot CHECK (AUDIT): all 13 kept apps `ok`, HOME and A11Y unchanged, disabled count 10; STATE in the same
sitting `enabled=3`. **A1 passed.** Remote (DIRECT): power works; volume up and down work (checked later the same day). All A1 checks closed.
Build check (AUDIT): `Fire OS 7.7.1.7 (PS7717/5741)`, unchanged; uptime 10 minutes, matching the owner's
morning restart. No update has arrived since the audit.

## Stage A2a (AUDIT)

`bueller.music`, `tahoe`, `ods.kindleconnect`, `minitv.android.app`: all `installed=true enabled=3`. Already in
the target state; nothing changed. **A2a passed.**

## Stage A2b (AUDIT)

`storm.lightning.tutorial`, `bueller.photos`, `gamehub`: `new state: disabled-user`, STATE `enabled=3` for all
three. One `Failed to write while dumping service package: Broken pipe` line appeared between two STATE lines.
Cause (INFERENCE, standard pipe behaviour): STATE's `grep -m1` stops reading after the first `User 0:` line, so
`dumpsys` gets a broken pipe when it writes the rest and prints that message. The STATE values are read before
it happens, so it is harmless.
CHECK after the disable (AUDIT): 13 kept apps `ok`, HOME and A11Y unchanged, disabled count 13.
Reported as after the reboot (AUDIT): STATE `enabled=3` for all three, CHECK 13 `ok`, count 13. Pending: the
uptime line (to confirm a reboot happened before these readings) and the hand checks.

## Incident during A2b checks: stock Home on screen, Home key did not bring Couchy back (DIRECT)

After the app hand checks the owner returned to Couchy, then looked away at a phone for a while. When the owner looked
back, the TV showed the stock Amazon Home, and pressing Home did not bring Couchy back. A restart (the planned
next step) fixed it; every check since has passed.

Reading (INFERENCE, to test with the log pulls in this section):

- Home On Fire swaps in Couchy when the stock Home comes to the front. Home not bringing Couchy back means its
  accessibility service was not working at that moment (its process killed or not yet rebound), or Couchy
  could not start. Either way, both Couchy's own failure and Home On Fire's would show the same screen.
- Why the stock Home was on screen with nobody touching the remote: the likeliest trigger is the screensaver.
  It starts after a few idle minutes, and 0.8 measured it at about 144 MB RSS on a stick with about 158 MB
  available. Starting it pushes Couchy (now in the background) and possibly Home On Fire's process out under
  memory pressure (low-memory killer). When the screensaver ends, the default Home, which is still the stock
  launcher, comes up, and with Home On Fire's process gone nothing redirects it until the service restarts.
- A link to stage A cannot be ruled out: A2b disabled `com.amazon.bueller.photos`, and Amazon Photos can be a
  screensaver image source. On the same-build list, Photos was disabled with the screensaver kept and no such
  problem reported (DOCUMENT), so this is the weaker candidate, but it is checked below.
- A low-memory kill is not recorded in the crash history; it would be in the in-memory event log, which the
  restart cleared. So the dropbox pull can confirm a crash, but cannot rule out a low-memory kill.

Status: B1 is held until the dropbox pull is read.

### Incident pull 1: dropbox filtered for Couchy and Home On Fire (AUDIT)

`dumpsys dropbox` grepped for `couchy|homeonfire|toolici`: empty. Android's dropbox listing shows a short
preview of each entry, and a crash or ANR entry starts with `Process: <package>`, so a recorded crash or ANR of
either app would normally have matched (INFERENCE from how the listing works on Android 9, not checked on this
stick). So there is no recorded crash or ANR for Couchy or Home On Fire. That weakens "Couchy crashed" and fits
a low-memory kill, which leaves no dropbox entry. It does not prove the kill: the restart wiped the evidence for
that. Next: the entry headers around the incident time, and whether any screensaver or Photos entries exist.

### Incident pull 2: dropbox entry headers (AUDIT)

- About 30 `system_server_wtf` (about 1.3 KB each) at 12:43:07 to 12:43:08.
- `system_app_wtf` (1630 bytes) at 12:43:10 and 12:43:12.
- `SYSTEM_BOOT` and `SYSTEM_LAST_KMSG` at 12:43:23: the owner's restart.
- `system_app_wtf` again, exactly 1630 bytes, at 12:44:52 after the boot; `Log.main` zips at 12:47:56 and 12:52:57.

Reading (INFERENCE):

- The WTF burst lands 15 seconds before the boot record, which is where the shutdown of a restart falls.
  Services reporting "what a terrible failure" while they are stopped is common during a shutdown, so the burst
  most likely belongs to the restart, not to the incident, which started minutes earlier.
- The `system_app_wtf` of exactly 1630 bytes appears both before and after the boot: a repeating report from
  one system app, likely unrelated. Printing one tells which app.
- Nothing is recorded in the incident window itself, before the shutdown. That again fits a low-memory kill,
  which leaves no dropbox entry, rather than a crash or a hang.
- `SYSTEM_LAST_KMSG` is the kernel log from just before the restart. If this kernel kills processes itself
  under low memory, its kill lines name the process (Android shortens names to their last 15 characters, for
  example `conreo.couchytv`, `ious.homeonfire`, `ftv.screensaver`; INFERENCE, not checked on this stick).
  That would be direct evidence.

### Incident pull 3: SYSTEM_LAST_KMSG, tail (AUDIT)

Every match in the last 40 is shutdown teardown at kernel time about 1286.49 to 1286.94 s: init and `lmkd`
unregister messages and `libprocessgroup` stopping system daemons (mediametrics, media, smarthomed, statsd,
storaged, wificond, zygote, vold, adbd, logd). No Couchy, Home On Fire, screensaver or low-memory kill lines.
The shutdown burst fills the tail window, so a narrower `head -40` run is next.

Reading (INFERENCE):

- ~~The kernel log may not record low-memory kills on this stick.~~ Corrected by pull 4 below: it does.
- Logcat lives in memory and the restart cleared it. The two `Log.main` zips in dropbox are from after the boot
  (12:47 and 12:52), so they do not cover the incident.
- Kernel time 1286 s at shutdown means that boot had run about 21 minutes.

### Incident pull 4: SYSTEM_LAST_KMSG, head (AUDIT)

`dumpsys dropbox --print SYSTEM_LAST_KMSG` prints every stored entry, oldest first. The head window is an older
session (kernel time about 54322 to 54377 s, about 15 hours up), not the incident session. It holds a
low-memory kill storm, all `cache below limit 239616kB`: `uicksettings.ui`, `android.service`, `v.settings.core`,
`.tv.settings.v2`, `arentalcontrols`, `id.proxyhandler`, `om.amazon.logan`, `com.amazon.adep`, `.amazon.ceviche`
(adj 901) and `iders.downloads`, `android.service` (adj 902), then `lmkd` gets signal 15 as that session shuts
down. The kernel log names processes by their last 15 characters, as expected. No Couchy, Home On Fire or
screensaver names in either window seen so far. Next: a grep of all stored entries with no head or tail limit.

Reading (INFERENCE):

- **Correction:** low-memory kills do reach the kernel log on this stick, so the incident session's log is real
  evidence after all. If the full grep shows no kill of `conreo.couchytv` or `ious.homeonfire` in the incident
  session, a low-memory kill becomes unlikely, unless that session's log was cut short by the buffer size.
- The storm killed only cached background processes (adj 900 and up). Couchy in the background would sit
  around that level, so it can be killed this way. Home On Fire's accessibility service is bound by the system
  and normally sits far lower (more protected), so a kill of it would be unusual.
- The stick reaches the low-memory limit in normal use (about 234 MB of cache). That supports freeing memory
  (stage B, screensaver off) whatever this incident turns out to be.

### Screensaver facts (DIRECT)

The screensaver is on, and it plays high-resolution aerial video, not still photos. Reading (INFERENCE): video
decoding needs decoder buffers in addition to the app's own memory (about 144 MB RSS in 0.8), and the footage is
streamed, so it also adds network traffic to Amazon while the stick is idle. Both fit the memory-pressure
explanation and argue for Start Time > Never, which is the owner's choice. Still pending: the full grep of all
stored kernel logs for `onreo`, `homeonfire`, `screensaver`.

### Two aerial videos, not one (DIRECT)

1. The Fire TV screensaver (`com.amazon.ftv.screensaver`, Amazon's): on, plays aerial video.
2. Couchy's own home screen background: also a high-resolution aerial video, playing on Couchy's home screen.

Reading (INFERENCE):

- The main suspect stays the Fire TV screensaver: about 144 MB RSS when it ran in 0.8, it starts after a few idle
  minutes (which matches the incident), and when it ends the system shows the default Home, which is the stock
  launcher.
- Couchy's video is not cleared, though. While it plays, its decoder buffers and frames are part of Couchy's
  memory. When the screensaver comes to the front, Couchy becomes a background process, and the low-memory
  killer picks the larger processes first at the same level, so a bigger Couchy is a likelier target. And the
  screensaver may start while Couchy's video is still loaded, putting two video sessions on a 1 GB stick at once.
  0.2 measured Couchy at 28 MB PSS, but not while its video was confirmed playing on screen.
- Test one change at a time: first the Fire TV screensaver off (Start Time > Never). If the drop-out still
  happens, then try a still image as Couchy's background. Changing both at once would not tell which mattered.

### Stage A closed

- A2b post-reboot: the restart at 12:43:23 that ended the incident is the reboot; STATE afterwards showed all
  three at `enabled=3`, CHECK 13 `ok` and count 13, and the owner reports every check fine since (DIRECT).
- **Stage A passed.** Disabled count 13.
- Q4 (DIRECT): the owner set the Fire TV screensaver Start Time to Never after the incident. A shell read to
  confirm the setting is pending. This is also the first test for U18: if the drop-out does not recur, the
  screensaver was the likeliest trigger.
- B1 may proceed: the remaining U18 grep reads a past session and cannot change B1, and B1 only frees memory.
- Screensaver confirmed (AUDIT): `settings get secure screensaver_enabled` = `0`. `screensaver_components` still
  names `com.amazon.ftv.screensaver`, and `screensaver_activate_on_dock` and `_on_sleep` are still `1`; with the
  master flag at `0`, Android does not start the screensaver (INFERENCE, standard Android behaviour). A grep of
  the settings list for "screensaver" also matched hundreds of times inside Amazon's `ceviche` telemetry config
  values (`com.amazon.ceviche` is in stage B2). Read-only; nothing changed.

## Stage B1: metrics and performance collection (AUDIT)

All 7 `new state: disabled-user`, no protected refusals: `client.metrics.api`, `neo.minerva`, `neo.minerva.logcat`,
`tv.fw.metrics`, `wirelessmetrics.service`, `perfcollection`, `perfc`. STATE: all 7 `installed=true enabled=3`.
Pending: CHECK (expect count 20), hand checks, reboot, CHECK, STATE, screensaver flag still `0`.
CHECK anomaly (AUDIT): a CHECK run after B1 printed `MISSING` for all 13 kept apps, while DISABLED COUNT was 20 as
expected and HOME and A11Y were right. The committed CHECK prints `ok` or `PROBLEM`, never `MISSING`, and its
HOME line has a `name=` prefix, so the line that ran was most likely not the committed one. A direct probe
showed `pm list packages -e` containing both Couchy and Home On Fire, with 235 enabled packages (255 installed
minus 20 disabled). The kept apps are fine. CHECK in 02-plan.md now writes the enabled list to a file through
`cat` and checks against the file, and also prints the enabled count and the screensaver flag.
File-based CHECK after B1 (as relayed): 13 kept apps `ok`, HOME and A11Y right, disabled count 20. The relay did
not include the ENABLED COUNT or SCREENSAVER sections, and gave HOME without the `name=` prefix, so it is not
yet certain the committed line was the one that ran. Pending: hand checks, reboot, post-reboot CHECK pasted raw.

## U18 recurrence during B1 hand checks, no restart yet (DIRECT)

YouTube opened fine. Stremio: a movie started, playback froze, Stremio then apparently crashed, and the stock
Amazon Home came up. Pressing Home only refreshes the stock Home; Couchy does not come back. The Fire TV
screensaver was off (`screensaver_enabled=0`), so it was not the trigger this time; the trigger was Stremio
streaming under load. CAPTURE is being run before any restart.

Reading before CAPTURE (INFERENCE): the screensaver is no longer the common factor. What both incidents share is
a heavy foreground app (the screensaver's video, then Stremio's player) on a stick that already reaches its
low-memory limit in normal use, followed by Home On Fire not bringing Couchy back. Whether Couchy, Home On Fire's
service, or both are gone is what CAPTURE shows.

### Recurrence CAPTURE, before restart (AUDIT, as relayed)

- A11Y setting: still `io.github.toolicious.homeonfire/.HijackService`.
- Processes: `com.amazon.tv.launcher` running (about 110 MB RSS); `io.github.toolicious.homeonfire` running
  (about 27 MB RSS); **no `com.conreo.couchytv` process at all**.
- Memory: MemTotal 922,268 kB, MemFree 48,944 kB, MemAvailable 168,136 kB.
- Dropbox: exactly one `data_app_crash` at 2026-10-24 13:30:45 (2876 bytes), the incident minute; other
  entries are `data_app_anr` from Oct 23.
- `dmesg` is refused for the shell on this build (`klogctl: Operation not permitted`), so kernel kill lines
  can only be read afterwards from `SYSTEM_LAST_KMSG`. The relayed CAPTURE differs from the committed one, which
  reads logcat's event buffer instead of `dmesg`.

Reading (INFERENCE):

- Home On Fire's process is alive and its service setting is on, yet Home does not bring Couchy back, and
  Couchy is not running. So this is not "Home On Fire was killed". Either Home On Fire is alive but not
  receiving events (process alive does not mean the service is connected), or it tries to start Couchy and
  Couchy dies straight away, which on screen looks like Home "refreshing" the stock Home.
- The one crash entry decides between those: if it names Couchy, Couchy crashes on start; if it names Stremio,
  the crash is Stremio's frozen playback, and Couchy was removed some other way (most likely a low-memory kill
  while Stremio played).

### Recurrence logs: cause found (AUDIT, as relayed from the full scrollback)

- Dropbox `data_app_crash` 13:30:45: `Process: com.stremio.one`, `TraceHashCode LMK_com.stremio.one_600`. Stremio
  was **killed by the low-memory killer**, not crashed in its code. At death it held about 584 MB
  (ResidentSize 550,144 KB plus IonAllocations 47,952 KB) of the stick's 922 MB, and `other_free` was negative
  (-3135 pages).
- Main log: 13:30:37 `WIN DEATH` for Couchy's MainActivity; 13:30:38 `Process com.conreo.couchytv (pid 25880) has
  died: prev LAST`; 13:30:44 `Process io.github.toolicious.homeonfire (pid 1650) has died: vis BFGS` and
  `Scheduling restart of crashed service io.github.toolicious.homeonfire/.HijackService in 49965ms`; 13:31:34
  Home On Fire back as pid 29214 (the process CAPTURE saw).
- Events: `am_low_memory` firing continuously from 13:34 to 13:37 (values 23 to 28): still low on memory after
  Stremio died.

**The chain:** Stremio's playback grew to more than half the stick's RAM. The low-memory killer removed Couchy
first (background, "prev"), then Home On Fire (a visible-level bound service, so it went late), then Stremio itself.
Android restarted Home On Fire's service about 50 seconds later; nothing restarts Couchy. Since then, Home only
refreshes the stock Home.

This also explains the first incident (INFERENCE): the same chain with the screensaver's video as the heavy app.

**Not caused by the de-Amazon stages** (INFERENCE from the evidence): the kills are of a heavy app outgrowing the
RAM, the stick already hit its low-memory limit in an older session before any change (pull 4), and stages A and
B1 only took memory users away.

Still open: why the restarted Home On Fire does not bring Couchy back (U19). The hand test (open Couchy from the
app list, then press Home) answers it.

### Hand test and stream quality (DIRECT)

- Couchy reopened from the app list, then Home brought Couchy back and it worked. **U19 answered:** Home On Fire's
  redirect works again as soon as Couchy is running. Recovery after a drop-out is reopening Couchy; no reboot.
- The Stremio stream was 1080p, not 4K or a remux. So stream quality was not what drove Stremio to 584 MB; its
  own footprint did (INFERENCE: player, buffers and Stremio's built-in streaming server in one process).
- The owner's view (DIRECT): this stick is probably not powerful enough for apps like Stremio.

### B1 post-reboot CHECK (AUDIT, committed line, raw)

KEEP 13 `ok`; ENABLED COUNT 235; HOME `name=com.amazon.tv.launcher.ui.HomeActivity_vNext`; A11Y
`io.github.toolicious.homeonfire/.HijackService`; DISABLED COUNT 20; SCREENSAVER `0` (stays off across a reboot).
This is the first raw run of the file-based CHECK, and every section printed.
B1 STATE after the reboot (AUDIT): all 7 `installed=true enabled=3`. **Stage B1 passed.** Disabled count 20.

## Stage B2: logging, data services, ACR, Wi-Fi password upload (AUDIT)

All 7 `new state: disabled-user`, no refusals: `dp.logger`, `ceviche`, `tv.developer.dataservice`,
`livedeviceservice`, `privacypassservice`, `wifilocker`, `tv.acr`. STATE: all 7 `installed=true enabled=3`.
Pending: CHECK (expect disabled 27, enabled 228), hand checks, reboot, CHECK, STATE.

### Third Couchy drop-out, during B2 checks (DIRECT)

While the owner was away from the TV during a break, Couchy dropped out again; reopening Couchy recovered it and it
has been fine since. No capture. Unlike the first two, no heavy app was reported in front (screensaver off), and it
came after B2. Whether it was another low-memory kill (Couchy's own aerial video on screen, or something in the
background) or something B2 changed is not known yet. Dropbox survives a reboot; logcat survives until the next
reboot, so the B2 reboot is held until the log line has run.

### Netflix question (DIRECT)

The owner does not use Netflix and asks whether it should go. Evidence (AUDIT 0.2): `com.netflix.ninja` held about
81 MB with no screen open, so it does add weight when it lingers. It is a third-party app (0.4), so a full
`pm uninstall` works, unlike the system packages. Undo is a reinstall from the Appstore plus signing in again; there
is no one-line restore. Waiting for the owner's confirmation before CHECK, D1 and the keep list change.

## Runbook run by the owner's local agent, through C0 (DIRECT, relayed by Sonny)

The owner ran 03-runbook.md steps R0 to C0 through a local Codex agent with a phone harness. Reported complete
through C0 with the final owner checks passed; nothing after C0 has run. The step-by-step results log has not been
shared here.

Fresh read-only snapshot, 2026-10-25 about 05:01 CT (DIRECT, as relayed):

- Build `Fire OS 7.7.1.7 (PS7717/5741)`, unchanged.
- ENABLED 204, DISABLED 50. 27 after B2 plus B3 9, B4 4, B5 5, B6 5 = 50, so B3 to B6 had no refusals.
  Installed 254 = 204 + 50.
- Netflix fully uninstalled: absent from `pm list packages` and `pm list packages -u` (step N).
- HOME stock launcher activity; A11Y `HijackService`; `screensaver_enabled` 0; MemAvailable about 208 MB (was
  about 158 MB at the audit).
- C0: `package_verifier_enable` 1; `PACKAGE_NEEDS_VERIFICATION` resolves to `com.amazon.adep` (two receivers);
  `adep` `enabled=0`; `application.compatibility.enforcer` `enabled=0`, not a verification receiver.
- Not run: C1 (the three OTA packages at default), B7, stage D (`firebat` at default).
- `com.amazon.vizzini` reads `enabled=1`, not `0`. `1` is an explicit enable, which normally means something set
  it: a B7 trial plus its restore, or Fire OS re-enabling it. Open question (U21).

## C2: install verifier off (DIRECT)

`settings put global package_verifier_enable 0`; the immediate read printed `0`. `adep` and the compatibility
enforcer untouched. Pending: one real install to prove installs still work, and whether Fire OS resets the
setting at boot (checked with C1's reboot).

## B7 trial: Alexa voice core returns at boot (DIRECT, from the owner's Codex session log)

The B7 trial ran during the Codex run. `com.amazon.vizzini` was disabled (`enabled=3`); B7's CHECK passed at
203 enabled / 51 disabled, and YouTube and Stremio opened. After B7's reboot, Fire OS had re-enabled it
(`enabled=1`) and the counts were back at 204 / 50. The saved B7 restore then ran as the runbook directs and
succeeded. **B7 closed:** this build re-enables the voice core at boot, as on four other Fire TV builds in this
repo. `vizzini` stays enabled, and its about 23 MB counts against the shell-only ceiling. Its `enabled=1` is
explained (U21 resolved).

## C1 executed, partial (DIRECT)

`com.amazon.tv.forcedotaupdater.v2` disabled (`enabled=3`). `com.amazon.device.software.ota.override` and
`com.amazon.device.software.ota` refused (`Cannot disable a protected package`), unchanged at `enabled=0`. Counts
now 203 enabled / 51 disabled. Pre-check (the owner's About screenshots): an update is already staged ("Update to
install: System components"), and About says it begins automatically the next time the stick is not in use. The
owner did not press Install, and dismissed a USB Power Warning (the stick is powered from the TV's USB port).

Reading (INFERENCE): the two packages that install updates are protected, so the shell cannot stop this staged
update; it will most likely install at an idle moment or a reboot. When it does, the build changes and some
disabled packages may come back; the plan's stages are then re-checked against the new build. The USB power
warning means the TV's port may supply less than the stick wants; Amazon's wall adapter avoids that.

Remaining work handed to the owner's Codex as one job: [04-continuation-runbook.md](04-continuation-runbook.md).

### USB Power Warning and power setup (DIRECT)

Highlighting Install Update on About raised a "USB Power Warning": "USB power may not be sufficient for a system
update. We recommend using the included USB cable and Amazon power adapter for best results." Behind it: "An
update is available", "Update to install: System components". Dismissed with OK; Install not pressed. The stick is
powered from the TV's USB port, which is also why the TV's power button power-cycles the stick.

Reading (INFERENCE): the warning is advisory and does not prove the staged update cannot install on this power.
TV-USB power means the stick loses power whenever the TV turns off or sleeps, which can interrupt any step and,
in the worst case, an update while it installs. 04-continuation-runbook.md now treats a power loss as a reboot and
tells Codex to keep the TV on. Moving the stick to Amazon's wall adapter removes both risks; that is the owner's call.

### Continuation runbook revised after Codex's pre-run review (DIRECT, checked by Sonny)

Four gaps fixed in 04-continuation-runbook.md: a Section 0 pre-flight that reads and records the BASELINE (build,
counts, verifier, C1 state) and explains why it differs from Codex's last endpoint (C2 and C1 were run by the
owner afterwards); every later count expressed as "counts = baseline", with an explicit baseline update if
`forcedotaupdater.v2` returns at boot; the Home check polls every 3 s for up to 15 s (an early stock-launcher sample
is inconclusive) and is corroborated by Couchy's pid, the focused window and Home On Fire's service; the VPN check
prints one definite token (`TUN0_UP`, `TUN0_PRESENT_NOT_UP` or `TUN0_ABSENT`); and Section 2 always removes the test
app, whichever attempt installed it, and re-verifies counts before Section 3. The polling and VPN lines were
dry-run against stubbed shell commands here; they have not run on the stick.

## Reconciliation after the Codex run (DIRECT, verified by Sonny from the stick, 2026-10-25 17:52 to 17:54 CT)

Codex ran 04-continuation-runbook.md in the morning while the owner slept. The run ended when the owner's
**phone harness failed** (corrected, DIRECT: it was not a Codex crash), and the run's log was lost. The state below
comes from read-only shell snapshots, not from Codex's account.

- Build `PS7717.5741N`: the staged update did not install.
- 200 enabled / 53 disabled / 253 installed / 16 third-party. Against the pre-run baseline (203 / 51 / 254 / 17)
  the run's whole footprint is two disables and one full uninstall; nothing else moved, nothing re-enabled.
- New disables: `com.amazon.firebat` (Prime Video) and `com.amazon.spiderpork`. Removed: `com.streamdev.aiostreamer`
  (AIO Streamer), fully uninstalled.
- `package_verifier_enable` still 0; `forcedotaupdater.v2` still disabled; A11Y `HijackService`; HOME the stock
  launcher activity.
- D1 not applied: YouTube and Instagram read `No operations. Default mode: allow`; `firebat` default. D2 unknown
  (atvTools snippets are app-side, not device state).
- Persistence: uptime showed a boot at about 16:44 CT, before the snapshot, so the verifier setting, the C1 disable
  and both new disables survived a real reboot on an unchanged build.

Owner decisions (final): `firebat` stays disabled (Prime Video off). AIO Streamer stays uninstalled.

What is still open: D1 (never landed) and D2 (unknown). Everything else is done or decided. Not work items:
the staged update can still install on its own (shell-only ceiling; re-check state afterwards), Q3 (Appstore,
kept by default), U20 (Stremio's memory). Finish: [05-final-runbook.md](05-final-runbook.md).

### `com.amazon.spiderpork` identified

It is **Amazon Luna**, Amazon's cloud gaming app (DOCUMENT: APKMirror lists `com.amazon.spiderpork` as "Amazon Luna
(Fire TV)"; this repo's TCL Fire TV list labels it "Amazon Luna"; one community tool calls it a background analytics
service, unverified). It was in this plan's "unresolved, role unclear" group, so not in any batch. Disabled without
reported harm on two Fire TV lists in this repo: `examples/insignia-ns55f301na25/` (Fire OS 7, PS7715, the build
family closest to this stick) and `examples/tcl-58s571f-fire-tv/` (Fire OS 8); a community guide uninstalls it for
the user. Its games-hub tile (`com.amazon.gamehub`) was already disabled in stage A2b. Not near any protected
function (Home, Settings, input, remote, Wi-Fi, installer, sign-in). Disabling it is neutral; it stays disabled.
It was never seen running in the 0.2 or 0.8 snapshots, so the memory gain is nil.

### Is the disable phase done? Yes

- MemAvailable rose from about 158 MB (audit) to about 208 MB after B6: the disables freed roughly 50 MB.
- What remains resident is the system (launcher, `device.services`, `device.messaging`, input, Bluetooth, Wi-Fi),
  casting (`tcomm`, `whisperlink`), packages that cannot be disabled (`diode`, `software.ota`; `vizzini` returns at
  boot) and `imp` (kept for the stock Home). None of it can safely go.
- The 34 remaining packages in the "unresolved" group were not seen running in any snapshot except
  `device.rdmapplication` (about 14 MB RSS, role unknown). Disabling all of them would free little, at real risk.
- The drop-outs come from one heavy app: Stremio at about 584 MB on a stick with 922 MB total. No disable can
  close a gap that size.

So Codex's pushback holds: further disables will not improve performance noticeably. The disable phase is done.
The remaining levers are outside package lists: Stremio's own footprint (U20), Couchy's video background (a still
image), the stick on a wall adapter, and hardware with 2 GB of RAM.

### Corrections and execution change (DIRECT, 2026-10-25)

- The morning run ended because the owner's phone harness failed, not because Codex crashed (corrected above).
- From here on the owner runs every remaining step by hand in atvTools, one line at a time, with Sonny handing over
  each line; Codex and the phone harness are out of the loop. D1 for YouTube and Instagram is being applied in
  chat with the 02-plan.md D1 line (which also covers the disabled `firebat`, harmlessly).
  [05-final-runbook.md](05-final-runbook.md) is rewritten for manual execution: verification, the casting check,
  the reboot persistence check, the restore line, and D2.

## Project complete (DIRECT, from the stick and the owner, 2026-10-25 evening CT)

Final state:

- Final CHECK clean: 12 of 12 `ok`, no `PROBLEM`; ENABLED 200, DISABLED 53; HOME the stock launcher activity; A11Y
  `HijackService`; SCREENSAVER 0.
- D1 applied in chat and verified: `RUN_ANY_IN_BACKGROUND` = `ignore` for YouTube and Instagram. Linger test passed:
  after YouTube playback, backing out and one minute in Stremio, the YouTube and Instagram processes were gone and
  Stremio was running. YouTube opens with its sign-in intact; casting from the phone to YouTube worked from the
  backed-out state; the settings survived a reboot.
- Post-reboot readback: build still `PS7717.5741N` (the staged update did not install through any of the day's
  reboots); both appops `ignore`; disabled count 53.
- D2: the Quit YouTube force-stop line works (pid empty afterwards; the TV returned to Couchy). Quit lines for
  Instagram, Prime Video (`firebat`) and Stremio were delivered in the same form; the Prime Video one is dormant
  while Prime Video stays disabled.
- Owner remote checks passed: Home returns to Couchy; long-press Home opens the stock launcher and back; volume works.
- Owner's verdict (DIRECT): much faster and smoother, no lag, noticeably lighter.

Not run, and not needed for completion: the C2 install proof (04, Section 2). The verifier stays off; if an install
ever fails or hangs, `settings put global package_verifier_enable 1` puts it back.

**Standing note:** if the staged update ever installs (the build no longer reads `PS7717/5741`), the follow-up is a
fresh CHECK, then re-verifying the counts, the disables, the verifier setting and D1, because an update may turn
things back on. Nothing is redone until that read has been reviewed. The read lines are in
[05-final-runbook.md](05-final-runbook.md), "Appendix".

## Follow-up planned: clearing the staged update (DIRECT request, 2026-10-25 late evening CT)

Correction to the close-out position: the staged "System components" update cannot be **prevented** from the
shell (the update packages are protected), but it may be **cleared**: AFTVnews recommends
`pm clear com.amazon.device.software.ota` for an update that is already downloaded (DOCUMENT; older guidance). Plan
in [06-ota-clear.md](06-ota-clear.md): About wording before and after, one clear line, readbacks, a reboot check.
Open points (U22): Android may refuse to clear a protected package's data, and the update file may live outside the
app's data, so About decides, not `Success`. It can download again afterwards; a look at About every week or two,
with a re-clear when "Update to install" returns, joins the standing note. Not run yet.

## Staged-update clear refused (AUDIT, 2026-10-25 about 21:52 CT)

Run over `adb shell` from the owner's Mac (new route, connection authorized). F0 matched the expected state
(build PS7717/5741, 200 / 53, verifier 0, `software.ota` and `.override` `enabled=0`, `forcedotaupdater.v2`
`enabled=3`, `ota pid: 1576`, both update-file folders `Permission denied`). F1 was refused:
`Security exception: Cannot clear data for a protected package: com.amazon.device.software.ota`
(`PackageManagerShellCommand.runClear`); `ota pid after: 1576`. Nothing changed. Fire OS's protection covers clearing
data as well as disabling, so the staged update can be neither cleared nor prevented from the shell (U22 resolved).

Standing posture, unchanged: `forcedotaupdater.v2` stays disabled; look at About now and then without pressing
Install or Check for Updates; if the build ever changes, run a fresh CHECK and re-verify the counts, disables,
verifier and D1. The periodic re-clear proposed in 06-ota-clear.md is withdrawn.

Note on the new route (INFERENCE): ADB over the network on port 5555 is unencrypted. With both atvTools and the Mac
authorized, it stays a standing access path on the home network; turning ADB debugging off when it is not needed
closes it (the owner's choice).

## Incident note: slow Home handoff, no crash (AUDIT over adb, 2026-10-25 about 21:54 to 22:00 CT)

Owner report (DIRECT): Couchy "gone", the stock launcher on screen, and an apparent crash on Home after relaunching
Couchy by hand.

Evidence: the crash buffer was empty (no `FATAL EXCEPTION`); Couchy's process (pid 2360) ran continuously from before
the episode through it, with no death or low-memory kill lines; one `am_low_memory` notice at 21:55:43. A state read
showed Home On Fire alive (pid 1589), its accessibility grant intact, and Couchy installed, enabled, `stopped=false`.
The stick had booted about 21:22 when the TV was turned on; in the snapshot the stock launcher held 125 MB PSS and
`com.amazon.venezia` (Appstore) 47 MB.

Verdict: no crash and no kill. Couchy sat in the background after the About visit in 06-ota-clear.md F0, and the
handoff from the stock Home back to Couchy was slow under memory pressure shortly after boot. The Home On Fire to
Couchy chain is intact. No action taken.

Reading (INFERENCE): this differs from the earlier drop-outs, where Couchy was killed and only reopening it helped.
Here the redirect was only late, so waiting a few seconds, or pressing Home once more, is the remedy. A visit to the
stock launcher's own screens (Settings, About) brings the stock launcher's memory up, which makes the slowness more
likely right after.

## Tune script prepared (DIRECT request, 2026-10-25 about 22:16 CT; not run yet)

[tune.sh](tune.sh), one run from the owner's Mac over adb: animation scales to 0.5 (window, transition, animator),
`pm trim-caches 999G` with `/data` usage before and after, then a verification block (build, 200 / 53, verifier 0,
D1 `ignore` for YouTube and Instagram) and a PASS / PROBLEM summary. It stops before any change if adb has no
authorized device or the build is not PS7717/5741, and it writes the exact restore lines for the scales it read
into its log. Dry-run here against a stubbed `adb`; not run on the stick.

Evidence on the scales (DOCUMENT): the list for this exact build (`examples/amazon-fire-tv-stick-lite-2020/`) says
0.5 helps; the Fire OS 8 list (`examples/amazon-fire-tv-stick-4k-2023/`) found that at 0.5 every entry in the stock
launcher's side menu closed the menu without opening anything, fixed by going back to 1.0. That was Fire OS 8; if
the stock launcher's menus misbehave here after the change, the restore lines put the scales back.
