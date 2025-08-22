Note: This is not made to create pull request to be added, this is the same disassembly showing how Sonic 2 Level Select by Esrael is added in this disassembly. No need to make tutorial about it and I did _NOT_ endorse on this disassembly.

If you would like to use this in your project, remember to read the original description for more information about this disassembly.

Original description
## Sonic 1 UnGit Disassembly
This is a fork of the [Sonic 1 GitHub disassembly targeting _asm68k_](https://github.com/sonicretro/s1disasm/tree/asm68k) that aims to remove as much superfluous junk as possible. While the community disassembly is great for research purposes, it comes with a lot of stuff that makes the project folder unnecessarily bloated.

Furthermore, this project attempts to recreate some conveniences of the old Hivebrain 2005 disassembly — namely, undoing the extraction of every single object into its own file in the _\_incObj_ folder. Call me stubborn and old-fashioned, but I'd rather have everything right there in _sonic1.asm_ instead.

You may now go ahead and call me a heretic. I don't care.

## Differences

### Files
* Completely merged _incObj folder with sonic1.asm
* Completely merged _inc folder with sonic1.asm (this is technically diverting from the Hivebrain 2005 style, but I never understood the arbitrary extraction of those files anyway)
* Removed various junk files, including most project files for community tools (except for SonLVL and SonPLN, courtesy of Speems)
* Collapsed all revision conditionals to always use JP rev01
* Re-extracted title card mappings (out of all the things to re-include, why the hell would you do it for the title cards???)
* Removed most unused files
* Moved _tilemaps_ folder stuff into _misc_ folder
* Renamed some includes to start with _
* Moved sound driver to _sound_ folder
* Renamed _sonic.asm_ to _sonic1.asm_

### Code Style
* Collapsed multi-empty lines to a single one each
* Removed all trailing whitespace before a line end
* Removed _S U B R O U T I N E_ garbage
* Replaced all tabs in comments with single spaces
* Some comment cleanup around objects
* Removed zonewarning macro

### Code
* MegaPCM (thanks to RobiWanKenobi)
* ASM music (thanks to RobiWanKenobi)
* vladikcomper's debugger (thanks to RobiWanKenobi)
* Enabled a whole bunch of compiler optimizations
* Removed checksum check and fixheadr.exe
* Removed ROM padder
* Flag to conveniently enable all cheats
* Fixed PRESS START BUTTON bug

## Warning
This project is *NOT* anywhere close to being bit-accurate and has zero intentions of being so. The main goal of this project is to provide a nicer out-of-the-box experience without being bombarded with a whole bunch of stuff 99% of people won't ever touch. If you care about bit accuracy, the GitHub community disassembly is right there.
