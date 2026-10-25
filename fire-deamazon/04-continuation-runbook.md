# Continuation runbook: C1 verification, C2 install proof, stage D, final owner checks

**One job for the owner's local Codex**, which drives the iPhone, types into the atvTools ADB shell connected to
the Fire TV Stick Lite (AFTSS `sheldon`, Fire OS 7.7.1.7, PS7717/5741), can reboot the stick, launch apps and read
the TV screen. It replaces the remaining part of [03-runbook.md](03-runbook.md). Background:
[02-plan.md](02-plan.md), [audit-log.md](audit-log.md).

## Starting state (DIRECT, 2026-10-25)

- Build `Fire OS 7.7.1.7 (PS7717/5741)`.
- Expected counts: **ENABLED 203, DISABLED 51**. Keep list is the 12-app version (Netflix uninstalled).
- C2 applied: `package_verifier_enable` = `0`; persistence across a reboot not yet checked.
- C1 partial: `com.amazon.tv.forcedotaupdater.v2` disabled (`enabled=3`); `com.amazon.device.software.ota.override`
  and `com.amazon.device.software.ota` refused as protected, unchanged at `enabled=0`.
- **An update is already staged:** About shows "Update to install: System components" and says it will begin
  automatically the next time the stick is not in use. The two packages that install it are protected, so the
  shell cannot stop it. It may install at the reboot in section 1 or at any idle moment. If it does, the build
  changes and this runbook stops (rule 5).
- The stick is powered from the TV's USB port; a USB Power Warning was shown and dismissed (DIRECT).

## Rules

1. **Only the commands in this file**, copied exactly. Each code block is one line and one paste (atvTools
   flattens multi-line pastes). Navigation keys and screen reading through the harness are allowed where a step
   says so; no other shell commands except those here.
2. **Results log, same format as before:** for every block, the step id, the local time, the exact command, and
   the raw output, unedited. For every screen read, what the screen showed, word for word where the step asks.
3. **Restore first:** before each change block, save the section's restore block as an atvTools snippet and say
   so in the log. Run a restore only when a stop condition says so.
4. **Never:** press or select "Install Update" or anything that starts an update; disable `com.amazon.adep`;
   touch `com.amazon.application.compatibility.enforcer`; disable, enable or uninstall any package not named
   here; force-stop Couchy, Home On Fire, NordVPN or `dev.vodik7.atvtoolsserver`; change accessibility settings;
   factory reset. Never write serial numbers, MAC or IP addresses, Wi-Fi names or emails into the log.
5. **Stop conditions, everywhere.** Run the current section's restore block (if it has one), reboot only if the
   section says so, write the evidence in the log, and **stop the whole runbook** if:
   - CHECK prints any `PROBLEM` line, HOME is not `name=com.amazon.tv.launcher.ui.HomeActivity_vNext`, A11Y is not
     `io.github.toolicious.homeonfire/.HijackService`, or a count differs from the expected one;
   - the build is anything other than `Fire OS 7.7.1.7 (PS7717/5741)` (the staged update installed: do not restore
     anything, just log CHECK and stop);
   - the Home screen is black, or an app that should open does not;
   - atvTools cannot reconnect within 5 minutes of a reboot.
6. **Couchy drop-out** (stock Home on screen, Home does not bring Couchy back): run CAPTURE, then LOG-READ, then
   RECOVER, and log all three. After or during heavy playback it is the known memory issue: carry on. Twice
   without a heavy app open: stop condition.
7. **Reboot procedure:** paste `reboot`, wait about 2 minutes, reconnect atvTools.
8. A `Failed to write while dumping service package: Broken pipe` line in STATE output is harmless.

## Tools

**CHECK** (12-app):

```sh
F=/sdcard/deamazon/chk.txt; pm list packages -e | cat > $F; echo "== KEEP =="; for p in com.conreo.couchytv io.github.toolicious.homeonfire com.amazon.tv.launcher com.amazon.firehomestarter com.amazon.imp com.stremio.one com.amazon.firetv.youtube com.esaba.downloader com.amazon.cloud9 com.instagram.airwave com.nordvpn.android dev.vodik7.atvtoolsserver; do grep -qx "package:$p" $F && echo "ok $p" || echo "PROBLEM $p"; done; echo "== ENABLED COUNT =="; wc -l < $F; echo "== HOME =="; cmd package resolve-activity -a android.intent.action.MAIN -c android.intent.category.HOME | grep -m1 "name="; echo "== A11Y =="; settings get secure enabled_accessibility_services; echo "== DISABLED COUNT =="; pm list packages -d | wc -l; echo "== SCREENSAVER =="; settings get secure screensaver_enabled
```
Expected: 12 lines `ok ...`; ENABLED COUNT `203`; HOME `name=com.amazon.tv.launcher.ui.HomeActivity_vNext`;
A11Y `io.github.toolicious.homeonfire/.HijackService`; DISABLED COUNT `51`; SCREENSAVER `0`. These counts hold
for the whole runbook (stage D changes no package state).

**AUTO-HOME:**

```sh
input keyevent KEYCODE_HOME; sleep 4; echo "== TOP AFTER HOME =="; dumpsys activity activities | grep -m1 mResumedActivity; echo "== VPN TUNNEL =="; ip link show tun0 2>/dev/null | head -1 || echo "no tun0"
```
Expected: `mResumedActivity` containing `com.conreo.couchytv`; a VPN TUNNEL line containing `tun0` and `UP`. If it
prints `no tun0`, read the screen of the NordVPN app (open it with the harness) and log whether it says
connected before treating it as a fault. Also read the TV screen: Couchy's home, not black.

**APPS:**

```sh
for p in com.amazon.firetv.youtube com.stremio.one; do echo "== $p =="; monkey -p $p -c android.intent.category.LEANBACK_LAUNCHER 1 >/dev/null 2>&1; sleep 6; dumpsys activity activities | grep -m1 mResumedActivity; done; input keyevent KEYCODE_HOME; sleep 4; echo "== BACK HOME =="; dumpsys activity activities | grep -m1 mResumedActivity
```
Expected: the YouTube section contains `com.amazon.firetv.youtube`, the Stremio section `com.stremio.one`, and
BACK HOME `com.conreo.couchytv`. Confirm on the TV screen that each app drew its own screen.

**CAPTURE**, **LOG-READ**, **RECOVER** (only for rule 6):

```sh
echo "== A11Y =="; dumpsys accessibility | grep -i -E "bound|homeonfire" | head -8; echo "== PIDS =="; for p in com.conreo.couchytv io.github.toolicious.homeonfire com.stremio.one; do echo "$p: $(pidof $p)"; done; echo "== TOP =="; dumpsys activity activities | grep -m2 -E "mResumedActivity|mFocusedActivity"; echo "== MEM =="; head -3 /proc/meminfo
```
```sh
echo "== EVENTS =="; logcat -d -b events | grep -i -E "am_kill|am_proc_died|am_low_memory|am_crash|am_anr" | grep -i -E "couchy|homeonfire|am_low_memory" | tail -25; echo "== MAIN =="; logcat -d -b main,system | grep -i -E "lowmemorykiller|lmkd|HijackService|homeonfire|couchytv" | tail -25; echo "== DROPBOX =="; dumpsys dropbox 2>/dev/null | grep -i -E "crash|anr" | tail -8
```
```sh
monkey -p com.conreo.couchytv -c android.intent.category.LEANBACK_LAUNCHER 1 >/dev/null 2>&1; echo "couchy pid: $(pidof com.conreo.couchytv)"
```
RECOVER expected: `couchy pid:` followed by a number, and Couchy on the TV screen.

---

## Section 1: C1 verification (and C2 persistence)

**Restore for this section** (save first; only for a stop condition): it re-enables the one package C1 changed.

```sh
echo "== RESTORE (enable) =="; for p in com.amazon.tv.forcedotaupdater.v2; do echo "$p: $(pm enable --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.tv.forcedotaupdater.v2; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
1.1 Run CHECK. Expected as in Tools (203 / 51).

1.2 Run AUTO-HOME, then APPS. Expected as in Tools.

1.3 Reboot (rule 7). **This reboot may install the staged update.**

1.4 Right after reconnecting:

```sh
echo "== UPTIME =="; uptime; echo "== BUILD =="; getprop ro.build.version.name; echo "verifier: $(settings get global package_verifier_enable)"; echo "== STATE =="; for p in com.amazon.tv.forcedotaupdater.v2 com.amazon.device.software.ota.override com.amazon.device.software.ota; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Expected and validation:
- UPTIME a few minutes.
- BUILD `Fire OS 7.7.1.7 (PS7717/5741)`. Anything else: the staged update installed. **Stop** (rule 5), after
  running CHECK once and logging it.
- `verifier: 0` means C2 held across the reboot; `verifier: 1` means Fire OS resets it at boot. Log which; neither
  is a stop.
- STATE: `com.amazon.tv.forcedotaupdater.v2 installed=true enabled=3`; the two `ota` packages `installed=true
  enabled=0`. If `forcedotaupdater.v2` reads `enabled=0` or `1`, Fire OS re-enabled it at boot: log it, not a stop.

1.5 Run CHECK (expected 203 / 51; if 1.4 showed `forcedotaupdater.v2` re-enabled, expected 204 / 50), AUTO-HOME
and APPS.

1.6 About re-look (screen only). With the harness: Home, then Settings > My Fire TV > About. Read and log, word
for word: whether "Install Update" or "Update to install: System components" still shows, and the exact sentence
about when it installs. **Do not select Install Update or any update item.** Then press Home and run AUTO-HOME.
If a USB power warning appears, dismiss it and log its text.

## Section 2: C2 install proof (verifier off)

**Restore for this section** (save first; run only if an install fails):

```sh
settings put global package_verifier_enable 1; echo "verifier: $(settings get global package_verifier_enable)"
```
2.1 Record the third-party apps before:

```sh
pm list packages -3 | sort | cat > /sdcard/deamazon/third-before.txt; echo "third-party before: $(wc -l < /sdcard/deamazon/third-before.txt)"; echo "verifier: $(settings get global package_verifier_enable)"
```
Expected: `third-party before: 17` (18 at the audit, minus Netflix) and `verifier: 0` (or `1` if 1.4 showed the
reset; then write in the log that this proof ran with the verifier on, and continue).

2.2 With the harness, open the Amazon Appstore and install **one small, free app that needs no sign-in or
payment** (a speed test or a clock app; log its exact name). Wait for the install to finish. Do not buy, sign in,
or grant anything beyond the defaults.

2.3 Record what was added:

```sh
pm list packages -3 | sort | cat > /sdcard/deamazon/third-after.txt; echo "third-party after: $(wc -l < /sdcard/deamazon/third-after.txt)"; echo "== NEW PACKAGE =="; grep -vxFf /sdcard/deamazon/third-before.txt /sdcard/deamazon/third-after.txt
```
Expected: `third-party after: 18` and exactly one package name under NEW PACKAGE. Then open that app from the
Appstore's Open button, read the screen to confirm it drew its own screen, and press Home.

2.4 Remove the test app, using the exact name printed under NEW PACKAGE in place of `<new package>`. This is the
one place where the agent fills in a package name, and only from 2.3's output:

```sh
pm uninstall <new package>; echo "== STILL THERE? =="; pm path <new package> || echo "gone"
```

Expected: `Success`, then `gone`.

Validation: the install completed, the app opened, it is removed. **If the install fails, hangs for more than 5
minutes, or shows a verification or blocked message:** read and log the message, run this section's restore,
read the setting back (`verifier: 1`), retry the install once and log the result, then skip to section 3 (not a
stop for the whole runbook).

2.5 Run CHECK (203 / 51).

## Section 3: D0 baseline measurement (read-only)

3.1 This opens YouTube, backs out with Back four times (no force-stop), opens Stremio and waits one minute
without playing anything:

```sh
monkey -p com.amazon.firetv.youtube -c android.intent.category.LEANBACK_LAUNCHER 1 >/dev/null 2>&1; sleep 15; for i in 1 2 3 4; do input keyevent KEYCODE_BACK; sleep 2; done; echo "== AFTER BACK =="; dumpsys activity activities | grep -m1 mResumedActivity; monkey -p com.stremio.one -c android.intent.category.LEANBACK_LAUNCHER 1 >/dev/null 2>&1; sleep 60; echo "== AFTER STREMIO 60s =="; dumpsys activity activities | grep -m1 mResumedActivity
```
This line takes about 90 seconds. If atvTools times out before it prints, log that and do the same steps through the harness instead (open YouTube, wait 15 s, Back four times, open Stremio, wait 60 s), then go on to 3.2.

Expected: AFTER BACK shows `com.conreo.couchytv` (if it still shows YouTube, log it and continue);
AFTER STREMIO shows `com.stremio.one`. Do not play anything in Stremio.

3.2 MEASURE:

```sh
for p in com.amazon.firetv.youtube com.instagram.airwave com.amazon.firebat com.amazon.vizzini; do echo "== $p =="; echo "pid: $(pidof $p)"; dumpsys meminfo $p | grep -m1 -E "TOTAL|No process"; echo "services: $(dumpsys activity services $p | grep -c ServiceRecord)"; echo "bg: $(cmd appops get $p RUN_ANY_IN_BACKGROUND)"; done
```
Expected, per app, five lines: `== <package> ==`; `pid:` with a number or empty; a `TOTAL` memory line or
`No process found`; `services:` with a number; `bg:` with `RUN_ANY_IN_BACKGROUND: allow` (or `default`). Log
all of it; there is no pass or fail here. Then press Home and run AUTO-HOME.

## Section 4: D1 stop background work for YouTube, Instagram, Prime Video

**Restore for this section** (save first):

```sh
echo "== RESTORE (allow background) =="; for p in com.amazon.firetv.youtube com.instagram.airwave com.amazon.firebat; do cmd appops set $p RUN_ANY_IN_BACKGROUND allow; echo "$p: $(cmd appops get $p RUN_ANY_IN_BACKGROUND)"; done
```
4.1 Change:

```sh
echo "== RESTRICT BACKGROUND =="; for p in com.amazon.firetv.youtube com.instagram.airwave com.amazon.firebat; do cmd appops set $p RUN_ANY_IN_BACKGROUND ignore; echo "$p: $(cmd appops get $p RUN_ANY_IN_BACKGROUND)"; done
```
Expected: three lines ending `RUN_ANY_IN_BACKGROUND: ignore`. Anything else: run the restore, stop (rule 5).

4.2 Repeat 3.1 and 3.2. Expected: same format; `bg:` now `ignore` for the three apps (`vizzini` unchanged).
Log the numbers next to 3.2's.

4.3 Each app still opens:

```sh
for p in com.amazon.firetv.youtube com.instagram.airwave com.amazon.firebat; do echo "== $p =="; monkey -p $p -c android.intent.category.LEANBACK_LAUNCHER 1 >/dev/null 2>&1; sleep 8; dumpsys activity activities | grep -m1 mResumedActivity; done; input keyevent KEYCODE_HOME; sleep 4; echo "== BACK HOME =="; dumpsys activity activities | grep -m1 mResumedActivity
```
Expected: each section names its own app (`com.amazon.firetv.youtube`, `com.instagram.airwave`,
`com.amazon.firebat`), BACK HOME names `com.conreo.couchytv`. Read the screen in each app: if a profile or
account name is visible, log only "signed in" or "signed out", never the name. An app that shows signed out
when it was signed in before, or does not open: run the restore, stop (rule 5).

4.4 Reboot (rule 7). Then run the section 1.4 block again (build check first; same rules), then:

```sh
echo "== BACKGROUND SETTING =="; for p in com.amazon.firetv.youtube com.instagram.airwave com.amazon.firebat; do echo "$p: $(cmd appops get $p RUN_ANY_IN_BACKGROUND)"; done
```
Expected: three lines ending `ignore` (the setting survives a reboot). If any reads `allow` or `default`, log
"D1 does not persist across reboot" and continue.

4.5 Run CHECK (203 / 51), AUTO-HOME, APPS.

4.6 **Prime Video trigger:** if 3.2 or 4.2 showed a `pid` number for `com.amazon.firebat` although Prime Video was
not opened in this runbook before that point, log "firebat starts by itself". Do not act on it; it is for review.

## Section 5: D2 one-tap full quit snippets (no system change)

Save these four blocks as atvTools snippets named "Quit YouTube", "Quit Instagram", "Quit Prime Video" and
"Quit Stremio". Do not run them now. They close an app fully and keep its sign-in.

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
Also save RECOVER as a snippet named "Bring Couchy back".

## Section 6: final state and the owner's batched checks

6.1 Run CHECK and the section 1.4 block once more, and log both as the final state.

6.2 Leave these for the owner (Sandeep) to do at the TV, in this order, and write them at the end of the log as
a checklist with blank answers:

1. Physical remote Home: Couchy comes up.
2. Long-press Home: the stock Amazon launcher opens; Home again: back to Couchy.
3. Cast to YouTube from the phone: playback starts on the TV (this is the D1 casting check).
4. Volume up and down on the remote work.
5. Power button **last**: it turns the TV off, and with the stick on the TV's USB port that also cuts the stick's
   power.

If 3 fails, the owner runs the section 4 restore snippet.

## What to hand back

The results log, plus a short summary at the top: whether the build stayed PS7717/5741, `verifier` after each
reboot, `forcedotaupdater.v2` after each reboot, the About wording from 1.6, the test app's name and result, the
3.2 and 4.2 MEASURE numbers side by side, whether D1 persisted, any drop-outs with their CAPTURE and LOG-READ.
