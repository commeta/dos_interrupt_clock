; ms or free dos clockoff interrupt proc сборка из дампа
; https://github.com/commeta/dos_interrupt_proс
; 
; Copyright 1999 commeta <dcs-spb@ya.ru>
; 
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; 
; You should have received a copy of the GNU General Public License
; along with this program; if not, write to the Free Software
; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
; MA 02110-1301, USA.
 

.MODEL TINY
.CODE
ORG 100h

START:
    ; Адрес 0: Получить версию DOS  
    MOV AX, 0DC2h       ; AH=0Dh, AL=C2h - недокументированная функция DOS
    INT 21h             ; Вызов DOS
    
    ; Адрес 5-6: Сохранить регистры на стеке
    PUSH ES             ; Сохранить ES
    PUSH BX             ; Сохранить BX
    
    ; Адрес 7-12: Получить вектор прерывания 61h
    MOV AX, 3561h       ; AH=35h (получить вектор прерывания), AL=61h
    INT 21h             ; ES:BX теперь указывает на обработчик INT 61h
    
    ; Адрес 12-15: Подготовить параметры для установки вектора
    PUSH ES             ; Сохранить сегмент обработчика INT 61h
    POP DS              ; DS = сегмент обработчика INT 61h  
    PUSH BX             ; Сохранить смещение обработчика
    POP DX              ; DX = смещение обработчика INT 61h
    
    ; Адрес 16-21: Установить вектор прерывания 1Ch (системный таймер)
    MOV AX, 251Ch       ; AH=25h (установить вектор), AL=1Ch (таймер)
    INT 21h             ; Установить INT 1Ch на адрес из DS:DX
    
    ; Адрес 21: Сохранить ES снова
    PUSH ES
    
    ; Адрес 22-24: Подготовить доступ к BIOS Data Area
    XOR AX, AX          ; AX = 0
    MOV ES, AX          ; ES = 0 (BIOS Data Area)
    
    ; Адрес 26-28: Работа с флагом клавиатуры
    MOV DI, 417h        ; DI = 0x417 (адрес флага клавиатуры в BIOS Data Area)
    MOV AL, ES:[DI]     ; Загрузить байт флага клавиатуры
    
    ; Адрес 32-34: Модифицировать флаг (отключить Scroll Lock)
    AND AL, 0EFh        ; Сбросить бит 4 (Scroll Lock = 0)
    MOV ES:[DI], AL     ; Записать измененный флаг обратно
    
    ; Адрес 37: Восстановить ES
    POP ES
    
    ; Адрес 38-43: Подготовка к освобождению памяти
    POP AX              ; Восстановить значение со стека
    POP ES              ; Восстановить ES со стека  
    SUB AX, 2           ; Уменьшить AX на 2
    MOV DI, AX          ; DI = AX (указатель в память)
    MOV AX, ES:[DI]     ; Загрузить слово из памяти ES:[DI]
    
    ; Адрес 48-49: Подготовить сегмент для освобождения
    DEC AX              ; Уменьшить на 1 (получить предыдущий сегмент)
    MOV ES, AX          ; ES = сегмент блока памяти для освобождения
    
    ; Адрес 51-53: Освободить блок памяти
    MOV AH, 49h         ; Функция 49h - освободить блок памяти
    INT 21h             ; ES указывает на блок для освобождения
    
    ; Адрес 55: Проверить успешность операции
    JAE EXIT_SUCCESS    ; Если CF=0 (нет ошибки), перейти к выходу
    
    ; Адрес 57-63: Обработка ошибки - вывести код ошибки
    ADD AL, 30h         ; Преобразовать код ошибки в ASCII символ
    MOV DL, AL          ; DL = символ для вывода
    MOV AH, 02h         ; Функция 02h - вывод символа на экран
    INT 21h             ; Вывести символ
    
EXIT_SUCCESS:
    ; Адрес 65-68: Завершение программы
    MOV AX, 4C00h       ; Функция 4Ch - завершить программу с кодом 0
    INT 21h             ; Завершить

END START

; ПОДРОБНЫЙ АНАЛИЗ ПРОГРАММЫ:
;
; Эта программа выполняет операцию по восстановлению таблицы векторов прерываний:
;
; 1. ПОЛУЧЕНИЕ ВЕРСИИ DOS (0DC2h):
;    - Недокументированная функция для получения внутренней информации DOS
;
; 2. ПЕРЕХВАТ ПРЕРЫВАНИЯ ТАЙМЕРА:
;    - Получает текущий обработчик INT 61h
;    - Устанавливает этот же обработчик для INT 1Ch (системный таймер)
;    - Это означает перенаправление системных тиков таймера
;
; 3. ОТКЛЮЧЕНИЕ SCROLL LOCK:
;    - Обращается к BIOS Data Area по адресу 0x417
;    - Сбрасывает бит 4, отвечающий за индикатор Scroll Lock
;    - Это "выключает" индикацию часов на клавиатуре
;
; 4. ОСВОБОЖДЕНИЕ ПАМЯТИ:
;    - Использует сложную логику для определения блока памяти
;    - Освобождает блок через функцию DOS 49h
;    - При ошибке выводит код ошибки на экран
;
; НАЗНАЧЕНИЕ: Программа отключает отображение системного времени
; и освобождает связанную с этим память.
