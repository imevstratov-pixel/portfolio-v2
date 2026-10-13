#!/usr/bin/env bash
# Internal-notes check over the built site (quality bar of the brief).
#
#   npm run build && npm run leakcheck            # checks dist/
#   bash tools/leakcheck.sh path/to/dist
#
# In a preview build (PREVIEW not 0) it also fails on the Metrika counter
# (mc.yandex.ru) anywhere in dist/ and on any HTML page without a robots meta.
#
# Greps dist/ for: _note _todo _draft hidden «МЕСТО ДЛЯ» seller-ai-course
# studio-expert university-curator.
# - Everything the build generates (Astro pages, _astro/ assets, work.html,
#   404.html) must contain none of them.
# - Files copied verbatim from the old site (assets/, resume/, demo/, en/,
#   styles.css, script.js, game.js, products/) must contain none of the content
#   markers; in them "hidden" and "_note" also occur as ordinary CSS/HTML
#   (overflow:hidden, aria-hidden, .lightbox__note), so those two are listed
#   for review but do not fail the check. Pass --strict to fail on them too.
set -euo pipefail

STRICT=0
DIST=""
for arg in "$@"; do
  case "$arg" in
    --strict) STRICT=1 ;;
    *) DIST="$arg" ;;
  esac
done
DIST="${DIST:-$(cd "$(dirname "$0")/.." && pwd)/dist}"
[ -f "$DIST/index.html" ] || { echo "leakcheck: $DIST has no index.html, run npm run build first" >&2; exit 1; }

ALL='_note|_todo|_draft|hidden|МЕСТО ДЛЯ|seller-ai-course|studio-expert|university-curator'
CONTENT='_todo|_draft|МЕСТО ДЛЯ|seller-ai-course|studio-expert|university-curator'
SOFT='_note|hidden'
# print each hit as file:line: …context… (minified files have very long lines)
hits() { local pat="$1"; shift; grep -I -n -o -E ".{0,40}($pat).{0,40}" -- "$@"; }
LEGACY=(assets resume demo en styles.css script.js game.js products)

cd "$DIST"
prune=()
for p in "${LEGACY[@]}"; do prune+=(-path "./$p" -prune -o); done
mapfile -t generated < <(find . "${prune[@]}" -type f -print | sort)
legacy=()
for p in "${LEGACY[@]}"; do
  [ -e "$p" ] && mapfile -t -O "${#legacy[@]}" legacy < <(find "./$p" -type f | sort)
done

fail=0
if [ "${#generated[@]}" -gt 0 ] && hits "$ALL" "${generated[@]}"; then
  echo "leakcheck: internal markers found in generated files (above)" >&2
  fail=1
fi
if [ "${#legacy[@]}" -gt 0 ] && hits "$CONTENT" "${legacy[@]}"; then
  echo "leakcheck: content markers found in copied legacy files (above)" >&2
  fail=1
fi
soft=$( [ "${#legacy[@]}" -gt 0 ] && grep -I -l -E "$SOFT" -- "${legacy[@]}" || true )
if [ -n "$soft" ]; then
  if [ "$STRICT" = 1 ]; then
    echo "leakcheck (--strict): \"hidden\" or \"_note\" in legacy files:" >&2
    # shellcheck disable=SC2086
    hits "$SOFT" $soft >&2
    fail=1
  else
    echo "leakcheck: note, \"hidden\"/\"_note\" occur in $(echo "$soft" | wc -l) legacy file(s) copied from the old site (CSS/HTML usage; review with --strict):"
    echo "$soft" | sed 's/^/  /'
  fi
fi

# Preview builds (PREVIEW not 0): no analytics anywhere and noindex on every
# HTML page, legacy pages included (tools/legacy-preview.mjs adds it there).
if [ "$(echo "${PREVIEW:-1}" | tr -d '[:space:]')" != "0" ]; then
  if grep -rIl 'mc.yandex.ru' . >/dev/null 2>&1; then
    echo "leakcheck: preview build contains the Yandex Metrika counter:" >&2
    grep -rIl 'mc.yandex.ru' . | sed 's/^/  /' >&2
    fail=1
  fi
  mapfile -t noindex_missing < <(find . -name '*.html' -type f -print0 | xargs -0 grep -L 'name="robots"' | sort)
  if [ "${#noindex_missing[@]}" -gt 0 ]; then
    echo "leakcheck: preview build has HTML pages without a robots meta:" >&2
    printf '  %s\n' "${noindex_missing[@]}" >&2
    fail=1
  fi
fi

echo "leakcheck: ${#generated[@]} generated files, ${#legacy[@]} legacy files checked"
if [ "$fail" = 1 ]; then exit 1; fi
echo "OK: no internal notes in dist/"
