cd C:\build\zxAsm\DoubleBuffering\

echo ---------           Compile           ---------
sjasmplus C:\build\zxAsm\DoubleBuffering\DBUFFER.asm

echo ---------           Running           ---------
"C:\Program Files (x86)\Spectaculator\Spectaculator.exe" C:\build\zxAsm\DoubleBuffering\dbuffer.sna
