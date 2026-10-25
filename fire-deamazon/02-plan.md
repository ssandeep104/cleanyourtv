# De-Amazon plan, in stages

> **Status: complete (2026-10-25).** Kept as the record. Final state in [audit-log.md](audit-log.md), "Project complete".

Written from [01-gap-analysis.md](01-gap-analysis.md). Every package in a batch is on this stick (AUDIT 0.5) and
was changed without harm on the same model and build in this repo (DOCUMENT,
`examples/amazon-fire-tv-stick-lite-2020/`), unless the stage says otherwise. Nothing else is in a batch.

## Rules for every stage

- **One line per paste.** Every batch is a single line (AUDIT 0.0). Each prints a label and one result line
  per package, so a refusal shows up next to its package name.
- **Restore first.** Each stage lists its restore batch before its change batch. Save the restore line in
  atvTools as a snippet before you run the change.
- **Never in any batch:** Couchy, Home On Fire, `com.amazon.tv.launcher`, `com.amazon.firehomestarter`,
  `com.amazon.imp`, and every package in the gap analysis's "Needed" and "Kept" categories.
- **One stage at a time,** in this order. Stop at the first problem.
- **Line length.** Lines up to about 680 characters work (AUDIT: CHECK ran to completion).

### The check, run after every change batch and again after the reboot

Paste **CHECK** (same line every stage):

```sh
F=/sdcard/deamazon/chk.txt; pm list packages -e | cat > $F; echo "== KEEP =="; for p in com.conreo.couchytv io.github.toolicious.homeonfire com.amazon.tv.launcher com.amazon.firehomestarter com.amazon.imp com.stremio.one com.amazon.firetv.youtube com.esaba.downloader com.amazon.cloud9 com.instagram.airwave com.nordvpn.android dev.vodik7.atvtoolsserver; do grep -qx "package:$p" $F && echo "ok $p" || echo "PROBLEM $p"; done; echo "== ENABLED COUNT =="; wc -l < $F; echo "== HOME =="; cmd package resolve-activity -a android.intent.action.MAIN -c android.intent.category.HOME | grep -m1 "name="; echo "== A11Y =="; settings get secure enabled_accessibility_services; echo "== DISABLED COUNT =="; pm list packages -d | wc -l; echo "== SCREENSAVER =="; settings get secure screensaver_enabled
```
CHECK writes the enabled list to `/sdcard/deamazon/chk.txt` through the `cat` pipe and checks each app against
that file (AUDIT, B1: an in-memory version of this check once reported every kept app missing while
`pm list packages -e` showed them all present; the file method is the one proven by the backup in 0.3).

Expected: `ok` for all 12 apps (13 until Netflix was uninstalled in runbook step N) (no `PROBLEM`), ENABLED COUNT equal to 254 minus the disabled count (255 before Netflix was uninstalled), SCREENSAVER `0`, HOME names `com.amazon.tv.launcher.ui.HomeActivity_vNext`,
A11Y names `io.github.toolicious.homeonfire/.HijackService`, and a disabled count that moves as the stage says
(up by the batch size after each A, B and C1 batch, unchanged otherwise; 9 at the start). Then paste the stage's own **STATE** line (the end of each change and restore line prints it too).

A `Failed to write while dumping service package: Broken pipe` line in STATE output is harmless: STATE reads
only the first matching line and closes the pipe, and `dumpsys` reports that (AUDIT, A2b).

How to read STATE: `installed=true enabled=3` is disabled for you; `installed=false` is uninstalled for you;
`installed=true enabled=0` (default) or `enabled=1` is on.

Then by hand, on the TV:

1. Press **Home**: Couchy comes up.
2. **Long-press Home**: the stock Amazon launcher opens (your escape hatch). Press Home again: back to Couchy.
3. Open YouTube and Stremio for a few seconds each.
4. NordVPN shows connected.
5. The remote's volume and power buttons still work.

**Reboot:** Settings > My Fire TV > Restart (or paste `reboot`; atvTools then loses the connection).
After it is back, reconnect atvTools, paste CHECK and the STATE line again, and repeat the five hand checks.

**If Couchy stops coming back on Home** (stock Home stays on screen), run **CAPTURE** before restarting:
the restart wipes the in-memory event log that records low-memory kills.

```sh
echo "== A11Y =="; dumpsys accessibility | grep -i -E "bound|homeonfire" | head -8; echo "== PIDS =="; for p in com.conreo.couchytv io.github.toolicious.homeonfire com.amazon.ftv.screensaver; do echo "$p: $(pidof $p)"; done; echo "== TOP =="; dumpsys activity activities | grep -m2 -E "mResumedActivity|mFocusedActivity"; echo "== EVENTS =="; logcat -d -b events | grep -E "am_kill|am_proc_died|am_low_memory|am_crash|am_anr" | grep -i -E "couchy|homeonfire|screensaver|am_low_memory" | tail -20
```

**If anything fails** (a `PROBLEM` line, Couchy or the escape hatch missing, a black screen, an app that will
not open): paste that stage's restore line, reboot, and send me the output. Do not start the next stage.

## Stage A: disable (Amazon apps and tutorials)

**Uninstall for user 0 is refused on this firmware** (AUDIT, first A1 run:
`com.amazon.tmm.tutorial: Failure [DELETE_FAILED_INTERNAL_ERROR]`, package unchanged at `installed=true
enabled=0`). So stage A disables the same packages instead, the same way as stage B. For your goal the
effect is the same: a disabled app cannot run, start at boot or show on any screen. The difference is only
that it stays listed in Settings > Applications as disabled.

### A1: disable test on one harmless package (the remote tutorial)

Restore (save first):

```sh
echo "== RESTORE (enable) =="; for p in com.amazon.tmm.tutorial; do echo "$p: $(pm enable --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.tmm.tutorial; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Change:

```sh
echo "== DISABLE =="; for p in com.amazon.tmm.tutorial; do echo "$p: $(pm disable-user --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.tmm.tutorial; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Expected: `Package com.amazon.tmm.tutorial new state: disabled-user`, then `installed=true enabled=3`.

Now prove the restore path: paste the restore line above. Expected: `new state: enabled`, then
`installed=true enabled=1`.

Then paste the change line once more (expected `disabled-user`, `enabled=3`), and run CHECK, the hand checks,
reboot, and CHECK and STATE again.

**If the disable is refused too** (`Cannot disable a protected package`, `SecurityException`, or any error):
stop and send it. Stage B uses the same command, so it would need rethinking first.

### A2a: the four you had already disabled: nothing to change

`com.amazon.bueller.music`, `com.amazon.tahoe`, `com.amazon.ods.kindleconnect` and
`com.amazon.minitv.android.app` are already disabled (AUDIT 0.6), which is the final state stage A wants.
With uninstall refused, there is no further step for them. Confirm they are still off:

```sh
echo "== STATE =="; for p in com.amazon.bueller.music com.amazon.tahoe com.amazon.ods.kindleconnect com.amazon.minitv.android.app; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Expected: `installed=true enabled=3` for all four. No restore line is needed: nothing changes.

### A2b: the other three (Photos, the remote app tutorial, games hub)

Restore (save first):

```sh
echo "== RESTORE (enable) =="; for p in com.amazon.storm.lightning.tutorial com.amazon.bueller.photos com.amazon.gamehub; do echo "$p: $(pm enable --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.storm.lightning.tutorial com.amazon.bueller.photos com.amazon.gamehub; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Change:

```sh
echo "== DISABLE =="; for p in com.amazon.storm.lightning.tutorial com.amazon.bueller.photos com.amazon.gamehub; do echo "$p: $(pm disable-user --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.storm.lightning.tutorial com.amazon.bueller.photos com.amazon.gamehub; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Expected: `new state: disabled-user` for each, then `installed=true enabled=3` for each. Then CHECK, hand checks, reboot, CHECK and STATE again.

## Stage B: disable (background services)

Six batches, one at a time, each with its own restore, check and reboot. A package that Fire OS refuses
(`Cannot disable a protected package`) stays as it was; note it and carry on, it is not a failure.
B5 and B6 are safe whether or not you keep Alexa voice: voice search kept working with all of them off on
your build (DOCUMENT).

### B1: metrics and performance collection (7 packages)

Restore (save first):

```sh
echo "== RESTORE (enable) =="; for p in com.amazon.client.metrics.api com.amazon.neo.minerva com.amazon.neo.minerva.logcat com.amazon.tv.fw.metrics com.amazon.wirelessmetrics.service com.amazon.perfcollection com.amazon.perfc; do echo "$p: $(pm enable --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.client.metrics.api com.amazon.neo.minerva com.amazon.neo.minerva.logcat com.amazon.tv.fw.metrics com.amazon.wirelessmetrics.service com.amazon.perfcollection com.amazon.perfc; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Change:

```sh
echo "== DISABLE =="; for p in com.amazon.client.metrics.api com.amazon.neo.minerva com.amazon.neo.minerva.logcat com.amazon.tv.fw.metrics com.amazon.wirelessmetrics.service com.amazon.perfcollection com.amazon.perfc; do echo "$p: $(pm disable-user --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.client.metrics.api com.amazon.neo.minerva com.amazon.neo.minerva.logcat com.amazon.tv.fw.metrics com.amazon.wirelessmetrics.service com.amazon.perfcollection com.amazon.perfc; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Expected: `new state: disabled-user` for each, then `enabled=3` for each. Then CHECK, hand checks, reboot, CHECK and STATE.

### B2: logging, data services, ACR, Wi-Fi password upload (7 packages)

Restore (save first):

```sh
echo "== RESTORE (enable) =="; for p in com.amazon.dp.logger com.amazon.ceviche com.amazon.tv.developer.dataservice com.amazon.livedeviceservice com.amazon.privacypassservice com.amazon.wifilocker com.amazon.tv.acr; do echo "$p: $(pm enable --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.dp.logger com.amazon.ceviche com.amazon.tv.developer.dataservice com.amazon.livedeviceservice com.amazon.privacypassservice com.amazon.wifilocker com.amazon.tv.acr; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Change:

```sh
echo "== DISABLE =="; for p in com.amazon.dp.logger com.amazon.ceviche com.amazon.tv.developer.dataservice com.amazon.livedeviceservice com.amazon.privacypassservice com.amazon.wifilocker com.amazon.tv.acr; do echo "$p: $(pm disable-user --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.dp.logger com.amazon.ceviche com.amazon.tv.developer.dataservice com.amazon.livedeviceservice com.amazon.privacypassservice com.amazon.wifilocker com.amazon.tv.acr; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Expected: `new state: disabled-user` for each, then `enabled=3` for each. Then CHECK, hand checks, reboot, CHECK and STATE.

### B3: ads, promos, notices, release notes, Live tab (9 packages)

Restore (save first):

```sh
echo "== RESTORE (enable) =="; for p in com.amazon.kso.blackbird com.amazon.sneakpeek com.amazon.hybridadidservice com.amazon.tv.easyupgrade com.amazon.systemnotices com.amazon.uxnotification com.amazon.tv.releasenotes com.amazon.franktvinput com.amazon.tv.livetv; do echo "$p: $(pm enable --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.kso.blackbird com.amazon.sneakpeek com.amazon.hybridadidservice com.amazon.tv.easyupgrade com.amazon.systemnotices com.amazon.uxnotification com.amazon.tv.releasenotes com.amazon.franktvinput com.amazon.tv.livetv; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Change:

```sh
echo "== DISABLE =="; for p in com.amazon.kso.blackbird com.amazon.sneakpeek com.amazon.hybridadidservice com.amazon.tv.easyupgrade com.amazon.systemnotices com.amazon.uxnotification com.amazon.tv.releasenotes com.amazon.franktvinput com.amazon.tv.livetv; do echo "$p: $(pm disable-user --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.kso.blackbird com.amazon.sneakpeek com.amazon.hybridadidservice com.amazon.tv.easyupgrade com.amazon.systemnotices com.amazon.uxnotification com.amazon.tv.releasenotes com.amazon.franktvinput com.amazon.tv.livetv; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Expected: `new state: disabled-user` for each, then `enabled=3` for each. Then CHECK, hand checks, reboot, CHECK and STATE. After B3, also open the stock launcher with long-press Home and leave it on screen for 30 seconds: it must draw rows, not a black screen (the black-Home case in audit-log 0.6 involved `imp`, which is not here).

### B4: setup helpers for other Amazon devices, Matter controller (4 packages)

Restore (save first):

```sh
echo "== RESTORE (enable) =="; for p in com.amazon.whisperjoin.middleware.np com.amazon.tv.ffsprovisioneeclient com.amazon.tv.mattercohost com.amazon.naatyam; do echo "$p: $(pm enable --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.whisperjoin.middleware.np com.amazon.tv.ffsprovisioneeclient com.amazon.tv.mattercohost com.amazon.naatyam; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Change:

```sh
echo "== DISABLE =="; for p in com.amazon.whisperjoin.middleware.np com.amazon.tv.ffsprovisioneeclient com.amazon.tv.mattercohost com.amazon.naatyam; do echo "$p: $(pm disable-user --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.whisperjoin.middleware.np com.amazon.tv.ffsprovisioneeclient com.amazon.tv.mattercohost com.amazon.naatyam; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Expected: `new state: disabled-user` for each, then `enabled=3` for each. Then CHECK, hand checks, reboot, CHECK and STATE.

### B5: Alexa alerts and media playback (5 packages)

Restore (save first):

```sh
echo "== RESTORE (enable) =="; for p in com.amazon.tv.alexaalerts com.amazon.tv.alexanotifications com.amazon.alexa.externalmediaplayer.fireos com.amazon.alexamediaplayer.runtime.ftv com.amazon.aiondec; do echo "$p: $(pm enable --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.tv.alexaalerts com.amazon.tv.alexanotifications com.amazon.alexa.externalmediaplayer.fireos com.amazon.alexamediaplayer.runtime.ftv com.amazon.aiondec; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Change:

```sh
echo "== DISABLE =="; for p in com.amazon.tv.alexaalerts com.amazon.tv.alexanotifications com.amazon.alexa.externalmediaplayer.fireos com.amazon.alexamediaplayer.runtime.ftv com.amazon.aiondec; do echo "$p: $(pm disable-user --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.tv.alexaalerts com.amazon.tv.alexanotifications com.amazon.alexa.externalmediaplayer.fireos com.amazon.alexamediaplayer.runtime.ftv com.amazon.aiondec; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Expected: `new state: disabled-user` for each, then `enabled=3` for each. Then CHECK, hand checks, reboot, CHECK and STATE.

### B6: Alexa multi-room audio and hints (5 packages)

Restore (save first):

```sh
echo "== RESTORE (enable) =="; for p in com.amazon.audiohome com.amazon.whad com.amazon.whasettings com.amazon.wha.mediabrowserservice com.amazon.aca; do echo "$p: $(pm enable --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.audiohome com.amazon.whad com.amazon.whasettings com.amazon.wha.mediabrowserservice com.amazon.aca; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Change:

```sh
echo "== DISABLE =="; for p in com.amazon.audiohome com.amazon.whad com.amazon.whasettings com.amazon.wha.mediabrowserservice com.amazon.aca; do echo "$p: $(pm disable-user --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.audiohome com.amazon.whad com.amazon.whasettings com.amazon.wha.mediabrowserservice com.amazon.aca; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Expected: `new state: disabled-user` for each, then `enabled=3` for each. Then CHECK, hand checks, reboot, CHECK and STATE.

### B7 (optional trial): disable Alexa voice core

See the Alexa verdict below. Expected outcome from four other Fire TV builds: Fire OS re-enables it at the next
boot. This trial tells us whether your build does the same. If STATE after the reboot shows `enabled=0`, it
came back: paste the restore line and leave it, since a package that returns at every boot is not worth fighting.

Restore (save first):

```sh
echo "== RESTORE (enable) =="; for p in com.amazon.vizzini; do echo "$p: $(pm enable --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.vizzini; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Change:

```sh
echo "== DISABLE =="; for p in com.amazon.vizzini; do echo "$p: $(pm disable-user --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.vizzini; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Expected now: `disabled-user`, `enabled=3`. While it is off, the remote's mic button does nothing. After the
reboot, STATE says which way your build goes.

## Stage C: updates and app verification

### C0: read-only look at the verification packages and the verifier setting

No change. Shows which component Android calls to verify installs, and what the two enforcement candidates
register for:

```sh
echo "== VERIFIER RECEIVERS =="; cmd package query-receivers -a android.intent.action.PACKAGE_NEEDS_VERIFICATION -t application/vnd.android.package-archive | grep -E "packageName|name=" | head -10; for p in com.amazon.adep com.amazon.application.compatibility.enforcer; do echo "== $p =="; dumpsys package $p | grep -E "versionName|enabled=|BOOT_COMPLETED|PACKAGE_ADDED|PACKAGE_REPLACED|PACKAGE_NEEDS_VERIFICATION" | head -15; done; echo "== SETTING =="; settings get global package_verifier_enable
```
Expected: a short list. I decide from it whether `adep`, `application.compatibility.enforcer` or the
verifier setting go into a C2 batch, or stay unresolved. Nothing changes until then.

### C1: attempt to disable the update packages

What success means: Fire OS stops downloading and installing updates, including security patches; you then
update apps only through the Appstore or by sideloading. What refusal means: nothing changed, updates keep
coming, and the shell cannot stop them on this build (see [ceiling.md](ceiling.md)).

Restore (save first):

```sh
echo "== RESTORE (enable) =="; for p in com.amazon.tv.forcedotaupdater.v2 com.amazon.device.software.ota.override com.amazon.device.software.ota; do echo "$p: $(pm enable --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.tv.forcedotaupdater.v2 com.amazon.device.software.ota.override com.amazon.device.software.ota; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Change:

```sh
echo "== DISABLE =="; for p in com.amazon.tv.forcedotaupdater.v2 com.amazon.device.software.ota.override com.amazon.device.software.ota; do echo "$p: $(pm disable-user --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.tv.forcedotaupdater.v2 com.amazon.device.software.ota.override com.amazon.device.software.ota; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Expected: either `disabled-user` or `Cannot disable a protected package` per package; both are useful.
Then CHECK, hand checks, plus: Settings > My Fire TV > About opens (do not press Install). Reboot, CHECK, STATE.

## Stage D: app lifecycle (quit on exit)

Background in [lifecycle.md](lifecycle.md). Applies to YouTube, Instagram and Prime Video first (Netflix is uninstalled); Stremio and Silk
only after these three behave. MEASURE also prints `vizzini` (Alexa voice) so its idle cost is on record.

### D0: baseline, before any change

On the TV: open YouTube, play a few seconds, press Back until you are on Couchy (no force-stop). Open Stremio
and wait one minute. Then paste **MEASURE**:

```sh
for p in com.amazon.firetv.youtube com.instagram.airwave com.amazon.firebat com.amazon.vizzini; do echo "== $p =="; echo "pid: $(pidof $p)"; dumpsys meminfo $p | grep -m1 -E "TOTAL|No process"; echo "services: $(dumpsys activity services $p | grep -c ServiceRecord)"; echo "bg: $(cmd appops get $p RUN_ANY_IN_BACKGROUND)"; done
```
Expected per app: a pid or empty, memory or `No process found`, a count of running services, and the
background setting (`allow` or `default` now).

### D1: stop background work for the three apps

Restore (save first):

```sh
echo "== RESTORE (allow background) =="; for p in com.amazon.firetv.youtube com.instagram.airwave com.amazon.firebat; do cmd appops set $p RUN_ANY_IN_BACKGROUND allow; echo "$p: $(cmd appops get $p RUN_ANY_IN_BACKGROUND)"; done
```
Change:

```sh
echo "== RESTRICT BACKGROUND =="; for p in com.amazon.firetv.youtube com.instagram.airwave com.amazon.firebat; do cmd appops set $p RUN_ANY_IN_BACKGROUND ignore; echo "$p: $(cmd appops get $p RUN_ANY_IN_BACKGROUND)"; done
```
Expected: `RUN_ANY_IN_BACKGROUND: ignore` for each. Then repeat the D0 steps and MEASURE, and check by hand:
YouTube and Prime Video are still signed in, and casting from your phone to YouTube still starts playback. Reboot,
MEASURE again (the setting should still read `ignore`).

### D2: one-tap full quit (snippets, no change to the system)

Save each as its own atvTools snippet and use it whenever you want an app fully closed. It keeps logins and data.

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
Never make one for Home On Fire (a force-stop switches its accessibility service off), Couchy or NordVPN.

## Proposals after C0 (decisions for the owner; nothing runs until decided)

### C0 result (AUDIT, 2026-10-25 snapshot)

`package_verifier_enable` = `1`. The receivers for `PACKAGE_NEEDS_VERIFICATION` resolve to `com.amazon.adep`
(two receivers): on this build, adep is Android's install-time package verifier. `adep` is `enabled=0`
(default, on). `com.amazon.application.compatibility.enforcer` is `enabled=0` and is not a verification receiver.

### Options for app verification

| Option | What it does | Risk on this build | Undo |
|---|---|---|---|
| 1. Leave as is | Amazon's verifier keeps checking each install | None new. Your current apps install and run today | Nothing to undo |
| 2. Verifier off (`package_verifier_enable 0`) **(recommended, as a trial)** | Android stops asking adep to approve installs | Low: one standard Android setting. It does not stop a launch-time block if Amazon enforces one some other way (INFERENCE: the late-2025 full-screen blocks came at launch). Fire OS may reset it at boot: the reboot check shows that | `settings put global package_verifier_enable 1` |
| 3. Disable `com.amazon.adep` | Removes the verifier itself | Higher: Android may then wait for a verifier that never answers on each install (a delay or a failed install), Appstore updates may break, and adep's other roles are unknown; this repo's Fire OS 8 list left it alone | `pm enable --user 0 com.amazon.adep` |
| 2 and 3 together | Both | The risks of 3 | Both undo lines |

Recommendation: option 2 now, option 3 not without a reason (a real block). The enforcer stays untouched (U15).

C2 restore (save first):

```sh
settings put global package_verifier_enable 1; echo "verifier: $(settings get global package_verifier_enable)"
```

C2 change:

```sh
settings put global package_verifier_enable 0; echo "verifier: $(settings get global package_verifier_enable)"
```

Expected: `verifier: 0`. Then CHECK, and one real install to prove installs still work (owner: update or install one
small app from Downloader or the Appstore). Reboot, then read it again with
`echo "verifier: $(settings get global package_verifier_enable)"`: `0` means it held; `1` means Fire OS resets it at
boot, and there is nothing more the shell can do.

## Verdicts: Prime Video and Alexa

Your rule (DIRECT): remove a component if just having it costs background weight; keep it if it costs
nothing while unused.

### Prime Video: keep, with background work stopped (D1)

- **Separable:** yes. It is its own package, `com.amazon.firebat`, plus `com.amazon.tv.support`. The Prime
  rows and tiles on the stock Home are the launcher's own feed, not this app, and the Appstore
  (`venezia`, `tigris`) is a different package. DOCUMENT: same-build list and the Fire OS 7 and 8 lists here.
- **Idle cost (AUDIT):** not running in either 0.8 snapshot; 97 MB PSS in 0.2, with no screen open. So it
  does not stay up on its own all the time, but it was left in memory at least once. `tv.support` was never
  seen running.
- **Removing it breaks:** the Prime Video app, Prime tiles on the stock Home, and "play X on Prime" by voice.
  A TCL Fire TV in this repo disables `firebat` without other harm (DOCUMENT, Fire OS 8, not your build).
- **Verdict:** keep it, add it to D1 so it cannot work in the background, and measure it in D0 and after
  D1. **Trigger:** if a MEASURE taken without you opening Prime Video shows `firebat` with a pid, it is
  starting by itself, which fails your rule: then it gets a disable batch (restore `pm enable --user 0
  com.amazon.firebat`).

### Alexa: remove the extras now (B5, B6); the voice core cannot be removed durably

What the stack costs (AUDIT, 0.2 PSS; 0.8 RSS in brackets, which double-counts shared memory):

| Part | Packages seen running | Idle cost | Plan |
|---|---|---|---|
| Hints and cue cards | `aca` | 39 MB (not running in 0.8) | B6 |
| Alexa media playback | `alexamediaplayer.runtime.ftv` and `:smbs` | 21 MB (32 to 40 MB) | B5 |
| Multi-room audio | `whad` | 7 MB (18 MB) | B6 |
| **Extras, total** | | **about 67 MB** | **B5, B6** |
| Voice core | `vizzini` | 23 MB (76 to 78 MB), resident in every snapshot | B7 trial |
| Shared with casting and voice | `tcomm` | 6 MB (27 MB) | Kept |

Not seen running, so they cost nothing idle and stay: `aria`, `cardinal`, `vizzini.ftvcds`,
`alexa.datastore.app`, `alexadirectivebrokerservice`, `androidskillconnectioncapability`,
`spotify.mediabrowserservice`, `comms.starktachyon`.

- **Removing the extras breaks:** Alexa alarms, timers, reminders and notifications on the TV; Alexa music
  playback on the stick; multi-room audio; Alexa Home Theater; skill connections; hint cards. **Voice search
  keeps working:** your build ran with all of them off (DOCUMENT, same-build list).
- **Removing the voice core would break:** the remote's mic button, voice search everywhere (including
  voice search inside YouTube and other apps, which goes through Alexa on Fire TV), voice dictation on the
  keyboard, and Alexa smart-home control.
- **Why it cannot go for good:** on four other Fire TV builds in this repo, Fire OS re-enabled `vizzini` at
  every boot. On the Hisense, `pm uninstall -k --user 0` was refused for it too, and on the TCL the
  `voice_disabled=1` setting was reset at boot (DOCUMENT: `amazon-fire-tv-stick-4k-2018`, `amazon-fire-tv-afteu014` on Fire OS 7, `hisense-fire-tv-aftcibfbd1`,
  `tcl-58s571f-fire-tv`).
- **Verdict:** B5 and B6 remove about two-thirds of Alexa's idle weight and keep voice search. The voice core
  (`vizzini`, about 23 MB, resident) fails your rule, so B7 tries to disable it once; if your build brings it
  back at boot like the others, it stays, and that 23 MB is part of the shell-only ceiling.

## What I still need from you, one at a time

| # | Question | Blocks |
|---|---|---|
| Q3 | Keep the Amazon Appstore? INFERENCE: your YouTube, Netflix and Instagram are Appstore builds and get their updates through it, so my recommendation is to keep it. | `venezia`, `tigris` |
| Q4 | ~~Screensaver off~~ Done: Start Time set to Never by the owner after the A2b incident (U18). | Nothing in the batches |
| U11, U12 | What FireSend Cleaner and `dev.app1.xyz` do for you. | Stage D overlap only |

Q1 (Prime Video) and Q2 (Alexa) are decided above. Stages A, B, C0, C1 and D do not wait on Q3.
