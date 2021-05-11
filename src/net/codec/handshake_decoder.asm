SERVICE_GAME    equ 14  ; The game service.
SERVICE_JS5     equ 15  ; The JS5 service.

; Decodes an incoming handshake message.
;
; Usage:
; mov rdi, client
; call decode_handshake_message
decode_handshake_message:
    push rbp
    mov rbp, rsp

    ; Get the pointer to the receive buffer.
    mov rcx, [rdi+client.recv_buf]
    cmp dword [rcx+rsbuffer.size], 2
    jl .exit

    ; Read the handshake service id.
    call rsbuffer_read_byte
    cmp al, SERVICE_GAME
    je .game
    cmp al, SERVICE_JS5
    je .js5
    jmp .close

.game:
    ; Decode the game handshake.
    mov qword [rdi+client.decoder], decode_login_message
    call decode_login_message
    jmp .exit
.js5:
    jmp .exit

.close:
    jmp .exit

.exit:
    mov rsp, rbp
    pop rbp
    ret