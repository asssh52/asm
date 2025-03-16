
;-------------------CONSTS-------------------------------------------------------
BuffSize equ 10h           ; max buffer size
strPtr   equ formatLine
;--------------------------------------------------------------------------------

section .text
global _start

;================================================================================
; Comm: main func.
;================================================================================
_start:
    call fillBuff
    call printBuff
    call exitProg
;================================================================================



;================================================================================
;Comm:
;In: format line RBX
;Destr: RAX, RCX, RDX
;================================================================================
fillBuff:

    xor rcx, rcx
    xor rdx, rdx
    mov rbx, formatLine

;-=-=-=-=-=-=-=-=-=-=
    processCharLoop:
    xor rax, rax

    cmp rdx, BuffSize            ; if buffsize >= maxsize
    jge emptyBuff

    mov al, [rbx + rcx]

    cmp al, '%'                 ; if char == %
    je processArg

    cmp al, 0h                  ; if char == 0
    je endLoop


    mov [Buffer + rdx], al      ; load char to buff
    inc rcx
    inc rdx
    jmp processCharLoop

;----------------------
    jmp processArgEnd
    processArg:
    inc rcx
    mov al, [rbx + rcx]

    cmp al, '%'
    jg percentEnd
    mov [Buffer + rdx], al
    inc rcx
    inc rdx
    jmp processCharLoop
    percentEnd:


    sub rax, 62h            ; sub ascii('b')
    shl rax, 3d
    add rax, jumpTable
    inc rcx

    jmp [rax]

    processArgEnd:
;----------------------



;----------------------
    jmp emptyBuffEnd
    emptyBuff:
                                ;!!!!!!!!! rdx > buffsize
    push rcx
    call printBuff
    pop rcx
    xor rdx, rdx                ; rdx = 0
    jmp processCharLoop

    emptyBuffEnd:
;----------------------


;----------------------
    align 8
    jumpTable:
        dq printBin





;----------------------

    printBin:
        mov r11, Buffer
        mov rsi, 0ffffh
        mov rdi, 2h
        call printNum
        jmp processCharLoop
    endLoop:
;-=-=-=-=-=-=-=-=-=-=
    ret

;================================================================================


;================================================================================
;Comm: prints num to buffer, in different notations.
;In: R11 + RDX - place in buffer,  RSI - number, RDI - notation (2, 8, 10, 16)
;Destr: RAX, R8
;================================================================================
printNum:

    cmp rdi, 2h
    je pBin

    cmp rdi, 8h
    je pOct

    ;cmp rdi, 0ah
    ;je pDec

    jmp pHex

    pBin:
        mov r8, 1h
        jmp mainPrnt

    pOct:
        mov r8, 3h
        jmp mainPrnt

    pHex:
        mov r8, 4h
        jmp mainPrnt

    mainPrnt:
        sub rdi, 1h

    loopPrnt:
        mov rax, rsi
        and rax, rdi

        mov r10, rax
        add r10, alphabet

        xor rax, rax
        mov al, [r10]
        mov r10b, al

        call putChar

        push rcx
        mov rcx, r8
        shr rsi, cl
        pop rcx

        cmp rsi, 0h
        jne loopPrnt

    pNumEnd:
    ret

;================================================================================




;================================================================================
;Comm: prints one char to buff, clears and prints the buffer if it is full.
;Comm: saves RCX, might destr other regs
;In: R11 - buff, RDX - current pos in buff, R10 - char to print.
;Destr: ?
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
formatLine: db "%b meow %b", 0ah, 0h
alphabet:   db "0123456789abcdef"
