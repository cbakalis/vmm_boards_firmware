----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    07/13/2014  
--! Module Name:    EPROC_FIFO_DRIVER
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee, work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use work.all;
use work.centralRouter_package.all;

--! a driver for EPROC FIFO, manages block header and sub-chunk trailer
entity EPROC_FIFO_DRIVER is
generic (
    GBTid               : integer := 0;
    egroupID            : integer := 0;
    epathID             : integer := 0;
    toHostTimeoutBitn   : integer := 8
    );
port ( 
    clk40           : in  std_logic;
    clk160          : in  std_logic;
    rst             : in  std_logic;
    ----------
    encoding        : in  std_logic_vector (1 downto 0);
    maxCLEN         : in  std_logic_vector (2 downto 0); 
    ---------
    raw_DIN         : in  std_logic_vector (9 downto 0); -- IG: get data from Epath without the 8/10 bit encoding
    raw_DIN_RDY     : in  std_logic; -- IG: get data ready from Epath without the 8/10 bit encoding
    ----------
    xoff            : in  std_logic;
    timeCntIn       : in std_logic_vector ((toHostTimeoutBitn-1) downto 0);
    TimeoutEnaIn    : in std_logic;
    instTimeoutEnaIn: in std_logic;
    ----------
    wordOUT         : out  std_logic_vector (15 downto 0);
    wordOUT_RDY     : out  std_logic;
    ----------
    busyOut         : out std_logic 
    );
end EPROC_FIFO_DRIVER;

architecture Behavioral of EPROC_FIFO_DRIVER is

--
signal DIN         : std_logic_vector (9 downto 0); -- IG: inserting the 8/10 bit encoding into the FIFO driver
signal DIN_RDY     : std_logic; -- IG: inserting the 8/10 bit encoding into the FIFO driver
signal raw_DIN_s0  : std_logic_vector (9 downto 0); -- IG: data from the 8/10 bits decoder
signal raw_DIN_s1  : std_logic_vector (9 downto 0); -- IG: use to delay the HDLC or Direct data in 1 clock cycle
signal input_mux_sel0,input_mux_sel1  : std_logic; 

signal DIN_r : std_logic_vector (7 downto 0) := (others => '0');
signal DIN_CODE_r : std_logic_vector (1 downto 0) := (others => '0');

signal DIN_s,DIN_s0,DIN_s1 : std_logic_vector (9 downto 0) := "1100000000";
signal DIN_RDY_s,DIN_RDY_s0,DIN_RDY_s1,DIN_RDY_r : std_logic := '0';
---
signal  receiving_state, data_shift_trig, trailer_shift_trig, trailer_shift_trig_s, 
        EOC_error, SOC_error, rst_clen_counter, data16bit_rdy, 
        truncating_state, truncation_trailer_sent,trailer_sent : std_logic := '0';

signal send_trailer_trig,data_shift_trig_s : std_logic;

signal DIN_prev_is_zeroByte, DIN_is_zeroByte : std_logic := '0';
signal direct_data_mode, direct_data_boundary_detected : std_logic;
      
signal trailer_trunc_bit, trailer_cerr_bit, first_subchunk, first_subchunk_on : std_logic := '0';
signal trailer_mod_bits  : std_logic_vector (1 downto 0);
signal trailer_type_bits : std_logic_vector (2 downto 0) := (others => '0');

signal EOB_MARK, preEOB_MARK,truncateDataFlag, flushed, flush_trig, data_rdy : std_logic;
signal trailer_shift_trigs, trailer_shift_trig0, header_shift_trigs : std_logic;
signal trailer_shift_trig1 : std_logic := '0';

signal trailer, trailer0, trailer1, header, data : std_logic_vector (15 downto 0);
signal wordOUT_s : std_logic_vector (15 downto 0) := (others => '0');

signal pathENA : std_logic := '0';
signal pathENAtrig, blockCountRdy,xoff_s,not_a_comma,trailer_reserved_bit : std_logic;
--
signal timeCnt_lastClk : std_logic_vector ((toHostTimeoutBitn-1+2) downto 0) := (others=>'1');
signal instTimeoutEnaIn_s,TimeoutEnaIn_s,timeout_state,timeout_ena,timeout_soc_ena,timeout_eoc_ena : std_logic := '0';
signal timeout_event,timeout_trailer_case : std_logic;
--
signal clk160_cnt0,clk160_cnt1 : std_logic_vector (1 downto 0) := (others=>'0');
signal data16bit_rdy_code : std_logic_vector (1 downto 0);
--

begin

------------------------------------------------------------
-- input selector to allow
-- one 8b10b decoder per e-path
------------------------------------------------------------
dec_8b10: entity work.dec_8b10_wrap -- 
port map(
	RESET         => rst,
	RBYTECLK      => clk160,
	ABCDEIFGHJ_IN => raw_DIN, -- 8b10b encoded
	HGFEDCBA      => raw_DIN_s0(7 downto 0),
	ISK           => raw_DIN_s0(9 downto 8),
	BUSY          => busyOut
);
--
process(clk160,rst) -- pipeline the input in case of other then 8b10b encoding
begin
    if rst = '1' then
        raw_DIN_s1 <= (others => '0');
    elsif rising_edge (clk160) then
        raw_DIN_s1 <= raw_DIN;
    end if;
end process;
--
input_mux_sel0 <= '0' when (encoding = "01") else '1';
input_sel0: entity work.MUX2_Nbit generic map(N =>10) port map (raw_DIN_s0 ,raw_DIN_s1 ,input_mux_sel0 ,DIN);
--
process(clk160,rst) -- cdc: clk40/clk80/clk160 to clk160
begin
    if rst = '1' then
        clk160_cnt0 <= (others=>'0');
    elsif rising_edge (clk160) then
        if raw_DIN_RDY = '1' then
            clk160_cnt0 <= clk160_cnt0 + 1;
        else
            clk160_cnt0 <= (others=>'0');
        end if;
    end if;
end process;
--
DIN_RDY <= '1' when (clk160_cnt0 = "01") else '0'; -- 1-clk pulse @ clk160
--
------------------------------------------------------------
-- DIN(10bit) and DIN_RDY(1 clk160) are clk160-aligned here
------------------------------------------------------------


------------------------------------------------------------
-- timeout logic for triggering the send-out of an 
-- incomplete block
------------------------------------------------------------
not_a_comma <= '1' when (DIN_RDY = '1' and DIN(9 downto 8) /= "11") else '0';
--
process(clk160,rst) -- timeout is held disabled until the new block is started
begin
    if rst = '1' then
        instTimeoutEnaIn_s  <= '0';
        TimeoutEnaIn_s      <= '0';
    elsif rising_edge (clk160) then
        if xoff_s = '1' then
            instTimeoutEnaIn_s  <= '0';
            TimeoutEnaIn_s      <= '0';
        elsif DIN(9 downto 8) = "10" then -- only after the first soc the timeout is enabled/re-enabled
            instTimeoutEnaIn_s  <= instTimeoutEnaIn;
            TimeoutEnaIn_s      <= TimeoutEnaIn;
        end if;
    end if;
end process;
--
process(clk160,rst) 
begin
    if rst = '1' then
        timeout_ena         <= '0';
        timeout_soc_ena     <= '0';
        timeout_eoc_ena     <= '0';
        input_mux_sel1      <= '0';
        timeout_event       <= '0';
        timeout_state       <= '0';
        timeCnt_lastClk     <= (others=>'1');
        clk160_cnt1         <= (others=>'0');
    elsif rising_edge (clk160) then         
        --
        if EOB_MARK = '1' or xoff_s = '1' then
            timeout_ena <= '0';
        elsif not_a_comma = '1' then
            timeout_ena <= TimeoutEnaIn_s or instTimeoutEnaIn_s;
        end if;
        --
        if (timeCnt_lastClk = (timeCntIn & clk160_cnt1) and TimeoutEnaIn_s = '1') or 
                (trailer_sent = '1' and instTimeoutEnaIn_s = '1' and timeout_state = '0' and timeout_eoc_ena = '0') then  -- timeCntIn is held 1 clk40, refreshed @ clk160, once during this time
            timeout_event <= timeout_ena; --  held 1 clk40
        else
            timeout_event <= '0';
        end if;
        --
        --if (timeout_event = '1' or input_mux_sel1 ='1') and DIN_RDY_s1 = '1' then -- start of timeout packet
--        if timeout_soc_ena = '1' and DIN_RDY_r = '1' and DIN_CODE_r = "10" then -- start of timeout packet (soc was sent)
        if timeout_soc_ena = '1' and DIN_RDY_s1 = '1' and DIN_s1(9 downto 8) = "10" and input_mux_sel1 = '1' then -- start of timeout packet (soc was sent)
            timeout_state   <= '1';
        elsif EOB_MARK = '1' or not_a_comma = '1' or xoff_s = '1' then
            timeout_state   <= '0';
        end if;
        --
        ------------------------
        --
        -- mux1: select control
        --
        if not_a_comma = '1' or EOB_MARK = '1' or timeout_ena = '0' then -- not a comma on the input / end-of-block
            input_mux_sel1  <= '0'; -- original input is selected
            timeCnt_lastClk <= timeCntIn & clk160_cnt1;   -- "valid data" or "disabled timeout" -> update counter cycle start point
        elsif timeout_event = '1' then
            input_mux_sel1  <= '1'; -- latched on timeout packet
        end if;
        --
        -- mux1: sel[1] input
        --
        DIN_RDY_s1  <= DIN_RDY; -- this would be the rate of the commas according to a e-link speed
        --
        if timeout_event = '1' and timeout_state = '0' then -- first clock of the timeout_state, next should be an soc
            timeout_soc_ena <= '1';
        elsif DIN_RDY_s1 = '1' and DIN_s1(9 downto 8) = "10" then -- soc was sent
            timeout_soc_ena <= '0';
        end if;
        --
        if ((preEOB_MARK = '1' or not_a_comma = '1' or xoff_s = '1') and timeout_state = '1') then -- next should be an eoc
            timeout_eoc_ena <= '1';
        elsif header_shift_trigs = '1' or trailer_sent = '1' then -- t/o trailer was written
            timeout_eoc_ena <= '0';
        end if;
        --
        if timeout_soc_ena = '1' and timeout_state = '0' then -- start of timeout packet
            DIN_s1          <= "10" & "00000000"; -- sop
        elsif timeout_eoc_ena = '1' then
            DIN_s1          <= "01" & "00000000"; -- eop
        else
            DIN_s1          <= "00" & "00000000"; -- zero-data
        end if;        
        --
        -- mux1: sel[0] input 
        --
        DIN_RDY_s0  <= DIN_RDY;
        DIN_s0      <= DIN;
        --
        -- mux1
        --
        if input_mux_sel1 = '0' then -- from input
            DIN_s       <= DIN_s0; 
            DIN_RDY_s   <= DIN_RDY_s0;
        else
            DIN_s       <= DIN_s1; 
            DIN_RDY_s   <= DIN_RDY_s1;
        end if; 
        --
        clk160_cnt1 <= clk160_cnt1 + 1;    
        -- 
    end if;
end process;
--
--
timeout_trailer_case    <= timeout_state or timeout_eoc_ena;
--
process(clk160)
begin
    if rising_edge (clk160) then        
        if xoff = '1' then
            if not_a_comma = '1' then 
                xoff_s <= '1'; -- latched
            end if;
        else 
            xoff_s <= '0';
        end if;
    end if;
end process;
--xoff_s                  <= xoff;
trailer_reserved_bit    <= xoff;
--


---------------------------------------------
-- for the direct data case:
-- register the input byte comparator result 
-- for the direct data case to detect zeros as data delimeter
---------------------------------------------
direct_data_mode <= not(encoding(1) or encoding(0));
--
process(clk160)
begin
    if rising_edge (clk160) then
        if DIN_RDY = '1' then
            if DIN(7 downto 0) = "00000000" then
                DIN_is_zeroByte <= '1';
            else
                DIN_is_zeroByte <= '0';
            end if;
        end if;
    end if;
end process;
-- pipeline the input byte comparator result 
process(clk160)
begin
    if rising_edge (clk160) then
        if DIN_RDY = '1' then
            DIN_prev_is_zeroByte <= DIN_is_zeroByte;
        end if;
    end if;
end process;
--
direct_data_boundary_detected <= '1' when (DIN_is_zeroByte = '1' and DIN_prev_is_zeroByte = '1') else '0';
--

---------------------------------------------
-- initial enabling of the path: 
-- enabled after reset on the first 
-- valid input symbol (must be comma!)
-- the first symbol is then lost! as we are sending
-- a bloack header when it is detected
---------------------------------------------
process(clk160)
begin
    if rising_edge (clk160) then
        if rst = '1' then
            pathENA <= '0';
        elsif DIN_RDY_s = '1' then  
            pathENA <= '1';
        end if;
    end if;
end process;
-- trigger to restart the block counter
pathENA1clk: entity work.pulse_pdxx_pwxx GENERIC MAP(pd=>0,pw=>1) PORT MAP(clk160, pathENA, pathENAtrig); 


---------------------------------------------
-- main process inputs
---------------------------------------------
--
process(clk160, rst)
begin
    if rising_edge (clk160) then
        --
        DIN_RDY_r   <= DIN_RDY_s; 
        DIN_r       <= DIN_s(7 downto 0);
        --
        if direct_data_mode = '1' then
            DIN_CODE_r  <= direct_data_boundary_detected & '0'; -- "10"=soc, "00"=data
        else
            if truncateDataFlag = '0' then
                DIN_CODE_r <= DIN_s(9 downto 8);
            else
                --if DIN_RDY_r = '1' then
                    DIN_CODE_r <= "11";
                --end if;
            end if;
        end if;       
    end if;       
end process;
--


-----------------------------------------------------------
-- clock 3
--        case of the input word code:
-- "00" => data, "01" => EOC, "10" => SOC, "11" => COMMA
-----------------------------------------------------------
process(clk160, rst)
begin
    if rst = '1' then
        --
        receiving_state     <= '0';
        trailer_trunc_bit   <= '1';
        trailer_cerr_bit    <= '1';
        trailer_type_bits   <= "000"; -- not a legal code
        data_shift_trig     <= '0';
        trailer_shift_trig  <= '0';
        EOC_error           <= '0';
        SOC_error           <= '0';
        rst_clen_counter    <= '0';
        first_subchunk_on   <= '0';
        truncating_state    <= '0';
        --
    elsif rising_edge (clk160) then
        if DIN_RDY_r = '1' then
            case (DIN_CODE_r) is 
                when "00" =>  -- data
                    --
                    data_shift_trig     <= (receiving_state) and (not truncateDataFlag); -- shift-in data if in the receiving state
                    -- if block filled up after that, chunk trailer and block header will be shifted-in as well
                    trailer_trunc_bit   <= truncateDataFlag;  -- truncation mark in case of CLEN_error
                    trailer_cerr_bit    <= truncateDataFlag;  -- CLEN_error is '1' in case of receiving data after CLEN is reached
                    trailer_type_bits   <= (not (truncateDataFlag or first_subchunk)) & truncateDataFlag & first_subchunk;  -- 001_first, 011_whole, 100_middle, 010_last
                    trailer_shift_trig  <= truncateDataFlag and receiving_state; -- send a trailer once when CLEN value is reached (SOC will rst the chunk-len-counter)
                    receiving_state     <= receiving_state and (not truncateDataFlag); -- switching off receiving in case of truncateDataFlag, waiting for SOC now
                    EOC_error           <= '0';
                    SOC_error           <= not receiving_state; -- if current state is not 'receiving', flag an error, do nothing
                    rst_clen_counter    <= '0';
                    first_subchunk_on   <= '0';
                    truncating_state    <= truncateDataFlag and receiving_state; -- truncation trailer is sent in this 'case' (once)
                    --
                when "01" =>  -- EOC
                    --
                    trailer_shift_trig  <= receiving_state; -- if '1' => correct state, shift-in a trailer, if not, do nothing
                    -- sending a trailer is including padding with zeros ('flush') in case of even word count (should be flagged somewhere...)
                    trailer_trunc_bit   <= '0';  -- no truncation, proper ending
                    trailer_cerr_bit    <= '0';
                    trailer_type_bits   <= '0' & '1' & first_subchunk; -- 'last sub-chunk' or 'whole sub-chunk' mark
                    EOC_error           <= not receiving_state; -- if current state was not 'receiving', flag an error, do nothing
                    receiving_state     <= '0';                  
                    --
                    truncating_state    <= truncating_state;
                    rst_clen_counter    <= '0';
                    first_subchunk_on   <= '0';
                    data_shift_trig     <= '0';
                    SOC_error           <= '0';
                    --
                when "10" =>  -- SOC
                    --
                    trailer_shift_trig  <= (receiving_state and (not direct_data_mode)) or (truncateDataFlag and (not truncation_trailer_sent)); -- if '1' => incorrect state, shift-in a trailer to finish the unfinished chunk
                     -- sending a trailer is including padding with zeros ('flush') in case of even word count (should be flagged somewhere...)
                    trailer_trunc_bit   <= '1';  -- truncation mark in case of sending a trailer (this is when EOC was not received)
                    trailer_cerr_bit    <= '1';
                    trailer_type_bits   <= "01" & (first_subchunk or truncateDataFlag); -- 'last sub-chunk' or 'whole sub-chunk' mark
                    SOC_error           <= receiving_state; -- if current state was already 'receiving', flag an error
                    receiving_state     <= not truncateDataFlag; --'1';
                    rst_clen_counter    <= '1';
                    first_subchunk_on   <= '1';
                    truncating_state    <= truncateDataFlag and (not truncation_trailer_sent); -- truncation trailer is sent in this 'case' (once)
                    --
                    data_shift_trig     <= '0';
                    EOC_error           <= '0';
                    --
                when "11" =>  -- COMMA
                    --
                    -- do nothing
                    receiving_state     <= receiving_state;
                    truncating_state    <= truncating_state;
                    trailer_trunc_bit   <= '0'; 
                    trailer_cerr_bit    <= '0';
                    trailer_type_bits   <= "000"; 
                    data_shift_trig     <= '0';
                    trailer_shift_trig  <= '0';
                    EOC_error           <= '0';
                    SOC_error           <= '0';
                    rst_clen_counter    <= '0';
                    first_subchunk_on   <= '0';
                    --
                when others =>
            end case;
        else
            receiving_state     <= receiving_state;
            trailer_trunc_bit   <= trailer_trunc_bit;
            trailer_cerr_bit    <= trailer_cerr_bit;
            trailer_type_bits   <= trailer_type_bits; --"000";
            truncating_state    <= truncating_state;
            data_shift_trig     <= '0';
            trailer_shift_trig  <= '0';
            EOC_error           <= '0';
            SOC_error           <= '0';
            rst_clen_counter    <= '0';
            first_subchunk_on   <= '0';
        end if;
    end if;
end process;

-----------------------------------------------------------
-- truncation trailer should be only sent once (the first one)
-----------------------------------------------------------
process(clk160)
begin
    if rising_edge (clk160) then 
        if truncateDataFlag = '0' then
            truncation_trailer_sent <= '0';
        else -- truncateDataFlag = '1':
            if trailer_shift_trig = '1' then
                truncation_trailer_sent <= '1'; -- latch, send only one truncation trailer
            end if;
        end if;
    end if;
end process;
--
-----------------------------------------------------------
-- clock3, writing to the shift register
--        data8bit ready pulse
-----------------------------------------------------------
process(clk160)
begin
    if rising_edge (clk160) then -- first, try to flush the shift register        
        trailer_shift_trig_s        <= trailer_shift_trig and (not EOB_MARK); -- this trailer is a result of {eoc} or {soc without eoc} or {max clen violation}
    end if;
end process;
--
send_trailer_trig   <= trailer_shift_trig_s or EOB_MARK;--  
data_shift_trig_s   <= data_shift_trig;
flush_trig          <= trailer_shift_trig;-- and (not truncateDataFlag); -- no need for flush in truncation case
--
DATA_shift_r: entity work.reg8to16bit -- only for data or 'flush' padding
PORT MAP(
    rst         => rst,
    clk         => clk160,
    flush       => flush_trig, --trailer_shift_trig,
    din         => DIN_r,
    din_rdy     => data_shift_trig_s,
    -----
    flushed     => flushed,
    dout        => data,
    dout_rdy    => data_rdy
    );

----------------------------------------------------------- 
-- clock  
--  BLOCK_WORD_COUNTER
-----------------------------------------------------------
BLOCK_WORD_COUNTER_inst: entity work.BLOCK_WORD_COUNTER 
generic map (GBTid=>GBTid, egroupID=>egroupID, epathID=>epathID)
port map (
	CLK                    => clk160,
	RESET                  => rst, 
	RESTART                => pathENAtrig,
	BW_RDY                 => data16bit_rdy, -- counts everything that is written to EPROC FIFO
	EOB_MARK               => EOB_MARK, -- End-Of-Block: 'send the chunk trailer' trigger
	preEOB_MARK            => preEOB_MARK,
	BLOCK_HEADER_OUT       => header,
	BLOCK_HEADER_OUT_RDY   => header_shift_trigs,
	BLOCK_COUNT_RDY        => blockCountRdy
    );
--
process(clk160)
begin
    if rising_edge (clk160) then 
        if first_subchunk_on = '1' or rst = '1' then
            first_subchunk <= '1';
        elsif EOB_MARK = '1' and timeout_trailer_case = '0' then --
            first_subchunk <= '0';
        end if;
    end if;
end process;

-----------------------------------------------------------
-- Sub-Chunk Data manager
-- sends a trailer in 2 clocks (current clock and the next)
-----------------------------------------------------------
--
trailer_mod_bits <= trailer_trunc_bit & trailer_cerr_bit;
--
SCDataMANAGER_inst: entity work.SCDataMANAGER 
PORT MAP(
    CLK             => clk160,
    rst             => rst,
    xoff            => xoff_s,
    maxCLEN         => maxCLEN,
    rstCLENcount    => rst_clen_counter,
    truncateCdata   => truncateDataFlag,    -- out, next data will be truncated, a trailer will be sent instead
    trailerMOD      => trailer_mod_bits,    -- in, keeps its value till the next DIN_RDY_s
    trailerTYPE     => trailer_type_bits,   -- in, keeps its value till the next DIN_RDY_s 
    trailerRSRVbit  => trailer_reserved_bit,
    timeoutState    => timeout_trailer_case, -- timeout_state,
    -------
    trailerSENDtrig => send_trailer_trig,
    dataCNTena      => data_shift_trig_s, -- counts data Bytes (not 16-bit words)data_rdy, -- counts only data (or 'flush' padding), no header, no trailer
    -------
    trailerOUT      => trailer0,
    trailerOUTrdy   => trailer_shift_trig0
);
--

--
process(clk160)
begin
    if rising_edge (clk160) then 
        trailer_shift_trig1 <= flushed;
        trailer1            <= trailer0;
    end if;
end process;
--
trailer_shift_trigs <= (trailer_shift_trig0 and (not flushed)) or trailer_shift_trig1;
--
process(trailer_shift_trig1, trailer1, trailer0)
begin
    if trailer_shift_trig1 = '1' then 
        trailer <= trailer1;
    else
        trailer <= trailer0;
    end if;
end process;

-----------------------------------------------------------
-- 16 bit output MUX, goes to a EPROC FIFO
-----------------------------------------------------------
--
data16bit_rdy         <= data_rdy or trailer_shift_trigs or header_shift_trigs;
data16bit_rdy_code(0) <= (not trailer_shift_trigs) and (data_rdy xor header_shift_trigs);
data16bit_rdy_code(1) <= (not header_shift_trigs) and (data_rdy xor trailer_shift_trigs);
--
process(clk160)
begin
    if rising_edge (clk160) then 

    case (data16bit_rdy_code) is 
        when "01" =>  -- header
            wordOUT_s <= header;
        when "10" =>  -- trailer
            wordOUT_s <= trailer;
        when "11" =>  -- data
            wordOUT_s <= data;           
        when others =>
            --wordOUT_s <= (others => '0');
    end case;
    
    end if;
end process;
--

--
process(clk160)
begin
    if rising_edge (clk160) then 
        wordOUT_RDY     <= data16bit_rdy;
        trailer_sent    <= trailer_shift_trigs;
    end if;
end process;
--


wordOUT     <= wordOUT_s;




end Behavioral;

