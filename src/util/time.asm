; Declare external functions
extern gettimeofday

; Represents the C timeval struct (https://man7.org/linux/man-pages/man2/gettimeofday.2.html)
struc timeval
    .tv_sec     resq    1   ; Seconds
    .tv_usec    resq    1   ; Microseconds
endstruc

; A helper function for retrieving the current timestamp, in milliseconds.
current_timestamp_milli:
    push rbp
    mov rbp, rsp

    sub rsp, timeval_size   ; Allocate space for the timeval struct.
    mov rdi, rsp
    xor rsi, rsi
    call gettimeofday

    ; Calculate milliseconds
    xor rax, rax
    xor rdx, rdx
    mov rcx, 1000
    mov rax, qword [rsp+timeval.tv_usec]
    div rcx
    mov rcx, qword [rsp+timeval.tv_sec]
    imul rcx, 1000
    add rax, rcx

    mov rsp, rbp
    pop rbp
    ret