; Constants
; =====================================
section .rodata
g_gameInitMessage       db  "Initialising asm377...", 10, 0
g_dwGamePort            dw  43594
g_listenMsg             db  "Listening on port %d...", 10, 0
g_netFailMsg            db  "Failed to listen on port %d (perhaps a server is already running?)", 10, 0
g_acceptConMsg          db  "Accept new connection", 10, 0
g_readDataMsg           db  "Read data from socket", 10, 0
g_acceptFailedMsg       db  "Accept socket failed", 10, 0
g_acceptSuccessMsg      db  "Accepted connection from %s.", 10, 0
g_readMsg               db  "Read %d bytes from client %#08x (%s).", 10, 0
g_usernameHashMsg       db  "The username hash is %d.", 10, 0
g_maxUsers              dd  2048
g_rsaCertPath           db  "data/game.pem", 0
g_readFileFlags         db  "rb", 0
g_rsaModulusMsg         db  "========= Public RSA Details =========", 10
                        db  "Modulus=%s", 10
                        db  "Exponent=%s", 10
                        db  "======================================", 10, 0

; Mutable global data
; =====================================
section .data
g_socket                dq 0
g_epollDescriptor       dq 0
g_clientSize            dd 0    ; The number of connected clients.
g_clientList            dq 0    ; A list of clients, where the socket fd is the index.
g_rsaPrivateKey         dq 0    ; The RSA private key.