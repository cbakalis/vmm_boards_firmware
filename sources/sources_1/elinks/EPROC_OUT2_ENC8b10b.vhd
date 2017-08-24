----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    05/19/2014 
--! Module Name:    EPROC_IN2_DEC8b10b
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use work.centralRouter_package.all;

--! 8b10b encoder for EPROC_OUT2 module
entity EPROC_OUT2_ENC8b10b is
port(
    bitCLK      : in  std_logic;
    bitCLKx2    : in  std_logic;
    bitCLKx4    : in  std_logic;
    rst         : in  std_logic; 
    getDataTrig : out std_logic;   
    edataIN     : in  std_logic_vector (9 downto 0);
    edataINrdy  : in  std_logic;
    EdataOUT    : out std_logic_vector(1 downto 0)
    );
end EPROC_OUT2_ENC8b10b;

architecture Behavioral of EPROC_OUT2_ENC8b10b is

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
component enc8b10_wrap 
port ( 	
	clk            : in  std_logic;
	rst            : in  std_logic;
	dataCode       : in  std_logic_vector (1 downto 0); -- 00"data, 01"eop, 10"sop, 11"comma
	dataIN         : in  std_logic_vector (7 downto 0);
	dataINrdy      : in  std_logic;
	encDataOut     : out  std_logic_vector (9 downto 0);
	encDataOutrdy  : out  std_logic
	);
end component enc8b10_wrap;
----------------------------------
----------------------------------
component MUX8_Nbit 
generic (N : integer  := 16);
Port ( 
	data0    : in  std_logic_vector((N-1) downto 0);
	data1    : in  std_logic_vector((N-1) downto 0);
	data2    : in  std_logic_vector((N-1) downto 0);
	data3    : in  std_logic_vector((N-1) downto 0);
	data4    : in  std_logic_vector((N-1) downto 0);
	data5    : in  std_logic_vector((N-1) downto 0);
	data6    : in  std_logic_vector((N-1) downto 0);
	data7    : in  std_logic_vector((N-1) downto 0);
	sel      : in  std_logic_vector(2 downto 0);
	data_out : out std_logic_vector((N-1) downto 0)
	);
end component MUX8_Nbit;
----------------------------------
----------------------------------

constant zeros2bit  : std_logic_vector (1 downto 0) := (others=>'0');
signal enc10bit, enc10bit_r : std_logic_vector (9 downto 0);
signal request_cycle_cnt, send_count : std_logic_vector (2 downto 0) := (others=>'0');
signal send_out_trig : std_logic := '0';
signal inp_request_trig, inp_request_trig_out : std_logic;


begin

-------------------------------------------------------------------------------------------
-- input handshaking, request cycle 5 CLKs
-------------------------------------------------------------------------------------------
process(bitCLK)
begin
	if bitCLK'event and bitCLK = '1' then	   
		if rst = '1' then
		  request_cycle_cnt  <= (others=>'0');
		else 
		  if inp_request_trig = '1' then
		      request_cycle_cnt <= (others=>'0');
		  else
		      request_cycle_cnt <= request_cycle_cnt + 1;
		  end if;
		end if;
	end if;
end process;
--
inp_request_trig <= '1' when (request_cycle_cnt = "100") else '0';
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
-- 8b10b encoding
-------------------------------------------------------------------------------------------
enc8b10bx: enc8b10_wrap 
port map ( 	
	clk            => bitCLKx4,
	rst            => rst,
	dataCode       => edataIN(9 downto 8), -- 00"data, 01"eop, 10"sop, 11"comma
	dataIN         => edataIN(7 downto 0),
	dataINrdy      => edataINrdy, -- one? CLKx4 after inp_request_trig_out
	encDataOut     => enc10bit
	);

-------------------------------------------------------------------------------------------
-- sending out 2 bits @ bitCLK
-------------------------------------------------------------------------------------------
--
process(bitCLK)
begin
	if bitCLK'event and bitCLK = '1' then	   
        if rst = '1' then  
            enc10bit_r <= (others=>'0');
        elsif send_out_trig = '1' then
            --enc10bit_r <= enc10bit;
            enc10bit_r <= enc10bit(0) & enc10bit(1) & enc10bit(2) & enc10bit(3) & enc10bit(4) & enc10bit(5) & enc10bit(6) & enc10bit(7) & enc10bit(8) & enc10bit(9);
        end if;
	end if;
end process;
--
process(bitCLK)
begin
	if bitCLK'event and bitCLK = '1' then	   
        if send_out_trig = '1' then
            send_count <= (others=>'0');
        else
            send_count <= send_count + 1;
        end if;
	end if;
end process;
--
outmux: MUX8_Nbit 
generic map (N=>2)
port map ( 
	data0    => enc10bit_r(1 downto 0),
	data1    => enc10bit_r(3 downto 2),
	data2    => enc10bit_r(5 downto 4),
	data3    => enc10bit_r(7 downto 6),
	data4    => enc10bit_r(9 downto 8),
	data5    => zeros2bit,
	data6    => zeros2bit,
	data7    => zeros2bit,
	sel      => send_count,
	data_out => EdataOUT
	);
--



end Behavioral;

