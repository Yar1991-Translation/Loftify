#!/bin/bash
# Summarize SurfaceFlinger timestats for the Loftify layer.
# Usage: perf_parse.sh <ts-file>
AWKPROG='
/layerName = .*loftify/ { inlayer=1 }
inlayer && /renderRate/     { gsub(/[^0-9]/,"",$3); rr=$3 }
inlayer && /totalFrames =/  { tf+=$3 }
inlayer && /totalTimelineFrames/ { ttf+=$3 }
inlayer && /jankyFrames/    { jf+=$3 }
inlayer && /appUnattributedJankyFrames/ { au+=$3 }
inlayer && /sfLongGpuJankyFrames/ { sfg+=$3 }
inlayer && /sfLongCpuJankyFrames/ { sfc+=$3 }
inlayer && /averageFPS/     { afps+=$3; nl++ }
inlayer && /^present2present histogram/ { mode=1; next }
mode && /ms=/ {
  n=split($0, pairs, /[ \t]+/);
  for (i=1; i<=n; i++) {
    split(pairs[i], kv, "=");
    if (kv[1]+0 >= 25) big += kv[2]+0;
    total += kv[2]+0;
  }
  mode=0
}
END {
  if (ttf == 0) { print "no loftify layer data"; exit 1 }
  printf "renderRate=%d totalTimelineFrames=%d jankyFrames=%d (%.1f%%) appUnattributed=%d sfLongGpu=%d sfLongCpu=%d gaps>=25ms=%d/%d avgFPS=%.1f\n",
    rr, ttf, jf, (ttf? 100.0*jf/ttf : 0), au, sfg, sfc, big, total, (nl? afps/nl : 0);
}'
awk "$AWKPROG" "$1"
