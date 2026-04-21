# Quickshell Master Design Document
**Target Environment:** Hyprland (Wayland)
**Core Objectives:** Maximum performance (minimal CPU, <100MB RAM), memory efficiency, visual consistency, and strict component modularity.

## 1. Standardized Architecture & Directory Hierarchy
To minimize side effects during reloads and promote modularity, the project must adhere to a strict directory structure. Keep system logic completely isolated from user-facing UI.

* **`shell.qml`**: The main entry point that wires core services and top-level windows/loaders. Keep it thin.
* **`assets/`**: Centralizes static resources like icons, SVG images, and custom GLSL shaders.
* **`components/`**: Reusable QML primitives (e.g., `StyledButton.qml`, elevation wrappers, sliders) to ensure uniform visual consistency.
* **`services/`**: The single source of truth for system data (e.g., Audio, NetworkManager, UPower) using a singleton pattern.
* **`modules/`**: High-level, isolated UI features (e.g., the Bar, Dock, Control Center). 
* **`config/`**: User-tunable runtime settings (e.g., `shell.json`), typed configuration accessors, and appearance tokens (themes/colors).

> **Crucial Import Rule:** Do **not** use relative paths (e.g., `import "../../foo.qml"`). This is deprecated in Quickshell v0.2+. Use root-relative syntax like `import qs.components`.

## 2. QML Coding Conventions & Idioms
To ensure bug-free QML that the Language Server (LSP) can parse cleanly, enforce the following rules:

* **Standardized Property Order:** All QML objects must declare attributes in this exact sequence:
    1.  `id`: (Must be first, always lowercase. Root of file should be `id: root`).
    2.  `required property`: Data that must be passed from the parent.
    3.  Custom Properties: Explicitly type them (e.g., `property int spacing`, never `var`).
    4.  Signal Declarations.
    5.  JavaScript Functions.
    6.  Object Properties (Overridden built-ins like `width` or `color`).
    7.  Anchors & Attached Objects (e.g., `Layout.fillWidth`).
    8.  Child Objects.
    9.  Signal Handlers (e.g., `onClicked`, always at the bottom).
* **Qualified Access Scoping:** Always explicitly use the component ID when accessing properties (e.g., `root.spacing` instead of an unqualified `spacing`). This prevents naming collisions and improves engine performance.
* **Lists and Scaling:** Use a `Repeater` with a `RowLayout`/`ColumnLayout` for short widget lists (tray icons). Strictly use `ListView` for long or scrollable content to ensure efficient memory recycling.

## 3. Performance & Resource Optimization
Unoptimized shells consume hundreds of megabytes of RAM; a well-engineered Quickshell config should use negligible CPU and under 100MB of RAM.

* **Abolish "Process-per-Widget":** Never spawn individual bash processes per widget. This causes a "thundering herd" effect. Centralize IPC monitoring using a single script (via `inotifywait`) or native singletons. 
* **Long-Running Commands:** For background scripts listening to IPC commands, use `SplitParser` to read datum streams as they arrive instead of waiting for the process to exit.
* **Smart Instancing (Variants):** When using `Variants` to duplicate windows across multiple monitors, **do not** place `Process` and `Timer` components directly inside the window component, or they will multiply. Move them out using `Scope` or make them a `Singleton`.
* **Lazy Loading:** Always use `Loader` (for Item components) or `LazyLoader` (for non-items) for conditional popups like calendars or app launchers. This unloads the widget trees, allowing garbage collection.
* **Staggered Initialization:** Use sleep delays in your Hyprland autostart config to stagger the launching of Quickshell, wallpaper daemons, and network applets to prevent login lag.
* **System Clock:** If a clock widget does not display seconds, set `SystemClock.precision` to `Minutes` to eliminate background polling.

## 4. Wayland Surface & Window Management
* **Window Types:** Use `PanelWindow` for Docks and Bars. Use `PopupWindow` or `FloatingWindow` for fly-out menus.
* **The Waybar Pattern:** Anchor the bar to the top, left, and right. Use `implicitHeight` so it adapts to widgets dynamically. Set `exclusiveZone` to match the bar's height so tiled windows do not overlap it.
* **The Dock Pattern & Centering Paradox:** Wayland loses exclusive zone tracking if a surface is anchored to two parallel edges without an explicit width. Anchor a bottom dock *only* to the bottom edge. Let its width be driven naturally by the `implicitWidth` of its internal layout to center it properly.
* **Hyprland Singleton:** Always use `Quickshell.Hyprland` for real-time IPC. Use `Hyprland.workspaces.values.find()` and `Hyprland.focusedWorkspace` instead of spanning scripts to poll `hyprctl`.

## 5. UI/UX, Theming & Bug Mitigation
* **Centralized Theming:** Never hardcode colors in components. Route all colors, radii, and fonts through your `config/` module globally.
* **Window Opacity:** If using a transparent background, explicitly set `QsWindow.surfaceFormat` to `opaque: false` so Quickshell properly requests a transparent Wayland surface.
* **The "Hole in My Window" Bug (QTBUG-137166):** If you give a `Rectangle` a transparent color but define a border radius, explicitly add `border.width: 0`, or everything beneath that rectangle will turn invisible.
* **Startup Misplacement:** To prevent `PanelWindow` elements from spawning in the top-left corner on the initial launch, define your anchors *before* any geometry properties (`width`/`height`).
* **Binding Loops:** Never use `Item.childrenRect` to determine a container's size. The golden rule is: **implicit size flows from children to parent; actual size flows from parent to children.**
* **Missing Asset Crashes:** Requesting missing assets can render purple/black fallback squares. Always provide a fallback path using `Quickshell.iconPath()` or use Quickshell's built-in `IconImage`.
