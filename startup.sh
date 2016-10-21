#!/bin/bash
#pkill compton
#compton --backend glx --vsync opengl-swc  &
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
fcitx &
nm-applet &
pkill xss-lock
xss-lock -- slimlock &
pkill indicator-keylo
indicator-keylock &
pkill volumeicon
volumeicon 
