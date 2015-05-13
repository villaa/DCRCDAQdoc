
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
-- Power up reset, Global clock inputs
	CpldRst, VXOClk, EncClk, ExtRef,
-- microcontroler strobes
	CpldCS, Rd, Wr,
-- Serial data from CPLD 
	DSetupRtn : in std_logic;
-- Clock, Data, Frame sync lines from charge ADCs
	QDatIA,QDatIB : in std_logic_vector(2 downto 1);
	QFR,QDCO : in std_logic;
	QADCCS,QADCSClk,QADCSDat : buffer std_logic;
-- Data from Phonon ADCs
	PhADat,PhBDat,PhCDat,PhDDat : in std_logic;
-- Convert strobes, reset for ADCs, Phonon ADC serial clock
	PhCvtReq,PhSClk,
-- PLL related outputs
	SqWv,PhDtct,ShDn,
-- CPLD Serial Link outputs
	DSetupDat,DSetupClk,DSetupSync : buffer std_logic;
-- DDS data
	Dac : buffer std_logic_vector(9 downto 0);
-- TTL inputs
	GPI : in std_logic_vector(1 downto 0 );
	PSFreq : in std_logic;
-- microcontroller address bus
	CA :in std_logic_vector(7 downto 1);
	CD : inout std_logic_vector(15 downto 0);
-- SDRAM Address and data bus
	A  : buffer std_logic_vector(12 downto 0);
	BA : buffer std_logic_vector(1 downto 0);
	D  : inout std_logic_vector(15 downto 0);
-- SDRAM control lines
	SDClk,SDCS,WE,CAS,RAS,DQM : buffer std_logic;
-- TTL Outputs
	GPO : buffer std_logic_vector(1 downto 0 );
-- LVDS Cat-5 cable bus
	LvBus : inout std_logic_vector(1 downto 0);
	DsChnRx : in std_logic_vector(1 downto 0);
	DsChnTx : buffer std_logic_vector(1 downto 0);
	LVDir,LVBusTerm : buffer std_logic;
-- Status LEDs
	StatLED : buffer std_logic_vector(1 downto 0);
-- Debug port pin
	Tst : buffer std_logic_vector(10 downto 1)
	);
end component;

-- constants                                                 
	Constant Setup_Array_size : integer := 11;
	Constant ADC_Array_size : integer := 256;

-- user defined types

	Type Setup_Data_array    is Array(0 to Setup_Array_size - 1) of std_logic_vector(15 downto 0);
	Type Setup_Address_Array is Array(0 to Setup_Array_size - 1) of std_logic_vector(7 downto 1);
  Type ADC_Array is Array(0 to ADC_Array_size - 1) of std_logic_vector(15 downto 0);

  Constant Wrt_Data : Setup_Data_array  :=(X"0000",X"0001",X"1010",X"0202",X"001F",X"0010",
                                           X"001F",X"4000",X"0020",X"0000",X"0000");

  Constant Wrt_Address : Setup_Address_Array := ("0010101","0010111","0011000","1011001","0011010",
                                                 "0011011","0011100","0111100","0010101","0000010","0000011");

  Constant Inner_Array : ADC_Array := (X"7C48",X"7C28",X"7C6C",X"7C78",X"7C84",X"7C48",X"7C58",X"7C54",
													X"7C4C",X"7C4C",X"7C28",X"7C6C",X"7C80",X"7C54",X"7C5C",X"7C4C",
													X"7C44",X"7C48",X"7C50",X"7C4C",X"7C58",X"7C54",X"7C50",X"7C40",
													X"7C48",X"7C58",X"7C64",X"7C64",X"7C64",X"7C7C",X"7C68",X"7C44",
													X"7C48",X"7C5C",X"7C68",X"7C6C",X"7C70",X"7C74",X"7C30",X"7C24",
													X"7C58",X"7C60",X"7C70",X"7C4C",X"7C5C",X"7C60",X"7C48",X"7C64",
													X"7C7C",X"7C48",X"7C54",X"7C2C",X"7C58",X"7C6C",X"7C80",X"7C4C",
													X"7C94",X"7C38",X"7C50",X"7C38",X"7C58",X"7C40",X"7C68",X"7C64",
													X"7C5C",X"7C4C",X"7C68",X"7C58",X"7C38",X"7C54",X"7C64",X"7C7C",
													X"7C38",X"7C30",X"7C60",X"7C80",X"7C30",X"7C60",X"7C58",X"7C34",
													X"7C48",X"7C3C",X"7C3C",X"7C6C",X"7C24",X"7CB4",X"7C50",X"7C3C",
													X"7C58",X"7C50",X"7C48",X"7C68",X"7C58",X"7C70",X"7C40",X"7C68",
													X"7C78",X"7C60",X"7C54",X"7C64",X"7C44",X"7C5C",X"7C68",X"7C64",
													X"7C5C",X"7C8C",X"7C74",X"7C5C",X"7C38",X"7C68",X"7C6C",X"7C54",
													X"7C34",X"7C54",X"7C5C",X"7C48",X"7C54",X"7C74",X"7C70",X"7C54",
													X"7C44",X"7C40",X"7C34",X"7C4C",X"7C60",X"7C58",X"7C5C",X"7C60",
													X"7C48",X"7C2C",X"7C48",X"7C5C",X"7C5C",X"7C38",X"7C94",X"7C6C",
													X"7C50",X"7C48",X"7C5C",X"7C54",X"7C40",X"7C3C",X"7C60",X"7C88",
													X"7C50",X"7C4C",X"7C54",X"7C4C",X"7C84",X"7C34",X"7C64",X"7C78",
													X"7C58",X"7C50",X"7C54",X"7C64",X"7C68",X"7C24",X"7C80",X"7C64",
													X"7C60",X"7C58",X"7C38",X"7C70",X"7C68",X"7C38",X"7C48",X"7C64",
													X"7C44",X"7C64",X"7C88",X"7C78",X"7C60",X"7C2C",X"7C58",X"7C74",
													X"7C4C",X"7C54",X"7C44",X"7C58",X"7C80",X"7C54",X"7C50",X"7C70",
													X"7C50",X"7C60",X"7C54",X"7C54",X"7C54",X"7C70",X"7C68",X"7C44",
													X"7C60",X"7C60",X"7C4C",X"7C84",X"7C8C",X"7C68",X"7C50",X"7C5C",
													X"7C44",X"7C84",X"7C54",X"7C64",X"7C70",X"7C54",X"7C34",X"7C50",
													X"7C58",X"7C64",X"7C50",X"7C80",X"7C74",X"7C48",X"7C28",X"7C70",
													X"7C68",X"7C60",X"7C54",X"7C6C",X"7C6C",X"7C40",X"7C34",X"7C4C",
													X"7C64",X"7C4C",X"7C6C",X"7C84",X"7C7C",X"7C3C",X"7C40",X"7C4C",
													X"7C64",X"7C38",X"7C40",X"7C5C",X"7C84",X"7C44",X"7C6C",X"7C68",
													X"7C80",X"7C24",X"7C60",X"7C48",X"7C40",X"7C2C",X"7C44",X"7C5C",
													X"7C84",X"7C5C",X"7C5C",X"7C58",X"7C5C",X"7C58",X"7C4C",X"7C64");
                                    
  Constant Outer_Array : ADC_Array := (X"8278",X"8284",X"8278",X"826C",X"827C",X"8280",X"8280",X"8268",
													X"827C",X"8280",X"8274",X"8264",X"8284",X"8274",X"8288",X"8268",
													X"828C",X"826C",X"8288",X"8260",X"8288",X"8274",X"828C",X"8268",
													X"8290",X"825C",X"8294",X"8264",X"8290",X"8278",X"828C",X"8270",
													X"8288",X"8268",X"8290",X"8274",X"828C",X"8274",X"8288",X"8274",
													X"8280",X"8270",X"8288",X"8280",X"827C",X"8278",X"827C",X"8278",
													X"8284",X"8278",X"8284",X"827C",X"827C",X"8284",X"827C",X"8278",
													X"8284",X"8264",X"8284",X"8280",X"827C",X"828C",X"8274",X"8278",
													X"827C",X"8258",X"827C",X"826C",X"827C",X"8288",X"826C",X"826C",
													X"8274",X"8264",X"8278",X"8274",X"8278",X"8280",X"8268",X"826C",
													X"827C",X"826C",X"827C",X"8278",X"8270",X"8280",X"8274",X"8270",
													X"8278",X"826C",X"8288",X"827C",X"8268",X"8278",X"8278",X"8270",
													X"8270",X"826C",X"8288",X"827C",X"826C",X"8274",X"8278",X"826C",
													X"8264",X"8274",X"8284",X"8274",X"8270",X"8278",X"8278",X"8270",
													X"8264",X"8270",X"8284",X"8274",X"8274",X"8280",X"827C",X"827C",
													X"8264",X"826C",X"8280",X"8278",X"827C",X"8284",X"8278",X"8280",
													X"8268",X"8268",X"8280",X"8274",X"827C",X"827C",X"8280",X"827C",
													X"8268",X"8268",X"8284",X"8278",X"8278",X"8278",X"8284",X"8278",
													X"826C",X"8268",X"8280",X"8284",X"8274",X"8274",X"8280",X"8278",
													X"8270",X"8270",X"8278",X"8284",X"8274",X"8274",X"8274",X"827C",
													X"826C",X"8278",X"8280",X"8280",X"8274",X"8270",X"8278",X"8280",
													X"8270",X"8288",X"8280",X"8280",X"826C",X"8278",X"8284",X"8280",
													X"827C",X"8290",X"8274",X"8278",X"8268",X"827C",X"8280",X"8280",
													X"8288",X"828C",X"826C",X"826C",X"8270",X"8278",X"827C",X"8270",
													X"8288",X"8288",X"826C",X"8270",X"827C",X"827C",X"8284",X"8268",
													X"8288",X"8284",X"826C",X"8274",X"8280",X"828C",X"8288",X"8274",
													X"827C",X"828C",X"826C",X"827C",X"827C",X"8294",X"8280",X"8284",
													X"8278",X"8288",X"8268",X"827C",X"8280",X"8290",X"8278",X"8288",
													X"827C",X"8288",X"826C",X"8280",X"8284",X"8288",X"8270",X"8284",
													X"8284",X"8280",X"8268",X"8280",X"8284",X"8284",X"826C",X"828C",
													X"8288",X"8278",X"826C",X"8288",X"8290",X"8288",X"8270",X"828C",
													X"8284",X"827C",X"826C",X"8288",X"8288",X"827C",X"8264",X"8280");

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
signal Dac : std_logic_vector(9 downto 0);
signal QDatIA,QDatIB : std_logic_vector(2 downto 1);
signal QFR,QDCO : std_logic;
signal QADCCS,QADCSClk,QADCSDat : std_logic;
signal Rd,Wr : std_logic;
signal ShDn,SqWv : std_logic;
signal StatLED : std_logic_vector(1 downto 0);
signal Tst : std_logic_vector(10 downto 1);
signal VXOClk,EncClk : std_logic;
signal BusTimer : std_logic_vector(2 downto 0);
signal PhCvt,TOscEn,Clk50 : std_logic;
signal RetDiv : std_logic_vector(1 downto 0);
signal PhShiftCnt : std_logic_vector(4 downto 0);
signal PhShift : std_logic_vector(13 downto 0);

Type RAM_Rx is (Idle,WaitBurst,IncrIndex);
signal RAM_Rx_State : RAM_Rx;
signal BurstCount : std_logic_vector(2 downto 0);

signal IntDCOClk : std_logic;
signal DDRCount : std_logic_vector(2 downto 0);
signal ADCShiftCnt : std_logic_vector(2 downto 0);

Type OutputShiftArray is Array(1 downto 0) of std_logic_vector(7 downto 0);
signal OutputShiftA,OutputShiftB : OutputShiftArray;

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
	QDatIA => QDatIA, QDatIB => QDatIB,
	QFR => QFR, QDCO => QDCO,
	QADCCS => QADCCS, QADCSClk => QADCSClk, 
	QADCSDat => QADCSDat, Dac => Dac, PSFreq => PSFreq,	
	RAS => RAS,	Rd => Rd,	SDClk => SDClk,
	SDCS => SDCS,	ShDn => ShDn,
	SqWv => SqWv,	StatLED => StatLED,
	Tst => Tst,	VXOClk => VXOClk,	EncClk => EncClk,
	WE => WE,	Wr => Wr	);

	init : process                                               
-- variable declarations                                     
begin                                                 
-- Reset generator. Issue once at the beginning
		CpldRst <= '0'; GPI <= "00";
		ExtRef <= '0'; 
		RD <= '1'; 
		D <= (others => 'Z'); ExtRef <= '0';
		DsChnRx <= "00";
		GPI <= "00";
  		wait for 50 ns;
		CpldRst <= '1';

wait;                                                       
end process init; 

CSRWrite: process(VXOClk,CpldRst)

 Variable Wrt_Index : integer range 0 to Setup_Array_size;

 begin

  if CpldRst = '0' then
		Wrt_Index := 0;
		CA <= (others => '0');
		CD <= (others => 'Z');
	  WR <= '1';
    CpldCS <= '1';
    BusTimer <= "000";
    PhCvt <= '0';
    TOscEn <= '0';

elsif rising_edge(VXOClk)

 then
     PhCvt <= PhCvtReq after 2.8 ns;
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


-- Clock the charge ADC DCO on the falling edge of IntDCOClk 
DDRClock : process(IntDCOClk,CpldRst)

begin

if CpldRst = '0' then QDCO <= '0';

elsif falling_edge(IntDCOClk)

then 
if DDRCount(0) = '1' then QDCO <='1';
else  QDCO <= '0';
end if;
end if; -- CpldRst

end process DDRClock;

-- Clock the charge ADC data sreializers on the rising edge of IntDCOClk 
QSerialize : process(IntDCOClk,CpldRst)

 Variable Data_Index : integer range 0 to ADC_Array_size;

 begin

if CpldRst = '0' then

ADCShiftCnt <= "000";
Data_Index := 0; 

OutputShiftA(0) <= X"00"; 
OutputShiftB(0) <= X"00"; 
OutputShiftA(1) <= X"00"; 
OutputShiftB(1) <= X"00"; 

DDRCount <= "000";
QDatIA <= "00";
QDatIB <= "00";
QFR <= '0';

elsif rising_edge(IntDCOClk)

then 

if Data_Index < ADC_Array_size
 
 then 

if DDRCount < 7 then DDRCount <= DDRCount + 1;
else DDRCount <= "000";
end if;

if ADCShiftCnt = 6 then QFR <= '1';
elsif ADCShiftCnt = 2 then QFR <= '0';
else QFR <= QFR;
end if;

if ADCShiftCnt = 0 then ADCShiftCnt <= "111";
elsif ADCShiftCnt /= 0 then ADCShiftCnt <= ADCShiftCnt - 1;
else ADCShiftCnt <= ADCShiftCnt;
end if;

if ADCShiftCnt = 7 then 

OutputShiftA(0) <= Inner_Array(Data_Index)(15) & Inner_Array(Data_Index)(13) & Inner_Array(Data_Index)(11) & Inner_Array(Data_Index)(9) 
					  & Inner_Array(Data_Index)(7)  & Inner_Array(Data_Index)(5)  & Inner_Array(Data_Index)(3)  & Inner_Array(Data_Index)(1);
OutputShiftB(0) <= Inner_Array(Data_Index)(14) & Inner_Array(Data_Index)(12) & Inner_Array(Data_Index)(10) & Inner_Array(Data_Index)(8) 
					  & Inner_Array(Data_Index)(6)  & Inner_Array(Data_Index)(4)  & Inner_Array(Data_Index)(2)  & Inner_Array(Data_Index)(0);

OutputShiftA(1) <= Outer_Array(Data_Index)(15) & Outer_Array(Data_Index)(13) & Outer_Array(Data_Index)(11) & Outer_Array(Data_Index)(9) 
					  & Outer_Array(Data_Index)(7)  & Outer_Array(Data_Index)(5)  & Outer_Array(Data_Index)(3)  & Outer_Array(Data_Index)(1);
OutputShiftB(1) <= Outer_Array(Data_Index)(14) & Outer_Array(Data_Index)(12) & Outer_Array(Data_Index)(10) & Outer_Array(Data_Index)(8) 
					  & Outer_Array(Data_Index)(6)  & Outer_Array(Data_Index)(4)  & Outer_Array(Data_Index)(2)  & Outer_Array(Data_Index)(0);

else

OutputShiftA(0) <= (OutputShiftA(0)(6 downto 0) & '0');
OutputShiftB(0) <= (OutputShiftB(0)(6 downto 0) & '0');

OutputShiftA(1) <= (OutputShiftA(1)(6 downto 0) & '0');
OutputShiftB(1) <= (OutputShiftB(1)(6 downto 0) & '0');

end if;

QDatIA(1) <= OutputShiftA(0)(7);
QDatIB(1) <= OutputShiftB(0)(7);
QDatIA(2) <= OutputShiftA(1)(7);
QDatIB(2) <= OutputShiftB(1)(7);

 if Data_Index < ADC_Array_size then
  if ADCShiftCnt = 1 then Data_Index := Data_Index + 1;
else Data_Index := Data_Index;
end if;

end if;

end if; -- Data_Index 

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

CpldClk : process
begin
  Clk50 <= '0';
    wait for 10 ns;
  Clk50 <= '1';
    wait for 10 ns;
end process CpldClk;

-- Use this to generate ADC outputs
intDCOClkGen : process                                           
begin 
-- 160 MHz VXO clock
    IntDCOClk <= '0';
    wait for 1562.5 ps;
    IntDCOClk <= '1';
  wait for 1562.5 ps;
end process intDCOClkGen;  

always : process                                           
begin 
-- 40 MHz VXO clock
    VXOClk <= '0';
	 EncClk <= '0';
    wait for 12.5 ns;
    VXOClk <= '1';
	 EncClk <= '1';
wait for 12.5 ns;
--WAIT;                                                        
end process always;  
      
end RevCFPGA_arch;
