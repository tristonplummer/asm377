; Declare external functions.
extern socket
extern htons
extern bind
extern listen

; Socket-related constants
AF_INET         equ 2
SOCK_STREAM     equ 1
BACKLOG_SIZE    equ 512

; The sockaddr struct (https://elixir.bootlin.com/linux/latest/source/include/uapi/linux/in.h#L237)
struc sockaddr_in
    .sin_family:    resw 1
    .sin_port:      resw 1
    .sin_addr:      resd 1
    .sin_pad:       resb 8
endstruc

; Initialise the network socket.
init_network:
    push rbp
    mov rbp, rsp

    ; Allocate space for required local variables
    sub rsp, (8 + sockaddr_in_size)

    ; Create a socket
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    xor rdx, rdx
    call socket
    test rax, rax
    je .fail
    mov qword [rsp], rax

    ; Assign ip address and port to the local socket address.
    xor rax, rax
    mov word [rsp+8+sockaddr_in.sin_family], AF_INET
    mov dword [rsp+8+sockaddr_in.sin_addr], eax ; Any address
    mov di, word [g_dwGamePort]
    call htons
    mov word [rsp+8+sockaddr_in.sin_port], ax

    ; Bind the socket
    mov rdi, qword [rsp]    ; Socket descriptor
    lea rsi, [rsp+8]        ; sockaddr_in
    mov rdx, sockaddr_in_size
    call bind
    test rax, rax
    jne .fail

    ; Listen for connections
    mov rsi, BACKLOG_SIZE
    call listen
    test rax, rax
    jne .fail

    ; Print a message confirming the state of the network
    mov rdi, g_listenMsg
    mov si, word [g_dwGamePort]
    call printf
    mov rax, 1
    jmp .exit
.fail:
    xor rax, rax
.exit:
    mov rsp, rbp
    pop rbp
    ret