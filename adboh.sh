#!/bin/bash
# This script wraps up some simple adb processes so that you can call it a little easier when
# integrating android device calls via ADB.

# the location of the adb util
adb_bin=$(which adb)

#############
# Functions #
#############

function connect_adb {
    # Establish an ADB session
    $adb_bin connect $deviceip
    connected=1
    sleep 3
}

function disconnect_adb {
    # Disconnect the ADB session
    if [ -v connected ]; then
        $adb_bin disconnect $deviceip
    fi

}

function adb_reboot {
    # issue reboot
    $adb_bin shell reboot &
    connected=1
    sleep 3
}

function send_keyevent {
# send_keyevent <arg> (<arg> <arg>)
    for var in "$@"
	do
	    case "$var" in
		up)
		    var=19
		    shift 2;;
		down)
		    var=20
		    shift 2;;
		left)
		    var=21
		    shift 2;;
		right)
		    var=22
		    shift 2;;
		enter)
		    var=66
		    shift 2;;
		back)
		    var=4
		    shift 2;;
		home)
		    var=3
		    shift 2;;
		menu)
		    var=1
		    shift 2;;
		play)
		    var=85
		    shift 2;;
		pause)
		    var=85
		    shift 2;;
		previous)
		    var=88
		    shift 2;;
		next)
		    var=87
		    shift 2;;
		power)
		    var=26
		    shift 2;;
		settings)
		    longpress=1 
		    var=3
		    shift 2;;
		--)
		    # There are no final arguments left to process, end
		    shift
		    break;;
		esac
	if [ -v longpress ]; then
	    $adb_bin shell input keyevent --longpress "$var"
	    unset longpress
	else
	    $adb_bin shell input keyevent "$var"
	fi	
    done

}

function start_app {
# start_app <com.package.name/com.package.name.ActivityName>
    $adb_bin shell am start -n $package

}

function quick_state {
# send the device into another state, do not quote
# quick_state <state>
    case "$state" in
		wake)
		    send_keyevent KEYCODE_WAKEUP
		    shift 2;;
	    	sleep)
		    if $adb_bin shell dumpsys power | grep -q "Display Power: state=ON" ; then 
			send_keyevent KEYCODE_POWER
		    fi 
		    shift 2;;
		mirror)
		    send_keyevent settings right enter
		    shift 2;;
		settings)
		    send_keyevent settings right right enter
		    shift 2;;
		reboot)
		    adb_reboot
		    disconnect_adb
		    shift 2;;
		--)
		    # There are no final arguments left to process, end
		    shift
		    break;;
		esac

}


#######################
# Argument Processing #
#######################
# Execute getopt on the arguments passed to this program, identified by the special character $@
args=`getopt -n "$0" -o "d:ha:k:s:" --long "deviceip:,app:,keys:,state:" -- "$@"`

# Bad arguments, something has gone wrong with the getopt command.
if [ $? -ne 0 ];
then
  exit 1
fi

# Make sure whitespace is preserved
eval set -- "$args"

# Test all the options and perform whatever needs to be done
while true;
do
    case "$1" in

	-d|--deviceip)
	    if [ -n "$2" ]; then
		deviceip=$2
	    fi

	    connect_adb 
	    shift 2;;

	-k|--keys)
	    if [ -n "$2" ]; then
		keys=$2
	    fi

	    send_keyevent $keys
	    shift 2;;

	-s|--state)
	    if [ -n "$2" ]; then
		state=$2
	    fi

	    quick_state $state
	    shift 2;;


	-a|--app)
	    if [ -n "$2" ]; then
		package=$2
	    fi
	    start_app

	    shift 2;;

	-h|--help)
	    # Print help information
	    echo "Available options:"
	    echo "-d | --deviceip"
	    echo -e "\tThe IP Address for the device you are connecting to\n"
	    echo "-a | --app"
	    echo -e "\tApplication to start in com.package.name/com.package.name.Activity format\n"
	    echo "-k | --keys"
	    echo -e "\tKey events to send to device (enclose multiple in double quotes)\n"
	    echo "-s | --state"
	    echo -e "\tQuick State, currently supported options are;\n"
	    echo -e "\t\twake, sleep, reboot\n"
	    echo "-h | --help"
	    echo -n "\tDisplay this help menu\n"
	    exit
	    shift 2;;

	--)
	    # There are no final arguments left to process, end
	    shift
	    break;;
    esac
done

disconnect_adb
