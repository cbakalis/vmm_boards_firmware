----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    05/19/2014
--! Module Name:    EPROC_IN2
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee, work;
use ieee.std_logic_1164.all;
use work.all;

--! 80 Mbps E-link processor, 2bit input @ clk40
entity EPROC_IN2 is
generic (
    do_generate             : boolean := true;
    includeNoEncodingCase   : boolean := true
    );
port ( 
    bitCLK          : in  std_logic;
    bitCLKx2        : in  std_logic;
    rst             : in  std_logic;
    ENA             : in  std_logic;
    swap_inputbits  : in  std_logic; -- bit swap on a GBT frame level
    ENCODING        : in  std_logic_vector(1 downto 0);
    EDATA_IN        : in  std_logic_vector(1 downto 0);
    DATA_OUT        : out std_logic_vector(9 downto 0);
    DATA_RDY        : out std_logic
    );
end EPROC_IN2;

architecture Behavioral of EPROC_IN2 is

signal edata_in_s : std_logic_vector(1 downto 0);
signal data_direct_8b10b_case,data_HDLC_case,DATA_OUT_s : std_logic_vector(9 downto 0);
signal drdy_direct_8b10b_case,drdy_HDLC_case,DATA_RDY_sig : std_logic;
signal ena_case0, ena_case1 : std_logic;
---

begin

gen_enabled: if do_generate = true generate

--
in_sel: process(swap_inputbits,EDATA_IN) -- bit swapping on a GBT frame level
begin   
    if swap_inputbits = '1' then
        edata_in_s <= EDATA_IN(0) & EDATA_IN(1);
    else
        edata_in_s <= EDATA_IN;
    end if;	   
end process;
--

-------------------------------------------------------------------------------------------
-- case 0: direct & 8b10b ENCODING b00 / b01
-------------------------------------------------------------------------------------------
ena_case0 <= '1' when (ENCODING(1) = '0' and ENA = '1') else '0';
--
direct_8b10b_case: entity work.EPROC_IN2_DEC8b10b 
generic map( includeNoEncodingCase => includeNoEncodingCase)
port map(
    bitCLK      => bitCLK,
    rst         => rst,
    ena         => ena_case0,
    encoding    => ENCODING(0),
    edataIN     => edata_in_s,
    dataOUT     => data_direct_8b10b_case,
    dataOUTrdy  => drdy_direct_8b10b_case
	);

-------------------------------------------------------------------------------------------
-- case 1: HDLC ENCODING b10
-------------------------------------------------------------------------------------------
ena_case1 <= '1' when (ENCODING = "10" and ENA = '1') else '0';
--
decHDLC_case: entity work.EPROC_IN2_HDLC 
port map(  
    bitCLK      => bitCLK,
    bitCLKx2    => bitCLKx2,
    rst         => rst,
    ena         => ena_case1,
    edataIN     => edata_in_s,
    dataOUT     => data_HDLC_case,
    dataOUTrdy  => drdy_HDLC_case
    );

	
-------------------------------------------------------------------------------------------
-- output data/rdy according to the encoding settings
-------------------------------------------------------------------------------------------
DATA_OUT_MUX2_10bit: entity work.MUX2_Nbit 
generic map(N=>10)
port map(
    data0       => data_direct_8b10b_case,
    data1       => data_HDLC_case,
    sel         => ENCODING(1),
    data_out    => DATA_OUT_s
	);
--
DATA_RDY_sig <= drdy_direct_8b10b_case or drdy_HDLC_case;
--
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

