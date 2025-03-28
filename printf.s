
;-------------------CONSTS-------------------------------------------------------
BuffSize equ 10h           ; max buffer size
;--------------------------------------------------------------------------------

section .text
global meowprint

;================================================================================
; Comm: main func.
;================================================================================
meowprint:
    pop r15                 ; ret addr

    push r9
    push r8
    push rcx
    push rdx
    push rsi
    push rdi

    pop rbx

    push rbp
    mov rbp, rsp

    call fillBuff
    call printBuff
    ;call exitProg

    pop rbp

    add rsp, 40d
    push r15

    ret
;================================================================================



;================================================================================
;Comm: main func
;In: format line RBX
;Destr: a lot
;================================================================================
fillBuff:

    xor r13, r13
    xor rdx, rdx
    ;mov rbx, formatLine

;-=-=-=-=-=-=-=-=-=-=
    processCharLoop:
    xor rax, rax

    cmp rdx, BuffSize            ; if buffsize >= maxsize
    jge emptyBuff

    mov al, [rbx + r13]

    cmp al, '%'                 ; if char == %
    je processArg

    cmp al, 0h                  ; if char == 0
    je endLoop


    mov [Buffer + rdx], al      ; load char to buff
    inc r13
    inc rdx
    jmp processCharLoop

;----------------------
    jmp processArgEnd
    processArg:
    inc r13
    mov al, [rbx + r13]

    cmp al, '%'
    jg percentEnd
    mov [Buffer + rdx], al
    inc r13
    inc rdx
    jmp processCharLoop
    percentEnd:

    inc r13

    mov r11, Buffer
    jmp [8 * (rax - 'b') + jumpTable]

    processArgEnd:
;----------------------



;----------------------
    jmp emptyBuffEnd
    emptyBuff:

    push r13
    call printBuff
    pop r13
    xor rdx, rdx                ; rdx = 0
    jmp processCharLoop

    emptyBuffEnd:
;----------------------

    printBin:
        mov rsi, [rbp + 8]
        add rbp, 8h
        mov cl, 01h
        mov rdi, 1h
        call printNum
        jmp processCharLoop

    printChar:
        mov r10, [rbp + 8]
        add rbp, 8h
        call putChar
        jmp processCharLoop

    printDec:
        mov rsi, [rbp + 8]
        add rbp, 8h
        call printNumDec
        jmp processCharLoop

    printHex:
        mov rsi, [rbp + 8]
        add rbp, 8h
        mov cl, 04h
        mov rdi, 0fh
        call printNum
        jmp processCharLoop

    printOct:
        mov rsi, [rbp + 8]
        add rbp, 8h
        mov cl, 03h
        mov rdi, 7h
        call printNum
        jmp processCharLoop

    printStr:
        push rax
        push rbx
        push rdi

        mov rsi, [rbp + 8]
        add rbp, 8h
        call printString

        pop rdi
        pop rbx
        pop rax

        jmp processCharLoop

    endLoop:
;-=-=-=-=-=-=-=-=-=-=
    ret

;================================================================================



;================================================================================
;Comm: prints num to buffer, in decimal.
;In: R11 + RDX - place in buffer,  RSI - number
;Destr: RAX, RBX, RDX, RDI, R12, R10
;================================================================================
printNumDec:
    push rbx

    mov r12, rsi
    and r12, 0xf0000000
    cmp r12, 0xf0000000
    jne skipMinus
    xor rsi, -1d
    inc rsi

    mov r10, '-'
    call putChar

    skipMinus:

    xor r12, r12
    xor rcx, rcx
    mov rbx, rdx
    xor rdx, rdx
    xor rax, rax
    mov rdi, 10d

    loopNumDec:
        xor rdx, rdx
        mov rax, rsi
        div rdi
        mov rsi, rax

        mov r10, rdx
        add r10, alphabet

        xor rax, rax
        mov al, [r10]
        mov r10b, al

        mov [digitBuff + rcx], r10b
        inc rcx

        cmp rsi, 0h
        jne loopNumDec


    mov rdx, rbx
    loopGetDigNumDec:
        mov r10b, [digitBuff + rcx - 1]
        call putChar

        ;dec r12
        ;cmp r12, 0h
        ;jne loopGetDigNumDec
        loop loopGetDigNumDec

    pop rbx
    ret

;================================================================================



;================================================================================
;Comm: prints '0' terminated string to STDOUT.
;In: RSI - ptr to string.
;Destr: RAX, RDI, RDX, RBX
;================================================================================
printString:
    xor rbx, rbx
    call getStrLen ; RCX - len

    cmp rcx, BuffSize
    jl smallStr

    push rcx
    push rsi
    call printBuff
    pop rsi
    pop rcx

    mov rdx, rcx
    mov rax, 0x01
    mov rdi, 1
    syscall

    jmp smallStrEnd
    smallStr:

    mov r10b, [rsi + rbx]
    inc rbx
    call putChar
    cmp rbx, rcx
    jne smallStr

    smallStrEnd:

    ret

;================================================================================



;================================================================================
;Comm: gets length of '0' terminated string.
;In: RSI - ptr to string.
;Out: RDX - length
;Destr: RDX
;================================================================================
getStrLen:
    xor rcx, rcx

    loopStrLen:
        cmp byte [rsi + rcx], 0h
        je loopStrLenEnd
        inc rcx
        jmp loopStrLen

    loopStrLenEnd:
    ret

;================================================================================



;================================================================================
;Comm: prints num to buffer, in different notations.
;In: R11 + RDX - place in buffer,  RSI - number, CL - shift (power of 2), RDI - notaion (mask) - 1 (1, 7, 15)
;Destr: RAX, RDX, R8, R12
;================================================================================
printNum:

    mainPrnt:
        xor r12, r12

    loopPrnt:
        mov rax, rsi
        and rax, rdi

        mov r10, rax
        add r10, alphabet

        xor rax, rax            ;printing char
        mov al, [r10]
        mov r10b, al

        mov [digitBuff + r12], r10b
        inc r12

        shr rsi, cl

        cmp rsi, 0h
        jne loopPrnt

    mov rcx, r12
    loopGetDigNum:
        mov r10b, [digitBuff + rcx - 1]
        call putChar

        loop loopGetDigNum


    pNumEnd:
    ret

;================================================================================




;================================================================================
;Comm: prints one char to buff, clears and prints the buffer if it is full.
;Comm: saves RCX, might destr other regs
;In: R11 - buff, RDX - current pos in buff, R10 - char to print.
;Destr: RAX, RDI, RSI, RDX
;================================================================================
putChar:
    cmp rdx, BuffSize
    je clearBuff

    mov [r11 + rdx], r10b
    inc rdx

    jmp endClearBuff

    clearBuff:
    push rax
    push rbx
    push rcx
    push rdi
    push rsi
    push r10
    push r11

    call printBuff

    pop r11
    pop r10
    pop rsi
    pop rdi
    pop rcx
    pop rbx
    pop rax

    xor rdx, rdx
    call putChar

    endClearBuff:

    ret

;================================================================================



;================================================================================
;Comm: prints buffer to STDOUT, symbol count printed is BuffSize.
;In: RDX - chars to print.
;Destr: RAX, RDI, RSI.
;================================================================================
printBuff:
    mov rax, 0x01           ; write64 (rdi, rsi, rdx)
    mov rdi, 1              ; stdout
    mov rsi, Buffer         ; buffer
    syscall

    ret

;================================================================================





;================================================================================
;Comm: exits the programm with exit code 0.
;Destr: RAX, RDI.
;================================================================================
exitProg:
    mov rax, 0x3c           ; func to exit
    xor rdi, rdi            ; exit code
    syscall

    ret

;==================================================================================


section     .data

Buffer:     times BuffSize db "0"
digitBuff:  times 64d      db "0"
;additionalBuff:            db "0"
;String:     db "wiwiwi", 0h
;formatLine1: db "s:%s, c:%c, b:%b, o:%o, x:%h, d:%d", 0ah, 0
;formatLine: db "%d", 0ah, 0
alphabet:   db "0123456789abcdef"

section     .rodata

    align 8
    jumpTable:
        dq printBin    ; 0      'b'
        dq printChar   ; 1      'c'
        dq printDec    ; 2      'd'
        times 3d dq 0h ; 'h' - 'd' - 1
        dq printHex    ; 6      'h'
        times 6d dq 0h ; 'o' - 'h' - 1
        dq printOct    ; 13     'o'
        times 3d dq 0h ; 's' - 'o' - 1
        dq printStr    ; 17     's'
;----------------------
