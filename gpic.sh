#!/bin/sh

self=`basename $0`

case "$ACTION" in
    init)
#	echo ""
#	echo "$self: INIT"
	# exit 1 # non-null exit to make gphoto2 call fail
	;;
    start)
#	echo "$self: START"
	;;
    download)
	echo "$self: DOWNLOAD to $ARGUMENT"
	gpicview $ARGUMENT &
	;;
    stop)
	echo "$self: Session Completed"
	;;
    *)
	echo "$self: Unknown action: $ACTION"
	;;
esac

exit 0