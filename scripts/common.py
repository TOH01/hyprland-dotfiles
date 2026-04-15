from pathlib import Path
import shutil
import re
import json
import subprocess

# repo paths
REPO_ROOT = Path(__file__).resolve().parent.parent
REPO_CONF_DIR = REPO_ROOT / "configs"
REPO_BACKUP_DIR = REPO_ROOT / "backup"
REPO_THEME_CONFIG = REPO_ROOT / "theme.json"
REPO_ENV_CONFIG = REPO_ROOT / "env.json"
REPO_DEPENDENCY_LIST = REPO_ROOT / "dependencies.json"
REPO_CSS_MASTER_THEME = REPO_ROOT / "theme.css"

# local filesystem paths
HOME_DIR = Path.home()
SCRIPT_DIR = HOME_DIR / ".local" / "bin"
CONFIG_DIR = HOME_DIR / ".config"


def get_dir_contents(paths: list[Path]) -> tuple[list[Path], list[Path]]:
    if not paths:
        return [], []

    current = Path(paths[0])
    rest = paths[1:]

    if current.is_dir():
        subpaths = sorted(current.iterdir())
        d, f = get_dir_contents(subpaths + rest)
        return [current] + d, f
    if current.is_file():
        d, f = get_dir_contents(rest)
        return d, [current] + f

    return [], []


def write_template_file(src: Path, dest: Path) -> None:
    if not REPO_THEME_CONFIG.exists():
        raise FileNotFoundError(f"Theme config not found: {REPO_THEME_CONFIG}")
    if not REPO_ENV_CONFIG.exists():
        raise FileNotFoundError(f"Environment config not found: {REPO_ENV_CONFIG}")
    
    theme = json.loads(REPO_THEME_CONFIG.read_text())
    env = json.loads(REPO_ENV_CONFIG.read_text())
    text = src.read_text()
    result = re.sub(r'\{\{(\w+)\}\}',
                    lambda m: theme.get(m.group(1), m.group(0)), text)
    result = re.sub(r'\{\{\$(\w+)\}\}',
        lambda m: (
            v if isinstance(v := env.get(m.group(1), m.group(0)), str)
            else json.dumps(v)
        ), result)
    dest.with_suffix("").write_text(result)


def copy_structure(base_src: Path, base_dest: Path,
                   dirs: list[Path], files: list[Path]) -> None:

    for directory in dirs:
        dest_dir = base_dest / directory
        dest_dir.mkdir(exist_ok=True)

    for file in files:
        src_file = base_src / file
        dest_file = base_dest / file

        if src_file.exists():
            if src_file.suffix == ".template":
                write_template_file(src_file, dest_file)
            else:
                shutil.copy2(src_file, dest_file)


def get_relative_structure(dir : Path) -> tuple[list[Path], list[Path]]:
    dirs, files = get_dir_contents([dir])

    rel_dirs = []
    rel_files = []

    for file in files:
        rel_files.append(file.relative_to(dir))

    for directory in dirs:
        if directory.resolve() != dir.resolve():
            rel_dirs.append(directory.relative_to(dir))

    return rel_dirs, rel_files


def backup() -> None:
    rel_dirs, rel_files = get_relative_structure(REPO_CONF_DIR)
    # filter .template as they are not present in home dir
    for i, f in enumerate(rel_files):
        if f.suffix == ".template":
            rel_files[i] = f.with_suffix('')
    copy_structure(HOME_DIR, REPO_BACKUP_DIR, rel_dirs, rel_files)


def write_config() -> None:
    rel_dirs, rel_files = get_relative_structure(REPO_CONF_DIR)
    copy_structure(REPO_CONF_DIR, HOME_DIR, rel_dirs, rel_files)


def make_scripts_executable() -> None:
    _, files = get_dir_contents([SCRIPT_DIR])
    for file in files:
        if file.suffix == ".py":
            python_script = Path(file)
            python_script.chmod(python_script.stat().st_mode | 0o111)


def restore_config() -> None:
    rel_dirs, rel_files = get_relative_structure(REPO_BACKUP_DIR)
    copy_structure(REPO_BACKUP_DIR, HOME_DIR, rel_dirs, rel_files)


def check_dependencies() -> tuple[list[str], list[str], list[str]]:
    missing = []
    version_mismatch = []
    fulfilled = []
    dependencies = json.loads(REPO_DEPENDENCY_LIST.read_text())

    for dependency, check in dependencies.items():
        try:
            res = subprocess.run([dependency, check["cmd"]], text=True,
                                 stdout=subprocess.PIPE)
            version = check.get("version")
            if version and check["version"] not in res.stdout:
                match = re.search(r'v?(\d+\.\d+(?:\.\d+)*)', res.stdout)
                found_version = "unknown"

                if match:
                    found_version = match.group(1)

                version_mismatch.append(f"Found dependency '{dependency}'"
                                        f" {found_version}, "
                                        f"expected {check["version"]}")
            else:
                fulfilled.append(f"Satisfied dependency '{dependency}'")
        except FileNotFoundError:
            missing.append(f"Missing dependency '{dependency}'")

    return (missing, version_mismatch, fulfilled)


def hex_to_rgb(hex_str):
    hex_str = hex_str.lstrip('#')
    return tuple(int(hex_str[i:i+2], 16) for i in (0, 2, 4))


def generate_color(r, g, b, alpha, fmt):
    if fmt == 'hex':
        # Output example: "#ffffff" (Standard 6-digit hex
        return f"#{r:02x}{g:02x}{b:02x}"
    elif fmt == 'rgba':
        # Output example: "rgba(255, 255, 255, 0.5)" (CSS RGBA format)
        return f"rgba({r}, {g}, {b}, {alpha})"
    elif fmt == 'hypr':
        # Output example: "ffffff80" (8-digit hex without #, used by Hyprland)
        alpha_int = round(float(alpha) * 255)
        return f"{r:02x}{g:02x}{b:02x}{alpha_int:02x}"
    elif fmt == 'hex_alpha':
        # Output example: "#ffffff80" (8-digit hex with # prefix)
        alpha_int = round(float(alpha) * 255)
        return f"#{r:02x}{g:02x}{b:02x}{alpha_int:02x}"
    return ""


def generate_theme():
    if not REPO_CSS_MASTER_THEME.exists():
        raise FileNotFoundError(f"Theme config not found: {REPO_CSS_MASTER_THEME}")
    
    with open(REPO_CSS_MASTER_THEME, 'r') as f:
        content = f.read()

    variables = {}
    var_matches = re.findall(r'--([\w-]+):\s*(#[0-9a-fA-F]+);', content)
    for name, hex_val in var_matches:
        variables[f"--{name}"] = hex_val

    theme_data = {}
    map_matches = re.findall(
        r'/\*\s*@map\s+(\w+):\s*'
        r'([^,\*]+?)\s*'
        r'(?:,\s*([^,\*]*?)\s*)?'
        r'(?:,\s*(\w+)\s*)?'
        r'\*/', content
    )

    for key, raw_val, alpha, fmt in map_matches:
        raw_val = raw_val.strip()
        alpha = alpha.strip() if alpha else ''
        fmt = fmt.strip() if fmt else ''

        if not raw_val.startswith('--'):
            theme_data[key] = raw_val
            continue

        if raw_val not in variables:
            raise ValueError(f"Warning: Variable {raw_val} not defined.")

        hex_val = variables[raw_val]
        r, g, b = hex_to_rgb(hex_val)
        alpha_val = float(alpha) if alpha else 1.0
        format_type = fmt if fmt else 'hex'
        theme_data[key] = generate_color(r, g, b, alpha_val, format_type)

    with open(REPO_THEME_CONFIG, 'w') as f:
        json.dump(theme_data, f, indent=2)
