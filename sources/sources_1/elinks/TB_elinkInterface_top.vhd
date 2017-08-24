----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    27/11/2016
--! Module Name:    TB_elinkInterface_top
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library work, ieee, std;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use std.textio.all;
--use work.txt_util.all;

--! Test Bench for a GBT_DATA_MANAGERtest module, 
--! stand alone GBT_DATA_MANAGER driven by EgroupDriver E-link emulator
ENTITY TB_elinkInterface_top IS
END TB_elinkInterface_top;
 
ARCHITECTURE behavior OF TB_elinkInterface_top IS 

-- Component Declaration for the Unit Under Test (UUT)
component elinkInterface_top 
generic(
    elinkRate       	: integer := 80; -- 80 / 160 / 320 / 640 MHz
    elinkEncoding       : std_logic_vector (1 downto 0) := "10"; -- 00-direct data / 01-8b10b encoding / 10-HDLC encoding 
	do_serialize 		: boolean := true
);
port (  
    clk_200_in_n    : in  std_logic;
    clk_200_in_p    : in  std_logic;
    sys_reset_n     : in  std_logic;
    rst_sw          : in  std_logic;
    locked          : out std_logic;
    clk40_out       : out std_logic;
    rst_state       : out std_logic;
    ------
    emu_ena         : in  std_logic; 
    --
    edata_clk       : out std_logic;
    edata           : out std_logic_vector (15 downto 0); 
    edata_rdy       : out std_logic 
    ------
    );
end component elinkInterface_top;

--Inputs
signal clk_200_in_n, sys_reset_n : std_logic := '1';
signal clk_200_in_p, rst_sw : std_logic := '0';
signal emu_ena  : std_logic := '0';

--Outputs
signal edata : std_logic_vector(15 downto 0);
signal edata_rdy, locked, edata_clk, rst_state, clk40_out : std_logic;

--
signal sim_rdy : std_logic := '0';

-- Clock period definitions
constant clk_200_period     : time := 5 ns;
constant clk40_period       : time := 25 ns;
constant clk_320_period     : time := 3.125 ns;

-- Elink Constants
constant elinkRate       	: integer := 80; -- 80 / 160 / 320 / 640 MHz
constant elinkEncoding      : std_logic_vector (1 downto 0) := "10"; -- 00-direct data / 01-8b10b encoding / 10-HDLC encoding 
constant do_serialize 		: boolean := true;
 
BEGIN

 
-- Instantiate the Unit Under Test (UUT)
uut: component elinkInterface_top 
generic map(
    elinkRate       	=> elinkRate, -- 80 / 160 / 320 / 640 MHz
    elinkEncoding       => elinkEncoding, -- 00-direct data / 01-8b10b encoding / 10-HDLC encoding 
	do_serialize 		=> do_serialize
)
port map (  
    clk_200_in_n    => clk_200_in_n,
    clk_200_in_p    => clk_200_in_p,
    sys_reset_n     => sys_reset_n,
    rst_sw          => rst_sw,
    locked          => locked,
    clk40_out       => clk40_out,
    rst_state       => rst_state,
    ------
    emu_ena         => emu_ena, 
    --
    edata_clk       => edata_clk,
    edata           => edata,
    edata_rdy       => edata_rdy
    ------
    );
    

----------------------------------
-- Clock process definition
CLK_200_process :process
begin
    clk_200_in_p <= '1';
    wait for clk_200_period/2;
    clk_200_in_p <= '0';
    wait for clk_200_period/2;
end process;
--
clk_200_in_n    <= not clk_200_in_p;
----------------------------------


---------------------------------------------------------------
-- elink data is written to file: "elink_data_16bit.txt"
---------------------------------------------------------------
process(edata_clk) -- write to a file
file results_file: text open write_mode is "elink_data_16bit.txt";
variable line_out: line;
begin
	if edata_clk'event and edata_clk = '0' then
		if edata_rdy = '1' then
            write(line_out, edata);
            writeline(results_file, line_out);
		end if;	
	end if;
end process;
--


---------------------------------------------------------------
-- reset/fifo flush process is inside top module
---------------------------------------------------------------
reset_proc: process
begin		
wait for 200 ns;	
sys_reset_n <= '0'; --<--------------- reset_n MMCMs
wait for 200 ns;	
sys_reset_n <= '1';
wait until locked = '1'; --<--------------- clocks are locked
wait until clk40_out = '0'; -- 
wait until clk40_out = '1'; -- next clock
rst_sw <= '1';
wait until clk40_out = '0'; -- 
wait until clk40_out = '1'; -- next clock
rst_sw <= '0';
wait until rst_state = '0';
------
wait until clk40_out = '0'; -- 
wait until clk40_out = '1'; -- next clock
sim_rdy <= '1';

wait;
end process;
--

--
ena_proc: process
begin			
wait until sim_rdy = '1';
wait for 200 ns;	
wait until clk40_out = '0'; -- 
wait until clk40_out = '1'; -- next clock
emu_ena <= '1';
wait;
end process;
--



end;
