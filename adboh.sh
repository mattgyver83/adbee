# This script wraps up some simple adb processes so that you can call it a little easier when
# integrating android device calls via ADB.

# the location of the adb util
adb_bin="/opt/android-sdk-linux/platform-tools/adb"
# ip address of the device to use (override with -d)
deviceip="10.220.29.213"

#############
# Functions #
#############

function connect_adb {
    # Establish an ADB session
    $adb_bin connect $deviceip
    sleep 3
}

function disconnect_adb {
    # Disconnect the ADB session
    $adb_bin disconnect $deviceip

}

function send_keyevent {
# send_keyevent <arg> (<arg> <arg>)
    for var in "$@"
        do $adb_bin shell input keyevent "$var"
    done

}

function wake_device {
    # Wake a sleeping device
    send_keyevent 26

}


#######################
# Argument Processing #
#######################
# Execute getopt on the arguments passed to this program, identified by the special character $@
args=`getopt -n "$0" -o "vd:h" --long "deviceip:" -- "$@"`

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

	    shift 2;;

	-k|--key)
	    if [ -n "$2" ]; then
		key=$2
	    fi

	    shift 2;;


	-p|--program)
	    if [ -n "$2" ]; then
		program=$2
	    fi
	    echo "-d, --deviceip"

	    shift 2;;

	-h|--help)
	    # Print help information
	    echo "Available options:"
	   
	    echo "-h | --help"
	    echo -n "\tDisplay this help menu"
	    exit
	    shift 2;;

	--)
	    # There are no final arguments left to process, end
	    shift
	    break;;
    esac
done


########
# Main #
########

connect_adb
send_keyevent 26
disconnect_adb
