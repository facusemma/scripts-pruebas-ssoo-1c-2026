#!/bin/bash
# ============================================================
#  PRUEBA BASE  —  parte 1: PLANI_PRE_0.prc | parte 2: MEMORIA_PRE_0.prc
#  Uso:  ./1_prueba_base.sh              (parte 1)
#        ./1_prueba_base.sh MEMORIA_PRE_0.prc   (parte 2)
# ============================================================

TP_DIR="$HOME/tp-2026-1c-kernelitos"     # ← ajustar si tu carpeta se llama distinto
PRUEBAS_DIR="$HOME/plug-n-pray-pruebas"          # ← repo de scripts .prc de la cátedra
SCRIPT_INICIAL="${1:-PLANI_PRE_0.prc}"

# ---------- Chequeos ----------
[ -d "$TP_DIR" ] || { echo "ERROR: no existe $TP_DIR (editá TP_DIR arriba)"; exit 1; }
[ -f "$PRUEBAS_DIR/$SCRIPT_INICIAL" ] || { echo "ERROR: no existe $PRUEBAS_DIR/$SCRIPT_INICIAL"; exit 1; }

# ---------- Matar instancias previas ----------
pkill -f kernel_memory; pkill -f kernel_scheduler; pkill -f memory_stick
pkill -f "bin/cpu"; pkill -f "bin/io"; pkill -f "bin/swap"
sleep 1

# ---------- Configs (automático con sed; nano es interactivo y frenaría el script) ----------
# Si querés inspeccionar a mano después:  nano <archivo>.config
sed -i 's|PLANIFICATION_ALGORITHM.*|PLANIFICATION_ALGORITHM=CMN|;
        s|QUEUES_ALGORITHMS.*|QUEUES_ALGORITHMS=[FIFO,RR,FIFO,RR]|;
        s|RR_QUANTUM.*|RR_QUANTUM=600|;
        s|QUEUE_PREEMPTION.*|QUEUE_PREEMPTION=TRUE|;
        s|SUSPENSION_TIMEOUT.*|SUSPENSION_TIMEOUT=60000|' "$TP_DIR/kernel_scheduler/kernelScheduler.config"

sed -i 's|SEGMENT_MAX_SIZE.*|SEGMENT_MAX_SIZE=128|;
        s|ALLOCATION_STRATEGY.*|ALLOCATION_STRATEGY=BEST|;
        s|INSTRUCTION_DELAY.*|INSTRUCTION_DELAY=250|;
        s|COMPACTION_DELAY.*|COMPACTION_DELAY=30000|' "$TP_DIR/kernel_memory/memory.config"

sed -i "s|SCRIPTS_BASEPATH.*|SCRIPTS_BASEPATH=$PRUEBAS_DIR|" "$TP_DIR/kernel_memory/memory.config"

sed -i 's|SEGMENT_MAX_SIZE.*|SEGMENT_MAX_SIZE=128|' "$TP_DIR"/cpu/cpu*.config

sed -i 's|MEMORY_DELAY.*|MEMORY_DELAY=1500|' "$TP_DIR/memory_stick/stick.config"

# --- Red: MODO CASA (localhost). 🏫 En el LAB, reemplazar por las IPs reales ---
sed -i 's|IP_MEMORIA.*|IP_MEMORIA=127.0.0.1|;s|IP_PROPIA.*|IP_PROPIA=127.0.0.1|' "$TP_DIR"/memory_stick/stick*.config
sed -i 's|IP_MEMORIA.*|IP_MEMORIA=127.0.0.1|' "$TP_DIR/kernel_scheduler/kernelScheduler.config" "$TP_DIR/swap/swap.config" 2>/dev/null
sed -i 's|IP_KERNEL_MEMORY.*|IP_KERNEL_MEMORY=127.0.0.1|;s|IP_SCHEDULER.*|IP_SCHEDULER=127.0.0.1|' "$TP_DIR"/cpu/cpu*.config
sed -i 's|IP_SCHEDULER.*|IP_SCHEDULER=127.0.0.1|' "$TP_DIR/io/io.config"

echo "== Configs aplicadas =="
grep -H "PLANIFICATION_ALGORITHM\|QUEUES_ALGORITHMS\|RR_QUANTUM\|SUSPENSION_TIMEOUT" "$TP_DIR/kernel_scheduler/kernelScheduler.config"
grep -H "SEGMENT_MAX_SIZE\|ALLOCATION_STRATEGY\|INSTRUCTION_DELAY" "$TP_DIR/kernel_memory/memory.config"

# ---------- Compilar ----------
echo "== Compilando (make clean && make en cada módulo) =="
for MOD in utils kernel_memory kernel_scheduler memory_stick cpu io swap; do
    ( cd "$TP_DIR/$MOD" && make clean >/dev/null && make ) || { echo "❌ ERROR compilando $MOD"; exit 1; }
done
echo "✅ Compilación OK"

# ---------- Función: abrir terminal ----------
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

# ---------- Lanzamiento en orden ----------
echo "== Lanzando módulos =="
abrir_terminal "1-KERNEL MEMORY" "cd $TP_DIR/kernel_memory && ./bin/kernel_memory memory.config"
sleep 3
abrir_terminal "2-SWAP" "cd $TP_DIR/swap && ./bin/swap swap.config"
sleep 2
abrir_terminal "3-STICK (256)" "cd $TP_DIR/memory_stick && ./bin/memory_stick stick.config 256"
sleep 2
abrir_terminal "4-SCHEDULER [$SCRIPT_INICIAL]" "cd $TP_DIR/kernel_scheduler && ./bin/kernel_scheduler kernelScheduler.config $SCRIPT_INICIAL"
sleep 2
abrir_terminal "5-IO SLEEP"  "cd $TP_DIR/io && ./bin/io io.config SLEEP"
sleep 1
abrir_terminal "5-IO STDIN"  "cd $TP_DIR/io && ./bin/io io.config STDIN"
sleep 1
abrir_terminal "5-IO STDOUT" "cd $TP_DIR/io && ./bin/io io.config STDOUT"
sleep 2
abrir_terminal "6-CPU 1" "cd $TP_DIR/cpu && ./bin/cpu cpu.config 1"

echo ""
echo "🚀 PRUEBA BASE lanzada con $SCRIPT_INICIAL"
echo "   Parte 1 (PLANI_PRE_0): esperar 6 EXITs (0,5,4,3,1,2)."
echo "   Parte 2: volver a correr →  ./1_prueba_base.sh MEMORIA_PRE_0.prc"
echo "            (SEG_FAULT del PID 1 es INTENCIONAL; tipear 'holamundo' cuando pida STDIN)"
echo "   Para matar todo:  pkill -f kernel_memory; pkill -f kernel_scheduler; pkill -f memory_stick; pkill -f 'bin/cpu'; pkill -f 'bin/io'; pkill -f 'bin/swap'"