# Last update: 2026/04/28

#-----------------------------------------------------------------------------
# General Comments
# Script automatizado para varredura de frequências e extração de dados
#-----------------------------------------------------------------------------
puts "  "
puts "  "
set var "worst"
set num 1 
#-----------------------------------------------------------------------------
# Main Custom Variables Design Dependent (set local)
#-----------------------------------------------------------------------------
set PROJECT_DIR $env(PROJECT_DIR)
set TECH_DIR $env(TECH_DIR)
set DESIGNS $env(DESIGNS)
set HDL_NAME $env(HDL_NAME)
set INTERCONNECT_MODE ple

#-----------------------------------------------------------------------------
# MAIN Custom Variables to be used in SDC (constraints file)
#-----------------------------------------------------------------------------

set MAIN_CLOCK_NAME clk
set MAIN_RST_NAME rst_n
set BEST_LIB_OPERATING_CONDITION PVT_1P32V_0C
set WORST_LIB_OPERATING_CONDITION PVT_0P9V_125C

set period_clk 100.0 ;# Valor inicial que será usado no primeiro read_sdc

set clk_uncertainty 0.05 ;# ns
set clk_latency 0.10 ;# ns
set in_delay 0.30 ;# ns
set out_delay 0.30;#ns 
set out_load 0.045 ;#pF 
set slew "146 164 264 252" 
set slew_min_rise 0.146 
set slew_min_fall 0.164 
set slew_max_rise 0.264 
set slew_max_fall 0.252 
set WORST_LIST {slow_vdd1v0_basicCells.lib} 
set BEST_LIST {fast_vdd1v2_basicCells.lib} 
set LEF_LIST {gsclib045_tech.lef gsclib045_macro.lef}
set WORST_CAP_LIST ${TECH_DIR}/gpdk045_v_6_0/soce/gpdk045.basic.CapTbl
set QRC_LIST ${TECH_DIR}/gpdk045_v_6_0/qrc/rcworst/qrcTechFile

#-----------------------------------------------------------------------------
# Load Path File & Tech File
#-----------------------------------------------------------------------------
source ${PROJECT_DIR}/backend/synthesis/scripts/common/path.tcl
source ${SCRIPT_DIR}/common/tech.tcl

if {$var == "worst"} {
    set_db [get_db library_domain *worst] .default true
} elseif {$var == "best"} {
    set_db [get_db library_domain *best] .default true
} else {
    put "Valor não indentificado - simulação WORST"
    set_db [get_db library_domain *worst] .default true
}

#-----------------------------------------------------------------------------
# Analyze RTL source
#-----------------------------------------------------------------------------
set_db init_hdl_search_path "${DEV_DIR} ${FRONTEND_DIR}"
set rtl_files ${DESIGNS}.vhd
read_hdl -language vhdl $rtl_files

#-----------------------------------------------------------------------------
# Elaborate Design
#-----------------------------------------------------------------------------
elaborate ${HDL_NAME}
set_top_module ${HDL_NAME}
check_design -unresolved ${HDL_NAME}
get_db current_design
check_library

#-----------------------------------------------------------------------------
# Constraints Iniciais
#-----------------------------------------------------------------------------
read_sdc ${BACKEND_DIR}/synthesis/constraints/${HDL_NAME}.sdc
set_db auto_ungroup none ;# ungrouping will not be performed

#-----------------------------------------------------------------------------
# Portas monitoradas e arquivo de saída
#   - Adicione ou remova entradas da lista conforme necessário.
#   - Formato de cada entrada: { nome_porta atributo_lp }
#-----------------------------------------------------------------------------
set MONITORED_PORTS {
    { "a_i[1]"   lp_computed_probability  }
    { "a_i[1]"   lp_computed_toggle_rate  }
    { "sum_o[7]" lp_computed_probability  }
    { "sum_o[7]" lp_computed_toggle_rate  }
}

set DATA_FILE "${RPT_DIR}/${HDL_NAME}_${var}_data_${num}.txt"

# ------------------------------------------------------------
# Proc: salvar_dados_porta
#   Abre o arquivo em modo append e registra os valores
#   coletados após cada síntese + anotação de poder.
# ------------------------------------------------------------
proc salvar_dados_porta {caminho_arquivo freq porta_attr_lista} {
    set fd [open $caminho_arquivo a]

    puts $fd "------------------------------------------------------------"
    puts $fd "Frequencia : $freq"
    puts $fd "Timestamp  : [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]"
    puts $fd "------------------------------------------------------------"

    foreach entrada $porta_attr_lista {
        set porta [lindex $entrada 0]
        set attr  [lindex $entrada 1]

        # Captura o valor; em caso de erro registra N/A
        if {[catch {
            set valor [get_db [get_db ports $porta] .$attr]
        } err]} {
            set valor "N/A (erro: $err)"
        }

        puts $fd [format "  %-20s  %-30s = %s" $porta $attr $valor]
    }

    puts $fd ""
    close $fd
}

#-----------------------------------------------------------------------------
# Cabeçalho inicial do arquivo de dados (criado/sobrescrito uma única vez)
#-----------------------------------------------------------------------------
set fd_init [open $DATA_FILE w]
puts $fd_init "============================================================"
puts $fd_init "Design   : $HDL_NAME"
puts $fd_init "Modo     : $var"
puts $fd_init "Gerado em: [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]"
puts $fd_init "============================================================"
puts $fd_init ""
close $fd_init

#-----------------------------------------------------------------------------
# Frequency Sweep
#-----------------------------------------------------------------------------
set freq_sweep {
    "100MHz"  10.0
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

    read_stimulus -allow_n_nets -format vcd -file somador_${freq}_x1.vcd
    set_db power_engine joules ;# <joules or legacy>
    report_sdb_annotation
    report_power -unit uW
    #report_power > ${RPT_DIR}/${HDL_NAME}_${var}_power_${freq}_x1.rpt

    #salvar_dados_porta $DATA_FILE $freq $MONITORED_PORTS

    #read_stimulus -allow_n_nets -format vcd -file somador_${freq}_x2.vcd
    #set_db power_engine joules ;# <joules or legacy>
    #report_sdb_annotation
    #report_power -unit uW
    #report_power > ${RPT_DIR}/${HDL_NAME}_${var}_power_${freq}_x2.rpt
	
    # -------------------------------------------------------
    # Coleta e salva os atributos das portas monitoradas
    # -------------------------------------------------------
    # salvar_dados_porta $DATA_FILE $freq $MONITORED_PORTS

    # puts " Dados de portas salvos em: $DATA_FILE"

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
