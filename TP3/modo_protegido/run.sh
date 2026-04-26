#!/bin/bash

# compilar
as --32 -g boot.S -o boot.o
ld -m elf_i386 -Ttext 0x7C00 --oformat binary boot.o -o boot.bin

# correr QEMU en background
qemu-system-i386 -drive format=raw,file=boot.bin -S -s &
QEMU_PID=$!

# abrir GDB ya configurado
gdb -ex "target remote localhost:1234" \
    -ex "add-symbol-file boot.o 0x7C00" \
    -ex "b protected_mode" \
    -ex "b print_loop if $al == 0"