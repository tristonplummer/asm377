%include "src/data.asm"
default rel

; Declare external functions.
extern printf
extern signal
extern exit
extern close
extern shutdown

; Code section.
section .text
    global main

; Include other files.
%include "src/game/world.asm"
%include "src/net/listener.asm"
%include "src/util/time.asm"

; Signal constants
SIGINT  equ 2
SIGSEGV equ 11
SIGTERM equ 15

; Socket shutdown type
SHUT_RDWR   equ 2

; The entry point of the game server.
main:
    push rbp
    mov rbp, rsp

    ; Print an initialisation message.
    mov rdi, g_gameInitMessage
    call printf

    ; Initialise the network
    call init_network
    test rax, rax
    je .network_failed

    ; Register a signal handler for SIGINT and SIGTERM.
    mov rdi, SIGINT
    mov rsi, sigterm_handler
    call signal
    mov rdi, SIGTERM
    mov rsi, sigterm_handler
    call signal
    mov rdi, SIGSEGV
    mov rsi, sigterm_handler
    call signal

    ; Start the game world.
    call start_game_world

    ; EXIT_SUCCESS
    xor rax, rax
    jmp .exit

; Failed to initialise the network
.network_failed:
    xor esi, esi
    mov edi, g_netFailMsg
    mov si, word [g_dwGamePort]
    call printf
.exit:
    mov rsp, rbp
    pop rbp
    ret

; Catches a termination signal.
sigterm_handler:
    push rbp
    mov rbp, rsp

    ; Close the socket and epoll descriptor
    mov rdi, qword [g_socket]
    mov rsi, SHUT_RDWR
    call shutdown
    mov rdi, qword [g_epollDescriptor]
    call close

    ; Exit the process
    call exit

    mov rsp, rbp
    pop rbp
    ret

