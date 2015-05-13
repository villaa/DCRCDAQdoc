onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/cpldrst
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/cpldcs
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/rd
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/wr
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/ca
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/cd
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/triginitreq
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/phadat
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/phbdat
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/phcdat
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/phddat
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/phcvtreq
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/phsclk
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/vxocnt
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/phclkdiv
add wave -noupdate -format Literal -radix hexadecimal -expand /revcfpga_vhd_tst/i1/phonon_shift
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/aligncount
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/phclk
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/intpfdand
add wave -noupdate -format Literal /revcfpga_vhd_tst/i1/intpfdffl
add wave -noupdate -format Literal /revcfpga_vhd_tst/i1/intpfdff
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/phdprdaddr
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/phdpwrtaddr
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/phbaselength
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/phsigsmpllngth
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/phbaseinitcnt
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/phbaserdptr
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/phsmplrdptr
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/phsmplinitcnt
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/phproduct
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/phbaseprodreg
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/phsigprodreg
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/phthreshprod
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/phtrigdiff
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/adctimer
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/ovrsmplclken
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/ovrsmplld
add wave -noupdate -format Literal -radix hexadecimal -expand /revcfpga_vhd_tst/i1/ovrsmpl
add wave -noupdate -format Literal -radix hexadecimal -expand /revcfpga_vhd_tst/i1/phsumdat
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/phbaseadd_sub
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/phbasesumen
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/phsmpladd_sub
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/phsmplsumen
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/phbasesload
add wave -noupdate -format Literal -radix hexadecimal -expand /revcfpga_vhd_tst/i1/phbaselinesum
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/phmult_dataa
add wave -noupdate -format Literal -radix hexadecimal -expand /revcfpga_vhd_tst/i1/phsmplsum
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/phmult_datab
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/phtrig
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/qbaselinesum
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/qmult_dataa
add wave -noupdate -format Literal -radix hexadecimal -expand /revcfpga_vhd_tst/i1/qsmplsum
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/qmult_datab
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/qproduct
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/qbaseprodreg
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/qsigprodreg
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/qthreshprod
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/qtrigdiff
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/qdprdaddr
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/qdpwrtaddr
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/qbaselength
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/qbaseinitcnt
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/qbaserdptr
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/qsmplrdptr
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/qsmplinitcnt
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/qsigsmpllngth
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/phwrtreq
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/i1/qwrtreq
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/i1/qbaseadd_sub
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/i1/qsmpladd_sub
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/i1/qbasesumen
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/i1/qsmplsumen
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/trigsload
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/i1/qbasesload
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/qavgcount
add wave -noupdate -format Literal -radix hexadecimal -expand /revcfpga_vhd_tst/i1/qsumdat
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/charge_shift
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {20161348 ps} 0}
configure wave -namecolwidth 308
configure wave -valuecolwidth 162
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
WaveRestoreZoom {18765625 ps} {25328125 ps}
