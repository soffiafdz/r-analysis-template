#!/usr/bin/env bash
# Screenshot every slide of a rendered revealjs deck, to check each one
# before the deck is shared (docs/STYLE.md, "Checking a deck").
#   reports-src/screenshot_slides.sh outputs/reports/slides.html <out_dir>
# Needs Firefox (FIREFOX=/path/to/firefox if it is not on the PATH); on some
# machines Chrome's headless mode crashes or prints blank pages. The window
# size is the deck's width and height (SLIDE_SIZE, default 1600,900).
set -euo pipefail

if [ $# -ne 2 ]; then
  echo "usage: $0 <deck.html> <out_dir>" >&2
  exit 1
fi
deck=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
out=$2
firefox=${FIREFOX:-firefox}
size=${SLIDE_SIZE:-1600,900}

mkdir -p "$out"
profile=$(mktemp -d)
trap 'rm -rf "$profile"' EXIT

n=$(grep -Eo '<section [^>]*class="([^"]* )?slide[ "]' "$deck" | wc -l)
for i in $(seq 0 $((n - 1))); do
  png=$(printf "%s/slide_%02d.png" "$out" $((i + 1)))
  "$firefox" --headless --no-remote --profile "$profile" \
    --window-size="$size" --screenshot "$png" "file://$deck#/$i" \
    > /dev/null 2>&1
done
echo "$n slides saved in $out"
