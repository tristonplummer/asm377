; The state of the login decoder.
decode_login_handshake_state    equ 0
decode_login_header_state       equ 1
decode_login_payload_state      equ 2

; Login constants
status_exchange_data            equ 0
server_seed                     equ 1234

; A jump table containing the different functions to execute depending on decoder state.
decode_login_message_states:
    dq decode_login_message_handshake_state
    dq decode_login_message_header_state
    dq decode_login_message_payload_state

; The number of login state values.
decode_login_state_qty  equ ($ - decode_login_message_states) / 8

; Decodes an incoming login request.
;
; Usage:
; mov rdi, client
; call decode_login_message
decode_login_message:
    push rbp
    mov rbp, rsp
    push rsi

    ; Get the pointer to the receive buffer.
    xor rax, rax
    mov rcx, [rdi+client.recv_buf]

    ; Call the login decode state function.
    mov eax, dword [rdi+client.decoder_state]
    cmp eax, decode_login_state_qty
    jge .exit
    mov rsi, qword [decode_login_message_states+eax*8]
    call rsi
.exit:
    pop rsi
    mov rsp, rbp
    pop rbp
    ret

; Decode the handshake state of the login message.
decode_login_message_handshake_state:
    push rbp
    mov rbp, rsp
    sub rsp, 17 ; Allocate 17 bytes on the stack for the response.

    ; If there are no bytes to be read, exit
    cmp dword [rcx+rsbuffer.remaining], 1
    jl .exit

    ; Read the username hash.
    call rsbuffer_read_byte
    xor rax, rax

    ; Increment the decoder state
    inc dword [rdi+client.decoder_state]

    ; Prepare the handshake response.
    mov byte [rsp], status_exchange_data
    mov qword [rsp+1], rax
    mov qword [rsp+9], server_seed

    ; Write the response to the client.
    mov edi, dword [rdi+client.socket]
    mov rsi, rsp    ; The response payload.
    mov rdx, 17     ; The length of the response
    call write
.exit:
    mov rsp, rbp
    pop rbp
    ret

; Decode the header state of the login message.
decode_login_message_header_state:
    push rbp
    mov rbp, rsp

    mov rsp, rbp
    pop rbp
    ret

; Decode the payload state of the login message.
decode_login_message_payload_state:
    push rbp
    mov rbp, rsp

    mov rsp, rbp
    pop rbp
    ret