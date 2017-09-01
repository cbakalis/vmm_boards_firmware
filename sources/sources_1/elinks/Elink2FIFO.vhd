----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    17/08/2015 
--! Module Name:    Elink2FIFO
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee, work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.all;

--! consists of 1 E-path
entity Elink2FIFO is
generic (
    InputDataRate       : integer := 80; -- 80 / 160 / 320 / 640 MHz
    elinkEncoding       : std_logic_vector (1 downto 0); -- 00-direct data / 01-8b10b encoding / 10-HDLC encoding 
    serialized_input    : boolean := true
    );
port ( 
    clk40       : in  std_logic;
    clk80       : in  std_logic;
    clk160      : in  std_logic;    
    clk320      : in  std_logic;
    rst         : in  std_logic;
    fifo_flush  : in  std_logic;
    swap_input  : in  std_logic;
    ------
    DATA1bitIN  : in std_logic := '0';
    elink2bit   : in std_logic_vector (1 downto 0) := (others=>'0'); -- 2 bits @ clk40, can interface 2-bit of GBT frame
    elink4bit   : in std_logic_vector (3 downto 0) := (others=>'0'); -- 4 bits @ clk40, can interface 4-bit of GBT frame
    elink8bit   : in std_logic_vector (7 downto 0) := (others=>'0'); -- 8 bits @ clk40, can interface 8-bit of GBT frame
    -- 640 Mbps e-link can't come in as a serial input yet (additional clock is needed)
    elink16bit  : in std_logic_vector (15 downto 0) := (others=>'0'); -- 16 bits @ clk40, can interface 16-bit of GBT frame
    ------
    efifoRclk   : in  std_logic;
    efifoRe     : in  std_logic; 
    efifoHF     : out std_logic; -- half-full flag: 1 KByte block is ready to be read
    efifoEmpty  : out std_logic;
    fifo_full   : out std_logic;
    efifoDout   : out std_logic_vector (15 downto 0)
    ------
    );
end Elink2FIFO;

architecture Behavioral of Elink2FIFO is

--
constant maxClen    : std_logic_vector (11 downto 0) := (others => '0'); -- no limit on packet size here
signal DATA2bitIN, shreg2bit : std_logic_vector (1 downto 0) := (others => '0');
signal DATA4bitIN, shreg4bit : std_logic_vector (3 downto 0) := (others => '0');
signal DATA8bitIN, shreg8bit : std_logic_vector (7 downto 0) := (others => '0');
signal DATA_OUT     : std_logic_vector(9 downto 0); 
signal DATA_RDY, FIFO_RESET_STATE, almost_full, BWORD_RDY  : std_logic;
signal BWORD        : std_logic_vector(15 downto 0); 
----

attribute mark_debug                : string;
attribute mark_debug of DATA_OUT    : signal is "true";
attribute mark_debug of DATA_RDY    : signal is "true";

begin


------------------------------------------------------------
-- E-PATH case 80 MHz
------------------------------------------------------------
InputDataRate80: if InputDataRate = 80 generate
--
actual_elink_case: if serialized_input = true generate
process(clk80)
begin
    if rising_edge(clk80) then
        shreg2bit <= DATA1bitIN & shreg2bit(1);
	end if;
end process;
--
process(clk40)
begin
    if rising_edge(clk40) then
        DATA2bitIN <= shreg2bit;
	end if;
end process;
end generate actual_elink_case;
--
--
GBT_frame_case: if serialized_input = false generate
process(clk40)
begin
    if rising_edge(clk40) then
        DATA2bitIN <= elink2bit;
	end if;
end process;
end generate GBT_frame_case; 
--

EPROC_IN2bit: entity work.EPROC_IN2 
generic map (
    		do_generate             => true,
    		includeNoEncodingCase   => true
    		)
port map( 
			bitCLK     => clk40,
			bitCLKx2   => clk80,
			rst        => rst,
			ENA        => '1', -- always enabled here
			swap_inputbits => swap_input, -- when '1', the input bits will be swapped
			ENCODING   => elinkEncoding,  -- 00-direct data / 01-8b10b encoding / 10-HDLC encoding 
			EDATA_IN   => DATA2bitIN, -- @ 40MHz
			DATA_OUT   => DATA_OUT,  -- 10-bit data out
			DATA_RDY   => DATA_RDY
		);

end generate InputDataRate80; 



------------------------------------------------------------
-- E-PATH case 160 MHz
------------------------------------------------------------
InputDataRate160: if InputDataRate = 160 generate

--
actual_elink_case: if serialized_input = true generate
process(clk160)
begin
    if rising_edge(clk160) then
        shreg4bit <= DATA1bitIN & shreg4bit(3 downto 1);
	end if;
end process;
--
process(clk40)
begin
    if rising_edge(clk40) then
        DATA4bitIN <= shreg4bit;
	end if;
end process;
end generate actual_elink_case;
--
--
GBT_frame_case: if serialized_input = false generate
process(clk40)
begin
    if rising_edge(clk40) then
        DATA4bitIN <= elink4bit;
	end if;
end process;
end generate GBT_frame_case; 
--

EPROC_IN4bit: entity work.EPROC_IN4 
generic map (
    		do_generate             => true,
    		includeNoEncodingCase   => true
    		)
port map( 
			bitCLK     => clk40,
			rst        => rst,
			ENA        => '1', -- always enabled here
			swap_inputbits => swap_input, -- when '1', the input bits will be swapped
			ENCODING   => elinkEncoding,  -- 00-direct data / 01-8b10b encoding / 10-HDLC encoding 
			EDATA_IN   => DATA4bitIN, -- @ 40MHz
			DATA_OUT   => DATA_OUT,  -- 10-bit data out
			DATA_RDY   => DATA_RDY
);

end generate InputDataRate160; 





------------------------------------------------------------
-- E-PATH case 320 MHz
------------------------------------------------------------
InputDataRate320: if InputDataRate = 320 generate

--
actual_elink_case: if serialized_input = true generate
process(clk320)
begin
    if rising_edge(clk320) then
        shreg8bit <= DATA1bitIN & shreg8bit(7 downto 1);
	end if;
end process;
--
process(clk40)
begin
    if rising_edge(clk40) then
        DATA8bitIN <= shreg8bit;
	end if;
end process;
end generate actual_elink_case;
--
--
GBT_frame_case: if serialized_input = false generate
process(clk40)
begin
    if rising_edge(clk40) then
        DATA8bitIN <= elink8bit;
	end if;
end process;
end generate GBT_frame_case; 
--

EPROC_IN8bit: entity work.EPROC_IN8 
generic map (
    		do_generate             => true,
    		includeNoEncodingCase   => true
    		)
port map( 
			bitCLK     => clk40,
			rst        => rst,
			ENA        => '1', -- always enabled here
			ENCODING   => elinkEncoding,  -- 00-direct data / 01-8b10b encoding / 10-HDLC encoding 
			swap_inputbits => swap_input, -- when '1', the input bits will be swapped
			EDATA_IN   => DATA8bitIN, -- @ 40MHz
			DATA_OUT   => DATA_OUT,  -- 10-bit data out
			DATA_RDY   => DATA_RDY
		);

end generate InputDataRate320; 



------------------------------------------------------------
-- E-PATH case 640 MHz
------------------------------------------------------------
InputDataRate640: if InputDataRate = 640 generate
--
EPROC_IN16bit: entity work.EPROC_IN16 
generic map (
    		do_generate             => true,
    		includeNoEncodingCase   => true
    		)
port map(
			bitCLK     => clk40,
			bitCLKx2   => clk80,
			bitCLKx4   => clk160,
			rst        => rst,
			ENA        => '1', -- always enabled here
			ENCODING   => elinkEncoding,  -- 00-direct data / 01-8b10b encoding / 10-HDLC encoding 
			EDATA_IN   => elink16bit, -- @ 40MHz
			DATA_OUT   => DATA_OUT,  -- 10-bit data out
			DATA_RDY   => DATA_RDY
		);
--
end generate InputDataRate640; 




------------------------------------------------------------
-- EPATH FIFO DRIVER
------------------------------------------------------------
efd: entity work.EPROC_FIFO_DRIVER 
generic map(
    GBTid       		=> 0, -- no use
    egroupID    		=> 0, -- no use
    epathID     		=> 0,  -- no use
    toHostTimeoutBitn   => 8
    )
port map (
    clk40           => clk40,
    clk160          => clk160,
    rst             => rst,
    encoding        => elinkEncoding,--IG "10", -- 00-direct data / 01-8b10b encoding / 10-HDLC encoding 
    maxCLEN         => "000", -- 000-not limit on packet length
    raw_DIN         => DATA_OUT,  -- 10-bit data in
    raw_DIN_RDY     => DATA_RDY,
    xoff            => almost_full,
    timeCntIn       => x"00", -- not in use
    TimeoutEnaIn    => '0',  -- not in use
    instTimeoutEnaIn=> '0',
    wordOUT         => BWORD, -- 16-bit block word
    wordOUT_RDY     => BWORD_RDY,
    busyOut         => open -- not in use here 
       );


------------------------------------------------------------
-- EPATH FIFOs
------------------------------------------------------------
efw: entity work.EPATH_FIFO_WRAP
port map (
    rst         => rst,
    fifoFlush   => fifo_flush,
    wr_clk 	    => clk160,
    rd_clk 	    => efifoRclk,
    din         => BWORD,
    wr_en       => BWORD_RDY,
    rd_en       => efifoRe,
    dout        => efifoDout,
    almost_full => almost_full,
    fifo_empty  => efifoEmpty,
    fifo_full   => fifo_full,
    prog_full   => efifoHF -- Half-Full - output: 1Kbyte block is ready
    );


end Behavioral;

