framenum=`herbstclient attr tags.focus.frame_count`
windownum=`herbstclient attr tags.focus.client_count`
if [ $windownum = 0 ] && [ $framenum = 1 ] ; then
	herbstclient set frame_transparent_width 0
else
	herbstclient set frame_transparent_width `herbstclient get window_border_width`
fi	
