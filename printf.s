
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
;Destr: RCX, RDX
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

    mov ah, [rbx + rcx]

    cmp ah, '%'                 ; if char == %
    je processArg

    cmp ah, 0h                  ; if char == 0
    je endLoop


    mov [Buffer + rdx], ah      ; load char to buff
    inc rcx
    inc rdx
    jmp processCharLoop

;----------------------
    jmp processArgEnd
    processArg:
    inc rcx
    mov ah, [rbx + rcx]

    cmp ah, '%'
    jg percentEnd
    mov [Buffer + rdx], ah
    inc rcx
    inc rdx
    jmp processCharLoop
    percentEnd:


    sub rax, 62h            ; sub ascii('b')
    shl rax, 3d
    add rax, jumpTable
    inc rcx
    inc rdx

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




    endLoop:
;-=-=-=-=-=-=-=-=-=-=
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

Buffer:     db "0000000000000000"
formatLine: db "meow %% meow %%", 0ah, 0h
