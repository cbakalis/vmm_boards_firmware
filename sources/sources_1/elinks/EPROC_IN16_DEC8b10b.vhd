----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    07/24/2014
--! Module Name:    EPROC_IN16_DEC8b10b
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee, work;
use ieee.std_logic_1164.all;
use work.all;
use work.centralRouter_package.all;

--! 8b10b decoder for EPROC_IN16 module
entity EPROC_IN16_DEC8b10b is
port (  
    bitCLK      : in  std_logic;
    bitCLKx2    : in  std_logic;
    bitCLKx4    : in  std_logic;
    rst         : in  std_logic;
    edataIN     : in  std_logic_vector (15 downto 0);
    dataOUT     : out std_logic_vector(9 downto 0);
    dataOUTrdy  : out std_logic
    );
end EPROC_IN16_DEC8b10b;

architecture Behavioral of EPROC_IN16_DEC8b10b is

----------------------------------
----------------------------------
component KcharTest is
port ( 
	clk            : in  std_logic;
	encoded10in    : in  std_logic_vector (9 downto 0);
	KcharCode      : out std_logic_vector (1 downto 0)
	);
end component KcharTest;
----------------------------------
----------------------------------

signal EDATAbitstreamSREG : std_logic_vector (95 downto 0) := (others=>'0'); -- 96 bit (16 x 5 = 80, plus 16 more)
signal word10bx8_align_array, word10bx8_align_array_r, word10bx8_align_array_s1, word10bx8_align_array_s2 : word10b_8array_16array_type;
signal word10b_array, word10b_array_s : word10b_8array_type;
signal isk_array            : isk_8array_type;

signal  comma_valid_bits_or, word10bx8_align_rdy_s1, word10bx8_align_rdy_s2, word10bx8_align_rdy_r, 
        word10b_array_rdy, word10b_array_rdy_s, word10b_array_rdy_s1, realignment_ena : std_logic;
        
signal align_select, align_select_work, align_select_current, align_select_work_s, align_select_work_s1 : std_logic_vector (3 downto 0) := (others=>'0');
signal comma_valid_bits     : std_logic_vector (15 downto 0);
signal alignment_sreg       : std_logic_vector (4 downto 0) := (others=>'0');

begin

-------------------------------------------------------------------------------------------
--live bitstream
-- 96 bit input shift register
-------------------------------------------------------------------------------------------
process(bitCLK, rst)
begin
	if rst = '1' then
        EDATAbitstreamSREG <= (others => '0');
	elsif bitCLK'event and bitCLK = '1' then
        EDATAbitstreamSREG <= edataIN & EDATAbitstreamSREG(95 downto 16);
	end if;
end process;
--

-------------------------------------------------------------------------------------------
--clock0
-- input shift register mapping into 10 bit registers
-------------------------------------------------------------------------------------------
input_map:  for I in 0 to 15 generate -- 8 10bit-words per alignment, 16 possible alignments
word10bx8_align_array(I)(0) <= EDATAbitstreamSREG((I+9)  downto  (I+0));   -- 1st 10 bit word, alligned to bit I
word10bx8_align_array(I)(1) <= EDATAbitstreamSREG((I+19) downto (I+10));   -- 2nd 10 bit word, alligned to bit I
word10bx8_align_array(I)(2) <= EDATAbitstreamSREG((I+29) downto (I+20));   -- 3rd 10 bit word, alligned to bit I
word10bx8_align_array(I)(3) <= EDATAbitstreamSREG((I+39) downto (I+30));   -- 4th 10 bit word, alligned to bit I
word10bx8_align_array(I)(4) <= EDATAbitstreamSREG((I+49) downto (I+40));   -- 5th 10 bit word, alligned to bit I
word10bx8_align_array(I)(5) <= EDATAbitstreamSREG((I+59) downto (I+50));   -- 6th 10 bit word, alligned to bit I
word10bx8_align_array(I)(6) <= EDATAbitstreamSREG((I+69) downto (I+60));   -- 7th 10 bit word, alligned to bit I
word10bx8_align_array(I)(7) <= EDATAbitstreamSREG((I+79) downto (I+70));   -- 8th 10 bit word, alligned to bit I
--word10bx8_align_array(I)(0) <= EDATAbitstreamSREG(I+0)&EDATAbitstreamSREG(I+1)&EDATAbitstreamSREG(I+2)&EDATAbitstreamSREG(I+3)&EDATAbitstreamSREG(I+4)&
--                               EDATAbitstreamSREG(I+5)&EDATAbitstreamSREG(I+6)&EDATAbitstreamSREG(I+7)&EDATAbitstreamSREG(I+8)&EDATAbitstreamSREG(I+9);   -- 1st 10 bit word, alligned to bit I
--word10bx8_align_array(I)(1) <= EDATAbitstreamSREG(I+10)&EDATAbitstreamSREG(I+11)&EDATAbitstreamSREG(I+12)&EDATAbitstreamSREG(I+13)&EDATAbitstreamSREG(I+14)&
--                               EDATAbitstreamSREG(I+15)&EDATAbitstreamSREG(I+16)&EDATAbitstreamSREG(I+17)&EDATAbitstreamSREG(I+18)&EDATAbitstreamSREG(I+19);   -- 2nd 10 bit word, alligned to bit I
--word10bx8_align_array(I)(2) <= EDATAbitstreamSREG(I+20)&EDATAbitstreamSREG(I+21)&EDATAbitstreamSREG(I+22)&EDATAbitstreamSREG(I+23)&EDATAbitstreamSREG(I+24)&
--                               EDATAbitstreamSREG(I+25)&EDATAbitstreamSREG(I+26)&EDATAbitstreamSREG(I+27)&EDATAbitstreamSREG(I+28)&EDATAbitstreamSREG(I+29);   -- 3rd 10 bit word, alligned to bit I
--word10bx8_align_array(I)(3) <= EDATAbitstreamSREG(I+30)&EDATAbitstreamSREG(I+31)&EDATAbitstreamSREG(I+32)&EDATAbitstreamSREG(I+33)&EDATAbitstreamSREG(I+34)&
--                               EDATAbitstreamSREG(I+35)&EDATAbitstreamSREG(I+36)&EDATAbitstreamSREG(I+37)&EDATAbitstreamSREG(I+38)&EDATAbitstreamSREG(I+39);   -- 4th 10 bit word, alligned to bit I
--word10bx8_align_array(I)(4) <= EDATAbitstreamSREG(I+40)&EDATAbitstreamSREG(I+41)&EDATAbitstreamSREG(I+42)&EDATAbitstreamSREG(I+43)&EDATAbitstreamSREG(I+44)&
--                               EDATAbitstreamSREG(I+45)&EDATAbitstreamSREG(I+46)&EDATAbitstreamSREG(I+47)&EDATAbitstreamSREG(I+48)&EDATAbitstreamSREG(I+49);   -- 5th 10 bit word, alligned to bit I
--word10bx8_align_array(I)(5) <= EDATAbitstreamSREG(I+50)&EDATAbitstreamSREG(I+51)&EDATAbitstreamSREG(I+52)&EDATAbitstreamSREG(I+53)&EDATAbitstreamSREG(I+54)&
--                               EDATAbitstreamSREG(I+55)&EDATAbitstreamSREG(I+56)&EDATAbitstreamSREG(I+57)&EDATAbitstreamSREG(I+58)&EDATAbitstreamSREG(I+59);   -- 6th 10 bit word, alligned to bit I
--word10bx8_align_array(I)(6) <= EDATAbitstreamSREG(I+60)&EDATAbitstreamSREG(I+61)&EDATAbitstreamSREG(I+62)&EDATAbitstreamSREG(I+63)&EDATAbitstreamSREG(I+64)&
--                               EDATAbitstreamSREG(I+65)&EDATAbitstreamSREG(I+66)&EDATAbitstreamSREG(I+67)&EDATAbitstreamSREG(I+68)&EDATAbitstreamSREG(I+69);   -- 7th 10 bit word, alligned to bit I
--word10bx8_align_array(I)(7) <= EDATAbitstreamSREG(I+70)&EDATAbitstreamSREG(I+71)&EDATAbitstreamSREG(I+72)&EDATAbitstreamSREG(I+73)&EDATAbitstreamSREG(I+74)&
--                               EDATAbitstreamSREG(I+75)&EDATAbitstreamSREG(I+76)&EDATAbitstreamSREG(I+77)&EDATAbitstreamSREG(I+78)&EDATAbitstreamSREG(I+79);   -- 8th 10 bit word, alligned to bit I
end generate input_map;


-------------------------------------------------------------------------------------------
--clock0
-- K28.5 comma test
-------------------------------------------------------------------------------------------
comma_test:  for I in 0 to 15 generate -- 8 10bit-words per alignment, comma is valid if two first words have comma
comma_valid_bits(I) <=  '1' when ((word10bx8_align_array(I)(0) = COMMAp or word10bx8_align_array(I)(0) = COMMAn) and 
                                  (word10bx8_align_array(I)(1) = COMMAp or word10bx8_align_array(I)(1) = COMMAn)) else '0';
end generate comma_test;
--                      
comma_valid_bits_or <=  comma_valid_bits(15) or comma_valid_bits(14) or comma_valid_bits(13) or comma_valid_bits(12) or 
                        comma_valid_bits(11) or comma_valid_bits(10) or comma_valid_bits(9) or comma_valid_bits(8) or
                        comma_valid_bits(7) or comma_valid_bits(6) or comma_valid_bits(5) or comma_valid_bits(4) or
                        comma_valid_bits(3) or comma_valid_bits(2) or comma_valid_bits(1) or comma_valid_bits(0);
-- 

-------------------------------------------------------------------------------------------
--clock1
-- alignment selector state
-------------------------------------------------------------------------------------------
process(bitCLK, rst)
begin
    if rst = '1' then
        alignment_sreg <= "00000";
    elsif bitCLK'event and bitCLK = '1' then 
		if comma_valid_bits_or = '1' then
            alignment_sreg <= "10000"; 
        else
            alignment_sreg <= alignment_sreg(0) & alignment_sreg(4 downto 1);    
        end if;            
    end if;
end process;
--
input_reg1: process(bitCLK)
begin
    if bitCLK'event and bitCLK = '1' then
        word10bx8_align_array_s1 <= word10bx8_align_array;
    end if;
end process;
--
word10bx8_align_rdy_s1 <= alignment_sreg(4);
--
process(bitCLK, rst)
begin
    if rst = '1' then
        align_select <= "0000";
    elsif bitCLK'event and bitCLK = '1' then
		if comma_valid_bits_or = '1' then
            align_select(0) <= (not comma_valid_bits(0)) and ( 
                comma_valid_bits(1)  or (  (not comma_valid_bits(1))  and (not comma_valid_bits(2))  and (
                comma_valid_bits(3)  or (  (not comma_valid_bits(3))  and (not comma_valid_bits(4))  and (
                comma_valid_bits(5)  or (  (not comma_valid_bits(5))  and (not comma_valid_bits(6))  and (
                comma_valid_bits(7)  or (  (not comma_valid_bits(7))  and (not comma_valid_bits(8))  and (
                comma_valid_bits(9)  or (  (not comma_valid_bits(9))  and (not comma_valid_bits(10)) and (
                comma_valid_bits(11) or (  (not comma_valid_bits(11)) and (not comma_valid_bits(12)) and (
                comma_valid_bits(13) or (  (not comma_valid_bits(13)) and (not comma_valid_bits(14)) and (
                comma_valid_bits(15)
                )))))))))))))));
            
            align_select(1) <= ((not comma_valid_bits(0)) and (not comma_valid_bits(1))) and (  
                (comma_valid_bits(2) or comma_valid_bits(3)) or (  
                ((not comma_valid_bits(2)) and (not comma_valid_bits(3)) and (not comma_valid_bits(4)) and (not comma_valid_bits(5))) and (
                (comma_valid_bits(6) or comma_valid_bits(7)) or (                
                ((not comma_valid_bits(6)) and (not comma_valid_bits(7)) and (not comma_valid_bits(8)) and (not comma_valid_bits(9))) and (
                (comma_valid_bits(10) or comma_valid_bits(11)) or (               
                ((not comma_valid_bits(10)) and (not comma_valid_bits(11)) and (not comma_valid_bits(12)) and (not comma_valid_bits(13))) and (
                (comma_valid_bits(14) or comma_valid_bits(15))
                )))))));
            
            align_select(2) <=  ((not comma_valid_bits(0)) and (not comma_valid_bits(1)) and (not comma_valid_bits(2)) and (not comma_valid_bits(3))) and (
                (comma_valid_bits(4) or comma_valid_bits(5) or comma_valid_bits(6) or comma_valid_bits(7)) or (               
                ((not comma_valid_bits(4)) and (not comma_valid_bits(5)) and (not comma_valid_bits(6)) and (not comma_valid_bits(7)) and (not comma_valid_bits(8)) and (not comma_valid_bits(9)) and (not comma_valid_bits(10)) and (not comma_valid_bits(11))) and (
                (comma_valid_bits(12) or comma_valid_bits(13) or comma_valid_bits(14) or comma_valid_bits(15))
                )));
                
            align_select(3) <=  ((not comma_valid_bits(0)) and (not comma_valid_bits(1)) and (not comma_valid_bits(2)) and (not comma_valid_bits(3)) and (not comma_valid_bits(4)) and (not comma_valid_bits(5)) and (not comma_valid_bits(6)) and (not comma_valid_bits(7))) and (     
                comma_valid_bits(8) or comma_valid_bits(9) or comma_valid_bits(10) or comma_valid_bits(11) or comma_valid_bits(12) or comma_valid_bits(13) or comma_valid_bits(14) or comma_valid_bits(15)
                );
        end if;
    end if;
end process;
--
align_select_work_s <=  "0000" when (align_select_current = "0000" and align_select = "1010") else
                        "0001" when (align_select_current = "0001" and align_select = "1011") else
                        "0010" when (align_select_current = "0010" and align_select = "1100") else
                        "0011" when (align_select_current = "0011" and align_select = "1101") else
                        "0100" when (align_select_current = "0100" and align_select = "1110") else
                        "0101" when (align_select_current = "0101" and align_select = "1111") else
                        align_select;

-------------------------------------------------------------------------------------------
--clock2
-- 
------------------------------------------------------------------------------------------- 
input_reg2: process(bitCLK)
begin
    if bitCLK'event and bitCLK = '1' then
        word10bx8_align_array_s2 <= word10bx8_align_array_s1;
        word10bx8_align_rdy_s2   <= word10bx8_align_rdy_s1;
    end if;
end process;
-- 
alg_reg2: process(bitCLK)
begin
    if bitCLK'event and bitCLK = '1' then
        align_select_current <= align_select;
        align_select_work_s1 <= align_select_work_s;
    end if;
end process;
--

-------------------------------------------------------------------------------------------
--clock3
-- alignment selected
-------------------------------------------------------------------------------------------
-- 
input_reg3: process(bitCLK)
begin
    if bitCLK'event and bitCLK = '1' then
        word10bx8_align_array_r <= word10bx8_align_array_s2;
        word10bx8_align_rdy_r   <= word10bx8_align_rdy_s2;
        align_select_work       <= align_select_work_s1;
    end if;
end process;
--

-------------------------------------------------------------------------------------------
--clock4
-- alignment selected
-------------------------------------------------------------------------------------------
-- 
input_reg4: process(bitCLK)
begin
    if bitCLK'event and bitCLK = '1' then
        word10b_array_rdy <= word10bx8_align_rdy_r;
    end if;
end process;
--
process(bitCLK)
begin
	if bitCLK'event and bitCLK = '1' then
        case (align_select_work) is 
            when "0000" =>  -- bit0 word got comma => align to bit0
                word10b_array <= word10bx8_align_array_r(0); 
            when "0001" =>  -- bit1 word got comma => align to bit1
                word10b_array <= word10bx8_align_array_r(1); 
            when "0010" =>  -- bit2 word got comma => align to bit2
                word10b_array <= word10bx8_align_array_r(2); 
            when "0011" =>  -- bit3 word got comma => align to bit3
                word10b_array <= word10bx8_align_array_r(3); 
            when "0100" =>  -- bit4 word got comma => align to bit4
                word10b_array <= word10bx8_align_array_r(4); 
            when "0101" =>  -- bit5 word got comma => align to bit5
                word10b_array <= word10bx8_align_array_r(5); 
            when "0110" =>  -- bit6 word got comma => align to bit6
                word10b_array <= word10bx8_align_array_r(6); 
            when "0111" =>  -- bit7 word got comma => align to bit7
                word10b_array <= word10bx8_align_array_r(7); 
            when "1000" =>  -- bit8 word got comma => align to bit8
                word10b_array <= word10bx8_align_array_r(8); 
            when "1001" =>  -- bit9 word got comma => align to bit9
                word10b_array <= word10bx8_align_array_r(9); 
            when "1010" =>  -- bit10 word got comma => align to bit10
                word10b_array <= word10bx8_align_array_r(10); 
            when "1011" =>  -- bit11 word got comma => align to bit11
                word10b_array <= word10bx8_align_array_r(11); 
            when "1100" =>  -- bit12 word got comma => align to bit12
                word10b_array <= word10bx8_align_array_r(12); 
            when "1101" =>  -- bit13 word got comma => align to bit13
                word10b_array <= word10bx8_align_array_r(13); 
            when "1110" =>  -- bit14 word got comma => align to bit14
                word10b_array <= word10bx8_align_array_r(14); 
            when "1111" =>  -- bit15 word got comma => align to bit15
                word10b_array <= word10bx8_align_array_r(15); 
            when others =>      
        end case;
    end if;
end process;
--

-------------------------------------------------------------------------------------------
-- 8b10b K-characters codes: COMMA/SOC/EOC/DATA
-------------------------------------------------------------------------------------------
KcharTests:  for I in 0 to 7 generate
KcharTestn: KcharTest 
port map( 
	clk            => bitCLK,
	encoded10in    => word10b_array(I),
	KcharCode      => isk_array(I)
	);
end generate KcharTests;
-- 
process(bitCLK)
begin
	if bitCLK'event and bitCLK = '1' then
		word10b_array_s       <= word10b_array;
		word10b_array_rdy_s   <= word10b_array_rdy;
	end if;
end process;
--
-- if more that 3 commas, will repeat itself next clock
realignment_ena      <=  '0' when (isk_array(0) = "11" and isk_array(1) = "11" and isk_array(2) = "11" and isk_array(3) = "11") else '1';
word10b_array_rdy_s1 <= word10b_array_rdy_s and realignment_ena;

-------------------------------------------------------------------------------------------
-- 8 words get aligned and ready as 10 bit word (data 8 bit and data code 2 bit)
-------------------------------------------------------------------------------------------
EPROC_IN16_ALIGN_BLOCK_inst: entity work.EPROC_IN16_ALIGN_BLOCK 
port map(
	bitCLKx2   => bitCLKx2,
    bitCLKx4   => bitCLKx4,
    rst        => rst,
    bytes      => word10b_array_s,
    bytes_rdy  => word10b_array_rdy_s1,
    dataOUT    => dataOUT,
    dataOUTrdy => dataOUTrdy
	);


end Behavioral;

