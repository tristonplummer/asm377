; Constants
; =====================================
section .rodata
g_gameInitMessage       db  "Initialising asm377...", 10, 0
g_dwGamePort            dw  43594
g_listenMsg             db  "Listening on port %d...", 10, 0
g_netFailMsg            db  "Failed to listen on port %d (perhaps a server is already running?)", 10, 0
g_acceptConMsg          db  "Accept new connection", 10, 0
g_readDataMsg           db  "Read data from socket", 10, 0
g_closeSocketMsg        db  "Close socket", 10, 0
g_acceptFailedMsg       db  "Accept socket failed", 10, 0
g_acceptSuccessMsg      db  "Accepted connection from %s.", 10, 0

; Mutable global data
; =====================================
section .data
g_socket                dq 0
g_epollDescriptor       dq 0