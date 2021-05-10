; Define external functions
extern malloc

; Represents a connected client.
struc client
    .socket:    resd 1  ; The socket file descriptor.
    .addr:      resb 17 ; The remote address.
    .decoder:   resq 1  ; Pointer to the message decoder.
endstruc

; Constructs the client.
;
; Usage:
; mov rdi, client
; mov rsi, socket
; mov rdx, remote_address
; call client_constructor
client_constructor:
    push rbp
    mov rbp, rsp
    push rsi

    ; Assign the socket.
    mov dword [rdi], esi

    ; Copy the remote address
    mov rax, [rdx]
    mov [rdi+client.addr], rax
    mov rax, [rdx + 8]
    mov [rdi+client.addr + 8], rax
    mov byte [rdi+client.addr+16], 0   ; Null terminator
    xor rax, rax

    ; Default initialise the codec.
    mov qword [rdi+client.decoder], decode_handshake_message

    pop rsi
    mov rsp, rbp
    pop rbp
    ret

; Destroys the client.
;
; Usage:
; mov rdi, client
; call client_destructor
client_destructor:
    push rbp
    mov rbp, rsp

    mov rsp, rbp
    pop rbp
    ret