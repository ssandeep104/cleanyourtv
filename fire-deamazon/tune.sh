#!/usr/bin/env bash
# fire-deamazon/tune.sh: animation scales to 0.5, cache trim, then a verification block of the whole tuned state.
# One run from a Mac (or Linux) terminal with adb connected to the stick (AFTSS, Fire OS 7.7.1.7 PS7717/5741).
#
# Run:     bash fire-deamazon/tune.sh
#          Verification only, no changes (use this for re-checks; sections 1 and 2 are skipped):
#          bash fire-deamazon/tune.sh --verify
#          (with more than one adb device attached: ANDROID_SERIAL=<stick ip>:5555 bash fire-deamazon/tune.sh)
# Log:     fire-deamazon/tune-YYYYmmdd-HHMMSS.log, next to this script.
#
# What it changes, and nothing else:
#   1. settings global window_animation_scale, transition_animation_scale, animator_duration_scale -> 0.5
#   2. pm trim-caches 999G (deletes app caches only; caches rebuild as apps run)
#
# RESTORE (animation scales). The values read at the start are printed in the log as exact restore lines; use
# those. If a value was read as "null" (never set), its default is 1.0. Normally:
#   adb shell settings put global window_animation_scale 1.0
#   adb shell settings put global transition_animation_scale 1.0
#   adb shell settings put global animator_duration_scale 1.0
# The cache trim has no restore and needs none.
#
# The verification block also covers round 2 (2026-10-26, applied by hand over adb, not by this script). Its
# restore lines, for reference only:
#   adb shell pm enable --user 0 com.amazon.device_remote_config_sync_service   (same for com.amazon.ale,
#     com.amazon.providers.contentsupport, com.amazon.connectivitydiag, com.amazon.katoch)
#   adb shell cmd appops set com.amazon.cloud9 RUN_ANY_IN_BACKGROUND allow       (same for com.amazon.venezia)
#   adb shell cmd appops set com.amazon.diode RUN_ANY_IN_BACKGROUND allow; adb shell cmd appops set com.amazon.diode RUN_IN_BACKGROUND allow
#     (same pair for com.amazon.device.logmanager, com.amazon.device.crashmanager, com.fireos.usagestats.proxy)
#   adb shell settings delete global ble_scan_always_enabled                     (it was unset before)
# Exit codes: 0 PASS, 1 different build or a PROBLEM line, 2 adb connection or read failed (nothing changed).
# Run it once. A second run would read 0.5 as the 'before' value; the first run's log keeps the true restore lines.

set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
LOG="$HERE/tune-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1

EXPECT_BUILD="Fire OS 7.7.1.7 (PS7717/5741)"
EXPECT_ENABLED=195
EXPECT_DISABLED=58
SCALES="window_animation_scale transition_animation_scale animator_duration_scale"
D1_APPS="com.amazon.firetv.youtube com.instagram.airwave"
BG_APPS="com.amazon.cloud9 com.amazon.venezia"
TELEMETRY="com.amazon.device.logmanager com.amazon.device.crashmanager com.amazon.diode com.fireos.usagestats.proxy"
R2_DISABLED="com.amazon.device_remote_config_sync_service com.amazon.ale com.amazon.providers.contentsupport com.amazon.connectivitydiag com.amazon.katoch"
VERIFY_ONLY=0
[ "${1:-}" = "--verify" ] && VERIFY_ONLY=1

PASS=0
PROBLEM=0
pass()    { PASS=$((PASS + 1));       echo "  PASS     $*"; }
problem() { PROBLEM=$((PROBLEM + 1)); echo "  PROBLEM  $*"; }
sh_()     { adb shell "$@" 2>&1 | tr -d '\r'; }
section() { echo; echo "== $* =="; }
# A build read is only trusted if it looks like a Fire OS version string; anything else (empty, "error: closed",
# "device offline", "unauthorized") means the adb connection or the read failed, not that the build changed.
is_build() { case "$1" in "Fire OS "*) return 0 ;; *) return 1 ;; esac; }
reconnect_help() {
  echo "The adb connection or the read failed; nothing on the stick was changed. Reconnect, then run the script again:"
  echo "  adb disconnect; adb connect <stick ip>:5555     (accept the prompt on the TV if it appears)"
  echo "  if that fails while the stick answers ping:  adb kill-server; adb connect <stick ip>:5555"
}

echo "fire-deamazon tune.sh  $(date)"
echo "log: $LOG"

section "0. Pre-flight"
STATE="$(adb get-state 2>&1 | tr -d '\r')"
if [ "$STATE" != "device" ]; then
  echo "adb get-state: $STATE"
  echo "No authorized adb device."
  reconnect_help
  exit 2
fi
BUILD="$(sh_ getprop ro.build.version.name)"
echo "build: $BUILD"
if ! is_build "$BUILD"; then
  echo "Could not read the build (the text above is an adb error, not a build)."
  reconnect_help
  exit 2
fi
if [ "$BUILD" != "$EXPECT_BUILD" ]; then
  echo "The stick reports a different build than '$EXPECT_BUILD': the staged update may have installed."
  echo "Stopping before any change. Run the standing re-check in fire-deamazon/README.md first."
  exit 1
fi
EN0="$(sh_ pm list packages -e | wc -l | tr -d ' ')"
DI0="$(sh_ pm list packages -d | wc -l | tr -d ' ')"
echo "enabled: $EN0  disabled: $DI0 (before)"

if [ "$VERIFY_ONLY" = 1 ]; then
  echo "verification only (--verify): sections 1 and 2 skipped, nothing will be changed"
else
section "1. Animation scales"
echo "read before:"
RESTORE=""
for s in $SCALES; do
  v="$(sh_ settings get global "$s")"
  echo "  $s = $v"
  case "$v" in null|"") r=1.0 ;; *) r="$v" ;; esac
  RESTORE="${RESTORE}adb shell settings put global $s $r"$'\n'
done
echo "restore lines for these exact values:"
printf '%s' "$RESTORE" | sed 's/^/  /'
for s in $SCALES; do
  out="$(sh_ settings put global "$s" 0.5)"
  [ -n "$out" ] && echo "  settings put $s: $out"
done
echo "read after:"
for s in $SCALES; do
  v="$(sh_ settings get global "$s")"
  case "$v" in
    0.5|0.50) pass "$s = $v" ;;
    *) problem "$s = $v (expected 0.5)" ;;
  esac
done

section "2. Storage hygiene"
echo "/data before:"
sh_ df -h /data | sed 's/^/  /'
out="$(sh_ pm trim-caches 999G)"
if [ -z "$out" ]; then
  pass "pm trim-caches 999G returned no error"
else
  echo "  pm trim-caches output: $out"
  case "$out" in
    *Exception*|*Error*|*rror:*|*denied*) problem "pm trim-caches reported an error" ;;
    *) pass "pm trim-caches ran (see output above)" ;;
  esac
fi
echo "/data after:"
sh_ df -h /data | sed 's/^/  /'
fi

section "3. Verification"
BUILD2="$(sh_ getprop ro.build.version.name)"
if ! is_build "$BUILD2"; then
  problem "build could not be read: $BUILD2 (adb connection or read failed; reconnect and run section 3's checks again)"
elif [ "$BUILD2" = "$EXPECT_BUILD" ]; then
  pass "build: $BUILD2"
else
  problem "build: $BUILD2 (expected $EXPECT_BUILD; the staged update may have installed)"
fi
EN1="$(sh_ pm list packages -e | wc -l | tr -d ' ')"
DI1="$(sh_ pm list packages -d | wc -l | tr -d ' ')"
[ "$EN1" = "$EXPECT_ENABLED" ] && pass "enabled: $EN1" || problem "enabled: $EN1 (expected $EXPECT_ENABLED)"
[ "$DI1" = "$EXPECT_DISABLED" ] && pass "disabled: $DI1" || problem "disabled: $DI1 (expected $EXPECT_DISABLED)"
[ "$EN1" = "$EN0" ] && [ "$DI1" = "$DI0" ] && pass "counts unchanged by this run ($EN0/$DI0)" || problem "counts moved during this run: $EN0/$DI0 -> $EN1/$DI1"
VER="$(sh_ settings get global package_verifier_enable)"
[ "$VER" = "0" ] && pass "verifier: $VER" || problem "verifier: $VER (expected 0)"
for p in $D1_APPS; do
  v="$(sh_ cmd appops get "$p" RUN_ANY_IN_BACKGROUND)"
  case "$v" in
    *ignore*) pass "D1 $p: $v" ;;
    *) problem "D1 $p: $v (expected ignore)" ;;
  esac
done
for p in $BG_APPS; do
  v="$(sh_ cmd appops get "$p" RUN_ANY_IN_BACKGROUND)"
  case "$v" in
    *ignore*) pass "background $p: $v" ;;
    *) problem "background $p: $v (expected ignore)" ;;
  esac
done
for p in $TELEMETRY; do
  for op in RUN_ANY_IN_BACKGROUND RUN_IN_BACKGROUND; do
    v="$(sh_ cmd appops get "$p" "$op")"
    case "$v" in
      *ignore*) pass "telemetry $p $op: $(printf '%s' "$v" | tr '\n' ' ')" ;;
      *) problem "telemetry $p $op: $v (expected ignore)" ;;
    esac
  done
done
DLIST="$(sh_ pm list packages -d)"
for p in $R2_DISABLED; do
  if printf '%s\n' "$DLIST" | grep -qx "package:$p"; then pass "disabled: $p"; else problem "$p is not disabled (round 2 expects it disabled)"; fi
done
for s in $SCALES; do
  v="$(sh_ settings get global "$s")"
  case "$v" in 0.5|0.50) pass "$s = $v" ;; *) problem "$s = $v (expected 0.5)" ;; esac
done
BLE="$(sh_ settings get global ble_scan_always_enabled)"
[ "$BLE" = "0" ] && pass "ble_scan_always_enabled: $BLE" || problem "ble_scan_always_enabled: $BLE (expected 0)"

section "Summary"
echo "PASS: $PASS   PROBLEM: $PROBLEM"
if [ "$PROBLEM" -eq 0 ]; then
  echo "RESULT: PASS"
else
  echo "RESULT: PROBLEM (see the PROBLEM lines above; restore lines: the header of tune.sh, and section 1 of the first run's log)"
fi
echo "log saved: $LOG"
[ "$PROBLEM" -eq 0 ]
