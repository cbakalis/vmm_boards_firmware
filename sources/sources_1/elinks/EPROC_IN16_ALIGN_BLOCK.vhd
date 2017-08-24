----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    06/27/2014 
--! Module Name:    EPROC_IN16_ALIGN_BLOCK
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee, work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.all;
use work.centralRouter_package.all;

--! continuously aligns 16bit bit-stream to a comma
entity EPROC_IN16_ALIGN_BLOCK is
port ( 
    bitCLKx2    : in  std_logic;
    bitCLKx4    : in  std_logic;
    rst         : in  std_logic;
    bytes       : in  word10b_8array_type; 
    bytes_rdy   : in  std_logic;         
    ------------
    dataOUT     : out std_logic_vector(9 downto 0);
    dataOUTrdy  : out std_logic
    );
end EPROC_IN16_ALIGN_BLOCK;

architecture Behavioral of EPROC_IN16_ALIGN_BLOCK is

signal bytes_r : word10b_8array_type := ((others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),(others=>'0'),(others=>'0')); 
signal send_state : std_logic := '0';
signal dataOUT_s : std_logic_vector(9 downto 0) := (others => '0');
signal dataOUTrdy_s,commaOUTrdy_s, bytes_rdy_r : std_logic := '0';
signal byte_count : std_logic_vector(2 downto 0) := "000";

begin

-------------------------------------------------------------------------------------------
-- clock1
-- input register
-------------------------------------------------------------------------------------------
process(bitCLKx2, rst)
begin
    if rst = '1' then
        bytes_rdy_r <= '0';
    elsif rising_edge(bitCLKx2) then
        if bytes_rdy = '1' then
            bytes_rdy_r <= not bytes_rdy_r;
        else
            bytes_rdy_r <= '0';
        end if;
    end if;
end process;
--
input_latch: process(bitCLKx2)
begin
    if rising_edge(bitCLKx2) then
        if bytes_rdy = '1' then
            bytes_r <= bytes;
        end if;
    end if;
end process;
--
process(bitCLKx2, rst) 
begin
    if rst = '1' then 
        send_state <= '0';
    elsif rising_edge(bitCLKx2) then
        if bytes_rdy = '1' then
            send_state <= '1';
        else
            if byte_count = "111" then 
                send_state <= '0';
            end if;
        end if;
    end if;
end process;
--
process(bitCLKx2) 
begin
    if rising_edge(bitCLKx2) then
        if send_state = '1' then 
            byte_count <= byte_count + 1;
        else
            byte_count <= "000";
        end if;
    end if;
end process;
--



-------------------------------------------------------------------------------------------
-- clock2
-- 
-------------------------------------------------------------------------------------------
process(bitCLKx4)
begin
    if rising_edge(bitCLKx4) then
        if send_state = '1' then
            dataOUTrdy_s    <= not dataOUTrdy_s;
            commaOUTrdy_s   <= '0';
        else
            dataOUTrdy_s    <= '0';
            commaOUTrdy_s   <= not commaOUTrdy_s;
        end if;
    end if;
end process;
--

-------------------------------------------------------------------------------------------
-- 
-------------------------------------------------------------------------------------------
out_select_proc: process(byte_count, bytes_r)
begin
    case (byte_count) is 
        when "000" => dataOUT_s <= bytes_r(0);
        when "001" => dataOUT_s <= bytes_r(1);
        when "010" => dataOUT_s <= bytes_r(2);
        when "011" => dataOUT_s <= bytes_r(3);
        when "100" => dataOUT_s <= bytes_r(4);
        when "101" => dataOUT_s <= bytes_r(5);
        when "110" => dataOUT_s <= bytes_r(6);
        when "111" => dataOUT_s <= bytes_r(7);
        when others =>
    end case;
end process;
--

-------------------------------------------------------------------------------------------
-- dataOUT_s (@bitCLKx4) & dataOUTrdy_s (@bitCLKx4, 2nd clock) can be used when 
-- decoder is moved up
-------------------------------------------------------------------------------------------
process(bitCLKx4)
begin
    if rising_edge(bitCLKx4) then
        if send_state = '1' then
            dataOUT <= dataOUT_s;
        else
            dataOUT <= COMMAp; -- comma
        end if;
    end if;
end process;
--
dataOUTrdy  <= (dataOUTrdy_s and send_state) or (commaOUTrdy_s and (not send_state));
--
end Behavioral;

