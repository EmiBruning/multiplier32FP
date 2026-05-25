
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




