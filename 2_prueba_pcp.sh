#!/bin/bash
# ============================================================
#  PRUEBA PLANIFICACIÓN CORTO PLAZO  —  PCP.prc
#  Uso:  ./2_prueba_pcp.sh
#  OJO: esta prueba NO termina sola (loops eternos por diseño).
#       Los EXITs esperados son 0, 5 y 6; el resto rota para siempre.
# ============================================================

TP_DIR="$HOME/tp-2026-1c-kernelitos"
PRUEBAS_DIR="$HOME/plug-n-pray-pruebas"
SCRIPT_INICIAL="PCP.prc"

[ -d "$TP_DIR" ] || { echo "ERROR: no existe $TP_DIR (editá TP_DIR arriba)"; exit 1; }
[ -f "$PRUEBAS_DIR/$SCRIPT_INICIAL" ] || { echo "ERROR: no existe $PRUEBAS_DIR/$SCRIPT_INICIAL"; exit 1; }

pkill -f kernel_memory; pkill -f kernel_scheduler; pkill -f memory_stick
pkill -f "bin/cpu"; pkill -f "bin/io"; pkill -f "bin/swap"
sleep 1

# ---------- Configs (sed automático; para inspeccionar a mano: nano <archivo>) ----------
sed -i 's|PLANIFICATION_ALGORITHM.*|PLANIFICATION_ALGORITHM=CMN|;
        s|QUEUES_ALGORITHMS.*|QUEUES_ALGORITHMS=[FIFO,RR,RR,RR]|;
        s|RR_QUANTUM.*|RR_QUANTUM=1500|;
        s|QUEUE_PREEMPTION.*|QUEUE_PREEMPTION=TRUE|;
        s|SUSPENSION_TIMEOUT.*|SUSPENSION_TIMEOUT=35000|' "$TP_DIR/kernel_scheduler/kernelScheduler.config"

sed -i 's|SEGMENT_MAX_SIZE.*|SEGMENT_MAX_SIZE=256|;
        s|ALLOCATION_STRATEGY.*|ALLOCATION_STRATEGY=BEST|;
        s|INSTRUCTION_DELAY.*|INSTRUCTION_DELAY=500|;
        s|COMPACTION_DELAY.*|COMPACTION_DELAY=30000|' "$TP_DIR/kernel_memory/memory.config"

sed -i "s|SCRIPTS_BASEPATH.*|SCRIPTS_BASEPATH=$PRUEBAS_DIR|" "$TP_DIR/kernel_memory/memory.config"

# ¡Regla de oro! SEGMENT_MAX_SIZE también en TODAS las CPUs (esta prueba usa 256)
sed -i 's|SEGMENT_MAX_SIZE.*|SEGMENT_MAX_SIZE=256|' "$TP_DIR"/cpu/cpu*.config

sed -i 's|MEMORY_DELAY.*|MEMORY_DELAY=1500|' "$TP_DIR/memory_stick/stick.config"

# --- Red: MODO CASA (localhost). 🏫 En el LAB, reemplazar por las IPs reales ---
sed -i 's|IP_MEMORIA.*|IP_MEMORIA=127.0.0.1|;s|IP_PROPIA.*|IP_PROPIA=127.0.0.1|' "$TP_DIR"/memory_stick/stick*.config
sed -i 's|IP_MEMORIA.*|IP_MEMORIA=127.0.0.1|' "$TP_DIR/kernel_scheduler/kernelScheduler.config" "$TP_DIR/swap/swap.config" 2>/dev/null
sed -i 's|IP_KERNEL_MEMORY.*|IP_KERNEL_MEMORY=127.0.0.1|;s|IP_SCHEDULER.*|IP_SCHEDULER=127.0.0.1|' "$TP_DIR"/cpu/cpu*.config
sed -i 's|IP_SCHEDULER.*|IP_SCHEDULER=127.0.0.1|' "$TP_DIR/io/io.config"

echo "== Configs aplicadas =="
grep -H "QUEUES_ALGORITHMS\|RR_QUANTUM\|SUSPENSION_TIMEOUT" "$TP_DIR/kernel_scheduler/kernelScheduler.config"
grep -H "SEGMENT_MAX_SIZE" "$TP_DIR/kernel_memory/memory.config" "$TP_DIR/cpu/cpu.config"

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
abrir_terminal "3-STICK (256)" "cd $TP_DIR/memory_stick && ./bin/memory_stick stick.config 256"
sleep 2
abrir_terminal "4-SCHEDULER [PCP]" "cd $TP_DIR/kernel_scheduler && ./bin/kernel_scheduler kernelScheduler.config PCP.prc"
sleep 2
abrir_terminal "5-IO SLEEP"  "cd $TP_DIR/io && ./bin/io io.config SLEEP"
sleep 1
abrir_terminal "5-IO STDIN"  "cd $TP_DIR/io && ./bin/io io.config STDIN"
sleep 1
abrir_terminal "5-IO STDOUT" "cd $TP_DIR/io && ./bin/io io.config STDOUT"
sleep 2
abrir_terminal "6-CPU 1" "cd $TP_DIR/cpu && ./bin/cpu cpu.config 1"

echo ""
echo "🚀 PCP lanzada. Esperado: EXITs 0/5/6 en ~1:30; desalojos por quantum (1500ms)"
echo "   y por prioridad; el resto queda rotando ETERNAMENTE (SET PC 0 = diseño)."
echo "   Cortar con:  pkill -f kernel_memory; pkill -f kernel_scheduler; pkill -f memory_stick; pkill -f 'bin/cpu'; pkill -f 'bin/io'; pkill -f 'bin/swap'"