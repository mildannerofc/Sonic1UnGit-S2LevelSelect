@echo off

cd sound
call compile_sounds
cd ..

asm68k /k /m /o ws+,op+,os+,ow+,oz+,oaq+,osq+,omq+,ae-,v+ /p sonic1.asm, s1built.bin
pause
start s1built.bin
