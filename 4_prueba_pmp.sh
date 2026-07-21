#!/bin/bash
# ============================================================
#  PRUEBA MEDIANO PLAZO  —  PMP.prc (4 sticks: 16/16/32/64)
#  Uso:  ./4_prueba_pmp.sh              (script clásico)
#        ./4_prueba_pmp.sh PMP_v2.prc   (variante nueva, SLEEPs de 8000)
#  ⌨️  Tipear en la terminal "IO STDIN" cuando pida (8 pedidos de 16 chars).
# ============================================================

TP_DIR="$HOME/tp-2026-1c-kernelitos"
PRUEBAS_DIR="$HOME/plug-n-pray-pruebas"
SCRIPT_INICIAL="${1:-PMP.prc}"

[ -d "$TP_DIR" ] || { echo "ERROR: no existe $TP_DIR (editá TP_DIR arriba)"; exit 1; }
[ -f "$PRUEBAS_DIR/$SCRIPT_INICIAL" ] || { echo "ERROR: no existe $PRUEBAS_DIR/$SCRIPT_INICIAL"; exit 1; }

pkill -f kernel_memory; pkill -f kernel_scheduler; pkill -f memory_stick
pkill -f "bin/cpu"; pkill -f "bin/io"; pkill -f "bin/swap"
sleep 1

# ---------- Sticks 1-4 (puertos 8003-8006) ----------
cd "$TP_DIR/memory_stick" || exit 1
for i in 1 2 3 4; do
    [ -f "stick$i.config" ] || cp stick.config "stick$i.config"
done
sed -i 's|PUERTO_STICK.*|PUERTO_STICK=8003|' stick1.config
sed -i 's|PUERTO_STICK.*|PUERTO_STICK=8004|' stick2.config
sed -i 's|PUERTO_STICK.*|PUERTO_STICK=8005|' stick3.config
sed -i 's|PUERTO_STICK.*|PUERTO_STICK=8006|' stick4.config
sed -i 's|MEMORY_DELAY.*|MEMORY_DELAY=1500|' stick*.config
# Nota del PDF: con MEMORY_DELAY=1000 e INSTRUCTION_DELAY=250 es más determinístico.

# ---------- Configs (sed automático; para inspeccionar a mano: nano <archivo>) ----------
sed -i 's|PLANIFICATION_ALGORITHM.*|PLANIFICATION_ALGORITHM=CMN|;
        s|QUEUES_ALGORITHMS.*|QUEUES_ALGORITHMS=[FIFO,FIFO,FIFO,FIFO]|;
        s|RR_QUANTUM.*|RR_QUANTUM=1500|;
        s|QUEUE_PREEMPTION.*|QUEUE_PREEMPTION=TRUE|;
        s|SUSPENSION_TIMEOUT.*|SUSPENSION_TIMEOUT=10000|' "$TP_DIR/kernel_scheduler/kernelScheduler.config"

sed -i 's|SEGMENT_MAX_SIZE.*|SEGMENT_MAX_SIZE=128|;
        s|ALLOCATION_STRATEGY.*|ALLOCATION_STRATEGY=BEST|;
        s|INSTRUCTION_DELAY.*|INSTRUCTION_DELAY=500|;
        s|COMPACTION_DELAY.*|COMPACTION_DELAY=30000|' "$TP_DIR/kernel_memory/memory.config"

sed -i "s|SCRIPTS_BASEPATH.*|SCRIPTS_BASEPATH=$PRUEBAS_DIR|" "$TP_DIR/kernel_memory/memory.config"

sed -i 's|SEGMENT_MAX_SIZE.*|SEGMENT_MAX_SIZE=128|' "$TP_DIR"/cpu/cpu*.config

# --- Red: MODO CASA (localhost). 🏫 En el LAB, reemplazar por las IPs reales ---
sed -i 's|IP_MEMORIA.*|IP_MEMORIA=127.0.0.1|;s|IP_PROPIA.*|IP_PROPIA=127.0.0.1|' "$TP_DIR"/memory_stick/stick*.config
sed -i 's|IP_MEMORIA.*|IP_MEMORIA=127.0.0.1|' "$TP_DIR/kernel_scheduler/kernelScheduler.config" "$TP_DIR/swap/swap.config" 2>/dev/null
sed -i 's|IP_KERNEL_MEMORY.*|IP_KERNEL_MEMORY=127.0.0.1|;s|IP_SCHEDULER.*|IP_SCHEDULER=127.0.0.1|' "$TP_DIR"/cpu/cpu*.config
sed -i 's|IP_SCHEDULER.*|IP_SCHEDULER=127.0.0.1|' "$TP_DIR/io/io.config"

echo "== Configs aplicadas =="
grep -H "QUEUES_ALGORITHMS\|SUSPENSION_TIMEOUT" "$TP_DIR/kernel_scheduler/kernelScheduler.config"

echo "== Compilando =="
for MOD in utils kernel_memory kernel_scheduler memory_stick cpu io swap; do
    ( cd "$TP_DIR/$MOD" && make clean >/dev/null && make ) || { echo "❌ ERROR compilando $MOD"; exit 1; }
done
echo "✅ Compilación OK"

abrir_terminal() {
    local TITULO="$1"; local CMD="$2"
    if command -v x-terminal-emulator >/dev/null 2>&1; then
        x-terminal-emulator -T "$TITULO" -e "bash -c '$CMD; exec bash'" &
    elif command -v xfce4-terminal >/dev/null 2>&1; then
        xfce4-terminal --title="$TITULO" -x bash -c "$CMD; exec bash" &
    elif command -v gnome-terminal >/dev/null 2>&1; then
        gnome-terminal --title="$TITULO" -- bash -c "$CMD; exec bash" &
    elif command -v lxterminal >/dev/null 2>&1; then
        lxterminal -T "$TITULO" -e "bash -c '$CMD; exec bash'" &
    else
        xterm -T "$TITULO" -e bash -c "$CMD; exec bash" &
    fi
}

echo "== Lanzando módulos =="
abrir_terminal "1-KERNEL MEMORY" "cd $TP_DIR/kernel_memory && ./bin/kernel_memory memory.config"
sleep 3
abrir_terminal "2-SWAP" "cd $TP_DIR/swap && ./bin/swap swap.config"
sleep 2
abrir_terminal "3-STICK1 (16)" "cd $TP_DIR/memory_stick && ./bin/memory_stick stick1.config 16"
sleep 1
abrir_terminal "3-STICK2 (16)" "cd $TP_DIR/memory_stick && ./bin/memory_stick stick2.config 16"
sleep 1
abrir_terminal "3-STICK3 (32)" "cd $TP_DIR/memory_stick && ./bin/memory_stick stick3.config 32"
sleep 1
abrir_terminal "3-STICK4 (64)" "cd $TP_DIR/memory_stick && ./bin/memory_stick stick4.config 64"
sleep 2
abrir_terminal "4-SCHEDULER [$SCRIPT_INICIAL]" "cd $TP_DIR/kernel_scheduler && ./bin/kernel_scheduler kernelScheduler.config $SCRIPT_INICIAL"
sleep 2
abrir_terminal "5-IO SLEEP"  "cd $TP_DIR/io && ./bin/io io.config SLEEP"
sleep 1
abrir_terminal "⌨️ 5-IO STDIN (TIPEAR ACA)" "cd $TP_DIR/io && ./bin/io io.config STDIN"
sleep 1
abrir_terminal "5-IO STDOUT" "cd $TP_DIR/io && ./bin/io io.config STDOUT"
sleep 2
abrir_terminal "6-CPU 1" "cd $TP_DIR/cpu && ./bin/cpu cpu.config 1"

# Monitor del camino de swap (el semáforo del protocolo estricto)
sleep 1
abrir_terminal "👁 MONITOR SWAP" "tail -f $TP_DIR/kernel_memory/kernelMemory.log | grep --line-buffered -i 'suspendido\\|SWAP\\|Error al traducir'"

echo ""
echo "🚀 PMP lanzada con $SCRIPT_INICIAL — 8 STDINs: PID1 x4, PID2 x2, PID3 x2 (16 chars c/u)."
echo "   PROTOCOLO ESTRICTO (valida el fix del swap): en el PRIMER pedido de cada PID,"
echo "   escribí el texto y ESPERÁ ver 'suspendido en SWAP' en el MONITOR antes del Enter."
echo "   Éxito: 'Escritura en SWAP (proceso suspendido)', cero 'Error al traducir',"
echo "   8 textos intactos por STDOUT y 5 EXITs. Termina sola (~6 min, tiene SLEEPs de 60s)."
echo "   Cortar con:  pkill -f kernel_memory; pkill -f kernel_scheduler; pkill -f memory_stick; pkill -f 'bin/cpu'; pkill -f 'bin/io'; pkill -f 'bin/swap'"