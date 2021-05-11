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
    .remaining: resd 1
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
    xor rdx, rdx

    ; Assign the number of remaining bytes.
    push rdi
    mov edx, dword [rdi+rsbuffer.position]
    mov esi, dword [rdi+rsbuffer.size]
    sub esi, edx
    mov dword [rdi+rsbuffer.remaining], esi
    pop rdi
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
    push rdx
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

    pop rdx
    pop rcx
    mov rsp, rbp
    pop rbp
    ret

; Skips a number of bytes in the buffer.
;
; Usage:
; mov rcx, buffer
; mov rsi, quantity
; call rsbuffer_skip_bytes
rsbuffer_skip_bytes:
    push rbp
    mov rbp, rsp

    add dword [rcx+rsbuffer.position], esi
    sub dword [rcx+rsbuffer.remaining], esi

    mov rsp, rbp
    pop rbp
    ret

; Read a byte from the buffer. The byte is returned in al.
;
; Usage:
; mov rcx, buffer
; call rsbuffer_read_byte
rsbuffer_read_byte:
    push rbp
    mov rbp, rsp
    push rdi
    push rsi
    xor rax, rax

    ; Read the byte.
    mov eax, dword [rcx+rsbuffer.position]
    mov rdi, qword [rcx+rsbuffer.data]
    lea rsi, [rdi+rax]
    mov al, byte [rsi]
    inc dword [rcx+rsbuffer.position]

    ; Assign the number of remaining bytes.
    mov edi, dword [rcx+rsbuffer.position]
    mov esi, dword [rcx+rsbuffer.size]
    sub esi, edi
    mov dword [rcx+rsbuffer.remaining], esi

    pop rsi
    pop rdi
    mov rsp, rbp
    pop rbp
    ret

; Read a short from the buffer. The short is returned in ax.
;
; Usage:
; mov rcx, buffer
; call rsbuffer_read_short
rsbuffer_read_short:
    push rbp
    mov rbp, rsp
    push rdi
    push rsi
    xor rax, rax

    ; Read the short as big endian.
    mov eax, dword [rcx+rsbuffer.position]
    mov rdi, qword [rcx+rsbuffer.data]
    lea rsi, [rdi+rax]
    mov ah, byte [rsi]
    mov al, byte [rsi+1]
    add dword [rcx+rsbuffer.position], 2

    ; Assign the number of remaining bytes.
    mov edi, dword [rcx+rsbuffer.position]
    mov esi, dword [rcx+rsbuffer.size]
    sub esi, edi
    mov dword [rcx+rsbuffer.remaining], esi

    pop rsi
    pop rdi
    mov rsp, rbp
    pop rbp
    ret

; Read an int from the buffer. The int is returned in eax.
;
; Usage:
; mov rcx, buffer
; call rsbuffer_read_int
rsbuffer_read_int:
    push rbp
    mov rbp, rsp
    push rdi
    push rsi
    xor rax, rax

    ; Read the int as big endian.
    mov eax, dword [rcx+rsbuffer.position]
    mov rdi, qword [rcx+rsbuffer.data]
    lea rsi, [rdi+rax]
    mov ah, byte [rsi]
    mov al, byte [rsi+1]
    add dword [rcx+rsbuffer.position], 4

    ; Assign the number of remaining bytes.
    mov edi, dword [rcx+rsbuffer.position]
    mov esi, dword [rcx+rsbuffer.size]
    sub esi, edi
    mov dword [rcx+rsbuffer.remaining], esi

    pop rsi
    pop rdi
    mov rsp, rbp
    pop rbp
    ret