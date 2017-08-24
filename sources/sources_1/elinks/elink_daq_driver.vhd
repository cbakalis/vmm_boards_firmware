--------------------------------------------------------------------------------------
-- Company: NTUA - BNL
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
-- Create Date: 18.07.2017 16:32:39
-- Design Name: 
-- Module Name: elink_daq_driver - RTL
-- Project Name: 
-- Target Devices: 
-- Target Devices: Artix7 xc7a200t-2fbg484 & xc7a200t-3fbg484 
-- Tool Versions: Vivado 2017.2 
-- 
-- Changelog:
-- 22.08.2017 Adapted the module to level0 readout for VMM3 and ROC format.
-- Consulted: "ROC Requirements for the NSW VMM3 readout ASIC and the NSW Readout 
-- Controller ASIC Design Review Report" - 10/05/2016 AND "ATLAS NSW Electronics 
-- Specification Component or Facility Name: ROC The Read Out Controller" - 11/24/2016
-- (Christos Bakalis).
--
--------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity elink_daq_driver is
    Port(
        ---------------------------
        ---- general interface ---- 
        clk_in      : in  std_logic;
        fifo_flush  : in  std_logic;
        driver_ena  : in  std_logic;
        ---------------------------
        ------- pf interface ------
        din_daq     : in  std_logic_vector(15 downto 0);
        wr_en_daq   : in  std_logic;
        trigger_cnt : in  std_logic_vector(15 downto 0);
        wr_en_safe  : in  std_logic;
        vmm_id      : in  std_logic_vector(2 downto 0);
        last        : in  std_logic;
        busy        : out std_logic;
        ---------------------------
        ------ elink inteface -----
        empty_elink : in  std_logic;
        wr_en_elink : out std_logic;
        dout_elink  : out std_logic_vector(17 downto 0)
    );
end elink_daq_driver;

architecture RTL of elink_daq_driver is

component DAQelinkFIFO
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

    signal rd_en            : std_logic := '0';
    signal dout_fifo        : std_logic_vector(15 downto 0) := (others => '0');
    signal data_out         : std_logic_vector(15 downto 0) := (others => '0');
    signal fifo_full        : std_logic := '0';
    signal fifo_empty       : std_logic := '0';
    signal packet_part      : unsigned(2 downto 0) := (others => '0');    
    signal hit_data_prv     : std_logic_vector(31 downto 0) := (others => '0');
    signal chunk_flag       : std_logic := '1';
    signal ena_cnt          : std_logic := '0';
    signal vmm_bitmask_miss : std_logic_vector(7 downto 0) := (others => '0');
    signal len_cnt          : std_logic_vector(9 downto 0) := (others => '0');
    signal len_cnt_ug       : unsigned(9 downto 0) := (others => '0');
    signal wait_cnt         : unsigned(1 downto 0) := (others => '0');
    signal wr_en_daq_i      : std_logic := '0';
    signal din_daq_i        : std_logic_vector(15 downto 0) := (others => '0');
    signal empty_elink_i    : std_logic := '0';
    signal empty_elink_s    : std_logic := '0';

    -- E-LINK EOP and SOP
    signal elink_flag       : std_logic_vector(1 downto 0) := (others => '0');
    constant SOP            : std_logic_vector(1 downto 0) := "10";
    constant MOP            : std_logic_vector(1 downto 0) := "00";
    constant EOP            : std_logic_vector(1 downto 0) := "01";

    -- ROC EOP and SOP. Some ambiguity has occurred regarding the correct SOP, due to a discrepancy between the two ROC docs.
    -- Currently using K28.1 as SOP as indicated by one of the two ROC docs. The other option is to use K28.4.
    constant ROC_SOP        : std_logic_vector(7 downto 0) := "00111100"; -- K28.1
    --constant ROC_SOP        : std_logic_vector(7 downto 0) := "10011100"; -- K28.4 
    constant ROC_EOP        : std_logic_vector(7 downto 0) := "11011100"; -- K28.6

    -- state signals and attributes
    type stateType is (ST_IDLE, ST_SOP_0, ST_SOP_1, ST_CHANGE_FLG, ST_WR_HDR_0, ST_WR_HDR_1, ST_CHK_FIFO, ST_REG_DATA_0, ST_REG_DATA_1,
                       ST_CHK_CHUNK_FLG, ST_WR_DATA_0, ST_WR_DATA_1, ST_TRL_0, ST_TRL_1, ST_TRL_2, ST_EOP_0, ST_EOP_1,
                       ST_WAIT, ST_DONE); 
    signal state                        : stateType := ST_IDLE;
    signal state_prv                    : stateType := ST_IDLE;
    attribute FSM_ENCODING              : string;
    attribute FSM_ENCODING of state     : signal is "ONE_HOT";
    
    attribute ASYNC_REG                      : string;
    attribute ASYNC_REG of empty_elink_i     : signal is "TRUE";
    attribute ASYNC_REG of empty_elink_s     : signal is "TRUE";

begin

-- FSM that reads from the DAQ2Elink FIFO and writes to the Elink FIFO in ROC format
FSM_DRV_proc: process(clk_in)
begin
    if(rising_edge(clk_in))then
        if(driver_ena = '0')then
            elink_flag      <= SOP;
            packet_part     <= "000";
            rd_en           <= '0';
            chunk_flag      <= '1';
            wr_en_elink     <= '0';
            busy            <= '0';
            ena_cnt         <= '0';
            hit_data_prv    <= (others => '0');
            wait_cnt        <= (others => '0');
            state_prv       <= ST_IDLE;
            state           <= ST_IDLE;
        else
            case state is
    
            -- wait for 'last' signal from PF to start sending data to the elinkFIFO
            when ST_IDLE =>
                elink_flag      <= SOP;
                rd_en           <= '0';
                packet_part     <= "000";
                wr_en_elink     <= '0';
                chunk_flag      <= '1';
                busy            <= '0';
                ena_cnt         <= '0';
                hit_data_prv    <= (others => '0');
                wait_cnt        <= (others => '0');
                state_prv       <= ST_IDLE;
                if(last = '1')then
                    state       <= ST_SOP_0;
                else
                    state       <= ST_IDLE;
                end if;

            -- e-link SOP states ---
            ------------------------

            -- write the e-link SOP
            when ST_SOP_0 =>
                busy        <= '1';
                wr_en_elink <= '1';
                state       <= ST_SOP_1;

            when ST_SOP_1 =>
                wr_en_elink <= '0';
                rd_en       <= '1';   -- get the vmm level0 header out
                state_prv   <= ST_SOP_1;
                state       <= ST_WAIT; -- ST_CHANGE_FLG

            when ST_CHANGE_FLG =>
                wait_cnt    <= (others => '0');
                elink_flag  <= MOP;
                rd_en       <= '0';
                state_prv   <= ST_CHANGE_FLG;
                state       <= ST_WAIT; -- ST_WR_HDR_0


            --- ROC header states --
            ------------------------

            -- write the ROC "hit data" header (1/2)
            when ST_WR_HDR_0 =>
                wait_cnt    <= (others => '0');
                rd_en       <= '0';
                wr_en_elink <= '1';
                state_prv   <= ST_WR_HDR_0;
                state       <= ST_WAIT;
                --if(packet_part = "000")then  -- select the next part
                --    state   <= ST_WAIT; -- ST_WR_HDR_1
                --elsif(packet_part = "001")then   -- select the next part
                --    state   <= ST_WAIT; -- ST_WR_HDR_1
                --else
                --    state   <= ST_WAIT;  -- ST_CHK_FIFO, all three header chunks written
                --end if;

            when ST_WR_HDR_1 =>
                wr_en_elink <= '0';
                wait_cnt    <= (others => '0');
                packet_part <= packet_part + 1; -- write next part of header
                state_prv   <= ST_WR_HDR_1;
                state       <= ST_WAIT; -- ST_WR_HDR_0


            -- ROC hit data states -
            ------------------------

            -- check the FIFO first
            when ST_CHK_FIFO =>
                wr_en_elink <= '0';
                wait_cnt    <= (others => '0');
                ena_cnt     <= '1'; -- enable the hit data length counter
                packet_part <= "011";
                if(fifo_empty = '1')then
                    state   <= ST_TRL_0;
                else
                    state   <= ST_REG_DATA_0;
                end if;

            -- read the first 16-bit hit data word
            when ST_REG_DATA_0 =>
                rd_en       <= '1';
                chunk_flag  <= not chunk_flag; -- initially from one to zero
                state_prv   <= ST_REG_DATA_0;
                if(fifo_empty = '0')then
                    state   <= ST_WAIT; -- ST_REG_DATA_1
                else -- error!
                    state   <= ST_DONE;
                end if;

            when ST_REG_DATA_1 =>
                rd_en       <= '0';
                wait_cnt    <= (others => '0');
                state       <= ST_CHK_CHUNK_FLG;
                if(chunk_flag = '0')then -- read and register the first part
                    hit_data_prv(31 downto 16)  <= dout_fifo;
                else                     -- read and register the second part
                    hit_data_prv(15 downto 0)   <= dout_fifo;
                end if;

            when ST_CHK_CHUNK_FLG =>
                if(chunk_flag = '0')then
                    state <= ST_REG_DATA_0; -- more to read and register
                else
                    state <= ST_WR_DATA_0;  -- time to write
                end if;

            when ST_WR_DATA_0 =>
                wr_en_elink <= '1';
                wait_cnt    <= (others => '0');
                state_prv   <= ST_WR_DATA_0;
                if(packet_part = "011")then
                    state       <= ST_WAIT; -- ST_WR_DATA_1;
                elsif(packet_part = "100")then
                    state       <= ST_WAIT; -- ST_CHK_FIFO;
                else
                    state       <= ST_DONE;
                end if;

            when ST_WR_DATA_1 =>
                wr_en_elink <= '0';
                wait_cnt    <= (others => '0');
                packet_part <= packet_part + 1;
                state_prv   <= ST_WR_DATA_1;
                state       <= ST_WAIT; -- ST_WR_DATA_0


            -- ROC trailer part ----
            ------------------------
            when ST_TRL_0 =>
                packet_part <= "101";
                state_prv   <= ST_TRL_0;
                state       <= ST_WAIT; -- ST_TRL_1

            when ST_TRL_1 =>
                wr_en_elink <= '1';
                wait_cnt    <= (others => '0');
                state_prv   <= ST_TRL_1;
                if(packet_part = "101")then
                    state <= ST_WAIT; -- ST_TRL_2
                elsif(packet_part = "110")then
                    state <= ST_WAIT; -- ST_TRL_2
                elsif(packet_part = "111")then -- all written
                    state <= ST_WAIT; -- ST_EOP_0
                else -- error!
                    state <= ST_DONE;
                end if;

            when ST_TRL_2 =>
                wr_en_elink <= '0';
                wait_cnt    <= (others => '0');
                packet_part <= packet_part + 1;
                state_prv   <= ST_TRL_2;
                state       <= ST_WAIT; -- ST_TRL_1


            -- e-link EOP states ---
            ------------------------

            when ST_EOP_0 =>
                wr_en_elink <= '0';
                wait_cnt    <= (others => '0');
                elink_flag  <= EOP;
                state_prv   <= ST_EOP_0;
                state       <= ST_WAIT; -- ST_EOP_1

            when ST_EOP_1 =>
                wr_en_elink <= '1';
                state       <= ST_DONE;

            ----- misc states ------
            ------------------------

            -- stay here until elink is done
            when ST_DONE =>
                wr_en_elink <= '0';
                wait_cnt    <= (others => '0');
                if(empty_elink_s = '1')then
                    state <= ST_IDLE;
                else
                    state <= ST_DONE;
                end if;

            -- stay here for some cycles to stablize MUX and FIFO bus
            when ST_WAIT =>
                rd_en       <= '0';
                wr_en_elink <= '0';
                if(wait_cnt = "11")then
                    case state_prv is
                    when ST_SOP_1       => state <= ST_CHANGE_FLG;
                    when ST_CHANGE_FLG  => state <= ST_WR_HDR_0;
                    when ST_WR_HDR_0    => if(packet_part = "010")then state <= ST_CHK_FIFO; else state <= ST_WR_HDR_1; end if;
                    when ST_WR_HDR_1    => state <= ST_WR_HDR_0;
                    when ST_WR_DATA_1   => state <= ST_WR_DATA_0;
                    when ST_REG_DATA_0  => state <= ST_REG_DATA_1;
                    when ST_WR_DATA_0   => if(packet_part = "011")then state <= ST_WR_DATA_1; else state <= ST_CHK_FIFO; end if;
                    when ST_TRL_0       => state <= ST_TRL_1;
                    when ST_TRL_1       => if(packet_part = "111")then state <= ST_EOP_0; else state <= ST_TRL_2; end if; 
                    when ST_TRL_2       => state <= ST_TRL_1;
                    when ST_EOP_0       => state <= ST_EOP_1;
                    when others         => state <= ST_DONE; --error!
                    end case;
                else
                    wait_cnt <= wait_cnt + 1;
                end if;
                
            when others =>
                elink_flag      <= SOP;
                packet_part     <= "000";
                rd_en           <= '0';
                chunk_flag      <= '1';
                wr_en_elink     <= '0';
                busy            <= '0';
                ena_cnt         <= '0';
                hit_data_prv    <= (others => '0');
                wait_cnt        <= (others => '0');
                state_prv       <= ST_IDLE;
                state           <= ST_IDLE;
    
            end case;
        end if;
    end if;
end process;

sel_dout: process(elink_flag, packet_part, dout_fifo, trigger_cnt, hit_data_prv, vmm_bitmask_miss, len_cnt)
begin
    case elink_flag is
    when SOP    => data_out <= (others => '0');
    when MOP    => 
        case packet_part is

        -- ROC HEADER 
        when "000"  => data_out <= ROC_SOP & x"00";
                    --               SOP   &   padding 
        when "001"  => data_out <= "00" & dout_fifo(13 downto 12) & dout_fifo(11 downto 0);
                    --              T|0 &           ORB           &      BCID        (T is zero because TDC is included later on)
        when "010"  => data_out <= trigger_cnt;
                    --                   16
        -- ROC DATA
        when "011"  => data_out <= hit_data_prv(30) & hit_data_prv(3) & hit_data_prv(2 downto 0) & vmm_id & hit_data_prv(27 downto 20);
                    --                   P          &       N         &         rel_bcid         &  vmmId &    channel_id&pdo(2 first MSB)
        when "100"  => data_out <= hit_data_prv(19 downto 4);
                    --             pdo(rest of word) & tdo

        -- ROC TRAILER
        when "101"  => data_out <= "00" & vmm_bitmask_miss & "0000" & len_cnt(9 downto 8);
                    --             E|TO &  missing VMMs    &  L0_ID   &   hit length counter (2 first MSB) (L0_ID is unused)
        when "110"  => data_out <= len_cnt(7 downto 0)          & x"00";
                    --           hit length cnt(rest of word)   & bitmask (unused)
        when "111"  => data_out <= x"00" & ROC_EOP;
                    --           padding & EOP
        when others => null;    
        end case;
    when EOP    => data_out <= (others => '0');
    when others => data_out <= (others => '0');
    end case;
end process;

-- process that counts hit data
count_hit_proc: process(clk_in)
begin
    if(rising_edge(clk_in))then
        if(ena_cnt = '1')then
            if(rd_en = '1' and chunk_flag = '0')then -- increment once every two rd_ena
                len_cnt_ug <= len_cnt_ug + 1;
            else
                len_cnt_ug <= len_cnt_ug;
            end if;
        else
            len_cnt_ug <= (others => '0');
        end if;
    end if;
end process;

-- process that asserts the missing vmm bitmask
vmm_miss_proc: process(vmm_id)
begin
    case vmm_id is
    when "000"  => vmm_bitmask_miss <= "01111111";
    when "001"  => vmm_bitmask_miss <= "10111111";
    when "010"  => vmm_bitmask_miss <= "11011111";
    when "011"  => vmm_bitmask_miss <= "11101111";
    when "100"  => vmm_bitmask_miss <= "11110111";
    when "101"  => vmm_bitmask_miss <= "11111011";
    when "110"  => vmm_bitmask_miss <= "11111101";
    when "111"  => vmm_bitmask_miss <= "11111110";
    when others => vmm_bitmask_miss <= "11111111";
    end case;
end process;

-- process that asserts wr_en from PF only when vmm data are being written
-- and registers the daq data. also synchronizes the FIFO empty signal
wr_en_daq_proc: process(clk_in)
begin
    if(rising_edge(clk_in))then

        din_daq_i       <= din_daq; -- register the daq data
        empty_elink_i   <= empty_elink; -- sync the empty signal
        empty_elink_s   <= empty_elink_i;

        case wr_en_safe is
        when '1'    => wr_en_daq_i <= wr_en_daq;
        when '0'    => wr_en_daq_i <= '0';
        when others => wr_en_daq_i <= '0';
        end case;

    end if;
end process;


driverFIFO : DAQelinkFIFO
  PORT MAP (
    clk     => clk_in,
    srst    => fifo_flush,
    din     => din_daq_i,
    wr_en   => wr_en_daq_i,
    rd_en   => rd_en,
    dout    => dout_fifo,
    full    => fifo_full,
    empty   => fifo_empty
  );

  dout_elink <= elink_flag & data_out;
  len_cnt    <= std_logic_vector(len_cnt_ug);

end RTL;
