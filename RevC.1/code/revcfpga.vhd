-- FPGA for Digital Control and Readout Card (DCRC)
-- Sten Hansen 	Fermilab   04/25/2008

-- FPGA responsible for de-serializing ADC data, SDRAM controller,
-- interface to CPLD in the analog section, buffer manager
-- trigger logic, microcontroller interface

-- 04/25/08 convert Rev A equations from AHDL to VHDL
-- 07/16/08 implement simple SDRAM interface, expanded adressing, CPLD serial link
-- 11/18/08 implement averaging by 64
-- 11/25/08 implement self triggers
-- 12/01/08 implement phase detector
-- 12/09/08 implement DDS frequency sweep logic, add phase data to phonon data
-- stream during the frequency sweep
-- 08/19/09 Added scratch pad RAM shadowing CPLD data for local readback of written values
-- 10/21/09 Added register to record write address synched to test signal
-- 04/15/10 Changed charge trigger to be based on  absolute value of data excursion
-- 05/03/10 first set of equations for Rev C.
-- 10/16/10 Add independent deadtime generators for each channel
--				Add trigger FIFO word count readback
--				Add Serial link communication
-- 03/20/12 First set of equations for Rev C.1.
--				Split project into 3 files as a start
-- 			Changed Phonon SClk to 45 MHz, changed clock train synching
--				Changed SDRAM interface to 50MHz clocking from 100MHz
-- 04/17/12 Change charge ADC data format to LVDS 2 bit serial

----------------------------- Main Body of design -------------------------

LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.Global_Defs.all;

--LIBRARY altera_mf;
--USE altera_mf.all;
--LIBRARY lpm;
--USE lpm.lpm_components.all;

entity RevCFPGA is port(

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
-- CPLD Serial Link outputs, make this link do double duty for DDS setup
	DSetupDat,DSetupClk,DSetupSync : buffer std_logic;
-- TTL inputs
	GPI : in std_logic_vector(1 downto 0 );
	PSFreq : in std_logic;
-- microcontroller address bus
	CA :in AddrPtr;
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
	Dac : buffer std_logic_vector(9 downto 0);
-- Status LEDs
	StatLED : buffer std_logic_vector(1 downto 0);
-- Debug port pin
	Tst : buffer std_logic_vector(10 downto 1)
	);
end RevCFPGA;

architecture behavioural of RevCFPGA is

---------------------- Type and signal declarations -----------------------

-- There are four 14 bit phonon ADCs and two 16 bit charge ADCs
Type Phonon_Array is Array (3 downto 0) of std_logic_vector (13 downto 0);
-- define ins and outs for four phonon fifos
Signal Phonon_Shift,PhDPOut,PhTrigThresh,PhAvs_data,PhCircBuffDat : Phonon_Array;
Type OverSample_Array is Array (3 downto 0) of std_logic_vector (15 downto 0);
Signal OvrSmpl,PhOvrSmpl_data : OverSample_Array;
-- Make phonon FIFOs 16 bits wide to accomodate phase/magnitude tag bits
Type Phonon_Data is Array (3 downto 0) of std_logic_vector (15 downto 0);
Signal Phonon_Queue,PhFifoDat : Phonon_Data;
Signal PhClk,PhShiftEn : std_logic;

-- define words used for phonon fifos
Type PhononFifoStatus is Array (3 downto 0) of std_logic_vector (6 downto 0);
Signal PhononWords : PhononFifoStatus;

-- Read, write addresses for DPRam used for Phonon triggers 
Signal PhDPRdAddr,PhDPWrtAddr,PhBaseLength : std_logic_vector (6 downto 0);
Signal PhBaseInitCnt,PhBaseRdPtr,PhSmplRdPtr : std_logic_vector (6 downto 0);
Signal PhSmplInitCnt,PhSigSmplLngth  : std_logic_vector (4 downto 0);
-- Delay line of Dffs used for timing phonon trigger arithmetic blocks
Signal PhLtncyPipe : std_logic_vector (5 downto 0);
-- Signals used for phonon triggers
Type Phonon_Product is Array (3 downto 0) of std_logic_vector (28 downto 0);
Signal PhProduct,PhBaseProdReg,PhSigProdReg,PhThreshProd,PhTrigDiff : Phonon_Product;

-- DDR ADC Macro output signals
Signal ADCDDR_Rxl1,ADCDDR_Rxh1,ADCDDR_Rxl0,ADCDDR_Rxh0 : std_logic_vector (1 downto 0);
-- ADC is set up to produce a serial stream of 16 bits per conversion clock. 
-- That simplifies the framing. Each frame starts on the positive edge of the DCO
-- The DDR macro produces two output bits per bit clock a 1x the clock speed
-- To shift 16 bits, shift chains four bits long for each clock edge of each bit line are defined
Type DDIn_Array is Array (1 downto 0) of std_logic_vector (1 downto 0);
Signal DDInDat : DDIn_Array;
-- The positive edge ouputs of the DDR macros are delayed by one clock 
-- cycle with respect to the negative edge ouputs, so make the positive
-- edge shift register type (ADC_Shifth) one bit longer then ADC_Shiftl
Type ADC_Shifth is Array (1 downto 0) of std_logic_vector (4 downto 0);
Type ADC_Shiftl is Array (1 downto 0) of std_logic_vector (3 downto 0);
Signal ADC_In_h1,ADC_In_h0 : ADC_Shifth;
Signal ADC_In_l1,ADC_In_l0 : ADC_Shiftl;
-- Clock the output of ADC shift registers into staging registers
-- Use this register to organize scattered bits from the shift registers
-- into a single 16 bit word
Type ADC_Stage_Type is Array (1 downto 0) of std_logic_vector (15 downto 0);
signal ADC_Stage : ADC_Stage_Type;

-- Signals used for timing and control of incoming ADC data
Signal QFRDL : std_logic_vector(1 downto 0);
-- Sum 16 14 bit samples at 40msps to produce a 16 bit result at 2.5 msps
Type QSum_Array is Array (1 downto 0) of std_logic_vector (17 downto 0);
signal QSumIn,QSumOut : QSum_Array;

Type Charge_Array is Array (1 downto 0) of std_logic_vector (15 downto 0);
-- define signals for two charge fifos, DPRam buffers, Thresh registers
Signal Charge_Shift,Charge_Queue,QDPOut,QFifoDat,QCircBuff_data : Charge_Array;
Signal QSumDat,QTrigThresh : Charge_Array;

-- Signal arrays for intermediate values of charge trigger calculations,
-- For the baseline average
Type QBaseSum_Array is Array (1 downto 0) of std_logic_vector (22 downto 0);
Signal QBaselineSum,QMult_DataA : QBaseSum_Array; 
-- For the signal average
Type QSmplSum_Array is Array (1 downto 0) of std_logic_vector (20 downto 0);
Signal QSmplSum : QSmplSum_Array;
-- Multiply everything by the length of the average to avoid a normalizing divide
Signal QMult_DataB : std_logic_vector (7 downto 0);
Type Charge_Product is Array (1 downto 0) of std_logic_vector (30 downto 0);
Signal QProduct,QBaseProdReg,QSigProdReg,QThreshProd,QTrigDiff,AbsQTrigDiff : Charge_Product;

-- define "words used" for charge fifos
Type ChargeFifoStatus is Array (1 downto 0) of std_logic_vector (7 downto 0);
Signal ChargeWords : ChargeFifoStatus;

-- Read, write addresses for DPRam used for Charge triggers 
Signal QDPRdAddr,QDPWrtAddr,QBaseLength : std_logic_vector (6 downto 0);
Signal QBaseInitCnt,QBaseRdPtr,QSmplRdPtr : std_logic_vector (6 downto 0);
Signal QSmplInitCnt,QSigSmplLngth : std_logic_vector (4 downto 0);

-- Signal arrays for intermediate values of phonon trigger calculations,
Signal PhSumDat : Phonon_Array;
Type PhBaseSum_Array is Array (3 downto 0) of std_logic_vector (20 downto 0);
Signal PhBaselineSum,PhMult_DataA : PhBaseSum_Array;
Type PhSmplSum_Array is Array (3 downto 0) of std_logic_vector (18 downto 0);
Signal PhSmplSum : PhSmplSum_Array;
Signal PhMult_DataB : std_logic_vector (7 downto 0);

-- Phonon and charge trigger bits
-- Address at which a trigger occurred
Signal TriggerPointer : std_logic_vector(21 downto 0);
Signal PS_Phase : std_logic_vector(7 downto 0);
Signal PhTrig,PhRdReq : std_logic_vector(3 downto 0);
-- charge fifo read request, charge trigger bits
Signal QRdReq,QTrig,WrtEnDl,VXOCntDl : std_logic_vector(1 downto 0);
-- Oversample the phonons by 2x
Signal OvrSmplClkEn,OvrSmplLd,PhADCRdy,PhWrtReq,QADCRdy,QWrtReq : std_logic;
-- Register the incoming serial data bits from the phonon ADCs
Signal RPha,RPhB,RPhC,RPhD : std_logic;
-- Modulo 32 counter to time the reads of the ADCs
Signal ADCTimer : std_logic_vector (5 downto 0);
-- Trigger FIFO signals
Signal Trig_Fifordreq,Trig_Fiford,Trig_Fifowrreq,TrigFIFO_Empty,TrigFIFO_Full : std_logic;
Signal TrigFIFOCount : std_logic_vector (6 downto 0);
-- Flasher timer for Trig LED
Signal FlashCount : std_logic_vector(11 downto 0);
-- Trigger counters
Signal PhTrigCnt0,PhTrigCnt1,PhTrigCnt2,PhTrigCnt3 : std_logic_vector (15 downto 0);
Signal QTrigCnt0,QTrigCnt1,CntStage : std_logic_vector (15 downto 0);
-- Trigger deadtime counters
Type Deadtime_Array is Array (5 downto 0) of std_logic_vector (7 downto 0);
Signal TrigInhCnt : Deadtime_Array;
-- Trigger enable bits, trigger bits
Signal TrigParm,TrigStat : std_logic_vector (5 downto 0);
Signal Trig_Fifo_data : std_logic_vector (27 downto 0);
-- Trigger summer control bits
Signal PhBaseAdd_Sub,PhSmplAdd_Sub,PhBaseSumEn,PhSmplSumEn : std_logic; 
Signal QBaseAdd_Sub,QSmplAdd_Sub,QBaseSumEn,QSmplSumEn : std_logic;
Signal TrigInitReq,TrigSload,PhBaseSload,QBaseSload,TstSigTrigEn : std_logic; 

-- Bit field written to the trigger FIFO
Signal Trig_Out : std_logic_vector (27 downto 0);

-- Signals used for data averaging mode
Type PhAvg_Array is Array (3 downto 0) of std_logic_vector (19 downto 0);
Signal PhAv : PhAvg_Array;
Type QAvg_Array  is Array (3 downto 0) of std_logic_vector (21 downto 0);
Signal QAv : QAvg_Array;

Signal PhAvgCount,QAvgCount : std_logic_vector (5 downto 0);
Signal PhAvgLd,QAvgLd,PhAvClkEn,QAvClkEn,PhBaseSummer_cin,
		 PhSmplSummer_cin,QBaseSummer_cin,QSmplSummer_cin : std_logic;
Signal AverageIntReg : std_logic_vector (6 downto 0);

--  define inputs and outputs of SDRAM read buffer fifo
Signal Out_QueueOut,Out_QueueDat : std_logic_vector (15 downto 0);
Signal Out_Queuewords : std_logic_vector (7 downto 0);
Signal UsedWords : std_logic_vector (7 downto 0);

Signal RDDL,WRDL,Mode : std_logic_vector (1 downto 0);
Signal Out_Queuerd,Out_Queuerdreq,Out_Queuewrreq,Out_QueueClr,Out_QueueFull : std_logic;

-- LED pulser related signals
Signal LEDPlsRateReg : std_logic_vector (15 downto 0);
Signal LEDRateCnt : std_logic_vector (16 downto 0);
Signal LEDPlsWidthReg,LEDWidthCnt,LEDTimer : std_logic_vector (9 downto 0);
Signal LEDPlsEn,LEDOn,LEDPlsReq : std_logic_vector (2 downto 1);
-- FET Heat Indicator bit
Signal FetHeat : std_logic;

-- CSR bits
Signal AvgEn,SS_FR,ByteSwap : std_logic;
Signal iCD : std_logic_vector (15 downto 0);

-- Global clock and reset terms
signal PwrRst,SysClk : std_logic;

-- State Machine for SDRAM control
Type SDRAM_Controller is
	(Nop,Active,WaittCrd,SDRead,SDWrite,Wait0,Wait1,WaitPrecharge0,WaitPrecharge1,
   	 Refresh,RefreshWait0,RefreshWait1,RefreshWait2,Precharge,InitWait0,
		 InitRefresh0,InitWait1,InitWait2,InitWait3,InitRefresh1,InitWait4,
		 InitWait5,InitWait6,Load_Mode);
Signal RAMState : SDRAM_Controller;

-- State machine controlling ADC data capture
Type ADC_Controller is
	  (AcqIdle,WrtPhononA,WrtPhononB,WrtPhononC,WrtPhononD,
	   WrtChargeI0, WrtChargeI1, WrtChargeO0, WrtChargeO1, AcqDone);
Signal AcqState : ADC_Controller;

-- SDRAM related signals
signal SDWrtEn,SysWrtEn,RefreshReq,SDReadReq,SDWrtReq,InitReq : std_logic;
signal SDRDDL,SDWRDL : std_logic_vector (1 downto 0);
-- Counter used as refresh timer
signal RefreshCount : std_logic_vector (9 downto 0);
-- Pointers used for SDRAM addresses
signal SDRamAddr : std_logic_vector (24 downto 0);
signal PhononPtr,SDRamWrtAddrReg : std_logic_vector (21 downto 0);
signal ChargePtr : std_logic_vector (22 downto 0);
-- SDRAM write data bus
signal iD : std_logic_vector (15 downto 0);
-- Counter used as initialization timer
signal ResetCount : std_logic_vector (4 downto 0);
-- Burst mode transfer counter
signal BrstCnt,MaskCnt : std_logic_vector (2 downto 0);

-- Serial link to the CPLD
signal uCSDat,sDatReg : std_logic_vector (39 downto 0);
signal SDatBitCnt : std_logic_vector (5 downto 0);
signal SClkDiv : std_logic_vector (1 downto 0);
signal SetupSync,LongShift,SetupClk : std_logic;
signal TestCounter : std_logic_vector (31 downto 0);
signal TstIncReq,TstInc : std_logic;

-- shadow registers for DDS frequency sweep
signal Phase_Acc,StartFreq,Present_Freq,DeltaF : std_logic_vector(23 downto 0);
signal No_of_Steps,Step_Count : std_logic_vector(11 downto 0);
signal Step_interval,PhaseAccReg : std_logic_vector(13 downto 0);
signal Interval_Count : std_logic_vector(10 downto 0);
signal Interval_Prescale,Prescale_Value : std_logic_vector(8 downto 0);
signal SetUpSyncDL,TimerDL,CycleEdge : std_logic_vector(1 downto 0);
signal DAC_En,Phase_Acc_Dl,Sweep_En,Sweep_EnDl,PhiWrt_En,Sweep_Req,
		 PhRepeat,MirrorBit,DacDiv,Phase22D : std_logic;

-- Signals used for CPLD command queue
signal CPLD_Fifo_data : std_logic_vector (22 downto 0);
signal CpldRd_Dat : std_logic_vector (15 downto 0);
signal CPLDFifo_wrreq,CPLDFifo_rdreq,CPLDFifo_Empty,CPLDFifo_Full : std_logic;
signal Gap_Count : std_logic_vector (3 downto 0);
signal CPLDFifo_Out : std_logic_vector (22 downto 0);
-- signals used for VXO phase detector
signal RefIn,RefFd,FBFd,FBIn,RefClk,FBClk : std_logic;
-- Signals used for aligning 40 and 48 Mhz timing logic
signal PhWrtEnDL : std_logic_vector(1 downto 0);
signal AlignCount : std_logic_vector(2 downto 0);
signal VXOCnt : std_logic_vector(4 downto 0);
signal PhClkDiv : std_logic_vector(5 downto 0);
signal IntPFDAnd,PhDivTC,VXOWrtEn : std_logic;
signal IntPFDFF,IntPFDFFL : std_logic_vector(1 downto 0);

-- Signals used for serial data links
-- Registers for FM encoders
signal DSChnTx0_wrreq,DSChnTx0_TxDone,DSChnTx0_Tx_En,LinkWrtEn,
	    DSChnTx1_wrreq,DSChnTx1_TxDone,Tx1TxEn,FMTxEn,
	    DSChnTx0Buff_empty,DSChnTx1Buff_empty : std_logic;
signal Tx0BuffOut,AsciiTxDat : std_logic_vector (7 downto 0);
signal BinaryTxDat,CmdCode : std_logic_vector (15 downto 0);
--  FM decoder parity error bits
signal DSChnRx0ParityErr,DSChnRx1ParityErr,
	    DSChnRx0Clr_Err,DSChnRx1Clr_Err : std_logic;
signal BusRx0ParityErr,BusRx1ParityErr,
	    BusRx0Clr_Err,BusRx1Clr_Err : std_logic;
-- FM decoder buffer FIFO signals
signal DSChnRx0_rdreq,DSChnRx0_rd,DSChnRx0_RxDone,
	    DSChnRx1_rdreq,DSChnRx1_rd,DSChnRx1_RxDone,
	    BusRx0_rdreq,BusRx0_rd,BusRx0_RxDone,
	    BusRx1_RxDone,DSChnRx0Buff_empty,DSChnRx1Buff_empty,
	    DSChnRx0Buff_full,DSChnRx1Buff_full,NullFlag,InitFlag,CR_Flag,
   	 BusRx0Buff_empty,BusRx1Buff_empty,CMDWrtReq,
   	 DsChnRx0_active,BuffRst,FMRxClk : std_logic;
signal iLVBus,TXOut,BusMode : std_logic_vector (1 downto 0);
-- Transition detector for downstream link, link address, address of active module
signal TransitionCount : std_logic_vector (3 downto 0);
signal TxReqCnt,FMSelect : std_logic_vector (2 downto 0);
signal DsChnRx0Dl : std_logic_vector (1 downto 0);

signal DSChnRx1_wrreq,nSysClk,DSChnRx0_wrreq : std_logic;

-- Parallel data from FM decoders, buffered data from Receive
-- FIFOs
signal DSChnRx0Dat,BusRx0Dat,DSChnRx0BuffOut,BusRx0BuffOut,Tx1BuffStage : std_logic_vector (7 downto 0);
signal DSChnRx1BuffOut,Tx1BuffOut,Tx1PData,BusRx1Dat,DSChnRx1Dat : std_logic_vector (15 downto 0);

-- Signals used for serial transmitter for Charge ADC setup
-- Definitions used for the serial control of the mixer ADCs
signal ADCCmdFIFOOut,ADCCmdShift : std_logic_vector(15 downto 0);
signal ClkDiv : std_logic_vector(1 downto 0);
signal ADCCmdFIFOWrt,ADCCmdFIFORd,ADCCmdFIFOEmpty : std_logic; 
signal ADCCmdBitcount : std_logic_vector(4 downto 0);
Type ADCCmd_Serializer_FSM is (Idle,Load,SetCS,Shift,ClearCS);
signal ADCCmd_Shift : ADCCmd_Serializer_FSM;

begin

----------------------- Altera specific macro port maps ------------------------------

SysPll : vxopll 
	port map (inclk0 => VXOClk, areset => PwrRst, 
			  c0 => SysClk,   -- 80 Mhz clock
			  c1 => SDClk,    -- 50 MHz Clock
			  c2 => FMRxClk );   -- 160 Mhz clock

PhPll: PhADCPll
	port map	(inclk0 => EncClk, areset => PwrRst, 
				 c0 => PhClk );   -- 90 Mhz clock 

-- Setup data queue for the LTC2265 Charge ADC 
ADCSetupFIFO : lpm_fifo_dc
	generic MAP (LPM_WIDTH => 16, LPM_NUMWORDS => 128, LPM_WIDTHU => 7, LPM_SHOWAHEAD => "ON")
port map (aclr => PwrRst, wrclock => SysClk, data => CD, 
			 rdreq => ADCCmdFIFORd,rdclock => SysClk, wrreq => ADCCmdFIFOWrt, 
			 rdempty => ADCCmdFIFOEmpty, q => ADCCmdFIFOOut);

-- Queue serial commands to the CPLD to keep them from over-running each other
CPLD_Fifo : lpm_fifo_dc
	generic MAP (LPM_WIDTH => 23, LPM_NUMWORDS => 64, LPM_WIDTHU => 6, LPM_SHOWAHEAD => "ON")
		port map (aclr => PwrRst, data => CPLD_Fifo_data, wrclock => SysClk,
				  rdclock => SysClk, wrreq => CPLDFifo_wrreq, rdreq => CPLDFifo_rdreq, 
				  rdempty => CPLDFifo_Empty, wrfull => CPLDFifo_Full, q => CPLDFifo_Out);
PwrRst <= not CPLDRst;
CPLD_Fifo_data <= CA & CD; -- CA & "00" & CD(15 downto 2) when CA = QBiasDACAddr0 or CA = QBiasDACAddr1 else 

-- Local storage of values written to the CPLD
	CPLD_ReadBack : lpm_ram_dp
     generic map (LPM_WIDTH => 16, LPM_WIDTHAD => 7, LPM_NUMWORDS => 128)
		port map (data => CD, rdaddress => CA, wraddress => CA, 
		          rdclock => SysClk, wren => CPLDFifo_wrreq, wrclock => SysClk, 
		          q => CpldRd_Dat);

-- Trigger queue. Store the address of the SDRAM pointer at the time of a trigger
-- along with six status bits (QO,QI,PhA,PhB,PhC,PhD) indicating the source of the trigger
Trig_Fifo : lpm_fifo_dc
	generic MAP (LPM_WIDTH => 28, LPM_NUMWORDS => 128, LPM_WIDTHU => 7, LPM_SHOWAHEAD => "ON")
		port map (aclr => PwrRst, data => Trig_Fifo_data, 
				  wrclock => SysClk, rdclock => SysClk, wrreq => Trig_Fifowrreq, 
				  rdreq => Trig_Fifordreq, wrusedw => TrigFIFOCount, rdempty => TrigFIFO_Empty, 
				  wrfull => TrigFIFO_Full, q => Trig_Out);
Trig_Fifo_data <= (TrigStat & TriggerPointer);

-- Attach small FIFO blocks at the input and output of the SDRAM to 
-- spool data. These absorb the latencies arising from refresh cycles 
-- and the setup of the burst mode transfers. 

-- spooling FIFO to hold SDRAM read data
Out_Fifo : lpm_fifo_dc 
	generic MAP (LPM_WIDTH => 16, LPM_NUMWORDS => 256, LPM_WIDTHU => 8, LPM_SHOWAHEAD => "ON")
		port map (aclr => Out_QueueClr, data => D, wrclock => SDClk,
				rdclock => SysClk, wrreq => Out_Queuewrreq, rdreq => Out_Queuerdreq,
			  	wrusedw => Out_Queuewords, wrfull => Out_QueueFull,q => Out_QueueOut);

-- Reset term for SDRAM read spooling FIFO
Out_QueueClr <= '1' when CpldRst = '0' 
					 or (CpldCS = '0'and WR = '0' 
 and ((CA = SDRamRdPtrLoAd)  or (CA = PhAADCDatLoAddr)
   or (CA = PhBADCDatLoAddr) or (CA = PhCADCDatLoAddr)
   or (CA = PhDADCDatLoAddr) or (CA = QIADCDatLoAddr)
   or (CA = QOADCDatLoAddr))) else '0';

-- Map Phonon input FIFO connections
GenPhInFifos :
 for i in 0 to 3 generate
  PhFifos : lpm_fifo_dc
	generic MAP (LPM_WIDTH => 16, LPM_NUMWORDS => 128, LPM_WIDTHU => 7, LPM_SHOWAHEAD => "ON")
	 port map(aclr => PwrRst,  data => PhFifoDat(i), wrclock => SysClk,
			  rdclock => SDClk, wrreq => PhWrtReq, rdreq => PhRdReq(i),
			  rdusedw => PhononWords(i), q => Phonon_Queue(i));
end generate;

-- Map Charge input FIFO connections
  QIFifo : lpm_fifo_dc
 generic map (LPM_WIDTH => 16, LPM_NUMWORDS => 256, LPM_WIDTHU => 8, LPM_SHOWAHEAD => "ON")
	port map (aclr => PwrRst, data => QFifoDat(0), wrclock => SysClk, 
			  rdclock => SDClk, wrreq => QWrtReq, rdreq => QRdReq(0),
			  rdusedw => ChargeWords(0), q => Charge_Queue(0));

			  QOFifo : lpm_fifo_dc
  generic map (LPM_WIDTH => 16, LPM_NUMWORDS => 256, LPM_WIDTHU => 8, LPM_SHOWAHEAD => "ON")
	port map  (aclr => PwrRst, data => QFifoDat(1), wrclock => SysClk, 
			  rdclock => SDClk, wrreq => QWrtReq, rdreq => QRdReq(1),
			  rdusedw => ChargeWords(1), q => Charge_Queue(1));

-- OverSample the Phonon ADCs by 2 to reduce the anti-aliasing filter steepness requirement
GenOvrSmpl:
  for i in 0 to 3 generate
	PhOvrSmpl : altaccumulate 
 generic map (WIDTH_IN => 16, WIDTH_OUT => 16, LPM_REPRESENTATION => "SIGNED")
	port map (data => PhOvrSmpl_data(i), clock => SysClk, 
				 clken => OvrSmplClkEn, sload => OvrSmplLd,
				 aclr => PwrRst, result => OvrSmpl(i));
PhOvrSmpl_data(i) <= (Phonon_Shift(i)(13) & Phonon_Shift(i)(13) & Phonon_Shift(i));
end generate;

-- Use accumulaters for averaging data for long the traces required for
-- low frequency spectra

-- Phonon averagers
GenPhAvs: 
  for i in 0 to 3 generate 
	PhAvs : altaccumulate 
 generic map (WIDTH_IN => 14, WIDTH_OUT => 20, LPM_REPRESENTATION => "SIGNED")
	port map (data => PhAvs_data(i), clock => SysClk, clken => PhAvClkEn, sload => PhAvgLd,
				aclr => PwrRst, result => PhAv(i));
PhAvs_data(i) <= OvrSmpl(i)(14 downto 1);

end generate;

-- Charge averagers
GenQAvs: 
 for i in 0 to 1 generate 
	QAvs: altaccumulate 
 generic map (WIDTH_IN => 16, WIDTH_OUT => 22, LPM_REPRESENTATION => "SIGNED")
	  port map (data => Charge_Shift(i), clock => SysClk, clken => QAvClkEn, sload => QAvgLd,
				aclr => PwrRst, result => QAv(i));

QSums: altaccumulate 
 generic map (WIDTH_IN => 18, WIDTH_OUT => 18, LPM_REPRESENTATION => "SIGNED")
	  port map (data => QSumIn(i), clock => SysClk, clken => ADCTimer(0), sload => QADCRdy,
				aclr => PwrRst, result => QSumOut(i));

QSumIn(i) <= ADC_Stage(i)(15) & ADC_Stage(i)(15) & ADC_Stage(i)(15) & ADC_Stage(i)(15) & ADC_Stage(i)(15 downto 2);

end generate;

-- Two moving averages of (presumably) two different lengths are compared. A longer
-- baseline average is compared to a shorter sample average. If the difference
-- between these averages exceeds the specified threshold a trigger results.

GenPhTrigArith: 

for i in 0 to 3 generate
	PhCircBuff : lpm_ram_dp
     generic map (LPM_WIDTH => 14, LPM_WIDTHAD => 7, LPM_NUMWORDS => 128)
		port map (data => PhCircBuffDat(i),
				  rdaddress => PhDPRdAddr, wraddress => PhDPWrtAddr,
				  rdclock => SysClk, wren => PhADCRdy, wrclock => SysClk, q => PhDPOut(i));
	PhCircBuffDat(i) <= OvrSmpl(i)(14 downto 1);

 	PhBaseSummer : altaccumulate
    generic map (WIDTH_IN => 14, WIDTH_OUT => 21, LPM_REPRESENTATION => "SIGNED")
		port map (data => PhSumDat(i), clock => SysClk, clken => PhBaseSumEn, sload => PhBaseSload,
				  add_sub => PhBaseAdd_Sub, aclr => PwrRst, result => PhBaselineSum(i),
				  cin => PhBaseSummer_cin);

 	PhSmplSummer : altaccumulate
    generic map (WIDTH_IN => 14, WIDTH_OUT => 19, LPM_REPRESENTATION => "SIGNED")
		port map (data => PhSumDat(i), clock => SysClk, clken => PhSmplSumEn, sload => TrigSload, 
				  add_sub => PhSmplAdd_Sub, aclr => PwrRst, result => PhSmplSum(i),
				  cin => PhSmplSummer_cin);

	PhMult : lpm_mult
    generic map (LPM_WIDTHA => 21, LPM_WIDTHB => 8, LPM_WIDTHP => 29,
				 LPM_REPRESENTATION => "SIGNED", LPM_PIPELINE => 1)
		port map (dataa => PhMult_DataA(i),datab => PhMult_DataB, aclr => PwrRst,
				  clock => SysClk, result => PhProduct(i));

	PhBaselineSub : lpm_add_sub
     generic map (LPM_WIDTH => 29, LPM_REPRESENTATION => "SIGNED", LPM_DIRECTION => "SUB", LPM_PIPELINE => 1)
		port map (dataa => PhSigProdReg(i), datab => PhBaseProdReg(i),
				    aclr => PwrRst, clock => SysClk, result => PhTrigDiff(i));

					 PhThreshComp : lpm_compare
     generic map (LPM_WIDTH => 29,LPM_REPRESENTATION => "SIGNED",LPM_PIPELINE => 1)
		port map (dataa => PhTrigDiff(i), datab => PhThreshProd(i), aclr => PwrRst, 
				    clken => '1', clock => SysClk, agb => PhTrig(i));
 end generate;

GenQTrigArith:
for i in 0 to 1 generate
	QCircBuff : lpm_ram_dp
     generic map (LPM_WIDTH => 16, LPM_WIDTHAD => 7, LPM_NUMWORDS => 128)
		port map (data => QCircBuff_data(i),rdaddress => QDPRdAddr, wraddress => QDPWrtAddr,
				  rdclock => SysClk, wren => QADCRdy, wrclock => SysClk, q => QDPOut(i));
	QCircBuff_data(i) <= QFifoDat(i);

	QBaseSummer : altaccumulate
     generic map (WIDTH_IN => 16, WIDTH_OUT => 23, LPM_REPRESENTATION => "UNSIGNED")
		port map (data => QSumDat(i), clock => SysClk, clken => QBaseSumEn,sload => QBaseSload, 
				  add_sub => QBaseAdd_Sub, aclr => PwrRst,result => QBaselineSum(i),
				  cin => QBaseSummer_cin);
   QSmplSummer : altaccumulate
    generic map (WIDTH_IN => 16, WIDTH_OUT => 21, LPM_REPRESENTATION => "UNSIGNED")
		port map (data => QSumDat(i), clock => SysClk, clken => QSmplSumEn, sload => TrigSload, 
				  add_sub => QSmplAdd_Sub, aclr => PwrRst, result => QSmplSum(i),
				 cin => QSmplSummer_cin);

	QMult : lpm_mult
     generic map (LPM_WIDTHA => 23, LPM_WIDTHB => 8, LPM_WIDTHP => 31, 
				  LPM_REPRESENTATION => "UNSIGNED", LPM_PIPELINE => 1)
		port map (dataa => QMult_DataA(i),datab => QMult_DataB, aclr => PwrRst,
				   clock => SysClk, result => QProduct(i));
	QBaselineSub : lpm_add_sub
     generic map (LPM_WIDTH => 31, LPM_REPRESENTATION => "SIGNED", LPM_DIRECTION => "SUB", LPM_PIPELINE => 1)
		port map (dataa => QSigProdReg(i), datab => QBaseProdReg(i),
				  aclr => PwrRst, clock => SysClk, result => QTrigDiff(i));

	QTrigABsVal : lpm_abs
     generic map (LPM_WIDTH => 31)
		port map (DATA => QTrigDiff(i),  RESULT => AbsQTrigDiff(i));

	QThreshComp : lpm_compare
     generic map (LPM_WIDTH => 31,LPM_REPRESENTATION => "UNSIGNED", LPM_PIPELINE => 1)
		port map (dataa => AbsQTrigDiff(i), datab => QThreshProd(i),aclr => PwrRst,
				  clken => '1', clock => SysClk, agb => QTrig(i));

end generate;

--------------------- Serial Link port maps -------------------------------

-- Two FM transmitters are needed

DSChnTx0 : Serial_Tx 
	generic MAP(size => 8)
	port map(clock => SysClk, reset => CPLDRst, Tx_En => DSChnTx0_Tx_En,
		      pdata_in => Tx0BuffOut, FMData_Out => TXOut(0), 
		      Tx_Done => DSChnTx0_TxDone);
 
 DSChnTx0_Tx_En <= not DSChnTx0Buff_empty;

 -- Transmit to the bus if a master, else to the daisy chain if not
iLVBus(0)  <= TXOut(0) when LVDir = '1' else '0';
DsChnTx(0) <= TXOut(0) when LVDir = '0' else '0';

DSChnTx1 : Serial_Tx 
	generic MAP(size => 16)
	port map(clock => SysClk, reset => CPLDRst, Tx_En => Tx1TxEn,
		      pdata_in => Tx1PData, FMData_Out => TXOut(1), 
		      Tx_Done => DSChnTx1_TxDone);

-- Transmit to the bus if a master, else to the daisy chain if not
iLVBus(1)  <= TXOut(1) when LVDir = '1' else '0';
DsChnTx(1) <= TXOut(1) when LVDir = '0' else '0';

-- Select between microcontroller written or synchronizing codes or 
-- neighboring card as sources for serial TX1
BusMode <= (LVDir & FMTxEn);
with BusMode select
Tx1PData <= CmdCode when "10",
		      CmdCode when "11",
		   Tx1BuffOut when "00",
		           CD when others;

 -- Four FM receivers are needed
DSChnRx0 : Serial_Rx 
	generic MAP(size => 8)
	port map(sysclk => SysClk, rxclock => FMRxClk, reset => CPLDRst, Clr_Err => DSChnRx0Clr_Err,
		 FMData_In => DSChnRx(0), pdata_out => DSChnRx0Dat, 
		 Rx_Done => DSChnRx0_RxDone, Parity_Err => DSChnRx0ParityErr);

DSChnRx1 : Serial_Rx 
	generic MAP(size => 16)
	port map(sysclk => SysClk, rxclock => FMRxClk, reset => CPLDRst, Clr_Err => DSChnRx1Clr_Err,
		 FMData_In => DSChnRx(1), pdata_out => DSChnRx1Dat, 
		 Rx_Done => DSChnRx1_RxDone, Parity_Err => DSChnRx1ParityErr);

BusRx0 : Serial_Rx 
	generic MAP(size => 8)
	port map(sysclk => SysClk, rxclock => FMRxClk, reset => CPLDRst, Clr_Err => BusRx0Clr_Err,
		 FMData_In => LVBus(0), pdata_out => BusRx0Dat, 
		 Rx_Done => BusRx0_RxDone, Parity_Err => BusRx0ParityErr);

BusRx1 : Serial_Rx
	generic MAP(size => 16)
	port map(sysclk => SysClk, rxclock => FMRxClk, reset => CPLDRst, Clr_Err => BusRx1Clr_Err,
		 FMData_In => LVBus(1), pdata_out => BusRx1Dat, 
		 Rx_Done => BusRx1_RxDone, Parity_Err => BusRx1ParityErr);

LVBus <= iLVBus when LVDir = '1' else (others => 'Z');

--------------------------- Serial Link Buffer FIFOs -------------------------------

DSChnTx0Buff : lpm_fifo_dc
	generic MAP (LPM_WIDTH => 8, LPM_NUMWORDS => 1024, LPM_WIDTHU => 10, LPM_SHOWAHEAD => "ON")
	 port map(aclr => BuffRst, data => AsciiTxDat, wrclock => SysClk,
			  rdclock => SysClk, wrreq => DSChnTx0_wrreq, rdreq => DSChnTx0_TxDone,
			  rdempty => DSChnTx0Buff_empty, q => Tx0BuffOut);

-- Mux to select between auxillary ascii link data and microcontroller data
AsciiTxDat <= CD(7 downto 0) when LVDir = '1' else DSChnRx0Dat;

DSChnTx1Buff : lpm_fifo_dc
	generic MAP (LPM_WIDTH => 16, LPM_NUMWORDS => 256, LPM_WIDTHU => 8, LPM_SHOWAHEAD => "ON")
	 port map(aclr => BuffRst, data => BinaryTxDat, wrclock => SysClk,
			  rdclock => SysClk, wrreq => DSChnTx1_wrreq, rdreq => DSChnTx1_TxDone,
			  rdempty => DSChnTx1Buff_empty, q => Tx1BuffOut);

-- Mux to select between auxillary binary link data and microcontroller data
BinaryTxDat <= CD when FMTxEn = '1' else DSChnRx1Dat; 

-- Serial Data receive buffers
DSChnRx0Buff : lpm_fifo_dc
	generic MAP (LPM_WIDTH => 8, LPM_NUMWORDS => 1024, LPM_WIDTHU => 10, LPM_SHOWAHEAD => "ON")
	 port map(aclr => BuffRst, data => DSChnRx0Dat, wrclock => nSysClk,
			  rdclock => SysClk, wrreq => DSChnRx0_wrreq, rdreq => DSChnRx0_rd,
			   wrfull => DSChnRx0Buff_full, rdempty => DSChnRx0Buff_empty, q => DSChnRx0BuffOut);

nSysClk <= not SysClk;
DSChnRx0_wrreq <= DSChnRx0_RxDone and not LVDir;

DSChnRx1Buff : lpm_fifo_dc
	generic MAP (LPM_WIDTH => 16, LPM_NUMWORDS => 128, LPM_WIDTHU => 7, LPM_SHOWAHEAD => "ON")
	 port map(aclr => BuffRst, data => DSChnRx1Dat, wrclock => nSysClk,
			  rdclock => SysClk, wrreq => DSChnRx1_wrreq, rdreq => DSChnRx1_rd,
			   wrfull => DSChnRx1Buff_full, rdempty => DSChnRx1Buff_empty, q => DSChnRx1BuffOut);

DSChnRx1_wrreq <= DSChnRx1_RxDone and not LVDir;

BusRx0Buff : lpm_fifo_dc
	generic MAP (LPM_WIDTH => 8, LPM_NUMWORDS => 1024, LPM_WIDTHU => 10, LPM_SHOWAHEAD => "ON")
	 port map(aclr => BuffRst, data => BusRx0Dat, wrclock => nSysClk,
			   rdclock => SysClk, wrreq => BusRx0_RxDone, rdreq => BusRx0_rd,
			   rdempty => BusRx0Buff_empty, q => BusRx0BuffOut);
-- Reset the FIFOs if the buffer reset bit in the CSR is asserted
BuffRst <= '1' when CpldRst = '0' 
               or (CpldRst = '1' and CpldCS = '0' and WR = '0' and CA = CSRAddr and CD(14) = '1')
			   else '0';

-------------------------- Phase Detector logic ---------------------------

-- Select the external signal to be used as the clock for the reference 
-- side of the phase detector
with Mode select
RefClk <= ExtRef    when "01", -- 10MHz external reference
		    LVBus(1)  when others; -- 20MHz FM on the LVDS link

-- MSB of the internal clock divider is the clock for the oscillator side of the 
-- phase detector
with Mode select
FBClk <= VXOCnt(1) when "01",   -- 40 MHz div 4 to match 10MHz 
			VXOCnt(0) when others; -- 40 MHz div 2 to match 20MHz 

-- 50MHz divide by 4.
IntClkDiv : process(SDClk,CpldRst)
begin
 if CpldRst = '0' then
	SqWv <= '0'; 
elsif rising_edge(SDClk) then
 if Mode /= 0 and SqWv <= '0' then SqWv <= '1'; 
	else SqWv <= '0'; 
  end if; -- Mode /= 0
end if; -- CpldRst
end process IntClkDiv;

-- Input Dffs
PhDtctFBIn : process(FBClk,CpldRst)
begin
if CpldRst = '0' then FBIn <= '0'; 
-- Provide a symmetric square wave to the frequency discriminator Dff
 elsif rising_edge(FBClk) then FBIn <= not FBIn;
 end if; -- CpldRst
end process PhDtctFBIn;

PhDtctRefIn: process (RefClk,CpldRst)
begin
if CpldRst = '0' then RefIn <= '0';
-- Provide a symmetric square wave to the frequency discriminator Dff
elsif rising_edge(RefClk) then RefIn <= not RefIn;
end if;
end process PhDtctRefIn;

-- Frequency discriminator Dffs
PhDtctFBFD: process(FBClk,RefFd)
begin
if RefFd = '1' then FBFd <= '1';
elsif rising_edge(FBClk) then FBFd <= RefIn xor FBIn; end if; -- RefFd
end process PhDtctFBFD;

PhDtctRefFD: process (RefClk,FBFd)
begin
if FBFd = '0' then RefFd <= '0';
elsif rising_edge(RefClk) then RefFd <= RefIn xor FBIn; end if; -- FBFd
end process PhDtctRefFD;

Tst(9) <= RefClk;
Tst(8) <= RefIn;
Tst(7) <= FBClk;
Tst(6) <= FBIn;
Tst(5) <= FBFd;
Tst(4) <= RefFd;
Tst(3 downto 1) <= (others => '0');

----------------- Phase Detector combinatorial outputs --------------------
-- Disable Phase detector OP-Amp when no external clock is present 
SHDN <= '0' when Mode = 0 else 'Z';

PhDtct <= (Mode(0) or Mode(1))
			and (not RefFd and not(FBFd and (RefIn xor FBIn)));
			
----------------- Phonon/Charge clock alignment --------------------

--  This section is for aligning the phase of the 40 MHz based Phonon convert
--  strobe to to that of the 90 MHz based serial shift clock. The phasing can be 
--  done with two counters, a modulo 16 for the 40MHz logic and a modulo 36 
--  for the 90 MHz logic. The modulo 36 counter is reset by the output of 
--  a Phase/Frequency detector whose inputs are the 40MHz clock and the 90MHz
--  clock divided by 2. Once the 90 MHz counter has been aligned by the phase 
--  detector output, the terminal count of the 90 MHz counter is used to reset
--  the 40 MHz counter. This 90 MHz counter alignment process is run for seven
--  iterations after either power up or the rising edge of the SDRAM write enable.
--  The resetting of the 40 MHz counter by the 90MHz counter runs continously.

-- Phase detector flip flops clocked by the 40 MHz VXO
PFDVxo : process (VXOClk,IntPFDAnd)
begin 
if IntPFDAnd = '1' then 
	IntPFDFF(0) <= '0';
elsif rising_edge(VXOClk) then
  IntPFDFF(0) <= '1';
end if; -- PhClkDiv(0)
end process PFDVxo;

-- Phase detector flip flops clocked by 45 MHz PhClkDiv(0)
PFDPhClk : process (PhClkDiv(0),IntPFDAnd)
begin 
if IntPFDAnd = '1' then 
	IntPFDFF(1) <= '0';
elsif rising_edge(PhClkDiv(0)) then
  IntPFDFF(1) <= '1';
end if; -- PhClkDiv(0)
end process PFDPhClk;

-- The gate used to reset both PFD flip flops
IntPFDAnd <= IntPFDFF(0) and IntPFDFF(1);

-- Mod 32 counter running at 40MHz
Mod16Cnt: process (VXOClk,CpldRst)

begin

if CpldRst = '0' then 

	 VXOCnt <= "00000"; VXOWrtEn <= '0';
 	 PhCvtReq <= '0'; 			  

elsif rising_edge(VXOClk) then 

-- 40MHz synchronized copy of WrtEn
    VXOWrtEn <= SysWrtEn;

-- Modulo 32 40MHz counter 
-- Reset counter in response the terminal count of the 
-- Phonon prescale counter
	if PhDivTC = '1' then VXOCnt(3 downto 0) <= "0000";
	else VXOCnt(3 downto 0) <= VXOCnt(3 downto 0) + 1;
	end if;
	if VXOCnt(3 downto 0) = X"F" then VXOCnt(4) <= not VXOCnt(4);
	else VXOCnt(4) <= VXOCnt(4);
	end if;

-- 16 clock ticks @40MHz define the 2.5 msps conversion cycles
-- Make the convert strobe 25ns wide
-- Pick a point in the counting interval where there is acceptable
-- set up and hold w.r.t. the Phonon Sclk
 if VXOCnt(3 downto 0) = 2 and VXOWrtEn = '1'
  then PhCvtReq <= '1';
 else  PhCvtReq <= '0';
 end if;

end if; --CpldRst
end process Mod16Cnt;

-- Logic with a phonon clock time base
PhShift : process (PhClk,CpldRst)
begin

if CpldRst = '0' then 
-- Modulo 36 counter runing at 90MHz
	PhClkDiv <= (others => '0'); 
	AlignCount <= "111"; IntPFDFFL <= "00";
-- Phonon ADC serial read clock, data deserializers
	PhSClk <= '0'; PhDivTC <= '0'; PhWrtEnDL <= "00";
	RPha <= '0'; RPhB <= '0'; RPhC <= '0'; RPhD <= '0';
	Phonon_Shift(0) <= (others => '0');	Phonon_Shift(1) <= (others => '0'); 
	Phonon_Shift(2) <= (others => '0');	Phonon_Shift(3) <= (others => '0');
	Tst(10) <= '0'; 

elsif rising_edge(PhClk) then 

-- 90MHz synchronized copy of WrtEn
    PhWrtEnDL(0) <= SysWrtEn;
    PhWrtEnDL(1) <= PhWrtEnDL(0);

-- Align the mod 36 counter to the mod 16 counter seven times on the
-- rising edge of SysWrtEn
if PhWrtEnDL = 1 then AlignCount <= "111";
elsif PhClkDiv = 6 and AlignCount /= 0 then AlignCount <= AlignCount - 1;
else AlignCount <= AlignCount;
end if;

-- Generate delayed copies of the PFD output
IntPFDFFL(0) <= IntPFDFF(1);
IntPFDFFL(1) <= IntPFDFFL(0);

-- Generate a 48 MHz Phonon shift clock using bit 0 of the alignment counter
PhSClk <= PhClkDiv(0);

-- Modulo 36 90MHz counter 
  if PhClkDiv = 35 then PhClkDiv <= "000000";
  elsif IntPFDFFL = 3 and IntPFDFF(1) = '0' and AlignCount /= 0 then PhClkDiv <= "000110";
  else PhClkDiv <= PhClkDiv + 1;
 end if;

 -- Generate a terminal count for resetting the 40 MHz counter. Make it
 -- wide enough to account for the lower frequency of the VXO clock
	if PhClkDiv = 34 then PhDivTC <= '1';
elsif PhClkDiv = 0 then PhDivTC <= '0';
else PhDivTC <= PhDivTC;
end if;

------------------------ Phonon ADC shift registers -------------------------

RPha <= PhADat; RPhB <= PhBDat; 
RPhC <= PhCDat; RPhD <= PhDDat;


if PhClkDiv = 16 then PhShiftEn <= '1';
elsif PhClkDiv = 8 then PhShiftEn <= '0';
else PhShiftEn <= PhShiftEn;
end if;

if PhClkDiv(0) = '1' and PhShiftEn = '1' then
	Tst(10) <= '1';
 	Phonon_Shift(0) <= Phonon_Shift(0)(12 downto 0) & RPha;
	Phonon_Shift(1) <= Phonon_Shift(1)(12 downto 0) & RPhB;
	Phonon_Shift(2) <= Phonon_Shift(2)(12 downto 0) & RPhC;
	Phonon_Shift(3) <= Phonon_Shift(3)(12 downto 0) & RPhD;
 else
   Tst(10) <= '0';
	Phonon_Shift <= Phonon_Shift;
 end if;
end if; --CpldRst
end process PhShift;

------------------------ Charge ADC shift registers --------------------------

Frame : process(QDCO,CpldRst)
begin
 if CpldRst = '0' then QFRDL <= "00"; 
 elsif rising_edge(QDCO) then 
 QFRDL(0) <= QFR; 
 QFRDL(1) <= QFRDL(0);
 end if;
end process Frame;

-- Loop over ADC channels
QADCGen : for i in 0 to 1 generate

-- Define input connections from the 2 ADC data bits
DDInDat(i) <= (QDatIB(i+1) & QDatIA(i+1));

-- Define the ADC input DDR register comnnections 
InDDRs : ADC_DDR
port map (aclr => PwrRst, 
			 datain => DDInDat(i),
			 inclock => QDCO,
			 dataout_h(0) => ADCDDR_Rxh0(i),
			 dataout_h(1) => ADCDDR_Rxh1(i),
			 dataout_l(0) => ADCDDR_Rxl0(i),
			 dataout_l(1) => ADCDDR_Rxl1(i));

QShiftIn : process(QDCO,CpldRst)

begin
-- Connection to ADC outputs: A outs are indices 0 
-- 									B outs are indices 1

 if CpldRst = '0' then 

	ADC_In_h1(i) <= (others => '0');
   ADC_In_l1(i) <= (others => '0'); 	
	ADC_In_h0(i) <= (others => '0');
   ADC_In_l0(i) <= (others => '0'); 	
	ADC_Stage(i) <= (others => '0');

 elsif rising_edge(QDCO) then

-- Input shift registers running at 1x the ADC clock rate
-- The simulator claims the ADC ouptput format results in the negative edge 
-- clocked data coming through a clock cycle late with respect to the positive 
-- edge data. Make the positive clocked shift register one bit longer to re-align
-- the data from the two clock edges
 ADC_In_h0(i) <= (ADC_In_h0(i)(3 downto 0) & ADCDDR_Rxh0(i));
 ADC_In_l0(i) <= (ADC_In_l0(i)(2 downto 0) & ADCDDR_Rxl0(i));

 ADC_In_h1(i) <= (ADC_In_h1(i)(3 downto 0) & ADCDDR_Rxh1(i));
 ADC_In_l1(i) <= (ADC_In_l1(i)(2 downto 0) & ADCDDR_Rxl1(i));

	  if QFRDL = 1
-- Concatenate the bits from two shifted in 8 bit fragments to form one 16 bit word
   	then
			ADC_Stage(i) <= (ADC_In_h0(i)(4) & ADC_In_h1(i)(4) & ADC_In_l0(i)(3) & ADC_In_l1(i)(3)
								& ADC_In_h0(i)(3) & ADC_In_h1(i)(3) & ADC_In_l0(i)(2) & ADC_In_l1(i)(2)
								& ADC_In_h0(i)(2) & ADC_In_h1(i)(2) & ADC_In_l0(i)(1) & ADC_In_l1(i)(1)
							   & ADC_In_h0(i)(1) & ADC_In_h1(i)(1) & ADC_In_l0(i)(0) & ADC_In_l1(i)(0));
	else 
		  ADC_Stage(i) <= ADC_Stage(i);
  end if; -- QFR 
 
 end if; -- CpldRst
 
end process QShiftIn;

end generate; -- for i = 0 to 1

-- Asynchronous portion of the logic
DSetUpDat <= sDatReg(39);
DSetupSync <= SetupSync; 
DSetupClk <= SClkDiv(1);

----------------------- 80Mhz clocked logic -----------------------------

main: process(SysClk, CpldRst)

 begin

-- asynchronous reset/preset
  if CpldRst = '0' then
  
	RDDL <= "00" ;WRDL <= "00"; Sweep_EnDl <= '0'; PhiWrt_En <= '0';
	PhBaseLength <= "0001000"; QBaseLength <= "0001000"; Mode <= "10";	
	PhSigSmplLngth <= "00010"; QSigSmplLngth <= "00010";
	AvgEn <= '0'; SS_FR <= '0'; ByteSwap <= '0'; LEDPlsReq <= "00";
	LEDOn <= "00"; AverageIntReg <= "1000000"; DAC_En <= '0';
	LEDPlsRateReg <= X"FFFF"; LEDPlsWidthReg <= ("00" & X"80");
	LEDPlsEn <= "00"; LEDTimer <= "00" & X"00"; TstSigTrigEn <= '0';
	TrigParm <= "000000"; TrigStat <= "000000"; StatLED <= "11";
	PhTrigThresh(0) <= ("00" & X"010"); PhTrigThresh(1) <= ("00" & X"010"); 
	PhTrigThresh(2) <= ("00" & X"010"); PhTrigThresh(3) <= ("00" & X"010"); 
	QTrigThresh(0) <= X"0020"; QTrigThresh(1) <= X"0020"; 
	PhBaseAdd_Sub <= '0'; PhBaseSummer_cin <= '1'; PhSmplAdd_Sub <= '0'; PhSmplSummer_cin <= '1'; 
	PhBaseSumEn <= '0'; PhSmplSumEn <= '0';
	QBaseAdd_Sub <= '0'; QBaseSummer_cin <= '1'; QSmplAdd_Sub <= '0'; QSmplSummer_cin <= '1';
	QBaseSumEn <= '0'; QSmplSumEn <= '0';
	ADCTimer <= "000000"; VXOCntDl <= "00"; WrtEnDl <= "00";
	PhADCRdy <= '0'; PhAvClkEn <= '0'; PhWrtReq <= '0'; QAvClkEn <= '0'; 
	QADCRdy <= '0'; QWrtReq <= '0';  OvrSmplClkEn <= '0'; OvrSmplLd <= '0';
	Out_Queuerd <= '0'; Out_Queuerdreq <= '0'; LongShift <= '0';
	sDatReg <= X"0000000000"; SDatBitCnt <= "000000"; SClkDiv <= "00"; SetupClk <= '0';
	SetupSync <= '0'; Gap_Count <= "0000"; CPLDFifo_wrreq <= '0'; CPLDFifo_rdreq <= '0';
	PhAvgCount <= (others => '0'); QAvgCount <= (others => '0'); PhAvgLd <= '0'; QAvgLd <= '0';
	PhDPRdAddr <= (others => '0'); PhDPWrtAddr <= (others => '0'); QDPRdAddr <= (others => '0'); 
	QDPWrtAddr <= (others => '0'); 
    PhBaseInitCnt <= (others => '0'); PhBaseRdPtr <= (others => '0'); PhBaseSload <= '0';
	PhSmplRdPtr <= (others => '0');   PhSmplInitCnt <= (others => '0'); QBaseSload <= '0';
	QBaseInitCnt <= (others => '0');  QBaseRdPtr <= (others => '0'); TrigInitReq <= '0';
	QSmplRdPtr <= (others => '0');	QSmplInitCnt <= (others => '0'); TrigSload <= '0';
	PhThreshProd(0) <= (others => '0'); PhSigProdReg(0) <= (others => '0'); 
	PhBaseProdReg(0) <= (others => '0'); PhThreshProd(1) <= (others => '0'); 
	PhSigProdReg(1) <= (others => '0'); PhBaseProdReg(1) <= (others => '0'); 
	PhThreshProd(2) <= (others => '0'); PhSigProdReg(2) <= (others => '0'); 
	PhBaseProdReg(2) <= (others => '0'); PhThreshProd(3) <= (others => '0'); 
	PhSigProdReg(3) <= (others => '0'); PhBaseProdReg(3) <= (others => '0'); 
	QThreshProd(0) <= (others => '0'); QSigProdReg(0) <= (others => '0'); 
	QBaseProdReg(0) <= (others => '0');	QThreshProd(1) <= (others => '0'); 
	QSigProdReg(1) <= (others => '0'); QBaseProdReg(1) <= (others => '0'); 
	TriggerPointer <= (others => '0'); 
	TrigInhCnt(0) <= "00000000"; TrigInhCnt(1) <= "00000000"; TrigInhCnt(2) <= "00000000";
	TrigInhCnt(3) <= "00000000"; TrigInhCnt(4) <= "00000000"; TrigInhCnt(5) <= "00000000";
	CycleEdge <= "00"; PS_Phase <= X"00";
	Trig_Fifordreq <= '0'; Trig_Fiford <= '0'; Trig_Fifowrreq <= '0'; FlashCount <= X"000";
	TstIncReq <= '0'; TstIncReq <= '0'; TestCounter <= X"00000000";
   PhTrigCnt0 <= X"0000"; PhTrigCnt1 <= X"0000"; 
	PhTrigCnt2 <= X"0000"; PhTrigCnt3 <= X"0000";
	QTrigCnt0 <= X"0000"; QTrigCnt1 <= X"0000"; 
	CntStage <= X"0000"; FetHeat <= '0'; 
	-- Serial link related signals
	DSChnTx0_wrreq <= '0'; DSChnTx1_wrreq <= '0'; Tx1TxEn <= '0';
	DSChnRx0_rdreq <= '0'; DSChnRx0_rd <= '0'; 
	DSChnRx1_rdreq <= '0'; DSChnRx1_rd <= '0'; 
	BusRx0_rdreq <= '0'; BusRx0_rd <= '0'; LVDir <= '0';
	InitFlag <= '0'; NullFlag <= '0'; CR_Flag <= '0';
	DsChnRx0_active <= '0'; TransitionCount <= X"0";
	LVBusTerm <= '0'; CmdCode <= X"0000"; 
	LinkWrtEn <= '0';	CMDWrtReq <= '0'; FMTxEn <= '0';
	SysWrtEn <= '0';
	ADCCmd_Shift <= Idle;  ClkDiv <= "00"; ADCCmdFIFOWrt <= '0';
	ADCCmdFIFORd <= '0'; ADCCmdBitcount <= "00000";
	ADCCmdShift <= X"0000"; QADCSClk <= '0'; QADCCS <= '1';
	
	Phase_Acc <= X"000000"; PhaseAccReg <= "00" & X"000"; StartFreq <= X"100000";  
	Present_Freq <= X"000000"; DeltaF <= X"001000"; No_of_Steps <= X"010"; 
	Step_Count <= X"000"; Step_interval <= "00" & X"002"; Phase_Acc_Dl <= '0';	
	Interval_Count <= "000" & X"02"; 
	Interval_Prescale <= "0" & X"00"; Prescale_Value <= "0" & X"00"; 
	SetUpSyncDL <= "00"; TimerDL <= "00"; 
	Sweep_Req <= '0'; Sweep_En <= '0'; PhRepeat <= '0';
	Dac <= (others => '0'); MirrorBit <= '0'; DacDiv <= '0';
	Phase22D <= '0';
	
elsif rising_edge (SysClk) then 

-- Synchronous edge detectors for read and write strobes
RDDL(0) <= not CpldCS and not RD;
RDDL(1) <= RDDL(0);

WRDL(0) <= not CpldCS and not WR;
WRDL(1) <= WRDL(0);

-- CSR bits
 if CpldCS = '0' and WRDL = 1 and CA = CSRAddr
  then	
	PhiWrt_En <= CD(11);
	TstSigTrigEn <= CD(12);
	AvgEn <= CD(6);  
	Mode <= CD(4 downto 3);
	LVDir <= CD(0);
 else
	TstSigTrigEn <= TstSigTrigEn;
	PhiWrt_En <= PhiWrt_En;
	AvgEn <= AvgEn;	
	Mode <= Mode; 
	LVDir <= LVDir;
 end if;

-- CSR SDRAM write enable
-- If the card is on a cable, synchronize write enable with serial I/O
-- otherwise have it controlled directly by the uC
   if SysWrtEn = '0'
	and ((CpldCS = '0' and WRDL = 1  and CA = CSRAddr and Mode /= 2 and LVDir = '0' and CD(5) = '1')
   or (Mode = 2  and LVDir = '0' and BusRx1_RxDone = '1' and BusRx1Dat = WriteEn)
   or (Mode /= 2 and LVDir = '1' and DSChnTx1_TxDone = '1' and CmdCode <= WriteEn))
  then SysWrtEn <= '1';
 elsif SysWrtEn = '1'
	and ((CpldCS = '0' and WRDL = 1  and CA = CSRAddr and Mode /= 2 and LVDir = '0' and CD(5) = '0')
    or (Mode = 2  and LVDir = '0' and BusRx1_RxDone = '1' and BusRx1Dat = WriteDis)
    or (Mode /= 2 and LVDir = '1' and DSChnTx1_TxDone = '1' and CmdCode <= WriteDis))
 then SysWrtEn <= '0';
 else 
		SysWrtEn <= SysWrtEn; 
 end if;
 -- If a master send a Write Enable or Write Disable as appropriate on the link to the slaves
   if CpldCS = '0' and WRDL = 1 and CA = CSRAddr and CD(5) = '1'
 then CmdCode <= WriteEn;
elsif CpldCS = '0' and WRDL = 1 and CA = CSRAddr and CD(5) = '0'
 then CmdCode <= WriteDis;
 else CmdCode <= CmdCode;
 end if;
 
-- Read strobe logic for FIFOs read by the microcontroller
-- The TMS 470 address lines become invalid as soon as the read strobe is de-asserted
-- Latch the uC counter read so that the a counter increment on the trailing 
-- edge of the uC strobe. 
if TstIncReq = '0' and RDDL = 1 and CpldCS = '0' and CA = TestCounterLoAd
then TstIncReq <= '1';
elsif TstIncReq = '1' and RDDL = 2
then TstIncReq <= '0';
else TstIncReq <= TstIncReq;
end if;

if TstIncReq = '1' and RDDL = 2
	then TstInc <= '1';
else TstInc <= '0';
end if;
-- Counter that increments with each 32 bit read for use as a debuggin tool
if CpldCS = '0' and WRDL = 1 and (CA = TestCounterHiAd)
then TestCounter(31 downto 16) <= CD;
	 TestCounter(15 downto 0) <= TestCounter(15 downto 0);
elsif CpldCS = '0' and WRDL = 1 and (CA = TestCounterLoAd)
then TestCounter(15 downto 0) <= CD;
	 TestCounter(31 downto 16) <= TestCounter(31 downto 16);
elsif TstInc = '1' then TestCounter <= TestCounter + 1;
else TestCounter <= TestCounter;
end if;

-- If LED flasher is in single step mode, stop flasher sequence after 
-- LED turns on once
if CpldCS = '0' and WRDL = 1 and (CA = LEDPlsCtrlBits)
	then LEDPlsReq(2) <= CD(1);
elsif SS_FR = '1' and LEDOn(2) = '1' then LEDPlsReq(2) <= '0';
else LEDPlsReq(2) <= LEDPlsReq(2);
end if;

if CpldCS = '0' and WRDL = 1 and (CA = LEDPlsCtrlBits)
	then LEDPlsReq(1) <= CD(0);
elsif SS_FR = '1' and LEDOn(1) = '1' then LEDPlsReq(1) <= '0';
else LEDPlsReq(1) <= LEDPlsReq(1);
end if;

if CpldCS = '0' and WRDL = 1 and (CA = LEDPlsCtrlBits)
	then SS_FR <= CD(4);
else SS_FR <= SS_FR;
end if;

-- Status 1 LED output
if Mode = 2 then StatLED(1) <= '0';
else StatLED(1) <= '1';
end if;

 if CpldCS = '0' and WRDL = 1 and (CA = AverageIntAddr)
then AverageIntReg <= CD(6 downto 0);
else AverageIntReg <= AverageIntReg;
end if;

-- LED flasher width and repetition rate registers 
if CpldCS = '0' and WRDL = 1 and (CA = LEDPlsRateAddr)
then LEDPlsRateReg <= CD;
else LEDPlsRateReg <= LEDPlsRateReg;
end if;

if CpldCS = '0' and WRDL = 1 and (CA = LEDPlsWidthAddr)
then LEDPlsWidthReg <= CD(9 downto 0);
else LEDPlsWidthReg <= LEDPlsWidthReg;
end if;

-- Trigger parameter register
 if CpldCS = '0' and WRDL = 1 and (CA = TrigParmAddr)
then TrigParm <= CD(5 downto 0);
else TrigParm <= TrigParm;
end if;

-- Trigger baseline length registers
 if CpldCS = '0' and WRDL = 1 and (CA = BaseLengthAddr)
then PhBaseLength <= CD(6 downto 0);
	 QBaseLength <= CD(14 downto 8);
else PhBaseLength <= PhBaseLength;
	 QBaseLength <= QBaseLength;
end if;

-- Trigger sample length registers
 if CpldCS = '0' and WRDL = 1 and (CA = TrgSmplLngthAddr)
then PhSigSmplLngth <= CD(4 downto 0);
	 QSigSmplLngth <= CD(12 downto 8);
else PhSigSmplLngth <= PhSigSmplLngth;
	 QSigSmplLngth <= QSigSmplLngth;
end if;

-- Self trigger threshold registers
-- Phonon thresholds
 if CpldCS = '0' and WRDL = 1 and (CA = PhAThreshAddr)
then PhTrigThresh(0) <= CD(13 downto 0);
else PhTrigThresh(0) <= PhTrigThresh(0);
end if;
 if CpldCS = '0' and WRDL = 1 and (CA = PhBThreshAddr)
then PhTrigThresh(1) <= CD(13 downto 0);
else PhTrigThresh(1) <= PhTrigThresh(1);
end if;
 if CpldCS = '0' and WRDL = 1 and (CA = PhCThreshAddr)
then PhTrigThresh(2) <= CD(13 downto 0);
else PhTrigThresh(2) <= PhTrigThresh(2);
end if;
 if CpldCS = '0' and WRDL = 1 and (CA = PhDThreshAddr)
then PhTrigThresh(3) <= CD(13 downto 0);
else PhTrigThresh(3) <= PhTrigThresh(3);
end if;
-- Charge thresholds
 if CpldCS = '0' and WRDL = 1 and (CA = QIThreshAddr)
then QTrigThresh(0) <= CD;
else QTrigThresh(0) <= QTrigThresh(0);
end if;
 if CpldCS = '0' and WRDL = 1 and (CA = QOThreshAddr)
then QTrigThresh(1) <= CD;
else QTrigThresh(1) <= QTrigThresh(1);
end if;

 if CpldCS = '0' and RDDL = 1
then
 Case CA is
	when PhTrigCnt0Addr => CntStage <= PhTrigCnt0;
 	when PhTrigCnt1Addr => CntStage <= PhTrigCnt1;
 	when PhTrigCnt2Addr => CntStage <= PhTrigCnt2;
 	when PhTrigCnt3Addr => CntStage <= PhTrigCnt3;
    when QTrigCnt0Addr => CntStage <= QTrigCnt0;
    when QTrigCnt1Addr => CntStage <= QTrigCnt1;
	when others => CntStage <= CntStage;
	end case;
 else  CntStage <= CntStage;
end if;

-- Read strobe logic for FIFOs read by the microcontroller
-- The uC address lines become invalid as soon as the read strobe is de-asserted
-- Latch the uC FIFO read so that the a FIFO read request occurs on the trailing 
-- edge of the uC strobe. 
if (Trig_Fiford = '0' and RDDL = 1 and CpldCS = '0' and CA = TrigFifoLoAddr)
then Trig_Fiford <= '1';
elsif Trig_Fiford = '1' and RDDL = 2
then Trig_Fiford <= '0';
else Trig_Fiford <= Trig_Fiford;
end if;

-- Trig FIFO read is one clock tick wide on the trailing edge of read strobe
-- If WrtEn is 0, empty out the FIFO
if (Trig_Fiford = '1' and RDDL = 2) or SysWrtEn = '0'
	then Trig_Fifordreq <= '1';
else Trig_Fifordreq <= '0';
end if;

if Out_Queuerd = '0' and RDDL = 1 and CpldCS = '0' and CA = SDRamPort
then Out_Queuerd <= '1';
elsif Out_Queuerd = '1' and RDDL = 2
then Out_Queuerd <= '0';
else Out_Queuerd <= Out_Queuerd;
end if;

-- Output FIFO read is one clock tick wide on the trailing edge of read strobe
-- If WrtEn is 0, empty out the FIFO
if Out_Queuerd = '1' and RDDL = 2 
 then Out_Queuerdreq <= '1';
else Out_Queuerdreq <= '0';
end if;

-------------------- Shadow LED pulse generator registers -------------------

-- Turn on and off LED pulser only while LEDs are off
   if LEDPlsEn(1) = '0' and LEDPlsReq(1) = '1' then LEDPlsEn(1) <= '1';
elsif LEDPlsEn(1) = '1' and LEDPlsReq(1) = '0' and LEDOn(1) = '0'
then LEDPlsEn(1) <= '0';
end if;

   if LEDPlsEn(2) = '0' and LEDPlsReq(2) = '1' then LEDPlsEn(2) <= '1';
elsif LEDPlsEn(2) = '1' and LEDPlsReq(2) = '0' and LEDOn(2) = '0'
then LEDPlsEn(2) <= '0';
end if;

-- 10us time base
if (LEDTimer /= LEDCount) then LEDTimer <= LEDTimer + 1;
elsif (LEDTimer = LEDCount) then LEDTimer <= ("00" & X"00");
end if;

if (LEDTimer = LEDCount) and (LEDRateCnt /= LEDPlsRateReg & "0")
	then LEDRateCnt <= LEDRateCnt + 1;
elsif (LEDTimer = LEDCount) and (LEDRateCnt = LEDPlsRateReg & "0")
	then LEDRateCnt <= ("0" & X"0000");
else LEDRateCnt <= LEDRateCnt;
end if;

if (LEDOn /= 0) and (LEDTimer = LEDCount) and (LEDWidthCnt /= LEDPlsWidthReg)
	then LEDWidthCnt <= LEDWidthCnt + 1;
elsif (LEDOn = 0) or ((LEDTimer = LEDCount) and (LEDWidthCnt = LEDPlsWidthReg))
	then LEDWidthCnt <= ("00" & X"00");
else LEDWidthCnt <= LEDWidthCnt;
end if;

-- Bits to show when LEDs should be on
if (LEDTimer = LEDCount)
	then if LEDOn(1) = '0' and  LEDPlsEn(1) = '1' and (LEDRateCnt = LEDPlsRateReg & "0") and LEDPlsRateReg & "0" > X"0000"
		  then LEDOn(1) <= '1';
	     elsif LEDOn(1) = '1' and (LEDPlsEn(1) = '0' or (LEDWidthCnt = LEDPlsWidthReg))
		  then LEDOn(1) <= '0';
		 end if; -- LEDOn = '0'..
else LEDOn(1) <= LEDOn(1);
end if; -- (LEDtimer..

if (LEDTimer = LEDCount)
	then if LEDOn(2) = '0' and  LEDPlsEn(2) = '1' and (LEDRateCnt = LEDPlsRateReg & "0") and LEDPlsRateReg & "0" > X"0000"
		  then LEDOn(2) <= '1';
	     elsif LEDOn(2) = '1' and (LEDPlsEn(2) = '0' or (LEDWidthCnt = LEDPlsWidthReg))
		  then LEDOn(2) <= '0';
		 end if; -- LEDOn(1) = '0'..
else LEDOn(2) <= LEDOn(2);
end if; -- (LEDtimer..

 if CpldCS = '0' and WRDL = 1 and (CA = LEDPlsCtrlBits)
then FetHeat <= CD(8); 
else FetHeat <= FetHeat;
end if;

--------------------------------------------------------------------------------------------------

-- Use these bits to align ADCTimer with VXOCnt
if VXOCnt = 31 then VXOCntDl(0) <= '1';
else VXOCntDl(0) <= '0';
end if;
VXOCntDl(1) <= VXOCntDl(0);

-- Use this counter as the master timer for ADC control signals
if VXOCntDl = 1 then ADCTimer <= "110111";
else ADCTimer <= ADCTimer + 1;
end if;

-- 16 clock ticks @80MHz define the 2.5 msps phonon conversion cycle
-- Strobes indicating an ADC word has been shifted in
 if ADCTimer(4 downto 0) = 30 and SysWrtEn = '1'
  then QADCRdy <= '1';
  else QADCRdy <= '0'; 
  end if;

 if ADCTimer(4 downto 0) = 30 and SysWrtEn = '1'
then Charge_Shift(0) <= QSumOut(0)(17 downto 2);
	  Charge_Shift(1) <= QSumOut(1)(17 downto 2);
else Charge_Shift(0) <= Charge_Shift(0);
	  Charge_Shift(1) <= Charge_Shift(1);
end if;

-- use this register to cross clock domains
Sweep_EnDl <= Sweep_En;

-- Write to the phonon FIFOs for one extra clock tick if DDS frequency sweep
-- and Phase data writing is enabled
if (ADCTimer = 0 or (ADCTimer = 4 and PhiWrt_En = '1' and Sweep_EnDl = '1')) and SysWrtEn = '1'
	then PhADCRdy <= '1'; 		 
   else PhADCRdy <= '0'; 		 
end if;

if ADCTimer(4 downto 0) = 30 then OvrSmplClkEn <= '1'; 
else OvrSmplClkEn <= '0';
end if;

if ADCTimer = 30 then OvrSmplLd <= '1';
else OvrSmplLd <= '0';
end if;

-------------------------- Data Averaging ----------------------------

-- Averaging interval counters
if AvgEn = '1' and SysWrtEn = '1' and PhADCRdy = '1' and PhAvgCount /= 63
	then PhAvgCount <= PhAvgCount + 1;
elsif AvgEn = '0' or SysWrtEn = '0' 
 or (AvgEn = '1' and SysWrtEn = '1' and PhADCRdy = '1' and PhAvgCount = 63)
	then PhAvgCount <= "000000";
else PhAvgCount <= PhAvgCount;
end if;

if AvgEn = '1' and SysWrtEn = '1' and QADCRdy = '1' and QAvgCount /= 63 
	then QAvgCount <= QAvgCount + 1;
elsif AvgEn = '0' or SysWrtEn = '0' 
 or (AvgEn = '1' and SysWrtEn = '1' and QADCRdy = '1' and QAvgCount = 63)
	then QAvgCount <= "000000";
else QAvgCount <= QAvgCount;
end if;

-- Sload term for averaging accumulators
if AvgEn = '1' and SysWrtEn = '1' and PhADCRdy = '1' and PhAvgCount = 63
then PhAvgLd <= '1';
else PhAvgLd <= '0';
end if;

if AvgEn = '1' and SysWrtEn = '1' and QADCRdy = '1' and QAvgCount = 63
then QAvgLd <= '1';
else QAvgLd <= '0';
end if;

-- Delay ADC ready signals one clock tick to align them with the accumulator sloads
PhAvClkEn <= PhADCRdy;
QAvClkEn  <= QADCRdy;

-- Multiplex between ADC shift registers, ADC averaging summers and phase 
-- accumulator for input spooling FIFO data
if AvgEn = '1'
   then PhFifoDat(0) <= "00" & (PhAv(0)(19 downto 6) xor "10000000000000");
		  PhFifoDat(1) <= "00" & (PhAv(1)(19 downto 6) xor "10000000000000");
		  PhFifoDat(2) <= "00" & (PhAv(2)(19 downto 6) xor "10000000000000");
		  PhFifoDat(3) <= "00" & (PhAv(3)(19 downto 6) xor "10000000000000");
 	     QFifoDat(0) <= (QAv(0)(21 downto 6) xor X"8000");
 	     QFifoDat(1) <= (QAv(1)(21 downto 6) xor X"8000");
elsif Sweep_EnDl = '1' and PhiWrt_En = '1' and (ADCTimer > 0) and (ADCTimer < 5)
   then PhFifoDat(0) <= "10" & PhaseAccReg;
		  PhFifoDat(1) <= "10" & PhaseAccReg;
		  PhFifoDat(2) <= "10" & PhaseAccReg;
		  PhFifoDat(3) <= "10" & PhaseAccReg;
		  QFifoDat(0)  <= (Charge_Shift(0) xor X"8000");
		  QFifoDat(1)  <= (Charge_Shift(1) xor X"8000");
 else 
		PhFifoDat(0) <= "00" & (OvrSmpl(0)(14 downto 1) xor "10000000000000");
		PhFifoDat(1) <= "00" & (OvrSmpl(1)(14 downto 1) xor "10000000000000");
		PhFifoDat(2) <= "00" & (OvrSmpl(2)(14 downto 1) xor "10000000000000");
		PhFifoDat(3) <= "00" & (OvrSmpl(3)(14 downto 1) xor "10000000000000");
		QFifoDat(0)  <= (Charge_Shift(0) xor X"8000");
		QFifoDat(1)  <= (Charge_Shift(1) xor X"8000");
end if;

-- Strobe input spooling FIFO at the appropriate rate
if PhADCRdy = '1' and SysWrtEn = '1' and (AvgEn = '0' or PhAvgCount = 63)
	then PhWrtReq <=  '1';
   else PhWrtReq <=  '0';
end if;

if QADCRdy = '1' and SysWrtEn = '1' and (AvgEn = '0' or QAvgCount = 63)
	then QWrtReq <= '1'; 
   else QWrtReq <= '0';	
end if;

------------------------------ Trigger logic  ------------------------------

-- Use the rising edge of WrtEn to initialize trigger arithmetic
if WrtEnDl(0) = '0' and SysWrtEn = '1' and ADCTimer = 4 then WrtEnDl(0) <= '1';
elsif SysWrtEn = '0' then WrtEnDl(0) <= '0';
else WrtEnDl(0) <= WrtEnDl(0);
end if;
WrtEnDl(1) <= WrtEnDl(0);

-- Initialization waits until the next phonon ADC read
if WrtEnDl = 1 then 
	   TrigInitReq <= '1';
elsif TrigInitReq = '1' and PhWrtReq = '1'
then  TrigInitReq <= '0';
else TrigInitReq <= TrigInitReq; 
end if;

-- Reset trigger averaging accumulators
if (QSmplInitCnt = QSigSmplLngth) and ADCTimer = 0
then TrigSload <= '1';
else TrigSload <= '0';
end if;

if QSmplInitCnt = 0 and QBaseInitCnt = QBaseLength + 1 and ADCTimer(4 downto 0) = 0
then QBaseSload <= '1';
else QBaseSload <= '0';
end if; 

if PhSmplInitCnt = 0 and PhBaseInitCnt = PhBaseLength + 1 and ADCTimer = 0
then PhBaseSload <= '1';
else PhBaseSload <= '0';
end if; 

-- Baseline circular buffer address counters
-- The write addresses increment once for each ADC conversion
   if SysWrtEn = '0' then PhDPWrtAddr <= "0000000";
elsif SysWrtEn = '1' and PhWrtReq = '1' then PhDPWrtAddr <= PhDPWrtAddr + 1;
else PhDPWrtAddr <= PhDPWrtAddr;
end if;

   if SysWrtEn = '0' then QDPWrtAddr <= "0000000";
elsif SysWrtEn = '1' and QWrtReq = '1' then QDPWrtAddr <= QDPWrtAddr + 1;
else QDPWrtAddr <= QDPWrtAddr;
end if;

-- At least one full set of baseline samples is required before a trigger decision 
-- can be made. The following counters set this interval after an init
-- DP Ram baseline read holdoff counters. 
   if TrigInitReq = '1' and ADCTimer = 0 then PhBaseInitCnt <= PhBaseLength + 1;
elsif PhSmplInitCnt = 0 and PhBaseInitCnt /= 0 and ADCTimer = 0
	then PhBaseInitCnt <= PhBaseInitCnt - 1;
else PhBaseInitCnt <= PhBaseInitCnt;
end if;

   if TrigInitReq = '1' and QWrtReq = '1' then QBaseInitCnt <= QBaseLength + 1;
elsif QSmplInitCnt = 0 and QBaseInitCnt /= 0 and ADCTimer(4 downto 0) = 0
	then QBaseInitCnt <= QBaseInitCnt - 1;
else QBaseInitCnt <= QBaseInitCnt;
end if;

-- DP Ram baseline read pointers
-- The read addresses increment once for each ADC conversion
   if ADCTimer = 0 and PhSmplInitCnt = 0 and PhBaseInitCnt = PhBaseLength + 1 
	then PhBaseRdPtr <= PhDPWrtAddr;
elsif ADCTimer = 0 and PhBaseInitCnt = 0 
	then PhBaseRdPtr <= PhBaseRdPtr + 1;
else PhBaseRdPtr <= PhBaseRdPtr;
end if;

   if ADCTimer(4 downto 0) = 0 and QSmplInitCnt = 0 and QBaseInitCnt = QBaseLength + 1 
	then QBaseRdPtr <= QDPWrtAddr;
elsif ADCTimer(4 downto 0) = 0 and QBaseInitCnt = 0 
	then QBaseRdPtr <= QBaseRdPtr + 1;
else QBaseRdPtr <= QBaseRdPtr;
end if;

-- DP Ram sample read holdoff counters
   if TrigInitReq = '1' and ADCTimer = 0 then PhSmplInitCnt <= PhSigSmplLngth;
elsif ADCTimer = 0 and PhSmplInitCnt /= 0 
	then PhSmplInitCnt <= PhSmplInitCnt - 1;
else PhSmplInitCnt <= PhSmplInitCnt;
end if;

   if TrigInitReq = '1' and ADCTimer(4 downto 0) = 0 then QSmplInitCnt <= QSigSmplLngth;
elsif QSmplInitCnt /= 0 and ADCTimer(4 downto 0) = 0
	then QSmplInitCnt <= QSmplInitCnt - 1;
else QSmplInitCnt <= QSmplInitCnt;
end if;

-- DP Ram sample read pointers
    if TrigInitReq = '1' and ADCTimer = 0 then PhSmplRdPtr <= PhDPWrtAddr;
 elsif TrigInitReq = '0' and ADCTimer = 0 and PhSmplInitCnt = 0 then PhSmplRdPtr <= PhSmplRdPtr + 1;
else PhSmplRdPtr <= PhSmplRdPtr;
end if;

   if (QSmplInitCnt = QSigSmplLngth) and ADCTimer = 0 then QSmplRdPtr <= QDPWrtAddr;
elsif QSmplInitCnt = 0 and ADCTimer(4 downto 0) = 0 then QSmplRdPtr <= QSmplRdPtr + 1;
else QSmplRdPtr <= QSmplRdPtr;
end if;

-- First read the oldest signal sample, then the oldest baseline sample 
if ADCTimer(5 downto 1) < 2 then PhDPRdAddr <= PhSmplRdPtr;
else PhDPRdAddr <= PhBaseRdPtr;
end if;
if ADCTimer(4 downto 1) < 2 then QDPRdAddr <= QSmplRdPtr;
else QDPRdAddr <= QBaseRdPtr;
end if;

-- The input to the accumulator is the newest ADC sample for adding and
-- the oldest ADC sample for subtracting
if ADCTimer(5 downto 1) = 0 
	then PhSumDat(0) <= OvrSmpl(0)(14 downto 1);
		  PhSumDat(1) <= OvrSmpl(1)(14 downto 1);
		  PhSumDat(2) <= OvrSmpl(2)(14 downto 1);
		  PhSumDat(3) <= OvrSmpl(3)(14 downto 1);
else PhSumDat <= PhDPOut;
end if;

if ADCTimer(4 downto 1) = 0
	then QSumDat(0) <= QFifoDat(0);
		  QSumDat(1) <= QFifoDat(1);
else QSumDat <= QDPOut;
end if;

-- Enable accumulators once each for the new baseline add and the old baseline subtract
-- Delay the onset of the enable during subtract until the init counter has expired
if (ADCTimer = 0 and (PhSmplInitCnt = 0 or TrigInitReq = '1')) 
or (PhBaseInitCnt = 0 and ADCTimer = 7)
	then PhBaseSumEn <= '1';
else PhBaseSumEn <= '0';
end if;
if (ADCTimer(4 downto 0) = 0 and (QSmplInitCnt = 0 or TrigInitReq = '1')) 
or (QBaseInitCnt = 0 and ADCTimer(4 downto 0) = 7)
	then QBaseSumEn <= '1';
else QBaseSumEn <= '0';
end if;

-- Set add/subtract to subtract from the running sums when the oldest sample is present
-- at the pipeline outputs
if ADCTimer = 7 then 
	  PhBaseAdd_Sub <= '0'; PhBaseSummer_cin <= '1';
else PhBaseAdd_Sub <= '1'; PhBaseSummer_cin <= '0';
end if;

if ADCTimer(4 downto 0) = 7 then 
	  QBaseAdd_Sub <= '0'; QBaseSummer_cin <= '1';
else QBaseAdd_Sub <= '1'; QBaseSummer_cin <= '0';
end if;

-- Enable accumulators once each for the new sample add and old sample subtract
-- Delay the onset of the enable during subtract until the init counter has expired
if ADCTimer = 0 or (PhSmplInitCnt = 0 and ADCTimer = 5)
	then PhSmplSumEn <= '1';
else PhSmplSumEn <= '0';
end if;

if ADCTimer(4 downto 0) = 0 or (QSmplInitCnt = 0 and ADCTimer(4 downto 0) = 5)
	then QSmplSumEn <= '1';
else QSmplSumEn <= '0';
end if;

-- Set add/subtract to subtract when the oldest sample is present
if ADCTimer = 5 then 
	  PhSmplAdd_Sub <= '0'; PhSmplSummer_cin <= '1';
else PhSmplAdd_Sub <= '1'; PhSmplSummer_cin <= '0';
end if;
if ADCTimer(4 downto 0) = 5 then 
	  QSmplAdd_Sub <= '0'; QSmplSummer_cin <= '1';
else QSmplAdd_Sub <= '1'; QSmplSummer_cin <= '0';
end if;

-- Multiplex multiplier A inputs between baselinesum and samplesum
-- Multiplex multiplier B inputs between sample length and baseline length 
Case ADCTimer(3 downto 2) is
-- Sign extend threshold value to the input width of the multiplier
 when "00" => 
			  PhMult_DataA(0) <= PhTrigThresh(0)(13) & PhTrigThresh(0)(13) & PhTrigThresh(0)(13) 
			& PhTrigThresh(0)(13) & PhTrigThresh(0)(13) & PhTrigThresh(0)(13) & PhTrigThresh(0)(13) & PhTrigThresh(0);

		     PhMult_DataA(1) <= PhTrigThresh(1)(13) & PhTrigThresh(1)(13) & PhTrigThresh(1)(13) 
			& PhTrigThresh(1)(13) & PhTrigThresh(1)(13) & PhTrigThresh(1)(13) & PhTrigThresh(1)(13) & PhTrigThresh(1);	

		     PhMult_DataA(2) <= PhTrigThresh(2)(13) & PhTrigThresh(2)(13) & PhTrigThresh(2)(13) 
			& PhTrigThresh(2)(13) & PhTrigThresh(2)(13) & PhTrigThresh(2)(13) & PhTrigThresh(2)(13) & PhTrigThresh(2);	

		     PhMult_DataA(3) <= PhTrigThresh(3)(13) & PhTrigThresh(3)(13) & PhTrigThresh(3)(13) 
			& PhTrigThresh(3)(13) & PhTrigThresh(3)(13) & PhTrigThresh(3)(13) & PhTrigThresh(3)(13) & PhTrigThresh(3);	

 		      PhMult_DataB <= ("0" & PhBaseLength);

 when "01" => PhMult_DataA(0) <= PhThreshProd(0)(20 downto 0);
			     PhMult_DataA(1) <= PhThreshProd(1)(20 downto 0);
			     PhMult_DataA(2) <= PhThreshProd(2)(20 downto 0);
			     PhMult_DataA(3) <= PhThreshProd(3)(20 downto 0);
 		        PhMult_DataB <= ("000" & PhSigSmplLngth);
		
 when "10" => PhMult_DataA(0) <= PhSmplSum(0)(18) & PhSmplSum(0)(18) & PhSmplSum(0);
				  PhMult_DataA(1) <= PhSmplSum(1)(18) & PhSmplSum(1)(18) & PhSmplSum(1);	
		        PhMult_DataA(2) <= PhSmplSum(2)(18) & PhSmplSum(2)(18) & PhSmplSum(2);	
		        PhMult_DataA(3) <= PhSmplSum(3)(18) & PhSmplSum(3)(18) & PhSmplSum(3);	
 		        PhMult_DataB <= ("0" & PhBaseLength);

 when "11" => PhMult_DataA <= PhBaselineSum;
		        PhMult_DataB <= ("000" & PhSigSmplLngth);

when others => PhMult_DataA <= PhMult_DataA;
			      PhMult_DataB <= PhMult_DataB;
end case;

Case ADCTimer(3 downto 2) is
 when "00" =>  QMult_DataA(0) <= QTrigThresh(0)(15) & QTrigThresh(0)(15) & QTrigThresh(0)(15) 
			    & QTrigThresh(0)(15) & QTrigThresh(0)(15) & QTrigThresh(0)(15) & QTrigThresh(0)(15) & QTrigThresh(0);

			      QMult_DataA(1) <= QTrigThresh(1)(15) & QTrigThresh(1)(15) & QTrigThresh(1)(15)
			    & QTrigThresh(1)(15) & QTrigThresh(1)(15) & QTrigThresh(1)(15) & QTrigThresh(1)(15) & QTrigThresh(1);	

 			     QMult_DataB <= ("0" & QBaseLength);

 when "01" => QMult_DataA(0) <= QThreshProd(0)(22 downto 0);
			     QMult_DataA(1) <= QThreshProd(1)(22 downto 0);
		        QMult_DataB <= ("000" & QSigSmplLngth);

 when "10" =>  QMult_DataA(0) <= QSmplSum(0)(20) & QSmplSum(0)(20) & QSmplSum(0);
		         QMult_DataA(1) <= QSmplSum(1)(20) & QSmplSum(1)(20) & QSmplSum(1);	
 		         QMult_DataB <= ("0" & QBaseLength);

 when "11" =>  QMult_DataA <= QBaselineSum;
		         QMult_DataB <= ("000" & QSigSmplLngth);

when others => QMult_DataA <= QMult_DataA;
			      QMult_DataB <= QMult_DataB;
end case;

-- The comparator has as its inputs:
-- (samplesum * baseline length - baselinesum * sample length) vs (thresh * baseline length * sample length)

-- store threshold * baseline length * sample length
if ADCTimer = 3 or ADCTimer = 7 then PhThreshProd <= PhProduct;
else PhThreshProd <= PhThreshProd;
end if;

if ADCTimer(4 downto 0) = 3 or ADCTimer(4 downto 0) = 7 then QThreshProd <= QProduct;
else QThreshProd <= QThreshProd;
end if;

-- store signal * baseline length
if ADCTimer = 11 then PhSigProdReg <= PhProduct;
else  PhSigProdReg <=  PhSigProdReg;
end if;

if ADCTimer(4 downto 0) = 11 then QSigProdReg <= QProduct;
else  QSigProdReg <=  QSigProdReg;
end if;

-- store baseline * sample length
if ADCTimer = 15 then PhBaseProdReg <= PhProduct;
else  PhBaseProdReg <=  PhBaseProdReg;
end if;

if ADCTimer(4 downto 0) = 15 then QBaseProdReg <= QProduct;
else  QBaseProdReg <=  QBaseProdReg;
end if;

-- latch the outputs of the trigger comparator to form the trigger status word
if ADCTimer = 0 then TrigStat(3 downto 0) <= PhTrig;
else TrigStat(3 downto 0) <= TrigStat(3 downto 0);
end if;

if ADCTimer(4 downto 0) = 0 then TrigStat(5 downto 4) <= QTrig;
else TrigStat(5 downto 4) <= TrigStat(5 downto 4);
end if;

-- If an enabled trigger fires, write the trigger FIFO
if (((ADCTimer(4 downto 0) = 0 and QBaseInitCnt = 0 
										 and ((QTrig(1) = '1' and TrigParm(5) = '1' and TrigInhCnt(5) = 0) or
										      (QTrig(0) = '1' and TrigParm(4) = '1' and TrigInhCnt(4) = 0)))
-- XOR trig parm with comparator bits to account for signed arithmetic
or (ADCTimer = 0  and PhBaseInitCnt = 0 
						and (((PhTrig(3) = '1' xor PhTrigThresh(3)(13) = '1') and TrigParm(3) = '1' and TrigInhCnt(3) = 0) or
							  ((PhTrig(2) = '1' xor PhTrigThresh(2)(13) = '1') and TrigParm(2) = '1' and TrigInhCnt(2) = 0) or 
							  ((PhTrig(1) = '1' xor PhTrigThresh(1)(13) = '1') and TrigParm(1) = '1' and TrigInhCnt(1) = 0) or
							  ((PhTrig(0) = '1' xor PhTrigThresh(0)(13) = '1') and TrigParm(0) = '1' and TrigInhCnt(0) = 0)))
							  ) and TstSigTrigEn = '0' and SysWrtEn = '1')
-- If trigger is test signal inflection, use the DDS rollover as trigger
	 or (TstSigTrigEn = '1' and CycleEdge = 1 and TrigFIFO_Empty = '1')
then Trig_Fifowrreq <= '1';
else Trig_Fifowrreq <= '0';
end if;

-- Put a ~150us deadtime between charge triggers
-- Charge deatime counters
if QTrig(1) = '1' and TrigParm(5) = '1' and QBaseInitCnt = 0 
	and TrigInhCnt(5) = 0 and ADCTimer = 0 
then TrigInhCnt(5) <= QDeadTime;
elsif (TrigInhCnt(5) /= 0) and ADCTimer = 0 then TrigInhCnt(5) <= TrigInhCnt(5) - 1;
elsif TrigInitReq = '1' then TrigInhCnt(5) <= "00000000";
else TrigInhCnt(5) <= TrigInhCnt(5);
end if;
if QTrig(0) = '1' and TrigParm(4) = '1' and QBaseInitCnt = 0 
	and TrigInhCnt(4) = 0 and ADCTimer = 0
then TrigInhCnt(4) <=  QDeadTime;
elsif (TrigInhCnt(4) /= 0) and ADCTimer = 0 then TrigInhCnt(4) <= TrigInhCnt(4) - 1;
elsif TrigInitReq = '1' then TrigInhCnt(4) <= "00000000";
else TrigInhCnt(4) <= TrigInhCnt(4);
end if;

-- Put a ~150us deadtime between phonon triggers
-- Phonon deatime counters
if (PhTrig(3) = '1' xor PhTrigThresh(3)(13) = '1') and TrigParm(3) = '1' 
and PhBaseInitCnt = 0 and TrigInhCnt(3) = 0 and ADCTimer = 0
then TrigInhCnt(3) <= PhDeadTime;
elsif (TrigInhCnt(3) /= 0) and ADCTimer = 0
then TrigInhCnt(3) <= TrigInhCnt(3) - 1;
elsif TrigInitReq = '1' then TrigInhCnt(3) <= "00000000";
else TrigInhCnt(3) <= TrigInhCnt(3);
end if;
if (PhTrig(2) = '1' xor PhTrigThresh(2)(13) = '1') and TrigParm(2) = '1' 
and PhBaseInitCnt = 0 and TrigInhCnt(2) = 0 and ADCTimer = 0 
then TrigInhCnt(2) <= PhDeadTime;
elsif (TrigInhCnt(2) /= 0) and ADCTimer = 0
then TrigInhCnt(2) <= TrigInhCnt(2) - 1;
elsif TrigInitReq = '1' then TrigInhCnt(2) <= "00000000";
else TrigInhCnt(2) <= TrigInhCnt(2);
end if;
if (PhTrig(1) = '1' xor PhTrigThresh(1)(13) = '1') and TrigParm(1) = '1' 
and PhBaseInitCnt = 0 and TrigInhCnt(1) = 0 and ADCTimer = 0
then TrigInhCnt(1) <= PhDeadTime;
elsif (TrigInhCnt(1) /= 0) and ADCTimer = 0
then TrigInhCnt(1) <= TrigInhCnt(1) - 1;
elsif TrigInitReq = '1' then TrigInhCnt(1) <= "00000000";
else TrigInhCnt(1) <= TrigInhCnt(1);
end if;
if (PhTrig(0) = '1' xor PhTrigThresh(0)(13) = '1') and TrigParm(0) = '1' 
and PhBaseInitCnt = 0 and TrigInhCnt(0) = 0 and ADCTimer = 0 
then TrigInhCnt(0) <= PhDeadTime;
elsif (TrigInhCnt(0) /= 0) and ADCTimer = 0
then TrigInhCnt(0) <= TrigInhCnt(0) - 1;
elsif TrigInitReq = '1' then TrigInhCnt(0) <= "00000000";
else TrigInhCnt(0) <= TrigInhCnt(0);
end if;

-- Charge Trigger counters
 if CpldCS = '0' and WRDL = 1 and (CA = CSRAddr) and CD(15) = '1'
 then QTrigCnt1 <= X"0000";
elsif SysWrtEn = '1' and ADCTimer(4 downto 0) = 0 and QTrig(1) = '1' and TrigParm(5) = '1'
then  QTrigCnt1 <= QTrigCnt1 + 1;
else  QTrigCnt1 <= QTrigCnt1;
end if;

 if CpldCS = '0' and WRDL = 1 and (CA = CSRAddr) and CD(15) = '1'
 then QTrigCnt0 <= X"0000";
elsif SysWrtEn = '1' and ADCTimer(4 downto 0) = 0 and QTrig(0) = '1' and TrigParm(4) = '1'
then  QTrigCnt0 <= QTrigCnt0 + 1;
else  QTrigCnt0 <= QTrigCnt0;
end if;

-- Phonon Trigger counters
 if CpldCS = '0' and WRDL = 1 and (CA = CSRAddr) and CD(15) = '1'
 then PhTrigCnt3 <= X"0000";
elsif SysWrtEn = '1' and ADCTimer = 0 and PhTrig(3) = '1' and TrigParm(3) = '1'
then  PhTrigCnt3 <= PhTrigCnt3 + 1;
else  PhTrigCnt3 <= PhTrigCnt3;
end if;

 if CpldCS = '0' and WRDL = 1 and (CA = CSRAddr) and CD(15) = '1'
 then PhTrigCnt2 <= X"0000";
elsif  SysWrtEn = '1' and ADCTimer = 0 and PhTrig(2) = '1' and TrigParm(2) = '1'
then  PhTrigCnt2 <= PhTrigCnt2 + 1;
else  PhTrigCnt2 <= PhTrigCnt2;
end if;

 if CpldCS = '0' and WRDL = 1 and (CA = CSRAddr) and CD(15) = '1'
 then PhTrigCnt1 <= X"0000";
elsif  SysWrtEn = '1' and ADCTimer = 0 and PhTrig(1) = '1' and TrigParm(1) = '1'
then  PhTrigCnt1 <= PhTrigCnt1 + 1;
else  PhTrigCnt1 <= PhTrigCnt1;
end if;

 if CpldCS = '0' and WRDL = 1 and (CA = CSRAddr) and CD(15) = '1'
 then PhTrigCnt0 <= X"0000";
elsif  SysWrtEn = '1' and ADCTimer = 0 and PhTrig(0) = '1' and TrigParm(0) = '1'
then  PhTrigCnt0 <= PhTrigCnt0 + 1;
else  PhTrigCnt0 <= PhTrigCnt0;
end if;

-- Address at which trigger occurred
if PhWrtReq = '1' and SysWrtEn = '1' then 
	  TriggerPointer <= TriggerPointer + 1;
elsif SysWrtEn = '0' then TriggerPointer <= (others => '0');
else TriggerPointer <= TriggerPointer;
end if;

-- Counter for flashing trigger LED
if Trig_Fifowrreq = '1' then FlashCount <= X"FFF";
elsif (FlashCount /= 0) and (LEDTimer = LEDCount) 
	then FlashCount <= FlashCount - 1;
else FlashCount <= FlashCount;
end if;

if FlashCount /= 0 then StatLED(0) <= '0';
else StatLED(0) <= '1';
end if;

----------------- Serial Interface for setting up charge ADC ----------------

-- Clock runs at 80MHz, serial data bit period is SysClk div4
ClkDiv <= ClkDiv + 1;

--	Idle,Load,SetCS,Shift,ClearCS
 Case ADCCmd_Shift is
	   When Idle => 	
				if ADCCmdFIFOEmpty = '0' and ClkDiv = 0 then ADCCmd_Shift <= Load;
				else ADCCmd_Shift <= Idle;
				end if;
		When Load => ADCCmd_Shift <= SetCS;
		When SetCS => if QADCCS = '0'
							then ADCCmd_Shift <= Shift;
						 else ADCCmd_Shift <= SetCS;
						 end if;
		When Shift => if ADCCmdBitcount = 1 and ClkDiv = 0 then ADCCmd_Shift <= ClearCS;
						 else ADCCmd_Shift <= Shift;
						 end if;
	   When ClearCS => if QADCCS = '1' then ADCCmd_Shift <= Idle;
						else ADCCmd_Shift <= ClearCS;
						end if;
 end Case;

-- ADC data is 16 bits.
if WRDL = 1 and CA = ADCCmdAddr then ADCCmdFIFOWrt <= '1';
else ADCCmdFIFOWrt <= '0';
end if;

if ADCCmd_Shift = Load then ADCCmdFIFORd <= '1';
else ADCCmdFIFORd <= '0';
end if;
-- Set bit count to 16 when a load occurs
   if ADCCmd_Shift = Load then ADCCmdBitcount <= "10000";
elsif ClkDiv = 0 and ADCCmd_Shift = Shift and ADCCmdBitcount /= 0 
						 then ADCCmdBitcount <= ADCCmdBitcount - 1;
else ADCCmdBitcount <= ADCCmdBitcount;
end if;

if ADCCmd_Shift = Load then ADCCmdShift <= ADCCmdFIFOOut;
elsif ADCCmd_Shift = Shift and ClkDiv = 0 and ADCCmdBitcount /= 0 
then ADCCmdShift <= (ADCCmdShift(14 downto 0) & '0');
else ADCCmdShift <= ADCCmdShift;
end if;
QADCSDat <= ADCCmdShift(15);

if ClkDiv = 0 and ADCCmd_Shift = SetCS then QADCCS <= '0';
elsif ClkDiv = 0 and ADCCmd_Shift = ClearCS then QADCCS <= '1';
else QADCCS <= QADCCS;
end if;

-- Issue a serial clock while data is being shifted out
if QADCCS = '0' and ADCCmdBitcount /= 0 and (ClkDiv = 3 or ClkDiv = 0)
then QADCSClk <= '1';
else QADCSClk <= '0';
end if;

--------------- Serializer for sending data to the Max 570   ---------------

-- Command FIFO write request
if WRDL = 1 and CA >= LEDPlsADCAddr and CA <= QBiasDACAddr1
then CPLDFifo_wrreq <= '1';
else CPLDFifo_wrreq <= '0';
end if;

-- Signals used for CPLD command queue
 if  SDatBitCnt = 0 and Gap_Count = 0 and CPLDFifo_Empty = '0'
then CPLDFifo_rdreq <= '1';
else CPLDFifo_rdreq <= '0';
end if;

-- Run serial clock when bit count is non-zero or if LED pulser is enabled
-- if SDatBitCnt /= 0 or LEDPlsReq /= 0 or LEDPlsEn /= 0 then 
SClkDiv <= SClkDiv + 1;
-- else SClkDiv <= SClkDiv;
-- end if;

-- Send serial clock for 29 or 41 bit periods
if SDatBitCnt /= 0 and SClkDiv = 3 then SetupClk <= not SetupClk;
else SetupClk <= SetupClk;
end if;

-- Load down counter if the command FIFO has data
if SDatBitCnt = 0 and Gap_Count = 0 and CPLDFifo_Empty = '0'
 then 
-- The bit count is 40 if the destination is the 16 bit DACs, otherwise 28
if (CPLDFifo_Out(22 downto 16) >= PhA_BDacCtrl and CPLDFifo_Out(22 downto 16) <= PhA_BDacAddr7)
or (CPLDFifo_Out(22 downto 16) >= PhC_DDacCtrl and CPLDFifo_Out(22 downto 16) <= PhC_DDacAddr7)
or  CPLDFifo_Out(22 downto 16) = QBiasDACAddr0 or CPLDFifo_Out(22 downto 16) = QBiasDACAddr1
   then SDatBitCnt <= "101100";  -- decimal 44
        LongShift <= '1';
  else  SDatBitCnt <= "011100";  -- decimal 28
	    LongShift <= '0';
 end if;
elsif SDatBitCnt > 0 and SetupClk = '1' and SClkDiv = 3 then 
	SDatBitCnt <= SDatBitCnt - 1;
	LongShift <= LongShift;
else  SDatBitCnt <= SDatBitCnt;
	LongShift <= LongShift;
end if;

-- Load output shifer with data, start bits, stop bits on uC write,
-- Shift so long as bit counter is non-zero 

-- Load due to uC write to the CPLD
if SDatBitCnt = 0 and Gap_Count = 0 and CPLDFifo_Empty = '0'
  then sDatReg <= uCSDat;
-- The bit count is 40 if the destination is the 16 bit DACs, otherwise 28
 elsif SClkDiv = 3 and SetupClk = '1' and
 ((LongShift = '1' and SDatBitCnt < 44) or (LongShift = '0' and SDatBitCnt < 28))
 then sDatReg <= sDatReg(38 downto 0) & '0';
  else sDatReg <= sDatReg;
end if;

-- Frame sync for serial setup data
if    SetUpSync = '0' and SClkDiv = 3 and SetupClk = '1'
	and ((LongShift = '1' and SDatBitCnt = 44) or (LongShift = '0' and SDatBitCnt = 28))
	then SetUpSync <= '1';
	elsif SetUpSync = '1' and SDatBitCnt = 3 then SetUpSync <= '0';
 else SetUpSync <= SetUpSync;
end if;

-- Use this counter to put a pause between consecutive serial commands
if Gap_Count = 0 and SDatBitCnt = 1 
then Gap_Count <= "1111";
elsif Gap_Count /= 0 then Gap_Count <= Gap_Count - 1;
else Gap_Count <= Gap_Count;
end if;

--------------------  Link Interrupt status bits --------------------------

-- Receipt of Null on auxilliary ascii link
if DsChnRx0_active = '1' and DSChnRx0_RxDone = '1' and LVDir = '1' and DSChnRx0Dat = 0
then NullFlag <= '1';
-- Individual ISR clear
elsif (WRDL = "01" and CA = LinkISR and CD(0) = '1')
-- Global buffer reset
   or (WRDL = "01" and CA = CSRAddr and CD(14) = '1')
-- Read of this character from the FIFO
   or (RDDL = "01" and CpldCS = '0' and CA = DSChnRx0Addr and DSChnRx0BuffOut = 0)
-- This flag should only be active when listening for a response on the auxilliary port
   or LVDir = '0'
then NullFlag <= '0';
else NullFlag <= NullFlag;
end if;

if WRDL = "01" and CA = LinkISR	then ByteSwap <= CD(3);
else ByteSwap <= ByteSwap;
end if;

-- Receipt of carriage return character on primary ascii link
if BusRx0_RxDone = '1' and BusRx0Dat = X"0D"
then CR_Flag <= '1';
-- Individual ISR clear
elsif (WRDL = "01" and CA = LinkISR and CD(1) = '1')
-- Global buffer reset
or (WRDL = "01" and CA = CSRAddr and CD(14) = '1')
-- Read of this character from the FIFO
or (RDDL = "01" and CpldCS = '0' and CA = BusRx0Addr and BusRx0BuffOut = X"0D")
then CR_Flag <= '0';
else CR_Flag <= CR_Flag;
end if;

-- Receipt of an Init
if BusRx1_RxDone = '1' and BusRx1Dat = WriteEn
then InitFlag <= '1';
elsif WRDL = "01" and CA = LinkISR and CD(2) = '1'
then InitFlag <= '0';
else InitFlag <= InitFlag;
end if;

----------------------- Link Control and Status ------------------------

-- Daisy chain transmit enable
if CpldCS = '0' and WRDL = "01" and CA = LinkCSR
then FMTxEn <= CD(6);
else FMTxEn <= FMTxEn;
end if;

-- latch Commnad TX until the trailing edge of the uC write strobe
-- to allow time for the command to be updated by the uC
if CpldCS = '0' and WRDL = 1 and CA = CSRAddr and LVDir = '1'
then CMDWrtReq <= '1';
elsif WRDL = 2
then CMDWrtReq <= '0';
else CMDWrtReq <= CMDWrtReq;
end if;

-- Tx Enable for Tx1. If a master, send data on a command write
-- If a responding slave send uC data, otherwise transparently 
-- re-transmit data from the downstream neighbor
if (((WRDL = 2 and CMDWrtReq = '1')
or   (CpldCS = '0' and WRDL = 1 and CA = DSChnTx1Addr and FMTxEn = '1'))
or (DSChnTx1Buff_empty = '0' and FMTxEn = '0' and LVDir = '0')) and Tx1TxEn = '0'
then Tx1TxEn <= '1';
elsif Tx1TxEn = '1' and DSChnTx1_TxDone = '1'
then Tx1TxEn <= '0';
else Tx1TxEn <= Tx1TxEn;
end if;

-- Link transmit buffer writes
-- In transparent mode, send RxFIFO data to TXFifo
if (CpldCS = '0' and WRDL = 1 and CA = DSChnTx0Addr and FMTxEn = '1')
 or (DSChnRx0_RxDone = '1' and FMTxEn = '0')
then DSChnTx0_wrreq <= '1';
else DSChnTx0_wrreq <= '0';
end if;

if (CpldCS = '0' and WRDL = 1 and CA = DSChnTx1Addr and FMTxEn = '1')
 or (DSChnRx1_RxDone = '1' and FMTxEn = '0')
then DSChnTx1_wrreq <= '1';
else DSChnTx1_wrreq <= '0';
end if;

-- Clear Parity errors by writing a "1" to the appropriate CSR bit
-- Or a buffer reset
if CpldCS = '0' and WRDL = 1
	and ((CA = LinkCSR and CD(0) = '1') or (CA = CSRAddr and CD(14) = '1'))
then BusRx0Clr_Err <= '1';
else BusRx0Clr_Err <= '0';
end if;
if CpldCS = '0' and WRDL = 1
and ((CA = LinkCSR and CD(1) = '1') or (CA = CSRAddr and CD(14) = '1'))
then BusRx1Clr_Err <= '1';
else BusRx1Clr_Err <= '0';
end if;
if CpldCS = '0' and WRDL = 1
	and ((CA = LinkCSR and CD(2) = '1') or (CA = CSRAddr and CD(14) = '1'))
then DSChnRx0Clr_Err <= '1';
else DSChnRx0Clr_Err <= '0';
end if;
if CpldCS = '0' and WRDL = 1
	and ((CA = LinkCSR and CD(3) = '1') or (CA = CSRAddr and CD(14) = '1'))
then DSChnRx1Clr_Err <= '1';
else DSChnRx1Clr_Err <= '0';
end if;

-- Link receive buffer read strobes
-- Read strobe logic for FIFOs read by the microcontroller
-- Latch the uC read so that FIFO read request in on the trailing
-- edge of the strobe
-- Output FIFO read is one clock tick wide on the trailing edge of read strobe
if DSChnRx0_rdreq = '0' and RDDL = "01" and CpldCS = '0' and CA = DSChnRx0Addr
then DSChnRx0_rdreq <= '1';
elsif DSChnRx0_rdreq = '1' and RDDL = "10"
then DSChnRx0_rdreq <= '0';
else DSChnRx0_rdreq <= DSChnRx0_rdreq;
end if;
if DSChnRx0_rdreq = '1' and RDDL = "10" 
 then DSChnRx0_rd <= '1';
else DSChnRx0_rd <= '0';
end if;

if DSChnRx1_rdreq = '0' and RDDL = "01" and CpldCS = '0' and CA = DSChnRx1Addr
then DSChnRx1_rdreq <= '1';
elsif DSChnRx1_rdreq = '1' and RDDL = "10"
then DSChnRx1_rdreq <= '0';
else DSChnRx1_rdreq <= DSChnRx1_rdreq;
end if;
if DSChnRx1_rdreq = '1' and RDDL = "10" 
 then DSChnRx1_rd <= '1';
else DSChnRx1_rd <= '0';
end if;

if BusRx0_rdreq = '0' and RDDL = "01" and CpldCS = '0' and CA = BusRx0Addr
then BusRx0_rdreq <= '1';
elsif BusRx0_rdreq = '1' and RDDL = "10"
then BusRx0_rdreq <= '0';
else BusRx0_rdreq <= BusRx0_rdreq;
end if;
if BusRx0_rdreq = '1' and RDDL = "10" 
 then BusRx0_rd <= '1';
else BusRx0_rd <= '0';
end if;

-- Synchronous edge detector for checking if FM present
DsChnRx0Dl(0) <= DsChnRx(0);
DsChnRx0Dl(1) <= DsChnRx0Dl(0);

-- Borrow the LEDTimer interval counter
-- Increment this count with FM transistions, clear it periodically
if LEDTimer = LEDCount then TransitionCount <= X"0";
elsif (DsChnRx0Dl(0) = '1' xor DsChnRx0Dl(1) = '1') and TransitionCount /= X"F"
then TransitionCount <= TransitionCount + X"1";
else TransitionCount <= TransitionCount;
end if; 
-- At the end of the timing interval check to see if there were FM transitions
if    LEDTimer = LEDCount and TransitionCount = X"F" then DsChnRx0_active <= '1';
elsif LEDTimer = LEDCount and TransitionCount = X"0" then DsChnRx0_active <= '0';
else DsChnRx0_active <= DsChnRx0_active;
end if;
LVBusTerm <= not DsChnRx0_active or LVDir;

------------------------ DDS frequency sweep logic ------------------------

-- Registers containing frequency sweep paramters
if WRDL = 1 and CA = DDSAddr1
then No_of_Steps <= CD(11 downto 0);
else No_of_Steps <= No_of_Steps;
end if;

if WRDL = 1 and CA = DDSAddr2
then DeltaF(11 downto 0) <= CD(11 downto 0);
else DeltaF(11 downto 0) <= DeltaF(11 downto 0);
end if;

if WRDL = 1 and CA = DDSAddr3
then DeltaF(23 downto 12) <= CD(11 downto 0);
else DeltaF(23 downto 12) <= DeltaF(23 downto 12);
end if;

if WRDL = 1 and CA = DDSAddr4
then Step_interval <= CD(13 downto 0);
else Step_interval <= Step_interval;
end if;

if WRDL = 1 and CA = DDSAddr5
then StartFreq(11 downto 0) <= CD(11 downto 0);
else StartFreq(11 downto 0) <= StartFreq(11 downto 0);
end if;

if WRDL = 1 and CA = DDSAddr6
then StartFreq(23 downto 12) <= CD(11 downto 0);
else StartFreq(23 downto 12) <= StartFreq(23 downto 12);
end if;

-- If the DDSCtrl bit has been set, assert start sweep request
if WRDL = 1 and CA = TstPlsCtrlAd and CD(13) = '1'
then Sweep_Req <= '1';
elsif SetUpSyncDL = 1
then Sweep_Req <= '0';
else Sweep_Req <= Sweep_Req;
end if;

-- use these Dffs to detect end of serial transmission to the CPLD
if SetUpSync = '0' 
then SetUpSyncDL(0) <= '1'; 
else SetUpSyncDL(0) <= '0'; 
end if;

SetUpSyncDL(1) <= SetUpSyncDL(0);

-- If start sweep request is set, assert sweep enable at the end of serial transmit
if Sweep_Req = '1' and SetUpSyncDL = 1
then Sweep_En <= '1';
elsif (Interval_Count = 1 and Step_Count = No_of_Steps)
   or (WRDL = 1 and CA = DDSAddr0)
then Sweep_En <= '0';
else Sweep_En <= Sweep_En;
end if;

if WRDL = 1 and CA = DDSAddr0 then DAC_En <= CD(10);
else DAC_En <= DAC_En;
end if;

-- Logic for prescale multiplier bits
case Step_interval(12 downto 11) is
 when "00" => Prescale_Value <= "0" & X"00"; -- 1
 when "01" => Prescale_Value <= "0" & X"04"; -- 5
 when "10" => Prescale_Value <= "0" & X"63"; -- 100
 when "11" => Prescale_Value <= "1" & X"F3"; -- 500
 when others =>
end case;

-- Prescale counter
if Sweep_En = '1' and Interval_Prescale /= Prescale_Value and 
   (Step_interval(13) = '0' or (Phase_Acc(23) = '0' and Phase_Acc_Dl = '1'))
then Interval_Prescale <= Interval_Prescale + 1;
elsif Interval_Prescale = Prescale_Value and
   ((Step_interval(13) = '0' or (Phase_Acc(23) = '0' and Phase_Acc_Dl = '1'))
    or (Sweep_Req = '1' and SetUpSyncDL = 1))
then Interval_Prescale <= "0" & X"00";
else Interval_Prescale <= Interval_Prescale;
end if;

-- Step interval counter. The step_Interval(13) bit selects increment after a 
-- specified number of 50MHz clock ticks, or a specified number of waveform
-- cycles
if Sweep_En = '1' and Interval_Prescale = Prescale_Value and Interval_Count /= Step_interval(10 downto 0) and
	Step_Count /= No_of_Steps and (Step_interval(13) = '1' or (Phase_Acc(23) = '0' and Phase_Acc_Dl = '1'))
then Interval_Count <= Interval_Count + 1;
elsif (Sweep_Req = '1' and SetUpSyncDL = 1) or
(Interval_Prescale = Prescale_Value and Interval_Count = Step_interval(10 downto 0) 
  and (Step_interval(13) = '1' or (Phase_Acc(23) = '0' and Phase_Acc_Dl = '1')))
then Interval_Count <= "000" & X"01";
else Interval_Count <= Interval_Count;
end if;

-- Step counter. When the step interval count reaches a specified value, 
-- increment the step counter.
if Sweep_En = '1' and Interval_Prescale = Prescale_Value and Interval_Count = Step_interval(10 downto 0) 
  and (Step_interval(13) = '1' or (Phase_Acc(23) = '0' and Phase_Acc_Dl = '1'))
then Step_Count <= Step_Count + 1;
elsif Sweep_Req = '1' and SetUpSyncDL = 1
then Step_Count <= X"000";
else Step_Count <= Step_Count;
end if;

-- When the step counter increments, change the frequency by delta F
if Sweep_Req = '0' or (Sweep_Req = '1' and SetUpSyncDL = 1)
then Present_Freq <= StartFreq;
elsif Sweep_En = '1' and Interval_Prescale = Prescale_Value and Interval_Count = Step_interval(10 downto 0) 
  and (Step_interval(13) = '1' or (Phase_Acc(23) = '0' and Phase_Acc_Dl = '1'))
then Present_Freq <= Present_Freq + DeltaF;
else Present_Freq <= Present_Freq;
end if;

-- Clear the phase accumulator at the start of a frequency sweep
if Sweep_Req = '1' and SetUpSyncDL = 1
then Phase_Acc <= X"000000";
else Phase_Acc <= Phase_Acc + Present_Freq;
end if;

Phase22D <= Phase_Acc(22);
if Phase_Acc(23) = '1' and Phase_Acc(22) = '0' and Phase22D = '1' then 
	MirrorBit <= not MirrorBit; 
else MirrorBit <= MirrorBit;
end if;

DacDiv <= not DacDiv;

if  DacDiv = '0' and DAC_En = '1' then 
		Dac <= Phase_Acc(23 downto 14) xor (MirrorBit & MirrorBit & MirrorBit & MirrorBit & MirrorBit 
		 										    & MirrorBit & MirrorBit & MirrorBit & MirrorBit & MirrorBit);
elsif DAC_En = '0' then Dac <= (others => '0');
else Dac <= Dac;
end if;

TimerDL(0) <= ADCTimer(5);
TimerDL(1) <= TimerDL(0);
-- Latch the phase accumulator in preparation for an spooling FIFO write.
if TimerDL = 2 then PhaseAccReg <= Phase_Acc(23 downto 10);
else PhaseAccReg <= PhaseAccReg;
end if;
-- Synchronous edge detection of a waveform cycle
if Sweep_Req = '1' and SetUpSyncDL = 1
then Phase_Acc_Dl <= '0';
else Phase_Acc_Dl <= Phase_Acc(23);
end if;

if PhRepeat = '0' and Sweep_En = '1' and (AcqState = AcqIdle) and SDWrtEn = '1' and (RAMState = Nop)
 then PhRepeat <= '1';
elsif PhRepeat = '1' and (AcqState = AcqIdle) and SDWrtEn = '1' and (RAMState = Nop)
 then PhRepeat <= '0';
else PhRepeat <= PhRepeat;
end if;

-- Synchronous edge detector for DDS phase accumulator rollover
-- Cross clock boundaries 
CycleEdge(0) <= MirrorBit;
CycleEdge(1) <= CycleEdge(0);

end if; -- CpldRst

end process main;

------------------------ Address mapping for CPLD data ------------------------

-- Translate FPGA addressing to CPLD addressing
with CPLDFifo_Out(22 downto 16) select
 uCSDat <= X"00" & CPLDFifo_Out(15 downto 0) & X"0000" when LEDPlsCtrlBits,
 	   X"20"  & '1' & CPLDFifo_Out(14 downto 0) & X"0000" when PhGainsDACCtrl,
	   X"200" & CPLDFifo_Out(11 downto 0) & X"0000" when PhGainsDACAddr0,
	   X"201" & CPLDFifo_Out(11 downto 0) & X"0000" when PhGainsDACAddr1,
	   X"202" & CPLDFifo_Out(11 downto 0) & X"0000" when PhGainsDACAddr2,
	   X"203" & CPLDFifo_Out(11 downto 0) & X"0000" when PhGainsDACAddr3,
	   X"204" & CPLDFifo_Out(11 downto 0) & X"0000" when PhGainsDACAddr4,
	   X"205" & CPLDFifo_Out(11 downto 0) & X"0000" when PhGainsDACAddr5,
	   X"206" & CPLDFifo_Out(11 downto 0) & X"0000" when PhGainsDACAddr6,
	   X"207" & CPLDFifo_Out(11 downto 0) & X"0000" when PhGainsDACAddr7,
	   X"30"  & CPLDFifo_Out(15 downto 0) & X"0000" when TstPlsCtrlAd,
	   X"400" & CPLDFifo_Out(11 downto 0) & X"0000" when DDSAddr0,
	   X"401" & CPLDFifo_Out(11 downto 0) & X"0000" when DDSAddr1,
	   X"402" & CPLDFifo_Out(11 downto 0) & X"0000" when DDSAddr2,
	   X"403" & CPLDFifo_Out(11 downto 0) & X"0000" when DDSAddr3,
	   X"40" & "01" & CPLDFifo_Out(13 downto 0) & X"0000" when DDSAddr4,
	   X"40C" & CPLDFifo_Out(11 downto 0) & X"0000" when DDSAddr5,
	   X"40D" & CPLDFifo_Out(11 downto 0) & X"0000" when DDSAddr6,
	   X"501" & CPLDFifo_Out(11 downto 0) & X"0000" when TstPlsMagAddr,

	   X"60" & CPLDFifo_Out(15 downto 0) & X"0000" when PhA_BCtlrAddr,

	   X"70" & CPLDFifo_Out(15 downto 12) & X"0000" & CPLDFifo_Out(11 downto 0) when PhA_BDacCtrl,
	   X"70034" & CPLDFifo_Out(15 downto 0) & X"0" when PhA_BDacAddr0,
	   X"70035" & CPLDFifo_Out(15 downto 0) & X"0" when PhA_BDacAddr1,
	   X"70036" & CPLDFifo_Out(15 downto 0) & X"0" when PhA_BDacAddr2,
	   X"70037" & CPLDFifo_Out(15 downto 0) & X"0" when PhA_BDacAddr3,
	   X"70030" & CPLDFifo_Out(15 downto 0) & X"0" when PhA_BDacAddr4,
  	   X"70031" & CPLDFifo_Out(15 downto 0) & X"0" when PhA_BDacAddr5,
	   X"70032" & CPLDFifo_Out(15 downto 0) & X"0" when PhA_BDacAddr6,
	   X"70033" & CPLDFifo_Out(15 downto 0) & X"0" when PhA_BDacAddr7,

	   X"80" & CPLDFifo_Out(15 downto 0) & X"0000" when PhC_DCtlrAddr,

	   X"90" & CPLDFifo_Out(15 downto 12) & X"0000" & CPLDFifo_Out(11 downto 0) when PhC_DDacCtrl,
	   X"90034" & CPLDFifo_Out(15 downto 0) & X"0" when PhC_DDacAddr0,
	   X"90035" & CPLDFifo_Out(15 downto 0) & X"0" when PhC_DDacAddr1,
	   X"90036" & CPLDFifo_Out(15 downto 0) & X"0" when PhC_DDacAddr2,
	   X"90037" & CPLDFifo_Out(15 downto 0) & X"0" when PhC_DDacAddr3,
	   X"90030" & CPLDFifo_Out(15 downto 0) & X"0" when PhC_DDacAddr4,
	   X"90031" & CPLDFifo_Out(15 downto 0) & X"0" when PhC_DDacAddr5,
	   X"90032" & CPLDFifo_Out(15 downto 0) & X"0" when PhC_DDacAddr6,
	   X"90033" & CPLDFifo_Out(15 downto 0) & X"0" when PhC_DDacAddr7,

	   X"A0" & X"0002" & CPLDFifo_Out(15 downto 0) when QBiasDACAddr0,
	   X"A0" & X"0001" & CPLDFifo_Out(15 downto 0) when QBiasDACAddr1,
	   X"B00" & "00" & CPLDFifo_Out(9 downto 0) & X"0000" when LEDPlsWidthAddr,
	   X"C0" & CD & X"0000" when LEDPlsRateAddr,
 	   X"0000000000" when others;

--------------------------- 50Mhz logic ------------------------------

SDRAMCtrl : process(SDClk, CpldRst)

 begin

-- asynchronous reset
  if CpldRst = '0' then

	RefreshCount <= ("00" & X"00");
	SDRDDL <= "00"; SDWRDL <= "00"; RAMState <= Nop; AcqState <= AcqIdle;
	SDWrtEn <= '0'; SDWrtReq <= '0'; SDReadReq <= '0'; InitReq <= '0'; RefreshReq <= '0';
	SDRamAddr <= (others => '0'); PhononPtr <= (others => '0');
	ChargePtr <= (others => '0'); ResetCount <= "00000"; BrstCnt <= "000"; 
	MaskCnt <= "000"; SDCS <= '1'; Ras <= '1'; Cas <= '1'; WE <= '1'; 
	DQM <= '1'; PhRdReq <= "0000"; QRdReq <= "00";
	Out_Queuewrreq <= '0'; 

 elsif rising_edge (SDClk) then

--------------------------- SDRAM controller ------------------------------

-- Synchronous edge detector for uC strobes with respect to SysPll.clk1 (100 MHz)
-- Synchronous edge detectors for read and write strobes
 if CpldCS = '0' and RD = '0' then SDRDDL(0) <= '1'; else SDRDDL(0) <= '0'; end if;
 SDRDDL(1) <= SDRDDL(0);
 if CpldCS = '0' and WR = '0' then SDWRDL(0) <= '1'; else SDWRDL(0) <= '0'; end if;
 SDWRDL(1) <= SDWRDL(0);

 SDWrtEn <= SysWrtEn;

-- Reads and writes must wait if a refresh cycle is under way. Set the read
-- or write request with the uC, clear with read or write complete

if SDReadReq = '0' and SDWRDL = 1 and ((CA = SDRamRdPtrLoAd)
									or (CA = PhAADCDatLoAddr)
									or (CA = PhBADCDatLoAddr)
									or (CA = PhCADCDatLoAddr)
									or (CA = PhDADCDatLoAddr)
									or (CA = QIADCDatLoAddr)
									or (CA = QOADCDatLoAddr))
	then SDReadReq <= '1';
elsif SDReadReq = '1' and SDWRDL = 1 and (CA = CSRAddr) and (CD(5) = '0')
	then SDReadReq <= '0';
else SDReadReq <= SDReadReq;
end if;

-- If there are at least eight words in the specified fifo, do a burst write into the SDRAM
if SDWrtReq = '0' and RAMState = Nop 
					  and ((AcqState = WrtPhononA  and PhononWords(0) > 7)
					    or (AcqState = WrtPhononB  and PhononWords(1) > 7)
					    or (AcqState = WrtPhononC  and PhononWords(2) > 7)
					    or (AcqState = WrtPhononD  and PhononWords(3) > 7)
					    or (AcqState = WrtChargeI0 and ChargeWords(0) > 7)
					    or (AcqState = WrtChargeI1 and ChargeWords(0) > 7)
					    or (AcqState = WrtChargeO0 and ChargeWords(1) > 7)
					    or (AcqState = WrtChargeO1 and ChargeWords(1) > 7))
  then SDWrtReq <= '1';  
 elsif SDWrtReq = '1' and (RAMState = WaitPrecharge1)
  then SDWrtReq <= '0';  
else SDWrtReq <= SDWrtReq;
end if;

-- Read a block of eight words from the Phonon FIFOs into the SDRAM when the 
-- SDRAM is ready to be written. If SDWrtEn is off, empty out the FIFOs
if (RAMState = SDWrite and AcqState = WrtPhononA) or SDWrtEn = '0'
 then PhRdReq(0) <= '1';
elsif BrstCnt = 1 or (SDWrtEn = '1' and AcqState = AcqIdle) then PhRdReq(0) <= '0';
else PhRdReq(0) <= PhRdReq(0);
end if;
if (RAMState = SDWrite and AcqState = WrtPhononB) or SDWrtEn = '0'
 then PhRdReq(1) <= '1';
elsif BrstCnt = 1 or (SDWrtEn = '1' and AcqState = AcqIdle) then PhRdReq(1) <= '0';
else PhRdReq(1) <= PhRdReq(1); 
end if;
if (RAMState = SDWrite and AcqState = WrtPhononC) or SDWrtEn = '0'
 then PhRdReq(2) <= '1';
elsif BrstCnt = 1 or (SDWrtEn = '1' and AcqState = AcqIdle) then PhRdReq(2) <= '0';
else PhRdReq(2) <= PhRdReq(2); 
end if;
if (RAMState = SDWrite and AcqState = WrtPhononD) or SDWrtEn = '0'
 then PhRdReq(3) <= '1';
elsif BrstCnt = 1 or (SDWrtEn = '1' and AcqState = AcqIdle) then PhRdReq(3) <= '0';
else PhRdReq(3) <= PhRdReq(3); 
end if;

-- Read from the Charge FIFOs into the SDRAM when the SDRAM is ready for writes
if (RAMState = SDWrite  and (AcqState = WrtChargeI0 or AcqState = WrtChargeI1)) or SDWrtEn = '0'
then QRdReq(0) <= '1';
elsif BrstCnt = 1 or (SDWrtEn = '1' and AcqState = AcqIdle) then QRdReq(0) <= '0'; 
else QRdReq(0) <= QRdReq(0);
end if;

if (RAMState = SDWrite and (AcqState = WrtChargeO0 or AcqState = WrtChargeO1)) or SDWrtEn = '0'
then QRdReq(1) <= '1';
elsif BrstCnt = 1 or (SDWrtEn = '1' and AcqState = AcqIdle) then QRdReq(1) <= '0'; 
else QRdReq(1) <= QRdReq(1);
end if;

-- Count down SDRam Read addresses not on even burst block boundaries
if SDWRDL = 1 and (CA = SDRamRdPtrLoAd  or CA = PhAADCDatLoAddr
				    or CA = PhBADCDatLoAddr or CA = PhCADCDatLoAddr
				    or CA = PhDADCDatLoAddr)
then MaskCnt <= CD(2 downto 0);
elsif SDWRDL = 1 and 
				   (CA = QIADCDatLoAddr or CA = QOADCDatLoAddr)
then MaskCnt <= CD(1 downto 0) & "0";
elsif MaskCnt /= 0 and SDReadReq = '1' and SDWrtReq = '0' and RAMState = Wait1
then MaskCnt <= MaskCnt - 1;
else MaskCnt <= MaskCnt;
end if;

-- Write into the output spooling FIFO when the SDRAM is ready for reads
if SDReadReq = '1' and SDWrtReq = '0' and RAMState = Wait1 and MaskCnt = 0
then Out_Queuewrreq <= '1'; 
else Out_Queuewrreq <= '0';
end if;

-- The refresh period is 7.8us per row, 8192 rows, use auto refresh 
   if (RefreshCount < RefreshTime) then RefreshCount <= RefreshCount + 1;
elsif (RefreshCount = RefreshTime) then RefreshCount <= ("00" & X"00");
else RefreshCount <= RefreshCount;
end if;

-- Wait 100 us after reset before starting SDRam 
if (RefreshCount = RefreshTime) and (ResetCount < 31) 
then ResetCount <= ResetCount + 1;
else ResetCount <= ResetCount;
end if;

-- At the end of the reset interval, go through the initialization sequence
   if InitReq = '0' and (RefreshCount = RefreshTime) and (ResetCount = 30)
then InitReq <= '1';
elsif InitReq = '1' and (RAMState = Load_Mode) then InitReq <= '0';
else InitReq <= InitReq;
end if;

-- If a read or write is in progress, wait with refresh until the cycle is finished
-- Set the request with the refresh timer, clear with refresh complete
if RefreshReq = '0' and InitReq = '0' and (RefreshCount = RefreshTime) and (ResetCount = 31)
then RefreshReq <= '1';
elsif RefreshReq = '1' and (RAMState = Refresh) then RefreshReq <= '0';
else RefreshReq <= RefreshReq;
end if;

-- SDRAM read address register
-- Increment during reads into output spooling FIFO modulo 

-- modulo phonon page size for phonon data
if DQM = '0' and SDWRDL /= 1 
	and SDWrtReq = '0' and (SDRamAddr < ChargeBaseAd)
then SDRamAddr(24 downto 22) <= SDRamAddr(24 downto 22);
	 SDRamAddr(21 downto 0) <= SDRamAddr(21 downto 0) + 1;

-- modulo charge page size for charge data
elsif DQM = '0' and SDWRDL /= 1 
	and SDWrtReq = '0' and (SDRamAddr >= ChargeBaseAd)
then SDRamAddr(24 downto 23) <= SDRamAddr(24 downto 23);
	 SDRamAddr(22 downto 0) <= SDRamAddr(22 downto 0) + 1;

-- Set starting address with uC writes
elsif SDWRDL = 1 and (CA = SDRamRdPtrHiAd)
then SDRamAddr <= CD(8 downto 0) & SDRamAddr(15 downto 0);
elsif SDWRDL = 1 and (CA = SDRamRdPtrLoAd)
then SDRamAddr <= SDRamAddr(24 downto 16) & CD(15 downto 3) & "000";

-- Set starting address for Phonon A reads
elsif  SDWRDL = 1 and (CA = PhAADCDatHiAddr)
then SDRamAddr <= "000" & CD(5 downto 0) & SDRamAddr(15 downto 0);
elsif  SDWRDL = 1 and (CA = PhAADCDatLoAddr)
then SDRamAddr <= SDRamAddr(24 downto 16) & CD(15 downto 3) & "000";
-- Set starting address for Phonon B reads
elsif  SDWRDL = 1 and (CA = PhBADCDatHiAddr)
then SDRamAddr <= "001" & CD(5 downto 0) & SDRamAddr(15 downto 0);
elsif  SDWRDL = 1 and (CA = PhBADCDatLoAddr)
then SDRamAddr <= SDRamAddr(24 downto 16) & CD(15 downto 3) & "000";
-- Set starting address for Phonon C reads
elsif  SDWRDL = 1 and (CA = PhCADCDatHiAddr)
then SDRamAddr <= "010" & CD(5 downto 0) & SDRamAddr(15 downto 0);
elsif  SDWRDL = 1 and (CA = PhCADCDatLoAddr)
then SDRamAddr <= SDRamAddr(24 downto 16) & CD(15 downto 3) & "000";
-- Set starting address for Phonon D reads
elsif  SDWRDL = 1 and (CA = PhDADCDatHiAddr)
then SDRamAddr <= "011" & CD(5 downto 0) & SDRamAddr(15 downto 0);
elsif  SDWRDL = 1 and (CA = PhDADCDatLoAddr)
then SDRamAddr <= SDRamAddr(24 downto 16) & CD(15 downto 3) & "000";

-- Set starting address for Charge inner reads
elsif  SDWRDL = 1 and (CA = QIADCDatHiAddr)
then SDRamAddr <= "10" & CD(5 downto 0) & SDRamAddr(16 downto 0);
elsif  SDWRDL = 1 and (CA = QIADCDatLoAddr)
then SDRamAddr <= SDRamAddr(24 downto 17) & CD(15 downto 2) & "000";
-- Set starting address for Charge outer reads
elsif  SDWRDL = 1 and (CA = QOADCDatHiAddr)
then SDRamAddr <= "11" & CD(5 downto 0) & SDRamAddr(16 downto 0);
elsif  SDWRDL = 1 and (CA = QOADCDatLoAddr)
then SDRamAddr <= SDRamAddr(24 downto 17) & CD(15 downto 2) & "000";

else SDRamAddr <= SDRamAddr;
end if;

-- SDRAM write address for phonon data
if (AcqState = WrtPhononD) and SDWrtReq = '1' and DQM = '0'
then PhononPtr <= PhononPtr + 1;
-- Reset the pointers when a trigger occurs
elsif SDWrtEn = '0' or (Sweep_Req = '1' and SetUpSyncDL = 1)
then PhononPtr <= "00" & X"00000";
else PhononPtr <= PhononPtr;
end if;

-- diagnostic read of phonon pointer
if SDRDDL = 1 and (CA = SDRamWrtPtrHiAd)
then SDRamWrtAddrReg <= PhononPtr;
else SDRamWrtAddrReg <= SDRamWrtAddrReg;
end if;

-- SDRAM write address for charge data
if ((AcqState = WrtChargeO0) or (AcqState = WrtChargeO1)) 
							and SDWrtReq = '1' and DQM = '0'
then ChargePtr <= ChargePtr + 1;
elsif SDWrtEn = '0' or (Sweep_Req = '1' and SetUpSyncDL = 1)
then ChargePtr <= "000" & X"00000";
else ChargePtr <= ChargePtr;
end if;

-- Machine with States
--  (Nop,Active,WaittCrd,Read,Write,Wait0,Wait1,WaitPrecharge0,WaitPrecharge1,
--   Refresh,RefreshWait0,RefreshWait1,RefreshWait2,Precharge,InitWait0,InitRefresh0,
--   InitWait1,InitWait2,InitWait3,InitRefresh1,InitWait4,InitWait5,InitWait6,Load_Mode);

	Case RAMState is
	   When Nop =>	
		         if InitReq = '1' and RefreshReq = '0' then RAMState <= Precharge;
		    	elsif InitReq = '0' and RefreshReq = '1' then RAMState <= Refresh;
		    	elsif InitReq = '0' and RefreshReq = '0'
					  and ((SDReadReq = '1' and Out_Queuewords <= X"C0") or SDWrtReq = '1') then RAMState <= Active;
		    	else RAMState <= Nop;
		      end if;
-- Burst Read/Write sequence
	   	When Active => RAMState <= WaittCrd;
-- For arbitration purposes, writes take precedent over reads
		When WaittCrd =>
		if SDWrtReq = '1' then RAMState <= SDWrite;
			   			  else RAMState <= SDRead;
							  end if;
		When SDWrite => RAMState <= Wait0;
		When SDRead  => RAMState <= Wait0;
		When Wait0 => if SDWrtEn = '0' then RAMState <= Nop;
		          else RAMState <= Wait1;
					 end if;
		When Wait1 => 
						if BrstCnt = 0 then RAMState <= WaitPrecharge0;
					   else RAMState <= Wait1;
					  end if;
		When WaitPrecharge0 => RAMState <= WaitPrecharge1; 
		When WaitPrecharge1 => RAMState <= Nop; 
-- Refresh sequence
		When Refresh => RAMState <= RefreshWait0;	
		When RefreshWait0 => RAMState <= RefreshWait1;
		When RefreshWait1 => 
			RAMState <= RefreshWait2;
		When RefreshWait2 => RAMState <= Nop;
-- Init Sequence
		When Precharge => RAMState <= InitWait0;
		When InitWait0 => RAMState <= InitRefresh0;
		When InitRefresh0 => RAMState <= InitWait1;
		When InitWait1 => RAMState <= InitWait2;
		When InitWait2 => RAMState <= InitWait3;
		When InitWait3 => RAMState <= InitRefresh1;
		When InitRefresh1 => RAMState <= InitWait4;
		When InitWait4 => RAMState <= InitWait5;
		When InitWait5 => RAMState <= InitWait6;
		When InitWait6 => RAMState <= Load_Mode;
		When Load_Mode => RAMState <= Nop;
	end Case;

-- Define SDRAM control lines in table form to match data sheet 
Case RAMState is 
when Nop 		=> SDCS <= '1'; RAS <= '1'; CAS <= '1'; WE <= '1'; --Tst(5 downto 1) <= "00001";
when Active 	=> SDCS <= '0'; RAS <= '0'; CAS <= '1'; WE <= '1'; --Tst(5 downto 1) <= "00010";
when SDRead		=> SDCS <= '0'; RAS <= '1'; CAS <= '0'; WE <= '1'; --Tst(5 downto 1) <= "00011";
when SDWrite	=> SDCS <= '0'; RAS <= '1'; CAS <= '0'; WE <= '0'; --Tst(5 downto 1) <= "00100";
when Precharge	=> SDCS <= '0'; RAS <= '0'; CAS <= '1'; WE <= '0';	--Tst(5 downto 1) <= "00101";
when Load_Mode	=> SDCS <= '0'; RAS <= '0'; CAS <= '0'; WE <= '0';	--Tst(5 downto 1) <= "00110";
when Refresh	=> SDCS <= '0'; RAS <= '0'; CAS <= '0'; WE <= '1'; --	Tst(5 downto 1) <= "00111"; 
-- Other states used during initialization 
-- Refresh is required twice during initialize and once every 8us thereafter
when InitRefresh0 => SDCS <= '0'; RAS <= '0'; CAS <= '0' ;WE <= '1';	--Tst(5 downto 1) <= "01000";
when InitRefresh1 => SDCS <= '0'; RAS <= '0'; CAS <= '0' ;WE <= '1';	--Tst(5 downto 1) <= "01001";
when WaittCrd	   => SDCS <= '1'; RAS <= '1'; CAS <= '1' ;WE <= '1'; --Tst(5 downto 1) <= "01010";
when Wait0 		   => SDCS <= '1'; RAS <= '1'; CAS <= '1' ;WE <= '1';	--Tst(5 downto 1) <= "01011";
when Wait1		   => SDCS <= '1'; RAS <= '1'; CAS <= '1' ;WE <= '1';	--Tst(5 downto 1) <= "01100";
when WaitPrecharge0	=> SDCS <= '1'; RAS <= '1'; CAS <= '1' ;WE <= '1';	--Tst(5 downto 1) <= "01101";
when WaitPrecharge1 => SDCS <= '1'; RAS <= '1'; CAS <= '1' ;WE <= '1'; --Tst(5 downto 1) <= "01110";
when InitWait0	=> SDCS <= '1'; RAS <= '1'; CAS <= '1' ;WE <= '1';	--Tst(5 downto 1) <= "01111";
when InitWait1	=> SDCS <= '1'; RAS <= '1'; CAS <= '1' ;WE <= '1';	--Tst(5 downto 1) <= "10000";
when InitWait2	=> SDCS <= '1'; RAS <= '1'; CAS <= '1' ;WE <= '1';	--Tst(5 downto 1) <= "10001";
when InitWait3	=> SDCS <= '1'; RAS <= '1'; CAS <= '1' ;WE <= '1';	--Tst(5 downto 1) <= "10010";
when InitWait4	=> SDCS <= '1'; RAS <= '1'; CAS <= '1' ;WE <= '1';	--Tst(5 downto 1) <= "10011";
when InitWait5	=> SDCS <= '1'; RAS <= '1'; CAS <= '1' ;WE <= '1';	--Tst(5 downto 1) <= "10100";
when InitWait6	=> SDCS <= '1'; RAS <= '1'; CAS <= '1' ;WE <= '1';	--Tst(5 downto 1) <= "10101";
when RefreshWait0 => SDCS <= '1'; RAS <= '1'; CAS <= '1' ;WE <= '1';	--Tst(5 downto 1) <= "10110";
when RefreshWait1 => SDCS <= '1'; RAS <= '1'; CAS <= '1' ;WE <= '1';	--Tst(5 downto 1) <= "10111";
when RefreshWait2 => SDCS <= '1'; RAS <= '1'; CAS <= '1' ;WE <= '1'; --Tst(5 downto 1) <= "11000";
end case;

-- Address bit 24 (BA1) distinguishes between charge and phonon data
-- Bit 23 (BA0) distinguishes between Q inner and Q outer data
-- Bits 23,22 (BA0,A12) distinguish betweeen phonon A,B,C,D
if SDWrtReq = '0' then BA <= SDRamAddr(24 downto 23);
elsif SDWrtReq = '1' and ((AcqState = WrtPhononA) or (AcqState = WrtPhononB))
then BA <= "00";
elsif SDWrtReq = '1' and ((AcqState = WrtPhononC) or (AcqState = WrtPhononD))
then BA <= "01";
elsif SDWrtReq = '1' and ((AcqState = WrtChargeI0) or (AcqState = WrtChargeI1))
then BA <= "10";
elsif SDWrtReq = '1' and ((AcqState = WrtChargeO0) or (AcqState = WrtChargeO1))
then BA <= "11";
else BA <= BA;
end if;

-- The address lines are multiplexed
-- Send the upper order address bits during RAS
if (RAMState = Active) 
 then
	if SDWrtReq = '0' then A <= SDRamAddr(22 downto 10);
	 elsif SDWrtReq = '1' and (AcqState = WrtPhononA) 
	then A <= "0" & PhononPtr(21 downto 10);
	 elsif SDWrtReq = '1' and (AcqState = WrtPhononB) 
	then A <= "1" & PhononPtr(21 downto 10);
	 elsif SDWrtReq = '1' and (AcqState = WrtPhononC) 
	then A <= "0" & PhononPtr(21 downto 10);
	 elsif SDWrtReq = '1' and (AcqState = WrtPhononD) 
	then A <= "1" & PhononPtr(21 downto 10);
	 elsif SDWrtReq = '1' and (AcqState = WrtChargeI0) 
	then A <= ChargePtr(22 downto 10);
	 elsif SDWrtReq = '1' and (AcqState = WrtChargeI1) 
	then A <= ChargePtr(22 downto 10);
	 elsif SDWrtReq = '1' and (AcqState = WrtChargeO0) 
	then A <= ChargePtr(22 downto 10);
	 elsif SDWrtReq = '1' and (AcqState = WrtChargeO1) 
	then A <= ChargePtr(22 downto 10);
   end if; -- SDWrtReq = '0'
-- Send lower order address bits during CAS. Set bit 10 for Auto Precharge 
elsif (RAMState = SDRead) or (RAMState = SDWrite)
 then
  if SDWrtReq = '0' then A <= "001" & SDRamAddr(9 downto 0);
	 elsif SDWrtReq = '1' and (AcqState = WrtPhononA) 
	then  A <= "001" & PhononPtr(9 downto 0);
	 elsif SDWrtReq = '1' and (AcqState = WrtPhononB) 
	then  A <= "001" & PhononPtr(9 downto 0);
	 elsif SDWrtReq = '1' and (AcqState = WrtPhononC) 
	then  A <= "001" & PhononPtr(9 downto 0);
	 elsif SDWrtReq = '1' and (AcqState = WrtPhononD) 
	then  A <= "001" & PhononPtr(9 downto 0);
	 elsif SDWrtReq = '1' and (AcqState = WrtChargeI0) 
	then  A <= "001" & ChargePtr(9 downto 0);
	 elsif SDWrtReq = '1' and (AcqState = WrtChargeI1) 
	then  A <= "001" & ChargePtr(9 downto 0);
	 elsif SDWrtReq = '1' and (AcqState = WrtChargeO0) 
	then  A <= "001" & ChargePtr(9 downto 0);
	 elsif SDWrtReq = '1' and (AcqState = WrtChargeO1) 
	then  A <= "001" & ChargePtr(9 downto 0);
  end if;
-- Set Address bit 10 high for global precharge 
elsif (RAMState = Precharge)
	then A <= "0010000000000";
-- This word is sent once during initialization
-- Mode - burst access, CAS latency: 2, Burst: Sequential, Burst Length: 8 
elsif (RAMState = Load_Mode) 
	then A <= "0000000100011";
else A <= A;
end if;

-- Counter for counting down SDRAM burst read and write cycles
   if RAMState = Wait0 then BrstCnt <= "111";
elsif RAMState = Wait1 and BrstCnt /= 0 then BrstCnt <= BrstCnt - 1;
else BrstCnt <= BrstCnt;
end if;

-- Read/Write bus enable
if DQM = '1' and (RAMState = SDWrite or RAMState = SDRead)
then DQM <= '0';
elsif DQM = '0' and BrstCnt = 1
then DQM <= '1';
else DQM <= DQM;
end if;

-- Machine with States(AcqIdle,WrtPhononA,WrtPhononB,WrtPhononC,WrtPhononD,
--					       WrtChargeI0, WrtChargeI1, WrtChargeO0, WrtChargeO1,AcqDone)
	Case AcqState is
		when AcqIdle =>
		 if SDWrtEn = '1' and RAMState = Nop then AcqState <= WrtPhononA;
		  else AcqState <= AcqIdle;
		 end if;
		when WrtPhononA =>
		 if SDWrtReq = '1' and RAMState = Wait1 and BrstCnt = 0 
			then AcqState <= WrtPhononB;
		  elsif SDWrtEn = '0' then AcqState <= AcqIdle;
		  else AcqState <= WrtPhononA;
		 end if;
		when WrtPhononB =>
		 if SDWrtReq = '1' and RAMState = Wait1 and BrstCnt = 0
			then AcqState <= WrtPhononC;
		  elsif SDWrtEn = '0' then AcqState <= AcqIdle;
		  else AcqState <= WrtPhononB;
		 end if;
		when WrtPhononC =>
		 if SDWrtReq = '1' and RAMState = Wait1 and BrstCnt = 0 
			then AcqState <= WrtPhononD;
		  elsif SDWrtEn = '0' then AcqState <= AcqIdle;
		  else AcqState <= WrtPhononC;
		 end if;
		when WrtPhononD =>
		 if PhRepeat = '0' and SDWrtReq = '1' and RAMState = Wait1 and BrstCnt = 0
			then AcqState <= WrtChargeI0;
		 elsif SDWrtEn = '0' then AcqState <= AcqIdle;
		 elsif PhRepeat = '1' and SDWrtReq = '1' and RAMState = Wait1 and BrstCnt = 0 
			then AcqState <= AcqIdle;
		else AcqState <= WrtPhononD;
		 end if;
		when WrtChargeI0 =>
		 if SDWrtReq = '1' and RAMState = Wait1 and BrstCnt = 0
			then AcqState <= WrtChargeO0;
		  elsif SDWrtEn = '0' then AcqState <= AcqIdle;
		  else AcqState <= WrtChargeI0;
		 end if;
		when WrtChargeO0 =>
		 if SDWrtReq = '1' and RAMState = Wait1 and BrstCnt = 0 
			then AcqState <= WrtChargeI1;
		 elsif SDWrtEn = '0' then AcqState <= AcqIdle;
	    else AcqState <= WrtChargeO0;
		 end if;
		when WrtChargeI1 =>
		 if SDWrtReq = '1' and RAMState = Wait1 and BrstCnt = 0
			then AcqState <= WrtChargeO1;
		  elsif SDWrtEn = '0' then AcqState <= AcqIdle;
		  else AcqState <= WrtChargeI1;
		 end if;
		when WrtChargeO1 =>
		 if SDWrtReq = '1' and RAMState = Wait1 and BrstCnt = 0
			then AcqState <= AcqDone;
		  elsif SDWrtEn = '0' then AcqState <= AcqIdle;
		  else AcqState <= WrtChargeO1;
		 end if;
		when AcqDone => AcqState <= AcqIdle;
		when Others => AcqState <= AcqIdle;
	end case;

end if; -- rising_edge (SDClk) 

end process SDRAMCtrl;

------------------- conbinatorial SDRAM processes -------------------------
-- SDRAM data source
with AcqState select
 iD <= Phonon_Queue(0) when WrtPhononA,
       Phonon_Queue(1) when WrtPhononB,
	    Phonon_Queue(2) when WrtPhononC,
	    Phonon_Queue(3) when WrtPhononD,
	    Charge_Queue(0) when WrtChargeI0,
	    Charge_Queue(0) when WrtChargeI1,
	    Charge_Queue(1) when WrtChargeO0,
	    Charge_Queue(1) when others;

D <= iD when SDWrtReq = '1' and DQM = '0' else (others => 'Z');

------------------- mux for reading back registers -------------------------

-- Put this option in for the difference between Stellaris and TMS740 byte ordering
Out_QueueDat(7 downto 0) <= Out_QueueOut(15 downto 8) when ByteSwap = SwapVal else Out_QueueOut(7 downto 0);
Out_QueueDat(15 downto 8) <= Out_QueueOut(7 downto 0) when ByteSwap = SwapVal else Out_QueueOut(15 downto 8);

 with CA Select

iCD <= "000" & TstSigTrigEn & PhiWrt_En & CPLDFifo_Full & CPLDFifo_Empty & TrigFIFO_Full & TrigFIFO_Empty 
				    & AvgEn & SysWrtEn & Mode & "0" & "0" & LVDir when CSRAddr,
	 "000" & X"0" & SDRamAddr(24 downto 16) when SDRamRdPtrHiAd,
	 				SDRamAddr(15 downto 0) when SDRamRdPtrLoAd,
		X"00" & "00" & SDRamWrtAddrReg(21 downto 16) when SDRamWrtPtrHiAd,
					SDRamWrtAddrReg(15 downto 0) when  SDRamWrtPtrLoAd,
				   Out_QueueDat when SDRamPort,
			 "00" & Trig_Out(27 downto 22) & "00" & Trig_Out(21 downto 16) when TrigFifoHiAddr,
					Trig_Out(15 downto 0) when TrigFifoLoAddr,
					TestCounter(31 downto 16) when TestCounterHiAd,
					TestCounter(15 downto 0) when TestCounterLoAd,
	  X"00" & "0" & AverageIntReg when AverageIntAddr,
			X"00" & "00" & TrigParm when TrigParmAddr,
		 "0" & QBaselength & "0" & PhBaselength when BaseLengthAddr,
             "000" & QSigSmplLngth & "000" & PhSigSmplLngth when TrgSmplLngthAddr,
	PhTrigThresh(0)(13) & PhTrigThresh(0)(13) & PhTrigThresh(0) when PhAThreshAddr,
	PhTrigThresh(1)(13) & PhTrigThresh(1)(13) & PhTrigThresh(1) when PhBThreshAddr,
	PhTrigThresh(2)(13) & PhTrigThresh(2)(13) & PhTrigThresh(2) when PhCThreshAddr,
	PhTrigThresh(3)(13) & PhTrigThresh(3)(13) & PhTrigThresh(3) when PhDThreshAddr,
	QTrigThresh(0)  when QIThreshAddr,
	QTrigThresh(1)  when QOThreshAddr,
	CntStage when PhTrigCnt0Addr,
	CntStage when PhTrigCnt1Addr,
	CntStage when PhTrigCnt2Addr,
	CntStage when PhTrigCnt3Addr,
	CntStage when QTrigCnt0Addr,
	CntStage when QTrigCnt1Addr,
--	X"00" & PS_Phase when PS_PhaseRegAd,
	X"0" & "00" & LEDPlsWidthReg  when LEDPlsWidthAddr,
					LEDPlsRateReg   when LEDPlsRateAddr,
	X"0" & CpldRd_Dat(11) & "0" & CpldRd_Dat(9) & CpldRd_Dat(8) & "000" 
		  & CpldRd_Dat(4) & "00" & CpldRd_Dat(1 downto 0) when LEDPlsCtrlBits,
		 CpldRd_Dat when PhGainsDACCtrl,
	X"00" & TrigFIFO_Full & TrigFIFOCount when TrigFIFOCountAddr,
   X"0" & CpldRd_Dat(11 downto 0) when PhGainsDACAddr0,
	X"0" & CpldRd_Dat(11 downto 0) when PhGainsDACAddr1,
	X"0" & CpldRd_Dat(11 downto 0) when PhGainsDACAddr2,
	X"0" & CpldRd_Dat(11 downto 0) when PhGainsDACAddr3,
	X"0" & CpldRd_Dat(11 downto 0) when PhGainsDACAddr4,
	X"0" & CpldRd_Dat(11 downto 0) when PhGainsDACAddr5,
	X"0" & CpldRd_Dat(11 downto 0) when PhGainsDACAddr6,
	X"0" & CpldRd_Dat(11 downto 0) when PhGainsDACAddr7,
	"00" & (Sweep_Req or Sweep_En) & CpldRd_Dat(12) & "000" & CpldRd_Dat(8) 
	& "000"  & CpldRd_Dat(4) & "000" & CpldRd_Dat(0) when TstPlsCtrlAd,
	CpldRd_Dat when DDSAddr0,
	X"0" & No_of_Steps when DDSAddr1,
	X"0" & DeltaF(11 downto 0) when DDSAddr2,
	X"0" & DeltaF(23 downto 12) when DDSAddr3,
	"00" & Step_interval when DDSAddr4,
	X"0" & StartFreq(11 downto 0) when DDSAddr5,
	X"0" & StartFreq(23 downto 12) when DDSAddr6,
	X"0" & CpldRd_Dat(11 downto 0) when TstPlsMagAddr,
	CpldRd_Dat when PhA_BCtlrAddr,
	CpldRd_Dat when PhA_BDacCtrl,
	CpldRd_Dat when PhA_BDacAddr0,
	CpldRd_Dat when PhA_BDacAddr1,
	CpldRd_Dat when PhA_BDacAddr2,
	CpldRd_Dat when PhA_BDacAddr3,
	CpldRd_Dat when PhA_BDacAddr4,
	CpldRd_Dat when PhA_BDacAddr5,
	CpldRd_Dat when PhA_BDacAddr6,
	CpldRd_Dat when PhA_BDacAddr7,
	CpldRd_Dat when PhC_DCtlrAddr,
	CpldRd_Dat when PhC_DDacCtrl,
	CpldRd_Dat when PhC_DDacAddr0,
	CpldRd_Dat when PhC_DDacAddr1,
	CpldRd_Dat when PhC_DDacAddr2,
	CpldRd_Dat when PhC_DDacAddr3,
	CpldRd_Dat when PhC_DDacAddr4,
	CpldRd_Dat when PhC_DDacAddr5,
	CpldRd_Dat when PhC_DDacAddr6,
	CpldRd_Dat when PhC_DDacAddr7,
	CpldRd_Dat when QBiasDACAddr0,
	CpldRd_Dat when QBiasDACAddr1,
	X"000" & ByteSwap & InitFlag & CR_Flag & NullFlag when LinkISR,
	 DSChnTx1Buff_empty & DSChnTx0Buff_empty & DSChnRx1Buff_full & DSChnRx0Buff_full
  & DSChnRx1Buff_empty & DSChnRx0Buff_empty & BusRx0Buff_empty 
  & "00" & FMTxEn & DsChnRx0_active & (LVDir or not DsChnRx0_active)
  & DSChnRx1ParityErr & DSChnRx0ParityErr & BusRx1ParityErr & BusRx0ParityErr 
  when LinkCSR,
	X"00" & DSChnRx0BuffOut when DSChnRx0Addr,
	DSChnRx1BuffOut when DSChnRx1Addr,
	X"00" & BusRx0BuffOut when BusRx0Addr,
	ADC_Stage(0) when ADCTstRdAddr0,
	ADC_Stage(1) when ADCTstRdAddr1,
	X"0000" when others;

CD <= iCD when CpldCS = '0' and Rd = '0' else (others => 'Z');

end behavioural;
