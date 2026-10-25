# Runbook for a phone-driving agent: remaining stages

> **Status: complete (2026-10-25).** Kept as the record. Final state in [audit-log.md](audit-log.md), "Project complete".

**Who this is for:** an agent that operates the owner's iPhone and types into the atvTools app's ADB shell,
which is connected to the owner's Fire TV Stick Lite (AFTSS, Fire OS 7.7.1.7, PS7717/5741). It covers everything
still to do, in order, with the exact commands, what each should print, and what to do when it does not.

**Where things stand (AUDIT, 2026-10-24):** audit complete; stages A, B1 done; B2 changed and its first CHECK
passed (disabled 27, enabled 228), but **B2 is not closed**: its hand checks, reboot and post-reboot checks are
outstanding, and a third Couchy drop-out happened during B2's checks with no log read yet. Background for every
step is in [02-plan.md](02-plan.md), [audit-log.md](audit-log.md) and [01-gap-analysis.md](01-gap-analysis.md).

## Rules the agent must follow

1. **Only run commands from this file**, copied exactly, one code block per paste. Each block is one line.
   atvTools flattens multi-line pastes, so never split or join them, and never add your own commands except
   the read-only ones in this file.
2. **Copy the full output** of every block into a results log (step name, time, raw output). Do not summarise
   outputs in the log; the owner hands that log back for review.
3. **Restore lines first.** Before a change block, save its restore block as an atvTools snippet (or keep it
   ready to paste). Do not run a restore unless a stop condition says so.
4. **Ask the owner** at every step marked **OWNER**. The agent cannot see the TV screen or press the physical
   remote; those checks are the owner's. Do not mark a step passed without the owner's answer.
5. **Stop conditions.** Stop, run the current step's restore block (if it has one), ask the owner to reboot, and
   report, if any of these happen:
   - CHECK prints any `PROBLEM` line, HOME is not `name=com.amazon.tv.launcher.ui.HomeActivity_vNext`, A11Y is not
     `io.github.toolicious.homeonfire/.HijackService`, or a count is not the expected one;
   - a change prints anything other than `new state: disabled-user` or `Cannot disable a protected package`;
   - the owner reports a black screen, no Couchy after the recovery block, no stock launcher on long-press Home,
     an app that will not open, no Wi-Fi, NordVPN not connecting, or a dead remote;
   - atvTools cannot reconnect within 5 minutes of a reboot.
   A `Cannot disable a protected package` refusal is **not** a stop: note it and continue (the count is then one
   lower).
6. **Never:** run `pm uninstall` on anything but the one step that says so; force-stop Couchy, Home On Fire,
   NordVPN or `dev.vodik7.atvtoolsserver`; change accessibility settings; factory reset; install or remove apps
   beyond this file; touch packages not named here. Never paste serial numbers, MAC or IP addresses, Wi-Fi names
   or emails anywhere.
7. **Reboots:** paste `reboot` (atvTools then disconnects), wait about 2 minutes, reconnect atvTools, then go on.
8. A `Failed to write while dumping service package: Broken pipe` line in STATE output is harmless.

## Tools used throughout

**CHECK** (run where a step says CHECK). While Netflix is kept (13 apps):

```sh
F=/sdcard/deamazon/chk.txt; pm list packages -e | cat > $F; echo "== KEEP =="; for p in com.conreo.couchytv io.github.toolicious.homeonfire com.amazon.tv.launcher com.amazon.firehomestarter com.amazon.imp com.stremio.one com.amazon.firetv.youtube com.esaba.downloader com.amazon.cloud9 com.netflix.ninja com.instagram.airwave com.nordvpn.android dev.vodik7.atvtoolsserver; do grep -qx "package:$p" $F && echo "ok $p" || echo "PROBLEM $p"; done; echo "== ENABLED COUNT =="; wc -l < $F; echo "== HOME =="; cmd package resolve-activity -a android.intent.action.MAIN -c android.intent.category.HOME | grep -m1 "name="; echo "== A11Y =="; settings get secure enabled_accessibility_services; echo "== DISABLED COUNT =="; pm list packages -d | wc -l; echo "== SCREENSAVER =="; settings get secure screensaver_enabled
```
After step N removes Netflix, use this one instead (12 apps):

```sh
F=/sdcard/deamazon/chk.txt; pm list packages -e | cat > $F; echo "== KEEP =="; for p in com.conreo.couchytv io.github.toolicious.homeonfire com.amazon.tv.launcher com.amazon.firehomestarter com.amazon.imp com.stremio.one com.amazon.firetv.youtube com.esaba.downloader com.amazon.cloud9 com.instagram.airwave com.nordvpn.android dev.vodik7.atvtoolsserver; do grep -qx "package:$p" $F && echo "ok $p" || echo "PROBLEM $p"; done; echo "== ENABLED COUNT =="; wc -l < $F; echo "== HOME =="; cmd package resolve-activity -a android.intent.action.MAIN -c android.intent.category.HOME | grep -m1 "name="; echo "== A11Y =="; settings get secure enabled_accessibility_services; echo "== DISABLED COUNT =="; pm list packages -d | wc -l; echo "== SCREENSAVER =="; settings get secure screensaver_enabled
```
Expected: every KEEP line `ok`; ENABLED COUNT = 255 minus DISABLED COUNT (254 minus it once Netflix is
uninstalled); HOME `name=com.amazon.tv.launcher.ui.HomeActivity_vNext`; A11Y
`io.github.toolicious.homeonfire/.HijackService`; DISABLED COUNT as the step says; SCREENSAVER `0`.

**AUTO-HOME** (shell part of the hand checks; it injects a Home press and reads what is on screen, and whether the
VPN tunnel is up):

```sh
input keyevent KEYCODE_HOME; sleep 4; echo "== TOP AFTER HOME =="; dumpsys activity activities | grep -m1 mResumedActivity; echo "== VPN TUNNEL =="; ip link show tun0 2>/dev/null | head -1 || echo "no tun0"
```
Expected: `mResumedActivity` names `com.conreo.couchytv`; a `tun0` line containing `UP` (INFERENCE: NordVPN's
tunnel interface; if it prints `no tun0`, ask the owner to look at the NordVPN app before treating it as a fault).
An injected key is not proof for the real remote, so the owner still does the **OWNER** checks.

**APPS** (opens YouTube and Stremio, then goes Home; it does not play anything):

```sh
for p in com.amazon.firetv.youtube com.stremio.one; do echo "== $p =="; monkey -p $p -c android.intent.category.LEANBACK_LAUNCHER 1 >/dev/null 2>&1; sleep 6; dumpsys activity activities | grep -m1 mResumedActivity; done; input keyevent KEYCODE_HOME; sleep 4; echo "== BACK HOME =="; dumpsys activity activities | grep -m1 mResumedActivity
```
Expected: each section names that app's activity, and BACK HOME names `com.conreo.couchytv`. If an app
section names something else, ask the owner to open that app by hand before treating it as a fault.

**OWNER hand checks** (ask the owner; record yes or no for each):
1. Home on the remote shows Couchy.
2. Long-press Home opens the stock Amazon launcher; Home again returns to Couchy.
3. YouTube and Stremio open (and Netflix, while it is kept).
4. NordVPN shows connected.
5. Remote power and volume work.

**RECOVER** (Couchy drop-out: stock Home on screen and Home does not bring Couchy back):

```sh
monkey -p com.conreo.couchytv -c android.intent.category.LEANBACK_LAUNCHER 1 >/dev/null 2>&1; echo "couchy pid: $(pidof com.conreo.couchytv)"
```
Expected: `couchy pid:` followed by a number. If it prints nothing, ask the owner to open Couchy from the stock
launcher's app list. **Before** recovering, run CAPTURE and LOG-READ below and keep both outputs. A drop-out
during or right after heavy playback (Stremio) is the known memory issue, not a stage failure. A drop-out with
no heavy app open, repeated, is a stop condition.

**CAPTURE** (state during a drop-out):

```sh
echo "== A11Y =="; dumpsys accessibility | grep -i -E "bound|homeonfire" | head -8; echo "== PIDS =="; for p in com.conreo.couchytv io.github.toolicious.homeonfire com.stremio.one; do echo "$p: $(pidof $p)"; done; echo "== TOP =="; dumpsys activity activities | grep -m2 -E "mResumedActivity|mFocusedActivity"; echo "== MEM =="; head -3 /proc/meminfo
```
**LOG-READ** (memory kills and crashes; the events and main parts are wiped by a reboot):

```sh
echo "== EVENTS =="; logcat -d -b events | grep -i -E "am_kill|am_proc_died|am_low_memory|am_crash|am_anr" | grep -i -E "couchy|homeonfire|am_low_memory" | tail -25; echo "== MAIN =="; logcat -d -b main,system | grep -i -E "lowmemorykiller|lmkd|HijackService|homeonfire|couchytv" | tail -25; echo "== DROPBOX =="; dumpsys dropbox 2>/dev/null | grep -i -E "crash|anr" | tail -8
```
**UPTIME** (did a reboot happen, did an update arrive):

```sh
echo "== UPTIME =="; uptime; echo "== BUILD =="; getprop ro.build.version.name
```
Expected: BUILD `Fire OS 7.7.1.7 (PS7717/5741)`. Anything else: stop and report (an update arrived; the plan
was written for this build).

**The standard verification after every change** ("VERIFY"): CHECK, AUTO-HOME, APPS, OWNER hand checks, reboot,
UPTIME (uptime a few minutes), CHECK, the step's STATE block, OWNER hand checks again.

---

## Step R0: read the logs for the third drop-out (read-only, before the B2 reboot)

If the owner has not rebooted since the third drop-out, run LOG-READ now. If a reboot already happened, still run
it (the DROPBOX part survives). Record the output. **Decide:**
- Couchy `has died` near `am_low_memory` or `lowmemorykiller` lines, or a dropbox entry tagged `LMK_`: memory kill,
  B2 is not implicated; continue to R1.
- A `data_app_crash` for `com.conreo.couchytv` without an `LMK_` tag, or any line naming a B2 package
  (`dp.logger`, `ceviche`, `tv.developer.dataservice`, `livedeviceservice`, `privacypassservice`, `wifilocker`,
  `tv.acr`): stop and report before anything else.
- Nothing about Couchy at all: note it, continue to R1, and run CAPTURE plus LOG-READ at the next drop-out.

## Step R1: close B2

B2's packages: `com.amazon.dp.logger`, `com.amazon.ceviche`, `com.amazon.tv.developer.dataservice`, `com.amazon.livedeviceservice`, `com.amazon.privacypassservice`, `com.amazon.wifilocker`, `com.amazon.tv.acr`. Run VERIFY. Expected DISABLED COUNT **27**,
ENABLED COUNT **228** (227 if Netflix is already gone). B2's STATE block:

```sh
echo "== STATE =="; for p in com.amazon.dp.logger com.amazon.ceviche com.amazon.tv.developer.dataservice com.amazon.livedeviceservice com.amazon.privacypassservice com.amazon.wifilocker com.amazon.tv.acr; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Expected: `installed=true enabled=3` for all 7 after the reboot. Also confirm with the owner that Wi-Fi came back
by itself after the reboot (`wifilocker` handled saved Wi-Fi passwords). B2's restore, for a stop condition only:

```sh
echo "== RESTORE (enable) =="; for p in com.amazon.dp.logger com.amazon.ceviche com.amazon.tv.developer.dataservice com.amazon.livedeviceservice com.amazon.privacypassservice com.amazon.wifilocker com.amazon.tv.acr; do echo "$p: $(pm enable --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.dp.logger com.amazon.ceviche com.amazon.tv.developer.dataservice com.amazon.livedeviceservice com.amazon.privacypassservice com.amazon.wifilocker com.amazon.tv.acr; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
## Step N: Netflix (OWNER decision first)

Ask the owner: "Remove Netflix completely? It reinstalls from the Appstore, and you would sign in again." Only on
a clear yes:

```sh
echo "== UNINSTALL NETFLIX =="; pm uninstall com.netflix.ninja; echo "== STILL THERE? =="; pm path com.netflix.ninja || echo "gone"
```
Expected: `Success`, then `gone`. There is no restore line: undo is a reinstall from the Appstore. From now on use
the 12-app CHECK. ENABLED COUNT drops by one (254 minus DISABLED COUNT). Run CHECK once to confirm.
On a no or no answer: skip this step and keep using the 13-app CHECK.

## Step B3: disable ads, promos, notices, release notes, Live tab (9 packages)

Restore (save first, do not run):

```sh
echo "== RESTORE (enable) =="; for p in com.amazon.kso.blackbird com.amazon.sneakpeek com.amazon.hybridadidservice com.amazon.tv.easyupgrade com.amazon.systemnotices com.amazon.uxnotification com.amazon.tv.releasenotes com.amazon.franktvinput com.amazon.tv.livetv; do echo "$p: $(pm enable --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.kso.blackbird com.amazon.sneakpeek com.amazon.hybridadidservice com.amazon.tv.easyupgrade com.amazon.systemnotices com.amazon.uxnotification com.amazon.tv.releasenotes com.amazon.franktvinput com.amazon.tv.livetv; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Change:

```sh
echo "== DISABLE =="; for p in com.amazon.kso.blackbird com.amazon.sneakpeek com.amazon.hybridadidservice com.amazon.tv.easyupgrade com.amazon.systemnotices com.amazon.uxnotification com.amazon.tv.releasenotes com.amazon.franktvinput com.amazon.tv.livetv; do echo "$p: $(pm disable-user --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.kso.blackbird com.amazon.sneakpeek com.amazon.hybridadidservice com.amazon.tv.easyupgrade com.amazon.systemnotices com.amazon.uxnotification com.amazon.tv.releasenotes com.amazon.franktvinput com.amazon.tv.livetv; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Expected: `new state: disabled-user` for each (or a protected refusal), then `enabled=3`. Then VERIFY with DISABLED COUNT **36** (lower by one per protected refusal); STATE is the change block's STATE part.

Extra OWNER check for B3: long-press Home, leave the stock launcher on screen 30 seconds; it must draw its rows, not stay black. If the B3 output stops early, report it (these lines are about 700 characters).

## Step B4: disable setup helpers for other Amazon devices, Matter controller (4 packages)

Restore (save first, do not run):

```sh
echo "== RESTORE (enable) =="; for p in com.amazon.whisperjoin.middleware.np com.amazon.tv.ffsprovisioneeclient com.amazon.tv.mattercohost com.amazon.naatyam; do echo "$p: $(pm enable --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.whisperjoin.middleware.np com.amazon.tv.ffsprovisioneeclient com.amazon.tv.mattercohost com.amazon.naatyam; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Change:

```sh
echo "== DISABLE =="; for p in com.amazon.whisperjoin.middleware.np com.amazon.tv.ffsprovisioneeclient com.amazon.tv.mattercohost com.amazon.naatyam; do echo "$p: $(pm disable-user --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.whisperjoin.middleware.np com.amazon.tv.ffsprovisioneeclient com.amazon.tv.mattercohost com.amazon.naatyam; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Expected: `new state: disabled-user` for each (or a protected refusal), then `enabled=3`. Then VERIFY with DISABLED COUNT **40** (lower by one per protected refusal); STATE is the change block's STATE part.

## Step B5: disable Alexa alerts and media playback (5 packages)

Restore (save first, do not run):

```sh
echo "== RESTORE (enable) =="; for p in com.amazon.tv.alexaalerts com.amazon.tv.alexanotifications com.amazon.alexa.externalmediaplayer.fireos com.amazon.alexamediaplayer.runtime.ftv com.amazon.aiondec; do echo "$p: $(pm enable --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.tv.alexaalerts com.amazon.tv.alexanotifications com.amazon.alexa.externalmediaplayer.fireos com.amazon.alexamediaplayer.runtime.ftv com.amazon.aiondec; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Change:

```sh
echo "== DISABLE =="; for p in com.amazon.tv.alexaalerts com.amazon.tv.alexanotifications com.amazon.alexa.externalmediaplayer.fireos com.amazon.alexamediaplayer.runtime.ftv com.amazon.aiondec; do echo "$p: $(pm disable-user --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.tv.alexaalerts com.amazon.tv.alexanotifications com.amazon.alexa.externalmediaplayer.fireos com.amazon.alexamediaplayer.runtime.ftv com.amazon.aiondec; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Expected: `new state: disabled-user` for each (or a protected refusal), then `enabled=3`. Then VERIFY with DISABLED COUNT **45** (lower by one per protected refusal); STATE is the change block's STATE part.

Extra OWNER check: press the remote's mic button and say a short search; voice search must still work.

## Step B6: disable Alexa multi-room audio and hints (5 packages)

Restore (save first, do not run):

```sh
echo "== RESTORE (enable) =="; for p in com.amazon.audiohome com.amazon.whad com.amazon.whasettings com.amazon.wha.mediabrowserservice com.amazon.aca; do echo "$p: $(pm enable --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.audiohome com.amazon.whad com.amazon.whasettings com.amazon.wha.mediabrowserservice com.amazon.aca; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Change:

```sh
echo "== DISABLE =="; for p in com.amazon.audiohome com.amazon.whad com.amazon.whasettings com.amazon.wha.mediabrowserservice com.amazon.aca; do echo "$p: $(pm disable-user --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.audiohome com.amazon.whad com.amazon.whasettings com.amazon.wha.mediabrowserservice com.amazon.aca; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Expected: `new state: disabled-user` for each (or a protected refusal), then `enabled=3`. Then VERIFY with DISABLED COUNT **50** (lower by one per protected refusal); STATE is the change block's STATE part.

Extra OWNER check: press the remote's mic button and say a short search; voice search must still work.

## Step B7 (trial): Alexa voice core

The owner's rule removes it if it costs background memory (it does: about 23 MB, always running). Fire OS
re-enables it at every boot on four other Fire TV builds, so this is a test. While it is off, the mic button does
nothing.

Restore (save first):

```sh
echo "== RESTORE (enable) =="; for p in com.amazon.vizzini; do echo "$p: $(pm enable --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.vizzini; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Change:

```sh
echo "== DISABLE =="; for p in com.amazon.vizzini; do echo "$p: $(pm disable-user --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.vizzini; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Expected now: `disabled-user`, `enabled=3`. Then VERIFY (DISABLED COUNT one higher than after B6) without the
voice check. **After the reboot:** if STATE shows `enabled=0` or `enabled=1`, Fire OS brought it back: run the
restore block, record "vizzini returns at boot on this build", and continue (the count stays at B6's value). If it
still shows `enabled=3`, it stuck: record it and continue.

## Step C0: read-only look at app verification (then STOP and report)

```sh
echo "== VERIFIER RECEIVERS =="; cmd package query-receivers -a android.intent.action.PACKAGE_NEEDS_VERIFICATION -t application/vnd.android.package-archive | grep -E "packageName|name=" | head -10; for p in com.amazon.adep com.amazon.application.compatibility.enforcer; do echo "== $p =="; dumpsys package $p | grep -E "versionName|enabled=|BOOT_COMPLETED|PACKAGE_ADDED|PACKAGE_REPLACED|PACKAGE_NEEDS_VERIFICATION" | head -15; done; echo "== SETTING =="; settings get global package_verifier_enable
```
Expected: a short list. Nothing changes. **Stop here and hand the output to the owner for review**: whether
`com.amazon.adep`, `com.amazon.application.compatibility.enforcer` or the verifier setting get a change batch is
decided from it, outside this runbook. Then continue with C1.

## Step C1: attempt to disable the update packages

Success means no more Fire OS updates, including security patches. Refusal means nothing changed and updates
keep coming (a shell-only limit on this build). Either result is acceptable; record which.

Restore (save first):

```sh
echo "== RESTORE (enable) =="; for p in com.amazon.tv.forcedotaupdater.v2 com.amazon.device.software.ota.override com.amazon.device.software.ota; do echo "$p: $(pm enable --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.tv.forcedotaupdater.v2 com.amazon.device.software.ota.override com.amazon.device.software.ota; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Change:

```sh
echo "== DISABLE =="; for p in com.amazon.tv.forcedotaupdater.v2 com.amazon.device.software.ota.override com.amazon.device.software.ota; do echo "$p: $(pm disable-user --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.tv.forcedotaupdater.v2 com.amazon.device.software.ota.override com.amazon.device.software.ota; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Expected: `disabled-user` or `Cannot disable a protected package` for each. Then VERIFY (DISABLED COUNT up by
the number accepted), plus an OWNER check: Settings > My Fire TV > About opens (do not press Install).

## Step D0: baseline for app background behaviour (read-only)

OWNER: open YouTube, play a few seconds, press Back to Couchy (no force-stop); open Stremio and wait one minute
(do not play anything). Then:

```sh
for p in com.amazon.firetv.youtube com.instagram.airwave com.amazon.firebat com.amazon.vizzini; do echo "== $p =="; pm path $p >/dev/null 2>&1 || { echo "$p not installed, skipped"; continue; }; echo "pid: $(pidof $p)"; dumpsys meminfo $p | grep -m1 -E "TOTAL|No process"; echo "services: $(dumpsys activity services $p | grep -c ServiceRecord)"; echo "bg: $(cmd appops get $p RUN_ANY_IN_BACKGROUND)"; done
```
Expected per app: a pid or empty, memory or `No process found`, a service count, and `bg:` showing `allow` or
`default`.

## Step D1: stop background work for YouTube, Instagram and Prime Video

Restore (save first):

```sh
echo "== RESTORE (allow background) =="; for p in com.amazon.firetv.youtube com.instagram.airwave com.amazon.firebat; do pm path $p >/dev/null 2>&1 || { echo "$p not installed, skipped"; continue; }; cmd appops set $p RUN_ANY_IN_BACKGROUND allow; echo "$p: $(cmd appops get $p RUN_ANY_IN_BACKGROUND)"; done
```
Change:

```sh
echo "== RESTRICT BACKGROUND =="; for p in com.amazon.firetv.youtube com.instagram.airwave com.amazon.firebat; do pm path $p >/dev/null 2>&1 || { echo "$p not installed, skipped"; continue; }; cmd appops set $p RUN_ANY_IN_BACKGROUND ignore; echo "$p: $(cmd appops get $p RUN_ANY_IN_BACKGROUND)"; done
```
Expected: `RUN_ANY_IN_BACKGROUND: ignore` for each installed app. Then repeat the D0 OWNER steps and the D0
MEASURE block, and ask the OWNER: YouTube and Prime Video still signed in; casting from the phone to YouTube still
starts playback. Reboot, UPTIME, MEASURE again: `bg:` must still read `ignore`. If casting or sign-in broke, run
the restore block.

**Prime Video trigger:** if any MEASURE taken when the owner has not opened Prime Video shows a pid for
`com.amazon.firebat`, record it and report: it then gets its own disable batch, outside this runbook.

## Step D2: one-tap full quit (snippets only, no system change)

Save each as an atvTools snippet for the owner. They close an app fully and keep its logins.

```sh
am force-stop com.amazon.firetv.youtube; echo "stopped com.amazon.firetv.youtube"
```
```sh
am force-stop com.instagram.airwave; echo "stopped com.instagram.airwave"
```
```sh
am force-stop com.amazon.firebat; echo "stopped com.amazon.firebat"
```
```sh
am force-stop com.stremio.one; echo "stopped com.stremio.one"
```
Never make one for Couchy, Home On Fire, NordVPN or atvTools' helper.

## Done: what to hand back

The results log (every step, raw outputs, OWNER answers), plus a final CHECK and UPTIME. Open items that stay
with the owner: Q3 (keep the Appstore, recommended), the C0 decision, and U20 (Stremio's memory on this stick).
ADB stays on, because atvTools is how the owner runs RECOVER; turning ADB debugging off (Settings > My Fire TV >
Developer Options) is the owner's choice and disables atvTools until it is turned back on.
