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
use ieee.STD_LOGIC_1164.ALL;
use ieee.STD_LOGIC_UNSIGNED.ALL;
use work.all;
use work.centralRouter_package.all;

--! continuously aligns 4bit bit-stream to two commas
entity EPROC_IN4_ALIGN_BLOCK is
Port ( 
    bitCLKx2    : in  std_logic;
    bitCLKx4    : in  std_logic;
    rst         : in  std_logic;
    bytes       : in  word10b_2array_type; -- 8b10b encoded
    bytes_rdy   : in  std_logic;
    ------------
    dataOUT     : out std_logic_vector(9 downto 0);
    dataOUTrdy  : out std_logic;
    ------------
    busyOut     : out std_logic
    );
end EPROC_IN4_ALIGN_BLOCK;

architecture Behavioral of EPROC_IN4_ALIGN_BLOCK is

signal bytes_rdy_enabled : std_logic;
signal bytes_r, bytes_c3 : word10b_2array_type := ((others=>'0'),(others=>'0')); 
signal bytes_rdy_r, send_state : std_logic := '0';
signal dataOUT_s : std_logic_vector(9 downto 0) := (others => '0');
signal dataOUTrdy_s, dataOUTrdy_c3, dataOUTrdy_s1, bytes_rdy_s : std_logic := '0';
signal byte_count, byte_count_c3 : std_logic_vector(0 downto 0) := "0";
signal dataOUT_s_fe : std_logic_vector(9 downto 0);

begin

-------------------------------------------------------------------------------------------
-- clock1
-- input register
-------------------------------------------------------------------------------------------
bytes_rdy_enabled <= bytes_rdy;
--
process(bitCLKx2, rst)
begin
    if rst = '1' then
        bytes_rdy_s <= '0';
    elsif bitCLKx2'event and bitCLKx2 = '1' then
        if bytes_rdy_enabled = '1' then
            bytes_rdy_s <= not bytes_rdy_s;
        else
            bytes_rdy_s <= '0';
        end if;
    end if;
end process;
--
input_latch: process(bitCLKx2, rst)
begin
    if rst = '1' then
        bytes_r <= ((others=>'0'),(others=>'0')); 
    elsif bitCLKx2'event and bitCLKx2 = '1' then
        if bytes_rdy_enabled = '1' then
            bytes_r <= bytes;
        end if;
    end if;
end process;
--
bytes_rdy_r <= bytes_rdy_s and bytes_rdy_enabled;
--
process(bitCLKx2) 
begin
    if bitCLKx2'event and bitCLKx2 = '1' then
        if bytes_rdy_r = '1' then
            byte_count <= "0";
        else
            if send_state = '1' then 
                byte_count <= byte_count + 1;
            else
                byte_count <= "0";
            end if;
        end if;
    end if;
end process;
--
--
process(bitCLKx2, rst) 
begin
    if rst = '1' then
        send_state <= '0';
    elsif bitCLKx2'event and bitCLKx2 = '1' then
        if bytes_rdy_r = '1' then
            send_state <= '1';
        else
            if byte_count = "1" then 
                send_state <= '0';
            end if;
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
    if bitCLKx4'event and bitCLKx4 = '1' then
        if send_state = '1' then
            dataOUTrdy_s <= not dataOUTrdy_s;
        else
            dataOUTrdy_s <= '0';
        end if;
    end if;
end process;
--

-------------------------------------------------------------------------------------------
-- clock3*
-- bitCLKx2 -> bitCLKx4
-------------------------------------------------------------------------------------------
process(bitCLKx4)
begin
    if bitCLKx4'event and bitCLKx4 = '1' then
        bytes_c3      <= bytes_r;
        dataOUTrdy_c3 <= dataOUTrdy_s;
        byte_count_c3 <= byte_count;
    end if;
end process;
--
out_select_proc: process(byte_count_c3, bytes_c3)
begin
    case (byte_count_c3) is 
        when "0" => dataOUT_s <= bytes_c3(0);
        when "1" => dataOUT_s <= bytes_c3(1);
        when others =>
    end case;
end process;
--

-------------------------------------------------------------------------------------------
-- clock4*
-- 
-------------------------------------------------------------------------------------------
process(bitCLKx4)
begin
    if bitCLKx4'event and bitCLKx4 = '1' then
        dataOUTrdy_s1 <= dataOUTrdy_c3;
    end if;
end process;
--
dec_8b10: entity work.dec_8b10_wrap 
port map(
	RESET         => rst,
	RBYTECLK      => bitCLKx4,
	ABCDEIFGHJ_IN => dataOUT_s,
	HGFEDCBA      => dataOUT_s_fe(7 downto 0),
	ISK           => dataOUT_s_fe(9 downto 8),
	BUSY          => busyOut
);
--
process(bitCLKx4)
begin
    if bitCLKx4'event and bitCLKx4 = '1' then
        dataOUT     <= dataOUT_s_fe;
        --dataOUTrdy  <= dataOUTrdy_s1;
    end if;
end process;
--
dataOUTrdy  <= dataOUTrdy_s1;
--
end Behavioral;

