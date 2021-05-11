; Define external functions
extern malloc

; Represents a connected client.
struc client
    .socket:        resd 1      ; The socket file descriptor.
    .addr:          resb 17     ; The remote address.
    .decoder:       resq 1      ; Pointer to the message decoder.
    .decoder_state: resd 1      ; The state of the decoder.
    .recv_buf:      resq 1      ; Pointer to the receive buffer.
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
    sub rsp, 8

    ; Store the client on the stack.
    mov qword [rsp], rdi

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
    mov dword [rdi+client.decoder_state], eax

    ; Allocate the receive buffer.
    mov rdi, rsbuffer_size
    call malloc
    mov rdi, qword [rsp]
    mov qword [rdi+client.recv_buf], rax

    ; Initialise the receive buffer.
    mov rdi, rax
    mov rsi, rsbuffer_default_size
    call rsbuffer_constructor

    mov rdi, qword [rsp]
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