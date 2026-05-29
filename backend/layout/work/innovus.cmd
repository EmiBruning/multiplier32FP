#######################################################
#                                                     
#  Innovus Command Logging File                     
#  Created on Fri May 29 09:58:27 2026                
#                                                     
#######################################################

#@(#)CDS: Innovus v21.19-s058_1 (64bit) 04/04/2024 09:59 (Linux 3.10.0-693.el7.x86_64)
#@(#)CDS: NanoRoute 21.19-s058_1 NR231113-0413/21_19-UB (database version 18.20.605) {superthreading v2.17}
#@(#)CDS: AAE 21.19-s004 (64bit) 04/04/2024 (Linux 3.10.0-693.el7.x86_64)
#@(#)CDS: CTE 21.19-s010_1 () Mar 27 2024 01:55:37 ( )
#@(#)CDS: SYNTECH 21.19-s002_1 () Sep  6 2023 22:17:00 ( )
#@(#)CDS: CPE v21.19-s026
#@(#)CDS: IQuantus/TQuantus 21.1.1-s966 (64bit) Wed Mar 8 10:22:20 PST 2023 (Linux 3.10.0-693.el7.x86_64)

#@ source /home/ufsm00291/ufsm00291-bruning2023520081/projetos/multiplier32FP/backend/layout/scripts/layout.tcl
#@ Begin verbose source (pre): source /home/ufsm00291/ufsm00291-bruning2023520081/projetos/multiplier32FP/backend/layout/scripts/layout.tcl
#@ source ../../synthesis/scripts/common/variables.tcl
#@ Begin verbose source ../../synthesis/scripts/common/variables.tcl (pre)
set PROJECT_DIR $env(PROJECT_DIR)
set TECH_DIR $env(TECH_DIR)
set LEF_DIR $env(LEF_DIR)
set DESIGNS $env(DESIGNS)
set DESIGNS $env(DESIGNS)
set HDL_NAME $env(HDL_NAME)
set RTL_FILES $env(RTL_FILES)
set INTERCONNECT_MODE ple
set MAIN_CLOCK_NAME $env(MAIN_CLOCK_NAME)
set MAIN_RST_NAME $env(MAIN_RST_NAME)
set BEST_LIB_OPERATING_CONDITION $env(BEST_LIB_OPERATING_CONDITION)
set WORST_LIB_OPERATING_CONDITION $env(WORST_LIB_OPERATING_CONDITION)
set period_clk $env(period_clk)
set clk_uncertainty $env(clk_uncertainty)
set clk_latency $env(clk_latency)
set in_delay $env(in_delay)
set out_delay $env(out_delay)
set out_load $env(out_load)
set slew $env(slew)
set slew_min_rise $env(slew_min_rise)
set slew_min_fall $env(slew_min_fall)
set slew_max_rise $env(slew_max_rise)
set slew_max_fall $env(slew_max_fall)
set WORST_LIST $env(WORST_LIST)
set BEST_LIST $env(BEST_LIST)
set LEF_LIST $env(LEF_LIST)
set WORST_CAP_LIST $env(WORST_CAP_LIST)
set QRC_LIST $env(QRC_LIST)
set CAP_MAX $env(CAP_MAX)
set CAP_MIN $env(CAP_MIN)
set NET_ZERO $env(NET_ZERO)
set NET_ONE $env(NET_ONE)
set BUFFERS_CTS $env(BUFFERS_CTS)
set INVERTERS_CTS $env(INVERTERS_CTS)
set LEFT_CORE_PINS $env(LEFT_CORE_PINS)
set TOP_CORE_PINS $env(TOP_CORE_PINS)
set RIGHT_CORE_PINS $env(RIGHT_CORE_PINS)
set BOTTOM_CORE_PINS $env(BOTTOM_CORE_PINS)
#@ End verbose source ../../synthesis/scripts/common/variables.tcl
#@ source ${PROJECT_DIR}/backend/synthesis/scripts/common/path.tcl
#@ Begin verbose source /home/ufsm00291/ufsm00291-bruning2023520081/projetos/multiplier32FP/backend/synthesis/scripts/common/path.tcl (pre)
set BACKEND_DIR ${PROJECT_DIR}/backend
set SYNT_DIR ${BACKEND_DIR}/synthesis
set SCRIPT_DIR ${SYNT_DIR}/scripts
set RPT_DIR ${SYNT_DIR}/reports
set DEV_DIR ${SYNT_DIR}/deliverables
set LAYOUT_DIR ${BACKEND_DIR}/layout
set FRONTEND_DIR ${PROJECT_DIR}/frontend
set OTHERS ""
lappend FRONTEND_DIR $OTHERS
lappend LIB_DIR ${TECH_DIR}/io
lappend LEF_DIR ${TECH_DIR}/giolib045_v3.3/lef
#@ End verbose source /home/ufsm00291/ufsm00291-bruning2023520081/projetos/multiplier32FP/backend/synthesis/scripts/common/path.tcl
set_db init_power_nets $NET_ONE
set_db init_ground_nets $NET_ZERO
read_mmmc ${LAYOUT_DIR}/scripts/${DESIGNS}.view
#@ Begin verbose source /home/ufsm00291/ufsm00291-bruning2023520081/projetos/multiplier32FP/backend/layout/scripts/multiplier32FP.view (pre)
create_library_set -name fast -timing $BEST_LIST
create_library_set -name slow -timing $WORST_LIST
create_rc_corner -name rc_best -cap_table $CAP_MIN -temperature 0
create_rc_corner -name rc_worst -cap_table $CAP_MAX -temperature 125
create_opcond -name oc_slow -process {1.0} -voltage {0.90} -temperature {125} 
create_opcond -name oc_fast -process {1.0} -voltage {1.32} -temperature {0} 
create_timing_condition -name slow_timing -library_sets [list slow] -opcond oc_slow
create_timing_condition -name fast_timing -library_sets [list fast] -opcond oc_fast
create_delay_corner -name slow_max -timing_condition slow_timing -rc_corner rc_worst
create_delay_corner -name fast_min -timing_condition fast_timing -rc_corner rc_best
create_constraint_mode -name normal_genus_slow_max -sdc_files ${PROJECT_DIR}/backend/synthesis/constraints/$DESIGNS.sdc
create_analysis_view -name analysis_normal_slow_max -constraint_mode {normal_genus_slow_max} -delay_corner slow_max
create_analysis_view -name analysis_normal_fast_min -constraint_mode {normal_genus_slow_max} -delay_corner fast_min
set_analysis_view -setup [list analysis_normal_slow_max] -hold [list analysis_normal_fast_min]
#@ End verbose source /home/ufsm00291/ufsm00291-bruning2023520081/projetos/multiplier32FP/backend/layout/scripts/multiplier32FP.view
read_physical -lef $LEF_LIST
read_netlist ../../synthesis/deliverables/${DESIGNS}.v
init_design
create_floorplan -core_density_size {1.0 0.6 10 10 10 10}
connect_global_net $NET_ONE -type pg_pin -pin VDD -all
connect_global_net $NET_ZERO -type pg_pin -pin VSS -all
add_rings -nets "$NET_ONE $NET_ZERO" -type core_rings -width 2 -spacing 1 -layer {top 4 bottom 4}
add_stripes -nets "$NET_ONE $NET_ZERO" -layer 5 -width 1 -spacing 10 -set_to_set_distance 20
place_opt_design
route_design
report_design > relatorio_area.rpt
#@ End verbose source: /home/ufsm00291/ufsm00291-bruning2023520081/projetos/multiplier32FP/backend/layout/scripts/layout.tcl
llength [get_db insts]
current_design
get_db [current_design] .core_bbox
current_design
get_db [current_design] .area
report_timing
foreach cell [get_db lib_cells *NAND2*] { puts "[get_db $cell .name]: [get_db $cell .area]" }
exit
