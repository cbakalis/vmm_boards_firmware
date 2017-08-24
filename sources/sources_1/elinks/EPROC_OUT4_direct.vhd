----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    05/19/2014 
--! Module Name:    EPROC_OUT4_direct
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use work.centralRouter_package.all;

--! direct data mode EPROC_OUT4 module
entity EPROC_OUT4_direct is
port(
    bitCLK      : in  std_logic;
    bitCLKx2    : in  std_logic;
    bitCLKx4    : in  std_logic;
    rst         : in  std_logic; 
    getDataTrig : out std_logic;   
    edataIN     : in  std_logic_vector (9 downto 0);
    edataINrdy  : in  std_logic;
    EdataOUT    : out std_logic_vector(3 downto 0)
    );
end EPROC_OUT4_direct;

architecture Behavioral of EPROC_OUT4_direct is

----------------------------------
----------------------------------
component pulse_pdxx_pwxx
generic( 
	pd : integer := 0;
	pw : integer := 1);
port(
    clk         : in   std_logic;
    trigger     : in   std_logic;
    pulseout    : out  std_logic
	);
end component pulse_pdxx_pwxx;
----------------------------------
----------------------------------
component MUX2_Nbit 
generic (N : integer  := 16);
Port ( 
	data0    : in  std_logic_vector((N-1) downto 0);
	data1    : in  std_logic_vector((N-1) downto 0);
	sel      : in  std_logic;
	data_out : out std_logic_vector((N-1) downto 0)
	);
end component;
----------------------------------
----------------------------------

constant zeros4bit  : std_logic_vector (1 downto 0) := (others=>'0');
signal byte_r : std_logic_vector (7 downto 0);
signal request_cycle_cnt, send_count : std_logic := '0';
signal send_out_trig : std_logic := '0';
signal inp_request_trig, inp_request_trig_out : std_logic;


begin

-------------------------------------------------------------------------------------------
-- input handshaking, request cycle 2 CLKs
-------------------------------------------------------------------------------------------
process(bitCLK)
begin
	if bitCLK'event and bitCLK = '1' then	   
		if rst = '1' then
		  request_cycle_cnt  <= '0';
		else 
          request_cycle_cnt <= not request_cycle_cnt;
		end if;
	end if;
end process;
--
inp_request_trig <= request_cycle_cnt;
--
inp_reques1clk: pulse_pdxx_pwxx generic map(pd=>0,pw=>1) port map(bitCLKx4, inp_request_trig, inp_request_trig_out); 
getDataTrig <= inp_request_trig_out;
--
process(bitCLK)
begin
	if bitCLK'event and bitCLK = '1' then	   
		send_out_trig <= inp_request_trig;
	end if;
end process;
--


-------------------------------------------------------------------------------------------
-- sending out 2 bits @ bitCLK
-------------------------------------------------------------------------------------------
process(bitCLK)
begin
	if bitCLK'event and bitCLK = '1' then	   
        if send_out_trig = '1' then
            byte_r <= edataIN(7 downto 0);
        end if;
	end if;
end process;
--
process(bitCLK)
begin
	if bitCLK'event and bitCLK = '1' then	   
        if send_out_trig = '1' then
            send_count <= '0';
        else
            send_count <= not send_count;
        end if;
	end if;
end process;
--
outmux: MUX2_Nbit 
generic map (N=>4)
port map ( 
	data0    => byte_r(3 downto 0),
	data1    => byte_r(7 downto 4),
	sel      => send_count,
	data_out => EdataOUT
	);
--


end Behavioral;

