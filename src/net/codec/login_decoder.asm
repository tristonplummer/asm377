; Decodes an incoming login request.
;
; Usage:
; mov rdi, client
; call decode_login_message
decode_login_message:
    push rbp
    mov rbp, rsp

    ; Get the pointer to the receive buffer.
    mov rcx, [rdi+client.recv_buf]
    cmp dword [rcx+rsbuffer.remaining], 1

    ; Get the username hash.
    call rsbuffer_read_byte
    mov rsi, rax
    mov rdi, g_usernameHashMsg
    call printf

    mov rsp, rbp
    pop rbp
    ret