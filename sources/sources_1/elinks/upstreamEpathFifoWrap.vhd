----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    23/06/2015 
--! Module Name:    upstreamEpathFifoWrap
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee,work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;

--! EPATH FIFO 18 bit wide, 1K deep
entity upstreamEpathFifoWrap is
port (   
    rst             : in std_logic;
    fifoFLUSH       : in std_logic;
    ---
    wr_clk          : in std_logic;
    wr_en           : in std_logic;
    din             : in std_logic_vector(17 downto 0);    
    ---
    rd_clk          : in std_logic;
    rd_en           : in std_logic;
    dout            : out std_logic_vector(9 downto 0);
    doutRdy         : out std_logic;
    ---
    full            : out std_logic;
    empty           : out std_logic;
    prog_full       : out std_logic
    );
end upstreamEpathFifoWrap;

architecture Behavioral of upstreamEpathFifoWrap is

----------------------------------
----------------------------------
component fh_epath_fifo2K_18bit_wide -- IP
  port (
    wr_clk                  : in  std_logic;
    rst                     : in  std_logic;
    rd_clk                  : in  std_logic;
    din                     : in  std_logic_vector(17 downto 0);
    wr_en                   : in  std_logic;
    rd_en                   : in  std_logic;
    prog_full_thresh_assert : in  std_logic_vector(9 downto 0);
    prog_full_thresh_negate : in  std_logic_vector(9 downto 0);
    dout                    : out std_logic_vector(17 downto 0);
    full                    : out std_logic;
    almost_full             : out std_logic;
    empty                   : out std_logic;
    prog_full               : out std_logic
  );
end component;
----------------------------------
----------------------------------

signal rd_en_s, empty_efifo, prog_full_s : std_logic;
signal OE, rst_state, byte_cnt,byte_mux_sel,byte_rdy,rd_en1,rd_en2 : std_logic := '0';
signal dout18bit : std_logic_vector(17 downto 0);
signal byte0, byte1 : std_logic_vector(9 downto 0) := "1100000000";
constant comma_byte : std_logic_vector(9 downto 0) := "1100000000";

signal byte0_code,byte1_code,word16_code : std_logic_vector(1 downto 0);
signal empty_efifo1,empty_efifo2,empty_efifo3 : std_logic;

signal wr_en_r  : std_logic := '0';
signal din_r    : std_logic_vector(17 downto 0) := "110000000000000000";

begin

-------------------------------------------------------------------------------------------
-- write pipeline
-------------------------------------------------------------------------------------------
process(wr_clk)
begin
	if wr_clk'event and wr_clk = '1' then       
        wr_en_r   <= wr_en;
        din_r     <= din;
	end if;
end process;
--
-------------------------------------------------------------------------------------------
-- FIFO - ip
-------------------------------------------------------------------------------------------
epathFIFO: fh_epath_fifo2K_18bit_wide
port map(
    wr_clk      => wr_clk, 
    rst         => fifoFLUSH,
    rd_clk      => rd_clk, 
    din         => din_r,
    wr_en       => wr_en_r,
    rd_en       => rd_en_s,
    dout        => dout18bit, --18 bit
    full        => full,
    almost_full => open, --almost_full,
    empty       => empty_efifo, 
    prog_full   => prog_full_s, -- 1008/960 from 1024
    prog_full_thresh_assert  => std_logic_vector(to_unsigned(990, 10)),
    prog_full_thresh_negate => std_logic_vector(to_unsigned(980, 10))
    );  
--
-------------------------------------------------------------------------------------------
-- re pulse
-------------------------------------------------------------------------------------------
process(rd_clk,rst)
begin
	if rst = '1' then
        byte_cnt <= '0';
	elsif rd_clk'event and rd_clk = '1' then       
        if rd_en = '1' then -- 1 clk trigger 
            byte_cnt <= not byte_cnt;
        end if;
	end if;
end process;
--
rd_en_s <= rd_en and (not byte_cnt) and (not empty_efifo); -- only when byte_cnt = 0
--
word16_code <= dout18bit(17 downto 16);
--
process(word16_code,empty_efifo1,empty_efifo2)
begin
    if empty_efifo1 = '1' then
        byte0_code <= "11";
        byte1_code <= "11";
    else
        if word16_code = "10" then -- start of message
            byte0_code <= "11";
            byte1_code <= "10";
        elsif word16_code = "01" then -- end of message
            byte0_code <= "01";
            byte1_code <= "11";
        else -- "00" data
            byte0_code <= empty_efifo1 & empty_efifo1;
            byte1_code <= empty_efifo2 & empty_efifo2;
        end if;
    end if;
end process;
--
byte0 <= byte0_code & dout18bit(15 downto 8);
byte1 <= byte1_code & dout18bit(7 downto 0);
--byte0 <= byte0_code & dout18bit(7 downto 0);
--byte1 <= byte1_code & dout18bit(15 downto 8);
--
process(byte_cnt,byte0,byte1)
begin
	if byte_cnt = '1' then  
        dout  <= byte0;
    else 
        dout  <= byte1;
	end if;
end process;
--
--
process(rd_clk)
begin
	if rd_clk'event and rd_clk = '1' then  
        byte_rdy <= byte_cnt;
	end if;
end process;
--

-------------------------------------------------------------------------------------------
-- re pulse
-------------------------------------------------------------------------------------------
--
process(rd_clk)
begin
	if rd_clk'event and rd_clk = '1' then  
        doutRdy <= rd_en;   
        empty_efifo1 <= empty_efifo;
        empty_efifo2 <= empty_efifo1;  
        empty_efifo3 <= empty_efifo2; 
	end if;
end process;
--
empty <= empty_efifo;-- rd_clk domain
--
process(rd_clk)
begin
	if rd_clk'event and rd_clk = '1' then
        rst_state   <= rst or fifoFLUSH; 
        OE          <= not rst_state;      
	end if;
end process;
--
prog_full   <= prog_full_s and OE;
--


end Behavioral;

