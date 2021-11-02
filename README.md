# NitroSwan V0.1.1

<img align="right" width="220" src="./logo.png" />

This is a Bandai WonderSwan (Color) emulator for the Nintendo DS.

## How to use:

Depending on your flashcart you might have to DLDI patch the emulator.
Create a folder named "nitroswan" in either the root of your flash card or in the
data folder. Now put game/bios files into a folder where you have roms.
Note! You need a bios to be able to save in game.
The save file should be compatible with most other NeoGeo Pocket emulators.

When the emulator starts, you can either press L+R or tap on the screen to open
up the menu.
Now you can use the cross or touchscreen to navigate the menus, A or double tap
to select an option, B or the top of the screen to go back a step.

To select between the tabs use R & L or the touchscreen.

## Menu:

### File:
	Load Game: Select a game to load.
	Load State: Load a previously saved state of the currently running game.
	Save State: Save a state of the currently running game.
	Load Flash RAM: Load flash ram for the currently running game.
	Save Flash RAM: Save flash ram for the currently running game.
	Save Settings: Save the current settings.
	Reset Game: Reset the currently running game.

### Options:
	Controller:
		Autofire: Select if you want autofire.
		Controller: 2P start a 2 player game.
		Swap A/B: Swap which NDS button is mapped to which NGP button.
	Display:
		Mono Palette: Here you can select the palette for B & W games.
		Gamma: Lets you change the gamma ("brightness").
		Disable Foreground: Turn on/off foreground rendering.
		Disable Background: Turn on/off background rendering.
		Disable Sprites: Turn on/off sprite rendering.
	Machine Settings:
		Language: Select between Japanese and English.
		Machine: Select the emulated machine.
		Half cpu speed: This halves the emulated cpu speed.
			Can make games faster.
		Change Batteries: Change to new main batteries (AA/LR6).
		Change Sub Battery: Change to a new sub battery (CR2032).
		Cpu speed hacks: Allow speed hacks.
		Bios Settings: Load a real NGP Bios, recommended.
	Settings:
		Speed: Switch between speed modes.
			Normal: Game runs at it's normal speed.
			200%: Game runs at double speed.
			Max: Games can run up to 4 times normal speed (might change).
			50%: Game runs at half speed.
		Autoload State: Toggle Savestate autoloading.
			Automagically load the savestate associated with the current game.
		Autoload Flash RAM: Toggle flash/save ram autoloading.
			Automagically load the flash ram associated with the current game.
		Autosave Settings: This will save settings when
			leaving menu if any changes are made.
		Autopause Game: Toggle if the game should pause when opening the menu.
		Powersave 2nd Screen: If graphics/light should be turned off for the
			GUI screen when menu is not active.
		Emulator on Bottom: Select if top or bottom screen should be used for
			emulator, when menu is active emulator screen is allways on top.
		Debug Output: Show an FPS meter for now.
		Autosleep: Doesn't work.

### About:
	Some dumb info about the game and emulator...

## Credits:

Huge thanks to Loopy for the incredible PocketNES, without it this emu would
probably never have been made.
Thanks to:
Flavor & Koyote for WonderSwan info.
Godzil for the boot rom stubs. https://github.com/Godzil/NewOswan
Dwedit for help and inspiration with a lot of things.


Fredrik Ahlström
Twitter @TheRealFluBBa
http://www.github.com/FluBBaOfWard

