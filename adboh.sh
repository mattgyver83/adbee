# This script wraps up some simple adb processes so that you can call it a little easier when
# integrating android device calls via ADB.

# the location of the adb util
adb_bin="/opt/android-sdk-linux/platform-tools/adb"

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

function send_keyevent {
# send_keyevent <arg> (<arg> <arg>)
    for var in "$@"
        do $adb_bin shell input keyevent "$var"
    done

}

function start_app {
# start_app <com.package.name/com.package.name.ActivityName>
    $adb_bin shell am start -n $package

}

function wake_device {
    # Wake a sleeping device
    send_keyevent 26

}


#######################
# Argument Processing #
#######################
# Execute getopt on the arguments passed to this program, identified by the special character $@
args=`getopt -n "$0" -o "d:ha:k:" --long "deviceip:,app:,keys:" -- "$@"`

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
