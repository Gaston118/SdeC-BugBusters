# Makefile — TP2 GINI
# Compila: gini.asm + gini_calc.c → libgini.so (biblioteca compartida)
# Python la carga en tiempo de ejecución con ctypes.

CC            = gcc
NASM          = nasm
CFLAGS        = -Wall -fPIC             
CFLAGS_DBG    = -Wall -g3 -O0 -no-pie  
NASMFLAGS     = -f elf64              
NASMFLAGS_DBG = -f elf64 -g -F dwarf 
TARGET        = libgini.so
DEBUG_BIN     = debug_gini
VENV          = venv
PYTHON        = $(VENV)/bin/python3
PIP           = $(VENV)/bin/pip

all: $(TARGET)
	@echo "[INFO] $(TARGET) está actualizado. Usá << make clean && make >> para forzar recompilación."

# Crea el venv e instala dependencias
$(VENV)/bin/activate:
	python3 -m venv $(VENV)
	$(PIP) install --upgrade pip
	$(PIP) install requests

deps: $(VENV)/bin/activate
	@echo "[OK] Entorno virtual listo en ./$(VENV)"

# Detectar si el .asm existe para decidir qué usar
ASM_EXISTS := $(wildcard gini.asm)

ifeq ($(ASM_EXISTS), gini.asm)
    $(info [INFO] Usando rutina ASM: gini.asm)

    gini.o: gini.asm
	    $(NASM) $(NASMFLAGS) -o gini.o gini.asm

    gini_calc.o: gini_calc.c gini_calc.h
	    $(CC) $(CFLAGS) -c -o gini_calc.o gini_calc.c

    $(TARGET): gini.o gini_calc.o
	    $(CC) -shared -o $(TARGET) gini.o gini_calc.o
else
    $(info [INFO] gini.asm no encontrado — compilando con stub C)

    gini_calc.o: gini_calc.c gini_calc.h
	    $(CC) $(CFLAGS) -c -o gini_calc.o gini_calc.c

    gini_stub.o: gini_stub.c
	    $(CC) $(CFLAGS) -c -o gini_stub.o gini_stub.c

    $(TARGET): gini_calc.o gini_stub.o
	    $(CC) -shared -o $(TARGET) gini_calc.o gini_stub.o
endif

# Binario de debug para GDB (usa -g3 -O0)
debug: main_debug.c gini_calc.h
ifeq ($(ASM_EXISTS), gini.asm)
	$(info [DEBUG] Compilando con ASM real + debug flags)
	$(NASM) $(NASMFLAGS_DBG) -o gini_dbg.o gini.asm
	$(CC) $(CFLAGS_DBG) -c -o gini_calc_dbg.o gini_calc.c
	$(CC) $(CFLAGS_DBG) -c -o main_debug.o main_debug.c
	$(CC) $(CFLAGS_DBG) -o $(DEBUG_BIN) main_debug.o gini_calc_dbg.o gini_dbg.o
else
	$(info [DEBUG] Compilando con stub C + debug flags)
	$(CC) $(CFLAGS_DBG) -c -o gini_stub_dbg.o gini_stub.c
	$(CC) $(CFLAGS_DBG) -c -o gini_calc_dbg.o gini_calc.c
	$(CC) $(CFLAGS_DBG) -c -o main_debug.o main_debug.c
	$(CC) $(CFLAGS_DBG) -o $(DEBUG_BIN) main_debug.o gini_calc_dbg.o gini_stub_dbg.o
endif
	@echo "[OK] Binario de debug listo: ./$(DEBUG_BIN)"
	@echo "     Ejecutar con: gdb ./$(DEBUG_BIN)"

# Ejecutar 
run: deps $(TARGET)
	$(PYTHON) main.py

# Limpieza 
clean:
	rm -f *.o $(TARGET)

clean-all: clean
	rm -rf $(VENV)

.PHONY: all deps run clean clean-all
