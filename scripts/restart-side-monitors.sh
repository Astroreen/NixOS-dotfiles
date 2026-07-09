#!/usr/bin/env bash
# Force-reapply side monitor mode/position/transform via hyprctl eval.
# Hyprland's Lua config provider does not support `hyprctl keyword` (it errors
# with "keyword can't work with non-legacy parsers. Use eval."), so this uses
# `hyprctl eval hl.monitor({...})` instead. Disabling then re-enabling forces
# Hyprland to actually reapply mode/transform to already-connected monitors,
# which a plain reload does not reliably do.
hyprctl eval 'hl.monitor({ output = "HDMI-A-1", disabled = true })'
hyprctl eval 'hl.monitor({ output = "DP-2", disabled = true })'
hyprctl eval 'hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@240", position = "-1080x-480", scale = "1", transform = 1, disabled = false })'
hyprctl eval 'hl.monitor({ output = "DP-2", mode = "1920x1080@60", position = "3440x-480", scale = "1", transform = 3, disabled = false })'
