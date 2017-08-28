----------------------------------------------------------------------------------------
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
-- Design Name: VMM Configuration Block
-- Module Name: vmm_config_block - RTL
-- Project Name: MMFE8 - NTUA
-- Target Devices: Artix7 xc7a200t-2fbg484 and xc7a200t-3fbg484
-- Tool Versions: Vivado 2016.2
-- Description: Module that stores the data coming from the UDP/Ethernet for VMM
-- configuration using a FIFO serializer. It also drives the SCK and CS signals.

-- Dependencies: MMFE8 NTUA Project
-- 
-- Changelog:
-- 16.02.2017 Modified the serialization FSM for VMM3 configuration. (Christos Bakalis)
-- 28.03.2017 VMM_ID is now sampled one level above. (Christos Bakalis)
--
----------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity vmm_config_block is
    port(
    ------------------------------------
    ------- General Interface ----------
    clk_125             : in  std_logic;
    clk_40              : in  std_logic;
    rst                 : in  std_logic;
    rst_ram             : in  std_logic;
    cnt_bytes           : in  unsigned(7 downto 0);
    ------------------------------------
    --------- FIFO/UDP Interface -------
    user_din_udp        : in  std_logic_vector(7 downto 0); --prv
    user_valid_udp      : in  std_logic; --prv
    user_last_udp       : in  std_logic; --prv
    ------------------------------------
    ------ VMM Config Interface --------
    vmmConf_rdy         : out std_logic;
    vmmConf_done        : out std_logic;
    vmm_sck             : out std_logic;
    vmm_cs              : out std_logic;
    vmm_cfg_bit         : out std_logic;
    vmm_conf            : in  std_logic;
    top_rdy             : in  std_logic;
    init_ser            : in  std_logic;
    first_rd_done       : out std_logic;
    second_rd_start     : out std_logic
    );
end vmm_config_block;

architecture RTL of vmm_config_block is


    
    COMPONENT vmm_conf_ram
      PORT (
        clka    : IN STD_LOGIC;
        ena     : IN STD_LOGIC;
        wea     : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra   : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        dina    : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        clkb    : IN STD_LOGIC;
        enb     : IN STD_LOGIC;
        addrb   : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
        doutb   : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
      );
    END COMPONENT;

    signal rd_ena           : std_logic := '0';
    signal sel_vmm_data     : std_logic := '0';
    signal user_valid_ram  : std_logic := '0';
    signal addr_ram_wr      : std_logic_vector (7 downto 0);
    signal ram_ena          : std_logic := '1';
    signal wr_ready         : std_logic := '0';
    
    signal clk_count_ctrl   : integer range 0 to 3 := 0;
    signal sck_count        : integer range 0 to 95 := 0;
    signal cs_i             : std_logic := '0';
    signal cs_mux_out       : std_logic := '0';
    
    signal addr_rd_cnt      : integer range 0 to 1799 := 0;
    signal addr_ram_rd      : std_logic_vector (10 downto 0); 
    signal clk_count_rd     : integer range 0 to 9 := 0;
    signal rd_en            : std_logic := '0';
    signal rd_en_i          : std_logic := '0';
    signal times            : integer := 0;
    signal wait_cnt         : integer range 0 to 101 := 0;

    
    TYPE    ctrlFSM     IS (ST0, ST1, ST2, ST3, ST4);
    SIGNAL  ctrl_state  : ctrlFSM := ST0;
    
    TYPE    confFSM     IS (STIDLE, ST0, ST1, ST2, ST3);
    SIGNAL  conf_state  : confFSM := STIDLE;
    


begin


-- sub-process that drives the data into the RAM used for VMM configuration. 
-- it also detects the 'last' pulse sent from the UDP block to initialize the 
-- VMM config data serialization
VMM_conf_proc: process(clk_125)
begin
    if(rising_edge(clk_125))then
        if(rst = '1')then
            sel_vmm_data    <= '0';
            wr_ready        <= '0';
        else
            if(vmm_conf = '1' and user_last_udp = '0' and user_valid_udp = '1')then
                case cnt_bytes is 
                when "00001000" => --8
                    sel_vmm_data        <= '1'; -- select the correct data at the MUX
                when others => null;
                end case;
            elsif(vmm_conf = '1' and user_last_udp = '1')then -- 'last' pulse detected, signal master FSM
                wr_ready    <= '1';
            else
                wr_ready    <= '0';
                sel_vmm_data   <= '0';
            end if;
        end if;
    end if;
end process;

vmmConf_rdy <= wr_ready;

-- MUX that drives the VMM configuration data into the FIFO
RAM_valid_MUX: process(sel_vmm_data, user_valid_udp)
begin
    case sel_vmm_data is
    when '0'    =>  user_valid_ram <= '0';
    when '1'    =>  user_valid_ram <= user_valid_udp;
    when others =>  user_valid_ram <= '0';
    end case;
end process;



-- FSM that reads the data from the serializing FIFO  and asserts the SCK pulse 
-- after the bit has passed safely into the vmm configuration bus. serialization 
-- starts only after the assertion of the 'last' signal from the UDP block (see VMM_conf_proc)
VMM_conf_SCK_FSM: process(clk_40)
begin
    if(rising_edge(clk_40))then
         if(rst = '1')then
            rd_en_i         <= '0';
            vmmConf_done    <= '0';
            clk_count_rd    <= 0;
            addr_rd_cnt     <= 72;
            conf_state      <= STIDLE;
            first_rd_done   <= '0';
            second_rd_start <= '0';
            wait_cnt        <=  0;
         else
            case conf_state is
                when STIDLE =>
                    if(wr_ready = '1')then  -- changing user_last_udp for vmmConf_rdy
                        conf_state <= ST0;
                    else
                        conf_state <= STIDLE;
                    end if;
                when ST0 =>
                    vmmConf_done <= '0';
                    rd_en_i      <= '1';
                    conf_state   <= ST1;
                when ST1 =>
                    rd_en_i <= '0';
                    if (clk_count_rd = 8) then
                        if (addr_rd_cnt = 1799) then
                            conf_state <= ST2;
                        else
                            addr_rd_cnt     <= addr_rd_cnt + 1;
                            clk_count_rd    <= 0;
                            conf_state      <= ST0;
                        end if;
                    else
                        clk_count_rd <= clk_count_rd + 1;
                        conf_state   <= ST1;
                    end if;
                when ST2 =>
                    clk_count_rd    <= 0;
                    addr_rd_cnt     <= 72;
                    if (times = 0) then
                        times           <= times + 1;
                        first_rd_done   <= '1';
                        conf_state      <= ST3;
                    else
                        vmmConf_done <= '1';
                        conf_state   <= ST2;
                    end if;
                when ST3 =>
                    if (wait_cnt = 100) then
                        second_rd_start <= '1';
                        wait_cnt        <= 0;
                        conf_state      <= ST0;
                    else
                        wait_cnt    <= wait_cnt + 1;
                        conf_state  <= ST3;
                    end if;
                when others =>
                    conf_state <= STIDLE;
                end case;
          end if;
    end if;
end process;

rd_en <= rd_en_i;

VMM_ctrl_FSM: process(clk_40)
begin
if rising_edge(clk_40) then
    if (rst = '1') then
        clk_count_ctrl <= 0;
        sck_count      <= 0;
        vmm_sck        <= '0';
        cs_i           <= '0';
        ctrl_state     <= ST0;
    else
        case ctrl_state is
            when ST0 =>
                vmm_sck <= '0';
                cs_i    <= '0';
                if (rd_en = '1') then
                    ctrl_state <= ST1;
                else
                    ctrl_state <= ST0;
                end if;
            when ST1 =>
                if (clk_count_ctrl = 3) then
                    clk_count_ctrl <= 0;
                    vmm_sck        <= '1';
                    sck_count <= sck_count + 1;
                    if (sck_count = 95) then
                        ctrl_state <= ST2;
                    else
                        ctrl_state <= ST0;
                    end if;
                else
                    clk_count_ctrl <= clk_count_ctrl + 1;
                    vmm_sck        <= '0';
                    ctrl_state     <= ST1;
                end if;
            when ST2 =>
                vmm_sck    <= '0';
                sck_count  <= 0;
                ctrl_state <= ST3;
            when ST3 =>
                 cs_i       <= '1';
                 ctrl_state <= ST0;
            when others =>
                ctrl_state <= ST0;
            end case;
                
            end if;
            
        end if;
    
    end process;
    

    
-- MUX     
mux_VMM_ctrl_rd : process(addr_ram_wr, cs_i)
begin
    if(addr_ram_wr = x"707")then --addr 1799
        cs_mux_out <= '0';
    else
        cs_mux_out <= cs_i;
    end if;
end process;

delay_cs: process(clk_40)
begin
    if(rising_edge(clk_40))then
        vmm_cs <= cs_mux_out;
    end if;
end process;   


addr_ram_wr <= std_logic_vector(cnt_bytes);
      
-- RAM 
RAM_serializer : vmm_conf_ram
  PORT MAP (
    clka     =>  clk_125,
    ena      =>  ram_ena,
    wea(0)   =>  user_valid_ram,
    addra    =>  addr_ram_wr,   
    dina     =>  user_din_udp,
    clkb     =>  clk_40,
    enb      =>  rd_en,
    addrb    =>  addr_ram_rd,
    doutb(0) =>  vmm_cfg_bit
  );
      
addr_ram_rd    <=  std_logic_vector(to_unsigned(addr_rd_cnt, addr_ram_rd'length));


end RTL;
