; External functions
extern fopen
extern fclose
extern OPENSSL_init_ssl
extern PEM_read_RSAPrivateKey   ; https://www.openssl.org/docs/man1.1.1/man3/PEM_read_RSAPrivateKey.html
extern RSA_get0_n               ; https://www.openssl.org/docs/man1.1.1/man3/RSA_get0_n.html
extern RSA_get0_e               ; https://www.openssl.org/docs/man1.1.1/man3/RSA_get0_e.html
extern BN_bn2dec                ; https://www.openssl.org/docs/man1.1.1/man3/BN_bn2dec.html

; Loads the RSA certificate from the disk. Returns 0 if the file was not found, or if some error occurred.
load_rsa_certificate:
    push rbp
    mov rbp, rsp
    sub rsp, 32

    ; Open the certificate file.
    mov rdi, g_rsaCertPath
    mov rsi, g_readFileFlags
    call fopen
    test rax, rax
    je .exit
    mov qword [rsp], rax    ; Store the file handle.

    ; Read the private key.
    mov rdi, qword [rsp]
    xor rsi, rsi
    xor rdx, rdx
    xor rcx, rcx
    call PEM_read_RSAPrivateKey
    test rax, rax
    je .exit
    mov qword [g_rsaPrivateKey], rax

    ; Close the file
    mov rdi, qword [rsp]
    call fclose
    mov al, 1

    ; Print out the RSA details.
    mov rdi, qword [g_rsaPrivateKey]
    call RSA_get0_n
    mov rdi, rax
    call BN_bn2dec
    mov rsi, rax
    push rsi
    mov rdi, qword [g_rsaPrivateKey]
    call RSA_get0_e
    mov rdi, rax
    call BN_bn2dec
    mov rdx, rax
    mov rdi, g_rsaModulusMsg
    pop rsi
    call printf
.exit:
    mov rsp, rbp
    pop rbp
    ret