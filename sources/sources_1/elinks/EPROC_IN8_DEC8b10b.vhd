----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    06/25/2014 
--! Module Name:    EPROC_IN8_DEC8b10b
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee, work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.all;
use work.centralRouter_package.all;

--! 8b10b decoder for EPROC_IN8 module
entity EPROC_IN8_DEC8b10b is
generic (includeNoEncodingCase : boolean := true);
port (  
    bitCLK      : in  std_logic;
    rst         : in  std_logic;
    ena         : in  std_logic;
    encoding    : in  std_logic;  -- '0' direct data, '1' 8b10b
    edataIN     : in  std_logic_vector(7 downto 0);
    dataOUT     : out std_logic_vector(9 downto 0);
    dataOUTrdy  : out std_logic
    );
end EPROC_IN8_DEC8b10b;

architecture Behavioral of EPROC_IN8_DEC8b10b is

signal EDATAbitstreamSREG   : std_logic_vector(47 downto 0) := (others=>'0'); -- 48 bit (8 x 5 = 40, plus 8 more)
signal word10bx4_align_array, word10bx4_align_array_r : word10b_4array_8array_type;
signal word10b_array, word10b_array_s : word10b_4array_type;
signal isk_array            : isk_4array_type;

signal  comma_valid_bits_or,word10bx4_align_rdy_r, 
        word10b_array_rdy,word10b_array_rdy_s,word10b_array_rdy_s1,realignment_ena,comma_out_ena : std_logic;

signal comma_out_ena_s : std_logic := '0';
signal encoding_s : std_logic;

signal align_select         : std_logic_vector(2 downto 0) := (others=>'0');
signal comma_valid_bits     : std_logic_vector(7 downto 0);
signal alignment_sreg       : std_logic_vector(4 downto 0) := (others=>'0');

signal bytes_r : word10b_4array_type := ((others=>'0'),(others=>'0'),(others=>'0'),(others=>'0')); 
signal dataOUT_s : std_logic_vector(9 downto 0) := (others => '0');
signal direct10bData : std_logic_vector(9 downto 0) := (others => '0');
signal direct10bDataRdy,send_state,dataOUTrdy_s : std_logic := '0';
signal byte_count : std_logic_vector(1 downto 0) := "00";

attribute mark_debug                        : string;
attribute mark_debug of EDATAbitstreamSREG  : signal is "true";
attribute mark_debug of comma_valid_bits_or : signal is "true";
attribute mark_debug of alignment_sreg      : signal is "true";

begin

-------------------------------------------------------------------------------------------
--live bitstream
-- 48 bit input shift register
-------------------------------------------------------------------------------------------
process(bitCLK, rst)
begin
    if rst = '1' then
        EDATAbitstreamSREG <= (others => '0');
	elsif bitCLK'event and bitCLK = '1' then
        EDATAbitstreamSREG <= edataIN & EDATAbitstreamSREG(47 downto 8);
	end if;
end process;
--
-- direct data case
direct_data_enabled: if includeNoEncodingCase = true generate
input_counter: process(bitCLK, rst)
begin
    if rst = '1' then
        direct10bData       <= "1100000000";
    elsif rising_edge(bitCLK) then
        direct10bData    <= "00" & EDATAbitstreamSREG(7 downto 0);
    end if;
end process;
--
process(bitCLK, rst)
begin
    if rst = '1' then
        direct10bDataRdy <= '0';
    elsif bitCLK'event and bitCLK = '1' then
        direct10bDataRdy <= (not encoding) and ena;
    end if;
end process;
--
encoding_s <= encoding;
end generate direct_data_enabled;
--
direct_data_disabled: if includeNoEncodingCase = false generate
direct10bDataRdy    <= '0';
direct10bData       <= "1100000000";
encoding_s          <= '1';
end generate direct_data_disabled;
--

-------------------------------------------------------------------------------------------
--clock0
-- input shift register mapping into 10 bit registers
-------------------------------------------------------------------------------------------
input_map:  for I in 0 to 7 generate -- 4 10bit-words per alignment, 8 possible alignments
word10bx4_align_array(I)(0) <= EDATAbitstreamSREG((I+9)  downto  (I+0));   -- 1st 10 bit word, alligned to bit I
word10bx4_align_array(I)(1) <= EDATAbitstreamSREG((I+19) downto (I+10));   -- 2nd 10 bit word, alligned to bit I
word10bx4_align_array(I)(2) <= EDATAbitstreamSREG((I+29) downto (I+20));   -- 3rd 10 bit word, alligned to bit I
word10bx4_align_array(I)(3) <= EDATAbitstreamSREG((I+39) downto (I+30));   -- 4th 10 bit word, alligned to bit I
--word10bx4_align_array(I)(0) <= EDATAbitstreamSREG(I+0)&EDATAbitstreamSREG(I+1)&EDATAbitstreamSREG(I+2)&EDATAbitstreamSREG(I+3)&EDATAbitstreamSREG(I+4)&
--                               EDATAbitstreamSREG(I+5)&EDATAbitstreamSREG(I+6)&EDATAbitstreamSREG(I+7)&EDATAbitstreamSREG(I+8)&EDATAbitstreamSREG(I+9);   -- 1st 10 bit word, alligned to bit I
--word10bx4_align_array(I)(1) <= EDATAbitstreamSREG(I+10)&EDATAbitstreamSREG(I+11)&EDATAbitstreamSREG(I+12)&EDATAbitstreamSREG(I+13)&EDATAbitstreamSREG(I+14)&
--                               EDATAbitstreamSREG(I+15)&EDATAbitstreamSREG(I+16)&EDATAbitstreamSREG(I+17)&EDATAbitstreamSREG(I+18)&EDATAbitstreamSREG(I+19);   -- 2nd 10 bit word, alligned to bit I
--word10bx4_align_array(I)(2) <= EDATAbitstreamSREG(I+20)&EDATAbitstreamSREG(I+21)&EDATAbitstreamSREG(I+22)&EDATAbitstreamSREG(I+23)&EDATAbitstreamSREG(I+24)&
--                               EDATAbitstreamSREG(I+25)&EDATAbitstreamSREG(I+26)&EDATAbitstreamSREG(I+27)&EDATAbitstreamSREG(I+28)&EDATAbitstreamSREG(I+29);   -- 3rd 10 bit word, alligned to bit I
--word10bx4_align_array(I)(3) <= EDATAbitstreamSREG(I+30)&EDATAbitstreamSREG(I+31)&EDATAbitstreamSREG(I+32)&EDATAbitstreamSREG(I+33)&EDATAbitstreamSREG(I+34)&
--                               EDATAbitstreamSREG(I+35)&EDATAbitstreamSREG(I+36)&EDATAbitstreamSREG(I+37)&EDATAbitstreamSREG(I+38)&EDATAbitstreamSREG(I+39);   -- 4th 10 bit word, alligned to bit I
end generate input_map;

-------------------------------------------------------------------------------------------
--clock0
-- K28.5 comma test
-------------------------------------------------------------------------------------------
comma_test:  for I in 0 to 7 generate -- 4 10bit-words per alignment, comma is valid if two first words have comma
comma_valid_bits(I) <=  '1' when ((word10bx4_align_array(I)(0) = COMMAp or word10bx4_align_array(I)(0) = COMMAn) and 
                                  (word10bx4_align_array(I)(1) = COMMAp or word10bx4_align_array(I)(1) = COMMAn)) else '0';

end generate comma_test;
--                       
comma_valid_bits_or <=  '0' when comma_valid_bits = "00000000" else '1';
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
        word10bx4_align_array_r <= word10bx4_align_array;
    end if;
end process;
--
word10bx4_align_rdy_r <= alignment_sreg(4);
--

process(bitCLK, rst)
begin
    if rst = '1' then
        align_select <= "000";
    elsif bitCLK'event and bitCLK = '1' then
		if comma_valid_bits_or = '1' then
            align_select(0) <= (not comma_valid_bits(0)) and ( 
                comma_valid_bits(1) or (  (not comma_valid_bits(1)) and (not comma_valid_bits(2)) and (
                comma_valid_bits(3) or (  (not comma_valid_bits(3)) and (not comma_valid_bits(4)) and (
                comma_valid_bits(5) or (  (not comma_valid_bits(5)) and (not comma_valid_bits(6)) and (
                comma_valid_bits(7)
                )))))));
            
            align_select(1) <= (not comma_valid_bits(0)) and (not comma_valid_bits(1)) and 
                ((comma_valid_bits(2) or comma_valid_bits(3)) or (
                (not comma_valid_bits(2)) and (not comma_valid_bits(3)) and (not comma_valid_bits(4)) and (not comma_valid_bits(5)) and (
                comma_valid_bits(6) or comma_valid_bits(7))));
            
            align_select(2) <=  (not comma_valid_bits(0)) and (not comma_valid_bits(1)) and (not comma_valid_bits(2)) and (not comma_valid_bits(3)) and 
                (comma_valid_bits(4) or comma_valid_bits(5) or comma_valid_bits(6) or comma_valid_bits(7));
        end if;
    end if;
end process;
--

-------------------------------------------------------------------------------------------
--clock2
-- alignment selected
-------------------------------------------------------------------------------------------
-- 
input_reg2: process(bitCLK)
begin
    if bitCLK'event and bitCLK = '1' then
        word10b_array_rdy <= word10bx4_align_rdy_r and encoding and ena;
    end if;
end process;
--
process(bitCLK)
begin
	if bitCLK'event and bitCLK = '1' then
    case (align_select) is 
        when "000" =>  -- bit0 word got comma => align to bit0
            word10b_array <= word10bx4_align_array_r(0); 
        when "001" =>  -- bit1 word got comma => align to bit1
            word10b_array <= word10bx4_align_array_r(1); 
        when "010" =>  -- bit2 word got comma => align to bit2
            word10b_array <= word10bx4_align_array_r(2); 
        when "011" =>  -- bit3 word got comma => align to bit3
            word10b_array <= word10bx4_align_array_r(3); 
        when "100" =>  -- bit4 word got comma => align to bit4
            word10b_array <= word10bx4_align_array_r(4); 
        when "101" =>  -- bit5 word got comma => align to bit5
            word10b_array <= word10bx4_align_array_r(5); 
        when "110" =>  -- bit6 word got comma => align to bit6
            word10b_array <= word10bx4_align_array_r(6); 
        when "111" =>  -- bit7 word got comma => align to bit7
            word10b_array <= word10bx4_align_array_r(7); 
        when others =>
    end case;
    end if;
end process;
--

-------------------------------------------------------------------------------------------
-- 8b10b K-characters codes: COMMA/SOC/EOC/DATA
-------------------------------------------------------------------------------------------
KcharTests:  for I in 0 to 3 generate
KcharTestn: entity work.KcharTest 
port map( 
	clk            => bitCLK,
	encoded10in    => word10b_array(I),
	KcharCode      => isk_array(I)
	);
end generate KcharTests;
-- 
process(bitCLK)
begin
	if rising_edge(bitCLK) then
        if comma_out_ena = '1' and isk_array(3) /= "10" then 
            word10b_array_s <= (COMMAp,COMMAp,COMMAp,COMMAp);
        else 
            word10b_array_s <= word10b_array;
        end if;
        word10b_array_rdy_s <= word10b_array_rdy;
        comma_out_ena_s     <= comma_out_ena;
	end if;
end process;
--
-- if more that 2 commas, will repeat itself next clock
realignment_ena      <=  '0' when (isk_array(0) = "11" and isk_array(1) = "11" and isk_array(2) = "11") else '1';
word10b_array_rdy_s1 <= (word10b_array_rdy_s and realignment_ena) or (comma_out_ena_s and isk_array(3)(0) and isk_array(3)(1));
--
comma_out: entity work.pulse_fall_pw01 port map(bitCLK,realignment_ena,comma_out_ena);
--


-------------------------------------------------------------------------------------------
-- 4 words get aligned and ready as 10 bit word (data 8 bit and data code 2 bit)
-------------------------------------------------------------------------------------------
process(bitCLK, rst)
begin
    if rst = '1' then
        bytes_r     <= ((others=>'0'),(others=>'0'),(others=>'0'),(others=>'0')); 
        send_state  <= '0';
    elsif rising_edge(bitCLK) then
        if word10b_array_rdy_s1 = '1' then
            bytes_r     <= word10b_array_s;
            send_state  <= '1';
        else
            if byte_count = "11" then 
                send_state <= '0';
            end if;
        end if;
    end if;
end process;
--
process(bitCLK) 
begin
    if rising_edge(bitCLK) then
        if word10b_array_rdy_s1 = '1' or rst = '1' then
            byte_count <= "00";
        else
            if send_state = '1' then 
                byte_count <= byte_count + 1;
            else
                byte_count <= "00";
            end if;
        end if;
    end if;
end process;
--
process(bitCLK)
begin
    if rising_edge(bitCLK) then      
        dataOUTrdy_s <= send_state;
    end if;
end process;
--
out_select_proc: process(bitCLK)
begin
    if rising_edge(bitCLK) then
        case (byte_count) is 
            when "00" => dataOUT_s <= bytes_r(0);
            when "01" => dataOUT_s <= bytes_r(1);
            when "10" => dataOUT_s <= bytes_r(2);
            when "11" => dataOUT_s <= bytes_r(3);
            when others =>
        end case;
    end if;
end process;
--
--
process(bitCLK)
begin
	if rising_edge(bitCLK) then
        if encoding_s = '1' then -- 8b10b
            dataOUT     <= dataOUT_s;
        else -- direct data case
            dataOUT     <= direct10bData;
        end if;
        --
        dataOUTrdy <= direct10bDataRdy or dataOUTrdy_s;
        --
    end if;
end process;


end Behavioral;

