----------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch)
-- 
-- Create Date: 11/03/2016 12:56:56 PM
-- Design Name: ELINK_TX
-- Module Name: e_link_tester - Behavioral
-- Project Name: 
-- Target Devices: Artix7 xc7a200t-2fbg484 and xc7a200t-3fbg484 
-- Tool Versions: Vivado 2016.2
-- Description: 
-- 
-- Dependencies: 
-- 
-- Changelog:
-- 29.11.2016 Changed the data pattern the tester is sending. (Christos Bakalis)
-- 03.12.2016 Minor changes to state order and naming. (Christos Bakalis)
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity elink_daq_tester is
  Port(
    -----------------------------
    ---- general interface ------
    clk_in          : in  std_logic; 
    rst             : in  std_logic;
    tester_ena      : in  std_logic;
    ------------------------------
    ------ elink interface -------
    empty_elink     : in  std_logic;
    wr_en           : out std_logic;
    dout            : out std_logic_vector(17 downto 0)
    );
end elink_daq_tester;

architecture Behavioral of elink_daq_tester is

    signal wait_Cnt     : integer   := 0;
    signal sel          : std_logic_vector(1 downto 0) := (others => '0');
    signal wr_en_i      : std_logic := '0';
    signal init         : std_logic := '1';
    signal check_state  : std_logic_vector(3 downto 0) := (others => '0');

    type stateType is (IDLE, START, DELAY, WRITE_START, STEP_0_MOP, STEP_1_MOP, STEP_2_MOP, 
                       DELAY_MOP, STEP_3_MOP, WRITE_EOP_0, WRITE_EOP_1, DONE_SENDING);
    signal state : stateType := IDLE;

    attribute FSM_ENCODING          : string;
    attribute FSM_ENCODING of state : signal is "ONE_HOT";

begin

fillElinkFsm: process(clk_in)
begin
    if(rising_edge(clk_in))then
        if(rst = '1')then
            check_state <= (others => '0');
            sel         <= (others => '0');
            wr_en_i     <= '0';
            wait_Cnt    <= 0;
            init        <= '1';
            state       <= IDLE;
        else
            case state is
            when IDLE =>
                check_state <= "0001";
                sel         <= "10"; -- select SOP
                wr_en_i     <= '0';

                if(tester_ena = '1' and empty_elink = '1')then -- proceed if elink fifo is empty      
                    state <= DELAY;
                else
                    state <= IDLE;
                end if;
                
            when DELAY =>   -- holding delay allows FIFO2Elink to send comma characters
                check_state <= "0010";
                if(wait_Cnt < 1_000)then
                    wait_Cnt    <= wait_Cnt + 1;
                    state       <= DELAY;
                else
                    wait_Cnt    <= 0;
                    state       <= WRITE_START;
                end if;

            when WRITE_START =>
                check_state <= "0011";
                wr_en_i     <= '1'; -- write SOP
                state       <= STEP_0_MOP;

            when STEP_0_MOP =>
                check_state <= "0100";
                wr_en_i     <= '0';
                state       <= STEP_1_MOP;

            when STEP_1_MOP =>
                check_state <= "0101";
                if(init = '1')then
                    sel         <= "00"; -- select data (1234)
                else
                    sel         <= "11"; -- select data (5678)
                end if;    
                state       <= DELAY_MOP;
                
            when DELAY_MOP =>
                check_state <= "0110";
                state       <= STEP_2_MOP;

            when STEP_2_MOP =>
                check_state <= "0111";
                wr_en_i     <= '1';
                state       <= STEP_3_MOP;

            when STEP_3_MOP =>
                check_state <= "1000";
                wr_en_i     <= '0';
                
                if(wait_Cnt <= 40)then -- write 1234 and 5678 21 times each
                    wait_Cnt    <= wait_Cnt + 1;
                    init        <= not init;
                    state       <= STEP_0_MOP;
                else
                    wait_Cnt    <= 0;
                    init        <= '1'; 
                    sel         <= "01"; -- select EOP
                    state       <= WRITE_EOP_0;
                end if;

            when WRITE_EOP_0 =>
                check_state <= "1001";
                state       <= WRITE_EOP_1;

            when WRITE_EOP_1 =>
                check_state <= "1010";
                wr_en_i     <= '1';
                state       <= DONE_SENDING;

            when DONE_SENDING => -- go back to IDLE
                check_state <= "1011";
                wr_en_i     <= '0';
                state       <= IDLE;

            when others => 
                state <= IDLE;
            end case;
        end if;
    end if;
end process;

muxProc: process(sel)
begin
    case sel is
    when "00" =>    dout <= "00" & x"1234"; -- DATA 1234
    when "01" =>    dout <= "01" & x"0000"; -- EOP
    when "10" =>    dout <= "10" & x"0000"; -- SOP
    when "11" =>    dout <= "00" & x"5678"; -- DATA 5678
    when others =>  dout <= (others => '0'); 
    end case;
end process;

    wr_en           <= wr_en_i;

end Behavioral;
