Here is a comprehensive design document tailored for LLMs. It focuses on building a highly performant, consistent, and professional Quickshell configuration specifically for Hyprland, drawing directly from established best practices and official documentation.

***

# Quickshell Architecture & Design Document
**Target Environment:** Hyprland (Wayland)
**Target Modules:** Custom Bar (Waybar alternative), Popup Menu (Control Center/Dashboard), and Dock.
**Core Objectives:** Maximum performance, memory efficiency, visual consistency, and a professional OS feel.

## 1. Project Layout & Architecture
To ensure clean component boundaries and maintainability across modules, the project must follow a strict directory separation strategy:
*   **`shell.qml`**: The main entry point that wires core services and top-level windows/loaders.
*   **`components/`**: Reusable UI primitives (e.g., standardized buttons, sliders, elevation wrappers, effects) to ensure uniform visual consistency.
*   **`modules/`**: Product-level UI areas, specifically the Bar, Dock, and Popup Menu.
*   **`services/`**: System integrations and data providers (e.g., Audio, Network, Bluetooth, Hyprland IPC). Separating this keeps UI concerns isolated from system logic.
*   **`config/`**: Typed QML configuration accessors and appearance tokens (themes, colors).

**Import Syntax Constraint:** Do **not** use relative paths (e.g., `import "../../foo.qml"`) for QML imports, as this is deprecated in Quickshell v0.2+. All QML modules must be imported using root-relative syntax like `import qs.components` or `import qs.modules.common`.

## 2. Performance & Resource Optimization
Performance is critical. Implement the following best practices to keep CPU and memory overhead to an absolute minimum:
*   **Avoid Process-per-Widget:** Never use a process per widget, as this consumes significantly more memory. 
*   **Scope and Singletons:** When using `Variants` to create multiple window instances (e.g., a bar on every monitor), do not place `Process` and `Timer` components directly inside the window component. Doing so spawns redundant background processes. Move them out using `Scope` or make them a `Singleton`.
*   **Consolidated IPC Watchers:** Replace multiple shell processes/watchers with a single, consolidated IPC watcher. Using multiple tight polling loops for sockets can cause unnecessary 3-4% idle CPU usage.
*   **Lazy Loading:** Do not load the entire UI (like the Popup menu) at startup. Use `Loader` for components inheriting from `Item`, or `LazyLoader` for non-items, to construct UI trees only when requested and destroy them when hidden to heavily reduce memory usage.
*   **Staggered Initialization:** Spread out the load during autostart. Delay the loading of non-critical components (like update checkers or weather) by a few seconds to avoid temporary system overload and login lag.
*   **System Clock:** If a clock widget does not display seconds, set `SystemClock.precision` to `Minutes` to reduce the amount of work Quickshell does in the background.

## 3. Hyprland Integration & Window Management
*   **Window Types:** Use `PanelWindow` for the Bar and Dock. This Wayland-specific window type successfully docks to screen edges and reserves screen space so standard Hyprland windows don't overlap it. For the Popup Menu, use `PopupWindow` or a standard `FloatingWindow`.
*   **Multi-Monitor Support (Variants):** To ensure the Bar and Dock do not disappear when monitors are connected/disconnected, wrap them in a `Variants` component with Quickshell's monitor list acting as the data model. 
*   **Live Workspaces:** Utilize the `Quickshell.Hyprland` library for real-time IPC. Use `Hyprland.workspaces.values.find()` and `Hyprland.focusedWorkspace` to track and interact with active, inactive, and empty workspaces instantly.

## 4. UI/UX, Theming & Visual Consistency
To achieve a professional OS aesthetic, enforce the following visual paradigms:
*   **Centralized Theming:** Do not hardcode colors in individual components. Define theme properties globally (e.g., `root.colBg`) or load dynamic palettes dynamically (like JSON colors from `pywal`) and pass them through the `config/` module.
*   **Window Rounding & Opacity:** To make rounded windows, create a transparent, square window containing a rounded rectangle. 
*   **Critical Rendering Fixes:** 
    *   If using transparent background colors inside a window, explicitly set `QsWindow.surfaceFormat` to `opaque: false` so Quickshell properly requests a transparent surface.
    *   Avoid the "hole in my window" Qt bug (QTBUG-137166). If you define a `Rectangle` color as "transparent" and touch its `border` properties (such as radius), add `border.width: 0` to prevent everything under it from turning invisible.
*   **Icons & Images:** Round images using the `ClippingWrapperRectangle` component. When resolving icons, configure `Quickshell.iconPath()` to utilize fallback strings or empty strings to prevent broken purple/black fallback squares from rendering. Drop-shadows for standard UI elements should be applied using `RectangularShadow`.

## 5. QML Best Practices for the LLM
*   **Reactivity:** Rely fully on QML's reactive property bindings rather than manual updates. 
*   **Long-Running Commands:** For background scripts listening to IPC commands, use `SplitParser` to read each datum stream as it arrives instead of waiting for the process to exit.
*   **Lists and Scaling:** Use a `Repeater` combined with `RowLayout`/`ColumnLayout` for short widget lists (like workspaces or tray icons). For long or scrollable content (e.g., an app launcher in the Popup menu), strictly use `ListView`.

***