# NitroSwan V0.6.1

<img align="right" width="220" src="./logo.png" />

This is a Bandai WonderSwan (Color/Crystal) & PocketChallenge V2 emulator for the Nintendo DS.

## How to use

1. Create a folder named "nitroswan" in either the root of your flash card or in the data folder.
This is where settings and save files end up.
2. Now put game/bios files into a folder where you have (WonderSwan) roms.
3. Depending on your flashcart you might have to DLDI patch the emulator.

The save files should be compatible with most other WonderSwan emulators.

When the emulator starts, you can either press L+R or tap on the screen to open
up the menu.
Now you can use the cross or touchscreen to navigate the menus, A or double tap
to select an option, B or the top of the screen to go back a step.

To select between the tabs use R & L or the touchscreen.

Hold Start while starting a game to enter the boot rom settings, the internal EEPROM is saved when saving settings.

## Menu

### File

* Load Game: Select a game to load.
* Load State: Load a previously saved state of the currently running game.
* Save State: Save a state of the currently running game.
* Load NVRAM: Load non volatile ram (EEPROM/SRAM) for the currently running game.
* Save NVRAM: Save non volatile ram (EEPROM/SRAM) for the currently running game.
* Save Settings: Save the current settings (and internal EEPROM).
* Reset Game: Reset the currently running game.

### Options

* Controller:
  * Autofire: Select if you want autofire.
  * Controller: 2P start a 2 player game.
  * Swap A/B: Swap which NDS button is mapped to which WS button.

* Display:
  * Gamma: Lets you change the gamma ("brightness").
  * Contrast: Lets you change the contrast.
  * B&W Palette: Here you can select the palette for B & W games.
* Machine Settings:
  * Machine: Select the emulated machine.
  * Select WS Bios: Load a real WS Bios.
  * Select WS Color Bios: Load a real WS Color Bios.
  * Select WS Crystal Bios: Load a real WS Crystal Bios.
  * Import Internal EEPROM: Load a special internal EEPROM.
  * Clear Internal EEPROM: Reset internal EEPROM.
  * Cpu speed hacks: Allow speed hacks.
* Settings:
  * Speed: Switch between speed modes.
    * Normal: Game runs at it's normal speed.
    * 200%: Game runs at double speed.
    * Max: Games can run up to 4 times normal speed (might change).
    * 50%: Game runs at half speed.
  * Allow Refresh Change: Allow the Wonderswan to change NDS refresh rate.
  * Autoload State: Toggle Savestate autoloading. Automagically load the savestate associated with the selected game.
  * Autoload NVRAM: Toggle EEPROM/SRAM autoloading. Automagically load the EEPROM/SRAM associated with the selected game.
  * Autosave Settings: This will save settings when leaving menu if any changes are made.
  * Autopause Game: Toggle if the game should pause when opening the menu.
  * Powersave 2nd Screen: If graphics/light should be turned off for the GUI screen when menu is not active.
  * Emulator on Bottom: Select if top or bottom screen should be used for emulator, when menu is active emulator screen is allways on top.
  * Autosleep: Doesn't work.
* Debug:
  * Debug Output: Show FPS and logged text.
  * Disable Foreground: Turn on/off foreground rendering.
  * Disable Background: Turn on/off background rendering.
  * Disable Sprites: Turn on/off sprite rendering.
  * Step Frame: Emulate one frame.

### About

Some info about the emulator and game...

## Controls

```text
Start is mapped to WS Start.
Select is mapped to WS Sound.
In horizontal games the d-pad is mapped to WS X1-X4. A & B buttons are mapped to WS A & B.
Holding L maps the dpad to WS Y1-Y4.

In vertical games the d-pad is mapped to WS Y1-Y4. A, B, X & Y are mapped to WS X1-X4.

For Pocket Challenge V2:
Dpad is mapped to up, down, left & right.
L is mapped to Escape.
R & X is mapped to View.
A is mapped to Clear.
B is mapped to Circle.
Y is mapped to Pass.
```

## Games

There are 3 games that I know of that has serious problems.

* Beatmania: Game is too large even for the DSi.
* Chou Denki Card Game: You need to initialize NVRAM, this is the last item on the first page (初期化).
* Mahjong Touryuumon, speed too fast.

There are a couple of games that have visual glitches.

* Digimon - Anode Tamer & Cathode Tamer, missing background gradient in battles.
* Final Fantasy, Sprites show in dialog windows.
* Final Lap 2000, incorrect road colors.
* Final Lap Special - GT & Formula Machine, incorrect road colors.
* From TV Animation One Piece - Grand Battle Swan Colosseum, incorrect sky color.
* Makaimura, first boss sprites are glitchy, gargoyles in intro should not show up on the right.
* Rockman & Forte - Mirai Kara no Chousensha, no background fade in intro.
* Romancing Sa-Ga, sprites overlap text boxes.
* Sorobang, needs all 1024 tiles in 4color mode.
* WonderSwanColor BIOS, needs all 1024 tiles in 4color mode.

## Credits

```text
Huge thanks to Loopy for the incredible PocketNES, without it this emu would probably never have been made.
Thanks to:
Ed Mandy (Flavor) for WonderSwan info & flashcart. https://www.flashmasta.com
Koyote for WonderSwan info.
Alex Marshall (trap15) for WonderSwan info. http://daifukkat.su/docs/wsman/
Guy Perfect for WonderSwan info http://perfectkiosk.net/stsws.html
asie for info and inspiration.
Godzil for the boot rom stubs. https://github.com/Godzil/NewOswan
lidnariq for RTC info.
plasturion for some BnW palettes.
Dwedit for help and inspiration with a lot of things. https://www.dwedit.org
```

Fredrik Ahlström

Twitter/X @TheRealFluBBa

http://www.github.com/FluBBaOfWard
