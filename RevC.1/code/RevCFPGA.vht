
-- ***************************************************************************
-- This file contains a Vhdl test bench template that is freely editable to   
-- suit user's needs .Comments are provided in each section to help the user  
-- fill out necessary details.                                                
-- ***************************************************************************
-- Generated on "11/28/2010 13:07:20"
                                                            
-- Vhdl Test Bench template for design  :  RevCFPGA
-- 
-- Simulation tool : ModelSim-Altera (VHDL)
-- 

LIBRARY ieee;                                               
USE ieee.std_logic_1164.all;                                
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

ENTITY RevCFPGA_vhd_tst IS
END RevCFPGA_vhd_tst;
ARCHITECTURE RevCFPGA_arch OF RevCFPGA_vhd_tst IS

component RevCFPGA
	port (
	A : buffer std_logic_vector(12 downto 0);
	BA : buffer std_logic_vector(1 downto 0);
	CA : in std_logic_vector(7 downto 1);
	CD : inout std_logic_vector(15 downto 0);
	VXOClk0,VXOClk1,CpldCS,CpldRst,Rd,Wr : IN std_logic;
--	SDCS,SDClk,DQM,RAS,CAS,WE : buffer std_logic;
	D : inout std_logic_vector(15 downto 0);
	DsChnRx : in std_logic_vector(1 downto 0);
	DsChnTx : buffer std_logic_vector(1 downto 0);
	DSetupClk,DSetupDat,DSetupSync : buffer std_logic;
	DSetupRtn : in std_logic;
	ExtRef : in std_logic;
	GPI : in std_logic_vector(1 downto 0);
	GPO : buffer std_logic_vector(1 downto 0);
	LvBus : inout std_logic_vector(1 downto 0);
	LVBusTerm,LVDir : buffer std_logic;
	PhADat,PhBDat,PhCDat,PhDDat : in std_logic;
	PhCvtReq,PhSClk : buffer std_logic;
	PSFreq : in std_logic;
	QAdcRst,QCvtReq : buffer std_logic;
	QIBusy,QIRdERr,QISClk,QISDat,QISync : in std_logic;
	QOBusy,QORdErr,QOSclk,QOSDat,QOSync : in std_logic;
	PhDtct,ShDn,SqWv : buffer std_logic;
	StatLED : buffer std_logic_vector(1 downto 0);
	Tst : buffer std_logic_vector(10 downto 1)
	);
end component;

-- constants                                                 
	Constant Setup_Array_size : integer := 11;
	Constant ADC_Array_size : integer := 256;
	Constant DDR_Array_size : integer := 512;

-- user defined types

	Type Setup_Data_array    is Array(0 to Setup_Array_size - 1) of std_logic_vector(15 downto 0);
	Type Setup_Address_Array is Array(0 to Setup_Array_size - 1) of std_logic_vector(7 downto 1);
  Type ADC_Array is Array(0 to ADC_Array_size - 1) of std_logic_vector(15 downto 0);

  Constant Wrt_Address : Setup_Address_Array := ("0010101","0010111","0011000","0011001","0011010",
                                                 "0011011","0011100","0110011","0010101","0000010","0000011");

Constant Wrt_Data : Setup_Data_array  :=(X"0020",X"0030",X"1010",X"0202",X"001F",X"001F",
                                         X"001F",X"2000",X"0020",X"0000",X"0000");


  Constant Inner_Array : ADC_Array := (X"E1B9",X"E1B7",X"E1AF",X"E1B1",X"E1AA",X"E1AC",X"E1B7",X"E1BB",
                                       X"E1BD",X"E1B4",X"E1AE",X"E1A6",X"E1AC",X"E1B0",X"E1BC",X"E1C2",
                                       X"E1C1",X"E1BC",X"E1B2",X"E1AD",X"E1AC",X"E1B2",X"E1B6",X"E1C0",
                                       X"E1C9",X"E1C5",X"E1B2",X"E1B3",X"E1B4",X"E1AB",X"E1AA",X"E1AF",
                                       X"E1AE",X"E1B6",X"E1B9",X"E1B1",X"E1B3",X"E1B2",X"E1B6",X"E1BA",
                                       X"E1B5",X"E1B1",X"E1A8",X"E1A9",X"E1A4",X"E1AA",X"E1AA",X"E1B9",
                                       X"E1C5",X"E1C0",X"E1BA",X"E1B4",X"E1AE",X"E1AC",X"E1B2",X"E1AF",
                                       X"E1B5",X"E1B4",X"E1B0",X"E1B2",X"E1B0",X"E1AC",X"E1B5",X"E1C3",
                                       X"E1C2",X"E1C0",X"E1B4",X"E1B8",X"E1B4",X"E1BE",X"E1C2",X"E1C8",
                                       X"E1CB",X"E1BF",X"E1B0",X"E1A6",X"E1AA",X"E1A6",X"E1B0",X"E1B9",
                                       X"E1BF",X"E1B5",X"E1B0",X"E1AF",X"E1B5",X"E1B3",X"E1BC",X"E1C3",
                                       X"E1C3",X"E1BC",X"E1AC",X"E1AB",X"E1A5",X"E1B2",X"E1BA",X"E1C2",
                                       X"E1BE",X"E1C1",X"E1C3",X"E1BE",X"E1DC",X"E200",X"E2C5",X"E280",
                                       X"E1C1",X"E1BA",X"E1AD",X"E1A7",X"E1AA",X"E1A9",X"E1AD",X"E1B3",
                                       X"E1B2",X"E1AC",X"E1AC",X"E1AC",X"E1A7",X"E1AC",X"E1BA",X"E1C1",
                                       X"E1B7",X"E1B2",X"E1AC",X"E1A5",X"E1A4",X"E1A1",X"E1AA",X"E1B7",
                                       X"E1BF",X"E1B8",X"E1B5",X"E1B6",X"E1B3",X"E1B6",X"E1B5",X"E1BF",
                                       X"E1BA",X"E1BE",X"E1B7",X"E1B8",X"E1BD",X"E1C1",X"E1C1",X"E1C5",
                                       X"E1C8",X"E1BC",X"E1BB",X"E1B6",X"E1B5",X"E1B2",X"E1B8",X"E1B3",
                                       X"E1A7",X"E1A6",X"E1A1",X"E1AA",X"E1A9",X"E1B1",X"E1B3",X"E1B4",
                                       X"E1AD",X"E1A7",X"E1A0",X"E1A5",X"E1A9",X"E1B2",X"E1B6",X"E1B5",
                                       X"E1BC",X"E1BC",X"E1C2",X"E1B4",X"E1B0",X"E1AC",X"E1B1",X"E1B8",
                                       X"E1B7",X"E1B1",X"E1AA",X"E1A9",X"E1AC",X"E1BA",X"E1B7",X"E1BD",
                                       X"E1C0",X"E1B1",X"E1A8",X"E1AC",X"E1B4",X"E1B7",X"E1B9",X"E1B7",
                                       X"E1C0",X"E1B3",X"E1AD",X"E1A8",X"E1AB",X"E1AD",X"E1B3",X"E1BC",
                                       X"E1B8",X"E1B0",X"E1AA",X"E1A4",X"E1A8",X"E1B3",X"E1B9",X"E1B9",
                                       X"E1A8",X"E1A2",X"E1A4",X"E1A3",X"E1AD",X"E1BB",X"E1BB",X"E1BC",
                                       X"E1B4",X"E1AD",X"E1AE",X"E1B1",X"E1B6",X"E1BA",X"E1C4",X"E1B1",
                                       X"E1A7",X"E1A9",X"E1AA",X"E1B7",X"E1BA",X"E1C2",X"E1C5",X"E1BC",
                                       X"E1B0",X"E1AF",X"E1A1",X"E1A9",X"E1B3",X"E1B1",X"E1BA",X"E1B1",
                                       X"E1B0",X"E1A5",X"E1A8",X"E1B2",X"E1B9",X"E1C1",X"E1BE",X"E1B5",
                                       X"E1B1",X"E1B3",X"E1B4",X"E1B2",X"E1BB",X"E1C2",X"E1BC",X"E1B4");
                                    
  Constant Outer_Array : ADC_Array := (X"0014",X"0011",X"0013",X"0012",X"0012",X"0016",X"001B",X"0016",
                                       X"0009",X"FFF9",X"FFFE",X"0002",X"0005",X"000B",X"0017",X"0022",
                                       X"0015",X"000D",X"000A",X"0006",X"0006",X"000D",X"0016",X"0014",
                                       X"0009",X"0001",X"0007",X"FFFF",X"FFFC",X"0002",X"000E",X"000D",
                                       X"0000",X"FFFE",X"FFFF",X"FFFF",X"0010",X"0015",X"0015",X"0012",
                                       X"000C",X"000D",X"000A",X"0014",X"0018",X"0019",X"0022",X"0020",
                                       X"000C",X"FFFC",X"0000",X"FFFE",X"0013",X"0013",X"0019",X"0019",
                                       X"000C",X"0008",X"0009",X"0013",X"0015",X"0017",X"0011",X"0010",
                                       X"0000",X"FFFE",X"FFFB",X"FFFE",X"FFFF",X"0001",X"000B",X"000B",
                                       X"0008",X"0006",X"000B",X"0011",X"0012",X"001A",X"001D",X"000C",
                                       X"FFFD",X"0000",X"0009",X"0015",X"0018",X"001E",X"0013",X"000D",
                                       X"000B",X"000C",X"0006",X"0002",X"0007",X"000B",X"0006",X"FFF8",
                                       X"FFFC",X"0005",X"000A",X"000D",X"0011",X"001C",X"0018",X"000C",
                                       X"0007",X"0005",X"0008",X"0013",X"0017",X"0021",X"001C",X"0010",
                                       X"000D",X"000E",X"0007",X"000C",X"001D",X"001E",X"0015",X"0007",
                                       X"000D",X"0011",X"0010",X"0010",X"0017",X"0020",X"0015",X"000B",
                                       X"0003",X"0007",X"0007",X"000F",X"0019",X"0025",X"0019",X"0010",
                                       X"000D",X"0005",X"0008",X"000A",X"0014",X"0012",X"0008",X"FFF9",
                                       X"FFFF",X"FFFF",X"0007",X"0011",X"0014",X"001E",X"0014",X"0018",
                                       X"0013",X"0017",X"0011",X"0012",X"0017",X"0019",X"0008",X"0000",
                                       X"FFFE",X"0001",X"0006",X"000B",X"0017",X"0015",X"0010",X"000B",
                                       X"000C",X"0014",X"000D",X"0015",X"001B",X"0015",X"0006",X"0001",
                                       X"0002",X"000B",X"0018",X"0015",X"0013",X"0010",X"0008",X"0002",
                                       X"0000",X"0002",X"0004",X"0007",X"0008",X"000D",X"0013",X"0011",
                                       X"0004",X"FFFD",X"0002",X"0005",X"000E",X"0010",X"000D",X"0007",
                                       X"FFF8",X"FFF0",X"FFED",X"FFF9",X"0001",X"000C",X"0012",X"000F",
                                       X"0000",X"0001",X"0005",X"000C",X"0017",X"0019",X"001D",X"001A",
                                       X"0010",X"000D",X"000F",X"0010",X"000B",X"0006",X"000E",X"000C",
                                       X"0001",X"FFF8",X"FFF2",X"FFFD",X"0005",X"0010",X"0016",X"000E",
                                       X"0004",X"FFFF",X"FFFF",X"FFFE",X"0006",X"0011",X"0018",X"0006",
                                       X"001B",X"0003",X"0007",X"0000",X"0001",X"0003",X"000E",X"001D",
                                       X"001A",X"0010",X"000D",X"0010",X"0013",X"0019",X"0010",X"0018");

  Constant Phonon_Array : ADC_Array := (X"2203",X"2209",X"221D",X"220F",X"2202",X"220C",X"220A",X"220B",
                                        X"2213",X"2208",X"221C",X"2214",X"220A",X"220C",X"2212",X"2214",
                                        X"2205",X"2208",X"2218",X"2214",X"2208",X"2209",X"221C",X"2212",
                                        X"2203",X"2209",X"2220",X"2209",X"2204",X"221D",X"221A",X"2211",
                                        X"220D",X"2216",X"2212",X"21FF",X"2203",X"2212",X"2211",X"2205",
                                        X"2203",X"220E",X"2213",X"2218",X"2214",X"2217",X"2214",X"2203",
                                        X"21FB",X"220E",X"2217",X"2205",X"2210",X"221D",X"221E",X"220B",
                                        X"220D",X"220A",X"220F",X"2210",X"2213",X"2213",X"2217",X"2210",
                                        X"220E",X"2213",X"2203",X"2201",X"2215",X"2212",X"220C",X"2209",
                                        X"2218",X"2212",X"2208",X"2206",X"2214",X"2220",X"2209",X"2207",
                                        X"2213",X"221E",X"220A",X"21FF",X"220A",X"2210",X"2210",X"2210",
                                        X"2213",X"221D",X"220A",X"2206",X"2208",X"220E",X"220F",X"220C",
                                        X"2210",X"220B",X"2210",X"220E",X"2213",X"2218",X"2215",X"220D",
                                        X"2215",X"2216",X"220B",X"2208",X"2213",X"2210",X"220D",X"2210",
                                        X"2211",X"221C",X"220D",X"220B",X"2218",X"220A",X"2206",X"2219",
                                        X"2218",X"2208",X"2217",X"221D",X"2211",X"2212",X"220E",X"2217",
                                        X"2216",X"2208",X"220D",X"221C",X"2217",X"2215",X"2214",X"2217",
                                        X"220A",X"2216",X"2216",X"2212",X"2209",X"2204",X"2209",X"2213",
                                        X"220B",X"2204",X"2210",X"2212",X"220E",X"2212",X"2213",X"2215",
                                        X"2208",X"2212",X"2212",X"220E",X"2210",X"2213",X"2214",X"220C",
                                        X"2207",X"2201",X"2204",X"2211",X"220C",X"2209",X"2211",X"220D",
                                        X"2211",X"2214",X"221B",X"220F",X"21F9",X"220C",X"2218",X"2215",
                                        X"2208",X"220C",X"2217",X"2219",X"2202",X"220E",X"221E",X"2214",
                                        X"220D",X"2215",X"221F",X"220A",X"21F7",X"220F",X"2212",X"2200",
                                        X"21FD",X"2209",X"2212",X"220E",X"2208",X"220F",X"2208",X"21FF",
                                        X"2204",X"2218",X"2214",X"2200",X"2205",X"221D",X"2213",X"2203",
                                        X"2206",X"220E",X"2208",X"2211",X"2214",X"2215",X"2208",X"220B",
                                        X"220E",X"220C",X"2210",X"2200",X"2205",X"2212",X"220E",X"220F",
                                        X"2217",X"2212",X"2215",X"2218",X"221C",X"2216",X"2214",X"2201",
                                        X"220B",X"2219",X"220A",X"21FD",X"220F",X"221B",X"220F",X"2213",
                                        X"2217",X"221D",X"220E",X"2205",X"2214",X"220B",X"21FF",X"2203",
                                        X"2215",X"2219",X"2207",X"220F",X"220C",X"220D",X"2211",X"2210");

Type DDR_Array is Array(0 to DDR_Array_size - 1) of std_logic_vector(15 downto 0);

Constant DDR_Words : DDR_Array := (X"1234",X"5678",X"9ABC",X"DEF0",X"FEDC",X"BA98",X"7654",X"3210",
											  X"1122",X"3344",X"5566",X"7788",X"99AA",X"BBCC",X"DDEE",X"FF00",
											  X"EDED",X"CBCB",X"A9A9",X"8787",X"6565",X"4343",X"2121",X"0F0F",
											  X"1234",X"5678",X"9ABC",X"DEF0",X"FEDC",X"BA98",X"7654",X"3210",
											  X"1122",X"3344",X"5566",X"7788",X"99AA",X"BBCC",X"DDEE",X"FF00",
											  X"EDED",X"CBCB",X"A9A9",X"8787",X"6565",X"4343",X"2121",X"0F0F",
											  X"1122",X"3344",X"5566",X"7788",X"99AA",X"BBCC",X"DDEE",X"FF00",
											  X"EDED",X"CBCB",X"A9A9",X"8787",X"6565",X"4343",X"2121",X"0F0F",
											  X"1234",X"5678",X"9ABC",X"DEF0",X"FEDC",X"BA98",X"7654",X"3210",
											  X"1122",X"3344",X"5566",X"7788",X"99AA",X"BBCC",X"DDEE",X"FF00",
											  X"EDED",X"CBCB",X"A9A9",X"8787",X"6565",X"4343",X"2121",X"0F0F",
											  X"1234",X"5678",X"9ABC",X"DEF0",X"FEDC",X"BA98",X"7654",X"3210",
											  X"1122",X"3344",X"5566",X"7788",X"99AA",X"BBCC",X"DDEE",X"FF00",
											  X"EDED",X"CBCB",X"A9A9",X"8787",X"6565",X"4343",X"2121",X"0F0F",
											  X"1122",X"3344",X"5566",X"7788",X"99AA",X"BBCC",X"DDEE",X"FF00",
											  X"EDED",X"CBCB",X"A9A9",X"8787",X"6565",X"4343",X"2121",X"0F0F",
											  X"1234",X"5678",X"9ABC",X"DEF0",X"FEDC",X"BA98",X"7654",X"3210",
											  X"1122",X"3344",X"5566",X"7788",X"99AA",X"BBCC",X"DDEE",X"FF00",
											  X"EDED",X"CBCB",X"A9A9",X"8787",X"6565",X"4343",X"2121",X"0F0F",
											  X"1234",X"5678",X"9ABC",X"DEF0",X"FEDC",X"BA98",X"7654",X"3210",
											  X"1122",X"3344",X"5566",X"7788",X"99AA",X"BBCC",X"DDEE",X"FF00",
											  X"EDED",X"CBCB",X"A9A9",X"8787",X"6565",X"4343",X"2121",X"0F0F",
											  X"1122",X"3344",X"5566",X"7788",X"99AA",X"BBCC",X"DDEE",X"FF00",
											  X"EDED",X"CBCB",X"A9A9",X"8787",X"6565",X"4343",X"2121",X"0F0F",
											  X"1234",X"5678",X"9ABC",X"DEF0",X"FEDC",X"BA98",X"7654",X"3210",
											  X"1122",X"3344",X"5566",X"7788",X"99AA",X"BBCC",X"DDEE",X"FF00",
											  X"EDED",X"CBCB",X"A9A9",X"8787",X"6565",X"4343",X"2121",X"0F0F",
											  X"1234",X"5678",X"9ABC",X"DEF0",X"FEDC",X"BA98",X"7654",X"3210",
											  X"1122",X"3344",X"5566",X"7788",X"99AA",X"BBCC",X"DDEE",X"FF00",
											  X"EDED",X"CBCB",X"A9A9",X"8787",X"6565",X"4343",X"2121",X"0F0F",
											  X"1122",X"3344",X"5566",X"7788",X"99AA",X"BBCC",X"DDEE",X"FF00",
											  X"EDED",X"CBCB",X"A9A9",X"8787",X"6565",X"4343",X"2121",X"0F0F",
											  X"1234",X"5678",X"9ABC",X"DEF0",X"FEDC",X"BA98",X"7654",X"3210",
											  X"1122",X"3344",X"5566",X"7788",X"99AA",X"BBCC",X"DDEE",X"FF00",
											  X"EDED",X"CBCB",X"A9A9",X"8787",X"6565",X"4343",X"2121",X"0F0F",
											  X"1234",X"5678",X"9ABC",X"DEF0",X"FEDC",X"BA98",X"7654",X"3210",
											  X"1122",X"3344",X"5566",X"7788",X"99AA",X"BBCC",X"DDEE",X"FF00",
											  X"EDED",X"CBCB",X"A9A9",X"8787",X"6565",X"4343",X"2121",X"0F0F",
											  X"1122",X"3344",X"5566",X"7788",X"99AA",X"BBCC",X"DDEE",X"FF00",
											  X"EDED",X"CBCB",X"A9A9",X"8787",X"6565",X"4343",X"2121",X"0F0F",
											  X"1234",X"5678",X"9ABC",X"DEF0",X"FEDC",X"BA98",X"7654",X"3210",
											  X"1122",X"3344",X"5566",X"7788",X"99AA",X"BBCC",X"DDEE",X"FF00",
											  X"EDED",X"CBCB",X"A9A9",X"8787",X"6565",X"4343",X"2121",X"0F0F",
											  X"1234",X"5678",X"9ABC",X"DEF0",X"FEDC",X"BA98",X"7654",X"3210",
											  X"1122",X"3344",X"5566",X"7788",X"99AA",X"BBCC",X"DDEE",X"FF00",
											  X"EDED",X"CBCB",X"A9A9",X"8787",X"6565",X"4343",X"2121",X"0F0F",
											  X"1122",X"3344",X"5566",X"7788",X"99AA",X"BBCC",X"DDEE",X"FF00",
											  X"EDED",X"CBCB",X"A9A9",X"8787",X"6565",X"4343",X"2121",X"0F0F",
											  X"1234",X"5678",X"9ABC",X"DEF0",X"FEDC",X"BA98",X"7654",X"3210",
											  X"1122",X"3344",X"5566",X"7788",X"99AA",X"BBCC",X"DDEE",X"FF00",
											  X"EDED",X"CBCB",X"A9A9",X"8787",X"6565",X"4343",X"2121",X"0F0F",
											  X"1234",X"5678",X"9ABC",X"DEF0",X"FEDC",X"BA98",X"7654",X"3210",
											  X"1122",X"3344",X"5566",X"7788",X"99AA",X"BBCC",X"DDEE",X"FF00",
											  X"EDED",X"CBCB",X"A9A9",X"8787",X"6565",X"4343",X"2121",X"0F0F",
											  X"1122",X"3344",X"5566",X"7788",X"99AA",X"BBCC",X"DDEE",X"FF00",
											  X"EDED",X"CBCB",X"A9A9",X"8787",X"6565",X"4343",X"2121",X"0F0F",
											  X"1234",X"5678",X"9ABC",X"DEF0",X"FEDC",X"BA98",X"7654",X"3210",
											  X"1122",X"3344",X"5566",X"7788",X"99AA",X"BBCC",X"DDEE",X"FF00",
											  X"EDED",X"CBCB",X"A9A9",X"8787",X"6565",X"4343",X"2121",X"0F0F",
											  X"1234",X"5678",X"9ABC",X"DEF0",X"FEDC",X"BA98",X"7654",X"3210",
											  X"1122",X"3344",X"5566",X"7788",X"99AA",X"BBCC",X"DDEE",X"FF00",
											  X"EDED",X"CBCB",X"A9A9",X"8787",X"6565",X"4343",X"2121",X"0F0F",
											  X"1122",X"3344",X"5566",X"7788",X"99AA",X"BBCC",X"DDEE",X"FF00",
											  X"EDED",X"CBCB",X"A9A9",X"8787",X"6565",X"4343",X"2121",X"0F0F");

-- signals                                                   
signal A : std_logic_vector(12 downto 0);
signal BA : std_logic_vector(1 downto 0);
signal CA : std_logic_vector(7 downto 1);
signal SDClk,SDCS,DQM,RAS,CAS,WE : std_logic;
signal CD : std_logic_vector(15 downto 0);
signal CpldCS,CpldRst : std_logic;
signal D : std_logic_vector(15 downto 0);
signal DsChnRx,DsChnTx : std_logic_vector(1 downto 0);
signal DSetupClk,DSetupDat,DSetupRtn,DSetupSync : std_logic;
signal ExtRef : std_logic;
signal GPI,GPO : std_logic_vector(1 downto 0);
signal LvBus : std_logic_vector(1 downto 0);
signal LVBusTerm,LVDir : std_logic;
signal PhADat,PhBDat,PhCDat,PhDDat,PhCvtReq : std_logic;
signal PhDtct,PhSClk,PSFreq : std_logic;
signal QAdcRst,QCvtReq,QIBusy,QIRdERr,QISClk,QISDat,QISync : std_logic;
signal QOBusy,QORdErr,QOSclk,QOSDat,QOSync : std_logic;
signal Rd,Wr : std_logic;
signal ShDn,SqWv : std_logic;
signal StatLED : std_logic_vector(1 downto 0);
signal Tst : std_logic_vector(10 downto 1);
signal VXOClk0 : std_logic;
signal VXOClk1 : std_logic;

signal BusTimer : std_logic_vector(2 downto 0);

signal QADCClk,QCvt,PhCvt,TOscEn,Clk50 : std_logic;
signal RetDiv : std_logic_vector(1 downto 0);
signal QShiftCnt : std_logic_vector(5 downto 0);
signal QIShift,QOShift : std_logic_vector(15 downto 0);
signal PhShiftCnt : std_logic_vector(4 downto 0);
signal PhShift : std_logic_vector(13 downto 0);

signal CvtDl : std_logic_vector(1 downto 0);

Type RAM_Rx is (Idle,WaitBurst,IncrIndex);
signal RAM_Rx_State : RAM_Rx;
signal BurstCount : std_logic_vector(2 downto 0);

begin
	i1 : RevCFPGA
	port map (
-- list connections between master ports and signals
	A => A, BA => BA,	CA => CA,
	CAS => CAS,	CD => CD,
	CpldCS => CpldCS,	CpldRst => CpldRst,
	D => D,	DQM => DQM,
	DsChnRx => DsChnRx,	DsChnTx => DsChnTx,
	DSetupClk => DSetupClk,	DSetupDat => DSetupDat,
	DSetupRtn => DSetupRtn,	DSetupSync => DSetupSync,
	ExtRef => ExtRef,	GPI => GPI,	GPO => GPO,	
	LvBus => LvBus,	LVBusTerm => LVBusTerm,	LVDir => LVDir,
	PhADat => PhADat,	PhBDat => PhBDat,	PhCDat => PhCDat,
	PhCvtReq => PhCvtReq,	PhDDat => PhDDat,
	PhDtct => PhDtct,	PhSClk => PhSClk,
	PSFreq => PSFreq,	QAdcRst => QAdcRst,
	QCvtReq => QCvtReq,	QIBusy => QIBusy,
	QIRdERr => QIRdERr,	QISClk => QISClk,
	QISDat => QISDat,	QISync => QISync,
	QOBusy => QOBusy,	QORdErr => QORdErr,
	QOSclk => QOSclk,	QOSDat => QOSDat,
	QOSync => QOSync,	RAS => RAS,
	Rd => Rd,	SDClk => SDClk,
	SDCS => SDCS,	ShDn => ShDn,
	SqWv => SqWv,	StatLED => StatLED,
	Tst => Tst,	VXOClk0 => VXOClk0,	VXOClk1 => VXOClk1,
	WE => WE,	Wr => Wr	);

	init : process                                               
-- variable declarations                                     
begin                                                 
-- Reset generator. Issue once at the beginning
		CpldRst <= '0'; GPI <= "00";
		ExtRef <= '0'; QIBusy <= '0'; QOBusy <= '0';
		QIRdErr <= '0'; QORdErr <= '0'; 
		RD <= '1'; QISync <= '0'; QOSync <= '0';
		D <= (others => 'Z'); ExtRef <= '0';
		DsChnRx <= "00";
		GPI <= "00";
  		wait for 50 ns;
		CpldRst <= '1';

wait;                                                       
end process init; 

CSRWrite: process(VXOClk0,CpldRst)

 Variable Wrt_Index : integer range 0 to Setup_Array_size;

 begin

  if CpldRst = '0' then
		Wrt_Index := 0;
		CA <= (others => '0');
		CD <= (others => 'Z');
	  WR <= '1';
    CpldCS <= '1';
    BusTimer <= "000";
    QCvt <= '1'; PhCvt <= '0';
    TOscEn <= '0';
 elsif rising_edge(VXOClk0)

 then
     PhCvt <= PhCvtReq after 2.8 ns;
     QCvt <= QCvtReq after 2.8 ns;
     BusTimer <= BusTimer + 1;

	  if WR = '0' and CpldCs = '0' and CA = "0111100"
	  then TOscEn <= CD(14);
	  else TOscEn <= TOscEn;
	  end if;
	  
 if Wrt_Index < Setup_Array_size then

		if BusTimer >= 3 and BusTimer <= 6
		then
 	     CA <= Wrt_Address(Wrt_Index);
       CD <= Wrt_Data(Wrt_Index);
		 else
       CD <= (Others => 'Z');
       CA <= (Others => 'Z');
		 end if;
-- Send data with chip select
	    if BusTimer = 3
	    then CpldCS <= '0';
	    elsif BusTimer = 6
	    then  CpldCS <= '1';
	    else CpldCS <= CpldCS;
	    end if;

	    if  BusTimer = 4 or BusTimer = 5 then WR <= '0'; 
	    else WR <= '1';
	    end if;
	    if  BusTimer = 7 then Wrt_Index := Wrt_Index + 1;
	    else Wrt_Index := Wrt_Index;
	    end if;

-- Set WR_En <= '0' after the last write

else
     CpldCS <= CpldCS;
     WR <= WR;
	  CD <= CD;
	  Wrt_Index := Wrt_Index;

end if;

end if; -- rising edge

end process CSRWrite;


QSerialize : process(QADCClk,CpldRst)

 Variable Q_Index : integer range 0 to ADC_Array_size;

 begin

if CpldRst = '0' then

QShiftCnt <= "000000";
Q_Index := 0;  QIShift <= X"0000";
QISDat <= '0'; QOShift <= X"0000";
QOSDat <= '0';
CvtDl <= "00";

elsif rising_edge(QADCClk)

then 

CvtDl(0) <= not QCvt;
CvtDl(1) <= CvtDl(0);

if QShiftCnt = 0 and CvtDl = 1 then QShiftCnt <= "101000";
elsif QShiftCnt /= 0 then QShiftCnt <= QShiftCnt - 1;
else QShiftCnt <= QShiftCnt;
end if;

if QShiftCnt > 18 then 
  QISClk <= not QShiftCnt(0);
  QOSClk <= not QShiftCnt(0);
else 
  QISClk <= QShiftCnt(1);
  QOSClk <= QShiftCnt(1);
end if;

if QShiftCnt = 0 and CvtDl = 1 then 
  QIShift <= Inner_Array(Q_Index);
  QOShift <= Outer_Array(Q_Index);
elsif 
    (QShiftCnt > 18 and QShiftCnt(0) = '1')
or (QShiftCnt /= 0 and QShiftCnt <= 18 and  QShiftCnt(1 downto 0) = 0)
   then 
    QIShift <= (QIshift(14 downto 0) & '0');
    QOShift <= (QOshift(14 downto 0) & '0');
else 
    QIShift <= QIShift;
    QOShift <= QOShift;
end if;
QISDat <= QIshift(15);
QOSDat <= QOshift(15);

 if Q_Index < ADC_Array_size then
  if QShiftCnt = 1 then Q_Index := Q_Index + 1;
else Q_Index := Q_Index;
end if;
end if;

end if; -- rising edge

end process QSerialize;

PhSerialize : process(PhSClk,CpldRst)

 Variable Ph_Index : integer range 0 to ADC_Array_size;

 begin

if CpldRst = '0' then

PhShiftCnt <= "00000";
Ph_Index := 0; PhShift <= (others => '0');
PHADat <= '0'; PhBDat <= '0';
PHCDat <= '0'; PhDDat <= '0';

elsif rising_edge(PhSClk)

then 

if PhShiftCnt = 0 and PhCvt = '1' then PhShiftCnt <= "10001";
elsif PhShiftCnt /= 0 then PhShiftCnt <= PhShiftCnt - 1;
else PhShiftCnt <= PhShiftCnt;
end if;

if PhShiftCnt = 17 then 
PhShift <= Phonon_Array(Ph_Index)(13 downto 0);
elsif 
    PhShiftCnt <= 17 and PhShiftCnt /= 0
    then PhShift <= (PhShift(12 downto 0) & '0');
else 
    PhShift <= PhShift;
end if;

if PhShiftCnt = 17 or PhShiftCnt = 2 or PhShiftCnt = 1 or PhShiftCnt = 0 then 
PhADat <= 'Z' after 6 ns;
PhBDat <= 'Z' after 6 ns;
PhCDat <= 'Z' after 6 ns;
PhDDat <= 'Z' after 6 ns;
else
PhADat <= PhShift(13) after 6 ns;
PhBDat <= PhShift(13) after 6 ns;
PhCDat <= PhShift(13) after 6 ns;
PhDDat <= PhShift(13) after 6 ns;
end if;

 if Ph_Index < ADC_Array_size then
  if PhShiftCnt = 1 then Ph_Index := Ph_Index + 1;
else Ph_Index := Ph_Index;
end if;
end if;

end if; -- rising edge

end process PhSerialize;

RAM_Rd_Data : Process(SDClk,CpldRst)

 Variable RAM_Index : integer range 0 to DDR_Array_size;

 begin

if CpldRst = '0' then

 BurstCount <= "000"; 
 RAM_Index := 0; D <= (others => 'Z');

elsif rising_edge(SDClk)

	then

	if RAM_Index < DDR_Array_size
   then 
-- Idle,WaitBurst,IncrIndex
	Case RAM_Rx_State is
		When Idle =>
		  if SDCS = '0' and RAS = '1' and CAS = '0' and WE = '1'
			then RAM_Rx_State <= WaitBurst;
		  else RAM_Rx_State <= Idle;
		  end if;
		 when WaitBurst => 
			if BurstCount = 0
				then RAM_Rx_State <= IncrIndex;
			else RAM_Rx_State <= WaitBurst;
			end if;
		When IncrIndex => RAM_Rx_State <= Idle; 
	end case;

if RAM_Rx_State = Idle and SDCS = '0' and RAS = '1' and CAS = '0' and WE = '1' then BurstCount <= "111";
 elsif RAM_Rx_State = WaitBurst and BurstCount > 0
 then BurstCount <= BurstCount - 1;
 else BurstCount <= BurstCount;
 end if;

 if RAM_Rx_State = WaitBurst
 then D <= DDR_Words(RAM_Index) after 5.4 ns;
 else D <= (others => 'Z');
 end if;
 
 if RAM_Rx_State = WaitBurst
  then RAM_Index := RAM_Index + 1;
 else RAM_Index := RAM_Index;
 end if;
 
 end if; -- RAM_Index

end if; -- rising edge

end process	RAM_Rd_Data;

-- When OscEn is set, put 12.5Mhz on the DSetupRtn Line
Dret : Process(Clk50,CpldRst)
 begin
if CpldRst = '0' then
	  DSetupRtn <= '0'; 
	  RetDiv <= "00";
elsif rising_edge(Clk50)
	  then
	  	 if TOscEn = '1' then RetDiv <= RetDiv + 1;
		 else RetDiv <= "00";
		 end if;
  	 if TOscEn = '1' then DSetupRtn <= RetDiv(1);
	 else DSetupRtn <= '0';
	 end if;
end if;
end process Dret;


QClk : process
begin
  QADCClk <= '0';
    wait for 2.5 ns;
    QADCClk <= '1';
   wait for 2.5 ns;
end process QClk;

CpldClk : process
begin
  Clk50 <= '0';
    wait for 10 ns;
  Clk50 <= '1';
    wait for 10 ns;
end process CpldClk;

always : process                                           
begin 
-- 40 MHz VXO clock
    VXOClk0 <= '0';
    VXOClk1 <= '0';
    wait for 12.5 ns;
    VXOClk0 <= '1';
    VXOClk1 <= '1';
wait for 12.5 ns;
--WAIT;                                                        
end process always;  
      
end RevCFPGA_arch;
