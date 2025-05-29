# Defining Samples in ASM Music

At the top of your music file; use `dSAMPLE=$XX` 

* By Default, $81 is dKick, $82 is dSnare, $83 is a Timpani, and $88-$8B are Timpani pitches

* $8C is the Sega Chant

# Using ASM Music:

* To complie at build, add  `smps2asm2bin.exe "music/Music.asm" "cmp_music/Music.bin"` to compile_sounds.bat (renaming Music to the song of your choice)

* To get the game to read it, in s1.soundriver.asm; use `MusicXX:	incbin	"sound/cmp_music/Music.bin"` with an `even` on the line below

* It's easier to replace a song; but you can add new songs, you just need to define them in `_Constants.asm`

* Music must be compiled seperate
