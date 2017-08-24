----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    06/22/2014 
--! Module Name:    EPROC_IN4_ALIGN_BLOCK
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee, work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.all;
use work.centralRouter_package.all;

--! continuously aligns 4bit bit-stream to two commas
entity EPROC_IN4_ALIGN_BLOCK is
port ( 
    bitCLK      : in  std_logic;
    rst         : in  std_logic;
    bytes       : in  word10b_2array_type; -- 8b10b encoded
    bytes_rdy   : in  std_logic;
    ------------
    dataOUT     : out std_logic_vector(9 downto 0);
    dataOUTrdy  : out std_logic
    );
end EPROC_IN4_ALIGN_BLOCK;

architecture Behavioral of EPROC_IN4_ALIGN_BLOCK is

signal byte_in,byte_1 : std_logic_vector(9 downto 0) := (others => '0');
signal byte_in_rdy,byte_1_rdy : std_logic := '0';

begin

process(bitCLK)
begin
    if rising_edge(bitCLK) then
        if bytes_rdy = '1' then
            byte_1       <= bytes(1);
            byte_1_rdy   <= '1';
        else
            byte_1_rdy   <= '0';
        end if;
    end if;
end process;
--
process(bitCLK)
begin
    if rising_edge(bitCLK) then
        if bytes_rdy = '1' then
            byte_in       <= bytes(0);
            byte_in_rdy   <= '1';
        elsif byte_1_rdy = '1' then 
            byte_in       <= byte_1;
            byte_in_rdy   <= '1';
        else
            byte_in_rdy   <= '0';
        end if;
    end if;
end process;
--
dataOUT     <= byte_in;
dataOUTrdy  <= byte_in_rdy; 
----
end Behavioral;

