
# Last update: 2026/03/08

#-----------------------------------------------------------------------------
# Load vriables set in run_first.tcl
#-----------------------------------------------------------------------------
source ../../synthesis/scripts/common/variables.tcl

#-----------------------------------------------------------------------------
# Load Path File
#-----------------------------------------------------------------------------
source ${PROJECT_DIR}/backend/synthesis/scripts/common/path.tcl

#-----------------------------------------------------------------------------
# set tech files to be used in ".view"
#-----------------------------------------------------------------------------
# run_first.tcl

#-----------------------------------------------------------------------------
# Initiates the design files (netlist, LEFs, timing libraries)
#-----------------------------------------------------------------------------
set_db init_power_nets $NET_ONE
set_db init_ground_nets $NET_ZERO
read_mmmc ${LAYOUT_DIR}/scripts/${DESIGNS}.view
read_physical -lef $LEF_LIST
read_netlist ../../synthesis/deliverables/${DESIGNS}.v
init_design

#=============================================================================
# 1. FLOORPLAN & POWER PLANNING (Cria a área do chip e as trilhas de energia)
#=============================================================================
# Cria o quadrado do chip. Ajuste a densidade (0.6 = 60% ocupado por portas)
# 1.0 = Proporção do chip (Quadrado)
# 0.6 = Densidade (60% de ocupação)
# 10 10 10 10 = Margens em micrômetros (Esquerda, Baixo, Direita, Topo)
create_floorplan -core_density_size {1.0 0.6 10 10 10 10}

# Conecta logicamente os pinos globais de alimentação e terra do circuito
connect_global_net $NET_ONE -type pg_pin -pin VDD -all
connect_global_net $NET_ZERO -type pg_pin -pin VSS -all

# Cria os anéis de alimentação (Power Rings) ao redor do bloco
add_rings -nets "$NET_ONE $NET_ZERO" -type core_rings -width 2 -spacing 1 -layer {top 4 bottom 4}

# Cria as listras de alimentação verticais (Power Stripes) para alimentar as células padrão
add_stripes -nets "$NET_ONE $NET_ZERO" -layer 5 -width 1 -spacing 10 -set_to_set_distance 20

#=============================================================================
# 2. PLACEMENT (Espalha as portas lógicas do multiplicador no chip de forma ótima)
#=============================================================================
# Executa o posicionamento físico das células padronizadas e otimiza o timing
place_opt_design

#=============================================================================
# 3. ROUTING (Faz as conexões físicas/fiação metálica entre as células)
#=============================================================================
# Executa o roteamento global e detalhado das nets do sinal do multiplicador
route_design

#=============================================================================
# 4. EXTRAÇÃO DE DADOS (O que você queria fazer!)
#=============================================================================
# Agora que o design foi posicionado e roteado, extraia os dados com precisão:
report_design > relatorio_area.rpt


