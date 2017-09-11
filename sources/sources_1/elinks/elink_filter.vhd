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
-- Module Name: elink_filter - RTL
-- Project Name: MMFE8 
-- Target Devices: Arix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2017.2
-- Description: This module acts as a filter between the elink output and the 
-- elink2UDP input. If the elink header is detected, then it is being discarded.
-- Elink header has the format: 0x-- 0x20/0x21/0x22/0x23/0x83 0x00 0x-- 0xcd 0xab
-- Changelog:
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;

entity elink_filter is
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
    empty_fifo  : out std_logic;
    full_fifo   : out std_logic;
    rd_en_fifo  : in  std_logic;
    dout_fifo   : out std_logic_vector(15 downto 0)
    );
end elink_filter;

architecture RTL of elink_filter is

component fifo48to16
  port (
    clk     : in  std_logic;
    srst    : in  std_logic;
    din     : in  std_logic_vector(15 downto 0);
    wr_en   : in  std_logic;
    rd_en   : in  std_logic;
    dout    : out std_logic_vector(15 downto 0);
    full    : out std_logic;
    empty   : out std_logic
  );
end component;

    signal wr_en_buff   : std_logic := '0';
    signal wait_cnt0    : unsigned(1 downto 0) := (others => '0');
    
    signal empty_buff   : std_logic := '0';
    signal cnt_buff     : unsigned(1 downto 0) := (others => '0');
    
    signal wr_en_fifo   : std_logic := '0';
    signal wr_en_fifo_i : std_logic := '0';
    signal sel_48to16   : std_logic := '0';
    
    type buff_array_type is array (0 to 2) of std_logic_vector(15 downto 0); 
    signal array_buff   : buff_array_type;
    signal rst_buff_cnt : std_logic := '0';
    signal dout_buff    : std_logic_vector(47 downto 0) := (others => '0');
    
    signal wr2fifo_busy : std_logic := '0';
    signal wr_en_buf    : std_logic := '0';
    signal wait_cnt1    : unsigned(1 downto 0) := (others => '0');
    signal din_fifo_buf : std_logic_vector(15 downto 0) := (others => '0');
    signal din_fifo_i   : std_logic_vector(15 downto 0) := (others => '0');
    signal cnt_wr       : unsigned(1 downto 0) := (others => '0');
    signal flag_wr_ack  : std_logic := '0';
    signal buff_done    : std_logic := '0';
    
    signal flush_rx_i   : std_logic := '0';
    signal flush_rx_s   : std_logic := '0';
    signal dbg_filter   : std_logic_vector(2 downto 0);
    
    type stateType_16to48 is (ST_IDLE, ST_CHK, ST_WAIT_FOR_MORE, ST_WRITE_BUFF, ST_DONE, ST_WAIT);
    signal state_prv_16to48     : stateType_16to48 := ST_IDLE; 
    signal state_16to48         : stateType_16to48 := ST_IDLE;
    
    type stateType_48to16 is (ST_IDLE, ST_CHECK, ST_DRIVE, ST_WRITE, ST_WAIT);
    signal state_48to16         : stateType_48to16 := ST_IDLE;
    signal state_prv_48to16     : stateType_48to16 := ST_IDLE;
    
    attribute FSM_ENCODING                  : string;
    attribute FSM_ENCODING of state_16to48  : signal is "ONE_HOT";
    attribute FSM_ENCODING of state_48to16  : signal is "ONE_HOT";
    
    attribute ASYNC_REG                     : string;
    attribute ASYNC_REG of flush_rx_i       : signal is "TRUE";
    attribute ASYNC_REG of flush_rx_s       : signal is "TRUE";

begin

-- FSM that passes the words from the elink FIFO to the buffer
FSM_16to48: process(clk_elink)
begin
    if(rising_edge(clk_elink))then
        if(rst_rx = '1')then
            wr_en_buff      <= '0';
            wr_en_fifo      <= '0';
            sel_48to16      <= '0';
            rd_en_elink     <= '0';
            buff_done       <= '0';
            wait_cnt0       <= (others => '0');
            dbg_filter      <= (others => '0');
            state_16to48    <= ST_IDLE;
        else
            case state_16to48 is

            -- is the elink empty?
            when ST_IDLE =>
                dbg_filter          <= "000";
                wr_en_buff          <= '0';   
                wr_en_fifo          <= '0';
                sel_48to16          <= '0';
                buff_done           <= '0';
                state_prv_16to48    <= ST_IDLE;
                if(empty_elink = '0')then
                    rd_en_elink     <= '1';
                    state_16to48    <= ST_WAIT; -- to ST_CHK
                else
                    rd_en_elink     <= '0';
                    state_16to48    <= ST_IDLE;
                end if;

            -- check the word
            when ST_CHK =>
                dbg_filter          <= "001";
                 -- possibility that this is the header.
                 -- start filling buffer. grant FIFO
                 -- control to other process
                if(din_elink(7 downto 0) = x"20" or din_elink(7 downto 0) = x"21" or din_elink(7 downto 0) = x"22"
                or din_elink(7 downto 0) = x"23" or din_elink(7 downto 0) = x"83")then
                    wr_en_buff      <= '1';
                    sel_48to16      <= '1';
                    wr_en_fifo      <= '0';
                    state_16to48    <= ST_WAIT_FOR_MORE;
                else
                    wr_en_buff      <= '0';
                    sel_48to16      <= '0';
                    wr_en_fifo      <= '1'; -- normal word
                    state_16to48    <= ST_IDLE;
                end if;

            -- stay here for more potential header data
            when ST_WAIT_FOR_MORE =>
                dbg_filter          <= "010";
                wr_en_buff          <= '0';
                state_prv_16to48    <= ST_WAIT_FOR_MORE;
                if(empty_elink = '0')then
                    rd_en_elink     <= '1';
                    state_16to48    <= ST_WAIT; -- to ST_WRITE_BUFF
                else
                    rd_en_elink     <= '0';
                    state_16to48    <= ST_WAIT_FOR_MORE;
                end if;

            -- write to the buffer. the third writing will be the last
            when ST_WRITE_BUFF =>
                dbg_filter          <= "011";
                wr_en_buff          <= '1';
                buff_done           <= '1';
                state_prv_16to48    <= ST_WRITE_BUFF;
                if(buff_done = '1')then
                    state_16to48 <= ST_WAIT; -- to ST_DONE
                else
                    state_16to48 <= ST_WAIT_FOR_MORE;
                end if;

            -- stay here until the others process finishes writing
            when ST_DONE =>
                dbg_filter       <= "100";
                if(empty_buff = '1' and wr2fifo_busy = '0')then
                    state_16to48 <= ST_IDLE;
                else
                    state_16to48 <= ST_DONE;
                end if;

            -- generic state that waits
            when ST_WAIT =>
                dbg_filter      <= "111";
                wr_en_buff      <= '0';
                rd_en_elink     <= '0';
                wr_en_fifo      <= '0';
                wait_cnt0       <= wait_cnt0 + 1;
                if(wait_cnt0 = "11")then
                    case state_prv_16to48 is
                    when ST_IDLE            => state_16to48 <= ST_CHK;
                    when ST_WAIT_FOR_MORE   => state_16to48 <= ST_WRITE_BUFF;
                    when ST_WRITE_BUFF      => state_16to48 <= ST_DONE;
                    when others             => state_16to48 <= ST_IDLE;
                    end case;
                else
                    state_16to48 <= ST_WAIT;
                end if;

            when others =>
                wr_en_buff      <= '0';
                wr_en_fifo      <= '0';
                sel_48to16      <= '0';
                rd_en_elink     <= '0';
                buff_done       <= '0';
                wait_cnt0       <= (others => '0');
                state_16to48    <= ST_IDLE;
            end case;
        end if;
    end if;
end process;

-- buffers three 16-bit words
buff_16to48: process(clk_elink)
begin
    if(rising_edge(clk_elink))then
        if(flag_wr_ack = '1')then
            cnt_buff    <= cnt_buff + 1;
            flag_wr_ack <= '0';
        elsif(wr_en_buff = '1')then
            flag_wr_ack                      <= '1';
            array_buff(to_integer(cnt_buff)) <= din_elink;
        elsif(rst_buff_cnt = '1' or rst_rx = '1')then
            cnt_buff    <= (others => '0'); 
            flag_wr_ack <= '0';
        else
            cnt_buff    <= cnt_buff;
            flag_wr_ack <= flag_wr_ack; 
            array_buff  <= array_buff;
        end if;

        if(cnt_buff = "11")then
            empty_buff <= '0';
        else
            empty_buff <= '1';
        end if;

    end if;
end process;

    dout_buff <= array_buff(0) & array_buff(1) & array_buff(2);

-- FSM that passes the words from the buffer to the 16-bit FIFO,
-- if the word is not the e-link header
FSM_wr2fifo: process(clk_elink)
begin
    if(rising_edge(clk_elink))then
        if(rst_rx = '1')then
            wr_en_buf       <= '0';
            rst_buff_cnt    <= '0';
            wr2fifo_busy    <= '0';
            cnt_wr          <= (others => '0');
            wait_cnt1       <= (others => '0');
            state_48to16    <= ST_IDLE;
        else
            case state_48to16 is

            -- is the elink empty?
            when ST_IDLE =>
                wr_en_buf           <= '0';
                state_prv_48to16    <= ST_IDLE;
                if(empty_buff = '0')then
                    wr2fifo_busy    <= '1';
                    state_48to16    <= ST_WAIT; -- to ST_CHECK
                else
                    wr2fifo_busy    <= '0';
                    state_48to16    <= ST_IDLE;
                end if;

            -- is this the unwanted header?
            when ST_CHECK =>
                rst_buff_cnt      <= '0';
                if(dout_buff(15 downto 0) = x"cdab")then
                    state_48to16 <= ST_IDLE; -- discard
                else
                    state_48to16 <= ST_DRIVE;    
                end if;

            -------------------------
            -- write to the 48to16 fifo in three stages
            when ST_DRIVE =>
                case cnt_wr is
                when "00"   => din_fifo_buf <= dout_buff(47 downto 32);
                when "01"   => din_fifo_buf <= dout_buff(31 downto 16);
                when "10"   => din_fifo_buf <= dout_buff(15 downto 0);
                when others => din_fifo_buf <= (others => '0');
                end case;
                state_prv_48to16    <= ST_DRIVE;
                state_48to16        <= ST_WAIT; -- to ST_WRITE

            -- write to the fifo, and increment the cnt_wr
            when ST_WRITE =>
                wr_en_buf           <= '1';
                state_prv_48to16    <= ST_WRITE;
                if(cnt_wr = "10")then
                    cnt_wr          <= (others => '0');
                    state_48to16    <= ST_IDLE;
                else
                    cnt_wr          <= cnt_wr + 1;
                    state_48to16    <= ST_WAIT; -- to ST_DRIVE
                end if;

            -- generic state that waits
            when ST_WAIT =>
                wait_cnt1      <= wait_cnt1 + 1;
                wr2fifo_busy   <= '1';
                wr_en_buf      <= '0';
                if(wait_cnt1 = "11")then
                    case state_prv_48to16 is
                    when ST_IDLE  => state_48to16 <= ST_CHECK; rst_buff_cnt <= '1';
                    when ST_DRIVE => state_48to16 <= ST_WRITE;
                    when ST_WRITE => state_48to16 <= ST_DRIVE;
                    when others   => state_48to16 <= ST_IDLE; -- error!
                    end case;
                else
                    state_48to16    <= ST_WAIT;
                end if;

            --------------------------
            --------------------------

            when others =>
                wr_en_buf       <= '0';
                rst_buff_cnt    <= '0';
                wr2fifo_busy    <= '0';
                cnt_wr          <= (others => '0');
                wait_cnt1       <= (others => '0');
                state_48to16    <= ST_IDLE;
            end case;
        end if;
    end if;
end process;

mux_fifo: process(clk_elink)
begin
    if(rising_edge(clk_elink))then
        case sel_48to16 is
        when '0'    => wr_en_fifo_i <= wr_en_fifo;  din_fifo_i <= din_elink;
        when '1'    => wr_en_fifo_i <= wr_en_buf;   din_fifo_i <= din_fifo_buf;
        when others => wr_en_fifo_i <= '0';         din_fifo_i <= (others => '0');
        end case;
    end if;
end process;

syncRst: process(clk_elink)
begin
    if(rising_edge(clk_elink))then
        flush_rx_i <= flush_rx;
        flush_rx_s <= flush_rx_i;    
    end if;
end process;

fifo_filter: fifo48to16
  port map(
    clk     => clk_elink,
    srst    => flush_rx_s,
    din     => din_fifo_i,
    wr_en   => wr_en_fifo_i,
    rd_en   => rd_en_fifo,
    dout    => dout_fifo,
    full    => full_fifo,
    empty   => empty_fifo
  );

    dbg_filter_o <= dbg_filter;

end RTL;
