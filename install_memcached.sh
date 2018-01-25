#!/bin/sh

_MEMCACHED_PORT=11211
_MEMCACHED_CACHESIZE=1024

if [ `whoami` != "root" ] ; then
        echo "You must run this script as root. Sorry!"
        exit 1
fi

read  -p "Please select the memcached port for this instance: [$_MEMCACHED_PORT] " MEMCACHED_PORT
if [ ! `echo $MEMCACHED_PORT | egrep "^[0-9]+\$"`  ] ; then
        echo "Selecting default: $_MEMCACHED_PORT"
        MEMCACHED_PORT=$_MEMCACHED_PORT
fi

read  -p "Please select the memcached cachesize for this instance: [$_MEMCACHED_CACHESIZE] " MEMCACHED_CACHESIZE
if [ ! `echo $MEMCACHED_CACHESIZE | egrep "^[0-9]+\$"`  ] ; then
        echo "Selecting default: $_MEMCACHED_CACHESIZE"
        MEMCACHED_CACHESIZE=$_MEMCACHED_CACHESIZE
fi

_MEMCACHED_MAXCONN=$MEMCACHED_CACHESIZE
read  -p "Please select the memcached MAXCONN for this instance: [$_MEMCACHED_MAXCONN] " MEMCACHED_MAXCONN
if [ ! `echo $MEMCACHED_MAXCONN | egrep "^[0-9]+\$"`  ] ; then
        echo "Selecting default: $_MEMCACHED_MAXCONN"
        MEMCACHED_MAXCONN=$_MEMCACHED_MAXCONN
fi

_MEMCACHED_EXECUTABLE=`which memcached`
read -p "Please select the memcached executable path [$_MEMCACHED_EXECUTABLE] " MEMCACHED_EXECUTABLE
if [ ! -f "$MEMCACHED_EXECUTABLE" ] ; then
        MEMCACHED_EXECUTABLE=$_MEMCACHED_EXECUTABLE

        if [ ! -f "$MEMCACHED_EXECUTABLE" ] ; then
                echo "Mmmmm...  it seems like you don't have a memcached executable. Did you run make install yet?"
                exit 1
        fi

fi

_MEMCACHED_PIDFILE="/var/run/memcached/memcached_$MEMCACHED_PORT.pid"
read -p "Please select the redis config file name [$_MEMCACHED_PIDFILE] " MEMCACHED_PIDFILE
if [ !"$MEMCACHED_PIDFILE" ] ; then
        MEMCACHED_PIDFILE=$_MEMCACHED_PIDFILE
        echo "Selected default - $MEMCACHED_PIDFILE"
fi

#try and create it
mkdir -p `dirname "$MEMCACHED_PIDFILE"` || die "Could not create memcached pid directory"

_MEMCACHED_LOCKFILE="/var/lock/subsys/memcached_$MEMCACHED_PORT"
read -p "Please select the redis config file name [$_MEMCACHED_LOCKFILE] " MEMCACHED_LOCKFILE
if [ !"$MEMCACHED_LOCKFILE" ] ; then
        MEMCACHED_LOCKFILE=$_MEMCACHED_LOCKFILE
        echo "Selected default - $MEMCACHED_LOCKFILE"
fi

#try and create it
mkdir -p `dirname "$MEMCACHED_LOCKFILE"` || die "Could not create memcached lockfile directory"

#render the tmplates
INIT_TPL_FILE="./memcached.tpl"
INIT_SCRIPT_DEST="/etc/init.d/memcached_$MEMCACHED_PORT"

if [ -f /etc/sysconfig/memcached ];then
        rm -f /etc/sysconfig/memcached
fi

if [ -s $INIT_SCRIPT_DEST ];then
    read -p "Found the file $INIT_SCRIPT_DEST exists. Overwrite? yes or no : " CHOOSE
    while [[ "x"$CHOOSE != "xyes" && "x"$CHOOSE != "xno" && "x"$CHOOSE != "xy" && "x"$CHOOSE != "xn" ]]
    do 
        read -p "Please input yes(y) or no(n)?" CHOOSE
    done
    case $CHOOSE in
        yes|y) 
               rm -f $INIT_SCRIPT_DEST
               ;;
        no|n)  
               echo "ByeBye"
               exit -1
               ;;
    esac
fi

SED_EXPR="s#^PORT=[0-9]{5}\$#PORT=${MEMCACHED_PORT}#;\
s#^MAXCONN=.+\$#MAXCONN=${MEMCACHED_MAXCONN}#;\
s#^CACHESIZE=.+\$#CACHESIZE=${MEMCACHED_CACHESIZE}#;\
s#^prog=.+\$#prog=memcached_${MEMCACHED_PORT}#;\
s#^pidfile=.+\$#pidfile=${MEMCACHED_PIDFILE}#;\
s#^lockfile=.+\$#lockfile=${MEMCACHED_LOCKFILE}#;"
sed -r "$SED_EXPR" $INIT_TPL_FILE  > $INIT_SCRIPT_DEST

chmod 755 $INIT_SCRIPT_DEST

$INIT_SCRIPT_DEST status > /dev/null
[ "X$?" = "X0" ] && $INIT_SCRIPT_DEST stop

$INIT_SCRIPT_DEST start
