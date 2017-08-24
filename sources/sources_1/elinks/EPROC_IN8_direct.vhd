----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    04/13/2015 
--! Module Name:    EPROC_IN8_direct
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use work.centralRouter_package.all;

--! direct data driver for EPROC_IN2 module
entity EPROC_IN8_direct is
    port (  
        bitCLKx2    : in  std_logic;
        bitCLKx4    : in  std_logic;
        rst         : in  std_logic;
        edataIN     : in  std_logic_vector (7 downto 0);
        dataOUT     : out std_logic_vector(9 downto 0);
        dataOUTrdy  : out std_logic
        );
end EPROC_IN8_direct;

architecture Behavioral of EPROC_IN8_direct is
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

signal word10b  : std_logic_vector (9 downto 0) := "1100000000"; -- comma
signal word8b, word8b_s   : std_logic_vector (7 downto 0) := (others=>'0');
signal word8bRdy, word10bRdy : std_logic := '0';

begin

-------------------------------------------------------------------------------------------
-- input registers
-------------------------------------------------------------------------------------------
input_map: process(bitCLKx2)
begin
    if bitCLKx2'event and bitCLKx2 = '1' then
        word8b_s    <= edataIN;
        word8b      <= word8b_s;
    end if;
end process;

-------------------------------------------------------------------------------------------
-- output (code = "00" = data)
-------------------------------------------------------------------------------------------
process(bitCLKx2, rst)
begin
    if rst = '1' then
        word8bRdy <= '0';
    elsif bitCLKx2'event and bitCLKx2 = '1' then
        word8bRdy <= not word8bRdy;
    end if;
end process;
--
process(bitCLKx2, rst)
begin
    if rst = '1' then
       word10bRdy  <= '0';
    elsif bitCLKx2'event and bitCLKx2 = '1' then
        if word8bRdy = '1' then   
            word10b     <= "00" & word8b; -- data
            word10bRdy  <= '1';  
        else
            word10bRdy  <= '0';
        end if;
    end if;
end process;

dataOUT <= word10b;
dataOUTrdy_pulse: pulse_pdxx_pwxx GENERIC MAP(pd=>0,pw=>1) PORT MAP(bitCLKx4, word10bRdy, dataOUTrdy);

end Behavioral;

