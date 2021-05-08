%include "src/data.asm"
default rel

; Declare external functions.
extern printf

; Code section.
section .text
    global main

; Include other files.
%include "src/game/world.asm"
%include "src/net/listener.asm"
%include "src/util/time.asm"

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
