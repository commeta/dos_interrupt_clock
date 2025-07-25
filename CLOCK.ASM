; ms or free dos clock&sa interrupt proc сборка из дампа
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
.186
ORG 100h

start:
    ; Точка входа программы - сразу переходим к установке обработчика
    jmp install_handler

; ==================== ОБЛАСТЬ ДАННЫХ ====================
; Данные должны быть в правильном порядке согласно дизассемблеру

display_string  db 8 dup(?)     ; [CS:0003h] Строка времени в ASCII формате для отображения
time_buffer     db 3 dup(?)     ; [CS:000Ch] Буфер для хранения времени (часы, минуты, секунды в BCD)
old_handler     dd ?            ; [CS:000Fh] Адрес предыдущего обработчика INT 1Ch (сегмент:смещение)
string_ptr      dd ?            ; [CS:0013h] Указатель на строку времени для вывода
counter         db 0            ; [CS:0017h] Счетчик тиков таймера (для ограничения частоты)

; ==================== ОБРАБОТЧИК ПРЕРЫВАНИЯ ТАЙМЕРА ====================
; Этот обработчик вызывается 18.2 раза в секунду системным таймером (INT 1Ch)
timer_handler proc
    ; ---- ОГРАНИЧЕНИЕ ЧАСТОТЫ ОБНОВЛЕНИЯ ----
    cli                                 ; Запрет прерываний для атомарности операций
    inc byte ptr cs:[counter]           ; Увеличиваем счетчик тиков (cs:[0017h]++)
    cmp byte ptr cs:[counter], 14h      ; Сравниваем с 20 (14h) - это примерно 1 секунда
    jae time_update                     ; Если >= 20, переходим к обновлению времени
    jmp exit_handler                    ; Иначе - выходим без обновления
    
time_update:
    ; ---- СБРОС СЧЕТЧИКА И ПОДГОТОВКА К ОБНОВЛЕНИЮ ----
    mov byte ptr cs:[counter], 0        ; Сбрасываем счетчик для следующей секунды
    sti                                 ; Разрешаем прерывания
    pusha                              ; Сохраняем ВСЕ регистры общего назначения (AX,BX,CX,DX,SI,DI,BP,SP)
    
    ; ---- ПРОВЕРКА СОСТОЯНИЯ SCROLL LOCK ----
    ; Часы отображаются только когда включен Scroll Lock
    push es                            ; Сохраняем ES
    push 0                             ; Устанавливаем ES = 0 (область данных BIOS)
    pop es
    mov di, 417h                       ; ES:DI указывает на байт состояния клавиатуры BIOS
    mov al, es:[di]                    ; Загружаем байт состояния клавиатуры
    pop es                             ; Восстанавливаем ES
    and al, 10h                        ; Проверяем бит 4 (Scroll Lock)
    or al, al                          ; Устанавливаем флаги
    jne check_video_mode               ; Если Scroll Lock включен - продолжаем
    jmp restore_and_exit               ; Иначе - выходим без отображения
    
check_video_mode:
    ; ---- ПРОВЕРКА ВИДЕОРЕЖИМА ----
    ; Работаем только в текстовых режимах (0-3)
    push es                            ; Сохраняем ES
    push 0                             ; ES = 0 (область BIOS)
    pop es
    mov di, 449h                       ; ES:DI указывает на текущий видеорежим
    mov al, es:[di]                    ; Загружаем номер текущего видеорежима
    pop es                             ; Восстанавливаем ES
    cmp al, 3                          ; Сравниваем с режимом 3 (80x25 цветной текст)
    jbe get_time                       ; Если режим <= 3 - продолжаем
    jmp restore_and_exit               ; Иначе - выходим (графические режимы не поддерживаются)
    
get_time:
    ; ---- ПОЛУЧЕНИЕ ТЕКУЩЕГО ВРЕМЕНИ ОТ BIOS ----
    mov ah, 2                          ; Функция 02h BIOS INT 1Ah - получить время
    int 1ah                            ; Вызов BIOS: CH=часы, CL=минуты, DH=секунды (в упакованном BCD формате)
    
    ; ---- СОХРАНЕНИЕ ВРЕМЕНИ В БУФЕР ----
    ; Время приходит в упакованном BCD формате (каждая тетрада - одна цифра)
    xor si, si                         ; SI = 0 (индекс в буфере)
    mov cs:[time_buffer + si], ch      ; Сохраняем часы в time_buffer[0]
    inc si                             ; SI = 1
    mov cs:[time_buffer + si], cl      ; Сохраняем минуты в time_buffer[1]
    inc si                             ; SI = 2
    mov cs:[time_buffer + si], dh      ; Сохраняем секунды в time_buffer[2]
    
    ; ---- ПРЕОБРАЗОВАНИЕ BCD В ASCII СТРОКУ ----
    xor si, si                         ; SI = 0 (индекс в строке вывода)
    xor ax, ax                         ; Очищаем AX
    xor bx, bx                         ; BX = 0 (индекс в буфере времени)
    mov cx, 3                          ; Цикл для 3-х компонентов времени (час:мин:сек)
    
convert_loop:
    ; Обработка одного компонента времени (час, минута или секунда)
    mov ah, cs:[time_buffer + bx]      ; Загружаем BCD байт (например, 23h для 23 часов)
    mov al, ah                         ; Копируем для обработки младшей тетрады
    inc bx                             ; Переходим к следующему байту времени
    
    ; Разделение BCD байта на две цифры
    shr ah, 4                          ; Старшая тетрада (старшая цифра) - сдвиг вправо на 4 бита
    and al, 0fh                        ; Младшая тетрада (младшая цифра) - маска 0000 1111
    
    ; Преобразование в ASCII
    add ax, 3030h                      ; Добавляем ASCII код '0' (30h) к каждой цифре
    
    ; Сохранение в строку вывода
    mov cs:[display_string + si], ah   ; Старшая цифра
    inc si
    mov cs:[display_string + si], al   ; Младшая цифра
    inc si
    mov cs:[display_string + si], 3ah  ; Разделитель ':' (ASCII 3Ah)
    inc si
    loop convert_loop                  ; Повторяем для всех 3-х компонентов
    
    ; В результате получаем строку вида "12:34:56:"
    
    ; ---- ВЫВОД ВРЕМЕНИ НА ЭКРАН ----
    ; Устанавливаем указатель на нашу строку времени
    mov word ptr cs:[string_ptr], offset display_string     ; Смещение
    mov word ptr cs:[string_ptr + 2], cs                    ; Сегмент
    
    lds si, cs:[string_ptr]            ; Загружаем указатель на строку времени (DS:SI)
    mov cx, 8                          ; Длина строки для вывода (8 символов)
    mov dx, 48h                        ; Позиционирование (не используется в данной реализации)
    cld                                ; Очищаем флаг направления (строки обрабатываются слева направо)
    
    ; Настройка для работы с видеопамятью
    push es                            ; Сохраняем текущий ES
    push 0b800h                        ; Загружаем адрес сегмента видеопамяти (цветной текстовый режим)
    pop es                             ; ES = B800h
    mov di, 90h                        ; Смещение в видеопамяти (позиция на экране)
    
display_loop:
    ; Цикл вывода символов в видеопамять
    push cx                            ; Сохраняем счетчик цикла
    lodsb                              ; Загружаем символ из [DS:SI] в AL, SI++
    mov es:[di], al                    ; Записываем символ в видеопамять
    inc di                             ; Переходим к следующей позиции символа
    inc di                             ; Пропускаем байт атрибута (цвет/стиль)
    pop cx                             ; Восстанавливаем счетчик
    loop display_loop                  ; Повторяем для всех символов
    
    pop es                             ; Восстанавливаем исходный ES

restore_and_exit:
    ; ---- ВОССТАНОВЛЕНИЕ СОСТОЯНИЯ ----
    popa                               ; Восстанавливаем ВСЕ регистры общего назначения

exit_handler:
    ; ---- ЗАВЕРШЕНИЕ ОБРАБОТЧИКА ПРЕРЫВАНИЯ ----
    sti                                ; Разрешаем прерывания
    int 61h                            ; Передаем управление следующему обработчику в цепочке
    iret                               ; Возврат из прерывания (восстанавливает флаги и адрес возврата)

timer_handler endp

; ==================== ПРОЦЕДУРА УСТАНОВКИ ОБРАБОТЧИКА ====================
; Эта процедура выполняется один раз при запуске программы
install_handler:
    cli                                ; Запрещаем прерывания на время установки

    ; ---- ПОЛУЧЕНИЕ АДРЕСА ТЕКУЩЕГО ОБРАБОТЧИКА INT 1Ch ----
    mov ax, 351ch                      ; DOS функция 35h: получить вектор прерывания 1Ch
    int 21h                            ; Вызов DOS: ES:BX = адрес текущего обработчика
    
    ; ---- СОХРАНЕНИЕ СТАРОГО ОБРАБОТЧИКА ----
    ; Сохраняем адрес для восстановления цепочки прерываний
    mov word ptr cs:[old_handler], bx      ; Сохраняем смещение
    mov word ptr cs:[old_handler + 2], es  ; Сохраняем сегмент
    
    ; ---- УСТАНОВКА ПРОМЕЖУТОЧНОГО ОБРАБОТЧИКА ----
    ; Настройка регистров для установки нового обработчика
    push es                            ; Сохраняем ES (адрес старого обработчика)
    pop ds                             ; DS = сегмент старого обработчика
    push bx                            ; Сохраняем смещение старого обработчика
    pop dx                             ; DX = смещение старого обработчика
    
    ; Устанавливаем старый обработчик как INT 61h (для цепочки вызовов)
    mov ax, 2561h                      ; DOS функция 25h: установить вектор прерывания 61h
    int 21h                            ; DS:DX указывает на старый обработчик
    
    ; ---- УСТАНОВКА НАШЕГО ОБРАБОТЧИКА ----
    mov ax, 251ch                      ; DOS функция 25h: установить вектор прерывания 1Ch
    push cs                            ; Наш сегмент кода
    pop ds                             ; DS = CS
    mov dx, offset timer_handler       ; DX = адрес нашего обработчика
    int 21h                            ; Устанавливаем наш обработчик для INT 1Ch
    
    sti                                ; Разрешаем прерывания
    
    ; ---- ВКЛЮЧЕНИЕ SCROLL LOCK ----
    ; Автоматически включаем Scroll Lock для активации часов
    push es                            ; Сохраняем ES
    push 0                             ; ES = 0 (область BIOS)
    pop es
    mov di, 417h                       ; Адрес байта состояния клавиатуры
    mov byte ptr es:[di], 10h          ; Устанавливаем бит Scroll Lock (бит 4)
    pop es                             ; Восстанавливаем ES
    
    ; ---- ЗАВЕРШЕНИЕ КАК TSR (TERMINATE AND STAY RESIDENT) ----
    mov ax, 3103h                      ; DOS функция 31h (вариант 03h): завершить и остаться резидентной
    mov dx, 20h                        ; Размер резидентной части в параграфах (512 байт)
    int 21h                            ; Программа остается в памяти, управление возвращается DOS

END start
