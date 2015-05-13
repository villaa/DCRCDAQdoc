onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/cpldrst
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/vxoclk0
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/cpldcs
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/rd
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/wr
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/ca
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/cd
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/phadat
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/phcvtreq
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/qcvtreq
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/qisclk
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/qosdat
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/qadcclk
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/a
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/ba
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/sdclk
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/sdcs
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/dqm
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/ras
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/cas
add wave -noupdate -format Literal /revcfpga_vhd_tst/ram_rx_state
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/burstcount
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/we
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/d
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/sdramwrtaddrreg
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/qcvt
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/phsclk
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/phcvt
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/qshiftcnt
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/phshift
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/qoshift
add wave -noupdate -format Literal /revcfpga_vhd_tst/i1/phclkdiv
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/phwrtreq
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/phshiften
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/tst(10)
add wave -noupdate -format Literal -radix hexadecimal -expand /revcfpga_vhd_tst/i1/phonon_shift
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/charge_shift
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/cvtdl
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/i1/sdwrten
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/i1/sdreadreq
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/i1/sdwrtreq
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/sdramaddr
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/acqstate
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/ramstate
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/brstcnt
add wave -noupdate -format Literal -expand /revcfpga_vhd_tst/i1/phrdreq
add wave -noupdate -format Literal -expand /revcfpga_vhd_tst/i1/qrdreq
add wave -noupdate -format Literal -radix hexadecimal -expand /revcfpga_vhd_tst/i1/charge_queue
add wave -noupdate -format Literal -radix hexadecimal -expand /revcfpga_vhd_tst/i1/phonon_queue
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/phononwords
add wave -noupdate -format Literal /revcfpga_vhd_tst/i1/tst
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {11922500 ps} 0}
configure wave -namecolwidth 239
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
WaveRestoreZoom {11758437 ps} {12086563 ps}
