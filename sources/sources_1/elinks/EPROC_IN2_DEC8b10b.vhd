----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    05/19/2014 
--! Module Name:    EPROC_IN2_DEC8b10b
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee, work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.all;
use work.centralRouter_package.all;

--! 8b10b decoder for EPROC_IN2 module
entity EPROC_IN2_DEC8b10b is
generic (includeNoEncodingCase : boolean := true);
port (  
    bitCLK      : in  std_logic;
    rst         : in  std_logic;
    ena         : in  std_logic;
    encoding    : in  std_logic; -- '0' direct data, '1' 8b10b
    edataIN     : in  std_logic_vector (1 downto 0);
    dataOUT     : out std_logic_vector(9 downto 0);
    dataOUTrdy  : out std_logic
    );
end EPROC_IN2_DEC8b10b;

architecture Behavioral of EPROC_IN2_DEC8b10b is

signal EDATAbitstreamSREG : std_logic_vector (11 downto 0) := (others=>'0'); -- 12 bit (2 x 5 = 10, plus 2 more)
signal word10b_align_array, word10b_align_array_r : word10b_2array_type;
signal word10b : std_logic_vector (9 downto 0) := (others=>'0');
signal direct10bData : std_logic_vector (9 downto 0) := "1100000000";
signal comma_valid_bits_or, word10b_align_rdy_r,encoding_s : std_logic;
signal align_select, word10b_rdy,direct10bDataRdy : std_logic := '0';
signal comma_valid_bits : std_logic_vector (1 downto 0);
signal alignment_sreg   : std_logic_vector (4 downto 0) := (others=>'0');
signal inpcount : std_logic_vector (1 downto 0) := (others=>'0');

attribute mark_debug                        : string;
attribute mark_debug of EDATAbitstreamSREG  : signal is "true";
attribute mark_debug of comma_valid_bits_or : signal is "true";
attribute mark_debug of alignment_sreg      : signal is "true";

begin

-------------------------------------------------------------------------------------------
--live bitstream
-- input shift register
-------------------------------------------------------------------------------------------
process(bitCLK, rst)
begin
    if rst = '1' then
        EDATAbitstreamSREG <= (others => '0');
    elsif rising_edge(bitCLK) then
        EDATAbitstreamSREG <= edataIN & EDATAbitstreamSREG(11 downto 2);
    end if;
end process;
--
-- direct data case
direct_data_enabled: if includeNoEncodingCase = true generate
input_counter: process(bitCLK, rst)
begin
    if rst = '1' then
        inpcount            <= (others=>'0');
        direct10bDataRdy    <= '0';
        direct10bData       <= "1100000000";
    elsif rising_edge(bitCLK) then
        if inpcount = "11" then
            direct10bDataRdy <= (not encoding) and ena;
            direct10bData    <= "00" & EDATAbitstreamSREG(7 downto 0);
        else
            direct10bDataRdy <= '0';
        end if;
        --
        inpcount <= inpcount + 1; 
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
input_map:  for I in 0 to 1 generate -- 1 10bit-word per alignment, 2 possible alignments
word10b_align_array(I) <= EDATAbitstreamSREG((I+9)  downto  (I+0));   -- 10 bit word, alligned to bit I
--word10b_align_array(I) <= EDATAbitstreamSREG(I+0)&EDATAbitstreamSREG(I+1)&EDATAbitstreamSREG(I+2)&EDATAbitstreamSREG(I+3)&EDATAbitstreamSREG(I+4)&
--                          EDATAbitstreamSREG(I+5)&EDATAbitstreamSREG(I+6)&EDATAbitstreamSREG(I+7)&EDATAbitstreamSREG(I+8)&EDATAbitstreamSREG(I+9);   -- 10 bit word, alligned to bit I
end generate input_map;
--

-------------------------------------------------------------------------------------------
--clock0
-- K28.5 comma test
-------------------------------------------------------------------------------------------
comma_test:  for I in 0 to 1 generate -- 1 10bit-word per alignment, comma is valid if two first words have comma...
comma_valid_bits(I) <=  '1' when (word10b_align_array(I) = COMMAp or word10b_align_array(I) = COMMAn) else '0';
end generate comma_test;
--                        
comma_valid_bits_or <=  comma_valid_bits(1) or comma_valid_bits(0);
--

-------------------------------------------------------------------------------------------
--clock1
-- alignment selector state
-------------------------------------------------------------------------------------------
process(bitCLK, rst)
begin
    if rst = '1' then
        alignment_sreg <= "00000";
    elsif rising_edge(bitCLK) then 
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
    if rising_edge(bitCLK) then
        word10b_align_array_r <= word10b_align_array;
    end if;
end process;
--
word10b_align_rdy_r <= alignment_sreg(4);
--
process(bitCLK, rst)
begin
    if rst = '1' then
        align_select <= '0';
    elsif rising_edge(bitCLK) then
		if comma_valid_bits_or = '1' then
            align_select <= (not comma_valid_bits(0)) and comma_valid_bits(1);
        end if;
    end if;
end process;
--

-------------------------------------------------------------------------------------------
--clock2
-- alignment selected
-------------------------------------------------------------------------------------------
-- 
input_reg2: process(bitCLK, rst)
begin
    if rst = '1' then
        word10b_rdy <= '0';
    elsif rising_edge(bitCLK) then
        word10b_rdy <= word10b_align_rdy_r and encoding and ena;
    end if;
end process;
--
process(bitCLK)
begin
	if rising_edge(bitCLK) then
        case (align_select) is 
            when '0' =>  -- bit0 word got comma => align to bit0
                word10b <= word10b_align_array_r(0); 
            when '1' =>  -- bit1 word got comma => align to bit1
                word10b <= word10b_align_array_r(1); 
            when others =>
        end case;
    end if;
end process;
--

-------------------------------------------------------------------------------------------
-- at this stage: word10b and word10b_rdy are aligned @ bitCLK
-------------------------------------------------------------------------------------------
process(bitCLK)
begin
	if rising_edge(bitCLK) then
        if encoding_s = '1' then -- 8b10b
            dataOUT <= word10b;
        else -- direct data case
            dataOUT <= direct10bData;
        end if;
        --
        dataOUTrdy <= direct10bDataRdy or word10b_rdy;
        --
    end if;
end process;
--

end Behavioral;
