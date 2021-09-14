cd C:\build\zxAsm\DrawSprite\

echo ---------           Compile           ---------
sjasmplus C:\build\zxAsm\DrawSprite\DSPRITE.asm

echo ---------           Running           ---------
"C:\Program Files (x86)\Spectaculator\Spectaculator.exe" C:\build\zxAsm\DrawSprite\dsprite.sna
