#!/bin/bash
# ============================================================
#  PRUEBA MEMORIA  —  PLANI_MEM.prc  (4 sticks: 16/32/64/128)
#  Uso:  ./3_prueba_memoria.sh          (corrida 1: BEST)
#        ./3_prueba_memoria.sh WORST    (corrida 2: compacta)
# ============================================================

TP_DIR="$HOME/tp-2026-1c-kernelitos"
PRUEBAS_DIR="$HOME/plug-n-pray-pruebas"
ESTRATEGIA="${1:-BEST}"
SCRIPT_INICIAL="PLANI_MEM.prc"

[ -d "$TP_DIR" ] || { echo "ERROR: no existe $TP_DIR (editá TP_DIR arriba)"; exit 1; }
[ -f "$PRUEBAS_DIR/$SCRIPT_INICIAL" ] || { echo "ERROR: no existe $PRUEBAS_DIR/$SCRIPT_INICIAL"; exit 1; }

pkill -f kernel_memory; pkill -f kernel_scheduler; pkill -f memory_stick
pkill -f "bin/cpu"; pkill -f "bin/io"; pkill -f "bin/swap"
sleep 1

# ---------- Crear configs de sticks 1-4 si no existen (puertos 8003-8006) ----------
cd "$TP_DIR/memory_stick" || exit 1
for i in 1 2 3 4; do
    [ -f "stick$i.config" ] || cp stick.config "stick$i.config"
done
sed -i 's|PUERTO_STICK.*|PUERTO_STICK=8003|' stick1.config
sed -i 's|PUERTO_STICK.*|PUERTO_STICK=8004|' stick2.config
sed -i 's|PUERTO_STICK.*|PUERTO_STICK=8005|' stick3.config
sed -i 's|PUERTO_STICK.*|PUERTO_STICK=8006|' stick4.config
sed -i 's|MEMORY_DELAY.*|MEMORY_DELAY=1500|' stick*.config

# ---------- Configs (sed automático; para inspeccionar a mano: nano <archivo>) ----------
sed -i 's|PLANIFICATION_ALGORITHM.*|PLANIFICATION_ALGORITHM=RR|;
        s|RR_QUANTUM.*|RR_QUANTUM=1500|;
        s|QUEUE_PREEMPTION.*|QUEUE_PREEMPTION=TRUE|;
        s|SUSPENSION_TIMEOUT.*|SUSPENSION_TIMEOUT=35000|' "$TP_DIR/kernel_scheduler/kernelScheduler.config"

sed -i "s|SEGMENT_MAX_SIZE.*|SEGMENT_MAX_SIZE=128|;
        s|ALLOCATION_STRATEGY.*|ALLOCATION_STRATEGY=$ESTRATEGIA|;
        s|INSTRUCTION_DELAY.*|INSTRUCTION_DELAY=500|;
        s|COMPACTION_DELAY.*|COMPACTION_DELAY=30000|" "$TP_DIR/kernel_memory/memory.config"

sed -i "s|SCRIPTS_BASEPATH.*|SCRIPTS_BASEPATH=$PRUEBAS_DIR|" "$TP_DIR/kernel_memory/memory.config"

sed -i 's|SEGMENT_MAX_SIZE.*|SEGMENT_MAX_SIZE=128|' "$TP_DIR"/cpu/cpu*.config

# --- Red: MODO CASA (localhost). 🏫 En el LAB, reemplazar por las IPs reales ---
sed -i 's|IP_MEMORIA.*|IP_MEMORIA=127.0.0.1|;s|IP_PROPIA.*|IP_PROPIA=127.0.0.1|' "$TP_DIR"/memory_stick/stick*.config
sed -i 's|IP_MEMORIA.*|IP_MEMORIA=127.0.0.1|' "$TP_DIR/kernel_scheduler/kernelScheduler.config" "$TP_DIR/swap/swap.config" 2>/dev/null
sed -i 's|IP_KERNEL_MEMORY.*|IP_KERNEL_MEMORY=127.0.0.1|;s|IP_SCHEDULER.*|IP_SCHEDULER=127.0.0.1|' "$TP_DIR"/cpu/cpu*.config
sed -i 's|IP_SCHEDULER.*|IP_SCHEDULER=127.0.0.1|' "$TP_DIR/io/io.config"

echo "== Configs aplicadas (ESTRATEGIA=$ESTRATEGIA) =="
grep -H "ALLOCATION_STRATEGY\|SEGMENT_MAX_SIZE" "$TP_DIR/kernel_memory/memory.config"

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
abrir_terminal "1-KERNEL MEMORY [$ESTRATEGIA]" "cd $TP_DIR/kernel_memory && ./bin/kernel_memory memory.config"
sleep 3
abrir_terminal "2-SWAP" "cd $TP_DIR/swap && ./bin/swap swap.config"
sleep 2
abrir_terminal "3-STICK1 (16)"  "cd $TP_DIR/memory_stick && ./bin/memory_stick stick1.config 16"
sleep 1
abrir_terminal "3-STICK2 (32)"  "cd $TP_DIR/memory_stick && ./bin/memory_stick stick2.config 32"
sleep 1
abrir_terminal "3-STICK3 (64)"  "cd $TP_DIR/memory_stick && ./bin/memory_stick stick3.config 64"
sleep 1
abrir_terminal "3-STICK4 (128)" "cd $TP_DIR/memory_stick && ./bin/memory_stick stick4.config 128"
sleep 2
abrir_terminal "4-SCHEDULER [PLANI_MEM]" "cd $TP_DIR/kernel_scheduler && ./bin/kernel_scheduler kernelScheduler.config PLANI_MEM.prc"
sleep 2
abrir_terminal "5-IO SLEEP"  "cd $TP_DIR/io && ./bin/io io.config SLEEP"
sleep 1
abrir_terminal "5-IO STDIN"  "cd $TP_DIR/io && ./bin/io io.config STDIN"
sleep 1
abrir_terminal "5-IO STDOUT" "cd $TP_DIR/io && ./bin/io io.config STDOUT"
sleep 2
abrir_terminal "6-CPU 1" "cd $TP_DIR/cpu && ./bin/cpu cpu.config 1"

echo ""
echo "🚀 MEMORIA lanzada con ALLOCATION_STRATEGY=$ESTRATEGIA"
echo "   BEST: sin compactación, direcciones determinísticas (69→DF208, 70→DF0)."
echo "   WORST: compactación (~45s de espera, COMPACTION_DELAY=30000) y los 6 valores"
echo "          releídos INTACTOS tras la mudanza — ese es el criterio de éxito."
echo "   Corrida 2:  ./3_prueba_memoria.sh WORST"
echo "   Cortar con:  pkill -f kernel_memory; pkill -f kernel_scheduler; pkill -f memory_stick; pkill -f 'bin/cpu'; pkill -f 'bin/io'; pkill -f 'bin/swap'"