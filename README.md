# deskswap
a shell script to cycle your current desktop view through a custom list of desktop folders, the way you'd alt+tab through windows. it changes the xdg desktop location under kde 6 plasma to another, existing folder. great to use if you have a lot of files on your desktop and need a way to sort through them.

main link: https://github.com/200found/deskswap

## dependencies: 
- freedesktop
- bash 4 or later
- mapfile
- kdialog (kde) or notify-send (linux mint xfce)
- optionally, python 3 or later and qt to use the gui history editor

## installing
after meeting the dependencies, move the script and gui script to a dedicated deskswap folder somewhere in your preferred config or documents path, and chmod 755 them to be executable.

on first run, the script will create a history file to cycle back and forth through. deskswap can add and remove directories from that history, but it's just a plain text file, so you can edit it by hand really easily. or use the python script gui i used microsoft chatbbb to make (i know bash but not python/qt).

## use
i created deskswap because i wanted a way to visibly keep my files in front of me at all times, and also minimize the amount of icons on my desktop. now, each of my projects gets a new folder, and i cycle through those desktops as i work.

there are a number of ways to use this script, and some of them will need to be tailored to your workflow and distro. here are some recommendations:

1. i recommend binding deskswap to a keyboard shortcut, such as "deskswap.sh next" and "deskswap.sh prev". this is incredibly useful and 99% of how i use deskswap.
2. creating a .desktop file in ~/.local/share/applications to the gui ("deskswap.sh gui") in your preferred start-ish menu.
3. provided your window manager supports it, creating a few right click services to switch the desktop to a new folder (which adds to the history). in kde plasma 6, see: ~/.local/share/kio/servicemenus. my exec. command looks like: /home/brad/scripts/deskswap/deskswap.sh switch "%f"
4. you can probably chain this script with virtual desktop utilities.
5. some distros have features that mimic this program, such as kde activities. take care using both.

let me know how it works for you and i'll add to this documentation.

## todo
- there might be an unquoted use of the path, but i can't find it
- support more window managers. i started this while using linux mint xfce and now much prefer kde.
- more robust checks for history and input (already done?)
- localize
- make icon, like a cat holding a file icon
- tbh maybe remove the history editing features from the script; the history file is trivially easy to edit by hand and the gui works well.

## notes
it's been like 20 years since i last did any serious programming, so there's a lot of good practices i didn't know of when i wrote this. compsci is no longer my career. if you would like to help modernize this, i would welcome input on the matter.
