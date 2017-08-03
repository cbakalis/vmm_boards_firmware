-----------------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
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
-- Create Date: 30.01.2017
-- Design Name: UDP Data Handler
-- Module Name: udp_data_handler - RTL
-- Project Name: MMFE8 - NTUA
-- Target Devices: Artix7 xc7a200t-2fbg484 and xc7a200t-3fbg484
-- Tool Versions: Vivado 2016.2
-- Description: Module that samples the data coming from the UDP/Ethernet
-- and issues the corresponding FPGA commands depending on the payload and
-- the incoming port. It also serializes the data of the VMM configuration.

-- Dependencies: MMFE8 NTUA Project
-- 
-- Changelog:
-- 31.01.2017 The serialization now starts with a signal coming from the master FSM 
-- and the MUX select signal is being reset between packets. (Christos Bakalis)
-- 08.02.2017 Broke down the processes into two sub-components. (Christos Bakalis)
-- 27.02.2017 Changes to integrate with new flow_fsm clock (125 Mhz). (Christos Bakalis)
-- 07.03.2017 Added CKBC/CKTP configuration functionality. (Christos Bakalis)
-- 14.03.2017 FPGA register address configuration scheme deployed. (Christos Bakalis)
-- 17.03.2017 Added configuration-inhibit signal which is high if flow_fsm is not in
-- IDLE state. Change if fpga_glbl_rst is added again. (Christos Bakalis)
-- 28.03.2017 Module now samples the header data as well. (Christos Bakalis)
--
-----------------------------------------------------------------------------------------
library UNISIM;
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use UNISIM.VCOMPONENTS.all;

use work.axi.all;
use work.ipv4_types.all;
use work.arp_types.all;

entity udp_data_in_handler is
    port(
    ------------------------------------
    ------- General Interface ----------
    clk_125             : in  std_logic;
    clk_40              : in  std_logic;
    inhibit_conf        : in  std_logic;
    rst                 : in  std_logic;
    state_o             : out std_logic_vector(2 downto 0);
    valid_o             : out std_logic;
    ------------------------------------
    -------- FPGA Config Interface -----
    latency             : out std_logic_vector(15 downto 0);
    serial_number       : out std_logic_vector(31 downto 0);
    tr_delay_limit      : out std_logic_vector(15 downto 0);
    daq_on              : out std_logic;
    ext_trigger         : out std_logic;
    ckbcMode            : out std_logic;
    fpga_rst            : out std_logic;
    ------------------------------------
    -------- UDP Interface -------------
    udp_rx              : in  udp_rx_type;
    ------------------------------------
    ---------- AXI4SPI Interface -------
    flash_busy          : in  std_logic;
    newIP_rdy           : out std_logic;
    myIP_set            : out std_logic_vector(31 downto 0);
    myMAC_set           : out std_logic_vector(47 downto 0);
    destIP_set          : out std_logic_vector(31 downto 0);
    ------------------------------------
    -------- CKTP/CKBC Interface -------
    ckbc_freq           : out std_logic_vector(7 downto 0);
    cktk_max_num        : out std_logic_vector(7 downto 0);
    cktp_max_num        : out std_logic_vector(15 downto 0);
    cktp_skew           : out std_logic_vector(7 downto 0);
    cktp_period         : out std_logic_vector(15 downto 0);
    cktp_width          : out std_logic_vector(7 downto 0);
    ckbc_max_num        : out std_logic_vector(7 downto 0);
    ------------------------------------
    ------ VMM Config Interface --------
    vmm_bitmask         : out std_logic_vector(7 downto 0);
    vmmConf_came        : out std_logic;
    vmmConf_rdy         : out std_logic;
    vmmConf_done        : out std_logic;
    vmm_sck             : out std_logic;
    vmm_cs              : out std_logic;
    vmm_cfg_bit         : out std_logic;
    top_rdy             : in  std_logic;
    ------------------------------------
    ---------- XADC Interface ----------
    xadc_busy           : in  std_logic;
    xadc_rdy            : out std_logic;
    vmm_id_xadc         : out std_logic_vector(15 downto 0);
    xadc_sample_size    : out std_logic_vector(10 downto 0);
    xadc_delay          : out std_logic_vector(17 downto 0)
    );
end udp_data_in_handler;

architecture RTL of udp_data_in_handler is

    COMPONENT fpga_config_block
    PORT(
        -----------------------------------
        ------- General Interface ----------
        clk_125             : in  std_logic;
        rst                 : in  std_logic;
        cnt_bytes           : in  unsigned(7 downto 0);
        user_din_udp        : in  std_logic_vector(7 downto 0);
        ------------------------------------
        -------- UDP Interface -------------
        udp_rx              : in  udp_rx_type;
        ------------------------------------
        ---------- XADC Interface ----------
        xadc_conf           : in  std_logic;
        xadcPacket_rdy      : out std_logic;
        vmm_id_xadc         : out std_logic_vector(15 downto 0);
        xadc_sample_size    : out std_logic_vector(10 downto 0);
        xadc_delay          : out std_logic_vector(17 downto 0);
        ------------------------------------
        ---------- AXI4SPI Interface -------
        flash_conf          : in  std_logic;
        flashPacket_rdy     : out std_logic;
        myIP_set            : out std_logic_vector(31 downto 0);
        myMAC_set           : out std_logic_vector(47 downto 0);
        destIP_set          : out std_logic_vector(31 downto 0);
        ------------------------------------
        -------- CKTP/CKBC Interface -------
        ckbc_freq           : out std_logic_vector(7 downto 0);
        cktk_max_num        : out std_logic_vector(7 downto 0);
        cktp_max_num        : out std_logic_vector(15 downto 0);
        cktp_skew           : out std_logic_vector(7 downto 0);
        cktp_period         : out std_logic_vector(15 downto 0);
        cktp_width          : out std_logic_vector(7 downto 0);
        ------------------------------------
        -------- FPGA Config Interface -----
        fpga_conf           : in  std_logic;
        fpga_rst            : out std_logic;
        fpgaPacket_rdy      : out std_logic;
        latency             : out std_logic_vector(15 downto 0);
        tr_delay_limit      : out std_logic_vector(15 downto 0);
        ckbc_max_num        : out std_logic_vector(7 downto 0);
        daq_on              : out std_logic;
        ext_trigger         : out std_logic;
        ckbcMode            : out std_logic
    );
    END COMPONENT;

    COMPONENT vmm_config_block
    PORT(
        ------------------------------------
        ------- General Interface ----------
        clk_125             : in  std_logic;
        clk_40              : in  std_logic;
        rst                 : in  std_logic;
        rst_fifo            : in  std_logic;
        cnt_bytes           : in  unsigned(7 downto 0);
        ------------------------------------
        --------- FIFO/UDP Interface -------
        user_din_udp        : in  std_logic_vector(7 downto 0);
        user_valid_udp      : in  std_logic;
        user_last_udp       : in  std_logic;
        ------------------------------------
        ------ VMM Config Interface --------
        vmmConf_rdy         : out std_logic;
        vmmConf_done        : out std_logic;
        vmm_sck             : out std_logic;
        vmm_cs              : out std_logic;
        vmm_cfg_bit         : out std_logic;
        vmm_conf            : in  std_logic;
        top_rdy             : in  std_logic;
        init_ser            : in  std_logic
    );
    END COMPONENT;

    COMPONENT CDCC
    GENERIC(
        NUMBER_OF_BITS : integer := 8); -- number of signals to be synced
    PORT(
        clk_src     : in  std_logic;                                        -- input clk (source clock)
        clk_dst     : in  std_logic;                                        -- input clk (dest clock)
        data_in     : in  std_logic_vector(NUMBER_OF_BITS - 1 downto 0);    -- data to be synced
        data_out_s  : out std_logic_vector(NUMBER_OF_BITS - 1 downto 0)     -- synced data to clk_dst
    );
    END COMPONENT;

    signal user_data_prv    : std_logic_vector(7 downto 0)  := (others => '0');
    signal command          : std_logic_vector(15 downto 0) := (others => '0');
    signal user_valid_prv   : std_logic := '0';
    signal user_last_prv    : std_logic := '0';
    signal cnt_bytes        : unsigned(7 downto 0) := (others => '0');
    signal conf_state       : unsigned(2 downto 0) := (others => '0');
    signal sample_hdr       : std_logic := '0';
    signal vmm_conf         : std_logic := '0';
    signal vmm_ser_done     : std_logic := '0';
    signal vmmSer_done_s125 : std_logic := '0';
    signal vmm_conf_rdy     : std_logic := '0';
    signal fpga_conf        : std_logic := '0';
    signal flash_conf       : std_logic := '0';
    signal xadc_conf        : std_logic := '0';
    signal rst_fifo         : std_logic := '0';
    signal rst_fifo_s40     : std_logic := '0';
    signal xadcPacket_rdy   : std_logic := '0';
    signal flashPacket_rdy  : std_logic := '0';
    signal fpgaPacket_rdy   : std_logic := '0';
    signal init_ser         : std_logic := '0';
    signal init_ser_s40     : std_logic := '0';
    signal top_rdy_s40      : std_logic := '0';
    signal fpga_rst_i       : std_logic := '0';
    
    type masterFSM is (ST_IDLE, ST_CHK_PORT, ST_COUNT, ST_WAIT_FOR_BUSY, ST_WAIT_FOR_IDLE, ST_RESET_FIFO, ST_WAIT_FOR_SCK_FSM, ST_ERROR);
    signal st_master : masterFSM := ST_IDLE;
    
    ---- Uncomment the following to add signals to ILA debugging core
    -----------------------------------------------------------------
    attribute mark_debug : string;
    attribute keep       : string;

    --attribute mark_debug of latency                   : signal is "true";
    --attribute mark_debug of fpga_rst_conf             : signal is "true";
    --attribute mark_debug of daq_on                    : signal is "true";
    --attribute mark_debug of ext_trigger               : signal is "true";
    --attribute mark_debug of udp_rx.data.data_in       : signal is "true";
    --attribute mark_debug of udp_rx.data.data_in_valid : signal is "true";
    --attribute mark_debug of udp_rx.data.data_in_last  : signal is "true";
    --attribute mark_debug of udp_rx.hdr.dst_port       : signal is "true";
    --attribute mark_debug of flash_busy                : signal is "true";
    --attribute mark_debug of newIP_rdy                 : signal is "true";
    --attribute mark_debug of myIP_set                  : signal is "true";
    --attribute mark_debug of myMAC_set                 : signal is "true";
    --attribute mark_debug of destIP_set                : signal is "true";
    --attribute mark_debug of vmmConf_rdy               : signal is "true";
    --attribute mark_debug of vmmConf_done              : signal is "true";
    --attribute mark_debug of vmm_cktk                  : signal is "true";
    --attribute mark_debug of vmm_cfg_bit               : signal is "true";
    --attribute mark_debug of top_rdy                   : signal is "true";
    --attribute mark_debug of xadc_busy                 : signal is "true";
    --attribute mark_debug of xadc_rdy                  : signal is "true";
    --attribute mark_debug of vmm_id_xadc               : signal is "true";
    --attribute mark_debug of xadc_sample_size          : signal is "true";
    --attribute mark_debug of xadc_delay                : signal is "true";
    --attribute mark_debug of conf_state                : signal is "true";
    --attribute keep of conf_state                      : signal is "true";

    --attribute mark_debug of user_data_prv     : signal is "true";
    --attribute mark_debug of user_valid_prv    : signal is "true";
    --attribute mark_debug of user_valid_fifo   : signal is "true";
    --attribute mark_debug of user_last_prv     : signal is "true";
    --attribute mark_debug of cnt_bytes         : signal is "true";
    --attribute mark_debug of wait_cnt          : signal is "true";
    --attribute mark_debug of vmm_ser_done      : signal is "true";
    --attribute mark_debug of vmm_conf_rdy      : signal is "true";
    --attribute mark_debug of fpga_conf         : signal is "true";
    --attribute mark_debug of flash_conf        : signal is "true";
    --attribute mark_debug of sel_vmm_data      : signal is "true";
    --attribute mark_debug of xadc_conf         : signal is "true";
    --attribute mark_debug of rst_fifo          : signal is "true";
    --attribute mark_debug of xadcPacket_rdy    : signal is "true";
    --attribute mark_debug of flashPacket_rdy   : signal is "true";
    --attribute mark_debug of fpgaPacket_rdy    : signal is "true";
    --attribute mark_debug of fpga_conf_1of2    : signal is "true";
    --attribute mark_debug of fpga_conf_2of2    : signal is "true";
    --attribute mark_debug of rd_ena            : signal is "true";
    --attribute mark_debug of fifo_full         : signal is "true";
    --attribute mark_debug of fifo_empty        : signal is "true";

    --------------- List of Processes/FSMs ----------------
    -------------------------------------------------------
    --- 1. delay_din            (clk_125)
    --- 2. master_handling_FSM  (clk_125)
    --- 3. sample_header_proc   (clk_125)
    -------------------------------------------------------
    -------------------------------------------------------
begin

-- delay the input data for correct sampling by the sub-processes
delay_din: process(clk_125)
begin
    if(rising_edge(clk_125))then
        user_data_prv   <= udp_rx.data.data_in;
        user_valid_prv  <= udp_rx.data.data_in_valid;
        user_last_prv   <= udp_rx.data.data_in_last;
    end if;
end process;

-- Central configuarion FSM that checks for the first valid pulse
-- and for the UDP port, in order to initialize the byte counter 
-- that the sub-processes will use to sample the configuration data
master_handling_FSM: process(clk_125)
begin
    if(rising_edge(clk_125))then
        if(rst = '1')then
            cnt_bytes   <= (others => '0');
            vmm_conf    <= '0';
            fpga_conf   <= '0';
            flash_conf  <= '0';
            xadc_conf   <= '0';
            sample_hdr  <= '0';
            init_ser    <= '0';
            rst_fifo    <= '1';
            st_master   <= ST_IDLE;
        else
            case st_master is

            -- wait for valid signal to initialize counter. ignore inhibit flag if FPGA configuration
            when ST_IDLE =>
                conf_state  <= "000"; 
                vmm_conf    <= '0';
                fpga_conf   <= '0';
                flash_conf  <= '0';
                xadc_conf   <= '0';
                rst_fifo    <= '0';

                if(udp_rx.data.data_in_valid = '1' and inhibit_conf = '0')then
                    cnt_bytes   <= cnt_bytes + 1;
                    sample_hdr  <= '1';
                    st_master   <= ST_CHK_PORT;
                elsif(udp_rx.data.data_in_valid = '1' and inhibit_conf = '1' and 
                     (udp_rx.hdr.dst_port = x"1777" or udp_rx.hdr.dst_port = x"19C8"))then
                    cnt_bytes   <= cnt_bytes + 1;
                    sample_hdr  <= '1';
                    st_master   <= ST_CHK_PORT;
                else
                    cnt_bytes   <= (others => '0');
                    sample_hdr  <= '0';
                    st_master   <= ST_IDLE;
                end if;

            -- check the port and activate the corresponding sub-process
            when ST_CHK_PORT =>
                conf_state  <= "001";
                cnt_bytes   <= cnt_bytes + 1;
                
                case udp_rx.hdr.dst_port is
                when x"1778" => -- VMM CONF
                    vmm_conf    <= '1';
                    st_master   <= ST_COUNT;
                when x"19C8" => -- FPGA CONF
                    fpga_conf   <= '1';
                    st_master   <= ST_COUNT;
                when x"1777" => -- FPGA CONF
                    fpga_conf   <= '1';
                    st_master   <= ST_COUNT;
                when x"19CC" => -- FLASH CONF
                    flash_conf  <= '1';
                    st_master   <= ST_COUNT;
                when x"19D0" => -- XADC CONF
                    xadc_conf   <= '1';
                    st_master   <= ST_COUNT;
                when others =>  -- Unknown Port
                    st_master   <= ST_ERROR;
                end case;

            -- keep counting and wait for configuration packets to be formed
            when ST_COUNT =>
                conf_state  <= "010"; 
                cnt_bytes <= cnt_bytes + 1;

                if(xadcPacket_rdy = '1' or flashPacket_rdy = '1' or fpgaPacket_rdy = '1' or vmm_conf_rdy = '1')then
                    st_master <= ST_WAIT_FOR_BUSY;
                else
                    st_master <= ST_COUNT;
                end if;

            -- stop counting and wait for corresponding sub-module to get the init signal
            -- or wait for sub-process to finish
            when ST_WAIT_FOR_BUSY =>
                conf_state  <= "011";
                if(xadcPacket_rdy = '1' and xadc_busy = '1')then
                    xadc_conf   <= '0';
                    st_master   <= ST_WAIT_FOR_IDLE;
                elsif(flashPacket_rdy = '1' and flash_busy = '1')then
                    flash_conf  <= '0';
                    st_master   <= ST_WAIT_FOR_IDLE;
                elsif(fpgaPacket_rdy = '1' and udp_rx.data.data_in_valid = '0')then -- no need to wait, jump to idle state
                    st_master   <= ST_IDLE;
                elsif(vmm_conf_rdy = '1')then -- initialize serialization
                    init_ser    <= '1';
                    vmm_conf    <= '0';
                    st_master   <= ST_RESET_FIFO;
                else
                    st_master   <= ST_WAIT_FOR_BUSY;
                end if;
        
            -- wait for corresponding sub-module to finish processing    
            when ST_WAIT_FOR_IDLE =>
                conf_state  <= "100";
                if(xadc_busy = '0' and flash_busy = '0' and udp_rx.data.data_in_valid = '0')then
                    st_master <= ST_IDLE;
                else
                    st_master <= ST_WAIT_FOR_IDLE;
                end if;

            -- create a reset signal of adequate length. release the reset
            -- only when flow_fsm and sck_fsm are in the appropriate states
            when ST_RESET_FIFO =>
                conf_state  <= "101";
                if(vmmSer_done_s125 = '1' and top_rdy = '0')then -- flow_fsm is back to IDLE + serialization has finished => reset
                    rst_fifo    <= '1';
                    init_ser    <= '0';
                    st_master   <= ST_WAIT_FOR_SCK_FSM;
                else
                    rst_fifo    <= '0';     -- serialization not finished or flow_fsm is not in IDLE, wait
                    init_ser    <= '1';
                    st_master   <= ST_RESET_FIFO;
                end if;

            -- wait for SCK FSM to latch the reset signal
            when ST_WAIT_FOR_SCK_FSM =>
                conf_state  <= "110";
                if(vmmSer_done_s125 = '0' and udp_rx.data.data_in_valid = '0')then
                    rst_fifo    <= '0';
                    st_master   <= ST_IDLE;
                else
                    rst_fifo    <= '1';
                    st_master   <= ST_WAIT_FOR_SCK_FSM;
                end if;
            
            -- stay here until the UDP packet passes    
            when ST_ERROR =>
                conf_state  <= "111";
                if(udp_rx.data.data_in_valid = '0')then
                    st_master   <= ST_IDLE;
                else
                    st_master   <= ST_ERROR;
                end if;

            when others => 
                st_master <= ST_IDLE;
            end case;
        end if;
    end if;
end process;

-- process that samples the header data from the UDP packet
sample_header_proc: process(clk_125)
begin
    if(rising_edge(clk_125))then
        if(sample_hdr = '1')then
            case cnt_bytes is
            ---- sample s/n
            when "00000001" => --1
                serial_number(31 downto 24) <= user_data_prv;
            when "00000010" => --2
                serial_number(23 downto 16) <= user_data_prv;
            when "00000011" => --3
                serial_number(15 downto 8)  <= user_data_prv;
            when "00000100" => --4
                serial_number(7 downto 0)   <= user_data_prv;

            -- sample bitmask
            when "00000110" => --6
                vmm_bitmask                 <= user_data_prv;

            -- sample command
            when "00000111" => --7
                command(15 downto 8)        <= user_data_prv;
            when "00001000" => --8
                command(7 downto 0)         <= user_data_prv;
            when others => null;
            end case;
        else null;
        end if;
    end if;
end process;

fpga_config_logic: fpga_config_block
    port map(
        -----------------------------------
        ------- General Interface ----------
        clk_125             => clk_125,
        rst                 => rst,
        cnt_bytes           => cnt_bytes,
        user_din_udp        => user_data_prv,
        ------------------------------------
        -------- UDP Interface -------------
        udp_rx              => udp_rx,
        ------------------------------------
        ---------- XADC Interface ----------
        xadc_conf           => xadc_conf,
        xadcPacket_rdy      => xadcPacket_rdy,
        vmm_id_xadc         => vmm_id_xadc,
        xadc_sample_size    => xadc_sample_size,
        xadc_delay          => xadc_delay,
        ------------------------------------
        ---------- AXI4SPI Interface -------
        flash_conf          => flash_conf,
        flashPacket_rdy     => flashPacket_rdy,
        myIP_set            => myIP_set,
        myMAC_set           => myMAC_set,
        destIP_set          => destIP_set,
        ------------------------------------
        -------- CKTP/CKBC Interface -------
        ckbc_freq           => ckbc_freq,
        cktk_max_num        => cktk_max_num,
        cktp_max_num        => cktp_max_num,
        cktp_skew           => cktp_skew,
        cktp_period         => cktp_period,
        cktp_width          => cktp_width,
        ------------------------------------
        -------- FPGA Config Interface -----
        fpga_conf           => fpga_conf,
        fpga_rst            => fpga_rst_i,
        fpgaPacket_rdy      => fpgaPacket_rdy,
        latency             => latency,
        tr_delay_limit      => tr_delay_limit,
        ckbc_max_num        => ckbc_max_num,
        daq_on              => daq_on,
        ext_trigger         => ext_trigger,
        ckbcMode            => ckbcMode
    );

vmm_config_logic: vmm_config_block
    port map(
        ------------------------------------
        ------- General Interface ----------
        clk_125             => clk_125,
        clk_40              => clk_40,
        rst                 => rst,
        rst_fifo            => rst_fifo_s40,
        cnt_bytes           => cnt_bytes,
        ------------------------------------
        --------- FIFO/UDP Interface -------
        user_din_udp        => user_data_prv,
        user_valid_udp      => user_valid_prv,
        user_last_udp       => user_last_prv,
        ------------------------------------
        ------ VMM Config Interface --------
        vmmConf_rdy         => vmm_conf_rdy,
        vmmConf_done        => vmm_ser_done,
        vmm_sck             => vmm_sck,
        vmm_cs              => vmm_cs,
        vmm_cfg_bit         => vmm_cfg_bit,
        vmm_conf            => vmm_conf,
        top_rdy             => top_rdy_s40,
        init_ser            => init_ser_s40
    );

    xadc_rdy        <= xadcPacket_rdy;
    newIP_rdy       <= flashPacket_rdy;
    vmmConf_rdy     <= init_ser;
    vmmConf_done    <= vmmSer_done_s125;
    state_o         <= std_logic_vector(conf_state);
    valid_o         <= user_valid_prv;
    vmmConf_came    <= vmm_conf;

glbl_rst_buf: BUFG port map (O => fpga_rst, I => fpga_rst_i);

---------------------------------------------------------
--------- Clock Domain Crossing Sync Block --------------
---------------------------------------------------------

CDCC_125to40: CDCC
    generic map(NUMBER_OF_BITS => 3)
    port map(
        clk_src         => clk_125,
        clk_dst         => clk_40,
  
        data_in(0)      => init_ser,
        data_in(1)      => rst_fifo,
        data_in(2)      => top_rdy,
        data_out_s(0)   => init_ser_s40,
        data_out_s(1)   => rst_fifo_s40,
        data_out_s(2)   => top_rdy_s40
    );

CDCC_40to125: CDCC
    generic map(NUMBER_OF_BITS => 1)
    port map(
        clk_src         => clk_40,
        clk_dst         => clk_125,
  
        data_in(0)      => vmm_ser_done,
        data_out_s(0)   => vmmSer_done_s125
    );
---------------------------------------------------------
---------------------------------------------------------
---------------------------------------------------------

end RTL;