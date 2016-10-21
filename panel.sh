#!/bin/bash -x

hc() { "${herbstclient_command[@]:-herbstclient}" "$@" ;}
monitor=${1:-0}
geometry=( $(herbstclient monitor_rect "$monitor") )
if [ -z "$geometry" ] ;then
    echo "Invalid monitor $monitor"
    exit 1
fi
# geometry has the format W H X Y
x=${geometry[0]}
y=${geometry[1]}
panel_width=${geometry[2]}
panel_height=$DZEN_HEIGHT
_font="Noto Sans S Chinese-medium-16"
font="Noto Sans S Chinese-medium-16"
bgcolor=$DZEN_BGCOLOR
selbg=$COLOR_THEME
selfg=$DZEN_BGCOLOR
icon_path="/home/"$USER"/.config/herbstluftwm/icon/"
####
# Try to find textwidth binary.
# In e.g. Ubuntu, this is named dzen2-textwidth.
if which textwidth &> /dev/null ; then
    textwidth="textwidth";
elif which dzen2-textwidth &> /dev/null ; then
    textwidth="dzen2-textwidth";
else
    echo "This script requires the textwidth tool of the dzen2 project."
    exit 1
fi
####
# true if we are using the svn version of dzen2
# depending on version/distribution, this seems to have version strings like
# "dzen-" or "dzen-x.x.x-svn"
if dzen2 -v 2>&1 | head -n 1 | grep -q '^dzen-\([^,]*-svn\|\),'; then
    dzen2_svn="true"
else
    dzen2_svn=""
fi

if awk -Wv 2>/dev/null | head -1 | grep -q '^mawk'; then
    # mawk needs "-W interactive" to line-buffer stdout correctly
    # http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=593504
    uniq_linebuffered() {
      awk -W interactive '$0 != l { print ; l=$0 ; fflush(); }' "$@"
    }
else
    # other awk versions (e.g. gawk) issue a warning with "-W interactive", so
    # we don't want to use it there.
    uniq_linebuffered() {
      awk '$0 != l { print ; l=$0 ; fflush(); }' "$@"
    }
fi

hc pad $monitor $panel_height

{
    ### Event generator ###
    # based on different input data (mpc, date, hlwm hooks, ...) this generates events, formed like this:
    #   <eventname>\t<data> [...]
    # e.g.
    #   date    ^fg(#efefef)18:33^fg(#909090), 2013-10-^fg(#efefef)29
	conky -c ~/.config/herbstluftwm/conky/statusbar | while read -r; do
        echo -e "conky $REPLY";
    done > >(uniq_linebuffered) &
    childpid=$!
    hc --idle
    kill $childpid
} 2> /dev/null | {
    IFS=$'\t' read -ra tags <<< "$(hc tag_status $monitor)"
    visible=true
	battery=""
	date_time=""
	windowtitle=""
	while true ; do
		
        ### Output ###
        # This part prints dzen data based on the _previous_ data handling run,
        # and then waits for the next event to happen.

        #separator="^bg()^fg(#FFFFFF)|"
        # draw tags
        for i in "${tags[@]}" ; do
            case ${i:0:1} in
                '#')
                    echo -n "^bg($selbg)^fg(#000000)"
                    ;;
                '+')
                    echo -n "^bg(#9CA668)^fg(#141414)"
                    ;;
                ':')
                    echo -n "^bg()^fg(#ffffff)"
                    ;;
                '!')
                    echo -n "^bg(#FF0675)^fg(#141414)"
                    ;;
                *)
					echo -n "^bg()^fg(#777777)"
                    ;;
            esac
			echo -n " ${i:1} "
        done
		echo -n "^bg()^fg(#FFFFFF)  $windowtitle"
		cpu=`echo $conky | cut -d "|" -f1 ` 
		mem=`echo $conky | cut -d "|" -f2 ` 
		battery=`echo $conky | cut -d "|" -f3 ` 
		date=`echo $conky | cut -d "|" -f4 `
		time=`echo $conky | cut -d "|" -f5 `
		date_long=`echo "$time"|wc -L`
		if [ $date_long = 4 ] ; then
			time=0$time
		fi
		echo -n "^bg($bgcolor)^pa($(($panel_width - 400)))                                                                                                                                                                                                                           "
		cpu_icon="cpu.xbm"
		echo -n "^fg(#FFFFFF)^pa($(($panel_width - 400)))^i($icon_path$cpu_icon) ^fg($selbg)$cpu"
		mem_icon="mem.xbm"
		echo -n "^fg(#FFFFFF)^pa($(($panel_width - 340)))^i($icon_path$mem_icon) ^fg($selbg)$mem"
		bat_icon="battery"$[battery/10 ]".xbm"
		echo -n "^fg(#FFFFFF)^pa($(($panel_width - 265)))^i($icon_path$bat_icon) ^fg($selbg)$battery%"
		cal_icon="calendar.xbm"
		echo -n "^fg(#FFFFFF)^pa($(($panel_width - 200)))^i($icon_path$cal_icon) ^fg($selbg)$date"
		clock_icon="clock.xbm"
		echo -n "^fg(#FFFFFF)^pa($(($panel_width - 55)))^i($icon_path$clock_icon) ^fg($selbg)$time"
		echo 
		read line || break
        cmd=( $line )
		case "${cmd[0]}" in
            tag*)
                IFS=$'\t' read -ra tags <<< "$(hc tag_status $monitor)"
				herbstclient spawn bash ~/.config/herbstluftwm/tag.sh
                ;;
            conky)
                conky="${cmd[@]:1}"
                ;;
            quit_panel)
                exit
                ;;
            togglehidepanel)
                currentmonidx=$(hc list_monitors | sed -n '/\[FOCUS\]$/s/:.*//p')
                if [ "${cmd[1]}" -ne "$monitor" ] ; then
                    continue
                fi
                if [ "${cmd[1]}" = "current" ] && [ "$currentmonidx" -ne "$monitor" ] ; then
                    continue
                fi
                echo "^togglehide()"
                if $visible ; then
                    visible=false
                    hc pad $monitor 0
                else
                    visible=true
                    hc pad $monitor $panel_height
                fi
                ;;
            reload)
                exit
                ;;
            focus_changed|window_title_changed)
                windowtitle=`herbstclient attr clients.focus.title`
                ;;
        esac
	done 

    ### dzen2 ###
    # After the data is gathered and processed, the output of the previous block
    # gets piped to dzen2.

} 2> /dev/null | dzen2 -w $panel_width -x $x -y $y -fn "$font" -h $panel_height \
    -e 'button3=' \
    -ta l -bg "$bgcolor" -fg '#ffffff'
