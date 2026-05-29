
# Last update: 2026/03/08

#-----------------------------------------------------------------------------
# General Comments
#-----------------------------------------------------------------------------
puts "  "
puts "  "
puts "  "
puts "  "

#-----------------------------------------------------------------------------
# Load vriables set in run_first.tcl
#-----------------------------------------------------------------------------
source ../../synthesis/scripts/common/variables.tcl

#-----------------------------------------------------------------------------
# Load Path File
#-----------------------------------------------------------------------------
source ${PROJECT_DIR}/backend/synthesis/scripts/common/path.tcl

#-----------------------------------------------------------------------------
# Load Tech File
#-----------------------------------------------------------------------------
source ${SCRIPT_DIR}/common/tech.tcl
#set_db [get_db library_domain *best] .default true

#-----------------------------------------------------------------------------
# Analyze RTL source (manually set; file_list.tcl is not covered in ELC1054)
#-----------------------------------------------------------------------------
set_db init_hdl_search_path "${DEV_DIR} ${FRONTEND_DIR}"
read_hdl -language v2001 $RTL_FILES

#-----------------------------------------------------------------------------
# Elaborate Design
#-----------------------------------------------------------------------------
elaborate ${HDL_NAME}
set_top_module ${HDL_NAME}
check_design -unresolved ${HDL_NAME}
get_db current_design
check_library

#-----------------------------------------------------------------------------
# Constraints
#-----------------------------------------------------------------------------
read_sdc ${BACKEND_DIR}/synthesis/constraints/${HDL_NAME}.sdc
report timing -lint
#gui_show

#-----------------------------------------------------------------------------
# Pos "Elaborate" Attributes (manually set)
#-----------------------------------------------------------------------------
set_db auto_ungroup none ;# (none|both) ungrouping will not be performed


#-----------------------------------------------------------------------------
# Frequency Sweep
#-----------------------------------------------------------------------------
set freq_sweep {
    "10MHz"  100.0
}

foreach {freq period} $freq_sweep {

    puts " INICIANDO SÍNTESE PARA: $freq"

    dc::create_clock -name clk -period $period [dc::get_ports clk]

    syn_generic ${HDL_NAME} 
    syn_map ${HDL_NAME} 

    # report_design_rules > ${RPT_DIR}/${HDL_NAME}_${var}_drc_${freq}.rpt
    # report_area > ${RPT_DIR}/${HDL_NAME}_${var}_area_${freq}.rpt
    # report_area -normalize_with_gate NAND2X1 > ${RPT_DIR}/${HDL_NAME}_${var}_area_normalized_${freq}.rpt
    # report_timing > ${RPT_DIR}/${HDL_NAME}_${var}_timing_${freq}.rpt
    # report_gates > ${RPT_DIR}/${HDL_NAME}_${var}_gates_${freq}.rpt
    # report_qor > ${RPT_DIR}/${HDL_NAME}_${var}_qor_${freq}.rpt

    read_stimulus -allow_n_nets -format vcd -file multiplier32FP_50us.vcd
    set_db power_engine joules ;# <joules or legacy>
    report_sdb_annotation
    report_power -unit uW
    report_power > ${RPT_DIR}/${HDL_NAME}_power_${freq}_x1.rpt


    read_stimulus -allow_n_nets -format vcd -file multiplier32FP_50us.vcd
    set_db power_engine joules ;# <joules or legacy>
    report_sdb_annotation
    report_power -unit uW
    report_power > ${RPT_DIR}/${HDL_NAME}_power_${freq}_x2.rpt
	


}

#-----------------------------------------------------------------------------
# Preparing and generating output data (Verilog Netlist e SDF final)
#-----------------------------------------------------------------------------

source ../scripts/common/sdf_width_wa.etf
write_sdf -edge check_edge -setuphold split -recrem split -version 3.0 -design ${HDL_NAME} > ${DEV_DIR}/${HDL_NAME}_worst.sdf
write_hdl ${HDL_NAME} > ${DEV_DIR}/${HDL_NAME}.v


if {0} {

#01 
#report_power -unit uW

# Comandos abril 2025

#Use report_stim_hierarchy command to check design hierarchy
#report_design_hierarchy
#Use report_stim_hierarchy command to check stimulus hierarchy
#report_stim_hierarchy -file ${PROJECT_DIR}/frontend/${DESIGNS}_5kns.vcd -format vcd

#report_sdb_annotation -show_details unasserted

}
