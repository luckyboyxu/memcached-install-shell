#! /bin/sh
#
# chkconfig: - 55 45
# description:	The memcached daemon is a network memory cache service.
# processname: memcached
# config: /etc/sysconfig/memcached
# pidfile: /var/run/memcached/memcached.pid

# Standard LSB functions
#. /lib/lsb/init-functions

# Source function library.
. /etc/init.d/functions

PORT=11211
USER=memcached
MAXCONN=1024
CACHESIZE=64
OPTIONS=""

if [ -f /etc/sysconfig/memcached ];then 
	. /etc/sysconfig/memcached
fi

# Check that networking is up.
. /etc/sysconfig/network

if [ "$NETWORKING" = "no" ]
then
	exit 0
fi

RETVAL=0
prog="memcached"
pidfile=${PIDFILE-/var/run/memcached/memcached.pid}
lockfile=${LOCKFILE-/var/lock/subsys/memcached}

start () {
	echo -n $"Starting $prog: "
	# Ensure that /var/run/memcached has proper permissions
	if [ "`stat -c %U /var/run/memcached`" != "$USER" ]; then
		chown $USER /var/run/memcached
	fi

	daemon --pidfile ${pidfile} memcached -d -p $PORT -u $USER  -m $CACHESIZE -c $MAXCONN -P ${pidfile} $OPTIONS
	RETVAL=$?
	echo
	[ $RETVAL -eq 0 ] && touch ${lockfile}
}
stop () {
	echo -n $"Stopping $prog: "
	killproc -p ${pidfile} /usr/bin/memcached
	RETVAL=$?
	echo
	if [ $RETVAL -eq 0 ] ; then
		rm -f ${lockfile} ${pidfile}
	fi
}

restart () {
        stop
        start
}


# See how we were called.
case "$1" in
  start)
	start
	;;
  stop)
	stop
	;;
  status)
	status -p ${pidfile} memcached
	RETVAL=$?
	;;
  restart|reload|force-reload)
	restart
	;;
  condrestart|try-restart)
	[ -f ${lockfile} ] && restart || :
	;;
  *)
	echo $"Usage: $0 {start|stop|status|restart|reload|force-reload|condrestart|try-restart}"
	RETVAL=2
        ;;
esac

exit $RETVAL
