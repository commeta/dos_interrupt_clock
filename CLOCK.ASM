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
    ; Заголовок COM-файла и данные
    ; Сигнатура MZ и заголовок
    db 4Dh, 5Ah, 0ECh, 00h, 02h, 00h, 02h, 00h
    db 20h, 00h, 00h, 00h, 0FFh, 0FFh, 00h
    ; Дополнительные нули до смещения 17h
    times 8 db 00h
    db 1Eh, 00h, 00h, 00h, 01h, 00h, 11h, 00h
    db 00h, 00h, 15h
    ; Заполнение до смещения 0FFh
    times (0FFh - ($ - start)) db 00h
    
    ; Область данных с 200h
    times (200h - ($ - start)) db 00h
    db 0E9h
    mov bx, 0
    times (20Ch - ($ - start)) db 00h
    db 00h, 00h, 18h, 00h, 00h, 00h, 03h, 00h
    db 00h, 00h, 22h

; Смещения данных
old_vector     dd ?          ; Адрес старого обработчика прерывания
counter        db 0          ; Счетчик для ограничения вызовов
time_buffer    db 3 dup(?)   ; Буфер для времени из BIOS
display_buffer db 8 dup(?)   ; Буфер для отображения времени

; Процедура обработки прерывания таймера
timer_handler PROC
    cli                      ; Запрет прерываний
    inc cs:[counter]         ; Увеличение счетчика
    cmp cs:[counter], 14h    ; Проверка счетчика (20 тиков = ~1 сек)
    jae process_time         ; Если >= 20, обрабатываем время
    jmp exit_handler         ; Иначе выходим

process_time:
    mov cs:[counter], 0      ; Сброс счетчика
    sti                      ; Разрешение прерываний
    pusha                    ; Сохранение всех регистров
    push es

    ; Проверка состояния клавиатуры (Scroll Lock)
    push 0
    pop es
    mov di, 417h             ; Адрес флагов клавиатуры в BIOS
    mov al, es:[di]
    pop es
    and al, 10h              ; Проверка бита Scroll Lock
    or al, al
    jne check_video_mode     ; Если Scroll Lock включен, продолжаем
    jmp restore_and_exit

check_video_mode:
    ; Проверка видеорежима
    push 0
    pop es
    mov di, 449h             ; Адрес текущего видеорежима
    mov al, es:[di]
    pop es
    cmp al, 3                ; Текстовый режим 80x25
    jbe get_time             ; Если режим подходящий, получаем время
    jmp restore_and_exit

get_time:
    ; Получение времени от BIOS
    mov ah, 2                ; Функция получения времени
    int 1Ah                  ; Вызов BIOS
    
    ; Сохранение времени в буфер
    xor si, si
    mov cs:[time_buffer + si], ch    ; Часы
    inc si
    mov cs:[time_buffer + si], cl    ; Минуты  
    inc si
    mov cs:[time_buffer + si], dh    ; Секунды

    ; Преобразование BCD в ASCII
    xor si, si               ; Индекс для display_buffer
    xor ax, ax
    xor bx, bx
    mov cx, 3                ; Обработать 3 байта времени

convert_loop:
    mov ah, cs:[time_buffer + bx]
    mov al, ah
    inc bx
    shr ah, 4                ; Старшая тетрада
    and al, 0Fh              ; Младшая тетрада
    add ax, 3030h            ; Преобразование в ASCII
    mov cs:[display_buffer + si], ah
    inc si
    mov cs:[display_buffer + si], al
    inc si
    mov cs:[display_buffer + si], ':'   ; Разделитель
    inc si
    loop convert_loop

    ; Вывод на экран
    lds si, cs:[old_vector + 2]  ; Загрузка указателя на буфер
    mov cx, 8                    ; Длина строки времени
    mov dx, 48h                  ; Атрибут (белый текст на черном фоне)
    cld                          ; Сброс флага направления
    
    push es
    mov ax, 0B800h              ; Сегмент видеопамяти
    mov es, ax
    mov di, 90h                 ; Позиция на экране (верхний правый угол)

display_loop:
    push cx
    lodsb                       ; Загрузка символа
    mov es:[di], al            ; Запись символа в видеопамять
    inc di
    inc di                     ; Пропуск атрибута
    pop cx
    loop display_loop
    
    pop es

restore_and_exit:
    popa                        ; Восстановление регистров

exit_handler:
    sti                         ; Разрешение прерываний
    int 61h                     ; Вызов старого обработчика по цепочке
    iret                        ; Возврат из прерывания
timer_handler ENDP

; Процедура установки обработчика
install_handler PROC
    cli                         ; Запрет прерываний
    
    ; Получение старого вектора прерывания 1Ch
    mov ax, 351Ch              ; DOS функция 35h, прерывание 1Ch
    int 21h                    ; Вызов DOS
    push es                    ; Сохранение сегмента
    pop ds
    push bx                    ; Сохранение смещения
    pop dx
    
    ; Сохранение старого обработчика для вызова по цепочке
    mov ax, 2561h              ; DOS функция 25h, прерывание 61h  
    int 21h
    
    ; Установка нашего обработчика
    mov ax, 251Ch              ; DOS функция 25h, прерывание 1Ch
    lds dx, cs:[old_vector]    ; Загрузка адреса нашего обработчика
    int 21h
    
    sti                        ; Разрешение прерываний
    
    ; Включение Scroll Lock
    push 0
    pop es
    mov di, 417h
    mov es:[di], 10h           ; Установка флага Scroll Lock
    pop es
    
    ; Завершение и остание резидентным
    mov ax, 3103h              ; DOS функция 31h (TSR) с кодом возврата 3
    mov dx, 20h                ; Размер резидентной части в параграфах
    int 21h                    ; Завершение с оставанием в памяти
install_handler ENDP

END start
