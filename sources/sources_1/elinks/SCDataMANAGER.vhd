----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    07/13/2014
--! Module Name:    SCDataMANAGER - Sub-Chunk Data Manager
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library IEEE,work;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.all;

--! sub-chunk data manager, 
--! inserts sub-chunk trailer at the end of the chunk/block 
entity SCDataMANAGER is
Port ( 
    CLK             : in  std_logic;
    rst             : in  std_logic;
    xoff            : in  std_logic;
    maxCLEN         : in  std_logic_vector (2 downto 0); --  (15 downto 0);
    rstCLENcount    : in  std_logic;
    truncateCdata   : out std_logic; -- maximum allowed chunk length is reached of xoff received - truncation mark
    -------------
    trailerMOD      : in  std_logic_vector (1 downto 0); -- keeps its value till the next DIN_RDY_s
    trailerTYPE     : in  std_logic_vector (2 downto 0); -- keeps its value till the next DIN_RDY_s
    trailerRSRVbit  : in  std_logic; -- 
    timeoutState    : in  std_logic;
    -------------
    trailerSENDtrig : in  std_logic;  
    dataCNTena      : in  std_logic; -- counts only data (or 'flush' padding), no header, no trailer
    -------------
    trailerOUT      : out  std_logic_vector (15 downto 0);
    trailerOUTrdy   : out  std_logic
    );
end SCDataMANAGER;

architecture Behavioral of SCDataMANAGER is

----
signal truncate_state, sc_counter_rst, first_byte_count_rst : std_logic := '0';
signal truncate_data_flag, rst_fall, rstCLENcount_s, trailerSENDtrig_next_clk : std_logic;
signal sc_data_count : std_logic_vector(9 downto 0) := (others => '0');
signal schunk_length : std_logic_vector(9 downto 0);
signal chunk_data_count : std_logic_vector(11 downto 0);

signal trailer_s : std_logic_vector(15 downto 0);
constant zero_data_trailer : std_logic_vector(15 downto 0) := "0000000000000000"; -- "000"=null chunk, "00"=no truncation & no cerr, '0', 10 bit length is zero;
----

begin

rst_fall_pulse: entity work.pulse_fall_pw01 PORT MAP(CLK, rst, rst_fall); 

-----------------------------------------------------------------
-- chunk data counter, 
-- counts to MAX_COUNT then rises MAX_REACHED
-- used for chunk data truncation
-----------------------------------------------------------------
rst0: process(CLK)
begin
    if rising_edge(CLK) then
        rstCLENcount_s <= rstCLENcount or rst_fall;
	end if;
end process;

--
CD_COUNTER_inst: entity work.CD_COUNTER  
PORT MAP(
    CLK             => CLK,
    RESET           => rstCLENcount_s,
    xoff            => xoff,
    COUNT_ENA       => dataCNTena,
    MAX_COUNT       => maxCLEN,
    count_out       => chunk_data_count, -- the whole chunk data counter, used for data truncation
    truncate_data   => truncate_data_flag
);
--
truncate_state_latch: process(rstCLENcount, CLK)
begin
	if rstCLENcount = '1' then
		truncate_state <= '0';
	elsif CLK'event and CLK = '1' then
		if truncate_data_flag = '1' and trailerSENDtrig = '1' then -- first trigger goes through
			truncate_state <= '1';
		end if;
	end if;
end process;
--
truncateCdata <= truncate_data_flag;
--

-----------------------------------------------------------------
-- trailer: in case of zero data (last word of a block is left)
-----------------------------------------------------------------
zero_data_case: entity work.pulse_pdxx_pwxx generic map(pd=>1,pw=>2) PORT MAP(CLK, trailerSENDtrig, trailerSENDtrig_next_clk);
--process(CLK)
--begin
--	if CLK'event and CLK = '1' then
--		trailerSENDtrig_next_clk <= trailerSENDtrig;
--	end if;
--end process;
--

-----------------------------------------------------------------
-- Sub-Chunk Trailer bits
-- trailerTYPE(3bits) & trailerMOD(2bit) & trailerRSRVbit(1bit) & schunk_length(10);
-----------------------------------------------------------------
schunk_length   <= sc_data_count; -- chunk_data_count(9 downto 0); --
--
process(timeoutState,trailerTYPE,trailerMOD,trailerRSRVbit,schunk_length)
begin
    if timeoutState = '1' then
        trailer_s <= "101" & "00" & '0' & schunk_length;
    else
        trailer_s <= trailerTYPE & trailerMOD & trailerRSRVbit & schunk_length;
    end if;
end process;
--
process(trailerSENDtrig_next_clk, trailer_s)
begin
    if trailerSENDtrig_next_clk = '1' then
        trailerOUT <= zero_data_trailer; -- in case the only a space for a single 16-bit word is left, null-chunk is sent (ignored by software)
    else
        trailerOUT <= trailer_s;
    end if;
end process;
--
trailerOUTrdy <= trailerSENDtrig and (not truncate_state); -- same clock!

-----------------------------------------------------------------
-- sub-chunk data counter
-----------------------------------------------------------------
sc_counter_rst <= rstCLENcount_s; --rst_fall or rstCLENcount;
--
sub_chunk_counter: process(CLK)
begin
	if CLK'event and CLK = '1' then
		if sc_counter_rst = '1' or (dataCNTena = '0' and trailerSENDtrig = '1') then
            sc_data_count <= (others => '0');
        else
            if dataCNTena = '1' then --and first_byte_count_rst = '0' then
                if trailerSENDtrig = '1' then
                    sc_data_count <= "0000000001";
                else
                    sc_data_count <= sc_data_count + 1;
                end if;
            end if;
		end if;
	end if;
end process;
--

end Behavioral;

