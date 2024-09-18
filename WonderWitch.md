# WonderWitch Documentation

## Basics

There are three screens in the WonderWitch UI.
The first one is where you start the games/applications.
The second is where you can copy files to/from program-area(ROM)/work-area(RAM)
The third is where you can transfer files & execute commands via serial.

## How to use

When you first startup WonderWitch there is a flash/sram test, then there is
a small intro animation. Press any button to get to the first screen.
Now press WS Y4 (NDS L+Left) to get to the third screen.
Now open the menu on the DS, go to Options->WonderWitch.
Here you can send files/commands to the WonderWitch.
The first thing you want to do is upload a file.

Press the "Upload File" button and exit the emulator menu to let the WonderWitch work,
then choose the file to upload.
Exiting the menu after every command is still needed, I will try to fix this later.

Many games require several files to run, "sound.il" is one such file used by some.
Many games also require a WSColor, so make sure you run the emulator in color mode.
If you want to do any actions on a specific file you have to do "Dir" first to
select the file and then run the command (delete, execute).
After you have deleted a file you have to run defreg to get back the space.
Sometimes things start to get really slow (almost allways if you run execute),
 then try a reboot command or reset the console.

If you want to keep what you have uploaded to the WonderWitch make sure you use the
Save NVRAM in the emulator.

* WonderWitch: Tools for interacting with a WonderWitch.
  * Storage: Select storage, apps need to be located in ROM.
  * Upload File: Used for uploading files to WonderWitch.
  * Dir: Show contents of a directory, to select a file.
  * Execute: Execute an app. (use the WW start screen instead).
  * Delete: Delete a file.
  * Defrag: Reclaim storage from deleted files.
  * Download File: Download a file from WW to the DS.
  * NewFS (Formatt): Wipe everything in the selected storage.
  * XMODEM Transmit: Used for uploading files to WonderWitch.
  * XMODEM Receive: Used for downloading files from WonderWitch.
  * Reboot WW: Reboot the WonderWitch software.
  * CD: Change directory.
  * Interact: Set terminal to interactive mode.
  * Stty: Set/Show interactive mode.
  * Hello: Show info about WW software.
  * Speed: Show communication speed.

## Credits

```text
Huge thanks to asie for info and inspiration.
```

Fredrik Ahlström

X/Twitter @TheRealFluBBa

<https://www.github.com/FluBBaOfWard>
