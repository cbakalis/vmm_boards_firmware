----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    04/13/2015 
--! Module Name:    EPROC_IN16_direct
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use work.centralRouter_package.all;

--! direct data driver for EPROC_IN2 module
entity EPROC_IN16_direct is
    port (  
        bitCLKx4    : in  std_logic;
        rst         : in  std_logic;
        edataIN     : in  std_logic_vector (15 downto 0);
        dataOUT     : out std_logic_vector(9 downto 0);
        dataOUTrdy  : out std_logic
        );
end EPROC_IN16_direct;

architecture Behavioral of EPROC_IN16_direct is

signal word10b  : std_logic_vector (9 downto 0) := "1100000000"; -- comma
signal word8b_Byte0, word8b_Byte1, word8b_Byte0_s, word8b_Byte1_s   : std_logic_vector (7 downto 0) := (others=>'0');
signal word8bRdy, word10bRdy, Byte_index : std_logic := '0';

begin

-------------------------------------------------------------------------------------------
-- input registers
-------------------------------------------------------------------------------------------
input_map: process(bitCLKx4)
begin
    if bitCLKx4'event and bitCLKx4 = '1' then
        word8b_Byte0_s    <= edataIN(7 downto 0);
        word8b_Byte1_s    <= edataIN(15 downto 8);
        word8b_Byte0      <= word8b_Byte0_s;
        word8b_Byte1      <= word8b_Byte1_s;
    end if;
end process;

-------------------------------------------------------------------------------------------
-- output (code = "00" = data)
-------------------------------------------------------------------------------------------
process(bitCLKx4, rst)
begin
    if rst = '1' then
        word8bRdy <= '0';
    elsif bitCLKx4'event and bitCLKx4 = '1' then
        word8bRdy <= not word8bRdy;
    end if;
end process;
--
process(bitCLKx4)
begin
    if bitCLKx4'event and bitCLKx4 = '1' then
        if word8bRdy = '1' then   
            Byte_index <= not Byte_index;
        end if;
    end if;
end process;
--
process(bitCLKx4)
begin
    if bitCLKx4'event and bitCLKx4 = '1' then
        if word8bRdy = '1' then   
            if Byte_index = '0' then
                word10b     <= "00" & word8b_Byte0; 
                word10bRdy  <= '1'; 
            else
                word10b     <= "00" & word8b_Byte1;
                word10bRdy  <= '1';  
            end if;
        else
            word10bRdy  <= '0';
        end if;
    end if;
end process;

dataOUT     <= word10b;
dataOUTrdy  <= word10bRdy;

end Behavioral;

