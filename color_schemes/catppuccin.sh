#!/usr/bin/env bash

hex_channel_to_decimal() {
    printf '%d' "0x$1"
}

opacity_to_hex() {
    local opacity="$1"
    awk -v opacity="${opacity}" 'BEGIN {
        value = int((opacity * 255) + 0.5)
        printf "%02x", value
    }'
}

export THEME_NAME="catppuccin-mocha"

export THEME_ACTIVE_OPACITY="0.96"
export THEME_INACTIVE_OPACITY="0.94"
export THEME_WAYBAR_OPACITY="0.86"
export THEME_BG_HEX="#11111b"
export THEME_TERMINAL_BG_HEX="#0b0b12"
export THEME_SURFACE_HEX="#313244"
export THEME_SURFACE_ALT_HEX="#1e1e2e"
export THEME_TEXT_HEX="#cdd6f4"
export THEME_SUBTEXT_HEX="#a6adc8"
export THEME_ACCENT_HEX="#b4befe"
export THEME_ALERT_HEX="#f38ba8"
export THEME_BORDER_HEX="#b4befe"
export THEME_BORDER_SOFT_RGBA="rgba(180, 190, 254, 0.24)"
export THEME_HOVER_RGBA="rgba(180, 190, 254, 0.10)"
export THEME_SELECTED_FG_HEX="#11111b"

export THEME_HYPR_ACTIVE_BORDER_RGBA="b4befeee"
export THEME_HYPR_INACTIVE_BORDER_RGBA="6c7086aa"
export THEME_HYPR_SHADOW_RGBA="11111bee"

export THEME_DUNST_CRITICAL_FG_HEX="#cdd6f4"
export THEME_DUNST_CRITICAL_FRAME_HEX="#f38ba8"

bg_rgb="${THEME_BG_HEX#\#}"
bg_r="$(hex_channel_to_decimal "${bg_rgb:0:2}")"
bg_g="$(hex_channel_to_decimal "${bg_rgb:2:2}")"
bg_b="$(hex_channel_to_decimal "${bg_rgb:4:2}")"
active_alpha_hex="$(opacity_to_hex "${THEME_ACTIVE_OPACITY}")"
waybar_alpha_hex="$(opacity_to_hex "${THEME_WAYBAR_OPACITY}")"

export THEME_ACTIVE_SURFACE_HEX="${THEME_BG_HEX}${active_alpha_hex}"
export THEME_ACTIVE_SURFACE_RGBA="rgba(${bg_r}, ${bg_g}, ${bg_b}, ${THEME_ACTIVE_OPACITY})"
export THEME_WAYBAR_SURFACE_HEX="${THEME_BG_HEX}${waybar_alpha_hex}"
export THEME_WAYBAR_SURFACE_RGBA="rgba(${bg_r}, ${bg_g}, ${bg_b}, ${THEME_WAYBAR_OPACITY})"
export THEME_DUNST_CRITICAL_BG_HEX="${THEME_ACTIVE_SURFACE_HEX}"

export THEME_FASTFETCH_SWATCH_LINE='   \u001b[38;2;243;139;168m  \u001b[38;2;250;179;135m  \u001b[38;2;249;226;175m  \u001b[38;2;166;227;161m  \u001b[38;2;137;220;235m  \u001b[38;2;116;199;236m  \u001b[38;2;137;180;250m  \u001b[38;2;180;190;254m '

export THEME_COLOR0_HEX="#45475a"
export THEME_COLOR1_HEX="#f38ba8"
export THEME_COLOR2_HEX="#a6e3a1"
export THEME_COLOR3_HEX="#f9e2af"
export THEME_COLOR4_HEX="#89b4fa"
export THEME_COLOR5_HEX="#f5c2e7"
export THEME_COLOR6_HEX="#94e2d5"
export THEME_COLOR7_HEX="#bac2de"
export THEME_COLOR8_HEX="#585b70"
export THEME_COLOR9_HEX="#f38ba8"
export THEME_COLOR10_HEX="#a6e3a1"
export THEME_COLOR11_HEX="#f9e2af"
export THEME_COLOR12_HEX="#89b4fa"
export THEME_COLOR13_HEX="#f5c2e7"
export THEME_COLOR14_HEX="#94e2d5"
export THEME_COLOR15_HEX="#a6adc8"
