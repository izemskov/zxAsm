cd C:\build\zxAsm\ScoreWorker\

echo ---------           Compile           ---------
sjasmplus C:\build\zxAsm\ScoreWorker\SCORE.asm

echo ---------           Running           ---------
"C:\Program Files (x86)\Spectaculator\Spectaculator.exe" C:\build\zxAsm\ScoreWorker\score.sna
