----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    06/19/2014 
--! Module Name:    KcharTest
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.centralRouter_package.all;

--! KcharTest
entity KcharTest is
Port ( 
	clk            : in  std_logic;
	encoded10in    : in  std_logic_vector (9 downto 0);
	KcharCode      : out std_logic_vector (1 downto 0)
	);
end KcharTest;

architecture Behavioral of KcharTest is

signal KcharCode_comma,KcharCode_soc,KcharCode_eoc,KcharCode_sob,KcharCode_eob : std_logic;
signal KcharCode_s : std_logic_vector (1 downto 0) := (others=>'0');

begin

------------------------------------------------------------------------------------------------------
KcharCode_comma   <=  '1' when (encoded10in = COMMAp or encoded10in = COMMAn) else '0';
KcharCode_soc     <=  '1' when (encoded10in = SOCp or encoded10in = SOCn) else '0';
KcharCode_eoc     <=  '1' when (encoded10in = EOCp or encoded10in = EOCn) else '0';
KcharCode_sob     <=  '1' when (encoded10in = SOBp or encoded10in = SOBn) else '0';
KcharCode_eob     <=  '1' when (encoded10in = EOBp or encoded10in = EOBn) else '0';
------------------------------------------------------------------------------------------------------

process(clk)
begin
	if clk'event and clk = '1' then	   
		KcharCode_s(0) <= ((not KcharCode_soc) and (KcharCode_eoc xor KcharCode_comma)) or KcharCode_sob or KcharCode_eob;
        KcharCode_s(1) <= ((not KcharCode_eoc) and (KcharCode_soc xor KcharCode_comma)) or KcharCode_sob or KcharCode_eob;
	end if;
end process;
--
KcharCode <= KcharCode_s;

end Behavioral;

