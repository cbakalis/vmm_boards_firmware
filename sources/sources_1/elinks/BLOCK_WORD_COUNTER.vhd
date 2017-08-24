----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    07/13/2014 
--! Module Name:    BLOCK_WORD_COUNTER
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee, work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.centralRouter_package.all;
use work.all;

--! counts block words, inserts block header
entity BLOCK_WORD_COUNTER is
generic (
    GBTid               : integer := 0;
    egroupID            : integer := 0;
    epathID             : integer := 0
    );
port ( 
    CLK     : in  std_logic;
    RESET   : in  std_logic;
    RESTART : in  std_logic;
    BW_RDY  : in  std_logic; -- Block Word Ready Enable
    -------------
    EOB_MARK                : out  std_logic; -- End Of Block flag to send the trailer
    preEOB_MARK             : out  std_logic; -- timeout termination
    BLOCK_HEADER_OUT        : out  std_logic_vector(15 downto 0); --> sending block header
    BLOCK_HEADER_OUT_RDY    : out  std_logic;                      --> sending block header
    -------------
    BLOCK_COUNT_RDY         : out  std_logic
    );
end BLOCK_WORD_COUNTER;

architecture Behavioral of BLOCK_WORD_COUNTER is

signal count_sig    : std_logic_vector (9 downto 0) := (others => '0');
signal seq_num      : std_logic_vector (4 downto 0) := (others => '0');
signal SOB_MARK, SOB_MARK0, seqCNTcase, seqCNTtrig, EOB_MARK_sig : std_logic;
signal SOB_MARK1, blockCountRdy : std_logic := '0';
signal BLOCK_HEADER : std_logic_vector(31 downto 0); 
-- two first words are always sent in the beginning of a block transmittion
constant count_offset : std_logic_vector (9 downto 0) := "0000000001"; 

begin

ce: process(CLK)
begin
	if rising_edge(CLK) then
		if RESET = '1' or RESTART = '1' then
            blockCountRdy <= '0';
		elsif SOB_MARK1 = '1' then
            blockCountRdy <= '1';
		end if;
	end if;
end process;
--
BLOCK_COUNT_RDY <= blockCountRdy;

--------------------------------------------------------------
-- counting block words, data partition
--------------------------------------------------------------
counter: process(CLK)
begin
	if rising_edge(CLK) then
		if RESET = '1' then
		  count_sig <= (others => '0');
		else
            if EOB_MARK_sig = '1' or RESTART = '1' then
                count_sig <= count_offset;
            elsif BW_RDY = '1' then
                count_sig <= count_sig + 1;
            end if;
		end if;
	end if;
end process;

--------------------------------------------------------------
-- End Of Block trigger out for the 
-- sub-chunk data manager to insert a trailer
--------------------------------------------------------------
EOB_MARK_sig    <= '1' when (count_sig = BLOCK_WORDn) else '0'; -- there is one more space left, for the trailer
preEOB_MARK     <= '1' when (count_sig = BLOCK_WORDn-1) else '0'; -- for timeout termination
EOB_MARK        <= EOB_MARK_sig; -- to output

--------------------------------------------------------------
-- Block Sequence counter, 5 bit
--------------------------------------------------------------
seqCNTcase <= EOB_MARK_sig or RESTART;
seqCNTtrig_pulse: entity work.pulse_pdxx_pwxx generic map(pd=>2,pw=>1) port map(CLK, seqCNTcase, seqCNTtrig); 
--
scounter: process(CLK)
begin
    if rising_edge(CLK) then
        if RESET = '1' then
            seq_num <= (others => '0');
        else
            if seqCNTtrig = '1' then
                seq_num <= seq_num + 1;
            end if;
        end if;
    end if;
end process;

--------------------------------------------------------------
-- Start Of Block Mark to insert block header
--------------------------------------------------------------
SOB_MARK <= '1' when (count_sig = count_offset) else '0';

--------------------------------------------------------------
-- Start Of Block produces 2 triggers 
-- to send 2 words, as header is 32bit
--------------------------------------------------------------
SOB_MARK0_PULSE: entity work.pulse_pdxx_pwxx generic map(pd=>0,pw=>1) port map(CLK, SOB_MARK, SOB_MARK0); -- FIFO WE to send word0
SOB_MARK1_PULSE: process(CLK)
begin
    if rising_edge(CLK) then
        SOB_MARK1 <= SOB_MARK0; -- FIFO WE to send word1
    end if;
end process;
--
-- [0xABCD_16]  [[block_counter_5]  [GBTid_5   egroupID_3   epathID_3]]
BLOCK_HEADER <= "1010101111001101" & seq_num & (std_logic_vector(to_unsigned(GBTid, 5))) & (std_logic_vector(to_unsigned(egroupID, 3))) & (std_logic_vector(to_unsigned(epathID, 3))); 
--
out_sel: process(CLK)
begin
    if rising_edge(CLK) then
        if SOB_MARK0 = '1' then
            BLOCK_HEADER_OUT <= BLOCK_HEADER(31 downto 16);
        else
            BLOCK_HEADER_OUT <= BLOCK_HEADER(15 downto 0);
        end if;
    end if;
end process;
--
BLOCK_HEADER_OUT_RDY <= SOB_MARK0 or SOB_MARK1;
--

end Behavioral;