----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    07/13/2014
--! Module Name:    CD_COUNTER
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

--! chunk data counter
entity CD_COUNTER is
port ( 
    CLK             : in  std_logic;
    RESET           : in  std_logic;
    xoff            : in  std_logic;
    COUNT_ENA       : in  std_logic; -- high only when data is sent (not counting header and trailers)
    MAX_COUNT       : in  std_logic_vector (2 downto 0); -- (15 downto 0);
    -----
    count_out       : out std_logic_vector (11 downto 0);
    truncate_data   : out std_logic
    );
end CD_COUNTER;

architecture Behavioral of CD_COUNTER is

signal count_sig : std_logic_vector (11 downto 0) := (others => '0');
signal max_mark, max_ena  : std_logic;

begin

--
max_ena  <= '0' when (MAX_COUNT = "000") else '1'; -- when max count is 0x0, no chunk length limit is set  
max_mark <= '1' when ((count_sig(11 downto 9) = MAX_COUNT) and (max_ena = '1')) else '0'; -- stays high until reset
--
counter: process(RESET, CLK)
begin
	if RESET = '1' then
		count_sig <= (others => '0');
	elsif CLK'event and CLK = '1' then
        if (COUNT_ENA = '1' and max_mark = '0') then
			count_sig <= count_sig + 1; -- keeps the final value until reset
		end if;
	end if;
end process;
--
truncate_data   <= max_mark or xoff;
count_out       <= count_sig;
--

end Behavioral;

