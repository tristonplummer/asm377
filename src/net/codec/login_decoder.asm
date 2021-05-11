; External functions
extern rand

; The state of the login decoder.
decode_login_handshake_state    equ 0
decode_login_header_state       equ 1
decode_login_payload_state      equ 2

; Login constants
status_exchange_data            equ 0
status_rejected_session         equ 11
login_type_connect              equ 16
login_type_reconnect            equ 18
server_seed                     equ 1234

; A jump table containing the different functions to execute depending on decoder state.
decode_login_message_states:
    dq decode_login_message_handshake_state
    dq decode_login_message_header_state
    dq decode_login_message_payload_state

; The number of login state values.
decode_login_state_qty  equ ($ - decode_login_message_states) / 8

; The state of the decoder instance.
struc login_decoder_state
    .state:             resd 1
    .username_hash:     resb 1
    .payload_length:    resb 1
    .server_seed:       resq 1
endstruc

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

    ; Load the state of the decoder.
    mov eax, dword [rdi+client.decoder_state]
    test eax, eax
    jne .execute_decoder

    ; Allocate the state
    push rdi
    mov rdi, login_decoder_state_size
    call malloc
    xor rdi, rdi
    mov dword [rax], edi
    pop rdi
    mov dword [rdi+client.decoder_state], eax
.execute_decoder:
    mov eax, dword [rax]
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

    ; Load the decoder state
    xor rcx, rcx
    mov ecx, dword [rdi+client.decoder_state]

    ; Read the username hash.
    call rsbuffer_read_byte
    mov byte [rcx+login_decoder_state.username_hash], al

    ; Increment the decoder state
    inc dword [rcx]

    ; Prepare the handshake response.
    xor rax, rax
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
    sub rsp, 8

    ; Ensure there are at least 2 bytes to read.
    cmp dword [rcx+rsbuffer.remaining], 2
    jl .exit

    ; Read the login type.
    call rsbuffer_read_byte
    cmp al, login_type_connect
    je .continue
    cmp al, login_type_reconnect
    je .continue

    ; Reject the session.
    mov rsi, status_rejected_session
    call write_response_code
    jmp .exit
.continue:
    ; Read the length of the login payload
    call rsbuffer_read_byte

    ; Load the decoder state and store the payload length.
    push rcx
    xor rcx, rcx
    mov ecx, dword [rdi+client.decoder_state]
    mov byte [rcx+login_decoder_state.payload_length], al
    inc dword [rcx]
    pop rcx

    ; Read the payload of the login message.
    call decode_login_message_payload_state
.exit:
    mov rsp, rbp
    pop rbp
    ret

; Decode the payload state of the login message.
decode_login_message_payload_state:
    push rbp
    mov rbp, rsp
    sub rsp, 8

    ; Read the version
    call rsbuffer_read_byte

    ; Read the revision
    call rsbuffer_read_short
    mov rdi, g_usernameHashMsg
    mov rsi, rax
    call printf

.exit:
    mov rsp, rbp
    pop rbp
    ret

; A helper function to write a response code to a client, and then close the socket.
;
; Usage:
; mov rdi, client
; mov rsi, code
; call write_response_code
write_response_code:
    push rbp
    mov rbp, rsp
    push rdi

    ; Write the response code onto the stack.
    dec rsp
    mov byte [rsp], sil

    ; Write the response code to the client.
    mov edi, dword [rdi+client.socket]
    mov rsi, rsp
    mov rdx, 1
    call write

    ; Close the socket.
    call close_socket

    pop rdi
    mov rsp, rbp
    pop rbp
    ret