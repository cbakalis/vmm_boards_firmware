----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    17/08/2015 
--! Module Name:    elinkInterface_package
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee;
use ieee.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

--! 
package elinkInterface_package is

constant elinkRate      : integer := 80; -- 80 / 160 / 320 / 640 Mbps   (*640 Mbps receiver only, data source is an 8b10b encoded data from emulator)
-- if elinkRate is 160 MHz, only {00-direct data} or {01-8b10b encoding} is supported
constant elinkEncoding  : std_logic_vector(1 downto 0) := "01"; -- 00-direct data / 01-8b10b encoding / 10-HDLC encoding 
--
constant packet_size    : std_logic_vector(7 downto 0) := x"0a";

end package elinkInterface_package ;