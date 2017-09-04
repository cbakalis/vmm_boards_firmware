----------------------------------------------------------------------------------
-- Company: NTU ATHNENS - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch)
-- 
-- Copyright Notice/Copying Permission:
--    Copyright 2017 Christos Bakalis
--
--    This file is part of NTUA-BNL_VMM_firmware.
--
--    NTUA-BNL_VMM_firmware is free software: you can redistribute it and/or modify
--    it under the terms of the GNU General Public License as published by
--    the Free Software Foundation, either version 3 of the License, or
--    (at your option) any later version.
--
--    NTUA-BNL_VMM_firmware is distributed in the hope that it will be useful,
--    but WITHOUT ANY WARRANTY; without even the implied warranty of
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--    GNU General Public License for more details.
--
--    You should have received a copy of the GNU General Public License
--    along with NTUA-BNL_VMM_firmware.  If not, see <http://www.gnu.org/licenses/>.
-- 
-- Create Date: 30.08.2017 11:39:21
-- Design Name: 
-- Module Name: elink2UDP_wrapper - RTL
-- Project Name: MMFE8 
-- Target Devices: Arix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2017.2
-- Description: Wrapper for the modules that implement the elink-to-UDP interface.
-- Four main components: One (elink_filter) that detects and discards any e-link
-- related overhead, one (roc2udp) that detects the ROC SOP and EOP and packets
-- one ROC event into a single UDP packet before forwarding it to elink2udp, 
-- one (simple_mode) that forwards all elink data to the UDP, and one final module
-- (elink2udp) that forwards the data to the UDP/Ethernet blocks.
-- 
-- Changelog:
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use work.axi.all;
use work.ipv4_types.all;
use work.arp_types.all;

entity elink2UDP_wrapper is
Port(
    ---------------------------
    ---- General Interface ----
    clk_elink       : in  std_logic;
    clk_udp         : in  std_logic;
    rst_rx          : in  std_logic;
    flush_rx        : in  std_logic;
    enable_filter   : in  std_logic;
    enable_roc2udp  : in  std_logic;
    error_led       : out std_logic; -- indicating the data flow is too high
    ---------------------------
    ---- Elink Interface ------
    empty_elink     : in  std_logic;
    half_full_elink : in  std_logic;
    full_elink      : in  std_logic;
    rd_en_elink     : out std_logic;
    din_elink       : in  std_logic_vector(15 downto 0);
    ---------------------------
    ---- UDP Interface --------
    udp_tx_dout_rdy : in std_logic;
    udp_tx_start    : out std_logic;
    udp_txi         : out udp_tx_type
    );
end elink2UDP_wrapper;

architecture RTL of elink2UDP_wrapper is

component elink_filter
Port(
    ---------------------------
    ---- General Interface ----
    clk_elink    : in  std_logic;
    rst_rx       : in  std_logic;
    flush_rx     : in  std_logic;
    dbg_filter_o : out std_logic_vector(2 downto 0);
    ---------------------------
    ---- Elink Interface ------
    empty_elink  : in  std_logic;
    rd_en_elink  : out std_logic;
    din_elink    : in  std_logic_vector(15 downto 0);
    ---------------------------
    --- elink2UDP Interface ---
    empty_fifo  : out  std_logic;
    full_fifo   : out  std_logic;
    rd_en_fifo  : in   std_logic;
    dout_fifo   : out  std_logic_vector(15 downto 0)
    );
end component;

component roc2udp
Generic (real_roc : std_logic); -- set to '1' if the real ROC is sending data
Port(
    ---------------------------
    ---- General Interface ----
    clk_elink   : in  std_logic;
    rst_rx      : in  std_logic;
    fsm_roc_o   : out std_logic_vector(3 downto 0);
    ---------------------------
    -- Elink/Filter Interface -
    empty_fifo  : in  std_logic;
    rd_en_fifo  : out std_logic;
    din_fifo    : in  std_logic_vector(15 downto 0);
    ---------------------------
    --- elink2udp Interface ---
    full_len    : in  std_logic;
    full_daq    : in  std_logic;
    empty_len   : in  std_logic;
    udp_tx_busy : in  std_logic;
    flush_daq   : out std_logic;
    wr_en_len   : out std_logic;
    wr_en_daq   : out std_logic;
    dout_len    : out std_logic_vector(15 downto 0);
    dout_daq    : out std_logic_vector(15 downto 0)
    );
end component;

component simple_mode
Port(
    ---------------------------
    ---- General Interface ----
    clk_elink   : in  std_logic;
    rst_rx      : in  std_logic;
    ---------------------------
    -- Elink/Filter Interface -
    empty_fifo  : in  std_logic;
    rd_en_fifo  : out std_logic;
    din_fifo    : in  std_logic_vector(15 downto 0);
    ---------------------------
    --- elink2udp Interface ---
    wr_en_len   : out std_logic;
    wr_en_daq   : out std_logic;
    dout_len    : out std_logic_vector(15 downto 0);
    dout_daq    : out std_logic_vector(15 downto 0)
    );
end component;

component elink2udp
Port(
    ---------------------------
    ---- General Interface ----
    clk_elink       : in  std_logic;
    clk_udp         : in  std_logic;
    rst_rx          : in  std_logic;
    rst_rx_125      : out std_logic;
    flush_rx        : in  std_logic;
    dbg_udp_o       : out std_logic_vector(3 downto 0);
    ---------------------------
    ---- roc2udp Interface ----
    flush_daq       : in  std_logic;
    wr_en_len       : in  std_logic;
    wr_en_daq       : in  std_logic;
    din_len         : in  std_logic_vector(15 downto 0);
    din_daq         : in  std_logic_vector(15 downto 0);
    full_len        : out std_logic;
    full_daq        : out std_logic;
    empty_len       : out std_logic;
    udp_tx_busy     : out std_logic;
    ---------------------------
    ---- UDP Interface --------
    udp_tx_dout_rdy : in std_logic;
    udp_tx_start    : out std_logic;
    udp_txi         : out udp_tx_type
    );
end component;

COMPONENT ila_rx

PORT (
    clk    : IN STD_LOGIC;
    probe0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0)
);
END COMPONENT  ;

    signal rst_rx_filter        : std_logic := '0';
    signal rd_en_elink_filter   : std_logic := '0';
    signal empty_filter         : std_logic := '0';
    signal full_filter          : std_logic := '0';
    signal rd_en_filter         : std_logic := '0';
    signal dout_filter          : std_logic_vector(15 downto 0) := (others => '0');

    signal din_roc              : std_logic_vector(15 downto 0) := (others => '0');
    signal rst_roc2udp          : std_logic := '0';
    signal empty_roc            : std_logic := '0';
    signal rd_en_roc            : std_logic := '0';
    signal full_len             : std_logic := '0';
    signal empty_len            : std_logic := '0';
    signal udp_tx_busy          : std_logic := '0';
    signal full_daq             : std_logic := '0';
    signal flush_daq            : std_logic := '0';
    signal wr_len_roc           : std_logic := '0';
    signal wr_daq_roc           : std_logic := '0';
    signal dout_len_roc         : std_logic_vector(15 downto 0) := (others => '0');
    signal dout_daq_roc         : std_logic_vector(15 downto 0) := (others => '0');
    
    signal rst_simple           : std_logic := '0';
    signal empty_simple         : std_logic := '0';
    signal din_simple           : std_logic_vector(15 downto 0) := (others => '0');
    signal rd_en_simple         : std_logic := '0';
    signal wr_len_simple        : std_logic := '0';
    signal wr_daq_simple        : std_logic := '0';
    signal dout_len_simple      : std_logic_vector(15 downto 0) := (others => '0');
    signal dout_daq_simple      : std_logic_vector(15 downto 0) := (others => '0');

    signal rst_rx_125           : std_logic := '0';

    signal wr_en_len            : std_logic := '0';
    signal wr_en_daq            : std_logic := '0';
    signal din_daq              : std_logic_vector(15 downto 0) := (others => '0');
    signal din_len              : std_logic_vector(15 downto 0) := (others => '0');
    
    signal filter_full          : std_logic := '0';
    signal dbg_fsm_filter       : std_logic_vector(2 downto 0) := (others => '0');
    signal dbg_fsm_roc          : std_logic_vector(3 downto 0) := (others => '0');
    signal dbg_fsm_udp          : std_logic_vector(3 downto 0) := (others => '0');

    signal error_latched        : std_logic := '0';
    signal error_i              : std_logic := '0';
    signal error_s              : std_logic := '0';

    attribute ASYNC_REG             : string;
    attribute ASYNC_REG of error_i  : signal is "TRUE";
    attribute ASYNC_REG of error_s  : signal is "TRUE";
    
--    attribute mark_debug                    : string;
--    attribute mark_debug of full_daq        : signal is "TRUE";
--    attribute mark_debug of full_len        : signal is "TRUE";
--    attribute mark_debug of full_elink      : signal is "TRUE";
--    attribute mark_debug of filter_full     : signal is "TRUE";
--    attribute mark_debug of dbg_fsm_filter  : signal is "TRUE";
--    attribute mark_debug of dbg_fsm_roc     : signal is "TRUE";
--    attribute mark_debug of dbg_fsm_udp     : signal is "TRUE";
--    attribute mark_debug of flush_daq       : signal is "TRUE";
--    attribute mark_debug of wr_en_len       : signal is "TRUE";
--    attribute mark_debug of wr_en_daq       : signal is "TRUE";
--    attribute mark_debug of empty_len       : signal is "TRUE";
--    attribute mark_debug of rd_en_roc       : signal is "TRUE";
        
begin

elink_filter_inst: elink_filter
Port Map(
    ---------------------------
    ---- General Interface ----
    clk_elink    => clk_elink,
    rst_rx       => rst_rx_filter,
    flush_rx     => flush_rx,
    dbg_filter_o => dbg_fsm_filter,
    ---------------------------
    ---- Elink Interface ------
    empty_elink  => empty_elink,
    rd_en_elink  => rd_en_elink_filter,
    din_elink    => din_elink,
    ---------------------------
    --- elink2UDP Interface ---
    empty_fifo  => empty_filter,
    full_fifo   => full_filter,
    rd_en_fifo  => rd_en_filter,
    dout_fifo   => dout_filter
    );

    rst_rx_filter <= rst_rx or not enable_filter;

roc2udp_inst: roc2udp
Generic Map(real_roc => '0') -- set to zero if receiving data from NTUA/BNL firmware
Port Map(
    ---------------------------
    ---- General Interface ----
    clk_elink   => clk_elink,
    rst_rx      => rst_roc2udp,
    fsm_roc_o   => dbg_fsm_roc,
    ---------------------------
    -- Elink/Filter Interface -
    empty_fifo  => empty_roc,   -- from filter or elink
    rd_en_fifo  => rd_en_roc,   -- to filter or elink
    din_fifo    => din_roc,     -- from filter or elink
    ---------------------------
    --- elink2udp Interface ---
    full_len    => full_len,
    full_daq    => full_daq,
    empty_len   => empty_len,
    udp_tx_busy => udp_tx_busy,
    flush_daq   => flush_daq,
    wr_en_len   => wr_len_roc,
    wr_en_daq   => wr_daq_roc,
    dout_len    => dout_len_roc,
    dout_daq    => dout_daq_roc
    );

    rst_roc2udp <= rst_rx or not enable_roc2udp;

simpleMode_inst: simple_mode
Port Map(
    ---------------------------
    ---- General Interface ----
    clk_elink    => clk_elink,
    rst_rx       => rst_simple,
    ---------------------------
    -- Elink/Filter Interface -
    empty_fifo  => empty_simple,   -- from filter or elink
    rd_en_fifo  => rd_en_simple,    -- to filter or elink
    din_fifo    => din_simple,     -- from filter or elink
    ---------------------------
    --- elink2udp Interface ---
    wr_en_len   => wr_len_simple,
    wr_en_daq   => wr_daq_simple,
    dout_len    => dout_len_simple,
    dout_daq    => dout_daq_simple
    );

    rst_simple <= rst_rx or enable_roc2udp;

elink2udp_inst: elink2udp
Port Map(
    ---------------------------
    ---- General Interface ----
    clk_elink   => clk_elink,
    clk_udp     => clk_udp,
    rst_rx      => rst_rx,
    rst_rx_125  => rst_rx_125,
    flush_rx    => flush_rx,
    dbg_udp_o   => dbg_fsm_udp,
    ---------------------------
    ---- roc2udp Interface ----
    flush_daq   => flush_daq,
    wr_en_len   => wr_en_len,
    wr_en_daq   => wr_en_daq,
    din_len     => din_len,
    din_daq     => din_daq,
    full_len    => full_len,
    full_daq    => full_daq,
    empty_len   => empty_len,
    udp_tx_busy => udp_tx_busy,
    ---------------------------
    ---- UDP Interface --------
    udp_tx_dout_rdy => udp_tx_dout_rdy,
    udp_tx_start    => udp_tx_start,
    udp_txi         => udp_txi
    );

------------------------
--- auxilliary processes
------------------------

-- mux that chooses between filter or elink
muxFilter_proc: process(empty_elink, din_elink, rd_en_roc, din_elink, rd_en_simple,
                  empty_filter, dout_filter, rd_en_elink_filter, enable_filter)
begin
    case enable_filter is
    when '0'    => 
        empty_roc       <= empty_elink; empty_simple    <= empty_elink; 
        din_roc         <= din_elink;   din_simple      <= din_elink; 
        rd_en_elink     <= rd_en_roc or rd_en_simple;
        rd_en_filter    <= '0';
    when '1'    =>
        empty_roc       <= empty_filter; empty_simple   <= empty_filter; 
        din_roc         <= dout_filter; din_simple      <= dout_filter; 
        rd_en_elink     <= rd_en_elink_filter;
        rd_en_filter    <= rd_en_roc or rd_en_simple;
    when others => 
        empty_roc       <= '0';             empty_simple <= '0'; 
        din_roc         <= (others => '0'); din_simple   <= (others => '0'); 
        rd_en_elink     <= '0';
    end case;
end process;

-- mux that chooses between the data paths
muxROC_proc: process(dout_len_simple, dout_daq_simple, wr_len_simple, wr_daq_simple,
                  dout_len_roc, dout_daq_roc, wr_len_roc, wr_daq_roc, enable_roc2udp)
begin
    case enable_roc2udp is
    when '0'    => din_len <= dout_len_simple;  din_daq <= dout_daq_simple; wr_en_len <= wr_len_simple; wr_en_daq <= wr_daq_simple;
    when '1'    => din_len <= dout_len_roc;     din_daq <= dout_daq_roc;    wr_en_len <= wr_len_roc;    wr_en_daq <= wr_daq_roc;
    when others => din_len <= (others => '0');  din_daq <= (others => '0'); wr_en_len <= '0';           wr_en_daq <= '0';
    end case;
end process;

-- simple error logic. LEDs will blink if a FIFO becomes full
error_proc: process(clk_udp)
begin
    if(rising_edge(clk_udp))then
        if(rst_rx_125 = '1')then
            error_latched   <= '0';
            error_led       <= '0';
        else
            case error_latched is
            when '0'    => if(error_s = '1')then error_latched <= '1'; else error_latched <= '0'; end if;
            when '1'    => error_latched <= '1'; error_led <= '1'; -- stay here until reset
            when others => error_latched <= '0'; error_led <= '0';
            end case;
        end if;

    -- sync all status signals
        error_i <= full_daq or full_len or (full_filter and enable_filter) or full_elink; -- or flush_daq;
        error_s <= error_i;
    end if;
end process;

    filter_full <= full_filter and enable_filter;

--ila_rx_inst: ila_rx
--PORT MAP (
--  clk                    => clk_elink,
--  probe0(0)              => full_daq,
--  probe0(1)              => full_len,
--  probe0(2)              => full_elink,
--  probe0(3)              => filter_full,
--  probe0(6 downto 4)     => dbg_fsm_filter,
--  probe0(10 downto 7)    => dbg_fsm_roc,
--  probe0(14 downto 11)   => dbg_fsm_udp,
--  probe0(15)             => flush_daq,
--  probe0(16)             => wr_en_len,
--  probe0(17)             => wr_en_daq,
--  probe0(18)             => empty_len,
--  probe0(19)             => rd_en_roc,
--  probe0(31 downto 20) => (others => '0')
--);

end RTL;
