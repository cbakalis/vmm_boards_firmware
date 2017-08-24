----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    10/07/2014 
--! Module Name:    MUX8_Nbit
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library IEEE,work;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.all;

library unisim;
use unisim.vcomponents.all;

--! MUX 8x1, N bit data
entity MUX8_Nbit is
generic (
    N : integer  := 16);
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
end MUX8_Nbit;

architecture MUX8_Nbit_arc of MUX8_Nbit is

begin

process(data0,data1,data2,data3,data4,data5,data6,data7,sel)
begin

    case sel is 
        when "000" => data_out <= data0;
        when "001" => data_out <= data1;
        when "010" => data_out <= data2;
        when "011" => data_out <= data3;
        when "100" => data_out <= data4;
        when "101" => data_out <= data5;
        when "110" => data_out <= data6;
        when "111" => data_out <= data7;
        when others =>
    end case;

end process;

end MUX8_Nbit_arc;





