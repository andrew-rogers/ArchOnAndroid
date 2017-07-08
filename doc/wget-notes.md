Get Android compatible wget from https://github.com/pelya/wget-android/blob/master/android/wget-armeabi

wget will not work if LD_LIBRARY_PATH is set. This variable needs to be set for ArchLinux binaries to work in ArchOnAndroid so that ArchLinux libraries can be located. A wrapper is used to unset LD_LIBRARY_PATH and invoke wget.

aoa-setup.sh only sets the LD_LIBRARY_PATH after the wrapper script is created in $UTILS_BIN/wget

The wget wrapper will need a working shebang line which needs to be either /bin/sh or /system/bin/sh for LSB or Android respectively. Alternatively use busybox sh ie "#!/data/data/org.connectbot/ArchOnAndroid/utils/bin/busybox sh"

