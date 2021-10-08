#!/bin/bash
#File name: rsync-inotify.sh
#File path: /etc/keepalived/rsync-inotify.sh

case "$1" in
  start )
    systemctl start rsync-inotity.service
    nerdctl rm -f registry
  ;;

  stop )
    systemctl stop rsync-inotity.service
  ;;

  restart )
    systemctl restart rsync-inotity.service
  ;;
  * )
    echo "Usage:$0 start|stop|restart"
  ;;

esac