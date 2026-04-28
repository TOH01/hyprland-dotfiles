# Quickshell Master Design Document
**Target Environment:** Hyprland (Wayland)
**Core Objectives:** Maximum performance (minimal CPU, <100MB RAM), memory efficiency, visual consistency, and strict component modularity.

## 1. Project Architecture & Directory Hierarchy
The codebase follows a strict modular structure to isolate system logic, UI components, and configuration.

*   **`shell.qml`**: The entry point. It instantiates the main windows (e.g., `Bar`) using `Variants` and handles global shortcuts. Keep logic minimal.
*   **`components/`** (`qs.components`): Reusable UI primitives. These ensure a unified look and feel.
*   **`config/`** (`qs.config`): Global singletons for `Theme`, `Icons`, and `Language`.
*   **`services/`** (`qs.services`): System-level logic and global state managers (e.g., `PopupManager`, `NetworkService`).
*   **`modules/`** (`qs.modules`): Large, self-contained UI features (e.g., `Bar`, `LaunchMenu`, `PowerMenu`).
*   **`assets/`**: Static resources.

### Import Conventions
Always use root-relative imports via the `qmldir` modules. Avoid relative paths like `../../`.
```qml
import qs.config
import qs.services
import qs.components as Ui
import qs.modules
```

## 2. Configuration & Theming
Never hardcode strings, colors, or icons. Use the centralized configuration singletons.

*   **`Theme.qml`**: Contains all colors, spacing, margins, and animation durations.
    *   *Usage:* `color: Theme.bg`, `width: Theme.s4`.
*   **`Icons.qml`**: Centralizes all Nerd Font icon strings.
    *   *Usage:* `text: Icons.power`.
*   **`Language.qml`**: All user-facing strings for easy localization.
    *   *Usage:* `text: Language.wifi`.

## 3. Centralized Widget & Popup Management
The shell uses a centralized system to manage popups and bar instances to prevent overlapping and ensure smooth interaction.

### PopupManager & PopupBase
All fly-out menus should inherit from `PopupBase.qml` and be opened via the `PopupManager`.
*   **`PopupBase`**: Handles positioning relative to a bar item, animations, and focus/dismissal logic.
*   **`PopupManager`**: A singleton that ensures only one popup is open at a time.
    *   *Opening a popup:* `PopupManager.open(myPopup, anchorItem)`
    *   *Closing:* `PopupManager.closeCurrent()`

### BarRegistry
Used to track active bar instances across monitors. This is critical for global focus management (e.g., `HyprlandFocusGrab`).

### Lazy Loading Pattern
To keep memory usage low, always use `LazyLoader` for heavy modules like menus.
```qml
LazyLoader {
    id: menuLoader
    component: MyMenu { 
        onVisibleChanged: if (!visible) menuLoader.active = false 
    }
}
```

## 4. Reusable UI Components (`qs.components`)
Leverage the following components to maintain consistency:

*   **`Ui.Label`**: Combines an icon and text.
*   **`Ui.Button`**: A standardized interactive button with hover/press states.
*   **`Ui.AppIcon`**: Safely resolves application icons with fallbacks.
*   **`Ui.ToggleRow`**: A standard layout for settings toggles.
*   **`Ui.Separator`**: Consistent dividers.

## 5. QML Coding Standards
To ensure performance and maintainability:

*   **Standardized Property Order:**
    1.  `id` (Always `root` for the root element).
    2.  `required property`
    3.  Custom properties (Always typed).
    4.  Signals & Functions.
    5.  Object properties (anchors, size, color).
    6.  Child objects.
    7.  Signal handlers (`onXxx`).
*   **Qualified Access:** Always use `root.property` to avoid scoping ambiguity.
*   **Transparent Rectangles:** When using `radius` on a transparent `Rectangle`, you **must** set `border.width: 0` to avoid rendering artifacts (QTBUG-137166).
*   **Implicit Sizes:** Layouts should rely on `implicitWidth`/`implicitHeight` to grow naturally.

## 6. Performance Guidelines
*   **Minimize CPU:** Use `SystemClock.precision: Minutes` if seconds aren't needed.
*   **Singletons for Logic:** Move heavy logic (e.g., DBus listeners) into singletons in `services/` rather than duplicating them in every bar instance.
*   **Process Management:** Use `Quickshell.Io.Process` for system commands and prefer long-running streams with `SplitParser` for efficiency.
