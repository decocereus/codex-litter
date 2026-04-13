#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SWITCH_SCRIPT="$SCRIPT_DIR/switch-app-identity.sh"

IDENTIFIER="${IOS_LOCAL_IDENTIFIER:-}"
TEAM_ID="${IOS_LOCAL_TEAM_ID:-}"
DOWNLOAD_FRAMEWORKS=1

usage() {
  cat <<'EOF'
Usage: ./tools/scripts/setup-ios-local.sh [options]

Configures the repo for local iOS development by:
  1. choosing a local bundle/app-group identifier
  2. setting the iOS development team in apps/ios/project.yml
  3. regenerating apps/ios/Litter.xcodeproj
  4. optionally downloading ios_system frameworks

Options:
  --identifier <name>      Identifier prefix for com.<name>.litter
                           Defaults to a sanitized version of the current username.
  --team-id <id>           Apple Development team ID.
                           Defaults to the first Apple Development identity found in the keychain.
  --skip-frameworks        Skip downloading ios_system frameworks.
  -h, --help              Show this help.

Environment:
  IOS_LOCAL_IDENTIFIER     Same as --identifier
  IOS_LOCAL_TEAM_ID        Same as --team-id
EOF
}

sanitize_identifier() {
  local raw="$1"
  local normalized
  normalized="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '_')"
  normalized="${normalized##_}"
  normalized="${normalized%%_}"
  if [[ -z "$normalized" ]]; then
    normalized="localdev"
  fi
  if [[ ! "$normalized" =~ ^[a-z] ]]; then
    normalized="dev_${normalized}"
  fi
  printf '%s\n' "$normalized"
}

detect_team_id() {
  local identities identity team
  identities="$(security find-identity -p codesigning -v 2>/dev/null || true)"
  while IFS= read -r identity; do
    [[ "$identity" == *"Apple Development:"* ]] || continue
    team="$(printf '%s\n' "$identity" | sed -nE 's/.*\(([A-Z0-9]{10})\).*/\1/p' | head -n1)"
    if [[ -n "$team" ]]; then
      printf '%s\n' "$team"
      return 0
    fi
  done <<< "$identities"
  return 1
}

while [[ "${1:-}" != "" ]]; do
  case "$1" in
    --identifier)
      IDENTIFIER="${2:-}"
      [[ -n "$IDENTIFIER" ]] || { echo "error: --identifier requires a value" >&2; exit 1; }
      shift 2
      ;;
    --team-id)
      TEAM_ID="${2:-}"
      [[ -n "$TEAM_ID" ]] || { echo "error: --team-id requires a value" >&2; exit 1; }
      shift 2
      ;;
    --skip-frameworks)
      DOWNLOAD_FRAMEWORKS=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$IDENTIFIER" ]]; then
  IDENTIFIER="$(sanitize_identifier "$(id -un)")"
else
  IDENTIFIER="$(sanitize_identifier "$IDENTIFIER")"
fi

if [[ -z "$TEAM_ID" ]]; then
  if ! TEAM_ID="$(detect_team_id)"; then
    echo "error: could not auto-detect an Apple Development team ID from the keychain" >&2
    echo "hint: add --team-id <TEAMID> after signing into Xcode with your Apple ID" >&2
    exit 1
  fi
fi

echo "==> Configuring local iOS identity"
echo "    identifier: $IDENTIFIER"
echo "    team id:    $TEAM_ID"

"$SWITCH_SCRIPT" --to your-identifier --identifier "$IDENTIFIER" --team-id "$TEAM_ID"

if [[ "$DOWNLOAD_FRAMEWORKS" -eq 1 ]]; then
  echo "==> Downloading iOS support frameworks"
  (cd "$REPO_DIR" && make ios-frameworks)
fi

cat <<EOF
==> Local iOS setup complete

Next steps:
  1. Open apps/ios/Litter.xcodeproj in Xcode if you need to refresh signing prompts.
  2. For a simulator build:
     CARGO_INCREMENTAL=0 RUSTFLAGS='-C debuginfo=0' make ios-sim-fast
  3. For a device build:
     CARGO_INCREMENTAL=0 RUSTFLAGS='-C debuginfo=0' make ios-device-fast
EOF
