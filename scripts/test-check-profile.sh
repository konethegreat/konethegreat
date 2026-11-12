#!/usr/bin/env bash
# Tests for scripts/check-profile.sh.
#
# Every case copies the repository's README.md, assets/ and docs/ into a fresh
# temporary fixture, applies one change and runs check-profile.sh against it,
# asserting the exit code and, for failures, that the output names the offender.
# Dashes are generated with printf byte escapes so this file contains none.
#
# Usage: scripts/test-check-profile.sh
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(cd "$script_dir/.." && pwd)
checker="$script_dir/check-profile.sh"

tmp_root=$(mktemp -d)
trap 'rm -rf "$tmp_root"' EXIT

em_dash=$(printf '\xe2\x80\x94')
en_dash=$(printf '\xe2\x80\x93')

passed=0
failed=0

new_fixture() {
  local dir
  dir=$(mktemp -d "$tmp_root/fixture.XXXXXX")
  cp "$repo_root/README.md" "$dir/README.md"
  if [[ -d $repo_root/assets ]]; then cp -R "$repo_root/assets" "$dir/assets"; fi
  if [[ -d $repo_root/docs ]]; then cp -R "$repo_root/docs" "$dir/docs"; fi
  printf '%s\n' "$dir"
}

# run_case NAME EXPECTED_EXIT EXPECTED_OUTPUT_SUBSTRING SETUP_FUNCTION
run_case() {
  local name=$1 want=$2 needle=$3 setup=$4 dir out rc=0
  dir=$(new_fixture)
  "$setup" "$dir"
  out=$(bash "$checker" "$dir" 2>&1) || rc=$?
  if [[ $rc -eq $want && ( -z $needle || $out == *"$needle"* ) ]]; then
    printf 'PASS  %s (exit %d)\n' "$name" "$rc"
    passed=$((passed + 1))
  else
    printf 'FAIL  %s (exit %d, expected exit %d' "$name" "$rc" "$want"
    if [[ -n $needle ]]; then printf ' and output containing "%s"' "$needle"; fi
    printf ')\n'
    printf '%s\n' "$out" | sed 's/^/      /'
    failed=$((failed + 1))
  fi
}

svg_head='<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10" viewBox="0 0 10 10">'

setup_clean() { :; }

setup_em_dash_readme() {
  printf '\nA sentence with an em dash %s here.\n' "$em_dash" >>"$1/README.md"
}

setup_en_dash_docs() {
  mkdir -p "$1/docs/guide/deep"
  printf '# Notes\n\nPages 1%s3.\n' "$en_dash" >"$1/docs/guide/deep/notes.md"
}

setup_en_dash_svg() {
  printf '%s\n  <title>A%sB</title>\n</svg>\n' "$svg_head" "$en_dash" >"$1/assets/dash.svg"
}

setup_img_new_host() {
  printf '\n<img src="https://example.com/x.png" alt="x" />\n' >>"$1/README.md"
}

setup_img_single_quotes() {
  printf "\n<img alt='y' src='https://example.com/y.png'>\n" >>"$1/README.md"
}

setup_srcset_new_host() {
  printf '\n<picture>\n  <source srcset="assets/banner.svg 1x, https://example.com/x-2x.png 2x" />\n  <img src="assets/banner.svg" alt="b" />\n</picture>\n' >>"$1/README.md"
}

setup_markdown_image() {
  printf '\n![z](https://example.com/z.png)\n' >>"$1/README.md"
}

setup_dot_dot_escape() {
  printf '\n<img src="https://raw.githubusercontent.com/konethegreat/konethegreat/output/../../main/x.svg" alt="d" />\n' >>"$1/README.md"
}

setup_svg_https_link() {
  printf '%s\n  <image href="https://example.com/x.png" width="10" height="10"/>\n</svg>\n' "$svg_head" >"$1/assets/external.svg"
}

setup_svg_http_link() {
  printf '%s\n  <a href="http://example.com/"><rect width="10" height="10"/></a>\n</svg>\n' "$svg_head" >"$1/assets/plain-http.svg"
}

setup_svg_xlink_namespace() {
  printf '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="10" height="10">\n  <use xlink:href="#a"/>\n</svg>\n' >"$1/assets/xlink.svg"
}

setup_missing_root() {
  rm -rf "$1"
}

echo "Testing scripts/check-profile.sh"
run_case "clean copy of the repository" 0 "check-profile: OK" setup_clean
run_case "em dash in README.md" 1 "README.md:" setup_em_dash_readme
run_case "en dash in docs/guide/deep/notes.md" 1 "docs/guide/deep/notes.md:3:" setup_en_dash_docs
run_case "en dash in assets/dash.svg" 1 "assets/dash.svg:2:" setup_en_dash_svg
run_case "README img src on a new host" 1 "https://example.com/x.png" setup_img_new_host
run_case "README img src on a new host, single quotes" 1 "https://example.com/y.png" setup_img_single_quotes
run_case "README srcset with one URL on a new host" 1 "srcset points outside the allowed image sources: https://example.com/x-2x.png" setup_srcset_new_host
run_case "README Markdown image on a new host" 1 "https://example.com/z.png" setup_markdown_image
run_case "README img src escaping the output prefix with .." 1 "output/../../main/x.svg" setup_dot_dot_escape
run_case "SVG in assets/ with an external https link" 1 "assets/external.svg:2: external reference" setup_svg_https_link
run_case "SVG in assets/ with an external http link" 1 "assets/plain-http.svg:2: external reference" setup_svg_http_link
run_case "SVG with only the svg and xlink xmlns declarations" 0 "check-profile: OK" setup_svg_xlink_namespace
run_case "missing root directory is a usage error" 2 "root directory not found" setup_missing_root

printf '%d passed, %d failed\n' "$passed" "$failed"
if [[ $failed -gt 0 ]]; then
  exit 1
fi
