#!/bin/sh

if niri msg -j focused-window | jq -e '.is_floating == true' >/dev/null; then
    case "$1" in
        left)  niri msg action set-window-width "-10%" ;;
        right) niri msg action set-window-width "+10%" ;;
        up)    niri msg action set-window-height "-10%" ;;
        down)  niri msg action set-window-height "+10%" ;;
        *)     exit 2 ;;
    esac
else
    case "$1" in
        left)  niri msg action set-column-width "-10%" ;;
        right) niri msg action set-column-width "+10%" ;;
        up)    niri msg action set-window-height "-10%" ;;
        down)  niri msg action set-window-height "+10%" ;;
        *)     exit 2 ;;
    esac
fi
