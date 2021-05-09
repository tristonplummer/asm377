; Declare external functions.
extern socket
extern htons
extern bind
extern listen
extern pthread_create
extern epoll_create1
extern epoll_ctl
extern epoll_wait
extern fcntl
extern accept
extern inet_ntop

; Socket-related constants
AF_INET         equ 2
SOCK_STREAM     equ 1
BACKLOG_SIZE    equ 512

; Epoll constants
EPOLLIN         equ 0x001
EPOLLHUP        equ 0x10
EPOLLRDHUP      equ 0x2000
EPOLLET         equ 0x80000000
EPOLL_CTL_ADD   equ 1
EPOLL_MAXEVENTS equ 128

; Fnctl constants
F_GETFD         equ 1       ; Get file descriptor
F_SETFD         equ 2       ; Set file descriptor
O_NONBLOCK      equ 0x4000  ; Non blocking flag

; The sockaddr_in struct
struc sockaddr_in
    .sin_family:    resw 1
    .sin_port:      resw 1
    .sin_addr:      resd 1
    .sin_pad:       resb 8
endstruc

; The epoll_event struct
struc epoll_event
    .events:        resd 1
    .ptr:           resd 1
    .fd:            resd 1
    .u32:           resd 1
    .u64:           resq 1
endstruc

; Initialise the network socket.
init_network:
    push rbp
    mov rbp, rsp

    ; Allocate space for required local variables
    sub rsp, sockaddr_in_size

    ; Register an epoll descriptor
    xor rdi, rdi
    call epoll_create1
    cmp rax, -1
    je .fail
    mov [g_epollDescriptor], rax

    ; Create a socket
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    xor rdx, rdx
    call socket
    test rax, rax
    je .fail
    mov [g_socket], rax

    ; Assign ip address and port to the local socket address.
    xor rax, rax
    mov word [rsp+sockaddr_in.sin_family], AF_INET
    mov dword [rsp+sockaddr_in.sin_addr], eax ; Any address
    mov di, word [g_dwGamePort]
    call htons
    mov word [rsp+sockaddr_in.sin_port], ax

    ; Bind the socket
    mov rdi, qword [g_socket]   ; Socket descriptor
    mov rsi, rsp                ; sockaddr_in
    mov rdx, sockaddr_in_size
    call bind
    test rax, rax
    jne .fail

    ; Set the socket as non-blocking
    call set_non_blocking

    ; Listen for connections
    mov rsi, BACKLOG_SIZE
    call listen
    test rax, rax
    jne .fail

    ; Register the socket to be polled for events
    mov rdi, qword [g_epollDescriptor]
    mov rsi, qword [g_socket]
    mov rdx, (EPOLLIN | EPOLLRDHUP | EPOLLET)
    call epoll_ctl_add
    test rax, rax
    je .fail

    ; Print a message confirming the state of the network
    mov rdi, g_listenMsg
    mov si, word [g_dwGamePort]
    call printf

    ; Create a thread for operating on network events
    mov rdi, rsp
    xor rsi, rsi
    mov rdx, start_network
    xor rcx, rcx
    call pthread_create
    mov rax, 1
    jmp .exit
.fail:
    xor rax, rax
.exit:
    mov rsp, rbp
    pop rbp
    ret

; Starts operating on network events.
start_network:
    push rbp
    mov rbp, rsp
.loop:
    mov rdi, qword [g_epollDescriptor]
    mov rcx, 100
    call epoll_monitor
    jmp .loop

    mov rsp, rbp
    pop rbp
    ret

; Registers epoll events for a file descriptor.
;
; Usage:
; mov rdi, epoll_descriptor
; mov rsi, file_descriptor
; mov rdx, flags
; call epoll_ctl_add
epoll_ctl_add:
    push rbp
    mov rbp, rsp
    sub rsp, epoll_event_size

    ; Set up the event structure
    mov [rsp+epoll_event.events], rdx
    mov [rsp+epoll_event.fd], rsi

    ; Register for epoll
    mov rdx, rsi
    mov rsi, EPOLL_CTL_ADD
    mov rcx, rsp
    call epoll_ctl
    cmp rax, -1
    je .fail
    mov al, 1
    jmp .exit
.fail:
    xor rax, rax
.exit:
    mov rsp, rbp
    pop rbp
    ret

; Sets a socket as non-blocking.
;
; Usage:
; mov rdi, socket
; call set_non_blocking
set_non_blocking:
    push rbp
    mov rbp, rsp

    ; Get the file descriptor flags
    mov rsi, F_GETFD
    xor rdx, rdx
    call fcntl

    ; Modify the flags to include nonblocking, and set the new flags
    or rax, O_NONBLOCK
    mov rsi, F_SETFD
    mov rdx, rax
    call fcntl
    cmp rax, -1
    je .fail
    mov al, 1
    jmp .exit
.fail:
    xor rax, rax
.exit:
    mov rsp, rbp
    pop rbp
    ret

; Monitor for events.
;
; Usage:
; mov rdi, epoll_descriptor
; mov rcx, timeout
; call epoll_monitor
epoll_monitor:
    push rbp
    mov rbp, rsp
    sub rsp, (epoll_event_size * EPOLL_MAXEVENTS)

    ; Wait for events
    mov rsi, rsp
    mov rdx, EPOLL_MAXEVENTS
    call epoll_wait

.event_loop:
    ; If there are no events to process, exit
    test rax, rax
    je .exit
    dec rax

    ; Load the event
    mov rdx, rax
    imul rdx, epoll_event_size
    lea rcx, [rsp+rdx]
    mov rdx, [rcx+epoll_event.events]
    push rax

    ; If the file descriptor is our local socket, accept the connection
    mov edi, dword [rcx+epoll_event.fd]
    mov rsi, qword [g_socket]
    cmp edi, esi
    jne .check_recv_data
    call accept_socket
    jmp .rerun_event_loop

.check_recv_data:
    ; Check if we should read incoming data
    and rdx, EPOLLIN
    jne .check_closed
    call read_data
    jmp .rerun_event_loop
.check_closed:
    and rdx, EPOLLRDHUP
    jne .rerun_event_loop
    call close_socket
    jmp .rerun_event_loop
.rerun_event_loop:
    pop rax
    jmp .event_loop
.exit:
    mov rsp, rbp
    pop rbp
    ret

; Accepts a socket
accept_socket:
    push rbp
    mov rbp, rsp
    sub rsp, sockaddr_in_size + 40  ; 4 bytes for the struct size, 4 bytes for the socket, 32 bytes for the address string

    ; Assign the size of the sockaddr
    mov dword [rsp+sockaddr_in_size], sockaddr_in_size

    ; Accept the remote socket.
    mov rdi, rsi
    mov rsi, rsp
    lea rdx, [rsp+sockaddr_in_size]
    call accept
    cmp rax, -1
    je .fail
    mov dword [rsp+sockaddr_in_size+4], eax

    ; Set the socket as non-blocking
    mov rdi, rax
    call set_non_blocking
    test al, al
    je .fail

    ; Add the socket to the epoll monitor
    mov rdi, qword [g_epollDescriptor]
    mov esi, dword [rsp+sockaddr_in_size+4]
    mov rdx, (EPOLLIN | EPOLLET | EPOLLRDHUP | EPOLLHUP)
    call epoll_ctl_add
    test al, al
    je .fail

    ; Convert the remote address to a string.
    mov rdi, AF_INET
    lea rsi, [rsp+sockaddr_in.sin_addr]
    lea rdx, [rsp+sockaddr_in_size+8]
    mov ecx, dword [rsp+sockaddr_in]
    call inet_ntop
    test rax, rax
    je .fail

    ; Print the address of the remote socket.
    mov rdi, g_acceptSuccessMsg
    mov rsi, rax
    call printf
    jmp .exit
.fail:
    mov rdi, g_acceptFailedMsg
    call printf
.exit:
    mov rsp, rbp
    pop rbp
    ret

; Reads data from a remote socket
read_data:
    push rbp
    mov rbp, rsp

    mov rsp, rbp
    pop rbp
    ret

; Closes a socket
;
; Usage:
; mov rdi, socket
; call close_socket
close_socket:
    push rbp
    mov rbp, rsp

    mov rsp, rbp
    pop rbp
    ret