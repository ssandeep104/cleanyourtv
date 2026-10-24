# De-Amazon plan, in stages

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
E=$(pm list packages -e); echo "== KEEP =="; for p in com.conreo.couchytv io.github.toolicious.homeonfire com.amazon.tv.launcher com.amazon.firehomestarter com.amazon.imp com.stremio.one com.amazon.firetv.youtube com.esaba.downloader com.amazon.cloud9 com.netflix.ninja com.instagram.airwave com.nordvpn.android dev.vodik7.atvtoolsserver; do echo "$E" | grep -qx "package:$p" && echo "ok $p" || echo "PROBLEM $p"; done; echo "== HOME =="; cmd package resolve-activity -a android.intent.action.MAIN -c android.intent.category.HOME | grep -m1 "name="; echo "== A11Y =="; settings get secure enabled_accessibility_services; echo "== DISABLED COUNT =="; pm list packages -d | wc -l
```
Expected: `ok` for all 13 apps (no `PROBLEM`), HOME names `com.amazon.tv.launcher.ui.HomeActivity_vNext`,
A11Y names `io.github.toolicious.homeonfire/.HijackService`, and a disabled count that moves as the stage says
(up by the batch size in stage B and C1, down by 4 after A2a, unchanged otherwise). Then paste the stage's own **STATE** line (the end of each change and restore line prints it too).

How to read STATE: `installed=true enabled=3` is disabled for you; `installed=false` is uninstalled for you;
`installed=true enabled=0` (default) or `enabled=1` is on.

Then by hand, on the TV:

1. Press **Home**: Couchy comes up.
2. **Long-press Home**: the stock Amazon launcher opens (your escape hatch). Press Home again: back to Couchy.
3. Open YouTube, Netflix and Stremio for a few seconds each.
4. NordVPN shows connected.
5. The remote's volume and power buttons still work.

**Reboot:** Settings > My Fire TV > Restart (or paste `reboot`; atvTools then loses the connection).
After it is back, reconnect atvTools, paste CHECK and the STATE line again, and repeat the five hand checks.

**If anything fails** (a `PROBLEM` line, Couchy or the escape hatch missing, a black screen, an app that will
not open): paste that stage's restore line, reboot, and send me the output. Do not start the next stage.

## Stage A: uninstall for user 0 (Amazon apps and tutorials)

Why uninstall here and disable in stage B (INFERENCE, your goal decides): these are standalone apps with no
other package depending on them, so removing them for your user is clean. The background services in stage B
are disabled instead: that is the form verified on your build, and a disabled service is easier to tell
apart in a check. `-k` keeps their data, so a restore brings them back as they were. Nothing is deleted from
the system image: a factory reset brings everything back.

### A1: test uninstall and restore on one harmless package (the remote tutorial)

Restore (save first):

```sh
echo "== RESTORE (install-existing) =="; for p in com.amazon.tmm.tutorial; do echo "$p: $(cmd package install-existing $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.tmm.tutorial; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Change:

```sh
echo "== UNINSTALL FOR USER 0 =="; for p in com.amazon.tmm.tutorial; do echo "$p: $(pm uninstall -k --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.tmm.tutorial; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Expected: `Success`, then `installed=false`.

Now prove the restore path: paste the restore line above. Expected:
`Package com.amazon.tmm.tutorial installed for user: 0`, then `installed=true enabled=0`.

Then paste the change line once more (expected `Success`, `installed=false`), and run CHECK, the hand checks,
reboot, and CHECK and STATE again.

**If the uninstall is refused** (`DELETE_FAILED_INTERNAL_ERROR` or any `Failure`): this firmware does not
take uninstall-for-user. Stop and tell me: stage A2 becomes a disable batch of the same packages.

### A2a: the four you had already disabled

Their restore puts them back exactly as you left them: installed and disabled.

Restore (save first):

```sh
echo "== RESTORE (install-existing) =="; for p in com.amazon.bueller.music com.amazon.tahoe com.amazon.ods.kindleconnect com.amazon.minitv.android.app; do echo "$p: $(cmd package install-existing $p 2>&1)"; done; echo "== BACK TO DISABLED (as before) =="; for p in com.amazon.bueller.music com.amazon.tahoe com.amazon.ods.kindleconnect com.amazon.minitv.android.app; do echo "$p: $(pm disable-user --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.bueller.music com.amazon.tahoe com.amazon.ods.kindleconnect com.amazon.minitv.android.app; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Change:

```sh
echo "== UNINSTALL FOR USER 0 =="; for p in com.amazon.bueller.music com.amazon.tahoe com.amazon.ods.kindleconnect com.amazon.minitv.android.app; do echo "$p: $(pm uninstall -k --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.bueller.music com.amazon.tahoe com.amazon.ods.kindleconnect com.amazon.minitv.android.app; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Expected: `Success` for each, then `installed=false` for each. Then CHECK, hand checks, reboot, CHECK and STATE again.

### A2b: the other three (Photos, the remote app tutorial, games hub)

Restore (save first):

```sh
echo "== RESTORE (install-existing) =="; for p in com.amazon.storm.lightning.tutorial com.amazon.bueller.photos com.amazon.gamehub; do echo "$p: $(cmd package install-existing $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.storm.lightning.tutorial com.amazon.bueller.photos com.amazon.gamehub; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Change:

```sh
echo "== UNINSTALL FOR USER 0 =="; for p in com.amazon.storm.lightning.tutorial com.amazon.bueller.photos com.amazon.gamehub; do echo "$p: $(pm uninstall -k --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.storm.lightning.tutorial com.amazon.bueller.photos com.amazon.gamehub; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Expected: `Success` for each, then `installed=false` for each. Then CHECK, hand checks, reboot, CHECK and STATE again.

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

### B3: ads, promos, notices, Live tab (8 packages)

Restore (save first):

```sh
echo "== RESTORE (enable) =="; for p in com.amazon.kso.blackbird com.amazon.sneakpeek com.amazon.hybridadidservice com.amazon.tv.easyupgrade com.amazon.systemnotices com.amazon.uxnotification com.amazon.franktvinput com.amazon.tv.livetv; do echo "$p: $(pm enable --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.kso.blackbird com.amazon.sneakpeek com.amazon.hybridadidservice com.amazon.tv.easyupgrade com.amazon.systemnotices com.amazon.uxnotification com.amazon.franktvinput com.amazon.tv.livetv; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Change:

```sh
echo "== DISABLE =="; for p in com.amazon.kso.blackbird com.amazon.sneakpeek com.amazon.hybridadidservice com.amazon.tv.easyupgrade com.amazon.systemnotices com.amazon.uxnotification com.amazon.franktvinput com.amazon.tv.livetv; do echo "$p: $(pm disable-user --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.kso.blackbird com.amazon.sneakpeek com.amazon.hybridadidservice com.amazon.tv.easyupgrade com.amazon.systemnotices com.amazon.uxnotification com.amazon.franktvinput com.amazon.tv.livetv; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
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

Background in [lifecycle.md](lifecycle.md). Applies to YouTube, Netflix, Instagram and Prime Video first; Stremio and Silk
only after these four behave. MEASURE also prints `vizzini` (Alexa voice) so its idle cost is on record.

### D0: baseline, before any change

On the TV: open YouTube, play a few seconds, press Back until you are on Couchy (no force-stop). Open Stremio
and wait one minute. Then paste **MEASURE**:

```sh
for p in com.amazon.firetv.youtube com.netflix.ninja com.instagram.airwave com.amazon.firebat com.amazon.vizzini; do echo "== $p =="; echo "pid: $(pidof $p)"; dumpsys meminfo $p | grep -m1 -E "TOTAL|No process"; echo "services: $(dumpsys activity services $p | grep -c ServiceRecord)"; echo "bg: $(cmd appops get $p RUN_ANY_IN_BACKGROUND)"; done
```
Expected per app: a pid or empty, memory or `No process found`, a count of running services, and the
background setting (`allow` or `default` now).

### D1: stop background work for the four apps

Restore (save first):

```sh
echo "== RESTORE (allow background) =="; for p in com.amazon.firetv.youtube com.netflix.ninja com.instagram.airwave com.amazon.firebat; do cmd appops set $p RUN_ANY_IN_BACKGROUND allow; echo "$p: $(cmd appops get $p RUN_ANY_IN_BACKGROUND)"; done
```
Change:

```sh
echo "== RESTRICT BACKGROUND =="; for p in com.amazon.firetv.youtube com.netflix.ninja com.instagram.airwave com.amazon.firebat; do cmd appops set $p RUN_ANY_IN_BACKGROUND ignore; echo "$p: $(cmd appops get $p RUN_ANY_IN_BACKGROUND)"; done
```
Expected: `RUN_ANY_IN_BACKGROUND: ignore` for each. Then repeat the D0 steps and MEASURE, and check by hand:
YouTube, Netflix and Prime Video are still signed in, and casting from your phone to YouTube still starts playback. Reboot,
MEASURE again (the setting should still read `ignore`).

### D2: one-tap full quit (snippets, no change to the system)

Save each as its own atvTools snippet and use it whenever you want an app fully closed. It keeps logins and data.

```sh
am force-stop com.amazon.firetv.youtube; echo "stopped com.amazon.firetv.youtube"
```
```sh
am force-stop com.netflix.ninja; echo "stopped com.netflix.ninja"
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
| Q4 | Turn the screensaver off in Settings (menu only, no package change)? Optional. | Nothing in the batches |
| 0.5c | The checkpoint paste, to find the one package lost in the 0.5 relay (likely `com.amazon.device.services`, INFERENCE: it runs in 0.8 but is not in the relayed list). | Completeness of the gap analysis only |
| U11, U12 | What FireSend Cleaner and `dev.app1.xyz` do for you. | Stage D overlap only |

Q1 (Prime Video) and Q2 (Alexa) are decided above. Stages A, B, C0, C1 and D do not wait on Q3 or Q4.
