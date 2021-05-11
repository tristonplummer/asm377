rsbuffer_default_size   equ 1024    ; The default size of a RSBuffer.

; External functions
extern memmove
extern memcpy

; A ByteBuffer implementation.
struc rsbuffer
    .data:      resq 1
    .size:      resd 1
    .position:  resd 1
    .capacity:  resd 1
endstruc

; Initialises the rsbuffer structure.
;
; Usage:
; mov rdi, buffer
; mov rsi, size
; call rsbuffer_constructor
rsbuffer_constructor:
    push rbp
    mov rbp, rsp

    ; Define the capacity.
    mov dword [rdi+rsbuffer.capacity], esi

    ; Initialise the data.
    push rdi
    mov rdi, rsi
    call malloc
    pop rdi
    mov qword [rdi+rsbuffer.data], rax

    ; Zero out the position and size.
    xor rax, rax
    mov dword [rdi+rsbuffer.size], eax
    mov dword [rdi+rsbuffer.position], eax

    mov rsp, rbp
    pop rbp
    ret

; Writes bytes to an rsbuffer. This returns the number of bytes written in rax.
;
; Usage:
; mov rdi, buffer
; mov rsi, bytes
; mov rdx, length
; call rsbuffer_write_bytes
rsbuffer_write_bytes:
    push rbp
    mov rbp, rsp
    push rcx
.validate:
    ; If the length is greater than the capacity, fail
    cmp edx, dword [rdi+rsbuffer.capacity]
    jge .fail

    ; If there is not enough space, we should compact the buffer.
    mov eax, dword [rdi+rsbuffer.capacity]
    sub eax, dword [rdi+rsbuffer.position]
    cmp eax, edx
    jl .compact
    jmp .write
.compact:
    call rsbuffer_compact
    jmp .validate
.write:
    ; Write the bytes to the buffer data.
    mov eax, dword [rdi+rsbuffer.position]
    mov rcx, qword [rdi+rsbuffer.data]
    lea rcx, [rcx+rax]

    ; Copy the data
    push rdi
    mov rdi, rcx
    call memcpy
    pop rdi

    ; Increase the size.
    mov rax, rdx
    mov edx, dword [rdi+rsbuffer.size]
    add rdx, rax
    mov dword [rdi+rsbuffer.size], edx
    jmp .exit
.fail:
    xor rax, rax
.exit:
    pop rcx
    mov rsp, rbp
    pop rbp
    ret

; Compacts the buffer. This works by moving all of the data from the current position to
; the start of the buffer.
;
; Usage:
; mov rdi, buffer
; call rsbuffer_compact
rsbuffer_compact:
    push rbp
    mov rbp, rsp
    push rcx
    xor rax, rax

    ; Load the position into ecx
    mov ecx, dword [edi+rsbuffer.position]

    ; Calculate the number of bytes.
    mov eax, dword [edi+rsbuffer.capacity]
    sub eax, ecx

    ; Move the data to the start.
    push rdi
    push rax
    mov rdi, qword [edi+rsbuffer.data]
    lea rsi, [rdi+rcx]
    mov rdx, rax
    call memmove
    pop rdi
    pop rax

    ; Set the position.
    mov dword [rdi+rsbuffer.position], eax

    pop rcx
    mov rsp, rbp
    pop rbp
    ret