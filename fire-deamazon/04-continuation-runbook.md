# Continuation runbook: C1 verification, C2 install proof, stage D, final owner checks

> **Status: complete (2026-10-25).** Kept as the record. Final state in [audit-log.md](audit-log.md), "Project complete".

**One job for the owner's local Codex**, which drives the iPhone, types into the atvTools ADB shell connected to
the Fire TV Stick Lite (AFTSS `sheldon`, Fire OS 7.7.1.7, PS7717/5741), can reboot the stick, launch apps and read
the TV screen. It replaces the remaining part of [03-runbook.md](03-runbook.md). Background:
[02-plan.md](02-plan.md), [audit-log.md](audit-log.md).

## Starting state (DIRECT, 2026-10-25; verified in Section 0, not assumed)

- Build `Fire OS 7.7.1.7 (PS7717/5741)`.
- Expected counts: **ENABLED 203, DISABLED 51** (254 installed). Keep list is the 12-app version (Netflix
  uninstalled).
- **Why this differs from Codex's own last endpoint (204 / 50, verifier on):** after Codex's previous run ended,
  the owner ran two steps by hand: C2 (`package_verifier_enable` set to `0`) and C1 (`forcedotaupdater.v2`
  disabled, one more disabled package). Section 0 reads the real state before anything else.
- C2 applied: `package_verifier_enable` = `0`; persistence across a reboot not yet checked.
- C1 partial: `com.amazon.tv.forcedotaupdater.v2` disabled (`enabled=3`); `com.amazon.device.software.ota.override`
  and `com.amazon.device.software.ota` refused as protected, unchanged at `enabled=0`.
- **An update is already staged:** About shows "Update to install: System components" and says it will begin
  automatically the next time the stick is not in use. The two packages that install it are protected, so the
  shell cannot stop it. It may install at the reboot in section 1 or at any idle moment. If it does, the build
  changes and this runbook stops (rule 5).
- **Power (DIRECT):** the stick is powered from the TV's USB port, so turning the TV off (or the TV going to
  standby on its own) cuts the stick's power. When the owner highlighted Install Update on About, Fire OS showed
  a "USB Power Warning": "USB power may not be sufficient for a system update. We recommend using the included
  USB cable and Amazon power adapter for best results." Behind it About read "An update is available" and
  "Update to install: System components". The owner dismissed it with OK and did not press Install.
  The warning is advisory (INFERENCE): it does not prove the staged update cannot install on this power, so
  rule 5's build check stays. Two consequences for this runbook:
  - **Keep the TV on for the whole run.** If the TV switches off or sleeps, the stick loses power: treat it as a
    reboot (rule 7), run the section 1.4 block first, then re-run the STATE or read line of the section you were
    in, and log "power loss" with the time.
  - If the stick loses power while an update is installing, the install is interrupted. Fire OS normally retries
    it (INFERENCE, not verified on this build), but if the TV screen shows an update or recovery screen, or the
    stick does not come back within 10 minutes, stop and leave the stick alone for the owner.

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
Expected: 12 lines `ok ...`; ENABLED COUNT = **BASE_E**; HOME `name=com.amazon.tv.launcher.ui.HomeActivity_vNext`;
A11Y `io.github.toolicious.homeonfire/.HijackService`; DISABLED COUNT = **BASE_D**; SCREENSAVER `0`. BASE_E and
BASE_D are the baseline recorded in Section 0 (and updated only where a step says so). Stage D changes no
package state, so "counts = baseline" holds everywhere unless a step says otherwise.

**AUTO-HOME:**

```sh
input keyevent KEYCODE_HOME; echo "== HOME SAMPLES (every 3 s, up to 15 s) =="; i=0; while [ $i -lt 5 ]; do sleep 3; i=$((i+1)); t=$(dumpsys activity activities | grep -m1 mResumedActivity); echo "sample $i: $t"; case "$t" in *couchytv*) break;; esac; done; echo "couchy pid: $(pidof com.conreo.couchytv)"; echo "== FOCUS WINDOW =="; dumpsys window windows | grep -m1 mCurrentFocus; echo "== HOME ON FIRE SERVICE =="; dumpsys accessibility | grep -m2 -i homeonfire; echo "== VPN TUNNEL =="; if ip link show tun0 >/dev/null 2>&1; then if ip link show tun0 | grep -q UP; then echo TUN0_UP; else echo TUN0_PRESENT_NOT_UP; fi; else echo TUN0_ABSENT; fi; echo "nordvpn pid: $(pidof com.nordvpn.android)"
```
How to read it:
- **Home:** pass when a sample contains `com.conreo.couchytv`, `couchy pid:` shows a number, and FOCUS WINDOW
  names `com.conreo.couchytv`. Home On Fire's redirect has been logged taking about 3.6 seconds, so an early
  sample naming `com.amazon.tv.launcher` is **inconclusive, not a failure**; only all five samples (15 s) without
  Couchy count as a failure. A failure is handled as a Couchy drop-out (rule 6): CAPTURE, LOG-READ, RECOVER,
  then run AUTO-HOME once more; a second failure is a stop (rule 5). Also read the TV screen: Couchy, not black.
- **HOME ON FIRE SERVICE:** at least one line naming `homeonfire` (its service is known to the system).
- **VPN:** exactly one of `TUN0_UP` (pass), `TUN0_PRESENT_NOT_UP` or `TUN0_ABSENT`, then `nordvpn pid:`. For
  the last two, open the NordVPN app with the harness and log whether its screen says connected; if it says
  connected, pass (NordVPN may use another interface name, INFERENCE); if not, it is a stop (rule 5).

**APPS:**

```sh
for p in com.amazon.firetv.youtube com.stremio.one; do echo "== $p =="; monkey -p $p -c android.intent.category.LEANBACK_LAUNCHER 1 >/dev/null 2>&1; k=0; while [ $k -lt 5 ]; do sleep 3; k=$((k+1)); t=$(dumpsys activity activities | grep -m1 mResumedActivity); echo "sample $k: $t"; case "$t" in *"$p"*) break;; esac; done; done; input keyevent KEYCODE_HOME; echo "== BACK HOME =="; i=0; while [ $i -lt 5 ]; do sleep 3; i=$((i+1)); t=$(dumpsys activity activities | grep -m1 mResumedActivity); echo "sample $i: $t"; case "$t" in *couchytv*) break;; esac; done
```
Expected: in each app section, a sample containing that app's package (it polls up to 15 s and stops at the first
match); BACK HOME read the same way as AUTO-HOME (an early stock-launcher sample is inconclusive). Confirm on the
TV screen that each app drew its own screen.

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

## Section 0: pre-flight, record the BASELINE (read-only)

```sh
echo "== BUILD =="; getprop ro.build.version.name; echo "== ENABLED =="; pm list packages -e | wc -l; echo "== DISABLED =="; pm list packages -d | wc -l; echo "== INSTALLED =="; pm list packages | wc -l; echo "verifier: $(settings get global package_verifier_enable)"; echo "== STATE =="; for p in com.amazon.tv.forcedotaupdater.v2 com.amazon.device.software.ota.override com.amazon.device.software.ota; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Record from this output, at the top of the results log, as **BASELINE**:
- BUILD. If it is not `Fire OS 7.7.1.7 (PS7717/5741)`: **stop** and report (the staged update has installed);
  run nothing else.
- **BASE_E** = ENABLED, **BASE_D** = DISABLED. Check that BASE_E + BASE_D = INSTALLED; if not, stop and report.
  Expected 203 and 51 (254 installed). Other values within that sum are not a stop: record them, and say in
  the log which one differs and by how much.
- verifier: expected `0`. If `1`, record it; Section 2 then runs with the verifier on (see there).
- C1 STATE: expected `forcedotaupdater.v2 installed=true enabled=3` and both `ota` packages `enabled=0`.

## Section 1: C1 verification (and C2 persistence)

**Restore for this section** (save first; only for a stop condition): it re-enables the one package C1 changed.

```sh
echo "== RESTORE (enable) =="; for p in com.amazon.tv.forcedotaupdater.v2; do echo "$p: $(pm enable --user 0 $p 2>&1)"; done; echo "== STATE =="; for p in com.amazon.tv.forcedotaupdater.v2; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
1.1 Run CHECK. Expected: counts = baseline.

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
  enabled=0`. If `forcedotaupdater.v2` reads `enabled=0` or `1`, Fire OS re-enabled it at boot: log it (not a
  stop) and **update the baseline now**: BASE_E = BASE_E + 1, BASE_D = BASE_D - 1. Write "BASELINE updated:
  forcedotaupdater re-enabled at boot" with the new numbers in the log. Every later "counts = baseline" uses them.

1.5 Run CHECK (counts = baseline, as updated in 1.4 if it was), AUTO-HOME and APPS.

1.6 About re-look (screen only). With the harness: Home, then Settings > My Fire TV > About. Read and log, word
for word: whether "Install Update" or "Update to install: System components" still shows, and the exact sentence
about when it installs. **Do not select Install Update or any update item.** Then press Home and run AUTO-HOME.
Highlighting Install Update raises the USB Power Warning; if it appears, dismiss it with OK (or Back), never with anything that installs, and log its text.

## Section 2: C2 install proof (verifier off)

**Restore for this section** (save first; run only if an install fails):

```sh
settings put global package_verifier_enable 1; echo "verifier: $(settings get global package_verifier_enable)"
```
2.1 Record the third-party apps before:

```sh
pm list packages -3 | sort | cat > /sdcard/deamazon/third-before.txt; echo "third-party before: $(wc -l < /sdcard/deamazon/third-before.txt)"; echo "verifier: $(settings get global package_verifier_enable)"
```
Expected: `third-party before: 17` (18 at the audit, minus Netflix) and `verifier: 0`. If it shows `1`, log
"install proof ran with the verifier on" and continue.

2.2 **Attempt 1.** With the harness, open the Amazon Appstore and install **one small, free app that needs no
sign-in or payment** (a speed test or a clock app; log its exact name). Wait for the install to finish. Do not
buy, sign in, or grant anything beyond the defaults. Success = the Appstore shows Open. Failure = an error, a
verification or blocked message, or no finish within 5 minutes.

2.3 **Only if attempt 1 failed:** read and log the message, run this section's restore (expected `verifier: 1`),
then **attempt 2**: the same app, same rules. If attempt 2 also fails: log it, run 2.4 anyway (it confirms
nothing was left behind), skip 2.5 and 2.6, and go to 2.7.

2.4 Whichever attempt succeeded (or after two failures), record what was added:

```sh
pm list packages -3 | sort | cat > /sdcard/deamazon/third-after.txt; echo "third-party after: $(wc -l < /sdcard/deamazon/third-after.txt)"; echo "== NEW PACKAGE =="; grep -vxFf /sdcard/deamazon/third-before.txt /sdcard/deamazon/third-after.txt
```
Expected after a success: `third-party after: 18` and exactly one package name under NEW PACKAGE. After two
failures: `third-party after: 17` and nothing under NEW PACKAGE.

2.5 After a success: open the app from the Appstore's Open button, read the screen to confirm it drew its own
screen, and press Home.

2.6 After a success, **always** remove the test app, whichever attempt installed it. Put the exact name printed
under NEW PACKAGE in place of `<new package>` (the only place the agent fills in a package name, and only from
2.4's output):

```sh
pm uninstall <new package>; echo "== CHECK GONE =="; pm list packages | grep -qx "package:<new package>" && echo STILL_INSTALLED || echo GONE
```

Expected: `Success`, then `GONE`. `STILL_INSTALLED`: run the line once more; still there, stop (rule 5).

2.7 Before Section 3, re-verify: run 2.4's line again (expected `third-party after: 17`, nothing under NEW
PACKAGE) and CHECK (counts = baseline). Anything else: stop (rule 5).

Log the outcome as one of: "installs work with the verifier off" (attempt 1 succeeded), "installs need the
verifier on; restored to 1" (attempt 2 succeeded), or "installs fail either way" (both failed).

## Section 3: D0 baseline measurement (read-only)

3.1 This opens YouTube, backs out with Back four times (no force-stop), opens Stremio and waits one minute
without playing anything:

```sh
monkey -p com.amazon.firetv.youtube -c android.intent.category.LEANBACK_LAUNCHER 1 >/dev/null 2>&1; sleep 15; for n in 1 2 3 4; do input keyevent KEYCODE_BACK; sleep 2; done; echo "== AFTER BACK =="; i=0; while [ $i -lt 5 ]; do sleep 3; i=$((i+1)); t=$(dumpsys activity activities | grep -m1 mResumedActivity); echo "sample $i: $t"; case "$t" in *couchytv*) break;; esac; done; monkey -p com.stremio.one -c android.intent.category.LEANBACK_LAUNCHER 1 >/dev/null 2>&1; sleep 60; echo "== AFTER STREMIO 60s =="; dumpsys activity activities | grep -m1 mResumedActivity
```
This line takes about 90 seconds. If atvTools times out before it prints, log that and do the same steps through the harness instead (open YouTube, wait 15 s, Back four times, open Stremio, wait 60 s), then go on to 3.2.

Expected: AFTER BACK samples reach `com.conreo.couchytv` within 15 s (if they still show YouTube, log it and continue);
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
for p in com.amazon.firetv.youtube com.instagram.airwave com.amazon.firebat; do echo "== $p =="; monkey -p $p -c android.intent.category.LEANBACK_LAUNCHER 1 >/dev/null 2>&1; k=0; while [ $k -lt 5 ]; do sleep 3; k=$((k+1)); t=$(dumpsys activity activities | grep -m1 mResumedActivity); echo "sample $k: $t"; case "$t" in *"$p"*) break;; esac; done; done; input keyevent KEYCODE_HOME; echo "== BACK HOME =="; i=0; while [ $i -lt 5 ]; do sleep 3; i=$((i+1)); t=$(dumpsys activity activities | grep -m1 mResumedActivity); echo "sample $i: $t"; case "$t" in *couchytv*) break;; esac; done
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

4.5 Run CHECK (counts = baseline), AUTO-HOME, APPS.

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

6.1 Run CHECK (counts = baseline) and the section 1.4 block once more, and log both as the final state, next to the BASELINE.

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

The results log, plus a short summary at the top: the BASELINE (and any update to it), whether the build stayed PS7717/5741, `verifier` after each
reboot, `forcedotaupdater.v2` after each reboot, the About wording from 1.6, the test app's name and result, the
3.2 and 4.2 MEASURE numbers side by side, whether D1 persisted, any drop-outs with their CAPTURE and LOG-READ.
