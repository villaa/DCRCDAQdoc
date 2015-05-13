onerror {resume}
quietly virtual signal -install /revcfpga_vhd_tst/i1 { (context /revcfpga_vhd_tst/i1 )(\ADC_Stage[0][15]~regout\ & \ADC_Stage[0][14]~regout\ & \ADC_Stage[0][13]~regout\ & \ADC_Stage[0][12]~regout\ & \ADC_Stage[0][11]~regout\ & \ADC_Stage[0][10]~regout\ & \ADC_Stage[0][9]~regout\ & \ADC_Stage[0][8]~regout\ & \ADC_Stage[0][7]~regout\ & \ADC_Stage[0][6]~regout\ & \ADC_Stage[0][5]~regout\ & \ADC_Stage[0][4]~regout\ & \ADC_Stage[0][3]~regout\ & \ADC_Stage[0][2]~regout\ & \ADC_Stage[0][1]~regout\ & \ADC_Stage[0][0]~regout\ )} ADC_Stage0
quietly virtual signal -install /revcfpga_vhd_tst/i1 { (context /revcfpga_vhd_tst/i1 )(\ADC_Stage[1][15]~regout\ & \ADC_Stage[1][14]~regout\ & \ADC_Stage[1][13]~regout\ & \ADC_Stage[1][12]~regout\ & \ADC_Stage[1][11]~regout\ & \ADC_Stage[1][10]~regout\ & \ADC_Stage[1][9]~regout\ & \ADC_Stage[1][8]~regout\ & \ADC_Stage[1][7]~regout\ & \ADC_Stage[1][6]~regout\ & \ADC_Stage[1][5]~regout\ & \ADC_Stage[1][4]~regout\ & \ADC_Stage[1][3]~regout\ & \ADC_Stage[1][2]~regout\ & \ADC_Stage[1][1]~regout\ & \ADC_Stage[1][0]~regout\ )} ADC_Stage1
quietly virtual signal -install /revcfpga_vhd_tst/i1 { (context /revcfpga_vhd_tst/i1 )(\ADC_In_h0[0][4]~regout\ & \ADC_In_h0[0][3]~regout\ & \ADC_In_h0[0][2]~regout\ & \ADC_In_h0[0][1]~regout\ & \ADC_In_h0[0][0]~regout\ )} H00
quietly virtual signal -install /revcfpga_vhd_tst/i1 { (context /revcfpga_vhd_tst/i1 )(\ADC_In_h1[0][4]~regout\ & \ADC_In_h1[0][3]~regout\ & \ADC_In_h1[0][2]~regout\ & \ADC_In_h1[0][1]~regout\ & \ADC_In_h1[0][0]~regout\ )} H10
quietly virtual signal -install /revcfpga_vhd_tst/i1 { (context /revcfpga_vhd_tst/i1 )(\ADC_In_l0[0][3]~regout\ & \ADC_In_l0[0][2]~regout\ & \ADC_In_l0[0][1]~regout\ & \ADC_In_l0[0][0]~regout\ )} L00
quietly virtual signal -install /revcfpga_vhd_tst/i1 { (context /revcfpga_vhd_tst/i1 )(\ADC_In_l1[0][3]~regout\ & \ADC_In_l1[0][2]~regout\ & \ADC_In_l1[0][1]~regout\ & \ADC_In_l1[0][0]~regout\ )} L10
quietly virtual signal -install /revcfpga_vhd_tst/i1 { (context /revcfpga_vhd_tst/i1 )(\ADC_In_h1[1][4]~regout\ & \ADC_In_h1[1][3]~regout\ & \ADC_In_h1[1][2]~regout\ & \ADC_In_h1[1][1]~regout\ & \ADC_In_h1[1][0]~regout\ )} H11
quietly virtual signal -install /revcfpga_vhd_tst/i1 { (context /revcfpga_vhd_tst/i1 )(\ADC_In_h0[1][4]~regout\ & \ADC_In_h0[1][3]~regout\ & \ADC_In_h0[1][2]~regout\ & \ADC_In_h0[1][1]~regout\ & \ADC_In_h0[1][0]~regout\ )} H01
quietly virtual signal -install /revcfpga_vhd_tst/i1 { (context /revcfpga_vhd_tst/i1 )(\ADC_In_l1[1][3]~regout\ & \ADC_In_l1[1][2]~regout\ & \ADC_In_l1[1][1]~regout\ & \ADC_In_l1[1][0]~regout\ )} L11
quietly virtual signal -install /revcfpga_vhd_tst/i1 { (context /revcfpga_vhd_tst/i1 )(\ADC_In_l0[1][3]~regout\ & \ADC_In_l0[1][2]~regout\ & \ADC_In_l0[1][1]~regout\ & \ADC_In_l0[1][0]~regout\ )} L01
quietly WaveActivateNextPane {} 0
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/i1/cpldrst
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/i1/vxoclk
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/i1/cpldcs
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/i1/rd
add wave -noupdate -format Logic -radix hexadecimal /revcfpga_vhd_tst/i1/wr
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/ca
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/cd
add wave -noupdate -format Literal /revcfpga_vhd_tst/i1/qdatia
add wave -noupdate -format Literal /revcfpga_vhd_tst/i1/qdatib
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/qdatia(1)
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/qdatib(1)
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/qdatia(2)
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/qdatib(2)
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/qfr
add wave -noupdate -format Literal /revcfpga_vhd_tst/i1/qfrdl
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/qdco
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/phadat
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/phcvtreq
add wave -noupdate -format Logic /revcfpga_vhd_tst/i1/phsclk
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/ADC_Stage0
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/ADC_Stage1
add wave -noupdate -group Stage0 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[0\]\[15\]~regout\\
add wave -noupdate -group Stage0 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[0\]\[14\]~regout\\
add wave -noupdate -group Stage0 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[0\]\[13\]~regout\\
add wave -noupdate -group Stage0 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[0\]\[12\]~regout\\
add wave -noupdate -group Stage0 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[0\]\[11\]~regout\\
add wave -noupdate -group Stage0 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[0\]\[10\]~regout\\
add wave -noupdate -group Stage0 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[0\]\[9\]~regout\\
add wave -noupdate -group Stage0 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[0\]\[8\]~regout\\
add wave -noupdate -group Stage0 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[0\]\[7\]~regout\\
add wave -noupdate -group Stage0 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[0\]\[6\]~regout\\
add wave -noupdate -group Stage0 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[0\]\[5\]~regout\\
add wave -noupdate -group Stage0 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[0\]\[4\]~regout\\
add wave -noupdate -group Stage0 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[0\]\[3\]~regout\\
add wave -noupdate -group Stage0 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[0\]\[2\]~regout\\
add wave -noupdate -group Stage0 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[0\]\[1\]~regout\\
add wave -noupdate -group Stage0 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[0\]\[0\]~regout\\
add wave -noupdate -group Stage1 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[1\]\[15\]~regout\\
add wave -noupdate -group Stage1 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[1\]\[14\]~regout\\
add wave -noupdate -group Stage1 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[1\]\[13\]~regout\\
add wave -noupdate -group Stage1 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[1\]\[12\]~regout\\
add wave -noupdate -group Stage1 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[1\]\[11\]~regout\\
add wave -noupdate -group Stage1 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[1\]\[10\]~regout\\
add wave -noupdate -group Stage1 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[1\]\[9\]~regout\\
add wave -noupdate -group Stage1 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[1\]\[8\]~regout\\
add wave -noupdate -group Stage1 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[1\]\[7\]~regout\\
add wave -noupdate -group Stage1 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[1\]\[6\]~regout\\
add wave -noupdate -group Stage1 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[1\]\[5\]~regout\\
add wave -noupdate -group Stage1 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[1\]\[4\]~regout\\
add wave -noupdate -group Stage1 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[1\]\[3\]~regout\\
add wave -noupdate -group Stage1 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[1\]\[2\]~regout\\
add wave -noupdate -group Stage1 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[1\]\[1\]~regout\\
add wave -noupdate -group Stage1 -format Logic /revcfpga_vhd_tst/i1/\\ADC_Stage\[1\]\[0\]~regout\\
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/H00
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/H10
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/L00
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/L10
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/H01
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/H11
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/L11
add wave -noupdate -format Literal -radix hexadecimal /revcfpga_vhd_tst/i1/L01
add wave -noupdate -group Gh00 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_h0\[0\]\[4\]~regout\\
add wave -noupdate -group Gh00 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_h0\[0\]\[3\]~regout\\
add wave -noupdate -group Gh00 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_h0\[0\]\[2\]~regout\\
add wave -noupdate -group Gh00 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_h0\[0\]\[1\]~regout\\
add wave -noupdate -group Gh00 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_h0\[0\]\[0\]~regout\\
add wave -noupdate -group GH10 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_h1\[0\]\[4\]~regout\\
add wave -noupdate -group GH10 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_h1\[0\]\[3\]~regout\\
add wave -noupdate -group GH10 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_h1\[0\]\[2\]~regout\\
add wave -noupdate -group GH10 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_h1\[0\]\[1\]~regout\\
add wave -noupdate -group GH10 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_h1\[0\]\[0\]~regout\\
add wave -noupdate -group GL00 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_l0\[0\]\[3\]~regout\\
add wave -noupdate -group GL00 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_l0\[0\]\[2\]~regout\\
add wave -noupdate -group GL00 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_l0\[0\]\[1\]~regout\\
add wave -noupdate -group GL00 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_l0\[0\]\[0\]~regout\\
add wave -noupdate -group GL10 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_l1\[0\]\[3\]~regout\\
add wave -noupdate -group GL10 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_l1\[0\]\[2\]~regout\\
add wave -noupdate -group GL10 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_l1\[0\]\[1\]~regout\\
add wave -noupdate -group GL10 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_l1\[0\]\[0\]~regout\\
add wave -noupdate -group GH11 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_h1\[1\]\[4\]~regout\\
add wave -noupdate -group GH11 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_h1\[1\]\[3\]~regout\\
add wave -noupdate -group GH11 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_h1\[1\]\[2\]~regout\\
add wave -noupdate -group GH11 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_h1\[1\]\[1\]~regout\\
add wave -noupdate -group GH11 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_h1\[1\]\[0\]~regout\\
add wave -noupdate -group GH01 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_h0\[1\]\[4\]~regout\\
add wave -noupdate -group GH01 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_h0\[1\]\[3\]~regout\\
add wave -noupdate -group GH01 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_h0\[1\]\[2\]~regout\\
add wave -noupdate -group GH01 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_h0\[1\]\[1\]~regout\\
add wave -noupdate -group GH01 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_h0\[1\]\[0\]~regout\\
add wave -noupdate -group GL11 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_l1\[1\]\[3\]~regout\\
add wave -noupdate -group GL11 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_l1\[1\]\[2\]~regout\\
add wave -noupdate -group GL11 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_l1\[1\]\[1\]~regout\\
add wave -noupdate -group GL11 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_l1\[1\]\[0\]~regout\\
add wave -noupdate -group GL01 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_l0\[1\]\[3\]~regout\\
add wave -noupdate -group GL01 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_l0\[1\]\[2\]~regout\\
add wave -noupdate -group GL01 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_l0\[1\]\[1\]~regout\\
add wave -noupdate -group GL01 -format Logic /revcfpga_vhd_tst/i1/\\ADC_In_l0\[1\]\[0\]~regout\\
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {307509 ps} 0}
configure wave -namecolwidth 328
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
WaveRestoreZoom {0 ps} {6300 ns}
