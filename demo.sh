#!/usr/bin/env bash
# demo.sh — render every pet state with a pinned clock.
# Doubles as a smoke test: any state that crashes shows up here.
#
#   ./demo.sh          render the mood states
#   ./demo.sh stunts   walk through all 9 idle stunts, frame by frame

set -u
HERE=$(cd "$(dirname "$0")" && pwd)
SL="$HERE/statusline.sh"

# <model> <ctx%> <effort> <cwd> <tag>
# The tag becomes the session id: git results are cached ~5s per session, so
# scenarios sharing an id would leak state into each other.
payload() {
  printf '{"model":{"display_name":"%s"},"context_window":{"used_percentage":%s},' "$1" "$2"
  printf '"effort":{"level":"%s"},"thinking":{"enabled":true},' "$3"
  printf '"rate_limits":{"five_hour":{"used_percentage":41},"seven_day":{"used_percentage":63}},'
  printf '"workspace":{"current_dir":"%s"},"session_id":"demo-%s"}' "$4" "$5"
}

# <tick> <model> <ctx%> <effort>  — tick doubles as the session tag
render() { payload "$2" "$3" "$4" "$HERE" "$1" | SL_TICK="$1" bash "$SL"; }

if [ "${1:-}" = stunts ]; then
  i=0
  for n in nap dance wave tableflip flower coffee sparkle hug wander; do
    printf '\n\033[1m%s\033[0m\n' "$n"
    f=0
    while [ $f -lt 4 ]; do
      render $(( i * 10 + f )) "Opus 5" 20 high | head -1
      f=$(( f + 1 ))
    done
    i=$(( i + 1 ))
  done
  exit 0
fi

title() { printf '\n\033[1m%s\033[0m\n' "$1"; }
show()  { title "$1"; shift; render "$@"; }

show "idle — plenty of context"   5  "Opus 5" 12 high
show "focused — over half"        15 "Opus 5" 62 high
show "locked in — xhigh effort"   18 "Opus 5" 30 xhigh
show "sweating — 78%"             25 "Opus 5" 78 high
show "panic — 94%"                35 "Opus 5" 94 max

title "custom badge (SL_BADGE_CMD)"
payload "Opus 5" 20 high "$HERE" badge \
  | SL_TICK=45 SL_NO_SERAI=1 SL_BADGE_CMD='echo env:prod' bash "$SL"

title "no git, no badge"
payload "Opus 5" 20 high /tmp nogit | SL_TICK=55 bash "$SL"

title "malformed input (must still print, exit 0)"
echo 'not json' | SL_TICK=5 bash "$SL"; printf 'exit=%s\n' "$?"
