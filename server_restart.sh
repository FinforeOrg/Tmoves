#! /bin/sh
### BEGIN INIT INFO
# Provides:		server_restart.sh
# Required-Start:	$syslog
# Required-Stop:	$syslog
# Should-Start:		$local_fs
# Should-Stop:		$local_fs
# Default-Start:	2 3 4 5
# Default-Stop:		0 1 6
# Short-Description:    Tmoves Requirement Server
# Description:		Tmoves Requirement Server Start and Stop
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/home/yacobus/.rbenv/shims/:/home/yacobus/.rbenv/versions/1.9.3-p194/bin:$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH
set -e

case "$1" in
  start)
         source /data/tmoves/start_tmoves.txt
         /opt/nginx/sbin/nginx
         su yacobus
         cd /home/Tmoves/yacobus
         source start_sidekiq.txt 
         ;;
  stop)
         echo -n "Do Nothing"
         ;;
  restart|force-reload)
         ${0} stop
         ${0} start
         ;;
  *)
	exit 1
	;;
esac

exit 0
