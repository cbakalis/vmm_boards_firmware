----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    08/12/2014 
--! Module Name:    reg8to16bit
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library work, IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

--! width matching register 8 bit to 16 bit
entity reg8to16bit is
Port ( 
    rst     : IN STD_LOGIC;
    clk     : IN STD_LOGIC;
    flush   : IN STD_LOGIC;
    din     : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    din_rdy : IN STD_LOGIC;
    -----
    flushed  : OUT STD_LOGIC;
    dout     : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    dout_rdy : OUT STD_LOGIC
    );
end reg8to16bit;

architecture Behavioral of reg8to16bit is

----------------------------------
----------------------------------
component pulse_pdxx_pwxx
generic( 
	pd : integer := 0;
	pw : integer := 1);
port(
    clk         : in   std_logic;
    trigger     : in   std_logic;
    pulseout    : out  std_logic
	);
end component pulse_pdxx_pwxx;
----------------------------------
----------------------------------

----
signal dout16bit_s1, dout16bit_s2 : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal count, ce, count_1CLK_pulse_valid, flush_s, count_rst, flashed_delayed, count_trig : STD_LOGIC := '0';
signal count_1CLK_pulse_s : STD_LOGIC;
----

begin
-----
--
process(clk)
begin
    if clk'event and clk = '1' then
        if rst = '1' then
            ce <= '1';
        end if;
    end if;
end process;
---
-----
flush_s <= flush and (not count); -- when count is '0', flush the register

--
process(clk)
begin
    if clk'event and clk = '1' then
        flushed <= flush_s;
    end if;
end process;
---

process(flush_s, clk)
begin
    if flush_s = '1' then
        flashed_delayed <= '1';
    elsif clk'event and clk = '1' then
        flashed_delayed <= flush_s;
    end if;
end process;
---
--
process(clk)
begin
    if clk'event and clk = '1' then
        if din_rdy = '1' then
            dout16bit_s1 <= din;
            dout16bit_s2 <= dout16bit_s1;
        end if;
    end if;
end process;
---
process(flashed_delayed, dout16bit_s1, dout16bit_s2)
begin
    if flashed_delayed = '1' then 
        dout <= "00000000" & dout16bit_s1;
    else
        dout <= dout16bit_s1 & dout16bit_s2;
    end if;
end process;
---
---
count_rst <= rst; -- or flush_s;
---
process(count_rst, clk)
begin
    if count_rst = '1' then
        count <= '1';
    elsif clk'event and clk = '1' then
        if flush_s = '1' then
            count <= '1';
        elsif din_rdy = '1' then
            count <= not count;
        end if;
    end if;
end process;
---
count_trig <= count;-- and (not flashed_delayed) and (not rst) and ce;
count_1CLK_pulse: pulse_pdxx_pwxx PORT MAP(clk, count_trig, count_1CLK_pulse_s);
--count_1CLK_pulse_valid <= count_1CLK_pulse_s and (not flashed_delayed) and (not rst) and ce;
count_1CLK_pulse_valid <= count_1CLK_pulse_s and (not rst) and ce; --and (not flashed_delayed)
---
dout_rdy <= count_1CLK_pulse_valid; -- or flush_s;
---

end Behavioral;




