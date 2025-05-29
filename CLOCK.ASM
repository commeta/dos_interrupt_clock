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

.MODEL TINY
.CODE
ORG 100h

start:
    jmp install_handler     ; Переход к установке обработчика

; Данные программы
time_buffer     db 3 dup(?)     ; Буфер для хранения времени (час, мин, сек)
display_string  db 8 dup(?)     ; Строка для отображения времени
old_handler     dd ?            ; Адрес старого обработчика прерывания

; Обработчик прерывания таймера (INT 1Ch)
timer_handler proc
    ; Сохранение регистров
    pusha
    
    ; Проверка состояния Scroll Lock
    push es
    push 0
    pop es
    mov di, 417h        ; Адрес байта состояния клавиатуры в BIOS
    mov al, es:[di]
    pop es
    and al, 10h         ; Проверка бита Scroll Lock
    jz exit_handler     ; Если не нажат, выход
    
    ; Проверка видеорежима
    push es
    push 0
    pop es
    mov di, 449h        ; Адрес текущего видеорежима
    mov al, es:[di]
    pop es
    cmp al, 3           ; Проверка на текстовый режим
    ja exit_handler     ; Если не текстовый режим, выход
    
    ; Получение текущего времени
    mov ah, 2           ; Функция получения времени
    int 1ah             ; BIOS прерывание часов
    
    ; Сохранение времени в буфер
    xor si, si
    mov time_buffer[si], ch     ; Часы
    inc si
    mov time_buffer[si], cl     ; Минуты  
    inc si
    mov time_buffer[si], dh     ; Секунды
    
    ; Преобразование времени в строку
    xor si, si
    xor ax, ax
    xor bx, bx
    mov cx, 3           ; 3 компонента времени
    
convert_loop:
    mov ah, time_buffer[bx]
    mov al, ah
    inc bx
    shr ah, 4           ; Старшая тетрада
    and al, 0fh         ; Младшая тетрада
    add ax, 3030h       ; Преобразование в ASCII
    mov display_string[si], ah
    inc si
    mov display_string[si], al
    inc si
    mov display_string[si], ':'  ; Разделитель
    inc si
    loop convert_loop
    
    ; Отображение времени на экране
    push ds
    lds si, cs:[old_handler + 2] ; Загрузка адреса строки
    mov cx, 8           ; Длина строки времени
    mov dx, 48h         ; Позиция на экране
    cld
    
    push es
    push 0b800h         ; Видеопамять
    pop es
    mov di, 90h         ; Позиция в видеопамяти
    
display_loop:
    push cx
    lodsb               ; Загрузка символа
    mov es:[di], al     ; Запись в видеопамять
    inc di
    inc di              ; Пропуск атрибута
    pop cx
    loop display_loop
    
    pop es
    pop ds

exit_handler:
    popa
    sti
    int 61h         ; Вызов следующего обработчика в цепочке
    iret

timer_handler endp

; Процедура установки обработчика
install_handler:
    cli
    
    ; Получение адреса старого обработчика INT 1Ch
    mov ax, 351ch
    int 21h
    mov word ptr old_handler, bx
    mov word ptr old_handler + 2, es
    
    ; Установка нового обработчика
    mov ax, 251ch
    mov dx, offset timer_handler
    int 21h
    
    sti
    
    ; Установка Scroll Lock
    push es
    push 0
    pop es
    mov di, 417h
    mov byte ptr es:[di], 10h   ; Установка бита Scroll Lock
    pop es
    
    ; Завершение программы, оставляя резидентной
    mov ax, 3100h       ; Завершение с сохранением в памяти
    mov dx, 20h         ; Размер резидентной части в параграфах
    int 21h

END start
