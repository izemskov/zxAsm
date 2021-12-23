# Изучение ассемблера ZX-Spectrum

## 1. HelloWorld
Простой вывод строки с использованием функции ПЗУ 8252<br><br>
![Screenshot](HelloWorld/screen.png)

## 2. PassParamThroughStack
Небольшой эксперимент с передачей параметров в свою функцию через стек. 
Необходимо помнить, что на вершину стека, при вызове функции, кладется адрес возврата 
и важно его не испортить<br><br>
![Screenshot](PassParamThroughStack/screen.png)

## 3. SetScreenAttribute
Медленная функция установки аттрибутов экрана с использованием функции ПЗУ 16<br><br>
![Screenshot](SetScreenAttribute/screen.png)<br/>
![Screenshot](SetScreenAttribute/screen1.png)

## 4. FastSetScreenAttribute
Быстрая функция установки аттрибутов при помощи прямой работы с видеопамятью<br><br>
![Screenshot](FastSetScreenAttribute/screen.png)

## 5. StaticScreen
Вывод красивой рамки при помощи набора символов UDG и функции ПЗУ 8252<br><br>
![Screenshot](StaticScreen/screen.png)

## 6. TeletypeEffect
Эффект телетайпа. Первый эксперимент с использованием прерывания IM2 для реализации функции задержки<br><br>
![Screenshot](TeletypeEffect/screen.png)

## 7. DrawSprite
Вывод спрайта на экран при помощи прямой работы с видеопамятью<br><br>
![Screenshot](DrawSprite/screen.png)

## 8. AnimatedSprite
Вывод многокадрового спрайта в движении<br><br>
![Screenshot](AnimatedSprite/screen.gif)

## 9. KeyboardControl
Управление спрайтом при помощи клавиш WASD<br><br>
![Screenshot](KeyboardControl/screen.gif)

## 10. ScoreWorker
Счетчик очков<br><br>
![Screenshot](ScoreWorker/screen.gif)
