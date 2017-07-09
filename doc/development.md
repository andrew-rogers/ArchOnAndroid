ArchOnAndroid Development
=========================

Bootstrapping
-------------

Utilities required to install ArchLinux packages on Android:
* **wget** - downloads scripts and packages
* **busybox** - used to expand package archives and provides **grep**, **sed** and other required utilities

### wget

Get Android compatible **wget** from [GitHub](https://github.com/pelya/wget-android/blob/master/android/wget-armeabi)

**wget** will not work if the LD_LIBRARY_PATH variable is set. This variable needs to be set for ArchLinux binaries to work in ArchOnAndroid so that ArchLinux libraries can be located. A wrapper is used to unset LD_LIBRARY_PATH and invoke wget.

aoa-setup.sh only sets the LD_LIBRARY_PATH after the wrapper script is created in $UTILS_BIN/wget

The wget wrapper is a sh script that is automaticaly created during setup. A shebang is produced that points to the busybox sh ie. "#!/data/data/org.connectbot/ArchOnAndroid/utils/bin/busybox sh" when installed in connectbot.

Package Specific Modifications
------------------------------

### gcc

### make

If **make** is invoked without the modification the following error is produced:

```
make: /bin/sh: Command not found
```

The **make** command needs the SHELL variable set as it can't access /bin/sh an Android. A wrapper script is used to invoke **make** with the SHELL variable set to the busybox sh.