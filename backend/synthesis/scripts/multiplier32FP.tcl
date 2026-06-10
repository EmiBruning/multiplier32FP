

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
# Generic optimization (technology independent)
#-----------------------------------------------------------------------------
syn_generic ${HDL_NAME} 

#-----------------------------------------------------------------------------
# Agressively optimization (area, timing, power) and mapping
#-----------------------------------------------------------------------------
syn_map ${HDL_NAME} 
get_db insts .base_cell.name -u ;# List all cell names used in the current design.

#-----------------------------------------------------------------------------
# Preparing and generating output data (reports, verilog netlist)
#-----------------------------------------------------------------------------

read_stimulus -allow_n_nets -format vcd -file multiplier_fis_200MHz_x1.vcd
set_db power_engine joules ;# <joules or legacy>
report_sdb_annotation
report_power -unit uW
report_power > ${RPT_DIR}/${HDL_NAME}_power_200MHz_fis_x1.rpt

read_stimulus -allow_n_nets -format vcd -file multiplier_fis_200MHz_x2.vcd
set_db power_engine joules ;# <joules or legacy>
report_sdb_annotation
report_power -unit uW
report_power > ${RPT_DIR}/${HDL_NAME}_power_200MHz_fis_x2.rpt


#report_power > ${RPT_DIR}/${HDL_NAME}_power_500.rpt
#report_design_rules > ${RPT_DIR}/${HDL_NAME}_drc.rpt
#report_area > ${RPT_DIR}/${HDL_NAME}_area__10MHz.rpt ;# report_area -detail 
#report_area -normalize_with_gate NAND2X1 > ${RPT_DIR}/${HDL_NAME}_area_normalized_10MHz.rpt
#report_timing > ${RPT_DIR}/${HDL_NAME}_timing__10MHz.rpt
#report_gates > ${RPT_DIR}/${HDL_NAME}_gates.rpt
#report_qor > ${RPT_DIR}/${HDL_NAME}_qor.rpt
source ../scripts/common/sdf_width_wa.etf
write_sdf -edge check_edge -nonegchecks -setuphold split -recrem split -version 3.0 -design ${HDL_NAME}  > ${DEV_DIR}/${HDL_NAME}_worst_SPLIT.sdf
write_hdl ${HDL_NAME} > ${DEV_DIR}/${HDL_NAME}.v





