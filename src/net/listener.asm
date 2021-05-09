; Declare external functions.
extern socket
extern htons
extern bind
extern listen
extern pthread_create
extern epoll_create1
extern epoll_ctl
extern epoll_wait

; Socket-related constants
AF_INET         equ 2
SOCK_STREAM     equ 1
BACKLOG_SIZE    equ 512

; Epoll constants
EPOLLIN         equ 0x001
EPOLLRDHUP      equ 0x2000
EPOLLET         equ 0x80000000
EPOLL_CTL_ADD   equ 1
EPOLL_MAXEVENTS equ 128

; The sockaddr struct
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

    ; Listen for connections
    mov rsi, BACKLOG_SIZE
    call listen
    test rax, rax
    jne .fail

    ; Register the socket to be polled for events
    mov rdi, (EPOLLIN | EPOLLRDHUP | EPOLLET)
    mov rsi, qword [g_epollDescriptor]
    mov rdx, qword [g_socket]
    call epoll_register
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

; Register events for epoll
;
; Usage:
; mov rdi, events
; mov rsi, epoll_descriptor
; mov rdx, socket
; call epoll_register
epoll_register:
    push rbp
    mov rbp, rsp
    sub rsp, epoll_event_size

    ; Set up the event structure
    mov [rsp+epoll_event.events], rdi
    mov [rsp+epoll_event.fd], rdx

    ; Register for epoll
    mov rdi, rsi
    mov rsi, EPOLL_CTL_ADD
    mov rcx, rsp
    call epoll_ctl
    cmp rax, -1
    je .fail
    mov rax, 1
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

    ; If the file descriptor is our local socket, accept the connection
    mov rsi, qword [g_socket]
    cmp dword [rcx+epoll_event.fd], esi
    jne .check_recv_data
    call accept_socket
    jmp .event_loop

.check_recv_data:
    ; Check if we should read incoming data
    and rdx, EPOLLIN
    jne .check_closed

    call read_data
    jmp .event_loop
.check_closed:
    and rdx, EPOLLRDHUP
    jne .event_loop

    ; Close the socket
    mov rdi, [rcx+epoll_event.fd]
    call close_socket
    jmp .event_loop
.exit:
    mov rsp, rbp
    pop rbp
    ret

; Accepts a socket
accept_socket:
    push rbp
    mov rbp, rsp
    sub rsp, 8

    mov rdi, g_acceptConMsg
    call printf

    mov rsp, rbp
    pop rbp
    ret

; Reads data from a remote socket
read_data:
    push rbp
    mov rbp, rsp

    mov rdi, g_readDataMsg
    call printf

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

    mov rdi, g_closeSocketMsg
    call printf

    mov rsp, rbp
    pop rbp
    ret