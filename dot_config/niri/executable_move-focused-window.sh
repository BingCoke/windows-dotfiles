#!/bin/sh

if niri msg -j focused-window | jq -e '.is_floating' >/dev/null; then
    case "$1" in
        left)  niri msg action move-floating-window --x=-20 ;;
        right) niri msg action move-floating-window --x=+20 ;;
        up)    niri msg action move-floating-window --y=-20 ;;
        down)  niri msg action move-floating-window --y=+20 ;;
    esac
else
    case "$1" in
        left)  niri msg action move-column-left ;;
        right) niri msg action move-column-right ;;
        up)    niri msg action move-window-up ;;
        down)  niri msg action move-window-down ;;
    esac
fi
