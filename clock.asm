; ms or free dos clock&sa interrupt proc (bugfix) сборка из дампа
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
 
; clock&sa.asm

.model small


.stack
.data
TimeStr         db 9 dup(0)
TimeArray       db 8 dup(?)
Counter         db 0
.code
.386
org 11h ;
start:
jmp SetupInterruptHandler


; Процедура обработки прерывания
InterruptHandler proc
    cli                     ; Запрет прерываний
    inc byte ptr cs:[Counter] ; Увеличение счетчика
    cmp byte ptr cs:[Counter], 14h
    jae ResetCounter
    ;jmp short EndInterrupt
    jmp near ptr NextEndInterrupt

ResetCounter:
    mov byte ptr cs:[Counter], 0 ; Сброс счетчика

;CheckScrollLock:
    sti                     ; Разрешаем прерывания
    pusha                   ; Сохраняем регистры
    push es
    push 0
    pop es
    mov di, 0417h           ; Адрес флага Scroll Lock в памяти BIOS
    mov al, es:[di]
    pop es
    and al, 10h             ; Проверка флага Scroll Lock
    or al, al
    jne GetTime             ; Если Scroll Lock активен, получаем время
    jmp near ptr EndInterrupt

GetTime:
    push es
    push 0
    pop es
    mov di, 0449h           ; Сегмент видеопамяти
    mov al, es:[di]
    pop es
    cmp al, 3
    jbe DisplayTime         ; Если условие выполняется, выводим время на экран
    jmp near ptr EndInterrupt

DisplayTime:
    mov ah, 02h             ; Функция BIOS для получения времени
    int 1Ah                 ; Запрос времени из BIOS
    xor si, si              ; Обнуление SI для использования в качестве индекса
    mov cs:[TimeArray + si], ch ; Сохраняем часы в массиве
    inc si
    mov cs:[TimeArray + si], cl ; Сохраняем минуты в массиве
    inc si
    mov cs:[TimeArray + si], dh ; Сохраняем секунды в массиве

; Конвертация времени из BCD в ASCII и вывод на экран
;ConvertAndDisplay:
    xor si, si              ; Сброс SI для использования в качестве индекса массива времени
    xor ax, ax              ; Обнуление AX для использования в операциях
    xor bx, bx              ; Обнуление BX для использования в операциях
    mov cx, 3               ; Счетчик цикла для обработки часов, минут и секунд

LoopConvert:
    mov ah, cs:[TimeArray + bx] ; Получение компонента времени из массива
    mov al, ah              ; Копирование в AL для обработки
    inc bx                  ; Увеличение индекса массива времени
    shr ah, 4               ; Извлечение старшей тетрады (десятков)
    and al, 0Fh             ; Извлечение младшей тетрады (единиц)
    add ax, 3030h           ; Преобразование в ASCII
    mov cs:[TimeStr + si], ah ; Сохранение старшей тетрады в строку времени
    inc si
    mov cs:[TimeStr + si], al ; Сохранение младшей тетрады в строку времени
    inc si

; Вставка разделителя между компонентами времени
;InsertSeparator:
    mov byte ptr cs:[TimeStr + si], ':' ; Вставка символа ':'
    inc si                  ; Увеличение индекса строки времени

; Проверка окончания цикла конвертации и вывода
;CheckLoop:
    loop LoopConvert       ; Повторение цикла для следующего компонента времени

; Вывод времени на экран в правом верхнем углу
;OutputTimeToScreen:
    lds si, dword ptr [TimeStr]   ; Загрузка адреса строки времени в DS:SI
    mov cx, 8              ; Количество символов для вывода (чч:мм:сс)
    mov dx, 0048h          ; Позиция вывода на экране (строка 0, столбец 72)
    cld                    ; Сброс флага направления для автоинкремента DI

; Установка сегмента видеопамяти для вывода текста в текстовом режиме (BIOS)
;SetVideoMemorySegment:
    push es
    push 0B800h
    pop es                 ; Установка ES на сегмент видеопамяти 0B800h

; Цикл вывода символов времени на экран
OutputLoop:
    push cx                ; Сохранение CX перед изменениями в цикле
    lodsb                  ; Загрузка следующего байта строки времени в AL
    mov es:[di], al        ; Вывод символа по адресу [ES:DI]
    inc di                 ; Переход к следующему символу на экране (пропуск атрибута)
    inc di                 ; Пропуск байта атрибута при выводе в текстовом режиме
    pop cx                 ; Восстановление CX после выполнения цикла

; Проверка окончания цикла вывода и завершение работы процедуры обработки прерывания
;CheckOutputLoop:
    loop OutputLoop       ; Повторение цикла вывода для оставшихся символов строки времени

    pop es                 ; Восстановление предыдущего значения ES

EndInterrupt:
    popa                   ; Восстановление регистров из стека
NextEndInterrupt:
    sti                    ; Разрешение прерываний

    int 61h                ; Вызов старого обработчика прерываний по цепочке
    iret                   ; Возврат из прерывания

InterruptHandler endp
;end InterruptHandler








; Процедура установки обработчика прерывания
SetupInterruptHandler proc
    cli                      ; Запрет прерываний

    ; Получение адреса старого обработчика прерывания
    mov ax, 351Ch            ; DOS Fn 35H: получить вектор прерывания
    int 21h                  ; Вызов DOS API
    push es                  ; Сохраняем ES
    pop ds                   ; Переносим значение ES в DS
    push bx                  ; Сохраняем адрес старого обработчика
    pop dx                   ; Переносим адрес в DX для установки нового обработчика

    ; Установка нового обработчика прерывания
    mov ax, 2561h            ; DOS Fn 25H: установить вектор прерывания
    int 21h                  ; Вызов DOS API

    ; Сохранение адреса старого обработчика
    mov ax, 251Ch            ; Подготовка к сохранению старого обработчика
    ;lds dx, [0Fh]            ; Загружаем адрес старого обработчика в DX для вызова по цепочке
    lds dx, dword ptr InterruptHandler            ; Загружаем адрес старого обработчика в DX для вызова по цепочке
    int 21h                  ; Вызов DOS API для установки адреса старого обработчика

    sti                      ; Разрешаем прерывания

    push es                  ; Сохраняем ES
    push 0                   ; Зануляем верхнюю часть стека
    pop es                   ; Переносим 0 в ES для доступа к BIOS данных
    mov di, 0417h            ; DI указывает на порт клавиатуры
    mov byte ptr es:[di], 10h; Устанавливаем специфичный режим работы клавиатуры
    pop es                   ; Восстанавливаем старое значение ES

    mov ax, 3103h            ; Подготовка к завершению программы с кодом возврата 03h
    mov dx, 0020h            ; Необязательный параметр, обычно игнорируется DOS
    int 21h                  ; Вызов DOS для завершения программы
SetupInterruptHandler endp
;end SetupInterruptHandler

end start
