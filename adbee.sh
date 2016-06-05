#!/bin/bash
# This script wraps up some simple adb processes so that you can call it a little easier when
# integrating android device calls via ADB.

# the location of the adb util
source /etc/profile
adb_bin=$(which adb)
sniffer_bin=/opt/ha-bridge/bridge-sniffer/bridge-sniffer.sh

# debug log file location (default adb dir)
logfile=/var/log/openhab/adbee/debug.log

#############
# Functions #
#############

function enable_debug {
    set -x
    set -v
    exec > >(tee -a $logfile)
    exec 2> >(tee -a $logfile >&2)
    echo "DEBUG: log will be stored in $logfile"

}

function connect_adb {
    # Establish an ADB session and get the emulator name
    $adb_bin connect $deviceip
    connected=1
    sleep 3
    adb_id=$($adb_bin devices | grep -w $deviceip | grep -w "device" | awk '{print $1}')
    adb_bin="$adb_bin -s $adb_id"

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
		    var=KEYCODE_DPAD_UP
		    shift 2;;
		down)
		    var=KEYCODE_DPAD_DOWN
		    shift 2;;
		left)
		    var=KEYCODE_DPAD_LEFT
		    shift 2;;
		right)
		    var=KEYCODE_DPAD_RIGHT
		    shift 2;;
		enter)
		    var=KEYCODE_ENTER
		    shift 2;;
		back)
		    var=KEYCODE_BACK
		    shift 2;;
		home)
		    var=KEYCODE_HOME
		    shift 2;;
		play)
		    var=KEYCODE_MEDIA_PLAY_PAUSE
		    shift 2;;
		pause)
		    var=KEYCODE_MEDIA_PLAY_PAUSE
		    shift 2;;
		previous)
		    var=KEYCODE_MEDIA_PREVIOUS
		    shift 2;;
		next)
		    var=KEYCODE_MEDIA_NEXT
		    shift 2;;
		power)
		    var=KEYCODE_POWER
		    shift 2;;
		settings)
		    longpress=1 
		    var=KEYCODE_HOME
		    shift 2;;
		--)
		    # There are no final arguments left to process, end
		    shift
		    break;;
		esac
	if [ -v longpress ]; then
	    $adb_bin shell input keyevent --longpress "$var"
	    sleep 1
	    unset longpress
	else
	    $adb_bin shell input keyevent "$var"
	fi	
    done

}

function start_app {
# start_app <com.package.name>
    send_keyevent KEYCODE_WAKEUP
    packageIntent=$($adb_bin shell pm dump $package | grep -A 1 "MAIN" | grep $package | awk '{print $2}' | grep $package) 
    $adb_bin shell am start -n ${packageIntent::-1}

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
		    if $adb_bin shell dumpsys power | grep -q "Display Power: state=OFF" ; then 
			send_keyevent KEYCODE_WAKEUP
		    fi 
		    send_keyevent settings right right enter
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
args=`getopt -n "$0" -o "d:phga:k:s:" --long "deviceip:,app:,keys:,state:,ha:,debug,preserve,help" -- "$@"`

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

	--ha)
	    if [ -n "$2" ]; then
	         deviceip=$($sniffer_bin -n "$2")
	    fi

	    echo "Bridge Sniffer: detected $deviceip as the request initiators closest neighbor"

	    connect_adb 
	    shift 2;;

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

	-g|--debug)
	    enable_debug 
	    
	    shift 1;;

        -p|--preserve)
            connected=1 
	    preserve=1
         
            shift 1;;

	-h|--help)
	    # Print help information
	    echo "Available options:"
	    echo "-d | --deviceip"
	    echo -e "\tThe IP Address for the device you are connecting to\n"
	    echo "--ha"
	    echo -e "\tDetermine the IP address of the system from your HA via bridge-sniffer (beta)\n"
	    echo "-a | --app"
	    echo -e "\tApplication to start in com.package.name format\n"
	    echo "-k | --keys"
	    echo -e "\tKey events to send to device (enclose multiple in double quotes)\n"
	    echo "-s | --state"
	    echo -e "\tQuick State, currently supported options are;\n"
	    echo -e "\t\twake, sleep, reboot\n"
	    echo "-p | --preserve"
	    echo -e "\tDo not disconnect adb after execution\n"
	    echo "-g | --debug"
	    echo -e "\tEnable bash debugger (-xv)\n"
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

if [ ! -v preserve ]; then
    disconnect_adb
fi
