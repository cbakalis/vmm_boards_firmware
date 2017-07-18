----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    05/19/2015 
--! Module Name:    EPROC_IN2_HDLC
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee, work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.centralRouter_package.all;
use work.all;

--! HDLC decoder for EPROC_IN2 module
entity EPROC_IN2_HDLC is
port (  
    bitCLK      : in  std_logic;
    bitCLKx2    : in  std_logic;
    rst         : in  std_logic;
    ena         : in  std_logic;
    edataIN     : in  std_logic_vector (1 downto 0);
    dataOUT     : out std_logic_vector(9 downto 0);
    dataOUTrdy  : out std_logic
    );
end EPROC_IN2_HDLC;

architecture Behavioral of EPROC_IN2_HDLC is

----------------------------------
----------------------------------

signal edataIN_r : std_logic_vector (1 downto 0) := (others=>'1'); 
signal bit_in_sr,out_sr : std_logic_vector (7 downto 0) := (others=>'1'); 
signal bit_cnt,error_bit_cnt : std_logic_vector (2 downto 0) := (others=>'0'); 
signal error_state,error_state_r,error_out : std_logic := '1';
signal edataIN_latch_trig,bit_in,isflag_r,isflag_rr,bit_in_r,bit_in_r_we,remove_zero_r : std_logic := '0';
signal isflag,iserror,remove_zero,out_sr_rdy,dataOUTrdy_s,error_out_rdy,remove_zero_state : std_logic;

begin

-------------------------------------------------------------------------------------------
--live bitstream
-- input serializer
-------------------------------------------------------------------------------------------
process(bitCLKx2, rst)
begin
    if rst = '1' then
        edataIN_latch_trig <= '0';
    elsif bitCLKx2'event and bitCLKx2 = '1' then
        edataIN_latch_trig <= not edataIN_latch_trig;
    end if;
end process;
--
process(bitCLKx2, rst)
begin
    if rst = '1' then
        edataIN_r <= (others=>'1');
    elsif bitCLKx2'event and bitCLKx2 = '1' then
        if edataIN_latch_trig = '1' then
            --edataIN_r <= edataIN;
            edataIN_r <= edataIN(0) & edataIN(1); -- HDLC bits are swapped by default
        end if;    
    end if;
end process;
--
process(bitCLKx2)
begin
    if bitCLKx2'event and bitCLKx2 = '1' then
        if edataIN_latch_trig = '0' then
            bit_in <= edataIN_r(0);
        else
            bit_in <= edataIN_r(1);
        end if;
    end if;
end process;
--

-------------------------------------------------------------------------------------------
--clock1
-- input shift register 
-------------------------------------------------------------------------------------------
process(bitCLKx2, rst)
begin
    if rst = '1' then
        bit_in_sr <= (others=>'1');
    elsif bitCLKx2'event and bitCLKx2 = '1' then
        bit_in_sr <= bit_in & bit_in_sr(7 downto 1);
    end if;
end process;
--
isflag      <=  '1' when (bit_in_sr = "01111110") else '0';
iserror     <=  '1' when (bit_in_sr(7 downto 1) = "1111111") else '0';
remove_zero <=  '1' when (bit_in_sr(7 downto 2) = "011111" and isflag = '0' and error_state = '0') else '0';
--
-------------------------------------------------------------------------------------------
--clock2
-- latching the error state, forwarding clean bit sequence
-------------------------------------------------------------------------------------------
process(bitCLKx2, rst)
begin
    if rst = '1' then
        error_state <= '1';
    elsif bitCLKx2'event and bitCLKx2 = '1' then
        if iserror = '1' then
            error_state <= '1';
        elsif isflag = '1' then
            error_state <= '0';
        end if;
    end if;
end process;
--
process(bitCLKx2, rst)
begin
    if rst = '1' then       
        isflag_r        <= '0';
        isflag_rr       <= '0';
        --bit_in_r_we     <= '0';
        remove_zero_r   <= '0';
		error_state_r 	<= '1';
    elsif bitCLKx2'event and bitCLKx2 = '1' then
        isflag_r        <= isflag;
        isflag_rr       <= isflag_r;
        --bit_in_r_we     <= not(error_state or remove_zero);
        remove_zero_r   <= remove_zero;
		error_state_r 	<= error_state;
    end if;
end process;
--
bit_in_r_we     <= not(error_state or remove_zero);
--
bit_in_r <= bit_in_sr(7);
--

-------------------------------------------------------------------------------------------
--clock3
-- output shift register
-------------------------------------------------------------------------------------------
process(bitCLKx2)
begin
    if bitCLKx2'event and bitCLKx2 = '1' then 
        if remove_zero = '0' then 
            out_sr  <= bit_in_r & out_sr(7 downto 1);            
        end if;           
    end if;
end process;
--
process(bitCLKx2, rst)
begin
    if rst = '1' then
        bit_cnt <= (others=>'0');
    elsif bitCLKx2'event and bitCLKx2 = '1' then
        if error_state = '1' then
            bit_cnt <= (others=>'0');
        else
            if bit_in_r_we = '1' or isflag_r = '1' then
                bit_cnt <= bit_cnt + 1;
            end if;
        end if;
    end if;
end process;
--
process(bitCLKx2)
begin
    if rising_edge(bitCLKx2) then 
        if bit_cnt = "111" and error_state = '0' and remove_zero = '0' then
            out_sr_rdy <=  '1';
        else
            out_sr_rdy <=  '0';
        end if;
    end if;
end process;
--


-------------------------------------------------------------------------------------------
--clock3+
-- output latch
------------------------------------------------------------------------------------------- 
dataOUTrdy_s    <= isflag_r or out_sr_rdy or error_out_rdy;
dataOUTrdy      <= dataOUTrdy_s and ena; -- @ bitCLKx2
--out_rdy_pulse: entity work.pulse_pdxx_pwxx generic map(pd=>0,pw=>1) port map(bitCLKx4,dataOUTrdy_s,dataOUTrdy); 
--
process(bitCLKx2)
begin
    if rising_edge(bitCLKx2) then 
        if bit_in_sr /= x"ff" then --IG: problematic exit condition due to 7 ones and not 8 in the shift register, replace the error_out signal with error_state_r
            error_out <= '0'; 
        elsif error_state = '1' then
            error_out <= '1'; 
        end if;        
    end if;
end process;
--
process(bitCLKx2, rst)
begin
    if rst = '1' then
        error_bit_cnt <= (others=>'0');
    elsif bitCLKx2'event and bitCLKx2 = '1' then
--IG        if error_out = '0' then
        if (error_state_r = '0') then --IG
            error_bit_cnt <= (others=>'0');
        else
            error_bit_cnt <= error_bit_cnt + 1;
        end if;
    end if;
end process;
--
--IG error_out_rdy <= '1' when (error_bit_cnt = "001" and error_out = '1') else '0';
error_out_rdy <= '1' when ((error_bit_cnt = "001") and (error_state_r = '1')) else '0';
--
process(bitCLKx2)
begin
    if rising_edge(bitCLKx2) then 
		if error_state_r = '1' and isflag = '1' then
			dataOUT(9 downto 8) <= "10"; -- sop
		elsif error_state_r = '0' and isflag = '1' then
			dataOUT(9 downto 8) <= "01"; -- eop
		else
--IG			dataOUT(9 downto 8) <= error_out & error_out; -- 00-data, 11-error
			dataOUT(9 downto 8) <= error_state_r & error_state_r; -- 00-data, 11-error
		end if;  
    end if;
end process;
--
dataOUT(7 downto 0) <= out_sr;
--




end Behavioral;

