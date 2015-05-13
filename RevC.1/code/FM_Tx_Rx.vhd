----------------------- FM Serializer  ------------------------

LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.Global_Defs.all;

entity Serial_Tx is
	generic (size : positive);
	port(clock, reset, Tx_En : in std_logic;
		 pdata_in : in std_logic_vector(size-1 downto 0 );
		 Tx_Done,FMData_Out : buffer std_logic);
--		 FMData_Out : buffer std_logic);
end Serial_Tx;

architecture behavioural of Serial_Tx is

-- Serializer state machine
Type FMTx is (TxIdle,TxStrtA,TxStrtB,ShftTx,ParityTx);
signal Tx_State : FMTx;

-- Shift register, bit width counter
signal TxShft : std_logic_vector (size-1 downto 0);
signal TxBitWdth : std_logic_vector (2 downto 0);
-- Transmitted FM data, running parity bit
signal TxParity,In_Present,Align,Tx_Req : std_logic;

begin

FM_Encode : process(clock, reset)
-- Frame bit counter
variable TxBtCnt : integer range 0 to size-1;

begin
 if reset = '0' then 

	Tx_State <= TxIdle; FMData_Out <= '0';
	Tx_Done <= '0'; TxParity <= '0';
	TxShft <= (others => '0');
	TxBitWdth <= "000"; TxBtCnt := 0;

elsif rising_edge(clock) then

   Case TxBitWdth is
	When "000" => TxBitWdth <= "001";
	When "001" => TxBitWdth <= "010";
	When "010" => TxBitWdth <= "011";
	When "011" => if Tx_State = TxStrtA or Tx_State = TxStrtB
			  then TxBitWdth <= "100";
			  else TxBitWdth <= "000";
			  end if;
	When "100" => if Tx_State = TxStrtA or Tx_State = TxStrtB
			  then TxBitWdth <= "101";
			  else TxBitWdth <= "000";
			  end if;
	When others => TxBitWdth <= "000";
  end Case;

-- FMTx TxIdle,TxStrtA,TxStrtB,ShftTx,ParityTx
Case Tx_State is
-- Send data on uC write
        When TxIdle => 
	 	 if Tx_En = '1' and TxBitWdth = "011"
		  then Tx_State <= TxStrtA;
			else Tx_State <= TxIdle;
			end if;
		When TxStrtA =>
		 if TxBitWdth = "101" then Tx_State <= TxStrtB;
		  else Tx_State <= TxStrtA;
		 end if;
 		When TxStrtB =>
		 if TxBitWdth = "101" then Tx_State <= ShftTx;
		  else Tx_State <= TxStrtB;
		 end if;
          When ShftTx =>
         if TxBitWdth = "011" and TxBtCnt = 0 then Tx_State <= ParityTx;
         else Tx_State <= ShftTx;
         end if;
           When ParityTx =>
         if TxBitWdth = "011" then Tx_State <= TxIdle;
         else Tx_State <= ParityTx;
         end if;
end case;

-- Two transitions per bit period is a 1, one transition denotes a 0
 -- default state is a string of 1's
if ((TxBitWdth = "001" or TxBitWdth = "011") and Tx_State = TxIdle)
		  or TxBitWdth = "101" 	-- Start bit is defined 1 1/2 bit periods
					-- Number of data FM transitions is ShiftOut register data dependent
          or (Tx_State = ShftTx and ((TxShft(size-1) = '1' and TxBitWdth = "001") or TxBitWdth = "011"))
					-- Number of parity FM transitions is parity bit dependent
          or (Tx_State = ParityTx and ((TxParity = '0' and TxBitWdth = "001") or TxBitWdth = "011"))
then FMData_Out <= not FMData_Out;
else FMData_Out <= FMData_Out;
end if;

-- data frames are "size" bits long 
if Tx_State = TxStrtB and TxBitWdth = "101"
  then TxBtCnt := (size-1);
elsif Tx_State = TxIdle then TxBtCnt := 0;
elsif Tx_State = ShftTx and TxBitWdth = "011" and TxBtCnt /= 0
	then TxBtCnt := TxBtCnt-1;
else TxBtCnt := TxBtCnt;
end if;
-- Load shift register with data byte at the beginning of the transmit sequence
-- load condition
if Tx_State = TxIdle and Tx_En = '1' and TxBitWdth = "011"
  then TxShft <= pdata_in;
-- Shift one bit left (MSB first) during data portion of frame
-- shift condition
elsif Tx_State = ShftTx and TxBitWdth = "011" 
	then TxShft <= (TxShft(size-2 downto 0) & '0');
else TxShft <= TxShft;
end if;

  if (TxParity = '1' and Tx_State = TxIdle) -- reset parity at start
  or (Tx_State = ShftTx and TxBitWdth = "011" and TxShft(size-1) = '0')
-- Toggle parity bit with each shifted out "0"
then TxParity <= not TxParity;
else TxParity <= TxParity;
end if;

-- Indicate when a frame has been shifted out
if TxBitWdth = "011" and Tx_State = ParityTx then Tx_Done <= '1';
else Tx_Done <= '0';
end if;

end if; -- reset

end process FM_Encode;

end behavioural; -- of Serial_Tx

------------------------------ FM Deserializer ----------------------------

LIBRARY ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
USE work.Global_Defs.all;

entity Serial_Rx is
	generic (size : positive);
	port( sysclk, rxclock, reset, FMData_In, Clr_Err : in std_logic;
	pdata_out : buffer std_logic_vector(size-1 downto 0 );
	Rx_Done : buffer std_logic;
	Parity_Err : buffer std_logic);
end Serial_Rx;

architecture behavioural of Serial_Rx is

Type FMRx is (RxIdle,RxStrt,RxShift,ParityRx);
Signal Rx_State : FMRx;
-- Registers for FM decoder
-- Shift register, bit width counter
signal RxBitWdth : std_logic_vector (3 downto 0);
-- Edge detector for incoming FM data
signal RxDl : std_logic_vector (1 downto 0);
-- Transmitted FM data, running parity bit
signal RxParity,Rx_NRZ,Rx_Done_Req : std_logic;

begin

FM_Decode : process(rxclock, reset)

-- Frame bit counter
variable RxBtCnt : integer range 0 to size-1;

begin
 if reset = '0' then 

	Rx_State <= RxIdle; RxDl <= "00"; 
	Rx_Done_Req <= '0'; RxParity <= '0'; Parity_Err <= '0';
	pdata_out <= (others => '0'); RxBtCnt := 0; 
	Rx_NRZ <= '0'; RxBitWdth <= "0000";

elsif rising_edge(rxclock) then

-- Synchronous edge detector for input
RxDl(0) <= FMData_In;
RxDl(1) <= RxDl(0);

-- Reset sampling counter with every Clock transition while decoder is in Idle,
-- otherwise reset only once per bit period
if (RxDl(1) = '1' xor RxDl(0) = '1') and (RxBitWdth > "0100" or Rx_State = RxIdle)
  then RxBitWdth <= "0000";
elsif RxBitWdth /= "1111" and 
	not((RxDl(1) = '1' xor RxDl(0) = '1') and (RxBitWdth > "0100" or Rx_State = RxIdle))
  then RxBitWdth <= RxBitWdth + 1;
else RxBitWdth <= RxBitWdth;
end if;

-- RxIdle,RxStrt,RxShift,ParityRx 
Case Rx_State is
    When RxIdle =>
      if RxBitWdth = "1000" then Rx_State <= RxStrt;
       else Rx_State <= RxIdle;
      end if;
    When RxStrt =>
     if RxBitWdth = "1000" then Rx_State <= RxShift;
	  elsif ((RxDl(1) = '1' xor RxDl(0) = '1') and RxBitWdth < "1000")
		  or RxBitWdth = "1111" then Rx_State <= RxIdle;
      else Rx_State <= RxStrt;
     end if;
    When RxShift =>
      if RxBtCnt = 0 and RxBitWdth = "0110" then Rx_State <= ParityRx;
	   elsif RxBitWdth = "1111" then Rx_State <= RxIdle;
      else Rx_State <= RxShift;
      end if;
     When ParityRx =>
      if RxBitWdth = "0110" or RxBitWdth = "1111"
		then Rx_State <= RxIdle;
     else Rx_State <= ParityRx;
      end if;
end case;

-- Serial data from FM is 1 if transition is in the middle of the bit period,
-- 0 if it is at the end 
if Rx_NRZ = '1' and (RxDl(1) = '1' xor RxDl(0) = '1') and RxBitWdth > "0100"
then Rx_NRZ <= '0';
elsif  Rx_NRZ = '0' and (RxDl(1) = '1' xor RxDl(0) = '1') and RxBitWdth <= "0100"
then Rx_NRZ <= '1';
else Rx_NRZ <= Rx_NRZ;
end if;

-- Serial data frame is "size" bits long
   if Rx_State = RxStrt and RxBitWdth = "1000" then RxBtCnt := (size-1);
elsif Rx_State = RxIdle then RxBtCnt := 0;
elsif Rx_State = RxShift and RxBitWdth = "0110" and RxBtCnt /= 0 
then RxBtCnt := RxBtCnt - 1;
else RxBtCnt := RxBtCnt;
end if;

-- Shift register
if Rx_State = RxShift and RxBitWdth = "0110"  
then pdata_out <= (pdata_out(size-2 downto 0) & Rx_NRZ);
else pdata_out <= pdata_out;
end if;

-- Parity bit toggles for each zero bit 
if  (Rx_State = RxShift and RxBitWdth = "0110" and Rx_NRZ = '0')
 or (RxParity = '1' and Rx_State = RxStrt)
then RxParity <= not RxParity;
else RxParity <= RxParity;
end if;

-- If transmitted parity doesn't match the running parity, parity error 
if (Parity_Err = '1' and Clr_Err = '1')
or (Parity_Err = '0' and (Rx_NRZ = '1' xor RxParity = '0') and Rx_State = ParityRx
                 and (RxDl(1) = '1' xor RxDl(0) = '1') and RxBitWdth = "0110")
then Parity_Err <= not Parity_Err;
else Parity_Err <= Parity_Err;
end if;

-- Hold Rx done high for one sysclck period.
if Rx_State = ParityRx and RxBitWdth = "0110" then Rx_Done_Req <= '1';
elsif Rx_Done = '1' then Rx_Done_Req <= '0';
else Rx_Done_Req <= Rx_Done_Req;
end if;

end if; -- rising edge

end process FM_Decode;

-- SendRxDone for one sysclk period
Send_Rx_Done : process(sysclk, reset)
begin
if reset = '0' then Rx_Done <= '0';
 elsif rising_edge(sysclk) then Rx_Done <= Rx_Done_Req;
end if; -- reset
end process Send_Rx_Done;
end behavioural; -- of Serial_Rx
