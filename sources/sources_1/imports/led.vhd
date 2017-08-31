----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Alfonso Amayuelas Fernandez (alfonso.amayuelas.fernandez@cern.ch)
-- 
-- Create Date: 06/29/2017 05:25:37 PM
-- Design Name: 
-- Module Name: led - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity led is
 Port ( clk,enable : in std_logic;
        led_out     : out  std_logic_vector (3 downto 0)
         );
end led;

architecture Behavioral of led is
    type state_type is (ST0, ST1, ST2, ST3, ST4);
    signal state        : state_type;
    signal  count       : unsigned(22 downto 0) := (others => '0');
    constant thr_int    : unsigned(22 downto 0) := "11111111111111111111111";
    
begin


    general_proc : process (clk)
    

    begin
            
        if (rising_edge(clk))   then
            
        
            if (enable = '0') then
                count <= (others => '0');
                state <= ST0;
                led_out <= "0000";
                
            else
                case state is 
                    when ST0 => 
                        led_out <= "0000";
                        if (count = thr_int) then
                            count <= (others => '0');
                            state <= ST1;
                        else
                            count <= count + 1;
                            state <= ST0;
                        end if;
                    when ST1 =>
                        led_out <= "0001";
                        if (count = thr_int) then
                            count <= (others => '0');
                            state <= ST2;
                         else
                            count <= count + 1;
                            state <= ST1;
                         end if;
                    when ST2 =>
                        led_out <= "0010";
                        if (count = thr_int) then 
                            count <= (others => '0');
                            state <= ST3;
                        else
                            count <= count + 1;
                            state <= ST2;
                        end if;
                    when ST3 =>
                        led_out <= "0100";
                        if (count = thr_int) then
                            count <= (others => '0');
                            state <= ST4;
                        else
                            count <= count + 1;
                            state <= ST3;
                        end if;
                        
                    when ST4 =>
                        led_out <= "1000";
                        if (count = thr_int) then
                            count <= (others => '0');
                            state <= ST1;
                        else
                            count <= count + 1;
                            state <= ST4;
                        end if;
                    
                    when others =>
                        count <= (others => '0');
                        state <= ST0;
                        led_out <= "0000";
                        
                   end case;
                end if;
              end if;
           
    end process general_proc;
 

end Behavioral;
