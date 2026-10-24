# Stage 0: read-only audit and on-stick backup

Nothing here changes the stick. Batch 0.3 only writes text files to `/sdcard/deamazon/b0/` on the stick,
so the original state is kept there before any change.

**Every batch is one line** (AUDIT, batch 0.0: atvTools flattens a multi-line paste into one line and
Return sends it). Copy the whole line, paste it into the atvTools ADB shell, press Return, paste the
output back. Steps are joined with `;`, so a step that fails does not stop the ones after it, and each
section prints an `== label ==` so the output is easy to read.

**Rule for this build (AUDIT, batch 0.3):** `pm`, `settings` and `cmd` hand their output file to Android's
system process, which then writes into it. Redirected straight to a file on `/sdcard`, that write is refused
and the file gets only `cmd: Failure calling service package: Failed transaction (2147483646)`. So in this
project, output from `pm`, `settings` or `cmd` always goes through a pipe first (`| cat > file`, `| sort`,
`| grep`, or `$(...)`); the system process may write into a pipe, and the shell writes the file.
`getprop` and `dumpsys` are not affected (they worked in 0.2 and 0.3).

If atvTools cuts a line off (output ends early, or an error about an unexpected end), tell me which batch
and I will split it.

**Do not paste** a serial number, MAC address, IP address, Wi-Fi name or account email if one shows up.
None of the commands below should print one; if one does, blur or delete it before pasting.

**Updates:** your build (PS7717) is already past every known unlock and exploit cutoff (see
[ceiling.md](ceiling.md)), so staying on it gains nothing on that front. Still, don't install a pending
update by hand until the plan is done: an update can re-enable packages and change which ones are
protected, and the plan is written against this build.

---

## 0.0 Paste test (done)

AUDIT: multi-line pastes arrive as one line. All batches below are single lines.

## 0.1 Device identity (done)

AUDIT: AFTSS, `sheldon`, Fire OS 7.7.1.7 (PS7717/5741), Android 9 / SDK 28, patch 2026-03-01, `mt8695`,
verified boot `green`. Kept below for the record.

```sh
for p in ro.product.model ro.product.device ro.product.name ro.build.version.name ro.build.display.id ro.build.version.release ro.build.version.sdk ro.build.version.security_patch ro.board.platform ro.boot.verifiedbootstate; do echo "$p = $(getprop $p)"; done
```

Expected: one `name = value` line each. Model like `AFTSS` or `AFTMM`, device codename like `sheldon` or
`mantis`, a `Fire OS x.y.z.w` name, an Android version and SDK number. This decides the model row in the
ceiling and which commands exist (several only exist from SDK 28, Fire OS 7).

## 0.2 Memory and storage

```sh
echo "== RAM =="; head -3 /proc/meminfo; echo "== STORAGE =="; df -h /data; echo "== TOP PROCESSES =="; dumpsys meminfo | sed -n '/Total PSS by process/,/Total PSS by OOM/p' | head -45
```

Expected: total RAM, free space on `/data`, and the 40-odd biggest processes right now.

## 0.3 Backup on the stick (writes files to /sdcard only)

First attempt (AUDIT): `getprop.txt` was written (16,861 bytes); the seven `pm` and `settings` files held only
the `Failed transaction` line (70 and 71 bytes), because their output was redirected straight to `/sdcard`.
This version pipes each one through `cat`, deletes only the seven broken files, keeps `getprop.txt`, then
checks itself:

```sh
D=/sdcard/deamazon/b0; mkdir -p $D; rm -f $D/pkgs-*.txt $D/settings-*.txt; pm list packages -u | cat > $D/pkgs-all-incl-uninstalled.txt; pm list packages | cat > $D/pkgs-installed.txt; pm list packages -d | cat > $D/pkgs-disabled.txt; pm list packages -3 | cat > $D/pkgs-thirdparty.txt; settings list global | cat > $D/settings-global.txt; settings list secure | cat > $D/settings-secure.txt; settings list system | cat > $D/settings-system.txt; echo "== LINES =="; wc -l $D/*.txt; echo "== FAILED FILES (should be empty) =="; grep -l "Failure calling" $D/*.txt
```

Expected: a line count per file, and nothing under FAILED FILES. Rough sizes: `pkgs-all-incl-uninstalled`
200 or more lines, `pkgs-installed` fewer than that, `pkgs-disabled` a few dozen (your earlier disables),
`pkgs-thirdparty` about ten, each settings file dozens to hundreds, `getprop` several hundred. Any file at
1 line, or any name under FAILED FILES, means stop and paste it. The counts carry no identifiers, so the
whole output is safe to paste. Never paste the files themselves.

## 0.4 Third-party apps (what you installed)

```sh
echo "== THIRD PARTY =="; pm list packages -3 | sort
```

Expected: Couchy, Home On Fire, Stremio, Downloader, Netflix, Instagram, NordVPN and anything else you
sideloaded. This tells me the exact package names to keep.

## 0.5 System packages still installed

```sh
echo "== SYSTEM INSTALLED =="; pm list packages -s | sort; echo "== COUNT =="; pm list packages -s | wc -l
```

Expected: a long list (150 to 300 lines), then the count. If the pasted list has fewer lines than the
count, atvTools cut it off: say so and I will split it alphabetically.

### 0.5a / 0.5b: the full list, in two halves for pasting

The gap analysis needs every package name as printed, not a summary: nothing goes into a batch unless the
audit shows it on this stick. Paste each half as its own output.

```sh
echo "== SYSTEM 1-120 =="; pm list packages -s | sort | sed -n '1,120p'
```

```sh
echo "== SYSTEM 121-END =="; pm list packages -s | sort | sed -n '121,$p'
```

Expected: 120 lines, then the remaining 117 (237 in all, AUDIT 0.5 count).

### 0.5c: find the one package missing from the relayed list

The relayed list has 236 names; the stick counted 237. This prints every 20th line with its number (11 lines),
so the first number whose name differs from `audit-0.5-system-packages.txt` places the missing name within 20:

```sh
echo "== CHECKPOINTS =="; pm list packages -s | sort | grep -n . | grep -E '^[0-9]*[02468]0:'
```

Expected if nothing were missing: `20:package:com.amazon.application.compatibility.enforcer` through
`220:package:com.android.settings.intelligence`. From the first checkpoint that shows a different name,
everything is shifted by one.

## 0.6 What you already disabled, and what you already uninstalled for your user

```sh
echo "== DISABLED =="; pm list packages -d | sort; pm list packages -u | sort > /data/local/tmp/u.txt; pm list packages | sort > /data/local/tmp/i.txt; echo "== UNINSTALLED FOR USER 0 =="; grep -vxFf /data/local/tmp/i.txt /data/local/tmp/u.txt; rm /data/local/tmp/u.txt /data/local/tmp/i.txt
```

Already safe under the rule above: every `pm` output here goes through `sort` before it reaches a file.

Expected: two lists. The second one is everything still in the system image that you removed for your user;
each of those can come back with `cmd package install-existing <name>`.

## 0.7 Home, accessibility and install-verification settings

```sh
echo "== HOME =="; cmd package resolve-activity -a android.intent.action.MAIN -c android.intent.category.HOME | head -6; for k in "secure enabled_accessibility_services" "secure accessibility_enabled" "global package_verifier_enable" "global verifier_verify_adb_installs" "secure install_non_market_apps" "global always_finish_activities"; do echo "$k = $(settings get $k)"; done
```

Expected: Home resolves to `com.amazon.tv.launcher` (INFERENCE: Home On Fire hands off to Couchy, so the
stock one is still Home underneath); the accessibility line names Home On Fire; the rest print numbers or
`null`. If `cmd package resolve-activity` prints an error, that is fine, say so.

## 0.8 Amazon processes running right now

```sh
echo "== AMAZON PROCESSES (RSS KB) =="; ps -A -o RSS,NAME 2>/dev/null | grep -i -e amazon -e fireos | sort -rn | head -60; echo "== FALLBACK =="; ps -A -o RSS,NAME >/dev/null 2>&1 || ps | grep -i amazon
```

Expected: memory (KB) and name of each Amazon process alive now. The FALLBACK section stays empty unless
this Fire OS has an older `ps`, in which case it prints the old-style list instead.

## 0.9 Update and verification machinery

```sh
echo "== CANDIDATES =="; pm list packages -u | grep -i -e ota -e update -e verif -e fdra -e adep -e venezia -e tigris -e devicecontrol -e dcp -e sync; for p in com.amazon.device.software.ota com.amazon.device.software.ota.override com.amazon.tv.forcedotaupdater.v2; do echo "== $p =="; dumpsys package $p | grep -E "versionName|enabled=|pkgFlags" | head -8; done
```

Expected: the package names Amazon uses on this build for updates, app verification, the Appstore and sync.
An empty section means that package does not exist on this build, which is useful too.

---

When 0.1 to 0.9 are pasted, I write `01-gap-analysis.md` and `02-plan.md` from them.
