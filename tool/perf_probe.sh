#!/bin/bash
# Drives the app UI on the tablet and captures per-phase frame stats via
# SurfaceFlinger timestats (gfxinfo does not track the Impeller Vulkan
# pipeline on this device).
# Usage: perf_probe.sh <phase> <tag>
# Phases: tabs | scroll | nav    (tag: e.g. base / fixed)
SER=9d98361a
PKG=com.cloudchewie.loftify
W=2136
H=3200
# Floating pill: centered, four items. Verified against on-device screenshots.
Y_NAV=3093
NAVS=(865 1052 1198 1355)
CX=$((W/2))
OUTDIR=/tmp/perf
mkdir -p $OUTDIR

adb_shell() { adb -s $SER shell "$@"; }

# Return to the home tab so every phase starts from the same screen state.
settle() {
  adb_shell input tap ${NAVS[0]} $Y_NAV
  sleep 1.6
}

dump_stats() {
  adb_shell "dumpsys SurfaceFlinger --timestats -dump" > "$OUTDIR/ts_$1_$2.txt" 2>/dev/null
  echo "saved $OUTDIR/ts_$1_$2.txt"
}

case "$1" in
  tabs)
    settle
    adb_shell "dumpsys SurfaceFlinger --timestats -enable -clear"
    for round in 1 2 3 4 5; do
      for x in "${NAVS[@]}"; do
        adb_shell input tap $x $Y_NAV
        sleep 0.8
      done
    done
    sleep 0.5
    dump_stats $1 $2
    ;;
  scroll)
    settle
    adb_shell "dumpsys SurfaceFlinger --timestats -enable -clear"
    for i in $(seq 1 15); do
      adb_shell input swipe $CX 2400 $CX 700 120
      sleep 0.35
    done
    for i in $(seq 1 6); do
      adb_shell input swipe $CX 900 $CX 2300 120
      sleep 0.35
    done
    sleep 0.5
    dump_stats $1 $2
    ;;
  nav)
    settle
    adb_shell "dumpsys SurfaceFlinger --timestats -enable -clear"
    for i in $(seq 1 6); do
      adb_shell input tap 400 600   # open a post
      sleep 2.5
      adb_shell input keyevent KEYCODE_BACK
      sleep 1.2
    done
    sleep 0.5
    dump_stats $1 $2
    ;;
  theme)
    # Dark/light toggle in the Mine tab top action row.
    adb_shell input tap ${NAVS[3]} $Y_NAV
    sleep 1.6
    adb_shell "dumpsys SurfaceFlinger --timestats -enable -clear"
    for i in $(seq 1 8); do
      adb_shell input tap 1595 153
      sleep 1.4
    done
    sleep 0.5
    dump_stats $1 $2
    ;;
  disable)
    adb_shell "dumpsys SurfaceFlinger --timestats -disable"
    ;;
  *)
    echo "unknown phase: $1"; exit 1 ;;
esac
