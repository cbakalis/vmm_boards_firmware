----------------------------------------------------------------------------------
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
-- Design Name: FPGA Configuration Block
-- Module Name: fpga_config_block - RTL
-- Project Name: MMFE8 - NTUA
-- Target Devices: Artix7 xc7a200t-2fbg484 and xc7a200t-3fbg484
-- Tool Versions: Vivado 2016.2
-- Description: Module that samples the data coming from the UDP/Ethernet
-- to produce various control signals for the FPGA user logic. It controls
-- the configuration of the XADC/AXI4SPI_FLASH modules and more general
-- FPGA commands.

-- Dependencies: MMFE8 NTUA Project
-- 
-- Changelog:
-- 07.03.2017 Changed FPGA_conf_proc to accomodate CKBC/CKTP configuration
-- and future register address configuration scheme. (Christos Bakalis)
-- 14.03.2017 Register address configuration scheme deployed. (Christos Bakalis)
-- 17.03.2017 Added synchronizers for daq and trigger signals. (Christos Bakalis)
-- 31.03.2017 Added 2 ckbc mode register (Paris)
-- 05.08.2017 Added fpga_config_router and fpga_config_buffer to optimize the 
-- FPGA configuration scheme. (Christos Bakalis)
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

use work.axi.all;
use work.ipv4_types.all;
use work.arp_types.all;

entity fpga_config_block is
    port(
    ------------------------------------
    ------- General Interface ----------
    clk_125             : in  std_logic;
    rst                 : in  std_logic;
    rst_fifo_init       : in  std_logic;
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
    ckbc_max_num        : out std_logic_vector(7 downto 0);
    ------------------------------------
    -------- FPGA Config Interface -----
    fpga_conf           : in  std_logic;
    fpga_rst            : out std_logic;
    fpgaPacket_rdy      : out std_logic;
    latency             : out std_logic_vector(15 downto 0);
    latency_extra       : out std_logic_vector(15 downto 0);
    tr_delay_limit      : out std_logic_vector(15 downto 0);
    daq_on              : out std_logic;
    ext_trigger         : out std_logic;
    ckbcMode            : out std_logic;
    artTimeout          : out std_logic_vector(7 downto 0)
    );
end fpga_config_block;

architecture RTL of fpga_config_block is

component fpga_reg_buffer
  port (
    rst         : in  std_logic;
    wr_clk      : in  std_logic;
    rd_clk      : in  std_logic;
    din         : in  std_logic_vector(31 downto 0);
    wr_en       : in  std_logic;
    rd_en       : in  std_logic;
    dout        : out std_logic_vector(31 downto 0);
    full        : out std_logic;
    empty       : out std_logic;
    wr_rst_busy : out std_logic;
    rd_rst_busy : out std_logic
  );
end component;

component fpga_config_router
    port(
    ------------------------------------
    ------ General Interface -----------
    clk_125             : in std_logic;
    reg_addr            : in std_logic_vector(7 downto 0);
    reg_rst             : in std_logic;
    reg_value_bit       : in std_logic;
    sreg_ena            : in std_logic;
    ------------------------------------
    ---------- XADC Interface ----------
    vmm_id_xadc         : out std_logic_vector(15 downto 0);
    xadc_sample_size    : out std_logic_vector(10 downto 0);
    xadc_delay          : out std_logic_vector(17 downto 0);
    ------------------------------------
    ---------- AXI4SPI Interface -------
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
    latency             : out std_logic_vector(15 downto 0);
    latency_extra       : out std_logic_vector(15 downto 0);
    tr_delay_limit      : out std_logic_vector(15 downto 0);
    ckbc_max_num        : out std_logic_vector(7 downto 0);
    daq_state           : out std_logic_vector(7 downto 0);
    trig_state          : out std_logic_vector(7 downto 0);
    ro_state            : out std_logic_vector(7 downto 0);
    fpga_rst_state      : out std_logic_vector(7 downto 0);
    artTimeout          : out std_logic_vector(7 downto 0)
    );
end component;
    
    -- register the address/value and valid signal from UDP packet
    signal reg_address      : std_logic_vector(7 downto 0)  := (others => '0');
    signal reg_value        : std_logic_vector(31 downto 0) := (others => '0');
    signal din_valid        : std_logic := '0';
    signal din_last         : std_logic := '0';

    -- FPGA reset signals
    signal reg_rst          : std_logic := '0';
    signal rst_cnt          : integer range 0 to 63 := 0;

    -- other
    signal fpgaPacket_rdy_i : std_logic := '0';

    -- FSM, demux signals
    signal wait_cnt         : unsigned(4 downto 0) := (others => '0');
    signal reg_index        : integer range 0 to 31 := 31;
    signal reg_value_bit    : std_logic := '0';
    signal sreg_en          : std_logic := '0';
    signal read_buffers     : std_logic := '0';
    type stateType is (ST_IDLE, ST_CHK, ST_WAIT, ST_WRH_SREG, ST_WRL_SREG, ST_DONE);
    signal state : stateType := ST_IDLE;
    attribute FSM_ENCODING          : string;
    attribute FSM_ENCODING of state : signal is "ONE_HOT";

    -- signals for the FIFOs
    signal wr_en            : std_logic := '0';
    signal rd_en            : std_logic := '0';
    signal rst_fifo         : std_logic := '0';
    signal din_regAddr      : std_logic_vector(31 downto 0) := (others => '0');
    signal dout_regAaddr    : std_logic_vector(31 downto 0) := (others => '0');
    signal dout_regValue    : std_logic_vector(31 downto 0) := (others => '0');
    signal addr_buffer_full : std_logic := '0';
    signal addr_buffer_empty: std_logic := '0';
    signal val_buffer_full  : std_logic := '0';
    signal val_buffer_empty : std_logic := '0';
    signal addr_rdRst_busy  : std_logic := '0';
    signal addr_wrRst_busy  : std_logic := '0';
    signal val_rdRst_busy   : std_logic := '0';
    signal val_wrRst_busy   : std_logic := '0';

    -- internal registers and synchronizer signals
    signal daq_state_reg    : std_logic_vector(7 downto 0)  := (others => '0');
    signal trig_state_reg   : std_logic_vector(7 downto 0)  := (others => '0');
    signal ro_state_reg     : std_logic_vector(7 downto 0)  := (others => '0');
    signal fpga_rst_reg     : std_logic_vector(7 downto 0)  := (others => '0');
    signal daq_on_i         : std_logic := '0';
    signal daq_on_sync      : std_logic := '0';
    signal ext_trg_i        : std_logic := '0';
    signal ext_trg_sync     : std_logic := '0';
    signal fpga_rst_i       : std_logic := '0';
    signal ckbcMode_i       : std_logic := '0';
    signal ckbcMode_sync    : std_logic := '0';

    -- async_regs
    attribute ASYNC_REG : string;
    
    attribute ASYNC_REG of daq_on        : signal is "true";
    attribute ASYNC_REG of daq_on_sync   : signal is "true";
    attribute ASYNC_REG of ext_trigger   : signal is "true";
    attribute ASYNC_REG of ext_trg_sync  : signal is "true";
    attribute ASYNC_REG of ckbcMode      : signal is "true";
    attribute ASYNC_REG of ckbcMode_sync : signal is "true";

begin
    
-- register the valid signal
reg_valid_proc: process(clk_125)
begin
    if(rising_edge(clk_125))then
        din_valid <= udp_rx.data.data_in_valid;
        din_last  <= udp_rx.data.data_in_last;
    end if;
end process;

-- sub-process that samples register addresses and values for FPGA/xADC/Flash-IP configuration
FPGA_conf_proc: process(clk_125)
begin
    if(rising_edge(clk_125))then
        if(rst = '1')then
            reg_address     <= (others => '0');
            reg_value       <= (others => '0');
        else
            if((fpga_conf = '1' or flash_conf = '1' or xadc_conf = '1') and din_valid = '1')then
                case cnt_bytes is
                ----------------------------
                --- register addresses -----
                when "00001100" => -- 12
                    reg_address <= user_din_udp;
                when "00010100" => -- 20
                    reg_address <= user_din_udp;
                when "00011100" => -- 28
                    reg_address <= user_din_udp;
                when "00100100" => -- 36
                    reg_address <= user_din_udp;
                when "00101100" => -- 44
                    reg_address <= user_din_udp;
                when "00110100" => -- 52
                    reg_address <= user_din_udp;
                when "00111100" => -- 60
                    reg_address <= user_din_udp;
                ----------------------------
                --- register values --------
                when "00001101" => -- 13
                    reg_value(31 downto 24)    <= user_din_udp;
                when "00001110" => -- 14
                    reg_value(23 downto 16)    <= user_din_udp;
                when "00001111" => -- 15
                    reg_value(15 downto 8)     <= user_din_udp;
                when "00010000" => -- 16
                    reg_value(7 downto 0)      <= user_din_udp;
                ----------------------------
                when "00010101" => -- 21
                    reg_value(31 downto 24)    <= user_din_udp;
                when "00010110" => -- 22
                    reg_value(23 downto 16)    <= user_din_udp;
                when "00010111" => -- 23
                    reg_value(15 downto 8)     <= user_din_udp;
                when "00011000" => -- 24
                    reg_value(7 downto 0)      <= user_din_udp;
                ----------------------------
                when "00011101" => -- 29
                    reg_value(31 downto 24)    <= user_din_udp;
                when "00011110" => -- 30
                    reg_value(23 downto 16)    <= user_din_udp;
                when "00011111" => -- 31
                    reg_value(15 downto 8)     <= user_din_udp;
                when "00100000" => -- 32
                    reg_value(7 downto 0)      <= user_din_udp;
                ----------------------------
                when "00100101" => -- 37
                    reg_value(31 downto 24)    <= user_din_udp;
                when "00100110" => -- 38
                    reg_value(23 downto 16)    <= user_din_udp;
                when "00100111" => -- 39
                    reg_value(15 downto 8)     <= user_din_udp;
                when "00101000" => -- 40
                    reg_value(7 downto 0)      <= user_din_udp;
                ----------------------------
                when "00101101" => -- 45
                    reg_value(31 downto 24)    <= user_din_udp;
                when "00101110" => -- 46
                    reg_value(23 downto 16)    <= user_din_udp;
                when "00101111" => -- 47
                    reg_value(15 downto 8)     <= user_din_udp;
                when "00110000" => -- 48
                    reg_value(7 downto 0)      <= user_din_udp;
                ----------------------------
                when "00110101" => -- 53
                    reg_value(31 downto 24)    <= user_din_udp;
                when "00110110" => -- 54
                    reg_value(23 downto 16)    <= user_din_udp;
                when "00110111" => -- 55
                    reg_value(15 downto 8)     <= user_din_udp;
                when "00111000" => -- 56
                    reg_value(7 downto 0)      <= user_din_udp;
                ----------------------------
                when "00111101" => -- 61
                    reg_value(31 downto 24)    <= user_din_udp;
                when "00111110" => -- 62
                    reg_value(23 downto 16)    <= user_din_udp;
                when "00111111" => -- 63
                    reg_value(15 downto 8)     <= user_din_udp;
                when "01000000" => -- 64
                    reg_value(7 downto 0)      <= user_din_udp;
                ----------------------------
                when "01000100" => -- 68
                    read_buffers <= '1';
                when others => null;
                end case;
            elsif((fpga_conf = '1' or flash_conf = '1' or xadc_conf = '1') and din_valid = '0')then
                read_buffers <= '1';
            else
                read_buffers <= '0';
            end if;
        end if;
    end if;
end process;

-- process that controls the write-enable signal
wr_ena_proc: process(clk_125)
begin
    if(rising_edge(clk_125))then
        if((fpga_conf = '1' or flash_conf = '1' or xadc_conf = '1') and din_valid = '1' and din_last = '0')then
            case cnt_bytes is
            --        18           26           34           42           50           58           66     
            when  "00010010" | "00011010" | "00100010" | "00101010" | "00110010" | "00111010" | "01000010" =>
                wr_en <= '1';
            --        19           27           35           43           51           59           67     
            when  "00010011" | "00011011" | "00100011" | "00101011" | "00110011" | "00111011" | "01000011" =>
                wr_en <= '0';
            when others => 
                wr_en <= '0';
            end case;
        elsif((fpga_conf = '1' or flash_conf = '1' or xadc_conf = '1') and din_valid = '1' and din_last = '1')then
            wr_en <= '1';
        else
            wr_en <= '0';
        end if;
    end if;
end process;

-- FSM that reads the two FIFOs and fills the shift registers
FSM_FPGA_conf: process(clk_125)
begin
    if(rising_edge(clk_125))then
        --reg_value_bit   <= dout_regValue(reg_index); -- userclk2 clock domain

        if(fpga_conf = '0' and flash_conf = '0' and xadc_conf = '0')then
            rd_en               <= '0';
            sreg_en             <= '0';
            reg_index           <= 31;
            fpgaPacket_rdy_i    <= '0';
            flashPacket_rdy     <= '0';
            xadcPacket_rdy      <= '0';
            wait_cnt            <= (others => '0');
            state               <= ST_IDLE;
        else
            case state is

            -- wait to be activated by registering process
            when ST_IDLE =>
                if(read_buffers = '1' and wait_cnt = "11111")then
                    wait_cnt    <= (others => '0');
                    state       <= ST_CHK;
                elsif(read_buffers = '1' and wait_cnt /= "11111")then
                    wait_cnt    <= wait_cnt + 1;
                    state       <= ST_IDLE;
                else
                    wait_cnt    <= (others => '0');
                    state       <= ST_IDLE;
                end if;

            -- check if the FIFOs are empty
            when ST_CHK =>
                if(addr_buffer_empty = '0' and val_buffer_empty = '0')then
                    rd_en <= '1';
                    state <= ST_WAIT;
                else
                    rd_en <= '0';
                    state <= ST_DONE;
                end if;

            -- wait here for MUX and shift register
            when ST_WAIT =>
                rd_en       <= '0';
                wait_cnt    <= wait_cnt + 1;

                if(wait_cnt = "00111")then
                    state <= ST_WRH_SREG;
                else
                    state <= ST_WAIT;
                end if;

            -- write the shift register
            when ST_WRH_SREG =>
                sreg_en <= '1';
                state   <= ST_WRL_SREG;

            -- check the index
            when ST_WRL_SREG =>
                sreg_en     <= '0';

                if(reg_index = 0)then -- sent the entire register value
                    reg_index   <= 31;
                    state       <= ST_CHK;
                else
                    reg_index   <= reg_index - 1;
                    state       <= ST_WAIT;
                end if;

            -- wait here until reset by master_handling_FSM
            when ST_DONE =>   
                if(fpga_conf = '1')then
                    fpgaPacket_rdy_i    <= '1';
                elsif(flash_conf = '1')then
                    flashPacket_rdy     <= '1';
                elsif(xadc_conf = '1')then
                    xadcPacket_rdy      <= '1';
                else
                    fpgaPacket_rdy_i    <= '1';
                end if;

                state   <= ST_DONE;    

            when others =>
                rd_en               <= '0';
                sreg_en             <= '0';
                reg_index           <= 31;
                fpgaPacket_rdy_i    <= '0';
                flashPacket_rdy     <= '0';
                xadcPacket_rdy      <= '0';
                wait_cnt            <= (others => '0');
                state               <= ST_IDLE;
            end case;
        end if;
    end if;
end process;

fpga_conf_router_inst: fpga_config_router
    port map(
    ------------------------------------
    ------ General Interface -----------
    clk_125             => clk_125,
    reg_addr            => dout_regAaddr(7 downto 0),
    reg_rst             => reg_rst,
    reg_value_bit       => reg_value_bit,
    sreg_ena            => sreg_en,
    ------------------------------------
    ---------- XADC Interface ----------
    vmm_id_xadc         => vmm_id_xadc,
    xadc_sample_size    => xadc_sample_size,
    xadc_delay          => xadc_delay,
    ------------------------------------
    ---------- AXI4SPI Interface -------
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
    latency             => latency,
    latency_extra       => latency_extra,
    tr_delay_limit      => tr_delay_limit,
    ckbc_max_num        => ckbc_max_num,
    daq_state           => daq_state_reg,
    trig_state          => trig_state_reg,
    ro_state            => ro_state_reg,
    fpga_rst_state      => fpga_rst_reg,
    artTimeout          => artTimeout
    );

reg_addr_buffer: fpga_reg_buffer
    PORT MAP (
        rst         => rst_fifo,
        wr_clk      => clk_125,
        rd_clk      => clk_125,
        din         => din_regAddr,
        wr_en       => wr_en,
        rd_en       => rd_en,
        dout        => dout_regAaddr,
        full        => addr_buffer_full,
        empty       => addr_buffer_empty,
        wr_rst_busy => addr_rdRst_busy,
        rd_rst_busy => addr_wrRst_busy
    );

reg_value_buffer: fpga_reg_buffer
    PORT MAP (
        rst         => rst_fifo,
        wr_clk      => clk_125,
        rd_clk      => clk_125,
        din         => reg_value,
        wr_en       => wr_en,
        rd_en       => rd_en,
        dout        => dout_regValue,
        full        => val_buffer_full,
        empty       => val_buffer_empty,
        wr_rst_busy => val_rdRst_busy,
        rd_rst_busy => val_wrRst_busy
    );

-- FPGA reset asserter
rst_asserter_proc: process(clk_125)
begin
    if(rising_edge(clk_125))then
        if(fpga_rst_i = '1')then
            case rst_cnt is
            when 0 to 62 =>
                fpga_rst <= '1';
                rst_cnt  <= rst_cnt + 1;
            when 63 =>
                fpga_rst <= '0';
                reg_rst  <= '1';
            when others =>
                rst_cnt  <= 0;
                fpga_rst <= '0';
                reg_rst  <= '0';
            end case;
        else
            rst_cnt  <= 0;
            fpga_rst <= '0';
            reg_rst  <= '0';
        end if;
    end if;
end process;

    din_regAddr     <= x"000000" & reg_address;
    fpgaPacket_rdy  <= fpgaPacket_rdy_i;

-- process to handle daq state
daqOnOff_proc: process(daq_state_reg, daq_on_i, fpgaPacket_rdy_i)
begin
    if(fpgaPacket_rdy_i = '1')then
        case daq_state_reg is
        when x"01"  => daq_on_i <= '1';
        when x"00"  => daq_on_i <= '0';
        when others => daq_on_i <= daq_on_i;
        end case;
    else
        daq_on_i <= daq_on_i;
    end if;
end process;

-- process to handle trigger state
triggerState_proc: process(trig_state_reg, ext_trg_i, fpgaPacket_rdy_i)
begin
    if(fpgaPacket_rdy_i = '1')then
        case trig_state_reg is
        when x"04"  => ext_trg_i <= '1';
        when x"07"  => ext_trg_i <= '0';
        when others => ext_trg_i <= ext_trg_i;
        end case;
    else
        ext_trg_i   <= ext_trg_i;
    end if;
end process;

-- process to handle readout state
readoutState_proc: process(ro_state_reg, ckbcMode_i, fpgaPacket_rdy_i)
begin
    if(fpgaPacket_rdy_i = '1')then
        case ro_state_reg is
        when x"01"  => ckbcMode_i <= '1';
        when x"00"  => ckbcMode_i <= '0';
        when others => ckbcMode_i <= ckbcMode_i;
        end case;
    else
        ckbcMode_i <= ckbcMode_i;
    end if;
end process;

-- process to handle FPGA reset state
FPGArst_proc: process(fpga_rst_reg, fpga_rst_i, fpgaPacket_rdy_i)
begin
    if(fpgaPacket_rdy_i = '1')then
        case fpga_rst_reg is
        when x"aa"  => fpga_rst_i <= '1';
        when x"00"  => fpga_rst_i <= '0';
        when others => fpga_rst_i <= fpga_rst_i;
        end case;
    else
        fpga_rst_i <= fpga_rst_i;
    end if;
end process;

-- synchronizing circuit
syncProc: process(clk_125)
begin
    if(rising_edge(clk_125))then
        daq_on_sync     <= daq_on_i;
        daq_on          <= daq_on_sync;
        ext_trg_sync    <= ext_trg_i;
        ext_trigger     <= ext_trg_sync;
        ckbcMode_sync   <= ckbcMode_i;
        ckbcMode        <= ckbcMode_sync;
    end if;
end process;

    reg_value_bit   <= dout_regValue(reg_index);                  -- userclk2 clock domain
    rst_fifo        <= rst or fpgaPacket_rdy_i or rst_fifo_init;  -- reset the FIFOs after each configuration

end RTL;
