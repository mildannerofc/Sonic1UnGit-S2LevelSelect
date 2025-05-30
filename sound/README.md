# Defining Samples in ASM Music

At the top of your music file; use `dSAMPLE=$XX` or define it in `_smps2asm_inc.asm` in the DAC Sample Equates

* By Default, $81 is dKick, $82 is dSnare, $83 is a Timpani, and $88-$8B are Timpani pitches

* $84 - $8A (inclusive) are free

* $8C is the Sega Chant

* All samples are Unisgned 8-bit PCM by default instead of DPCM, and can be edited in a program such as , but must be Mono

# Using ASM Music:

* To get the game to read it, in s1.soundriver.asm; use `MusicXX:	include	"sound/music/Music.asm"` with an `even` on the line below

* It's easier to replace a song; but you can add new songs, you just need to define them in `_Constants.asm`

* $94 - $9F (inclusive) are clear
