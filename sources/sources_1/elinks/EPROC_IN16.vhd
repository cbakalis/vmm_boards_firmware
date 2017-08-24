----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    08/03/2014
--! Module Name:    EPROC_IN16
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee, work;
use ieee.std_logic_1164.ALL;
use work.all;

--! E-link processor, 16bit input
entity EPROC_IN16 is
generic (
    do_generate             : boolean := true;
    includeNoEncodingCase   : boolean := true
    );
port ( 
    bitCLK      : in  std_logic;
    bitCLKx2    : in  std_logic;
    bitCLKx4    : in  std_logic;
    rst         : in  std_logic;
    ENA         : in  std_logic;
    ENCODING    : in  std_logic_vector (1 downto 0);
    EDATA_IN    : in  std_logic_vector (15 downto 0);
    DATA_OUT    : out std_logic_vector (9 downto 0);
    DATA_RDY    : out std_logic
    );
end EPROC_IN16;

architecture Behavioral of EPROC_IN16 is

constant zeros10array  : std_logic_vector (9 downto 0) := (others=>'0');
signal DATA_OUT_direct,DATA_OUT_8b10b_case,DATA_OUT_HDLC_case,DATA_OUT_s : std_logic_vector (9 downto 0);
signal DATA_RDY_direct,DATA_RDY_8b10b_case,DATA_RDY_HDLC_case,DATA_RDY_sig : std_logic;
signal RESTART_sig, rst_case00, rst_case01 : std_logic;
---

begin

gen_enabled: if do_generate = true generate

RESTART_sig <= rst or (not ENA); -- comes from clk40 domain 

-------------------------------------------------------------------------------------------
-- ENCODING case "00": direct data, no delimeter...
-------------------------------------------------------------------------------------------
direct_data_enabled: if includeNoEncodingCase = true generate
rst_case00 <= RESTART_sig or (ENCODING(1) or ENCODING(0));
EPROC_IN16_direct_inst: entity work.EPROC_IN16_direct 
port map(
    bitCLKx4    => bitCLKx4,
    rst         => rst_case00,
    edataIN     => EDATA_IN,
    dataOUT     => DATA_OUT_direct,
    dataOUTrdy  => DATA_RDY_direct
    );
end generate direct_data_enabled;
--
direct_data_disabled: if includeNoEncodingCase = false generate
DATA_RDY_direct <= '0';
DATA_OUT_direct <= (others=>'0');
end generate direct_data_disabled;
--

-------------------------------------------------------------------------------------------
-- ENCODING case "01": DEC8b10b
-------------------------------------------------------------------------------------------
rst_case01 <= RESTART_sig or (ENCODING(1) or (not ENCODING(0)));
--
EPROC_IN16_DEC8b10b_inst: entity work.EPROC_IN16_DEC8b10b 
port map(
    bitCLK      => bitCLK,
    bitCLKx2    => bitCLKx2,
    bitCLKx4    => bitCLKx4,
    rst         => rst_case01,
    edataIN     => EDATA_IN,
    dataOUT     => DATA_OUT_8b10b_case,
    dataOUTrdy  => DATA_RDY_8b10b_case
	);
	
-------------------------------------------------------------------------------------------
-- ENCODING case "10": HDLC
-------------------------------------------------------------------------------------------
-- TBD
DATA_OUT_HDLC_case <= (others=>'0');
DATA_RDY_HDLC_case <= '0';

-------------------------------------------------------------------------------------------
-- output data/rdy according to the encoding settings
-------------------------------------------------------------------------------------------
DATA_OUT_MUX4_10bit: entity work.MUX4_Nbit 
generic map(N=>10)
port map(
    data0 => DATA_OUT_direct,
    data1 => DATA_OUT_8b10b_case,
    data2 => DATA_OUT_HDLC_case,
    data3 => zeros10array, 
    sel   => ENCODING,
    data_out => DATA_OUT_s
    );

DATA_RDY_MUX4: entity work.MUX4 
port map(
    data0 => DATA_RDY_direct,
    data1 => DATA_RDY_8b10b_case,
    data2 => DATA_RDY_HDLC_case,
    data3 => '0',
    sel   => ENCODING,
    data_out => DATA_RDY_sig
	);


DATA_RDY <= DATA_RDY_sig;
DATA_OUT <= DATA_OUT_s;
--------------------
end generate gen_enabled;
--
--
gen_disabled: if do_generate = false generate
    DATA_OUT <= (others=>'0');
    DATA_RDY <= '0';
end generate gen_disabled;

end Behavioral;

