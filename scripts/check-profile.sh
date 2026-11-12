#!/usr/bin/env bash
# Profile guard for the konethegreat profile repository.
#
# Fails (exit 1) and prints every offending file and line when:
#   1. README.md, assets/*.svg or docs/**/*.md contain U+2014 (em dash) or U+2013 (en dash).
#   2. A src or srcset attribute, or an inline Markdown image, in README.md points anywhere
#      other than assets/, ./assets/, https://img.shields.io/ or
#      https://raw.githubusercontent.com/konethegreat/konethegreat/output/.
#   3. An assets/*.svg file contains an http:// or https:// reference other than the
#      xmlns="http://www.w3.org/2000/svg" or xmlns:xlink="http://www.w3.org/1999/xlink"
#      namespace declarations.
# Exits 0 with an OK line when everything is clean, and 2 on a usage error.
#
# Usage: scripts/check-profile.sh [root-dir]   (root-dir defaults to the repository root)
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=${1:-"$script_dir/.."}

if [[ $# -gt 1 ]]; then
  echo "usage: check-profile.sh [root-dir]" >&2
  exit 2
fi
if [[ ! -d $root ]]; then
  echo "check-profile: root directory not found: $root" >&2
  exit 2
fi
cd "$root"

# Match raw UTF-8 bytes, independent of the runner's locale.
export LC_ALL=C

em_dash=$'\xe2\x80\x94'
en_dash=$'\xe2\x80\x93'

failures=0
report() {
  printf '%s\n' "$1"
  failures=$((failures + 1))
}

# Files covered by the dash check.
text_files=()
if [[ -f README.md ]]; then
  text_files+=(README.md)
else
  report "README.md: not found"
fi

svg_files=()
for f in assets/*.svg; do
  if [[ -f $f ]]; then svg_files+=("$f"); fi
done
text_files+=(${svg_files[@]+"${svg_files[@]}"})

if [[ -d docs ]]; then
  while IFS= read -r -d '' f; do
    text_files+=("$f")
  done < <(find docs -type f -name '*.md' -print0 | sort -z)
fi

# 1. Em and en dashes.
check_dashes() {
  local f hits entry text what
  for f in ${text_files[@]+"${text_files[@]}"}; do
    if hits=$(grep -naF -e "$em_dash" -e "$en_dash" -- "$f"); then
      while IFS= read -r entry; do
        text=${entry#*:}
        what=""
        if [[ $text == *"$em_dash"* ]]; then what="U+2014 em dash"; fi
        if [[ $text == *"$en_dash"* ]]; then what="${what:+$what and }U+2013 en dash"; fi
        report "$f:${entry%%:*}: contains $what"
      done <<<"$hits"
    fi
  done
}

# 2. Image sources in README.md.
image_url_allowed() {
  local url=$1
  # Refuse anything that could step out of an allowed prefix once a browser
  # normalises the path: dot-dot segments, encoded dots and backslashes.
  case $url in
    */..* | ../* | .. | *\\* | *%2[eE]*) return 1 ;;
  esac
  case $url in
    assets/?* | ./assets/?* | https://img.shields.io/?* | \
      https://raw.githubusercontent.com/konethegreat/konethegreat/output/?*)
      return 0
      ;;
  esac
  return 1
}

check_image_url() {
  local lineno=$1 kind=$2 url=$3
  if ! image_url_allowed "$url"; then
    report "README.md:$lineno: $kind points outside the allowed image sources: ${url:-(empty)}"
  fi
}

count_newlines() {
  local s=${1//[^$'\n']/}
  printf '%d' "${#s}"
}

trim() {
  local s=$1
  s=${s#"${s%%[![:space:]]*}"}
  s=${s%"${s##*[![:space:]]}"}
  printf '%s' "$s"
}

check_readme_images() {
  [[ -f README.md ]] || return 0
  local content rest match prefix value head kind lineno line pass re cand url
  local re_attr re_md
  # src= or srcset= (any case), with a double-quoted, single-quoted or unquoted value.
  re_attr="(^|[^[:alnum:]_-])([Ss][Rr][Cc]([Ss][Ee][Tt])?)[[:space:]]*=[[:space:]]*(\"[^\"]*\"|'[^']*'|[^[:space:]>\"']+)"
  # Inline Markdown image: ![alt](url) or ![alt](<url>).
  re_md='!\[[^]]*\]\([[:space:]]*<?([^[:space:]<>)]+)'

  content=$(<README.md)
  content=${content//$'\r'/}

  for pass in attr md; do
    if [[ $pass == attr ]]; then re=$re_attr; else re=$re_md; fi
    rest=$content
    line=1
    while [[ $rest =~ $re ]]; do
      match=${BASH_REMATCH[0]}
      if [[ $pass == attr ]]; then
        kind=$(printf '%s' "${BASH_REMATCH[2]}" | tr '[:upper:]' '[:lower:]')
        value=${BASH_REMATCH[4]}
      else
        kind="markdown image"
        value=${BASH_REMATCH[1]}
      fi
      prefix=${rest%%"$match"*}
      head=${match:0:${#match}-${#value}}
      lineno=$((line + $(count_newlines "$prefix$head")))

      if [[ $value == \"*\" || $value == \'*\' ]]; then
        value=${value:1:${#value}-2}
      fi
      value=${value//[$'\n\t']/ }

      if [[ $kind == srcset ]]; then
        IFS=',' read -ra cands <<<"$value"
        for cand in ${cands[@]+"${cands[@]}"}; do
          cand=$(trim "$cand")
          [[ -n $cand ]] || continue
          url=${cand%%[[:space:]]*}
          check_image_url "$lineno" "srcset" "$url"
        done
      else
        check_image_url "$lineno" "$kind" "$(trim "$value")"
      fi

      line=$((line + $(count_newlines "$prefix$match")))
      rest=${rest:${#prefix}+${#match}}
    done
  done
}

# 3. External references inside assets/*.svg.
check_svg_refs() {
  local f hits entry
  local strip_ns="s#xmlns[[:space:]]*=[[:space:]]*(\"http://www\\.w3\\.org/2000/svg\"|'http://www\\.w3\\.org/2000/svg')##g"
  local strip_xlink="s#xmlns:xlink[[:space:]]*=[[:space:]]*(\"http://www\\.w3\\.org/1999/xlink\"|'http://www\\.w3\\.org/1999/xlink')##g"
  for f in ${svg_files[@]+"${svg_files[@]}"}; do
    if hits=$(sed -E -e "$strip_ns" -e "$strip_xlink" "$f" | grep -naiE 'https?://'); then
      while IFS= read -r entry; do
        entry=${entry//$'\r'/}
        report "$f:${entry%%:*}: external reference: $(trim "${entry#*:}")"
      done <<<"$hits"
    fi
  done
}

check_dashes
check_readme_images
check_svg_refs

if [[ $failures -gt 0 ]]; then
  printf 'check-profile: FAILED with %d finding(s)\n' "$failures"
  exit 1
fi
printf 'check-profile: OK, %d files checked (%d of them assets/*.svg)\n' \
  "${#text_files[@]}" "${#svg_files[@]}"
