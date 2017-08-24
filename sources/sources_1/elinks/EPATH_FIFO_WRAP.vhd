----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    09/14/2014 
--! Module Name:    EPATH_FIFO_WRAP
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.all;

--! EPATH FIFO 16 bit wide, 1K deep
entity EPATH_FIFO_WRAP is
port (   
    rst         : in std_logic;
    fifoFlush   : in std_logic;
    wr_clk      : in std_logic;
    rd_clk      : in std_logic;
    din         : in std_logic_vector(15 downto 0);
    wr_en       : in std_logic;
    rd_en       : in std_logic;
    dout        : out std_logic_vector(15 downto 0);
    almost_full : out std_logic;
    fifo_empty  : out std_logic;
    prog_full   : out std_logic
    );
end EPATH_FIFO_WRAP;

architecture Behavioral of EPATH_FIFO_WRAP is

----------------------------------
----------------------------------
component EPATH_FIFO -- IP
port (
    wr_clk      : in std_logic;
    rst         : in std_logic;
    rd_clk      : in std_logic;
    din         : in std_logic_vector(15 downto 0);
    wr_en       : in std_logic;
    rd_en       : in std_logic;
    dout        : out std_logic_vector(15 downto 0);
    full        : out std_logic;
    empty       : out std_logic;
    prog_full   : out std_logic;
    prog_empty  : out std_logic;
    prog_empty_thresh   : in std_logic_vector(9 downto 0);
    prog_full_thresh    : in std_logic_vector(9 downto 0)
  );
end component;
----------------------------------
----------------------------------

signal rd_en_s, wr_en_s : std_logic;
signal prog_full_s, full_s, empty_s, prog_empty_s : std_logic;
signal rst_state : std_logic;

begin

--
rd_en_s <= rd_en and (not rst_state);
wr_en_s <= wr_en and (not rst_state);
--
EPATH_FIFO_INST: EPATH_FIFO 
PORT MAP (
	wr_clk     => wr_clk, 
	rst        => fifoFlush,
	rd_clk     => rd_clk, 
	din        => din,
	wr_en      => wr_en_s,
	rd_en      => rd_en_s,
	dout       => dout,
	full       => full_s,
	empty      => empty_s,
	prog_full  => prog_full_s,
	prog_empty => prog_empty_s,
	prog_full_thresh  => std_logic_vector(to_unsigned(512, 10)),
    prog_empty_thresh => std_logic_vector(to_unsigned(1010, 10))
);
--
rst_state   <= rst or (full_s and empty_s);
fifo_empty  <= empty_s;
--
process(rd_clk)
begin
	if rising_edge(rd_clk) then
        prog_full <= prog_full_s and (not rst_state);
	end if;
end process;
--
process(wr_clk)
begin
	if rising_edge(wr_clk) then
        almost_full <= not prog_empty_s;
	end if;
end process;
--

end Behavioral;

