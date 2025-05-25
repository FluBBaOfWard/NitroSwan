# NitroSwan V0.7.2

<img align="right" width="220" src="./logo.png" alt="The WonderSwan logo" />

This is a Bandai WonderSwan (Color/Crystal) & Benesse PocketChallenge V2
 emulator for the Nintendo DS(i)/3DS.

## How to use

1. Create a folder named "nitroswan" in either the root of your flash card or
 in the data folder. This is where settings and save files end up.
2. Now put game/bios files into a folder where you have (WonderSwan) roms, max
 768 files per folder, filenames must not be longer than 127 chars. You can use
 zip-files (as long as they use the deflate compression). CAUTION! Games that
 require SLOT-2 RAM can not be used with zip-files!
3. Depending on your flashcart you might have to DLDI patch the emulator.

The save files should be compatible with most other WonderSwan emulators.

When the emulator starts, you can either press L+R or tap on the screen to open
 up the menu. Now you can use the cross or touchscreen to navigate the menus, A
 or double tap to select an option, B or the top of the screen to go back a
 step.

To select between the tabs use R & L or the touchscreen.

Hold Start while starting a game to enter the boot rom settings, the internal
 EEPROM is saved when saving settings.

Since the DS/DS Lite only has 4MB of RAM you will need a SLOT-2/GBA cart with
 RAM to play games larger than 2MB.

## Menu

### File

* Load Game: Select a game to load.
* Load State: Load a previously saved state of the currently running game.
* Save State: Save a state of the currently running game.
* Load NVRAM: Load non volatile ram (EEPROM/SRAM) for the currently running game.
* Save NVRAM: Save non volatile ram (EEPROM/SRAM) for the currently running game.
* Load Patch: Apply an IPS patch to the currectly loaded rom.
* Save Settings: Save the current settings (and internal EEPROM).
* Reset Game: Reset the currently running game.

### Options

* Controller:
  * Autofire: Select if you want autofire.
  * Swap A/B: Swap which NDS button is mapped to which WS button.
  * Alternate layout: See Controls.
* Display:
  * Gamma: Lets you change the gamma ("brightness").
  * Contrast: Lets you change the contrast.
  * B&W Palette: Here you can select the palette for B & W games.
  * Border: Choose what to show outside the WS screen.
* Machine:
  * Machine: Select the emulated machine.
  * Select WS Bios: Load a real WS Bios.
  * Select WS Color Bios: Load a real WS Color Bios.
  * Select WS Crystal Bios: Load a real WS Crystal Bios.
  * Import Internal EEPROM: Load a special internal EEPROM.
  * Clear Internal EEPROM: Reset internal EEPROM.
  * Headphones: Select whether heaphones are connected or not.
  * Cpu speed hacks: Allow speed hacks.
* Settings:
  * Speed: Switch between speed modes.
    * Normal: Game runs at its normal speed.
    * 200%: Game can run up to double speed.
    * Max: Games can run up to 4 times normal speed.
    * 50%: Game runs at half speed.
  * Allow Refresh Change: Allow the Wonderswan to change NDS refresh rate.
  * Autoload State: Toggle Savestate autoloading. Automagically load the savestate associated with the selected game.
  * Autoload NVRAM: Toggle EEPROM/SRAM autoloading. Automagically load the EEPROM/SRAM associated with the selected game.
  * Autosave Settings: This will save settings when leaving menu if any changes are made.
  * Autopause Game: Toggle if the game should pause when opening the menu.
  * Powersave 2nd Screen: If graphics/light should be turned off for the GUI screen when menu is not active.
  * Emulator on Bottom: Select if top or bottom screen should be used for emulator, when menu is active emulator screen is allways on top.
  * Autosleep: Doesn't work.
* WonderWitch: Tools for interacting with a WonderWitch.
  * See WonderWitch.md for more information.
* BootFriend: For uploading/downloading files with BootFriend.
* Debug:
  * Debug Output: Show FPS and logged text.
  * Disable Foreground: Turn on/off foreground rendering.
  * Disable Background: Turn on/off background rendering.
  * Disable Sprites: Turn on/off sprite rendering.
  * Disable Windows: Turn on/off window effects.
  * Step Frame: Emulate one frame.

### About

Some info about the emulator and game...

## Controls

### WonderSwan

```text
Start is mapped to WS Start.
Select is mapped to WS Sound.
In horizontal games the d-pad is mapped to WS X1-X4. A & B buttons are mapped to WS A & B.
Holding L or R maps the dpad to WS Y1-Y4.

In vertical games the d-pad is mapped to WS Y1-Y4. A, B, X & Y are mapped to WS X1-X4.

In alternate layout it is the same as normal horizontal, except L, R, X & Y are
mapped to WS Y1-Y4. To open the menu use L+Select.
```

### Pocket Challenge V2

```text
Dpad is mapped to up, down, left & right.
L is mapped to Escape.
R & X is mapped to Voice/View.
A is mapped to Clear.
B is mapped to Circle.
Y is mapped to Pass.
```

## Games

There are 3 games that I know of that has serious problems.

* Beatmania: Game is too large even for the DSi. Can be used with a 16MB SLOT-2 card or on 3DS.
* Chou Denki Card Game: You need to initialize NVRAM, this is the last item on the first page (初期化).
* Mahjong Touryuumon, emulated speed too fast.

There are a couple of games that have visual glitches.

* Dicing Knight. shadows are in front of player.
* Digimon - Anode Tamer & Cathode Tamer, missing background gradient in battles.
* Final Fantasy, sprites show in dialog windows.
* Final Lap 2000, incorrect road colors.
* Final Lap Special - GT & Formula Machine, incorrect road colors.
* From TV Animation One Piece - Grand Battle Swan Colosseum, incorrect sky color.
* Makaimura, first boss sprites are glitchy, gargoyles in intro should not show up on the right.
* Neon Genesis Evangelion - Shito Ikusei, sprites overlap avatar images.
* Rockman & Forte - Mirai Kara no Chousensha, no background fade in intro.
* Romancing Sa-Ga, sprites overlap text boxes.
* Sorobang, needs all 1024 tiles in 4color mode.
* WonderSwan Color BIOS, needs all 1024 tiles in 4color mode.

## Accuracy

I've made a few test programs for the WonderSwan to be able to really make sure
 it is as accurate as possible.

* [WSCPUTest](https://github.com/FluBBaOfWard/WSCpuTest) - Tests functions of the NEC V30MZ CPU instructions.
* [WSTimingTest](https://github.com/FluBBaOfWard/WSTimingTest) - Tests timing of the NEC V30MZ CPU instruction.
* [WSHWTest](https://github.com/FluBBaOfWard/WSHWTest) - Tests other HW of the WS SOC.

Other test programs I have used to get better accuracy.

* [WS-Test-Suite](https://github.com/asiekierka/ws-test-suite) - Lots of small tests.
* [RTC Test](https://forums.nesdev.org/viewtopic.php?t=21513) Test the RTC in certain cartridges.

## Credits

```text
Huge thanks to Loopy for the incredible PocketNES, without it this emu would probably never have been made.
Thanks to:
asie for info and inspiration. https://ws.nesdev.org/wiki/WSdev_Wiki
Ed Mandy (Flavor) for WonderSwan info & flashcart. https://www.flashmasta.com
Koyote for WonderSwan info.
Alex Marshall (trap15) for WonderSwan info. http://daifukkat.su/docs/wsman/
Guy Perfect for WonderSwan info http://perfectkiosk.net/stsws.html
Godzil for the boot rom stubs. https://github.com/Godzil/NewOswan
lidnariq for RTC info.
plasturion for some BnW palettes.
Dwedit for help and inspiration with a lot of things. https://www.dwedit.org
```

Fredrik Ahlström

<https://bsky.app/profile/therealflubba.bsky.social>

<https://www.github.com/FluBBaOfWard>

X/Twitter @TheRealFluBBa
