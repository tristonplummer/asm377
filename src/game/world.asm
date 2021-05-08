; The tick rate of the game world.
g_gameTickRate  equ 600

; Declare external functions
extern usleep

; Starts the game world.
start_game_world:
    push rbp
    mov rbp, rsp

    ; Start the game tick.
    jmp game_tick
    mov rsp, rbp
    pop rbp
    ret

; Represents the game tick.
game_tick:
    ; Store the start timestamp in rcx
    call current_timestamp_milli
    mov rcx, rax
    push rcx

    ; Process the game tick
    call game_tick_process

    ; Get the duration of the tick
    call current_timestamp_milli
    pop rcx
    sub rax, rcx

    ; If the tick took longer than 600ms, start the next tick straight away
    cmp rax, g_gameTickRate
    jge game_tick

    ; Calculate how long we should sleep for.
    mov rcx, g_gameTickRate
    sub rcx, rax
    imul rcx, 1000
    mov rdi, rcx
    call usleep
    jmp game_tick

; Runs the required functions for the game tick.
game_tick_process:
    push rbp
    mov rbp, rsp
    sub rsp, 8  ; Align the stack to 16-bytes

    mov rsp, rbp
    pop rbp
    ret