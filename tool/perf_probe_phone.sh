#!/bin/bash
# Drives the app UI on a phone and captures per-phase frame stats via
# SurfaceFlinger timestats (gfxinfo does not track the Impeller Vulkan
# pipeline — same reason as the tablet harness in perf_probe.sh).
#
# Usage: perf_probe_phone.sh <phase> <tag>
#   Phases: tabs | scroll | nav | theme | video | viewer | coords | disable
#   coords  — print/validate the computed tap coordinates (screenshot check).
#   video   — run with the video detail screen already open: tap-seek left/right,
#             drag-scrub the progress bar, back out. Regression probe for the
#             progress-bar gesture rework.
#   viewer  — run with the photo viewer already open: swipe images, drag-dismiss.
#             Smoke probe for decode/prefetch jank.
#
# Baseline recipe (release + canned demo data, no account needed):
#   D:/flutter/bin/flutter.bat build apk --release --target-platform android-arm64 --dart-define=DEMO_MODE=true
#   adb install -r build/app/outputs/flutter-apk/app-arm64-release.apk
#   bash tool/perf_probe_phone.sh scroll base
#   bash tool/perf_parse.sh /tmp/perf/ts_scroll_base.txt
#
# Device geometry is auto-detected (adb devices / wm size / wm density).
# Override with ADB_SER=<serial> if more than one device is attached.
#
# Coordinates are derived from the tablet harness fractions and the floating
# pill geometry (centered pill, four items, bar 64dp + 12dp margin). Validate
# once per device with: bash tool/perf_probe_phone.sh coords verify
# and adjust the fractions below if the taps miss.
PKG=com.loftify.yatmt
OUTDIR=/tmp/perf
mkdir -p $OUTDIR

# --- device detection ---------------------------------------------------------
if [ -z "$ADB_SER" ]; then
  ADB_SER=$(adb devices | awk 'NR>1 && $2=="device" {print $1; exit}')
fi
if [ -z "$ADB_SER" ]; then
  echo "no device attached"; exit 1
fi

adb_shell() { adb -s "$ADB_SER" shell "$@"; }

# wm size:   "Physical size: 1080x2400" (possibly + "Override size: ...")
# wm density: "Physical density: 420"
W=$(adb_shell wm size | awk -F': ' '/Size/ {split($2,a,"x"); w=a[1]} END {print w}')
H=$(adb_shell wm size | awk -F': ' '/Size/ {split($2,a,"x"); h=a[2]} END {print h}')
DENS=$(adb_shell wm density | awk -F': ' '/density/ {d=$2} END {print d}')
[ -z "$W" ] || [ -z "$H" ] || [ -z "$DENS" ] && { echo "failed to read wm size/density"; exit 1; }

dp2px() { echo $(( $1 * DENS / 160 )); }
dp_round() { awk -v f="$1" -v w="$W" 'BEGIN {printf "%d", f*w+0.5}'; }
dp_round_h() { awk -v f="$1" -v h="$H" 'BEGIN {printf "%d", f*h+0.5}'; }

CX=$((W/2))
# Floating pill: centered, four items (fractions from the verified tablet setup).
NAVS=($(dp_round 0.4050) $(dp_round 0.4925) $(dp_round 0.5609) $(dp_round 0.6344))
# Pill center ≈ margin 12dp + half bar 32dp + gesture inset ≈ 80dp from the bottom.
Y_NAV=$((H - $(dp2px 80)))
# A feed card near the top-left of the home waterfall (nav phase "open a post").
X_CARD=$(dp_round 0.19)
Y_CARD=$(dp_round_h 0.19)
# Mine tab → theme toggle in the top action row (right side).
X_THEME=$(dp_round 0.747)
Y_THEME=$(dp_round_h 0.048)

# --- helpers ------------------------------------------------------------------
settle() {
  # Return to the home tab so every phase starts from the same screen state.
  adb_shell input tap ${NAVS[0]} $Y_NAV
  sleep 1.6
}

dump_stats() {
  adb_shell "dumpsys SurfaceFlinger --timestats -dump" > "$OUTDIR/ts_$1_$2.txt" 2>/dev/null
  echo "saved $OUTDIR/ts_$1_$2.txt"
}

case "$1" in
  coords)
    echo "SER=$ADB_SER ${W}x${H} density=$DENS"
    echo "NAVS=${NAVS[*]} Y_NAV=$Y_NAV"
    echo "CARD=$X_CARD,$Y_CARD THEME=$X_THEME,$Y_THEME"
    if [ "$2" = "verify" ]; then
      adb exec-out screencap -p > "$OUTDIR/coords_$ADB_SER.png"
      echo "screenshot: $OUTDIR/coords_$ADB_SER.png — check the taps land on the pill items"
    fi
    ;;
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
      adb_shell input swipe $CX $((H*3/4)) $CX $((H*9/40)) 120
      sleep 0.35
    done
    for i in $(seq 1 6); do
      adb_shell input swipe $CX $((H*9/32)) $CX $((H*23/32)) 120
      sleep 0.35
    done
    sleep 0.5
    dump_stats $1 $2
    ;;
  nav)
    settle
    adb_shell "dumpsys SurfaceFlinger --timestats -enable -clear"
    for i in $(seq 1 6); do
      adb_shell input tap $X_CARD $Y_CARD   # open a post from the feed
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
      adb_shell input tap $X_THEME $Y_THEME
      sleep 1.4
    done
    sleep 0.5
    dump_stats $1 $2
    ;;
  video)
    # Open the video detail screen first. Tap-seek + drag-scrub the progress bar.
    Y_BAR=$((H - $(dp2px 120)))
    adb_shell "dumpsys SurfaceFlinger --timestats -enable -clear"
    adb_shell input tap $((W/4)) $Y_BAR          # tap-seek left half
    sleep 1.0
    adb_shell input tap $((W*3/4)) $Y_BAR        # tap-seek right half
    sleep 1.0
    for i in 1 2 3; do
      adb_shell input swipe $((W*3/4)) $Y_BAR $((W/4)) $Y_BAR 700  # drag-scrub
      sleep 0.8
    done
    sleep 0.5
    dump_stats $1 $2
    ;;
  viewer)
    # Open the photo viewer first. Swipe between images, then drag-dismiss.
    adb_shell "dumpsys SurfaceFlinger --timestats -enable -clear"
    for i in 1 2 3 4; do
      adb_shell input swipe $((W*3/4)) $((H/2)) $((W/4)) $((H/2)) 250
      sleep 0.7
    done
    adb_shell input swipe $((W/2)) $((H/2)) $((W/2)) $((H*3/4)) 250  # drag-dismiss
    sleep 0.5
    dump_stats $1 $2
    ;;
  disable)
    adb_shell "dumpsys SurfaceFlinger --timestats -disable"
    ;;
  *)
    echo "unknown phase: $1"; exit 1 ;;
esac
