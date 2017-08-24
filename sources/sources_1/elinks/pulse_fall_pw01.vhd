----------------------------------------------------------------------------------
--! Company:  Weizmann Institute of Science  
--! Engineer: juna
--! 
--! Create Date:    18/12/2014 
--! Module Name:    pulse_fall_pw01
----------------------------------------------------------------------------------
--! Use standard library
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--! generates a one-clk-pulse one clk after trigger's falling edge
entity pulse_fall_pw01 is
    Port ( 
        clk         : in   std_logic;
        trigger     : in   std_logic;
        pulseout    : out  std_logic
        );
end pulse_fall_pw01;

architecture behavioral of pulse_fall_pw01 is

------
signal trigger_1clk_delayed, t0 : std_logic;
------

begin

process (clk)
begin
    if clk'event and clk = '1' then
        trigger_1clk_delayed <= trigger;
    end if;
end process; 
--
t0 <= (not trigger) and trigger_1clk_delayed; -- the first clk after trigger fall
--
pulseout <= t0;
--

end behavioral;

