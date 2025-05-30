# Defining Samples in ASM Music

At the top of your music file; use `dSAMPLE=$XX` 

* By Default, $81 is dKick, $82 is dSnare, $83 is a Timpani, and $88-$8B are Timpani pitches

* $84 - $8A (inclusive) are free

* $8C is the Sega Chant

* All samples are PCM by default instead of DPCM

# Using ASM Music:

* To get the game to read it, in s1.soundriver.asm; use `MusicXX:	incbin	"sound/music/cmp/Music.bin"` with an `even` on the line below (the filename for Music.bin should have the same name as Music.asm)

* It's easier to replace a song; but you can add new songs, you just need to define them in `_Constants.asm`

* $94 - $9F (inclusive) are clear
