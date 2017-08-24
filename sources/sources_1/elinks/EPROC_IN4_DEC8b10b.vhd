----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    06/22/2014 
--! Module Name:    EPROC_IN4_DEC8b10b
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee, work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.all;
use work.centralRouter_package.all;

--! 8b10b decoder for EPROC_IN4 module
entity EPROC_IN4_DEC8b10b is
generic (includeNoEncodingCase : boolean := true);
port (  
    bitCLK      : in  std_logic;
    rst         : in  std_logic;
    ena         : in  std_logic;
    encoding    : in  std_logic;  -- '0' direct data, '1' 8b10b
    edataIN     : in  std_logic_vector(3 downto 0);
    dataOUT     : out std_logic_vector(9 downto 0);
    dataOUTrdy  : out std_logic
    );
end EPROC_IN4_DEC8b10b;

architecture Behavioral of EPROC_IN4_DEC8b10b is

signal EDATAbitstreamSREG   : std_logic_vector (23 downto 0) := (others=>'0'); -- 24 bit (4 x 5 = 20, plus 4 more)
signal word10bx2_align_array, word10bx2_align_array_r : word10b_2array_4array_type;
signal word10b_array, word10b_array_s : word10b_2array_type;
signal isk_array            : isk_2array_type;

signal  comma_valid_bits_or, word10bx2_align_rdy_r,
        word10b_array_rdy, word10b_array_rdy_s  : std_logic;

signal align_select         : std_logic_vector (1 downto 0) := (others=>'0');
signal comma_valid_bits     : std_logic_vector (3 downto 0);
signal alignment_sreg       : std_logic_vector (4 downto 0) := (others=>'0');

signal inpcount,direct10bDataRdy : std_logic := '0';
signal encoding_s : std_logic;
signal direct10bData : std_logic_vector (9 downto 0) := "1100000000";
signal byte_in,byte_1 : std_logic_vector(9 downto 0) := (others => '0');
signal byte_in_rdy,byte_1_rdy : std_logic := '0';

attribute mark_debug                        : string;
attribute mark_debug of EDATAbitstreamSREG  : signal is "true";
attribute mark_debug of comma_valid_bits_or : signal is "true";
attribute mark_debug of alignment_sreg      : signal is "true";

begin

-------------------------------------------------------------------------------------------
--live bitstream
-- 24 bit input shift register
-------------------------------------------------------------------------------------------
process(bitCLK, rst)
begin
    if rst = '1' then
        EDATAbitstreamSREG <= (others => '0');
	elsif bitCLK'event and bitCLK = '1' then
        EDATAbitstreamSREG <= edataIN & EDATAbitstreamSREG(23 downto 4);
	end if;
end process;
--
-- direct data case
direct_data_enabled: if includeNoEncodingCase = true generate
input_counter: process(bitCLK, rst)
begin
    if rst = '1' then
        inpcount            <= '0';
        direct10bDataRdy    <= '0';
        direct10bData       <= "1100000000";
    elsif rising_edge(bitCLK) then
        if inpcount = '1' then
            direct10bDataRdy <= (not encoding) and ena;
            direct10bData    <= "00" & EDATAbitstreamSREG(7 downto 0);
        else
            direct10bDataRdy <= '0';
        end if;
        --
        inpcount <= not inpcount; 
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
input_map:  for I in 0 to 3 generate -- 2 10bit-words per alignment, 4 possible alignments
word10bx2_align_array(I)(0) <= EDATAbitstreamSREG((I+9)  downto  (I+0));   -- 1st 10 bit word, alligned to bit I
word10bx2_align_array(I)(1) <= EDATAbitstreamSREG((I+19) downto (I+10));   -- 2nd 10 bit word, alligned to bit I
--word10bx2_align_array(I)(0) <= EDATAbitstreamSREG(I+0)&EDATAbitstreamSREG(I+1)&EDATAbitstreamSREG(I+2)&EDATAbitstreamSREG(I+3)&EDATAbitstreamSREG(I+4)&
--                               EDATAbitstreamSREG(I+5)&EDATAbitstreamSREG(I+6)&EDATAbitstreamSREG(I+7)&EDATAbitstreamSREG(I+8)&EDATAbitstreamSREG(I+9);   -- 1st 10 bit word, alligned to bit I
--word10bx2_align_array(I)(1) <= EDATAbitstreamSREG(I+10)&EDATAbitstreamSREG(I+11)&EDATAbitstreamSREG(I+12)&EDATAbitstreamSREG(I+13)&EDATAbitstreamSREG(I+14)&
--                               EDATAbitstreamSREG(I+15)&EDATAbitstreamSREG(I+16)&EDATAbitstreamSREG(I+17)&EDATAbitstreamSREG(I+18)&EDATAbitstreamSREG(I+19);   -- 2nd 10 bit word, alligned to bit I
end generate input_map;
--

-------------------------------------------------------------------------------------------
--clock0
-- K28.5 comma test
-------------------------------------------------------------------------------------------
comma_test:  for I in 0 to 3 generate -- 2 10bit-words per alignment, comma is valid if two first words have comma
comma_valid_bits(I) <=  '1' when ((word10bx2_align_array(I)(0) = COMMAp or word10bx2_align_array(I)(0) = COMMAn) and 
                                  (word10bx2_align_array(I)(1) = COMMAp or word10bx2_align_array(I)(1) = COMMAn)) else '0';
end generate comma_test;
--                   
comma_valid_bits_or <=  comma_valid_bits(3) or comma_valid_bits(2) or comma_valid_bits(1) or comma_valid_bits(0);
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
        word10bx2_align_array_r <= word10bx2_align_array;
    end if;
end process;
--
word10bx2_align_rdy_r <= alignment_sreg(4);
--
process(bitCLK, rst)
begin
    if rst = '1' then
        align_select <= "00";
    elsif bitCLK'event and bitCLK = '1' then
		if comma_valid_bits_or = '1' then
            align_select(0) <= (not comma_valid_bits(0)) and ( 
                comma_valid_bits(1) or (  (not comma_valid_bits(1)) and (not comma_valid_bits(2)) and (
                comma_valid_bits(3) 
                )));
            
            align_select(1) <= (not comma_valid_bits(0)) and (not comma_valid_bits(1)) and 
                (comma_valid_bits(2) or comma_valid_bits(3));
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
        word10b_array_rdy <= word10bx2_align_rdy_r and encoding and ena;
    end if;
end process;
--
process(bitCLK)
begin
	if bitCLK'event and bitCLK = '1' then
		case (align_select) is 
            when "00" =>  -- bit0 word got comma => align to bit0
                word10b_array <= word10bx2_align_array_r(0); 
            when "01" =>  -- bit1 word got comma => align to bit1
                word10b_array <= word10bx2_align_array_r(1); 
            when "10" =>  -- bit2 word got comma => align to bit2
                word10b_array <= word10bx2_align_array_r(2); 
            when "11" =>  -- bit3 word got comma => align to bit3
                word10b_array <= word10bx2_align_array_r(3); 
            when others =>
        end case;
	end if;
end process;
--

-------------------------------------------------------------------------------------------
-- 8b10b K-characters codes: COMMA/SOC/EOC/DATA
-------------------------------------------------------------------------------------------
KcharTests:  for I in 0 to 1 generate
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
	if bitCLK'event and bitCLK = '1' then
		word10b_array_s       <= word10b_array;
		word10b_array_rdy_s   <= word10b_array_rdy;
	end if;
end process;
--


-------------------------------------------------------------------------------------------
-- 2 words get aligned and ready as 10 bit word (data 8 bit and data code 2 bit)
-------------------------------------------------------------------------------------------
process(bitCLK)
begin
    if rising_edge(bitCLK) then
        if word10b_array_rdy_s = '1' then
            byte_1       <= word10b_array_s(1);
            byte_1_rdy   <= '1';
        else
            byte_1_rdy   <= '0';
        end if;
    end if;
end process;
--
process(bitCLK)
begin
    if rising_edge(bitCLK) then
        if word10b_array_rdy_s = '1' then
            byte_in       <= word10b_array_s(0);
            byte_in_rdy   <= '1';
        elsif byte_1_rdy = '1' then 
            byte_in       <= byte_1;
            byte_in_rdy   <= '1';
        else
            byte_in_rdy   <= '0';
        end if;
    end if;
end process;
--
process(bitCLK)
begin
	if rising_edge(bitCLK) then
        if encoding_s = '1' then -- 8b10b
            dataOUT     <= byte_in;
        else -- direct data case
            dataOUT     <= direct10bData;
        end if;
        --
        dataOUTrdy <= direct10bDataRdy or byte_in_rdy;
        --
    end if;
end process;



end Behavioral;

