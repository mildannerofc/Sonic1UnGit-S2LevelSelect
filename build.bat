@echo off

cd sound
rem *We could put the contents of this script below in here, but it looks better like this
call compile_sounds
cd ..

asm68k /k /m /o ws+,op+,os+,ow+,oz+,oaq+,osq+,omq+,ae-,v+ /p sonic1.asm, s1built.bin
pause
start s1built.bin
