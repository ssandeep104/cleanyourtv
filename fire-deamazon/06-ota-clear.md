# Follow-up: clearing the staged Fire OS update

**Status:** plan, not yet run. Manual, one line at a time, Sandeep in atvTools with Sonny. Each code block is one line.

## Why this exists

The close-out said the staged "System components" update could not be stopped from the shell, because the two
packages that install updates are protected. That was too strong. Disabling them is refused, but clearing the
update app's data may still work: AFTVnews recommends `pm clear com.amazon.device.software.ota` over ADB for an
update that is already downloaded and waiting, and says it resets the update checks so About shows "Last
checked: Never" (DOCUMENT; their guidance is several years old and predates Fire OS 7.7). A community Fire TV
guide says the same: clearing this app's data removes an update that was already downloaded.

## Assessment

**1. Is it safe here? Yes, as far as anything known says (INFERENCE where marked).**

- It deletes only the update app's own data. No package is disabled, no setting outside that app changes, and it
  does not touch Home, Couchy, Home On Fire, input, Wi-Fi or sign-in.
- The app is stopped and comes back on its own (it is a system service); its data is rebuilt empty, as on a new
  stick. Its update history and last-check date are lost, which is the point.
- **It may be refused.** On Android 9, a package protected from disabling can also be protected from having its
  data cleared; the shell would then print a `SecurityException` naming a protected package (INFERENCE from
  standard Android behaviour; not seen on this stick). A refusal changes nothing; it would mean the staged update
  cannot be cleared from the shell on this build either.
- Do it **while the stick is in use** (TV on, someone at it). The update installs when the stick is idle, so
  clearing while it is busy avoids clearing in the middle of an install.
- Side effect to expect (INFERENCE): with its history gone, the update app may check Amazon again soon and
  download the update again. That is the re-staging risk below, not damage.

**2. What `Success` proves, and what it does not.**

- `Success` proves Android wiped the update app's private data. It does **not** prove the downloaded update file
  is gone: Android can keep an update file outside the app's data (`/cache` or `/data/ota_package`), which the
  shell normally cannot list. The real check is the About screen: "Update to install" gone, and "Last checked"
  reset.
- It also does not prevent a new download. Nothing the shell can do on this build does.

**3. Re-staging: yes, it can download again.** The update app stays enabled (protected), so on its next check it
can fetch the same update. `forcedotaupdater.v2` is already disabled, which removes the forced-update path but not
the normal one; blocking Amazon's update servers is not available while NordVPN carries DNS (U8). So the clear
buys time, not a guarantee. A periodic re-clear joins the standing note: look at About now and then (every week or
two), and repeat this procedure whenever "Update to install" is back.

## Steps

### F0: before (Remote, then read-only)

1. **Remote:** Settings > My Fire TV > About. Write down, word for word: whether "Update to install: System
   components" (or "Install Update") shows, and the "Last checked" line if there is one. **Do not select Install
   Update or Check for Updates.** If the USB Power Warning appears, dismiss it with OK. Press Home.
2. Paste:

```sh
echo "== BUILD =="; getprop ro.build.version.name; echo "== ENABLED =="; pm list packages -e | wc -l; echo "== DISABLED =="; pm list packages -d | wc -l; echo "verifier: $(settings get global package_verifier_enable)"; echo "== OTA PACKAGES =="; for p in com.amazon.device.software.ota com.amazon.device.software.ota.override com.amazon.tv.forcedotaupdater.v2; do echo "$p $(dumpsys package $p | grep -m1 "User 0:" | grep -o -e "installed=[a-z]*" -e "enabled=[0-9]" | tr "\n" " ")"; done; echo "ota pid: $(pidof com.amazon.device.software.ota)"; echo "== UPDATE FILES (denied is normal) =="; ls /cache 2>&1 | head -5; ls /data/ota_package 2>&1 | head -5
```
Expected: `Fire OS 7.7.1.7 (PS7717/5741)`; ENABLED `200`; DISABLED `53`; `verifier: 0`;
`com.amazon.device.software.ota installed=true enabled=0`, `...ota.override installed=true enabled=0`,
`...forcedotaupdater.v2 installed=true enabled=3`; `ota pid:` a number or empty; the two file listings most likely
`Permission denied` (normal; if they do list files, write the names down). A different build means the update
already installed: stop here and run the standing follow-up instead.

### F1: clear (the only change)

No restore line exists: cleared data cannot be put back, and nothing needs restoring (the app rebuilds it).

```sh
echo "== CLEAR OTA DATA =="; pm clear com.amazon.device.software.ota 2>&1; echo "ota pid after: $(pidof com.amazon.device.software.ota)"
```
Expected: `Success`, then `ota pid after:` empty or a new number (the service restarting).
If it prints `SecurityException` or `Cannot clear data for a protected package` (or any other error): nothing
changed. Stop, report the exact text: the staged update cannot be cleared from the shell on this build, and the
ceiling stands as before.

### F2: after (Remote, then read-only)

1. **Remote:** Settings > My Fire TV > About again. Write down the same lines, word for word. Hoped-for result:
   no "Update to install", and "Last checked: Never" (or no date). **Do not press Check for Updates**: that would
   start a fresh download straight away.
2. Paste F0's line again. Expected: same as F0 (build, 200 / 53, `verifier: 0`, the three package states).
3. Paste CHECK from [05-final-runbook.md](05-final-runbook.md), step 1. Expected: as there.

If About still shows "Update to install" after `Success`: the file is kept outside the app's data, the clear did
not remove it, and there is nothing more the shell can do. Report it.

### F3: reboot check

1. Paste `reboot`, wait about 2 minutes, reconnect.
2. Paste F0's line. Expected: same build, same counts.
3. **Remote:** About once more: still no "Update to install". Then Home: Couchy.

## Standing note (added)

Look at Settings > My Fire TV > About every week or two (never press Install or Check for Updates). If "Update to
install" is back, run F0 to F3 again. If the build has changed, the update installed: run the standing follow-up
in [README.md](README.md) instead.
