# Final runbook: D1 checks and D2 snippets (manual, one line at a time)

**Who runs it:** Sandeep, by hand: each line pasted into the atvTools ADB shell on the iPhone, one at a time,
with Sonny handing over the next line after reading the output. No agent, no phone automation. Each code block is
one line (atvTools flattens multi-line pastes); paste it whole. Steps marked **Remote** are done by Sandeep on the
TV with the Fire TV remote.

**What it covers:** D1 (background work stopped for YouTube and Instagram) is applied in chat first, with the
02-plan.md D1 line. This file is everything after that: verification, the phone-casting check, the reboot
persistence re-check, the restore line, and D2. It changes no package state.

## Starting state (DIRECT, verified 2026-10-25 17:52 to 17:54 CT)

Build `PS7717.5741N` (the staged update has not installed); 200 enabled, 53 disabled, 253 installed;
`package_verifier_enable` 0; `forcedotaupdater.v2`, `firebat` (Prime Video) and `spiderpork` (Amazon Luna)
disabled; AIO Streamer uninstalled. The stick runs on the TV's USB port: keep the TV on until step 7.

## Stop rules

Stop and hand the output to Sonny before the next line if: CHECK prints `PROBLEM`; a count differs from the
baseline in step 1; the build is not `Fire OS 7.7.1.7 (PS7717/5741)`; YouTube or Instagram will not open or shows
signed out; casting fails; or atvTools is not back within 5 minutes of a reboot. For anything tied to D1 (an app
misbehaving, casting failing), run the restore line in step 2 first.

If Couchy drops out (stock Home on screen, Home does nothing): open Couchy from the stock launcher's app list, or
run the "Bring Couchy back" snippet (step 6). That is the known memory issue, not a D1 fault.

---

## Step 1: baseline (read-only)

```sh
echo "== BUILD =="; getprop ro.build.version.name; echo "== ENABLED =="; pm list packages -e | wc -l; echo "== DISABLED =="; pm list packages -d | wc -l; echo "== INSTALLED =="; pm list packages | wc -l; echo "verifier: $(settings get global package_verifier_enable)"; echo "== STATE =="; for p in com.amazon.tv.forcedotaupdater.v2 com.amazon.firebat com.amazon.spiderpork; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done
```
Expected:
- `Fire OS 7.7.1.7 (PS7717/5741)`
- ENABLED `200`, DISABLED `53`, INSTALLED `253` (ENABLED + DISABLED must equal INSTALLED)
- `verifier: 0`
- STATE: `com.amazon.tv.forcedotaupdater.v2 installed=true enabled=3`, `com.amazon.firebat installed=true enabled=3`,
  `com.amazon.spiderpork installed=true enabled=3`

Then CHECK:

```sh
F=/sdcard/deamazon/chk.txt; pm list packages -e | cat > $F; echo "== KEEP =="; for p in com.conreo.couchytv io.github.toolicious.homeonfire com.amazon.tv.launcher com.amazon.firehomestarter com.amazon.imp com.stremio.one com.amazon.firetv.youtube com.esaba.downloader com.amazon.cloud9 com.instagram.airwave com.nordvpn.android dev.vodik7.atvtoolsserver; do grep -qx "package:$p" $F && echo "ok $p" || echo "PROBLEM $p"; done; echo "== ENABLED COUNT =="; wc -l < $F; echo "== HOME =="; cmd package resolve-activity -a android.intent.action.MAIN -c android.intent.category.HOME | grep -m1 "name="; echo "== A11Y =="; settings get secure enabled_accessibility_services; echo "== DISABLED COUNT =="; pm list packages -d | wc -l; echo "== SCREENSAVER =="; settings get secure screensaver_enabled
```
Expected: 12 lines starting `ok`; ENABLED COUNT `200`; HOME `name=com.amazon.tv.launcher.ui.HomeActivity_vNext`;
A11Y `io.github.toolicious.homeonfire/.HijackService`; DISABLED COUNT `53`; SCREENSAVER `0`.

## Step 2: confirm D1 landed, and save the restore

```sh
echo "== BACKGROUND SETTING =="; for p in com.amazon.firetv.youtube com.instagram.airwave com.amazon.firebat; do echo "$p: $(cmd appops get $p RUN_ANY_IN_BACKGROUND)"; done
```
Expected:
- `com.amazon.firetv.youtube: RUN_ANY_IN_BACKGROUND: ignore`
- `com.instagram.airwave: RUN_ANY_IN_BACKGROUND: ignore`
- `com.amazon.firebat:` either `RUN_ANY_IN_BACKGROUND: ignore` (if the 02-plan line, which includes it, was used)
  or `No operations. Default mode: allow`. Both are fine: Prime Video is disabled, so it cannot run anyway.

If YouTube or Instagram does not read `ignore`, stop: D1 did not land.

**Restore** (save as an atvTools snippet named "Restore D1"; do not run unless a stop rule says so). It sets all
three back to allowed, which is harmless for the disabled Prime Video:

```sh
echo "== RESTORE (allow background) =="; for p in com.amazon.firetv.youtube com.instagram.airwave com.amazon.firebat; do cmd appops set $p RUN_ANY_IN_BACKGROUND allow; echo "$p: $(cmd appops get $p RUN_ANY_IN_BACKGROUND)"; done
```
Expected if ever run: three lines ending `RUN_ANY_IN_BACKGROUND: allow`.

## Step 3: apps still work (Remote)

1. **Remote:** open YouTube from Couchy. It opens and shows your signed-in account.
2. **Remote:** open Instagram. It opens and is signed in.
3. **Remote:** press Home. Couchy comes up (allow a few seconds for Home On Fire to switch over).

Expected: all three yes. Say "signed in" or "signed out", no names.

## Step 4: casting from the phone (Remote and phone)

1. **Remote:** leave the TV on Couchy (YouTube not open).
2. **Phone:** in the YouTube app, tap Cast and pick the Fire TV, then play any video.

Expected: YouTube opens on the TV by itself and plays. If it does not, run "Restore D1", then try casting again
and report both results.

## Step 5: does YouTube stop working in the background (read-only)

1. **Remote:** open YouTube, play a video for a few seconds, then press Back until you are on Couchy (no force-stop).
2. Wait one minute on Couchy.
3. Paste:

```sh
echo "== YOUTUBE AFTER LEAVING =="; echo "pid: $(pidof com.amazon.firetv.youtube)"; dumpsys meminfo com.amazon.firetv.youtube | grep -m1 -E "TOTAL|No process"; echo "services: $(dumpsys activity services com.amazon.firetv.youtube | grep -c ServiceRecord)"; echo "bg: $(cmd appops get com.amazon.firetv.youtube RUN_ANY_IN_BACKGROUND)"
```
Expected: `services: 0` (no background services running; the main gain of D1) and `bg: RUN_ANY_IN_BACKGROUND: ignore`.
`pid:` may show a number and memory a `TOTAL` line: Android keeps the paused process in memory until it needs
the space, without letting it work. That is fine. Any `services:` above 0 is not a stop; note it.

## Step 6: reboot and persistence

1. Paste `reboot` (atvTools disconnects), wait about 2 minutes, reconnect atvTools.
2. Paste:

```sh
echo "== UPTIME =="; uptime; echo "== BUILD =="; getprop ro.build.version.name; echo "== ENABLED =="; pm list packages -e | wc -l; echo "== DISABLED =="; pm list packages -d | wc -l; echo "== INSTALLED =="; pm list packages | wc -l; echo "verifier: $(settings get global package_verifier_enable)"; echo "== STATE =="; for p in com.amazon.tv.forcedotaupdater.v2 com.amazon.firebat com.amazon.spiderpork; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done; echo "== BACKGROUND SETTING =="; for p in com.amazon.firetv.youtube com.instagram.airwave com.amazon.firebat; do echo "$p: $(cmd appops get $p RUN_ANY_IN_BACKGROUND)"; done
```
Expected: uptime of a few minutes; everything as in step 1 (build, 200 / 53 / 253, `verifier: 0`, the three
`enabled=3`); and the BACKGROUND SETTING lines as in step 2 (YouTube and Instagram `ignore`). If YouTube or
Instagram now reads `allow` or `No operations`, D1 does not survive a reboot on this build: report it, not a stop.

3. Paste CHECK from step 1 again. Expected: as in step 1.
4. **Remote:** Home shows Couchy; long-press Home opens the stock launcher; Home again returns to Couchy.

## Step 7: D2 snippets

1. **Phone:** in atvTools, look at the saved snippets. Note which of these exist: "Quit YouTube", "Quit Instagram",
   "Quit Stremio", "Bring Couchy back", "Restore D1".
2. Create any that are missing, with exactly the lines in [snippets.md](snippets.md) (and step 2 for
   "Restore D1"). Do not run them while saving.
3. Test one, once: **Remote:** open YouTube; then run "Quit YouTube", which is this line:

```sh
am force-stop com.amazon.firetv.youtube; echo "stopped com.amazon.firetv.youtube"; echo "pid after: $(pidof com.amazon.firetv.youtube)"
```
Expected: `stopped com.amazon.firetv.youtube`, then `pid after:` with nothing after it (YouTube fully closed).
**Remote:** press Home if the TV still shows YouTube's last frame.

## Step 8: final checks (Remote), then done

1. Paste CHECK one last time. Expected: as in step 1.
2. **Remote:** volume up and down work.
3. **Remote:** power button **last**. It turns the TV off, which also cuts the stick's power (TV USB).

When the TV comes back on later: Home shows Couchy. That ends the project.

## Appendix: if the staged update installs later

The two packages that install updates are protected, so it can still install by itself. Afterwards, paste step 1's
two lines and step 2's read line, and hand the output to Sonny before changing anything: an update can re-enable
packages, change the counts and reset settings.
