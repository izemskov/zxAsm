cd C:\build\zxAsm\AnimatedSprite\

echo ---------           Compile           ---------
sjasmplus C:\build\zxAsm\AnimatedSprite\ASPRITE.asm

echo ---------           Running           ---------
"C:\Program Files (x86)\Spectaculator\Spectaculator.exe" C:\build\zxAsm\AnimatedSprite\asprite.sna
