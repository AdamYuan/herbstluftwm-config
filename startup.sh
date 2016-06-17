#!/bin/bash
pkill compton
compton --backend glx --vsync opengl-swc  &
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
fcitx &
nm-applet &
pkill xss-lock
xss-lock -- slimlock &
pkill indicator-keylo
indicator-keylock &
pkill volumeicon
volumeicon 

pkill trayer
source ~/.config/init/vars
run=""
while [ -z "$run" ]; do
	sleep 0.5
	run=$(ps -e | grep dzen)
	echo "$run"
done
trayer --edge top --align right --widthtype request --height $DZEN_HEIGHT --transparent true --alpha 1 --tint 0x`echo $DZEN_BGCOLOR|tail -c 7` --margin 100 &
