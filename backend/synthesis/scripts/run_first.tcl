#-----------------------------------------------------------------------------
# General design dependent variables
#-----------------------------------------------------------------------------
export DESIGNS="multiplier32FP" ;# put here the name of current design
export USER=???? ;# put here YOUR user name at this machine
export COURSE= ;# put the course name "ufsm00291/" or nothing
export PROJECT_DIR=/home/${COURSE}${USER}/projetos/${DESIGNS}
export BACKEND_DIR=${PROJECT_DIR}/backend
export TECH_DIR=/home/tools/design_kits/cadence/GPDK045 ;# technology dependent
export LIB_DIR=${TECH_DIR}/gsclib045_svt_v4.4/gsclib045/timing
export LEF_DIR=${TECH_DIR}/gsclib045_svt_v4.4/gsclib045/lef
export HDL_NAME=${DESIGNS}
export RTL_FILES="${DESIGNS}.vhd" ;# put here all project rtl files 
export VLOG_LIST="$BACKEND_DIR/synthesis/deliverables/${DESIGNS}.v  $BACKEND_DIR/synthesis/deliverables/${DESIGNS}_io.v  $BACKEND_DIR/synthesis/deliverables/${DESIGNS}_chip.v"
#-----------------------------------------------------------------------------
# Custom Variables to be used in SDC (constraints file)
#-----------------------------------------------------------------------------
export MAIN_CLOCK_NAME=clk
export MAIN_RST_NAME=rst_n
export BEST_LIB_OPERATING_CONDITION=PVT_1P32V_0C ;# see LEF files
export WORST_LIB_OPERATING_CONDITION=PVT_0P9V_125C ;# see LEF files
export period_clk=100.0  ;# (100 ns = 10 MHz) (10 ns = 100 MHz) (2 ns = 500 MHz) (1 ns = 1 GHz)
export clk_uncertainty=0.05 ;# ns (“a guess”)
export clk_latency=0.10 ;# ns (“a guess”)
export in_delay=0.30 ;# ns
export out_delay=0.30;#ns 
export out_load=0.045 ;#pF 
export slew="146 164 264 252" ;#minimum rise, minimum fall, maximum rise and maximum fall 
export slew_min_rise=0.146 ;# ns
export slew_min_fall=0.164 ;# ns
export slew_max_rise=0.264 ;# ns
export slew_max_fall=0.252 ;# ns
#-----------------------------------------------------------------------------
# TECH Custom Variables to be used in technology loading (tech file)
#-----------------------------------------------------------------------------
export WORST_LIST="${LIB_DIR}/slow_vdd1v0_basicCells.lib"
export BEST_LIST="${LIB_DIR}/fast_vdd1v2_basicCells.lib"
export LEF_LIST="${LEF_DIR}/gsclib045_tech.lef ${LEF_DIR}/gsclib045_macro.lef"
export WORST_CAP_LIST="${TECH_DIR}/gpdk045_v_6_0/soce/gpdk045.basic.CapTbl"
export QRC_LIST="${TECH_DIR}/gpdk045_v_6_0/qrc/rcworst/qrcTechFile"
export CAP_MAX="${WORST_CAP_LIST}" ;# mmmc - layout tool .view file
export CAP_MIN="${WORST_CAP_LIST}" ;# mmmc - layout tool .view file
#-----------------------------------------------------------------------------
# POWER nets to be used in layout flow
#-----------------------------------------------------------------------------
export NET_ZERO=VSS ;# power net: see the lef file
export NET_ONE=VDD ;# power net: see the lef file
#-----------------------------------------------------------------------------
# CTS cells
#-----------------------------------------------------------------------------
export BUFFERS_CTS="CLKBUFX20 CLKBUFX16 CLKBUFX12 CLKBUFX8 CLKBUFX6 CLKBUFX4 CLKBUFX3 CLKBUFX2"
export INVERTERS_CTS="INVX20 CLKINVX20 INVX16 INVX12 INVX8 INVX6 INVX4 INVX3 INVX2 INVX1 INVXL"
#-----------------------------------------------------------------------------
# Placing core design pins (design dependent)
#-----------------------------------------------------------------------------
export LEFT_CORE_PINS="{a_i[0]} {a_i[1]} {a_i[2]} {a_i[3]} {a_i[4]} {a_i[5]} {a_i[6]} {a_i[7]}"
export TOP_CORE_PINS="{b_i[0]} {b_i[1]} {b_i[2]} {b_i[3]} {b_i[4]} {b_i[5]} {b_i[6]} {b_i[7]}"
export RIGHT_CORE_PINS="{sum_o[0]} {sum_o[1]} {sum_o[2]} {sum_o[3]} {sum_o[4]} {sum_o[5]} {sum_o[6]} {sum_o[7]}"
export BOTTOM_CORE_PINS="carry_i carry_o clk rst_n"

#-----------------------------------------------------------------------------
# Tool commands section
#-----------------------------------------------------------------------------
# loading modules
module add cdn/genus/genus211
module add cdn/xcelium/xcelium2309
module add cdn/innovus/innovus211


# Para executar o XCELIUM
cd ${PROJECT_DIR}/frontend

### run HDL
#xrun -clean -64bit -v200x -v93 ${DESIGNS}.vhd Util_package.vhd ${DESIGNS}_tb.vhd -top ${DESIGNS}_tb -access +rwc -gui

### run netlist (logic synthesis)
#xrun -clean -64bit -v200x -v93 ${TECH_DIR}/gsclib045_all_v4.4/gsclib045/verilog/slow_vdd1v0_basicCells.v ${PROJECT_DIR}/backend/synthesis/deliverables/${DESIGNS}.v Util_package.vhd ${DESIGNS}_tb.vhd -top ${DESIGNS}_tb -access +rwc -clean -gui

### run netlist (logic synthesis) with compiled SDF 
#xrun -clean -timescale 1ns/10ps -mess -64bit -v200x -v93 -iocondsort ${TECH_DIR}/gsclib045_all_v4.4/gsclib045/verilog/slow_vdd1v0_basicCells.v ${PROJECT_DIR}/backend/synthesis/deliverables/${DESIGNS}.v Util_package.vhd ${DESIGNS}_tb.vhd -top ${DESIGNS}_tb -access +rwc -sdf_cmd_file ${PROJECT_DIR}/frontend/sdf_cmd_file.cmd -clean -gui 


# Para executar o GENUS
cd ${PROJECT_DIR}/backend/synthesis/work
## apenas o programa
#genus -abort_on_error -lic_startup Genus_Synthesis -lic_startup_options Genus_Physical_Opt -log genus -overwrite
# programa e carrega script para síntese automatizada
#genus -abort_on_error -lic_startup Genus_Synthesis -lic_startup_options Genus_Physical_Opt -log genus -overwrite -files ${PROJECT_DIR}/backend/synthesis/scripts/${DESIGNS}.tcl


# Para executar o INNOVUS
cd ${PROJECT_DIR}/backend/layout/work
## apenas o programa
innovus -stylus -overwrite -no_gui
## programa e carrega script para síntese automatizada
#innovus -stylus -overwrite -no_gui -files ../scripts/layout.tcl






