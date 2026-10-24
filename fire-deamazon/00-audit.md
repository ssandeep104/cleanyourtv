# Stage 0: read-only audit and on-stick backup

Nothing here changes the stick. Batch 0.3 only writes text files to `/sdcard/deamazon/b0/` on the stick,
so the original state is kept there before any change.

Run the batches in order in the atvTools ADB shell and paste each output back.

**Do not paste** a serial number, MAC address, IP address, Wi-Fi name or account email if one shows up.
None of the commands below should print one; if one does, blur or delete it before pasting.

**Until the plan is ready:** if the stick shows a pending Fire OS update (Settings > My Fire TV > About >
Check for Updates), do not install it. Some unlock and update-blocking paths only exist on older builds
(see [ceiling.md](ceiling.md)), so the current build is worth keeping until we know what it is.
(INFERENCE: the stick may still install an update by itself at a reboot or overnight; we cannot stop that
from here yet.)

---

## 0.0 Paste test (does atvTools run multi-line pastes?)

```sh
echo line-one
echo line-two
```

Expected: both `line-one` and `line-two`. If only `line-one` prints, tell me and every batch will be
rewritten as single lines joined with `;`.

## 0.1 Device identity

```sh
getprop ro.product.model
getprop ro.product.device
getprop ro.product.name
getprop ro.build.version.name
getprop ro.build.display.id
getprop ro.build.version.release
getprop ro.build.version.sdk
getprop ro.build.version.security_patch
getprop ro.board.platform
getprop ro.boot.verifiedbootstate
```

Expected: model like `AFTSS` or `AFTMM`, device codename like `sheldon` or `mantis`, a `Fire OS x.y.z.w`
name, an Android version and SDK number. This decides the model row in the ceiling and which commands
exist (several only exist from SDK 28, Fire OS 7).

## 0.2 Memory and storage

```sh
head -3 /proc/meminfo
df -h /data
dumpsys meminfo | sed -n '/Total PSS by process/,/Total PSS by OOM/p' | head -45
```

Expected: total RAM, free space on `/data`, and the 40-odd biggest processes right now.

## 0.3 Backup on the stick (writes files to /sdcard only)

```sh
mkdir -p /sdcard/deamazon/b0
pm list packages -u > /sdcard/deamazon/b0/pkgs-all-incl-uninstalled.txt
pm list packages > /sdcard/deamazon/b0/pkgs-installed.txt
pm list packages -d > /sdcard/deamazon/b0/pkgs-disabled.txt
pm list packages -3 > /sdcard/deamazon/b0/pkgs-thirdparty.txt
getprop > /sdcard/deamazon/b0/getprop.txt
settings list global > /sdcard/deamazon/b0/settings-global.txt
settings list secure > /sdcard/deamazon/b0/settings-secure.txt
settings list system > /sdcard/deamazon/b0/settings-system.txt
ls -l /sdcard/deamazon/b0
```

Expected: nine files listed, none of them 0 bytes. Paste only the `ls -l` lines, never the files themselves
(`getprop.txt` and the settings files hold identifiers). They stay on the stick as the "before" record.

## 0.4 Third-party apps (what you installed)

```sh
pm list packages -3 | sort
```

Expected: Couchy, Home On Fire, Stremio, Downloader, Netflix, Instagram, NordVPN and anything else you
sideloaded. This tells me the exact package names to keep.

## 0.5 System packages still installed

```sh
pm list packages -s | sort
```

Expected: a long list (150 to 300 lines). If atvTools cuts it off, paste what you get and say so.

## 0.6 What you already disabled, and what you already uninstalled for your user

```sh
echo "== DISABLED =="
pm list packages -d | sort
pm list packages -u | sort > /data/local/tmp/u.txt
pm list packages | sort > /data/local/tmp/i.txt
echo "== UNINSTALLED FOR USER 0 =="
grep -vxFf /data/local/tmp/i.txt /data/local/tmp/u.txt
rm /data/local/tmp/u.txt /data/local/tmp/i.txt
```

Expected: two lists. The second one is everything still in the system image that you removed for your user;
each of those can come back with `cmd package install-existing <name>`.

## 0.7 Home, accessibility and install-verification settings

```sh
cmd package resolve-activity -a android.intent.action.MAIN -c android.intent.category.HOME | head -6
settings get secure enabled_accessibility_services
settings get secure accessibility_enabled
settings get global package_verifier_enable
settings get global verifier_verify_adb_installs
settings get secure install_non_market_apps
settings get global always_finish_activities
```

Expected: Home resolves to `com.amazon.tv.launcher` (Home On Fire hands off to Couchy, so the stock one is
still Home underneath); the accessibility line names Home On Fire; the rest print numbers or `null`.
If `cmd package resolve-activity` prints an error, that is fine, say so.

## 0.8 Amazon processes running right now

```sh
ps -A -o RSS,NAME 2>/dev/null | grep -i -e amazon -e fireos | sort -rn | head -60
```

Expected: memory (KB) and name of each Amazon process alive now. If it prints nothing, run plain
`ps | grep -i amazon` instead (older Fire OS has an older `ps`).

## 0.9 Update and verification machinery

```sh
pm list packages -u | grep -i -e ota -e update -e verif -e fdra -e adep -e venezia -e tigris -e devicecontrol -e dcp -e sync
echo "== ota detail =="
dumpsys package com.amazon.device.software.ota | grep -E "versionName|enabled=|pkgFlags" | head -8
dumpsys package com.amazon.device.software.ota.override | grep -E "versionName|enabled=|pkgFlags" | head -8
dumpsys package com.amazon.tv.forcedotaupdater.v2 | grep -E "versionName|enabled=|pkgFlags" | head -8
```

Expected: the package names Amazon uses on this build for updates, app verification, the Appstore and sync.
Empty sections mean that package does not exist on this build, which is useful too.

---

When all ten are pasted, I write `01-gap-analysis.md` and `02-plan.md` from them.
