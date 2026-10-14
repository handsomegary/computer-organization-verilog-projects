# Rebuild a behavioral simulation project from committed relative sources.
# API baseline: AMD/Xilinx UG835 2018.3 and UG900 2019.2.
# No original workstation paths or FPGA pin constraints are needed.
set org_root [file normalize [file join [file dirname [info script]] ..]]
if {[file isdirectory [file join $org_root reference rtl]]} {
    set org_package $org_root
} elseif {[file isdirectory [file join $org_root repaired reference rtl]]} {
    set org_package [file join $org_root repaired]
} else {
    error "Missing reference/rtl or repaired/reference/rtl package"
}
set org_variant reference
set org_part xc7a35tcsg324-1
set org_out [file join $org_root vivado-sim]
set org_run 0
set org_check_only 0
if {![info exists argv]} {set argv {}}
for {set org_i 0} {$org_i < [llength $argv]} {incr org_i} {
    set org_arg [lindex $argv $org_i]
    switch -- $org_arg {
        -run {set org_run 1}
        -check-only {set org_check_only 1}
        -variant - -part - -out-dir {
            incr org_i
            if {$org_i >= [llength $argv]} {error "Missing value for $org_arg"}
            set org_value [lindex $argv $org_i]
            switch -- $org_arg {
                -variant {set org_variant $org_value}
                -part {set org_part $org_value}
                -out-dir {set org_out [file normalize $org_value]}
            }
        }
        default {error "Unknown option $org_arg"}
    }
}
set org_project computer_organization_sim
set org_rtl {}
set org_bench {}
switch -- $org_variant {
    reference {
        set org_rtl [list [file join $org_package reference rtl mips_single_cycle.v] [file join $org_package reference rtl mips_pipeline.v]]
        set org_bench [list [file join $org_package verification reference_demo_tb.v]]
        set org_design_top mips_single_cycle
        set org_sim_top reference_demo_tb
        set org_pass_marker {REFERENCE DEFAULT ROM PASS}
    }
    s02-single-cycle - s02-pipeline - s02-hazard - s03-single-cycle - s03-pipeline {
        switch -- $org_variant {
            s02-single-cycle {set org_rel sources/02-final-pj/single-cycle; set org_design_top CPU_SingleCycle; set org_sim_top CPU_SingleCycle_tb}
            s02-pipeline {set org_rel sources/02-final-pj/pipeline; set org_design_top CPU_Pipeline; set org_sim_top CPU_Pipeline_tb}
            s02-hazard {set org_rel sources/02-final-pj/hazard; set org_design_top CPU_NoHazard; set org_sim_top CPU_NoHazard_tb}
            s03-single-cycle {set org_rel sources/03-final-project-rar/single-cycle; set org_design_top CPU_SingleCycle; set org_sim_top CPU_SingleCycle_tb}
            s03-pipeline {set org_rel sources/03-final-project-rar/pipeline; set org_design_top CPU_Pipeline; set org_sim_top CPU_Pipeline_tb}
        }
        set org_rtl [lsort [glob -nocomplain -types f [file join $org_package $org_rel rtl *.v]]]
        set org_bench [lsort [glob -nocomplain -types f [file join $org_package $org_rel tb *.v]]]
        set org_pass_marker PASS
    }
    default {error "Unknown variant $org_variant"}
}
if {[llength $org_rtl] == 0 || [llength $org_bench] != 1} {
    error "Incomplete sources for variant $org_variant"
}
foreach org_file [concat $org_rtl $org_bench] {
    if {![file isfile $org_file]} {error "Required source missing: $org_file"}
}
if {[file exists $org_out]} {
    error "Output path already exists; choose a new -out-dir (nothing overwritten)"
}
puts "Selected $org_variant: [llength $org_rtl] RTL files, [llength $org_bench] testbench; part $org_part"
if {$org_check_only} {
    puts "SOURCE PREFLIGHT ONLY: no Vivado project creation or simulation performed"
    return
}
if {[llength [info commands create_project]] == 0} {
    error "Run this script with Vivado; plain Tcl supports -check-only"
}
# Deliberately omit -force: an existing project must never be overwritten.
create_project $org_project $org_out -part $org_part
set_property target_language Verilog [current_project]
set_property target_simulator XSim [current_project]
set_property source_mgmt_mode None [current_project]
add_files -norecurse -fileset sources_1 $org_rtl
add_files -norecurse -fileset sim_1 $org_bench
# Self-checking .v testbenches use the SystemVerilog $fatal task.
set_property file_type SystemVerilog [get_files $org_bench]
set_property top $org_design_top [get_filesets sources_1]
set_property top $org_sim_top [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
if {$org_run} {
    set_property xsim.simulate.runtime 0ns [get_filesets sim_1]
    # No -quiet: compile/elaboration errors must propagate.
    launch_simulation -mode behavioral -simset sim_1
    run -all
    close_sim
    set org_sim_dir [file join $org_out [format {%s.sim} $org_project] sim_1 behav xsim]
    set org_log_text ""
    foreach org_log [glob -nocomplain -types f [file join $org_sim_dir *.log]] {
        set org_handle [open $org_log r]
        append org_log_text [read $org_handle] "\n"
        close $org_handle
    }
    if {[regexp -nocase -line {^[ \t]*(FAIL|FATAL|ERROR)([ :]|$)} $org_log_text]} {
        error "Simulation log contains a failure; inspect $org_sim_dir"
    }
    if {[string first $org_pass_marker $org_log_text] < 0} {
        error "Self-checking testbench PASS marker not found; inspect $org_sim_dir"
    }
    puts "VIVADO TESTBENCH PASS marker verified for $org_variant"
}
close_project
puts "Project file: [file join $org_out [format {%s.xpr} $org_project]]"
