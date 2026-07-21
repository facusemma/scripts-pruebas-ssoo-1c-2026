# Scripts de pruebas — Plug & Pray (kernelitos)

Un script por prueba del PDF. Cada uno: mata instancias previas → aplica los configs de la prueba → compila todo (`make clean && make`) → abre **una terminal por módulo** en el orden correcto (KM → SWAP → sticks → Scheduler → IOs → CPUs) con pausas entre cada uno.

## Instalación (una sola vez)

```bash
mkdir -p ~/Desktop/scripts-pruebas
# copiar los 6 .sh a esa carpeta, y después:
cd ~/Desktop/scripts-pruebas && chmod +x *.sh
```

⚠️ **Antes de la primera corrida**, abrí cualquiera de los scripts y verificá las dos rutas de arriba:
- `TP_DIR` → la carpeta real del TP (por defecto: `~/Desktop/tp-2026-1c-kernelitos`)
- `PRUEBAS_DIR` → el clon del repo de scripts de la cátedra (por defecto: `~/plug-n-pray-pruebas`)

## Uso

| Prueba | Comando | Notas |
|---|---|---|
| Base parte 1 | `./1_prueba_base.sh` | 6 EXITs esperados |
| Base parte 2 | `./1_prueba_base.sh MEMORIA_PRE_0.prc` | SEG_FAULT del PID 1 = intencional; tipear "holamundo" |
| Corto Plazo | `./2_prueba_pcp.sh` | NO termina sola (loops por diseño) |
| Memoria BEST | `./3_prueba_memoria.sh` | sin compactación |
| Memoria WORST | `./3_prueba_memoria.sh WORST` | compacta (~45s de espera) |
| Mediano Plazo | `./4_prueba_pmp.sh` (o `PMP_v2.prc`) | tipear en la terminal "IO STDIN"; abre monitor de swap |
| Herencia | `./5_prueba_php.sh` | quedan los 5 PHP_3 rotando = correcto |
| Estabilidad | `./6_prueba_estabilidad.sh [ES3_x.prc] [nºCPUs]` | config sugerida; abre htop |

## Notas

- **¿Por qué sed y no nano?** nano es interactivo: frenaría el script esperando a un humano. El sed aplica los valores exactos del PDF automáticamente, y cada script imprime el resumen de lo aplicado para verificar a ojo. Si querés revisar a mano: `nano <archivo>.config` después de correr el script.
- **Red:** los scripts dejan todo en `127.0.0.1` (**modo casa**). Para el laboratorio, las líneas de IPs están marcadas con 🏫 — reemplazar por las IPs reales de cada máquina.
- **Terminales:** la función `abrir_terminal` prueba xfce4-terminal → gnome-terminal → lxterminal → xterm. Si en tu VM las ventanas no abren, avisá qué terminal usás y se ajusta la función.
- **Matar todo** (también lo imprime cada script al final):
```bash
pkill -f kernel_memory; pkill -f kernel_scheduler; pkill -f memory_stick; pkill -f "bin/cpu"; pkill -f "bin/io"; pkill -f "bin/swap"
```
