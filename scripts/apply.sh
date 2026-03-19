#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

scheme_name="catppuccin"
auto_confirm=0
skip_backup=0

while (($# > 0)); do
    case "$1" in
        --scheme)
            shift
            scheme_name="${1:-}"
            ;;
        --scheme=*)
            scheme_name="${1#*=}"
            ;;
        --yes)
            auto_confirm=1
            ;;
        --skip-backup)
            skip_backup=1
            ;;
        -h|--help)
            cat <<'EOF'
Usage: ./scripts/apply.sh [--scheme NAME] [--yes] [--skip-backup]

Renders files from configs/ with a color scheme and copies them into $HOME.
EOF
            exit 0
            ;;
        *)
            printf 'Unknown argument: %s\n' "$1" >&2
            exit 1
            ;;
    esac
    shift || true
done

load_scheme "${scheme_name}"

if (( auto_confirm == 0 )); then
    if [[ ! -t 0 ]]; then
        printf 'apply.sh requires a TTY for confirmation, or use --yes.\n' >&2
        exit 1
    fi

    printf 'This will overwrite matching files in %s using the %s scheme.\n' "${HOME}" "${NAME:-${scheme_name}}"
    printf 'Create a backup first? [Y/n] '
    read -r backup_reply
    if [[ ! "${backup_reply:-}" =~ ^([nN][oO]?|[nN])$ ]]; then
        "${SCRIPT_DIR}/backup.sh" "pre-apply-$(date +%Y%m%d-%H%M%S)"
    else
        skip_backup=1
    fi

    printf 'Apply rendered configs now? [y/N] '
    read -r apply_reply
    if [[ ! "${apply_reply}" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        printf 'Apply cancelled.\n'
        exit 0
    fi
elif (( skip_backup == 0 )); then
    "${SCRIPT_DIR}/backup.sh" "pre-apply-$(date +%Y%m%d-%H%M%S)"
fi

render_dir="$(mktemp -d)"
trap 'rm -rf "${render_dir}"' EXIT

render_repo_to_dir "${scheme_name}" "${render_dir}"
copy_tree_preserving_layout "${render_dir}" "${HOME}"

if pgrep -x waybar > /dev/null 2>&1; then
    pkill -SIGUSR2 -x waybar
fi

if pgrep -x dunst > /dev/null 2>&1; then
    if command -v dunstctl > /dev/null 2>&1; then
        dunstctl reload > /dev/null 2>&1 || true
    else
        pkill -HUP -x dunst || true
    fi
fi

printf 'Applied %s to %s\n' "${NAME:-${scheme_name}}" "${HOME}"
