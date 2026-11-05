#!/usr/bin/env bash

# change the xdg desktop under kde 6 plasma to another, existing folder. supports a cyclable history and can be used with a virtual desktop switch.
# for usage notes, dependencies, etc, please see the included readme or: https://github.com/200found/deskswap/README.md


# FUNCTIONS

# notification function; currently supports kde and xfce
notify() {
    local title="$1"
    local message="$2"
    # kde
    if command -v kdialog >/dev/null 2>&1; then
        kdialog --title "$title" --passivepopup "$message" 3
        return
    fi
    # linux mint xfce
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -t 3000 "$title" "$message"
        return
    fi
    echo "$title $message"
}

update_history() {
    local skip=0
    if [ "$path" = "$XDG_DESKTOP_DIR" ]; then
        skip=1
    fi
    for item in "${history_array[@]}"; do
        if [ "$item" = "$path" ]; then
            skip=1
            break
        fi
    done
    if [ "$skip" = 0 ]; then
        printf "$path\n" >> "$history_file"
    fi
}


# INIT

mode="$1"
path="$2"
working_dir="$(dirname "$0")"
# load xdg user directory definitions
source "$HOME/.config/user-dirs.dirs"
eval XDG_DESKTOP_DIR="$XDG_DESKTOP_DIR"
history_file="$working_dir/deskswap.history"
history_array=()
# read history file or create a blank one
if [ -f "$history_file" ]; then
    mapfile -t history_array < "$history_file"
else
    printf "$XDG_DESKTOP_DIR\n" > "$history_file"
    mapfile -t history_array < "$history_file"
fi


# MODES

# no args; show docs
if [ -z "$mode" ]; then
    echo 'A program to switch XDG desktop folders on the fly, to make virtual desktops more useful. Can probably be adapted to other window managers.

Usage: deskswap.sh [mode] [[path]]

Commands:
switch /path/to/folder          Switches desktop to the new path and adds it to the history.

next|prev                       Cycle through the next or previous desktop in history.

default                         Switch to $HOME/Desktop

reset                           Reset the history and revert to $HOME/Desktop

remove /path/to/folder          Remove specified path from the history file. Case-sensitive.

gui                            Open the experimental GUI for editing the history file.
'
    exit 1
fi


# default values mode
if [ "$mode" = "default" ]; then
    xdg-user-dirs-update --set DESKTOP "$HOME/Desktop"
    echo "Deskswap: desktop folder is now set to: $HOME/Desktop."
    notify "Deskswap" "Desktop folder is now set to: $HOME/Desktop"
    exit 0
fi


# clear history mode
if [ "$mode" = "reset" ]; then
    printf "$XDG_DESKTOP_DIR\n" > "$history_file"
    xdg-user-dirs-update --set DESKTOP "$HOME/Desktop"
    echo "Deskswap: history cleared and desktop folder is now reset to: $HOME/Desktop."
    notify "Deskswap" "History cleared and desktop folder is now reset to: $HOME/Desktop"
    exit 0
fi


# launch history editor gui
if [ "$mode" = "gui" ]; then
    echo "Deskswap: launching history editor."
    python3 "$working_dir/deskswap-gui.py"
    exit 0
fi


# switch to specified directory
if [ "$mode" = "switch" ]; then

    # if the path is empty, break
    if [ -z "$path" ]; then
        echo "Deskswap: no path specified to switch to."
        exit 1
    fi

    # if the folder doesn't exist, break
    if [ ! -d "$path" ]; then
        echo "Deskswap: folder $path does not exist."
        notify "Deskswap" "Folder does not exist: $path"
        exit 1
    fi

    # if the path specified is already set to the current desktop folder, there's nothing to do
    if [ "$path" = "$XDG_DESKTOP_DIR" ]; then
        echo "Deskswap: path is already set to $path."
        exit 0
    fi

    # update xdg user dirs
    xdg-user-dirs-update --set DESKTOP "$path"
    echo "Deskswap: desktop is now: $path."
    notify "Deskswap" "Desktop is now: $path"
    update_history
    exit 0
fi


# if next then cycle next desktop
if [ "$mode" = "next" ]; then
    current="$XDG_DESKTOP_DIR"
    index=-1

    # find current index
    i=0
    for item in "${history_array[@]}"; do
        if [ "$item" = "$current" ]; then
            index=$i
            break
        fi
        i=$((i+1))
    done

    # if not found, default to first entry
    if [ "$index" -lt 0 ]; then
        index=0
    fi

    # compute next index (wrap around)
    next_index=$(( (index + 1) % ${#history_array[@]} ))
    next_dir="${history_array[$next_index]}"

    if [ ! -d "$next_dir" ]; then
        xdg-user-dirs-update --set DESKTOP "$XDG_DESKTOP_DIR"
        notify "Deskswap Error" "Folder does not exist: $next_dir\nDesktop is now: $XDG_DESKTOP_DIR"
    else
        xdg-user-dirs-update --set DESKTOP "$next_dir"
        notify "Deskswap" "Desktop is now: $next_dir"
    fi
    exit 0
fi


# if prev then cycle prev desktop
if [ "$mode" = "prev" ]; then
    current="$XDG_DESKTOP_DIR"
    index=-1

    # find current index
    i=0
    for item in "${history_array[@]}"; do
        if [ "$item" = "$current" ]; then
            index=$i
            break
        fi
        i=$((i+1))
    done

    # if not found, default to first entry
    if [ "$index" -lt 0 ]; then
        index=0
    fi

    # compute previous index (wrap around)
    prev_index=$(( (index - 1 + ${#history_array[@]}) % ${#history_array[@]} ))
    prev_dir="${history_array[$prev_index]}"

    if [ ! -d "$prev_dir" ]; then
        xdg-user-dirs-update --set DESKTOP "$XDG_DESKTOP_DIR"
        notify "Deskswap Failed" "Folder does not exist: $prev_dir\nDesktop is now: $XDG_DESKTOP_DIR"
    else
        xdg-user-dirs-update --set DESKTOP "$prev_dir"
        notify "Deskswap" "Desktop is now: $prev_dir"
    fi
    exit 0
fi


# remove the specified path from history
# assumes a valid history array
if [ "$mode" = "remove" ]; then
    if [ "$path" = "$XDG_DESKTOP_DIR" ]; then
        echo "Deskswap: will not remove current desktop folder from history."
        notify "Deskswap Error" "Will not remove current desktop folder from history."
        exit 1
    fi
    if [ "$path" = "$HOME/Desktop" ]; then
        echo "Deskswap: will not remove default desktop folder from history."
        notify "Deskswap Error" "Will not remove default desktop folder from history."
        exit 1
    fi
    if [ ! -d "$path" ]; then
        echo "Deskswap: cannot remove a folder from history that does not exist."
        notify "Deskswap Error" "Cannot remove a folder from history that does not exist."
        exit 1
    fi
    printf "" > "$history_file"
    for item in "${history_array[@]}"; do
        if [ "$item" != "$path" ]; then
            printf "$item\n" >> "$history_file"
        else
            echo "Deskswap history removed: $path."
            notify "Deskswap History Removed" "$path removed."
        fi
    done
    echo "Desktop history updated."
    exit 0
fi


# if no mode matched, break
echo "Deskswap: unknown mode '$mode'"
exit 1
