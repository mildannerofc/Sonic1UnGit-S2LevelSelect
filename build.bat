@echo off

asm68k /k /m /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /o ae- /o v+ /o c+ /p sonic1.asm, s1built.bin, _debug/s1built.sym, _debug/sonic1.lst
"_debug/convsym.exe" _debug/s1built.sym s1built.bin -a

pause

if exist s1built.bin (
	start s1built.bin
)
