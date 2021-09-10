cd C:\build\zxAsm\TeletypeEffect\

echo ---------           Compile           ---------
sjasmplus C:\build\zxAsm\TeletypeEffect\TTYPE.asm

echo ---------           Running           ---------
"C:\Program Files (x86)\Spectaculator\Spectaculator.exe" C:\build\zxAsm\TeletypeEffect\ttype.sna
