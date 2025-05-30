; Оптимизированная версия программы для MS-DOS
; Компилируется в TASM
; Основные оптимизации: размер кода, скорость выполнения, использование памяти

.MODEL TINY
.CODE
.186
ORG 100h

start:
    jmp install_handler

; ==================== КОМПАКТНАЯ ОБЛАСТЬ ДАННЫХ ====================
display_string  db 8 dup(?)     ; Строка времени для отображения
old_handler     dd ?            ; Адрес предыдущего обработчика
counter         db 0            ; Счетчик тиков (оптимизировано - убран лишний буфер)

; ==================== ОПТИМИЗИРОВАННЫЙ ОБРАБОТЧИК ПРЕРЫВАНИЯ ====================
timer_handler proc
    ; Быстрая проверка счетчика без CLI/STI
    inc byte ptr cs:[counter]
    cmp byte ptr cs:[counter], 18
    jb exit_handler                     ; Короткий переход если не время обновлять
    
    mov byte ptr cs:[counter], 0
    pushf                               ; Сохраняем флаги вместо полного контекста
    push ax bx cx dx si di es          ; Селективное сохранение регистров
    
    ; ОПТИМИЗАЦИЯ: объединенная проверка состояния
    push 40h                           ; Сегмент BIOS данных
    pop es
    test byte ptr es:[17h], 10h        ; Проверка Scroll Lock одной инструкцией
    jz restore_exit                    ; Если выключен - выход
    
    cmp byte ptr es:[49h], 3           ; Быстрая проверка видеорежима
    ja restore_exit                    ; Если не текстовый - выход
    
    ; КЛЮЧЕВАЯ ОПТИМИЗАЦИЯ: прямое получение времени без промежуточного буфера
    mov ah, 2Ch                        ; DOS функция получения времени
    int 21h                            ; CH=часы, CL=минуты, DH=секунды
    
    ; СУПЕР-ОПТИМИЗАЦИЯ: прямое преобразование в ASCII с помощью таблицы
    mov si, offset display_string
    
    ; Обработка часов
    mov al, ch
    call convert_to_ascii
    mov byte ptr cs:[si+2], ':'
    
    ; Обработка минут  
    mov al, cl
    add si, 3
    call convert_to_ascii
    mov byte ptr cs:[si+2], ':'
    
    ; Обработка секунд
    mov al, dh
    add si, 3
    call convert_to_ascii
    
    ; ОПТИМИЗИРОВАННЫЙ вывод в видеопамять
    push 0B800h                        ; Видеопамять
    pop es
    mov di, 90h                        ; Позиция на экране
    mov si, offset display_string
    mov cx, 4                          ; 4 итерации для 8 символов
    
display_loop:
    ; Вывод 2 символов за раз (оптимизация)
    mov ax, cs:[si]                    ; Загружаем 2 символа
    mov es:[di], al                    ; Первый символ
    mov es:[di+2], ah                  ; Второй символ
    add si, 2
    add di, 4                          ; Пропускаем атрибуты
    loop display_loop
    
restore_exit:
    pop es di si dx cx bx ax          ; Восстанавливаем регистры
    popf
    
exit_handler:
    int 61h                           ; Передача управления старому обработчику
    iret

; ОПТИМИЗИРОВАННАЯ процедура преобразования в ASCII
convert_to_ascii proc
    ; Вход: AL = двоичное число (0-59), SI = указатель на буфер
    ; Выход: в буфер записаны 2 ASCII символа
    mov ah, 0
    mov bl, 10
    div bl                            ; AL = десятки, AH = единицы
    add ax, 3030h                     ; Преобразование в ASCII
    mov cs:[si], al                   ; Десятки
    mov cs:[si+1], ah                 ; Единицы
    ret
convert_to_ascii endp

timer_handler endp

; ==================== ОПТИМИЗИРОВАННАЯ УСТАНОВКА ====================
install_handler:
    ; Получение и сохранение старого обработчика
    mov ax, 351ch
    int 21h
    mov word ptr cs:[old_handler], bx
    mov word ptr cs:[old_handler+2], es
    
    ; Установка старого обработчика как INT 61h
    push es
    pop ds
    mov ax, 2561h
    mov dx, bx
    int 21h
    
    ; Установка нашего обработчика
    mov ax, 251ch
    push cs
    pop ds
    mov dx, offset timer_handler
    int 21h
    
    ; ОПТИМИЗАЦИЯ: прямая установка Scroll Lock
    push 40h
    pop es
    or byte ptr es:[17h], 10h         ; Включаем Scroll Lock одной операцией
    
    ; Завершение как TSR с минимальным размером
    mov ax, 3100h
    mov dx, (offset install_handler - offset start + 15) / 16  ; Точный расчет размера
    int 21h

END start
