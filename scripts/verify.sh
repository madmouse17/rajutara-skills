#!/usr/bin/env bash
# Verifies the skill set.
#
#   scripts/verify.sh [/path/to/optirust]
#
# 1. Layout: every skills/<name>/SKILL.md has frontmatter `name` equal to its directory, a
#    `description`, at most 300 lines, and an entry in skills/index.json (and the reverse).
# 2. With an optirust checkout: every repository path cited in backticks exists there. A cited
#    path starts with a top-level directory or root file of optirust; tokens with placeholders
#    (<name>, *, .., {}) are skipped.
set -euo pipefail

here="$(cd "$(dirname "$0")/.." && pwd)"
bad=0
fail() { echo "FAIL: $*" >&2; bad=$((bad + 1)); }

for dir in "$here"/skills/*/; do
  name="$(basename "$dir")"
  file="$dir/SKILL.md"
  [ -f "$file" ] || { fail "$name: no SKILL.md"; continue; }
  [ "$(sed -n 1p "$file")" = "---" ] || fail "$name: no frontmatter"
  [ "$(sed -n 's/^name: //p' "$file" | head -n1)" = "$name" ] || fail "$name: frontmatter name differs from directory"
  grep -q '^description: .\{20,\}' "$file" || fail "$name: missing description"
  [ "$(wc -l <"$file")" -le 300 ] || fail "$name: more than 300 lines"
  grep -q "\"path\": \"skills/$name/SKILL.md\"" "$here/skills/index.json" || fail "$name: not listed in skills/index.json"
done
for listed in $(sed -n 's|.*"path": "skills/\([^/]*\)/SKILL.md".*|\1|p' "$here/skills/index.json"); do
  [ -f "$here/skills/$listed/SKILL.md" ] || fail "index.json lists $listed, which has no SKILL.md"
done

root="${1:-}"
if [ -n "$root" ]; then
  [ -f "$root/AGENTS.md" ] || { echo "not an optirust checkout: $root" >&2; exit 2; }
  dirs='crates|docs|scripts|fixtures|samples|assets|docker|packaging|\.omp'
  files='AGENTS\.md|GLOSSARY\.md|CHANGELOG\.md|ROADMAP\.md|ATTRIBUTION\.md|CONTRIBUTING\.md|README\.md|SECURITY\.md|deny\.toml|about\.toml|rust-toolchain\.toml|Cargo\.toml|Cargo\.lock|THIRD-PARTY\.html'
  checked=0
  while IFS= read -r token; do
    path="${token//\`/}"
    path="${path%%:*}"
    case "$path" in *'<'*|*'*'*|*..*|*'{'*) continue ;; esac
    checked=$((checked + 1))
    [ -e "$root/$path" ] || fail "cited path missing in optirust: $path"
  done < <(grep -ohE "\`(($dirs)/[^\`[:space:]]*|($files))\`" "$here"/skills/*/SKILL.md | sort -u)
  echo "checked $checked cited paths"
fi

[ "$bad" -eq 0 ] && echo "ok" || { echo "$bad problem(s)" >&2; exit 1; }
