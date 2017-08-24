----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    16/07/2014 
--! Module Name:    MUX2_Nbit
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library unisim;
use unisim.vcomponents.all;

--! MUX 2x1, data 16 bit
entity MUX2_Nbit is
generic (N : integer := 1);
port ( 
	data0    : in  std_logic_vector((N-1) downto 0);
	data1    : in  std_logic_vector((N-1) downto 0);
	sel      : in  std_logic;
	data_out : out std_logic_vector((N-1) downto 0)
	);
end MUX2_Nbit;


--architecture low_level_MUX2_Nbit of MUX2_Nbit is
--begin
--GENERATE_BIT_MUX2:  for I in 0 to (N-1) generate
--MUXF7n : MUXF7 port map (data_out(I), data0(I), data1(I), sel);
--end generate GENERATE_BIT_MUX2;
--end low_level_MUX2_Nbit;


architecture behavioral of MUX2_Nbit is
begin

process(data0, data1, sel)
begin
    if sel = '0' then
        data_out <= data0;
    else
        data_out <= data1;
    end if;
end process;

end behavioral;