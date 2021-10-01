cd C:\build\zxAsm\KeyboardControl\

echo ---------           Compile           ---------
sjasmplus C:\build\zxAsm\KeyboardControl\KEYCTRL.asm

echo ---------           Running           ---------
"C:\Program Files (x86)\Spectaculator\Spectaculator.exe" C:\build\zxAsm\KeyboardControl\keyctrl.sna
