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
-- 27.08.2017 Major changes. Breakdown to three different FSMs. (Christos Bakalis)
-- 30.08.2017 All VMM hits are now packed in a single ROC packet. (Christos Bakalis)
--
--------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity elink_daq_driver is
    Port(
        ---------------------------
        ---- general interface ---- 
        clk_in          : in  std_logic;
        fifo_flush      : in  std_logic;
        driver_ena      : in  std_logic;
        use_timeout     : in  std_logic;
        timeout_limit   : in  std_logic_vector(15 downto 0);
        ---------------------------
        ------- pf interface ------
        din_daq         : in  std_logic_vector(15 downto 0);
        wr_en_daq       : in  std_logic;
        din_aux         : in  std_logic_vector(15 downto 0);
        wr_en_aux       : in  std_logic;
        trigger_cnt     : in  std_logic_vector(15 downto 0);
        start_null      : in  std_logic;
        start_pack      : in  std_logic;
        bitmask_null    : in  std_logic_vector(7 downto 0); 
        elink_done      : out std_logic;
        ---------------------------
        ------ elink inteface -----
        empty_elink     : in  std_logic;
        wr_en_elink     : out std_logic;
        dout_elink      : out std_logic_vector(17 downto 0)
    );
end elink_daq_driver;

architecture RTL of elink_daq_driver is

-- FIFO that buffers the DAQ data
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

-- FIFO that buffers the VMM_ID and the length of the packet
component AuxElinkFIFO
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

-- FIFO in-between this module and the elink FIFO
component adapterFIFO
  port (
    clk     : in  std_logic;
    srst    : in  std_logic;
    din     : in  std_logic_vector(17 downto 0);
    wr_en   : in  std_logic;
    rd_en   : in  std_logic;
    dout    : out std_logic_vector(17 downto 0);
    full    : out std_logic;
    empty   : out std_logic
  );
end component;

    signal rd_en_daq        : std_logic := '0';
    signal dout_fifo        : std_logic_vector(15 downto 0) := (others => '0');
    signal daq_full         : std_logic := '0';
    signal daq_empty        : std_logic := '0';    
    signal hitsLen          : std_logic_vector(9 downto 0) := (others => '0');
    signal len_cnt          : unsigned(9 downto 0) := (others => '0');
    signal wait_cnt         : unsigned(1 downto 0) := (others => '0');
    signal wait_cnt_null    : unsigned(1 downto 0) := (others => '0');
    signal din_daq_fifo     : std_logic_vector(15 downto 0) := (others => '0');

    signal flag_pack        : std_logic_vector(1 downto 0) := (others => '0');
    signal flag_null        : std_logic_vector(1 downto 0) := (others => '0');
    signal null_done        : std_logic := '0';
    signal pack_done        : std_logic := '0';
    
    signal bcid             : std_logic_vector(11 downto 0) := (others => '0');
    signal orb              : std_logic_vector(1 downto 0)  := (others => '0');
    signal cnt_mop          : std_logic_vector(2 downto 0)  := (others => '0');
    signal cnt_mop_null     : std_logic := '0';
    signal P                : std_logic := '0';
    signal N                : std_logic := '0';
    signal tdo              : std_logic_vector(7 downto 0)  := (others => '0');
    signal tdo_prv          : std_logic_vector(7 downto 0)  := (others => '0');
    signal pdo              : std_logic_vector(9 downto 0)  := (others => '0');
    signal channel_id       : std_logic_vector(5 downto 0)  := (others => '0');
    signal rel_bcid         : std_logic_vector(2 downto 0)  := (others => '0');
    
    signal sent_one         : std_logic := '0';
    signal wr_ena_pack      : std_logic := '0';
    signal wr_ena_null      : std_logic := '0';
    signal wr_en_fifo       : std_logic := '0';
    signal data_out_pack    : std_logic_vector(15 downto 0)  := (others => '0');
    signal data_out_null    : std_logic_vector(15 downto 0)  := (others => '0');
    
    signal rd_en_aux        : std_logic := '0';
    signal cnt_read         : unsigned(11 downto 0) := (others => '0');
    signal cnt_limit        : std_logic_vector(11 downto 0) := (others => '0');
    signal aux_empty        : std_logic := '0';
    signal aux_full         : std_logic := '0';
    signal first_vmm        : std_logic := '1';
    signal vmm_id           : std_logic_vector(2 downto 0)  := (others => '0');
    signal din_aux_fifo     : std_logic_vector(15 downto 0) := (others => '0');
    signal dout_aux_fifo    : std_logic_vector(15 downto 0) := (others => '0');
    signal wr_en_aux_fifo   : std_logic := '0';
    signal ena_adapt_null   : std_logic := '0';
    signal ena_adapt_pack   : std_logic := '0';
    
    signal din_adapter      : std_logic_vector(17 downto 0) := (others => '0');
    signal rd_en_adapter    : std_logic := '0';
    signal wr_en_adapter    : std_logic := '0';
    signal wr_en_elink_i    : std_logic := '0';
    signal dout_elink_i     : std_logic_vector(17 downto 0) := (others => '0');
    signal adapter_full     : std_logic := '0';
    signal adapter_empty    : std_logic := '0';
    signal cnt_timeout      : unsigned(15 downto 0) := (others => '0');
    signal adapt_done       : std_logic := '0';
    
    signal empty_elink_i    : std_logic := '0';
    signal empty_elink_s    : std_logic := '0';
    
    -- E-LINK EOP and SOP
    constant SOP            : std_logic_vector(1 downto 0) := "10";
    constant MOP            : std_logic_vector(1 downto 0) := "00";
    constant EOP            : std_logic_vector(1 downto 0) := "01";

    -- ROC EOP and SOP. Some ambiguity has occurred regarding the correct SOP, due to a discrepancy between the two ROC docs.
    -- Currently using K28.1 as SOP as indicated by one of the two ROC docs. The other option is to use K28.4.
    constant ROC_SOP        : std_logic_vector(7 downto 0) := "00111100"; -- K28.1
    --constant ROC_SOP        : std_logic_vector(7 downto 0) := "10011100"; -- K28.4 
    constant ROC_EOP        : std_logic_vector(7 downto 0) := "11011100"; -- K28.6

    -- state signals and attributes
    type stateType_pack is  (ST_IDLE, ST_REG_HDR, ST_SEND_HDR_0, ST_SEND_HDR_1, ST_SEND_HDR_2, ST_SEND_HDR_3, ST_SEND_HDR_4, ST_CHK_AUX,
                              ST_READ_DATA_0, ST_READ_DATA_1, ST_REG_DATA_0, ST_REG_DATA_1, ST_SEND_DATA_0, ST_SEND_DATA_1, ST_SEND_DATA_2,
                              ST_CHK_CNTR, ST_WR_TRL_0, ST_WR_TRL_1, ST_WR_TRL_2, ST_WR_TRL_3, ST_WR_EOP_0, ST_WR_EOP_1, ST_DONE, ST_WAIT);
                              
    type stateType_null is  (ST_IDLE, ST_SEND_EOP, ST_SEND_HDR_0, ST_SEND_HDR_1, ST_SEND_HDR_2, ST_SEND_HDR_3, ST_WR_EOP_0, ST_WR_EOP_1, ST_DONE, ST_WAIT);

    type stateType_adapt is (ST_IDLE, ST_READ, ST_WAIT, ST_CNT, ST_DONE);

    signal state_pack       : stateType_pack := ST_IDLE;
    signal state_null       : stateType_null := ST_IDLE;
    signal state_prv        : stateType_pack := ST_IDLE;
    signal state_prv_null   : stateType_null := ST_IDLE;
    signal state_adapt      : stateType_adapt:= ST_IDLE;

    attribute FSM_ENCODING  : string;
    attribute FSM_ENCODING of state_pack    : signal is "ONE_HOT";
    attribute FSM_ENCODING of state_null    : signal is "ONE_HOT";
    attribute FSM_ENCODING of state_adapt   : signal is "ONE_HOT";
    
    attribute ASYNC_REG : string;
    attribute ASYNC_REG of empty_elink_i    : signal is "TRUE";
    attribute ASYNC_REG of empty_elink_s    : signal is "TRUE";    

begin

------------------------------------------
-------------- FSM HIT PACKET ------------
------------------------------------------
-- FSM that writes the ROC e-link packet
FSM_packet_drv: process(clk_in)
begin
    if(rising_edge(clk_in))then
        if(start_pack = '0')then
            rd_en_daq       <= '0';
            flag_pack       <= SOP;
            wr_ena_pack     <= '0';
            sent_one        <= '0';
            first_vmm       <= '1';
            pack_done       <= '0';
            rd_en_aux       <= '0';
            ena_adapt_pack  <= '0';
            wait_cnt        <= (others => '0');
            cnt_read        <= (others => '0');
            cnt_mop         <= (others => '0');
            len_cnt         <= (others => '0');
            state_pack      <= ST_IDLE;
        else
            case state_pack is

            -- activated, read the first word
            when ST_IDLE =>
                rd_en_daq   <= '1'; -- if this is not the first VMM, 
                                    -- this reading will just discard the in-between VMM header
                rd_en_aux   <= '1'; -- also read the auxiliary FIFO
                cnt_read    <= cnt_read + 1;
                flag_pack   <= SOP;
                state_prv   <= ST_IDLE;
                state_pack  <= ST_WAIT; -- to ST_REG_HDR or ST_READ_DATA_0


            -- register the header and write the elink SOP
            when ST_REG_HDR =>
                wr_ena_pack <= '1';
                bcid        <= dout_fifo(11 downto 0);
                orb         <= dout_fifo(13 downto 12);
                state_prv   <= ST_REG_HDR;
                state_pack  <= ST_WAIT; -- to ST_SEND_HDR_0

            -----------------------------------------------
            -- start sending the roc header
            when ST_SEND_HDR_0 =>
                wr_ena_pack <= '0';
                flag_pack   <= MOP;
                state_prv   <= ST_SEND_HDR_0;
                state_pack  <= ST_WAIT; -- to ST_SEND_HDR_1

            when ST_SEND_HDR_1 =>
                wr_ena_pack <= '1';
                state_prv   <= ST_SEND_HDR_1;
                state_pack  <= ST_WAIT; -- to ST_SEND_HDR_2

            when ST_SEND_HDR_2 =>
                wr_ena_pack <= '0';
                state_prv   <= ST_SEND_HDR_2;
                state_pack  <= ST_WAIT; -- to ST_SEND_HDR_3

            when ST_SEND_HDR_3 =>
                wr_ena_pack <= '0';
                cnt_mop     <= "001";
                state_prv   <= ST_SEND_HDR_3;
                state_pack  <= ST_WAIT; -- to ST_SEND_HDR_4

            when ST_SEND_HDR_4 =>
                wr_ena_pack <= '1';
                state_prv   <= ST_SEND_HDR_4;
                state_pack  <= ST_WAIT; -- to ST_READ_DATA_0
            -- roc header has been sent by now
            ------------------------------------------------

            ------------------------------------------------
            -- start sending the data
            -- pass the first hit word to the bus
            when ST_READ_DATA_0 =>
                rd_en_daq   <= '1';
                cnt_read    <= cnt_read + 1;
                flag_pack   <= MOP;
                cnt_mop     <= "010";
                state_prv   <= ST_READ_DATA_0;
                state_pack  <= ST_WAIT; -- to ST_REG_DATA_0

            -- register the first hit word
            when ST_REG_DATA_0 =>
                P               <= dout_fifo(14);
                channel_id      <= dout_fifo(11 downto 6);
                pdo(9 downto 4) <= dout_fifo(5 downto 0);
                state_prv       <= ST_REG_DATA_0;
                state_pack      <= ST_WAIT; -- to ST_READ_DATA_1

            -- pass the second hit word to the bus, and increment the hit counter
            when ST_READ_DATA_1 =>
                rd_en_daq   <= '1';
                cnt_read    <= cnt_read + 1;
                len_cnt     <= len_cnt + 1;
                state_prv   <= ST_READ_DATA_1;
                state_pack  <= ST_WAIT; -- to ST_REG_DATA_1

            -- register the second hit word
            when ST_REG_DATA_1 =>
                pdo(3 downto 0) <= dout_fifo(15 downto 12);
                tdo             <= dout_fifo(11 downto 4);
                N               <= dout_fifo(3);
                rel_bcid        <= dout_fifo(2 downto 0);
                state_prv       <= ST_REG_DATA_1;
                state_pack      <= ST_WAIT;  -- to ST_SEND_DATA_0

            -- write the first word
            when ST_SEND_DATA_0 =>
                wr_ena_pack <= '1';
                state_prv   <= ST_SEND_DATA_0; 
                state_pack  <= ST_WAIT; -- to ST_SEND_DATA_1

            -- select the second chunk of the data
            when ST_SEND_DATA_1 =>
                cnt_mop     <= "011";
                state_prv   <= ST_SEND_DATA_1;
                state_pack  <= ST_WAIT;  -- to ST_SEND_DATA_2

            -- write the second chunk
            when ST_SEND_DATA_2 =>
                wr_ena_pack <= '1';
                state_pack  <= ST_CHK_CNTR;

            -- check the counter state to see if we are done
            when ST_CHK_CNTR =>
                wr_ena_pack <= '0';
                sent_one    <= '1'; -- flag that indicates one packet has been sent
                tdo_prv     <= tdo;
                state_prv   <= ST_CHK_CNTR;
                if(cnt_read = unsigned(cnt_limit))then
                    state_pack <= ST_CHK_AUX;
                else
                    state_pack <= ST_WAIT; -- to ST_READ_DATA_0
                end if;
            -- roc data have been sent by now
            -----------------------------------------------

            -----------------------------------------------
            -----------------------------------------------

            -- is this the last VMM?
            when ST_CHK_AUX =>
                cnt_read    <= (others => '0');
                first_vmm   <= '0';
                if(aux_empty = '1' and daq_empty = '1')then
                    state_pack <= ST_WR_TRL_0;
                else
                    state_pack <= ST_IDLE;
                end if;

            -----------------------------------------------
            -- start sending the roc trailer
            when ST_WR_TRL_0 =>
                state_prv   <= ST_WR_TRL_0;
                state_pack  <= ST_WAIT; -- to ST_WR_TRL_1

            when ST_WR_TRL_1 =>
                state_prv   <= ST_WR_TRL_1;
                state_pack  <= ST_WAIT; -- to ST_WR_TRL_2
                if(cnt_mop = "011")then
                    cnt_mop <= "100";
                elsif(cnt_mop = "100")then
                    cnt_mop <= "101";
                elsif(cnt_mop = "101")then
                    cnt_mop <= "110";
                else null;
                end if;

            when ST_WR_TRL_2 =>
                wr_ena_pack <= '1';
                state_prv   <= ST_WR_TRL_2;
                state_pack  <= ST_WAIT; -- to ST_WR_TRL_1

            when ST_WR_TRL_3 =>
                state_prv   <= ST_WR_TRL_3;
                if(cnt_mop = "110")then
                    state_pack <= ST_WAIT; -- to ST_WR_EOP_0
                else
                    state_pack <= ST_WR_TRL_1;
                end if;
            -- roc trailer has been sent by now
            ------------------------------------------------

            -- final states....
            when ST_WR_EOP_0 =>
                flag_pack   <= EOP;
                state_prv   <= ST_WR_EOP_0;
                state_pack  <= ST_WAIT; -- to ST_WR_EOP_1

            when ST_WR_EOP_1 =>
                wr_ena_pack <= '1';
                state_prv   <= ST_WR_EOP_1;
                state_pack  <= ST_DONE;

            -- wait here until reset by packet formation
            when ST_DONE =>
                wr_ena_pack     <= '0';
                ena_adapt_pack  <= '1';
                state_pack      <= ST_DONE;
                if(adapt_done = '1')then
                    pack_done   <= '1';
                else
                    pack_done   <= '0';
                end if;
            -----------------------------------------------

            -- generic state that waits
            when ST_WAIT =>
                rd_en_daq   <= '0';
                wr_ena_pack <= '0';
                rd_en_aux   <= '0';
                wait_cnt    <= wait_cnt + 1;
                if(wait_cnt = "11")then
                    case state_prv is
                    when ST_IDLE        => if(first_vmm = '1')then state_pack <= ST_REG_HDR; else state_pack <= ST_READ_DATA_0; end if;
                    when ST_REG_HDR     => state_pack <= ST_SEND_HDR_0;
                    when ST_SEND_HDR_0  => state_pack <= ST_SEND_HDR_1;
                    when ST_SEND_HDR_1  => state_pack <= ST_SEND_HDR_2;
                    when ST_SEND_HDR_2  => state_pack <= ST_SEND_HDR_3;
                    when ST_SEND_HDR_3  => state_pack <= ST_SEND_HDR_4;
                    when ST_SEND_HDR_4  => state_pack <= ST_READ_DATA_0;
                    when ST_READ_DATA_0 => state_pack <= ST_REG_DATA_0;
                    when ST_REG_DATA_0  => state_pack <= ST_READ_DATA_1;
                    when ST_READ_DATA_1 => state_pack <= ST_REG_DATA_1;
                    when ST_REG_DATA_1  => state_pack <= ST_SEND_DATA_0;
                    when ST_SEND_DATA_0 => state_pack <= ST_SEND_DATA_1;
                    when ST_SEND_DATA_1 => state_pack <= ST_SEND_DATA_2;
                    when ST_WR_TRL_0    => state_pack <= ST_WR_TRL_1;
                    when ST_WR_TRL_1    => state_pack <= ST_WR_TRL_2;
                    when ST_WR_TRL_2    => state_pack <= ST_WR_TRL_3;
                    when ST_WR_TRL_3    => state_pack <= ST_WR_EOP_0;
                    when ST_WR_EOP_0    => state_pack <= ST_WR_EOP_1;
                    when ST_CHK_CNTR    => state_pack <= ST_READ_DATA_0;
                    when ST_WR_EOP_1    => state_pack <= ST_DONE;
                    when others         => state_pack <= ST_DONE; --error!
                    end case;
                else
                    state_pack <= ST_WAIT;
                end if;

            when others =>
                rd_en_daq       <= '0';
                flag_pack       <= SOP;
                wr_ena_pack     <= '0';
                sent_one        <= '0';
                pack_done       <= '0';
                first_vmm       <= '1';
                rd_en_aux       <= '0';
                ena_adapt_pack  <= '0';
                cnt_read        <= (others => '0');
                wait_cnt        <= (others => '0');
                cnt_mop         <= (others => '0');
                state_pack      <= ST_IDLE;

            end case;
        end if;
    end if;
end process;

-- what to send from the packet forming FSM?
sel_dout_pack: process(flag_pack, cnt_mop, orb, bcid, trigger_cnt, P, N, rel_bcid, vmm_id, tdo_prv, channel_id, pdo,
                  bitmask_null, hitsLen, sent_one)
begin
    case flag_pack is
    when SOP    => data_out_pack <= (others => '0');
    when MOP    => 
        case cnt_mop is

        -- ROC HEADER 
        when "000"  =>  data_out_pack <= ROC_SOP & "00" & orb & bcid(11 downto 8);
                    --                     SOP   & T|0  & orb & bcid(first 4 MSB) (T is zero because TDC/TDO is included later on)
        when "001"  =>  data_out_pack <= bcid(7 downto 0) & trigger_cnt(15 downto 8);
                    --                    bcid(rest)      & L1ID(first 8 MSB)
        -- ROC DATA
        when "010"  =>  if(sent_one = '0')then
                            data_out_pack <= trigger_cnt(7 downto 0) & P & N & rel_bcid & vmm_id;
                    --                          L1DC(rest)
                        else
                            data_out_pack <= tdo_prv & P & N & rel_bcid & vmm_id;
                    --                  previous TDO       (select the appropriate first byte...)
                        end if;
        when "011"  =>  data_out_pack <= channel_id & pdo;

        -- ROC TRAILER
        when "100"  =>  data_out_pack <= tdo_prv & "00" & bitmask_null(7 downto 2);
                    --             previous TDO  & E|TO & bitmask(6 first MSB)
        when "101"  =>  data_out_pack <= bitmask_null(1 downto 0) & "0000" & hitsLen;
                    --                       bitmask(rest)        & L0ID(unused) & hit length
        when "110"  =>  data_out_pack <= "00000000" & ROC_EOP;
                    --             checksum(unused) & ROC_EOP
        when others => null;    
        end case;
    when EOP    => data_out_pack <= (others => '0');
    when others => data_out_pack <= (others => '0');
    end case;
end process;


------------------------------------------
-------------- FSM NULL HEADER -----------
------------------------------------------

-- FSM that writes a null ROC e-link packet
FSM_null_drv: process(clk_in)
begin
    if(rising_edge(clk_in))then
        if(start_null = '0')then
            wr_ena_null     <= '0';
            cnt_mop_null    <= '0';
            null_done       <= '0';
            ena_adapt_null  <= '0';
            flag_null       <= SOP;
            wait_cnt_null   <= (others => '0');
            state_null      <= ST_IDLE;
        else
            case state_null is
            when ST_IDLE =>
                flag_null       <= SOP;
                state_prv_null  <= ST_IDLE;
                state_null      <= ST_WAIT; -- to ST_SEND_EOP

            when ST_SEND_EOP =>
                wr_ena_null     <= '1';
                state_prv_null  <= ST_SEND_EOP;
                state_null      <= ST_WAIT;

            when ST_SEND_HDR_0 =>
                flag_null       <= MOP;
                state_prv_null  <= ST_SEND_HDR_0;
                state_null      <= ST_WAIT; -- to ST_SEND_HDR_1

            when ST_SEND_HDR_1 =>
                wr_ena_null     <= '1';
                state_prv_null  <= ST_SEND_HDR_1;
                state_null      <= ST_WAIT; -- to ST_SEND_HDR_2

            when ST_SEND_HDR_2 =>
                cnt_mop_null    <= '1';
                state_prv_null  <= ST_SEND_HDR_2;
                state_null      <= ST_WAIT; -- to ST_SEND_HDR_3

            when ST_SEND_HDR_3 =>
                wr_ena_null     <= '1';
                state_prv_null  <= ST_SEND_HDR_3;
                state_null      <= ST_WAIT; -- to ST_WR_EOP_0

            when ST_WR_EOP_0 =>
                flag_null       <= EOP;
                state_prv_null  <= ST_WR_EOP_0;
                state_null      <= ST_WAIT; -- to ST_WR_EOP_1

            when ST_WR_EOP_1 =>
                wr_ena_null     <= '1';
                state_prv_null  <= ST_WR_EOP_1;
                state_null      <= ST_WAIT; -- to ST_DONE

            -- wait here until reset by packet formation
            when ST_DONE =>
                wr_ena_null     <= '0';
                ena_adapt_null  <= '1';
                state_null      <= ST_DONE;
                if(adapt_done = '1')then
                    null_done   <= '1';
                else
                    null_done   <= '0';
                end if;

            -- generic state that waits
            when ST_WAIT =>
                wr_ena_null    <= '0';
                wait_cnt_null  <= wait_cnt_null + 1;
                if(wait_cnt_null = "11")then
                    case state_prv_null is
                    when ST_IDLE        => state_null <= ST_SEND_EOP;
                    when ST_SEND_EOP    => state_null <= ST_SEND_HDR_0;
                    when ST_SEND_HDR_0  => state_null <= ST_SEND_HDR_1;
                    when ST_SEND_HDR_1  => state_null <= ST_SEND_HDR_2;
                    when ST_SEND_HDR_2  => state_null <= ST_SEND_HDR_3;
                    when ST_SEND_HDR_3  => state_null <= ST_WR_EOP_0;
                    when ST_WR_EOP_0    => state_null <= ST_WR_EOP_1;
                    when ST_WR_EOP_1    => state_null <= ST_DONE;
                    when others         => state_null <= ST_DONE; --error!
                    end case;
                else
                    state_null <= ST_WAIT;
                end if;
                
            when others =>
                wr_ena_null     <= '0';
                cnt_mop_null    <= '0';
                null_done       <= '0';
                ena_adapt_null  <= '0';
                wait_cnt_null   <= (others => '0');
                state_null      <= ST_IDLE;
            end case;
        end if;
    end if;
end process;


------------------------------------------
-------------- FSM READ ADAPTER ----------
------------------------------------------

-- FSM that reads the adapter FIFO and waits if timeout is activated
FSM_adapt_drv: process(clk_in)
begin
    if(rising_edge(clk_in))then
        if(ena_adapt_pack = '0' and ena_adapt_null = '0')then
            adapt_done      <= '0';
            rd_en_adapter   <= '0';
            cnt_timeout     <= (others => '0');
            state_adapt     <= ST_READ;
        else
            case state_adapt is

            -- start reading
            when ST_READ =>
                if(adapter_empty = '0')then
                    rd_en_adapter   <= '1';
                    state_adapt     <= ST_READ;
                else
                    rd_en_adapter   <= '0';
                    state_adapt     <= ST_WAIT;
                end if;

            -- wait for elink to send it all
            when ST_WAIT =>
                if(empty_elink_s = '1' and use_timeout = '1')then
                    state_adapt <= ST_CNT;
                elsif(empty_elink_s = '1' and use_timeout = '0')then
                    state_adapt <= ST_DONE;
                else
                    state_adapt <= ST_WAIT;
                end if;

            -- counter for timeout
            when ST_CNT =>
                if(cnt_timeout = unsigned(timeout_limit))then
                    cnt_timeout <= (others => '0');
                    state_adapt <= ST_DONE;
                else
                    cnt_timeout <= cnt_timeout + 1;
                    state_adapt <= ST_CNT;
                end if;

            -- stay here until reset
            when ST_DONE =>
                adapt_done <= '1';

            when others => 
                adapt_done      <= '0';
                rd_en_adapter   <= '0';
                cnt_timeout     <= (others => '0');
                state_adapt     <= ST_READ;

            end case;
        end if;
    end if;
end process;


-- what to send out from the null header FSM?
sel_dout_null: process(flag_null, cnt_mop_null, trigger_cnt)
begin
    case flag_null is
    when SOP    => data_out_null <= (others => '0');
    when MOP    => 
        case cnt_mop_null is
        when '0'    => data_out_null <= ROC_SOP & "01" & "000111";
                    --                  SOP     & flags & ROC_ID
        when '1'    => data_out_null <= trigger_cnt(15 downto 8) & ROC_EOP;
                    --                   8 first MSB of L1ID     & EOP
        when others => null;    
        end case;
    when EOP    => data_out_null <= (others => '0');
    when others => data_out_null <= (others => '0');
    end case;
end process;

-- final synchronous multiplexer before the adapter
sel_dout_proc: process(clk_in)
begin
    if(rising_edge(clk_in))then
        if(start_null = '1')then
            din_adapter     <= flag_null & data_out_null;
            wr_en_adapter   <= wr_ena_null;
        elsif(start_pack = '1')then
            din_adapter     <= flag_pack & data_out_pack;
            wr_en_adapter   <= wr_ena_pack;
        else
            din_adapter     <= (others => '0');
            wr_en_adapter   <= '0';
        end if;
    end if;
end process;

-- synchronizing/delaying process
sync_delay_proc: process(clk_in)
begin
    if(rising_edge(clk_in))then
        empty_elink_i <= empty_elink;
        empty_elink_s <= empty_elink_i;        
    
        din_daq_fifo    <= din_daq; -- register the daq data
        wr_en_fifo      <= wr_en_daq; -- register the wr_en

        din_aux_fifo    <= din_aux;
        wr_en_aux_fifo  <= wr_en_aux;

        vmm_id          <= dout_aux_fifo(15 downto 13);
        cnt_limit       <= dout_aux_fifo(11 downto 0);

        if(dout_elink_i(17 downto 16) = "01")then -- elink EOP reached
            wr_en_elink_i   <= '0';
            wr_en_elink     <= '0';
        else
            wr_en_elink_i   <= rd_en_adapter;
            wr_en_elink     <= wr_en_elink_i;
        end if;
        
    end if;
end process;

    hitsLen     <= std_logic_vector(len_cnt);
    elink_done  <= pack_done or null_done;
    dout_elink  <= dout_elink_i;

driverFIFO : DAQelinkFIFO
  PORT MAP (
    clk     => clk_in,
    srst    => fifo_flush,
    din     => din_daq_fifo,
    wr_en   => wr_en_fifo,
    rd_en   => rd_en_daq,
    dout    => dout_fifo,
    full    => daq_full,
    empty   => daq_empty
  );

  auxFIFO : AuxElinkFIFO
  PORT MAP (
    clk     => clk_in,
    srst    => fifo_flush,
    din     => din_aux_fifo,
    wr_en   => wr_en_aux_fifo,
    rd_en   => rd_en_aux,
    dout    => dout_aux_fifo,
    full    => aux_full,
    empty   => aux_empty
  );

  adaptFIFO : adapterFIFO
  PORT MAP (
    clk     => clk_in,
    srst    => fifo_flush,
    din     => din_adapter,
    wr_en   => wr_en_adapter,
    rd_en   => rd_en_adapter,
    dout    => dout_elink_i,
    full    => adapter_full,
    empty   => adapter_empty
  );

end RTL;
