; Decodes an incoming handshake message.
decode_handshake_message:
    push rbp
    mov rbp, rsp

    ; Get the pointer to the receive buffer.
    mov rcx, [rdi+client.recv_buf]

    mov rsp, rbp
    pop rbp
    ret