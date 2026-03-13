#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

backup_name="${1:-$(date +%Y%m%d-%H%M%S)}"
backup_dir="${BACKUP_ROOT}/${backup_name}"

if [[ -e "${backup_dir}" ]]; then
    printf 'Backup already exists: %s\n' "${backup_dir}" >&2
    exit 1
fi

mkdir -p "${backup_dir}"

backed_up=0
missing=0

while IFS= read -r relative_path; do
    target_file="$(target_path_for_relative "${relative_path}")"
    backup_file="${backup_dir}/${relative_path#./}"

    if [[ -f "${target_file}" ]]; then
        mkdir -p "$(dirname -- "${backup_file}")"
        cp -a "${target_file}" "${backup_file}"
        backed_up=$((backed_up + 1))
    else
        missing=$((missing + 1))
    fi
done < <(list_repo_config_files)

printf 'Created backup: %s\n' "${backup_dir}"
printf 'Backed up files: %d\n' "${backed_up}"
printf 'Missing target files: %d\n' "${missing}"
