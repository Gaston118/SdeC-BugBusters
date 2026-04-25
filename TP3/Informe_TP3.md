# UNIVERSIDAD NACIONAL DE CÓRDOBA
# FACULTAD DE CIENCIAS EXACTAS, FÍSICAS Y NATURALES

## SISTEMAS DE COMPUTACIÓN	
## Trabajo Práctico N°3: Modo Protegido
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
 
El objetivo es entender la transición del procesador desde un estado de compatibilidad absoluta llamado "Modo Real" a uno de gestión avanzada llamado "Modo Protegido". Durante el desarrollo del trabajo se ejecutará código que permite llevar el procesador de un modo al otro.

## Apartado teórico

### *UEFI*
#### **Qué es UEFI? Como se puede usar? Mencionar además una función a la que podría llamar usando esa dinámica.**

UEFI (Unified Extensible Firmware Interface) es la especificación moderna que reemplaza al BIOS tradicional. A diferencia del BIOS, UEFI funciona en Modo Protegido o Modo Largo (64 bits) desde el arranque, permitiendo direccionar más memoria y utilizar una interfaz más compleja. Se usa mediante Servicios de Sistema (System Services) que las aplicaciones o cargadores de arranque invocan mediante tablas de punteros. Una función típica a la que se podría llamar es gRT->GetTime() para obtener el tiempo real del sistema o funciones de salida como Print().

#### Menciona casos de bugs de UEFI que puedan ser explotados

Al ser un entorno de software complejo, es susceptible a vulnerabilidades como LogoFAIL (donde se inyecta código malicioso a través del parser de la imagen del logo del fabricante) o BlackLotus, el primer bootkit de UEFI que logra evadir el Secure Boot.

#### Qué es Converged Security and Managment Engine (CSME), the Intel Management Engine BIOS Extension (Intel MEBx)?

* CSME (Converged Security and Management Engine): Es un subsistema autónomo basado en un procesador dentro del CPU de Intel que maneja la seguridad, el arranque y la criptografía del sistema.

* Intel MEBx: Es la extensión de la BIOS que permite configurar los parámetros de administración y seguridad del motor de Intel, generalmente usada para gestión remota (vPro).

#### Qué es Coreboot? Que productos lo incorporan? Cuales son las ventajas de su utilización?

Es un proyecto de software libre que busca reemplazar el firmware propietario por una solución mínima y transparente.

* Productos: Es utilizado en Chromebooks de Google y laptops orientadas a la privacidad como las de System76 o Purism.
* Ventajas: Ofrece mayor velocidad de arranque (solo inicializa lo estrictamente necesario), mayor seguridad al ser auditable y elimina las "cajas negras" del firmware propietario.

### *Linker*
#### Qué es un linker? Qué hace?

Es la herramienta encargada de combinar múltiples archivos objeto (.o) en un solo archivo ejecutable. Sus tareas principales son la resolución de símbolos y la relocalización, asegurando que todas las llamadas a funciones y variables apunten a las direcciones de memoria correctas.

#### Qué es la dirección que aparece en el script del linker? Por qué es necesaria?

Es la dirección base de carga (ej. 0x7C00 para un bootsector o la dirección especificada por la directiva . = 0x...). Es necesaria porque el linker debe calcular todas las direcciones de salto (jump) y accesos a datos basándose en el lugar exacto de la RAM donde el código residirá finalmente.

#### Para qué se utiliza la opción --oformat binary en el linker?

Se utiliza para generar un archivo binario puro, sin encabezados ni metadatos (como los de un archivo ELF o PE). En el desarrollo de bajo nivel (Bare Metal), el hardware no entiende de formatos de archivos; solo necesita los bytes de las instrucciones de máquina uno tras otro.

### *Modo Protegido*
#### Cómo sería un programa que tenga dos descriptores de memoria diferentes, uno para cada segmento (código y datos) en espacios de memoria diferenciados?

Para diferenciar código y datos, se deben crear dos entradas en la GDT (Global Descriptor Table). Ambos pueden tener la misma base (0x00000000) y límite (4 GB), pero se diferencian en sus Atributos:
* Segmento de Código (CS): Atributo de tipo "Ejecutable/Lectura".
* *Segmento de Datos (DS): Atributo de tipo "Lectura/Escritura".

#### Cambiar los bits de acceso del segmento de datos para que sea de solo lectura, intentar escribir, qué sucede? Qué debería suceder a continuación? Verificar con gbd

Si se modifica el atributo del segmento de datos a Solo Lectura y se intenta escribir el hardware bloquea la operación. Luego se dispara una Excepción de Protección General (#GP). En GDB se observa que la ejecución se detiene exactamente en la instrucción mov que intentó escribir, y los registros de estado indicarán la falta de privilegios de escritura.

#### En modo protegido, con qué valor se cargan los registros de segmento? Por qué?

En este modo los registros (CS, DS, etc) se cargan con un Selector. Esto es así porque ya no contienen una dirección base directamente como en modo real (donde se multiplicaba por 16). En modo protegido, el selector actúa como un índice para buscar en la tabla de descriptores (GDT) los parámetros reales de base, límite y atributos del segmento.

## Apartado práctico: Modo protegido
1. Creación de imagen booteable
Se ejecutó el comando 'printf '\364%509s\125\252' > main.img'. Desglose del comando:
* \364: Es el valor octal del opcode 0xF4, que corresponde a la instrucción de ensamblador HLT (Halt). Esto hace que el procesador se detenga apenas arranque.
* %509s: Le dice al comando que inserte 509 espacios en blanco. Esto es necesario para rellenar el archivo hasta el byte 510.
* \125\252: Son los valores octales de 0x55 y 0xAA. Juntos forman la firma de arranque obligatoria en los últimos dos bytes (511 y 512) del sector. Si estos bytes no están presentes, la BIOS no considerará el disco como arrancable.

<img width="678" height="468" alt="image" src="https://github.com/user-attachments/assets/7b476fbe-fd1b-4508-b074-55b60af73d98" />

Para comprobar si los bytes creados en el comando están en el orden correcto se utiliza el comando ´hd main.img´.

<img width="678" height="468" alt="image" src="https://github.com/user-attachments/assets/21709c1e-4b45-4c73-81c6-a93cced8a42d" />

Para comprobar quer funciona, ejecutamos la imagen con el emulador QEMU mediante el comando 'qemu-system-x86_64 --drive file=main.img,format=raw,index=0,media=disk'.
<img width="685" height="465" alt="image" src="https://github.com/user-attachments/assets/949b0900-9e72-4f45-8683-24c11384bc51" />

<img width="696" height="471" alt="image" src="https://github.com/user-attachments/assets/f54f72cc-ae47-4d5d-9d97-7bf026d461a5" />




