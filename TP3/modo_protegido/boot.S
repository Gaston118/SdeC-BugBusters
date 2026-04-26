.code16
.global _start

_start:
    cli

    # -------------------------
    # Habilitar A20
    # -------------------------
    inb $0x92, %al
    orb $0x02, %al
    outb %al, $0x92

    # -------------------------
    # Cargar GDT
    # -------------------------
    lgdt gdt_descriptor

    # -------------------------
    # Activar modo protegido
    # -------------------------
    movl %cr0, %eax
    orl $0x1, %eax
    movl %eax, %cr0

    # Salto lejano
    ljmp $0x08, $protected_mode

# =============================
# MODO PROTEGIDO
# =============================
.code32
protected_mode:
    movw $0x10, %ax
    movw %ax, %ds
    movw %ax, %es
    movw %ax, %ss
    movw %ax, %fs
    movw %ax, %gs

    movl $0x90000, %esp

    call clear_screen     # limpiar pantalla

    # -------------------------
    # Escribir mensaje en VGA
    # -------------------------
    movl $0xB8000, %edi
    movl $message, %esi
    cld

print_loop:
    lodsb
    cmpb $0, %al
    je done

    movb $0x0F, %ah
    stosw
    jmp print_loop

done:
    jmp done

# =============================
# LIMPIAR PANTALLA
# =============================
clear_screen:
    movl $0xB8000, %edi
    movl $80*25, %ecx
    movw $0x0720, %ax     

clear_loop:
    stosw
    loop clear_loop
    ret

# =============================
# MENSAJE
# =============================
message:
    .asciz "Grupo: BugBusters"

# =============================
# GDT
# =============================
.align 8
gdt_start:
    .quad 0x0000000000000000
    .quad 0x00CF9A000000FFFF
    .quad 0x00CF92000000FFFF
gdt_end:

gdt_descriptor:
    .word gdt_end - gdt_start - 1
    .long gdt_start

# =============================
# BOOT SIGNATURE
# =============================
.org 510
.word 0xAA55