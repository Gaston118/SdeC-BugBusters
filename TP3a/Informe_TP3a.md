---

<div align="center">

# Universidad Nacional de Córdoba
## Facultad de Ciencias Exactas, Físicas y Naturales

---

### Sistemas de Computación
# Trabajo Práctico N°3a
## Entorno UEFI, Desarrollo y Análisis de Seguridad

**Grupo:** BugBusters

| Integrantes |
|:----------:|
| Alfici, Facundo |
| Capdevila, Gastón |
| Viberti, Tomás |

**Docentes**

| |
|:---:|
| Jorge, Javier Alejandro |
| Solinas, Miguel |

**2026**

</div>

---

# Objetivo General 
Comprender la arquitectura de la Interfaz de Firmware Extensible Unificada (UEFI) como un entorno pre-sistema operativo, 
desarrollar binarios nativos, entender su formato y ejecutar rutinas tanto en entornos emulados como en hardware físico (bare metal).

**1 → Instalar dependencias** (QEMU, OVMF, gnu-efi, Ghidra)

**2 → TP1:** Arrancar la UEFI Shell y explorar handles, protocolos y memoria

**3 → TP2:** Escribir, compilar y analizar app en C

**4 → TP3:** Pasarla a un USB y ejecutarla en bare metal

---

## Instalar dependencias

```bash
sudo apt update
sudo apt install -y qemu-system-x86 ovmf gnu-efi build-essential binutils-mingw-w64
```

Esto instala:
- `qemu-system-x86` → el emulador de PC
- `ovmf` → el firmware UEFI que QEMU va a usar como "BIOS"
- `gnu-efi` → headers y librerías para compilar apps UEFI en C
- `build-essential` → gcc, make, etc.

**Verificar que OVMF quedó instalado:**

```bash
find /usr/share -iname "OVMF.fd" 2>/dev/null
```
Debería aparecer algo como `/usr/share/ovmf/OVMF.fd`.

**Instalar Ghidra:**

```bash
sudo apt install -y ghidra || sudo snap install ghidra --classic
```

---

## PARTE 1 Exploración del entorno UEFI y la Shell

### Arrancar la UEFI Shell

**Lanzar QEMU con el firmware UEFI:**

```bash
qemu-system-x86_64 -m 512 -bios /usr/share/ovmf/OVMF.fd -net none
```

> Como no hay ningún disco con OS, después de unos segundos debería caer automáticamente a la UEFI Shell.

<img width="1273" height="855" alt="image" src="https://github.com/user-attachments/assets/a036039f-a1f1-4b8a-a3d7-429f2ba6d436" />


### Handles y Protocolos

**Comando 1:**
```
Shell> map
```
Esto lista los "file systems" y dispositivos que UEFI detectó. 

<img width="379" height="86" alt="image" src="https://github.com/user-attachments/assets/3b41f4b6-2211-4713-8c6b-0b1fc0843578" />

> Solo apareció **BLK0** (sin FS0). Eso significa que UEFI detectó el disco virtual de QEMU como un dispositivo de bloque crudo, pero **no tiene un sistema de archivos FAT32** que UEFI pueda montar.
> Es normal porque no le pasamos ningún disco con datos a QEMU.

**Comando 2:**
```
Shell> dh -b
```
Lista **todos** los handles del sistema con sus protocolos asociados.

<img width="871" height="659" alt="image" src="https://github.com/user-attachments/assets/6fa1b7aa-05aa-4069-a4a6-7e6eddbd3976" />

| Handle | Qué es |
|--------|--------|
| `01` | `LoadedImage(DxeCore)` → el núcleo de la fase DXE cargado en memoria |
| `06` | `DevicePathFromText / DevicePathToText` → servicios para convertir rutas de dispositivo |
| `0D` | `RuntimeArch` → protocolo que provee los Runtime Services al OS |
| `0F` | `SecurityArch / Security2Arch` → el protocolo de Secure Boot |
| `14` | `CpuIo2` → acceso directo a puertos I/O del CPU |
| `16` | `CpuArch` → abstracción de la arquitectura del procesador |

### Pregunta de Razonamiento 1

**¿Cuál es la ventaja de este modelo frente al BIOS antiguo?**

El BIOS legacy accedía al hardware mediante **direcciones fijas e interrupciones hardcodeadas** (INT 13h para disco, INT 10h para video). Si el hardware cambiaba, el BIOS se rompía.

UEFI en cambio usa esta **base de datos de handles + protocolos**: cualquier driver publica un protocolo con un GUID, y cualquier otro componente lo descubre dinámicamente en runtime. Ventajas concretas:

- **Compatibilidad**: agregar hardware nuevo = agregar un driver que publica su protocolo, sin tocar el resto
- **Seguridad**: podés auditar exactamente qué protocolos están activos (como viste con `SecurityArch`)
- **Aislamiento**: un driver no necesita saber la dirección física del hardware, solo consume la interfaz

### Variables NVRAM

En la shell:
```
Shell> dmpstore -b
```

<img width="683" height="631" alt="image" src="https://github.com/user-attachments/assets/b1a6b137-d1df-4ed6-af7d-15919429a748" />

<img width="691" height="643" alt="image" src="https://github.com/user-attachments/assets/c272bd0a-4508-4087-a238-8297667e02ad" />

<img width="691" height="641" alt="image" src="https://github.com/user-attachments/assets/7c40b728-3af6-4ecc-b456-16dc27e2d44e" />

```
Shell> set TestSeguridad "Hola UEFI"
Shell> set -v
```

<img width="409" height="240" alt="image" src="https://github.com/user-attachments/assets/decd7d76-516a-4cc7-8bb5-506f071c10bc" />

### Pregunta de Razonamiento 2

**¿Cómo determina el Boot Manager la secuencia de arranque?**

1. Lee `BootOrder` de NVRAM → obtiene la lista ordenada `[0000, 0001, ...]`
2. Por cada índice, carga la variable `Boot####` correspondiente
3. Cada `Boot####` contiene: descripción, ruta del dispositivo y argumentos opcionales
4. Intenta cargar cada entrada en orden hasta que una tenga éxito
5. Si todas fallan, cae a la UEFI Shell

### Mapa de memoria

```
Shell> memmap -b
```

<img width="665" height="623" alt="image" src="https://github.com/user-attachments/assets/7fac85f8-c3bb-4cb9-8b83-6a28d2454549" />

<img width="679" height="635" alt="image" src="https://github.com/user-attachments/assets/2e77acc4-9de5-4342-b9d0-bac813af4a9c" />

<img width="704" height="640" alt="image" src="https://github.com/user-attachments/assets/8d3f725e-f575-415d-8f40-56543095d3d8" />

Los tipos de región que aparecen:

| Tipo | Qué significa |
|------|---------------|
| `Available` | RAM libre, el OS puede usarla |
| `BS_Code` | Código de drivers de Boot Services (se libera al llamar ExitBootServices) |
| `BS_Data` | Datos de Boot Services (ídem) |
| `LoaderCode` | El código del bootloader |
| `ACPI_NVS` | Memoria reservada para ACPI, el OS no puede tocarla |
| `RT_Data` | **Datos de Runtime Services** — persisten después de cargar el OS |

```
Shell> pci -b
```

<img width="583" height="286" alt="image" src="https://github.com/user-attachments/assets/59f177e2-e1b5-427c-9efc-3656351f29ee" />

```
Shell> drivers -b
```

<img width="711" height="672" alt="image" src="https://github.com/user-attachments/assets/f3e3a8df-47a7-472a-9969-a57216e25b43" />

<img width="655" height="632" alt="image" src="https://github.com/user-attachments/assets/7529db52-818b-4db2-bab7-12cf1fb341c5" />

### Pregunta de Razonamiento 3

**¿Por qué `RuntimeServicesCode` es objetivo principal de bootkits?**

Porque es la **única memoria del firmware que sobrevive después de que arranca el OS**.

Cuando el bootloader llama a `ExitBootServices()`, toda la memoria `BS_Code` y `BS_Data` se libera. Pero las regiones `RT_Code` y `RT_Data` **permanecen mapeadas en el espacio de direcciones del OS** porque el kernel las necesita para llamar funciones como `GetVariable()`, `SetVariable()` o `GetTime()`.

Un bootkit que logre modificar código en esas regiones (por ejemplo, hookeando `SetVariable`) consigue:
- **Ejecución en ring 0** cada vez que el OS llama un Runtime Service
- **Persistencia total**: sobrevive reinstalaciones del OS porque vive en el firmware
- **Invisibilidad**: el OS no puede detectar código que corre antes que él

---

## PARTE 2 Desarrollo, compilación y análisis de seguridad

<img width="1561" height="863" alt="image" src="https://github.com/user-attachments/assets/f1a9884c-853b-4513-ad99-31720608781c" />

| Sección | Qué contiene |
|---------|-------------|
| `.text` | El código máquina de tu `efi_main` y las funciones de gnuefi |
| `.reloc` | Las **relocation fix-ups** — le dicen al loader cómo ajustar direcciones cuando carga el binario en memoria arbitraria |
| `.data` | Variables globales y strings (como `L"Iniciando analisis..."`) |
| `.dynamic` | Info para el linker dinámico de UEFI |
| `.rela` | Tabla de relocaciones con addends |
| `.dynsym` | Tabla de símbolos dinámicos |

### Pregunta de Razonamiento 4

**¿Por qué usamos `SystemTable->ConOut->OutputString` en lugar de `printf`?**

Porque en el entorno pre-OS **no existe la libc**. `printf` depende de:
- El sistema operativo para escribir en stdout
- La libc (`glibc`) para formatear strings

En UEFI no hay ninguno de los dos. En cambio, `ConOut` es el protocolo `SimpleTextOutput` que UEFI expone a través de la System Table — es la única forma estándar de escribir en pantalla antes de que exista un OS. Por eso compilamos con `-ffreestanding` (sin libc).

### Ghidra

<img width="789" height="762" alt="image" src="https://github.com/user-attachments/assets/d2d6ccc2-4dd2-42bf-8889-4f0e13d459eb" />

<img width="1636" height="933" alt="image" src="https://github.com/user-attachments/assets/42caeed6-c985-468a-9602-5fb19a91f5b7" />

<img width="1629" height="820" alt="image" src="https://github.com/user-attachments/assets/79aacd2c-afb1-445b-ab18-9a7873b629e5" />

<img width="1634" height="933" alt="image" src="https://github.com/user-attachments/assets/de8238bb-a7cd-4f26-868e-81ee8d5a682e" />

### Pregunta de Razonamiento 5

**¿Por qué `0xCC` suele aparecer como `-52` en Ghidra?**

Porque Ghidra interpreta el byte `0xCC` como un entero con **signo** (signed char). En binario:

```
0xCC = 1100 1100
```

En complemento a dos de 8 bits, cuando el bit más significativo es `1`, el número es negativo:

```
0xCC como unsigned = 204
0xCC como signed   = 204 - 256 = -52
```

**Por qué importa en ciberseguridad:** `0xCC` es el opcode de la instrucción **INT3** — el software breakpoint del x86. Los debuggers lo usan para pausar la ejecución. Si un analista ve `-52` en pseudocódigo y no reconoce que es `0xCC`, puede pasar por alto que el binario tiene lógica de detección de debugging o anti-análisis. Es una técnica usada en malware para detectar si está siendo analizado.

> Aunque en el análisis con Ghidra, la condición `if (code[0] == 0xCC)` no aparece explícitamente en el pseudocódigo porque el compilador (gcc) la optimizó: como `code[]` se inicializa con `{ 0xCC }` y se compara inmediatamente con `0xCC`, la condición es **siempre verdadera** en tiempo de compilación, por lo que gcc eliminó el branch y dejó solo el cuerpo del `if`.

---

## PARTE 3 Ejecución en Hardware Físico (BareMetal)
