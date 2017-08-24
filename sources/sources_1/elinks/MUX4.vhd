----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    10/07/2014 
--! Module Name:    MUX4
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library unisim;
use unisim.vcomponents.all;

--! MUX 4x1
entity MUX4 is
Port ( 
	data0    : in std_logic;
	data1    : in std_logic;
	data2    : in std_logic;
	data3    : in std_logic;
	sel      : in std_logic_vector(1 downto 0);
	data_out : out std_logic
	);
end MUX4;

--architecture low_level_MUX4 of MUX4 is

--begin

--lut_inst: LUT6
--generic map (INIT => X"FF00F0F0CCCCAAAA")
--port map( 	
--	I0 => data0,
--	I1 => data1,
--	I2 => data2,
--	I3 => data3,
--	I4 => sel(0),
--	I5 => sel(1),
--	O => data_out
--	);

--end low_level_MUX4;

architecture behavioral of MUX4 is
begin

process(data0,data1,data2,data3,sel)
begin

    case sel is 
        when "00" => data_out <= data0;
        when "01" => data_out <= data1;
        when "10" => data_out <= data2;
        when "11" => data_out <= data3;
        when others =>
    end case;

end process;

end behavioral;




