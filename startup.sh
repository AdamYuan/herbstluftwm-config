#!/bin/bash
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
xrdb -load .Xresources &
fcitx &
pkill wicd-client
wicd-client -t &
pkill xss-lock
xss-lock -- slimlock &
pkill indicator-keylo
indicator-keylock &
pkill volumeicon
volumeicon 

