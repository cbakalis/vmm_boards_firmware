----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    06/25/2014
--! Module Name:    EPROC_IN8
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee, work;
use ieee.std_logic_1164.ALL;
use work.all;

--! E-link processor, 8bit input
entity EPROC_IN8 is
generic (
    do_generate             : boolean := true;
    includeNoEncodingCase   : boolean := true
    );
port ( 
    bitCLK      : in  std_logic;
    rst         : in  std_logic;
    ENA         : in  std_logic;
    ENCODING    : in  std_logic_vector(1 downto 0);
    EDATA_IN    : in  std_logic_vector(7 downto 0);
    swap_inputbits : in std_logic;
    DATA_OUT    : out std_logic_vector(9 downto 0);
    DATA_RDY    : out std_logic
    );
end EPROC_IN8;

architecture Behavioral of EPROC_IN8 is

signal edata_in_s : std_logic_vector (7 downto 0);
signal data_direct_8b10b_case : std_logic_vector(9 downto 0);
signal drdy_direct_8b10b_case : std_logic;
signal ena_case0 : std_logic;
---

begin

gen_enabled: if do_generate = true generate

in_sel: process(swap_inputbits,EDATA_IN)
begin   
    if swap_inputbits = '1' then
        edata_in_s <= EDATA_IN(0) & EDATA_IN(1) & EDATA_IN(2) & EDATA_IN(3)
                   &  EDATA_IN(4) & EDATA_IN(5) & EDATA_IN(6) & EDATA_IN(7);
    else
        edata_in_s <= EDATA_IN;
    end if;    
end process;

-------------------------------------------------------------------------------------------
-- case 0: direct & 8b10b ENCODING b00 / b01
-------------------------------------------------------------------------------------------
ena_case0 <= '1' when (ENCODING(1) = '0' and ENA = '1') else '0';
--
direct_8b10b_case: entity work.EPROC_IN8_DEC8b10b 
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
-- N/A

-------------------------------------------------------------------------------------------
-- output data/rdy according to the encoding settings
-------------------------------------------------------------------------------------------
DATA_RDY <= drdy_direct_8b10b_case;
DATA_OUT <= data_direct_8b10b_case;
--------------------
end generate gen_enabled;
--
--
gen_disabled: if do_generate = false generate
    DATA_OUT <= (others=>'0');
    DATA_RDY <= '0';
end generate gen_disabled;

end Behavioral;

