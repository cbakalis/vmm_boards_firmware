----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    24/01/2016 
--! Module Name:    EPROC_OUT2_HDLC
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library IEEE,work;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use work.centralRouter_package.all;
use work.all;

--! HDLC data mode EPROC_OUT2 module
entity EPROC_OUT2_HDLC is
port(
    bitCLK      : in  std_logic;
    bitCLKx2    : in  std_logic;
    bitCLKx4    : in  std_logic;
    rst         : in  std_logic; 
    getDataTrig : out std_logic;   
    edataIN     : in  std_logic_vector (9 downto 0);
    edataINrdy  : in  std_logic;
    EdataOUT    : out std_logic_vector(1 downto 0)
    );
end EPROC_OUT2_HDLC;

architecture Behavioral of EPROC_OUT2_HDLC is

----------------------------------
----------------------------------
component hdlc_bist_fifo
port (
    rst     : in std_logic;
    wr_clk  : in std_logic;
    rd_clk  : in std_logic;
    din     : in std_logic_vector(8 downto 0);
    wr_en   : in std_logic;
    rd_en   : in std_logic;
    dout    : out std_logic_vector(8 downto 0);
    full    : out std_logic;
    empty   : out std_logic
    );
end component;
----------------------------------
----------------------------------

signal bit_cnt,bit_cnt_r : std_logic_vector (2 downto 0) := (others=>'1');
signal two_bit_out,EdataOUT_s : std_logic_vector (1 downto 0) := (others=>'1');
signal bit_cnt_ena,ce,ce_r,we,re_r,oe : std_logic := '0';
signal fifo_empty_r,isflag_r : std_logic := '1';
signal bitOUTclk,rst_fall,restart,bit_stuffing_case,re,ce_1st_clk,fifo_empty,bit_out,bit_out_r,isflag : std_logic;
signal byte_out : std_logic_vector (8 downto 0);
signal dataByte : std_logic_vector (8 downto 0) := (others=>'1');
signal byte_out_r : std_logic_vector (7 downto 0) := (others=>'1');
signal bit_out_sr : std_logic_vector (4 downto 0) := (others=>'1');
signal bit_out_sr_clk0 : std_logic_vector (4 downto 0);

signal send_out_trig : std_logic := '0';

begin

bitOUTclk <= bitCLKx2; -- 2bit output

-------------------------------------------------------------------------------------------
-- restarting data requests after reset fall
-------------------------------------------------------------------------------------------
rst_fall_pulse: entity work.pulse_fall_pw01 port map(bitOUTclk,rst,rst_fall);
restart_pulse:  entity work.pulse_pdxx_pwxx generic map(pd=>10,pw=>1) port map(bitOUTclk,rst_fall,restart); 
--
process(bitOUTclk)
begin
	if bitOUTclk'event and bitOUTclk = '1' then	   
        if rst = '1' then
            ce <= '0';
        elsif restart = '1' then
            ce <= '1';
        end if;
        ce_r <= ce;
	end if;
end process;
--
ce_1st_clk_pulse:  entity work.pulse_pdxx_pwxx generic map(pd=>0,pw=>1) port map(bitOUTclk,ce,ce_1st_clk); 
--

-------------------------------------------------------------------------------------------
-- input latching @ bitCLKx4
-------------------------------------------------------------------------------------------
process(bitCLKx4)
begin
	if bitCLKx4'event and bitCLKx4 = '1' then	   
        if edataINrdy = '1' then
            if edataIN(9 downto 8) = "11" then -- comma ('error')
                dataByte    <= (others=>'1');
                we          <= '0';
            elsif edataIN(9 downto 8) = "01" or edataIN(9 downto 8) = "10" then -- eop/sop
                dataByte    <= '1' & HDLC_flag;
                we          <= '1';
            else
                dataByte    <= '0' & edataIN(7 downto 0);
                we          <= '1';
            end if;
        else
            we <= '0';
        end if;
	end if;
end process;
--


-------------------------------------------------------------------------------------------
-- HDLC bit stuffing FIFO
-------------------------------------------------------------------------------------------
bit_stuffing_FIFO: hdlc_bist_fifo
port map (
    rst     => rst,
    wr_clk  => bitCLKx4,
    rd_clk  => bitOUTclk,
    din     => dataByte,
    wr_en   => we,
    rd_en   => re,
    dout    => byte_out,
    full    => open,
    empty   => fifo_empty
    );

-------------------------------------------------------------------------------------------
-- bit counter: counting 8 bit to serialize the out while pausing for zero-bit stuffing
-------------------------------------------------------------------------------------------
bit_stuffing_case   <= '1' when (bit_out_sr_clk0 = "11111" and isflag_r = '0') else '0';
bit_cnt_ena         <= ce and (not bit_stuffing_case);
re                  <= '1' when (bit_cnt = "111" and bit_cnt_ena = '1') else '0';
getDataTrig_pulse:  entity work.pulse_pdxx_pwxx generic map(pd=>0,pw=>1) port map(bitCLKx4,re,getDataTrig); 
--
process(bitOUTclk)
begin
	if bitOUTclk'event and bitOUTclk = '1' then	   
        if ce = '1' then
            if bit_cnt_ena = '1' then
                bit_cnt <= bit_cnt + 1;
            end if;
        else
            bit_cnt  <= (others=>'1');
        end if;
	end if;
end process;
--


-------------------------------------------------------------------------------------------
-- comma selector
-------------------------------------------------------------------------------------------
process(bitOUTclk)
begin
	if bitOUTclk'event and bitOUTclk = '1' then	   
        re_r            <= re;
        fifo_empty_r    <= fifo_empty;
	end if;
end process;
--
isflag <= byte_out(8); --'1' when (byte_out = HDLC_flag) else '0';
--
process(bitOUTclk)
begin
	if bitOUTclk'event and bitOUTclk = '1' then	
        if re_r = '1' then
            if fifo_empty_r = '1' then	   
--IG                byte_out_r  <= (others=>'1'); --error flag, not HDLC_flag!
                byte_out_r  <= "01111111"; --error flag, not HDLC_flag! --IG: error flag is only 7 bits ones and 1 bit zero - "01111111"
                isflag_r    <= '1';
            else
                byte_out_r  <= byte_out(7 downto 0);
                isflag_r    <= isflag; -- no bit stuffing if flag is sent
            end if;
        end if;
	end if;
end process;
--



-------------------------------------------------------------------------------------------
-- bit selector
-------------------------------------------------------------------------------------------
--
process(bitOUTclk)
begin
	if bitOUTclk'event and bitOUTclk = '1' then	   
        bit_cnt_r <= bit_cnt;
	end if;
end process;
--
process(bit_cnt_r,byte_out_r)
begin	  
   case (bit_cnt_r) is 
      when "000" => bit_out <= byte_out_r(0);
      when "001" => bit_out <= byte_out_r(1);
      when "010" => bit_out <= byte_out_r(2);
      when "011" => bit_out <= byte_out_r(3);
      when "100" => bit_out <= byte_out_r(4);
      when "101" => bit_out <= byte_out_r(5);
      when "110" => bit_out <= byte_out_r(6);
      when "111" => bit_out <= byte_out_r(7);
      when others =>
   end case;		
end process;
--
process(bitOUTclk)
begin
	if bitOUTclk'event and bitOUTclk = '1' then	   
        oe  <= bit_cnt_ena;
	end if;
end process;
--
bit_out_r <= (bit_out and oe) or (not ce_r); 
bit_out_sr_clk0 <= bit_out_r & bit_out_sr(4 downto 1);
--
process(bitOUTclk)
begin
    if bitOUTclk'event and bitOUTclk = '1' then	   
        if rst = '1' then
            bit_out_sr <= (others=>'1');
        else
            bit_out_sr <= bit_out_r & bit_out_sr(4 downto 1);
        end if;
    end if;
end process;
--


-------------------------------------------------------------------------------------------
-- sending out 2 bits @ bitCLK
-------------------------------------------------------------------------------------------
process(bitOUTclk)
begin
	if bitOUTclk'event and bitOUTclk = '1' then	   
        send_out_trig <= (not send_out_trig) and ce;
	end if;
end process;
--
process(bitOUTclk)
begin
	if bitOUTclk'event and bitOUTclk = '1' then	   
        if send_out_trig = '1' then
            two_bit_out(1) <= bit_out_r;
        else
            two_bit_out(0) <= bit_out_r;
        end if;
	end if;
end process;
--
process(bitOUTclk,rst)
begin
    if rst = '1' then
        EdataOUT_s <= (others=>'1');
	elsif bitOUTclk'event and bitOUTclk = '1' then	   
        if send_out_trig = '0' and ce = '1' then
            --EdataOUT_s <= two_bit_out;
            EdataOUT_s <= two_bit_out(0) & two_bit_out(1);  -- HDLC bits are swapped by default
        end if;
	end if;
end process;
--
EdataOUT <= EdataOUT_s;
--

end Behavioral;

