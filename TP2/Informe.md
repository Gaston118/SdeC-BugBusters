# UNIVERSIDAD NACIONAL DE CÓRDOBA
# FACULTAD DE CIENCIAS EXACTAS, FÍSICAS Y NATURALES

## SISTEMAS DE COMPUTACIÓN	
## Trabajo Práctico N°2: Índice GINI con Python → C → ASM
### Grupo: BugBusters

- Alfici Facundo
- Capdevila Gastón
- Viberti Tomas

### Docentes
- Jorge, Javier Alejandro
- Solinas, Miguel

### 2026

---

## Descripción
 
Implementación de una arquitectura de capas para consultar y procesar el índice GINI del Banco Mundial. 
La capa superior (Python) consume una API REST, pasa los datos a una capa intermedia (C), que invoca una rutina en ASM 
para realizar la conversión de `double` a entero y sumarle 1, devolviendo el resultado a través de la cadena de capas.

## Arquitectura

```
Python (API Banco Mundial)
    ↓  
C (capa intermedia: gini_calc.c)
    ↓  
ASM (gini.asm)
    ↓ 
C → Python (muestra resultados)
```

## Estructura del proyecto

```
TP2/
├── gini.asm          ← rutina ASM 
├── gini_stub.c       ← reemplazo temporal si no hay .asm
├── gini_calc.c       ← capa intermedia C
├── gini_calc.h       ← header
├── main.py           ← capa superior Python
├── main_debug.c      ← programa C puro para depurar con GDB
└── Makefile
```

## Requisitos

```bash
sudo apt install nasm gcc python3-venv python3-pip gdb
```

## Comandos disponibles

```bash
make            # compilar ASM/stub + C → libgini.so
make deps       # crear venv + instalar requests
make run        # deps + compile + ejecutar Python
make debug      # compilar binario de debug para GDB (-g3 -O0)
make clean      # borrar objetos y binarios
make clean-all  # borrar todo incluyendo venv
```
---

## API REST — Banco Mundial
 
**Endpoint consultado:**
```
https://api.worldbank.org/v2/en/country/all/indicator/SI.POV.GINI
  ?format=json&date=2011:2020&per_page=32500&page=1
```

---

## Flujo completo
 
```
1. Python consulta la API → recibe value
2. Python llama: lib.calcular_gini
3. C recibe el double
4. C llama: gini_convert
5. ASM
6. C recibe en RAX, lo retorna a Python
7. Python imprime
```

<img width="613" height="390" alt="image" src="https://github.com/user-attachments/assets/463b2820-9fe0-4bd5-8338-40ddff55a365" />

---

## Sesión GDB

### 1. Compilar el binario de debug

```bash
make debug
# genera: ./debug_gini  (con -g3 -O0 -no-pie)
```

### 2. Iniciar GDB

```bash
gdb ./debug_gini
```

<img width="1160" height="628" alt="image" src="https://github.com/user-attachments/assets/fcb201c3-9c1a-4f70-a59a-370e70a0e9f1" />


### 3. Poner breakpoints

```gdb
# Breakpoint ANTES de la llamada al ASM
break main_debug.c:44

# Breakpoint DENTRO de gini_convert (antes del prólogo)
break gini_convert

# Ejecutar
run
```

<img width="1854" height="376" alt="image" src="https://github.com/user-attachments/assets/d8444196-1a2f-41c1-8aa9-98f878c5bcb3" />


### 4. ANTES de la llamada 

```gdb
# Ver todos los registros
info registers
```

### 5. Continuar hasta entrar a gini_convert

```gdb
continue
```

<img width="772" height="476" alt="image" src="https://github.com/user-attachments/assets/2234bc25-f163-4c25-bd86-0a04c05644eb" />


### 6. DURANTE la llamada

```gdb
# Avanzar instrucción por instrucción en ASM
stepi     # ejecuta: push rbp
stepi     # ejecuta: mov rbp, rsp
stepi     # ejecuta: cvttsd2si rax, xmm0
stepi     # ejecuta: add rax, 1

# Ver XMM0
info registers xmm0

# Ver RAX
info registers rax

# Ver el stack frame actual
info frame

# Ver backtrace
backtrace
```

### 7. DESPUÉS de la llamada

```gdb
# Continuar hasta volver a main
finish

# Verificar que RAX tiene el resultado
print $rax

# Verificar que RBP y RSP se restauraron correctamente
info registers rbp rsp
```

<img width="922" height="236" alt="image" src="https://github.com/user-attachments/assets/e7590227-80ae-4cae-8882-bf3e79039798" />


### 8. Comandos GDB útiles

| Comando             | Descripción                                  |
|---------------------|----------------------------------------------|
| `info registers`    | Todos los registros de propósito general     |
| `info registers xmm0` | Ver registro de punto flotante             |
| `x/8xg $rsp`        | 8 giant words del stack en hex               |
| `x/20xw $rsp`       | 20 words de 4 bytes del stack                |
| `info frame`        | Resumen del stack frame actual               |
| `backtrace` / `bt`  | Cadena de llamadas                           |
| `disassemble`       | Assembly de la función actual                |
| `stepi` / `si`      | Avanzar una instrucción ASM                  |
| `nexti` / `ni`      | Avanzar sin entrar a funciones               |
| `finish`            | Ejecutar hasta que retorne la función actual |
| `print $rax`        | Imprimir valor de un registro                |
| `layout regs`       | Modo TUI: registros en tiempo real           |
| `layout asm`        | Modo TUI: assembly en tiempo real            |
