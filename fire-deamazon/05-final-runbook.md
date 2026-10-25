# Final runbook: D1 background limits and D2 quit snippets

**One short job for the owner's local Codex** (iPhone harness, atvTools ADB shell on the Fire TV Stick Lite, AFTSS
`sheldon`, Fire OS 7.7.1.7 PS7717/5741). It finishes the project: everything else is done or decided (see
[audit-log.md](audit-log.md), "Reconciliation after the Codex run"). It changes no package state.

## Starting state (DIRECT, verified 2026-10-25 17:52 to 17:54 CT; Section 0 re-reads it)

- Build `PS7717.5741N`; the staged update has not installed.
- 200 enabled, 53 disabled, 253 installed, 16 third-party.
- `package_verifier_enable` 0; `forcedotaupdater.v2`, `firebat` (Prime Video) and `spiderpork` (Amazon Luna)
  disabled; AIO Streamer uninstalled. All survived a reboot.
- D1 not applied: YouTube and Instagram read `No operations. Default mode: allow`.
- The stick runs on the TV's USB port: keep the TV on for the whole run; a TV power-off is a power loss, handled
  as a reboot.

## Rules (same as 04)

1. Only the commands in this file, copied exactly; one code block = one line = one paste.
2. Results log: step id, local time, exact command, raw output. Write it to a file as you go, so a crash loses
   nothing (the last run's log was lost with Codex).
3. Save the restore block as an atvTools snippet before the change block. Run it only on a stop.
4. Never: select Install Update; disable, enable or uninstall any package; force-stop Couchy, Home On Fire,
   NordVPN or `dev.vodik7.atvtoolsserver`; change accessibility settings. No serials, MAC or IP addresses, Wi-Fi
   names or emails in the log.
5. Stop (run the restore if the section has one, log, end the job) if: CHECK prints `PROBLEM`; HOME, A11Y or a
   count differs from the baseline; the build is not `PS7717/5741` (log CHECK first, restore nothing); YouTube or
   Instagram will not open or shows signed out when it was signed in; atvTools is not back within 5 minutes of a
   reboot.
6. Couchy drop-out: CAPTURE, LOG-READ, RECOVER (from [04-continuation-runbook.md](04-continuation-runbook.md),
   "Tools"), log all three, carry on; twice without a heavy app open is a stop.
7. Reboot: paste `reboot`, wait about 2 minutes, reconnect.

## Tools

CHECK (12-app), expected counts = baseline:

```sh
F=/sdcard/deamazon/chk.txt; pm list packages -e | cat > $F; echo "== KEEP =="; for p in com.conreo.couchytv io.github.toolicious.homeonfire com.amazon.tv.launcher com.amazon.firehomestarter com.amazon.imp com.stremio.one com.amazon.firetv.youtube com.esaba.downloader com.amazon.cloud9 com.instagram.airwave com.nordvpn.android dev.vodik7.atvtoolsserver; do grep -qx "package:$p" $F && echo "ok $p" || echo "PROBLEM $p"; done; echo "== ENABLED COUNT =="; wc -l < $F; echo "== HOME =="; cmd package resolve-activity -a android.intent.action.MAIN -c android.intent.category.HOME | grep -m1 "name="; echo "== A11Y =="; settings get secure enabled_accessibility_services; echo "== DISABLED COUNT =="; pm list packages -d | wc -l; echo "== SCREENSAVER =="; settings get secure screensaver_enabled
```
AUTO-HOME (polls up to 15 s; an early stock-launcher sample is inconclusive; read it as in 04):

```sh
input keyevent KEYCODE_HOME; echo "== HOME SAMPLES (every 3 s, up to 15 s) =="; i=0; while [ $i -lt 5 ]; do sleep 3; i=$((i+1)); t=$(dumpsys activity activities | grep -m1 mResumedActivity); echo "sample $i: $t"; case "$t" in *couchytv*) break;; esac; done; echo "couchy pid: $(pidof com.conreo.couchytv)"; echo "== FOCUS WINDOW =="; dumpsys window windows | grep -m1 mCurrentFocus; echo "== HOME ON FIRE SERVICE =="; dumpsys accessibility | grep -m2 -i homeonfire; echo "== VPN TUNNEL =="; if ip link show tun0 >/dev/null 2>&1; then if ip link show tun0 | grep -q UP; then echo TUN0_UP; else echo TUN0_PRESENT_NOT_UP; fi; else echo TUN0_ABSENT; fi; echo "nordvpn pid: $(pidof com.nordvpn.android)"
```
---

## Section 0: baseline (read-only)

```sh
echo "== BUILD =="; getprop ro.build.version.name; echo "== ENABLED =="; pm list packages -e | wc -l; echo "== DISABLED =="; pm list packages -d | wc -l; echo "== INSTALLED =="; pm list packages | wc -l; echo "== THIRD PARTY =="; pm list packages -3 | wc -l; echo "verifier: $(settings get global package_verifier_enable)"; echo "== STATE =="; for p in com.amazon.tv.forcedotaupdater.v2 com.amazon.firebat com.amazon.spiderpork; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done; echo "== BACKGROUND =="; for p in com.amazon.firetv.youtube com.instagram.airwave; do echo "$p: $(cmd appops get $p RUN_ANY_IN_BACKGROUND)"; done
```
Record as **BASELINE** at the top of the log. Expected: build `Fire OS 7.7.1.7 (PS7717/5741)` (anything else: stop);
ENABLED 200, DISABLED 53, INSTALLED 253 (ENABLED + DISABLED must equal INSTALLED, else stop); THIRD PARTY 16;
`verifier: 0`; `forcedotaupdater.v2`, `firebat`, `spiderpork` each `installed=true enabled=3`; both BACKGROUND
lines `No operations. Default mode: allow` (or `allow`). Different counts with a correct sum: record them as the
baseline and say how they differ. Then run CHECK (counts = baseline) and AUTO-HOME.

## Section 1: D1, stop background work for YouTube and Instagram

Prime Video (`com.amazon.firebat`) is left out: it is disabled, so it cannot run in the background at all. If it is
ever re-enabled (`pm enable --user 0 com.amazon.firebat`), give it the same treatment by adding it to both lines
below; the restore line then needs it too.

1.1 Before (read-only): open YouTube, back out to Couchy, wait 60 s, read YouTube's process:

```sh
monkey -p com.amazon.firetv.youtube -c android.intent.category.LEANBACK_LAUNCHER 1 >/dev/null 2>&1; sleep 15; for n in 1 2 3 4; do input keyevent KEYCODE_BACK; sleep 2; done; echo "== AFTER BACK =="; i=0; while [ $i -lt 5 ]; do sleep 3; i=$((i+1)); t=$(dumpsys activity activities | grep -m1 mResumedActivity); echo "sample $i: $t"; case "$t" in *couchytv*) break;; esac; done; sleep 60; echo "== YOUTUBE 60 s AFTER LEAVING =="; echo "pid: $(pidof com.amazon.firetv.youtube)"; dumpsys meminfo com.amazon.firetv.youtube | grep -m1 -E "TOTAL|No process"; echo "services: $(dumpsys activity services com.amazon.firetv.youtube | grep -c ServiceRecord)"
```
Log the pid, memory and services lines. No pass or fail; a 90-second line (if atvTools times out, do the same
steps through the harness and log that).

**Restore** (save first as an atvTools snippet named "Restore D1"; do not run):

```sh
echo "== RESTORE (allow background) =="; for p in com.amazon.firetv.youtube com.instagram.airwave; do cmd appops set $p RUN_ANY_IN_BACKGROUND allow; echo "$p: $(cmd appops get $p RUN_ANY_IN_BACKGROUND)"; done
```
1.2 Change:

```sh
echo "== RESTRICT BACKGROUND =="; for p in com.amazon.firetv.youtube com.instagram.airwave; do cmd appops set $p RUN_ANY_IN_BACKGROUND ignore; echo "$p: $(cmd appops get $p RUN_ANY_IN_BACKGROUND)"; done
```
Expected: both lines end `RUN_ANY_IN_BACKGROUND: ignore`. Anything else: restore, stop.

1.3 Both apps still open (polls up to 15 s each):

```sh
for p in com.amazon.firetv.youtube com.instagram.airwave; do echo "== $p =="; monkey -p $p -c android.intent.category.LEANBACK_LAUNCHER 1 >/dev/null 2>&1; k=0; while [ $k -lt 5 ]; do sleep 3; k=$((k+1)); t=$(dumpsys activity activities | grep -m1 mResumedActivity); echo "sample $k: $t"; case "$t" in *"$p"*) break;; esac; done; done; input keyevent KEYCODE_HOME; echo "== BACK HOME =="; i=0; while [ $i -lt 5 ]; do sleep 3; i=$((i+1)); t=$(dumpsys activity activities | grep -m1 mResumedActivity); echo "sample $i: $t"; case "$t" in *couchytv*) break;; esac; done
```
Expected: each section reaches its own package; BACK HOME reaches `com.conreo.couchytv`. Read the screen in
each app: log "signed in" or "signed out" only (never a name).

1.4 After (read-only): run 1.1's line again and log it next to 1.1's numbers. Expected: same format; YouTube's
services count at 0, or lower than before (INFERENCE: background services stop once the app leaves the screen).

1.5 Reboot (rule 7), then:

```sh
echo "== UPTIME =="; uptime; echo "== BUILD =="; getprop ro.build.version.name; echo "== ENABLED =="; pm list packages -e | wc -l; echo "== DISABLED =="; pm list packages -d | wc -l; echo "== INSTALLED =="; pm list packages | wc -l; echo "== THIRD PARTY =="; pm list packages -3 | wc -l; echo "verifier: $(settings get global package_verifier_enable)"; echo "== STATE =="; for p in com.amazon.tv.forcedotaupdater.v2 com.amazon.firebat com.amazon.spiderpork; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done; echo "== BACKGROUND =="; for p in com.amazon.firetv.youtube com.instagram.airwave; do echo "$p: $(cmd appops get $p RUN_ANY_IN_BACKGROUND)"; done
```
Expected: uptime a few minutes; everything as the BASELINE, except both BACKGROUND lines now
`RUN_ANY_IN_BACKGROUND: ignore` (the setting survived the reboot). If they read `allow` or `default`, log "D1 does
not persist across reboot"; not a stop. Then CHECK (counts = baseline), AUTO-HOME, and 1.3's line again.

## Section 2: D2 quit snippets (no system change)

2.1 Through the harness, open atvTools' snippet list and log which of these exist, by name: "Quit YouTube",
"Quit Instagram", "Quit Stremio", "Bring Couchy back".

2.2 Create any that are missing, with exactly these commands. Do not run them. (No "Quit Prime Video": it is disabled.)

Quit YouTube:

```sh
am force-stop com.amazon.firetv.youtube; echo "stopped com.amazon.firetv.youtube"
```
Quit Instagram:

```sh
am force-stop com.instagram.airwave; echo "stopped com.instagram.airwave"
```
Quit Stremio:

```sh
am force-stop com.stremio.one; echo "stopped com.stremio.one"
```
Bring Couchy back:

```sh
monkey -p com.conreo.couchytv -c android.intent.category.LEANBACK_LAUNCHER 1 >/dev/null 2>&1; echo "couchy pid: $(pidof com.conreo.couchytv)"
```
If an existing "Quit Prime Video" snippet is found, leave it; it does nothing harmful while Prime Video is disabled.
The same four lines are kept in [snippets.md](snippets.md).

## Section 3: final state and the owner's checks

3.1 Run Section 0's line and CHECK once more; log both as FINAL next to the BASELINE.

3.2 At the end of the log, a checklist with blank answers for Sandeep, at the TV, in this order:

1. Remote Home: Couchy comes up.
2. Long-press Home: the stock launcher opens; Home again: back to Couchy.
3. Cast from the phone to YouTube: playback starts on the TV (the D1 casting check; if it fails, run the
   "Restore D1" snippet).
4. YouTube and Instagram open and are signed in.
5. Volume up and down.
6. Power button **last**: it turns the TV off, and that also cuts the stick's power.

## Appendix: if the staged update installs later

The update can still install itself (the two packages that install updates are protected). Afterwards, run
Section 0's line and CHECK once and hand the output back: an update can re-enable packages, change the counts
and reset settings. Nothing is re-done until that output has been read.

## Hand back

The log file, with the BASELINE and FINAL at the top, the 1.1 and 1.4 numbers side by side, whether D1 persisted,
the snippet list from 2.1, and any drop-outs.
