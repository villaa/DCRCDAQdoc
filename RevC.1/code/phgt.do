onerror {resume}
quietly virtual signal -install /revcfpga_vhd_tst/i1 { (context /revcfpga_vhd_tst/i1 )(\Phonon_Shift[0][13]~regout\ & \Phonon_Shift[0][12]~regout\ & \Phonon_Shift[0][11]~regout\ & \Phonon_Shift[0][10]~regout\ & \Phonon_Shift[0][9]~regout\ & \Phonon_Shift[0][8]~regout\ & \Phonon_Shift[0][7]~regout\ & \Phonon_Shift[0][6]~regout\ & \Phonon_Shift[0][5]~regout\ & \Phonon_Shift[0][4]~regout\ & \Phonon_Shift[0][3]~regout\ & \Phonon_Shift[0][2]~regout\ & \Phonon_Shift[0][1]~regout\ & \Phonon_Shift[0][0]~regout\ )} Phshift0
quietly virtual signal -install /revcfpga_vhd_tst/i1 { (context /revcfpga_vhd_tst/i1 )(\PhFifoDat[0][13]~regout\ & \PhFifoDat[0][12]~regout\ & \PhFifoDat[0][11]~regout\ & \PhFifoDat[0][10]~regout\ & \PhFifoDat[0][9]~regout\ & \PhFifoDat[0][8]~regout\ & \PhFifoDat[0][7]~regout\ & \PhFifoDat[0][6]~regout\ & \PhFifoDat[0][5]~regout\ & \PhFifoDat[0][4]~regout\ & \PhFifoDat[0][3]~regout\ & \PhFifoDat[0][2]~regout\ & \PhFifoDat[0][1]~regout\ & \PhFifoDat[0][0]~regout\ )} PhFifoDat0
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/cpldrst
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/vxoclk1
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/cpldcs
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/rd
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/wr
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/qisclk
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/qisdat
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/qisync
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/qosdat
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/qosync
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/qcvtreq
add wave -noupdate -format Logic /revcfpga_vhd_tst/qcvt
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/vxoclk0
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/phcvtreq
add wave -noupdate -format Logic {/revcfpga_vhd_tst/i1/\PhPll|altpll_component|_clk0~clkctrl_INCLK_bus\(0)}
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/vxocnt
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/phclkdiv
add wave -noupdate -format Literal /revcfpga_vhd_tst/i1/\\PhPll|altpll_component|_clk0~clkctrl_INCLK_bus\\
add wave -noupdate -format Literal /revcfpga_vhd_tst/i1/intpfdff
add wave -noupdate -format Literal /revcfpga_vhd_tst/i1/intpfdffl
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/\\PhDivTC~regout\\
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/\\IntPFDAnd~combout\\
add wave -noupdate -format Literal /revcfpga_vhd_tst/i1/phwrtendl
add wave -noupdate -format Literal /revcfpga_vhd_tst/i1/aligncount
add wave -noupdate -format Logic /revcfpga_vhd_tst/phcvt
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/phsclk
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/phshiftcnt
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/phshift
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/phadat
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/\\RPha~regout\\
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/\\RPhB~regout\\
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/\\RPhC~regout\\
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/\\RPhD~regout\\
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/\\PhShiftEn~regout\\
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/\\Tst\[10\]~reg0_regout\\
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/tst(8)
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/Phshift0
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/PhFifoDat0
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/adctimer
add wave -noupdate -format Literal /revcfpga_vhd_tst/i1/vxocntdl
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/\\QADCRdy~regout\\
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/\\PhADCRdy~regout\\
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/\\OvrSmplLd~regout\\
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/\\OvrSmplClkEn~regout\\
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {4767742 ps} 0} {{Cursor 2} {7289681 ps} 0}
configure wave -namecolwidth 301
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {4403094 ps} {5254618 ps}
