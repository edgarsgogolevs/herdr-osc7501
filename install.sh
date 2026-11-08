#!/bin/sh
# Install the Herdr OSC 7501 plugin so Hermes shows up in the agents list.
#
#   install.sh                 this computer
#   install.sh arch            one machine from `hc machine ls`
#   install.sh --all           this computer and every connected machine
#
# A remote agent is a Hermes process on that machine. Herdr only lists it
# after that process reports OSC 7501, so the plugin has to be installed
# there, not only here. Restart Hermes on that machine after installing.
# Already-open sessions keep the copy they started with.
set -eu

src=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
name=herdr-osc7501

die() { printf '%s\n' "$1" >&2; exit 1; }

install_here() {
  home=${HERMES_HOME:-$HOME/.hermes}
  dest=$home/plugins/$name
  mkdir -p "$dest"
  cp "$src/plugin.yaml" "$src/__init__.py" "$dest/"
  if ! command -v hermes >/dev/null 2>&1; then
    die "hermes is not on PATH. Plugin files are in $dest; enable it once hermes is installed."
  fi
  hermes plugins enable "$name" --no-allow-tool-override
  printf 'installed on this computer (%s)\n' "$dest"
}

remote_home() {
  hc exec --on "$1" --timeout 30 -- python3 -c 'import os; print(os.path.expanduser("~"))'
}

install_machine() {
  machine=$1
  command -v hc >/dev/null 2>&1 || die "hc is not on PATH; cannot reach $machine"
  home=$(remote_home "$machine")
  home=$(printf '%s' "$home" | tr -d '\r')
  case $home in
    /*) ;;
    *) die "could not resolve the home directory on $machine (got: $home)" ;;
  esac
  dest=$home/.hermes/plugins/$name
  hc file write --on "$machine" "$dest/plugin.yaml" < "$src/plugin.yaml"
  hc file write --on "$machine" "$dest/__init__.py" < "$src/__init__.py"
  if ! hc exec --on "$machine" --timeout 60 -- hermes plugins enable "$name" --no-allow-tool-override; then
    die "copied the plugin to $machine:$dest but hermes plugins enable failed. Install Hermes there, then re-run."
  fi
  printf 'installed on %s (%s)\n' "$machine" "$dest"
}

install_all() {
  install_here
  command -v hc >/dev/null 2>&1 || die "hc is not on PATH; installed locally only"
  hc machine ls --json | python3 -c '
import json, sys
data = json.load(sys.stdin)
for m in data.get("machines", []):
    if m.get("temporary"):
        continue
    if m.get("state") != "connected":
        print("skip %s (%s)" % (m.get("name") or m.get("id"), m.get("state")), file=sys.stderr)
        continue
    print(m["name"])
' | while IFS= read -r machine; do
    [ -n "$machine" ] || continue
    install_machine "$machine"
  done
}

case ${1:-} in
  "") install_here ;;
  --all) install_all ;;
  -h|--help)
    printf '%s\n' "Usage: install.sh [machine|--all]" \
      "  no argument   this computer" \
      "  <machine>     one machine from hc machine ls" \
      "  --all         this computer and every connected machine"
    ;;
  *) install_machine "$1" ;;
esac
