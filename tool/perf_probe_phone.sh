#!/bin/bash
# Drives the app UI on a phone and captures per-phase frame stats via
# SurfaceFlinger timestats (gfxinfo does not track the Impeller Vulkan
# pipeline — same reason as the tablet harness in perf_probe.sh).
#
# Usage: perf_probe_phone.sh <phase> <tag>
#   Phases: launch | tabs | scroll | nav | theme | video | viewer | coords | disable
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
# wm density: "Physical density: 440"
# adb shell output is CRLF — strip \r so the numbers survive arithmetic.
_wm_size() { adb_shell wm size | tr -d '\r'; }
W=$(_wm_size | awk -F': ' '/size/ {split($2,a,"x"); w=a[1]} END {print w}')
H=$(_wm_size | awk -F': ' '/size/ {split($2,a,"x"); h=a[2]} END {print h}')
DENS=$(adb_shell wm density | tr -d '\r' | awk -F': ' '/density/ {d=$2} END {print d}')
if [ -z "$W" ] || [ -z "$H" ] || [ -z "$DENS" ]; then
  echo "failed to read wm size/density"
  exit 1
fi

dp2px() { echo $(( $1 * DENS / 160 )); }
dp_round() { awk -v f="$1" -v w="$W" 'BEGIN {printf "%d", f*w+0.5}'; }
dp_round_h() { awk -v f="$1" -v h="$H" 'BEGIN {printf "%d", f*h+0.5}'; }

CX=$((W/2))

# --- nav item location -------------------------------------------------------
# Preferred: locate the tab items through Flutter semantics (uiautomator
# exposes the Semantics labels with bounds). Fallback: fractions measured on
# a 1080x2400 @440dpi phone with the default icon+label pill.
NAV_LABELS=("首页" "搜索" "动态" "我的")
NAV_FALLBACK_X=(0.234 0.426 0.613 0.794)

locate_nav() {
  # Remote paths travel as part of one quoted argument: MSYS would otherwise
  # rewrite /sdcard/... into a Windows path before adb sees it.
  adb_shell "uiautomator dump /sdcard/perf_probe_ui.xml" >/dev/null 2>&1
  local xml
  xml=$(adb_shell "cat /sdcard/perf_probe_ui.xml" | tr -d '\r')
  # Labels like "首页" also appear in page titles; the nav items are the
  # bottom-most occurrences of each label.
  _label_center() {
    printf '%s\n' "$xml" \
      | grep -o "content-desc=\"$1\"[^>]*bounds=\"\[[0-9,]*\]\[[0-9,]*\]\"" \
      | sed -E 's/.*bounds="\[([0-9]+),([0-9]+)\]\[([0-9]+),([0-9]+)\]"/\1 \2 \3 \4/' \
      | awk '{cx=($1+$3)/2; cy=($2+$4)/2; if (cy>maxy) {maxy=cy; best=cx; besty=cy}}
             END {if (maxy != "") printf "%d %d", best, besty}'
  }
  NAVS=()
  local y_nav=""
  for label in "${NAV_LABELS[@]}"; do
    local center x y
    center=$(_label_center "$label")
    [ -n "$center" ] || { NAVS=(); return 1; }
    x=${center% *}
    y=${center#* }
    NAVS+=("$x")
    [ -n "$y_nav" ] || y_nav=$y
  done
  Y_NAV=$y_nav
  return 0
}

if ! locate_nav; then
  echo "warning: semantics nav lookup failed, using measured fallback fractions"
  NAVS=()
  for f in "${NAV_FALLBACK_X[@]}"; do NAVS+=("$(dp_round "$f")"); done
  Y_NAV=$((H - $(dp2px 56)))
fi

# A feed card near the top-left of the home waterfall (nav phase "open a post").
X_CARD=$(dp_round 0.19)
Y_CARD=$(dp_round_h 0.30)
# Mine tab → theme toggle in the top action row (right side).
X_THEME=$(dp_round 0.747)
Y_THEME=$(dp_round_h 0.048)

# --- helpers ------------------------------------------------------------------
settle() {
  # Return to the home tab so every phase starts from the same screen state.
  # First tap re-expands the bar if it collapsed to the round button, the
  # second lands on Home.
  adb_shell input tap $((W/2)) $Y_NAV
  sleep 0.8
  adb_shell input tap ${NAVS[0]} $Y_NAV
  sleep 1.6
}

dump_stats() {
  adb_shell "dumpsys SurfaceFlinger --timestats -dump" > "$OUTDIR/ts_$1_$2.txt" 2>/dev/null
  echo "saved $OUTDIR/ts_$1_$2.txt"
}

case "$1" in
  launch)
    adb_shell am force-stop "$PKG"
    sleep 0.5
    adb_shell am start -n "$PKG/.MainActivity" >/dev/null
    sleep 4
    echo "launched $PKG"
    ;;
  coords)
    echo "SER=$ADB_SER ${W}x${H} density=$DENS"
    echo "NAVS=${NAVS[*]} Y_NAV=$Y_NAV"
    echo "CARD=$X_CARD,$Y_CARD THEME=$X_THEME,$Y_THEME"
    if [ "$2" = "verify" ]; then
      adb -s "$ADB_SER" exec-out screencap -p > "$OUTDIR/coords_$ADB_SER.png"
      echo "screenshot: $OUTDIR/coords_$ADB_SER.png — check the taps land on the pill items"
    fi
    ;;
  tabs)
    settle
    adb_shell "dumpsys SurfaceFlinger --timestats -enable -clear"
    for round in 1 2 3 4 5; do
      for x in "${NAVS[@]}"; do
        # Re-expand first: switching into a deep-scrolled tab collapses
        # the bar, and the next item tap would otherwise miss.
        adb_shell input tap $((W/2)) $Y_NAV
        sleep 0.5
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
