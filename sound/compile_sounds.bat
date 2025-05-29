@echo off

cd music

for %%f in (*.asm) do (
    ../smps2asm2bin.exe "%%~nf.asm" "cmp/%%~nf.bin"
)
cd ..
cd sfx
for %%f in (*.asm) do (
    ../smps2asm2bin.exe "%%~nf.asm" "cmp/%%~nf.bin"
)

cd ..

