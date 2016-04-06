Adbee
---------------------------------
This is an ADB wrapper script.  I made it with the intent of controlling my Amazon FireTV with my OpenHAB home automation setup.. it actually kinda became something that can be a bit more flexible in the future.

Here's a few things your probably wondering.
> **Whats it do**
> It is kinda straight forward actually.  You pass it a pretty simplified command and behind the scenes it takes that and calls an ADB shell command.  This obviously means you need to have ADB installed.

> **Why do I need it**
> Well .. you don't really.  But if your using some Home Automation software like OpenHAB and at this moment you have an Amazon FireTV, Echo, and OpenHAB setup then you can leverage it to do a few things like;
> 
 - Open apps if you know the package name and Activity you want to launch
 - Sleep and Wake the device
 - Turn on (only) Screen Mirroring
 - Send keyevents to emulate remote button presses

> **How are you using it**
> Its a bash shell script that runs on my raspberry pi that runs my Home Automation server [OpenHAB](http://www.openhab.org) along side of [ha-bridge](https://github.com/bwssytems/ha-bridge) which emulates a Phillips Hue Bridge.  I create items in OpenHAB and use the exec binding to execute my script the way I want it based on how I want that action to behave.  So like if I want to wake up my FireTV then I just set the exec binding to '/path/to/script/adbee.sh -d < ipaddress > -s wake' for the ON: action, and '< the same thing except > -s sleep' for the OFF: action.  Then just create the device in ha-bridge and setup your URL like you would and tell Alexa to "Discover Devices".  Once she sees the new devices if you played the home game correctly your action will kick off.

> **How can I use it**
> Basically the same way.  Just know its not perfect and I am not a developer.  While I would love to bake in a lot of things and make it better that is never a long term guarantee because I get bored easily and really made this to suit my needs but I feel like it should be made available for anyone looking for good bones to start from.  It will run on any Linux system as long as your using bash so you don't have to use a pi like me and really its just an adb script so it could be used for anything else you need to just achieve from a linux system to an android device.

> **Can you add X Feature**
I really can't guarantee anything but you could mark it as an issue or something here on github.  I honestly don't like maintaining anything I make - I like many of you get things "good enough" for me and then walk away from them, seasons change.  This is built pretty well though so I don't think you will be left high and dry and I expect this is going to become a pretty big piece of my Home Automation setup as I decide I need to do more with Android devices.

> **So, really, your not a developer whats doesn't work**
Glad you asked.  So the debug and maintain option actually require that they are the first two arguments, specifically if you want to use them it should be 'debug, then maintain' but in a perfect world you won't need them and honestly I advise against it just because its chatty and can create its own issues if your keeping sessions connected.  In fact right now there isn't anything in place to make sure your using the args in the right order so i'll add that in another section because thats important to know.

Its mostly implied but there are a few requirements.

>  1. Bash shell.
>  2. The android device your going to connect to has "USB Debugging" enabled.
>  3. ADB is already installed and located in your PATH
>  4. Whatever user your running the script as can execute ADB also.


Here are the order of operations

>  1. The device is connected to via ADB.
>  2. If the operation requires it its going to run a dumpsys on the device to get some state information.
>  3. The action should be run
>  4. The adb session is closed by default.  This is actually sort of important if you want to use multiple devices so unless you have good
> reason no need to use -m|--maintain

There is kind of a right way and wrong way to execute this since there is no syntax detection yet.

> Typically your going to execute something simple and honestly its preferred.  So something like this;
> adbee.sh -d < ipaddress > -s sleep
> or
> adbee.sh -d < ipaddress > -a com.netflix.ninja/com.netflix.ninja.MainActivity
> and even
> adbee.sh -d < ipaddress > --keys "left right enter"

>You could play around with chaining stuff but its a bit latent so thats why I made states so those things could be handled very specifically (thats the quick_states function).  You could make them as simple or as complex as you want and just call them with -s but were getting outside of the scope now.  Just know you could do that if you didn't want to write your own script and kinda create a macro of sorts.

Here is a list of those arguments.  Its way down here so you were forced to read the part above it all - I appreciate that you did.

> 
-d | --deviceip
The IP Address for the device you are connecting to


----------


>-a | --app
Application to start in com.package.name/com.package.name.Activity format.

>So for example, com.netflix.ninja/com.netflix.ninja.MainActivity

>I have tested this and it works but I didn't really have a practical purpose for this yet so it may need some tweaking to make it more useful and sane.

----------


>-k | --keys
Key events to send to device (enclose multiple in double quotes)

>IE: --keys "home left right enter"
This just calls the standard Android [keyevents](http://developer.android.com/reference/android/view/KeyEvent.html) so I guess any of them would work?  If you wanted to add some that your device needs if this doesn't you can currently just modify the send_keyevent function in the script for now.  If the button is one of those you need to hold down for a second or too (like the fireTVs home button for quick settings) just make sure you also provide it the longpress=1 variable, look at the "settings" keyevent for a better idea of what I am talking about.  I'll mention keymaps again later on, they don't exist yet but they will be something you can make yourself if you need to w/o having to muck with this.  I don't have a choice but to make this.


----------


>-s | --state
 Quick State, currently supported options are:
wake, sleep, reboot, mirror

>The first three are generic and would work for any device the last one though is where we start getting into some specific fireTV functionality.  For now use them but depending on how I go about keymaps this may get deprecated so I can support states in there too, though I imagine the first 3 since they are so generic will stick around this way.


----------


>-m | --maintain
Do not disconnect adb upon completion (default=disconnected)

>This will alter the default behavior of disconnecting.  There have been a few times where I wanted to use this when troubleshooting but thats it outside of that, kinda like debug if you don't need it don't use it because the default script logic is built around you disconnecting from the device.


----------


>-g | --debug
enable bash debugger (set -x & set -v)

>I thought I was so clever when I put this in.  Its helpful but its nothing more than enabling the bash debugger in the script so you can capture a log if you have some issues on a remote device.  I guess if problems arise it could be helpful to get this file from you if necessary.


----------


>-h | --help
Display the help menu

>its nothing like this but its good enough for mere mortals




