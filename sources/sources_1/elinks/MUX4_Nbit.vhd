----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    10/07/2014 
--! Module Name:    MUX4_Nbit
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library IEEE,work;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.all;

library unisim;
use unisim.vcomponents.all;

--! MUX 4x1, 16 bit data
entity MUX4_Nbit is
generic (
    N : integer     := 16);
Port ( 
	data0    : in  std_logic_vector((N-1) downto 0);
	data1    : in  std_logic_vector((N-1) downto 0);
	data2    : in  std_logic_vector((N-1) downto 0);
	data3    : in  std_logic_vector((N-1) downto 0);
	sel      : in  std_logic_vector(1 downto 0);
	data_out : out std_logic_vector((N-1) downto 0)
	);
end MUX4_Nbit;

architecture MUX4_Nbit_arc of MUX4_Nbit is
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

end MUX4_Nbit_arc;





