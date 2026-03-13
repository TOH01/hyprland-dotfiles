#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

backup_name="${1:-}"

if [[ -n "${backup_name}" ]]; then
    backup_dir="${BACKUP_ROOT}/${backup_name}"
else
    backup_dir="$(latest_backup_dir)"
fi

if [[ -z "${backup_dir:-}" || ! -d "${backup_dir}" ]]; then
    printf 'No backup found to restore.\n' >&2
    exit 1
fi

if [[ -t 0 ]]; then
    printf 'Restore backup %s into %s? [y/N] ' "${backup_dir}" "${HOME}"
    read -r reply
    if [[ ! "${reply}" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        printf 'Restore cancelled.\n'
        exit 0
    fi
fi

restored=0

while IFS= read -r relative_path; do
    source_file="${backup_dir}/${relative_path#./}"
    target_file="$(target_path_for_relative "${relative_path}")"

    mkdir -p "$(dirname -- "${target_file}")"
    cp -a "${source_file}" "${target_file}"
    restored=$((restored + 1))
done < <(
    cd "${backup_dir}"
    find . -type f | sort
)

printf 'Restored backup: %s\n' "${backup_dir}"
printf 'Restored files: %d\n' "${restored}"
