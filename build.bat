@echo off
rem RELEASE BUILD
asm68k /k /m /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /o ae- /o v+ /o c+ /p sonic1.asm, s1built.bin, s1built.sym, sonic1.lst
convsym.exe s1built.sym s1built.bin -a

rem DEBUG BUILD
asm68k /k /m /o ws+ /o op+ /o os+ /o ow+ /o oz+ /o oaq+ /o osq+ /o omq+ /o ae- /o v+ /o c+ /p /e __DEBUG__=1 sonic1.asm, s1built.debug.bin, s1built.debug.sym, s1built.debug.lst
convsym.exe s1built.debug.sym s1built.debug.bin -a

pause
start s1built.bin
