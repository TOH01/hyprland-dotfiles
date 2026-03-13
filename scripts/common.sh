#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
CONFIG_ROOT="${REPO_ROOT}/configs"
BACKUP_ROOT="${REPO_ROOT}/backups"
COLOR_SCHEME_ROOT="${REPO_ROOT}/color_schemes"

list_repo_config_files() {
    (
        cd "${CONFIG_ROOT}"
        find . -type f | sort
    )
}

target_path_for_relative() {
    local relative_path="$1"
    relative_path="${relative_path#./}"
    printf '%s\n' "${HOME}/${relative_path}"
}

load_scheme() {
    local scheme_name="$1"
    local scheme_file="${COLOR_SCHEME_ROOT}/${scheme_name}.sh"

    if [[ ! -f "${scheme_file}" ]]; then
        printf 'Unknown color scheme: %s\n' "${scheme_name}" >&2
        return 1
    fi

    while IFS= read -r variable_name; do
        unset "${variable_name}"
    done < <(compgen -A variable THEME_ || true)

    # shellcheck source=/dev/null
    source "${scheme_file}"
}

render_file() {
    local source_file="$1"
    local destination_file="$2"
    local content variable_name placeholder replacement

    content="$(<"${source_file}")"

    while IFS= read -r variable_name; do
        placeholder="{{${variable_name}}}"
        replacement="${!variable_name}"
        content="${content//${placeholder}/${replacement}}"
    done < <(compgen -A variable THEME_ | sort || true)

    mkdir -p "$(dirname -- "${destination_file}")"
    printf '%s' "${content}" > "${destination_file}"
    chmod --reference="${source_file}" "${destination_file}"
}

render_repo_to_dir() {
    local scheme_name="$1"
    local output_dir="$2"
    local relative_path source_file destination_file

    load_scheme "${scheme_name}"

    while IFS= read -r relative_path; do
        source_file="${CONFIG_ROOT}/${relative_path#./}"
        destination_file="${output_dir}/${relative_path#./}"
        render_file "${source_file}" "${destination_file}"
    done < <(list_repo_config_files)
}

copy_tree_preserving_layout() {
    local source_root="$1"
    local destination_root="$2"
    local relative_path source_file destination_file

    while IFS= read -r relative_path; do
        source_file="${source_root}/${relative_path#./}"
        destination_file="${destination_root}/${relative_path#./}"
        mkdir -p "$(dirname -- "${destination_file}")"
        cp --preserve=mode,timestamps "${source_file}" "${destination_file}"
    done < <(
        cd "${source_root}"
        find . -type f | sort
    )
}

latest_backup_dir() {
    find "${BACKUP_ROOT}" -mindepth 1 -maxdepth 1 -type d | sort | tail -n 1
}
