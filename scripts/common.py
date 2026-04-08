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

# local filesystem paths
HOME_DIR = Path.home()
SCRIPT_DIR = HOME_DIR / ".local" / "bin"


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
                    lambda m: env.get(m.group(1), m.group(0)), result)
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


def get_relative_structure() -> tuple[list[Path], list[Path]]:
    dirs, files = get_dir_contents([REPO_CONF_DIR])

    rel_dirs = []
    rel_files = []

    for file in files:
        rel_files.append(file.relative_to(REPO_CONF_DIR))

    for directory in dirs:
        if directory.resolve() != REPO_CONF_DIR.resolve():
            rel_dirs.append(directory.relative_to(REPO_CONF_DIR))

    return rel_dirs, rel_files


def backup() -> None:
    rel_dirs, rel_files = get_relative_structure()
    copy_structure(HOME_DIR, REPO_BACKUP_DIR, rel_dirs, rel_files)


def write_config() -> None:
    rel_dirs, rel_files = get_relative_structure()
    copy_structure(REPO_CONF_DIR, HOME_DIR, rel_dirs, rel_files)


def make_scripts_executable() -> None:
    _, files = get_dir_contents([SCRIPT_DIR])
    for file in files:
        if file.suffix == ".py":
            python_script = Path(file)
            python_script.chmod(python_script.stat().st_mode | 0o111)


def restore_config() -> None:
    rel_dirs, rel_files = get_relative_structure()
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
