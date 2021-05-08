; Constants
; =====================================
section .rodata
g_gameInitMessage       db  "Initialising asm377...", 10, 0
g_dwGamePort            dw  43594
g_listenMsg             db  "Listening on port %d...", 10, 0
g_netFailMsg            db  "Failed to listen on port %d (perhaps a server is already running?)", 10, 0

; Mutable global data
; =====================================
section .data