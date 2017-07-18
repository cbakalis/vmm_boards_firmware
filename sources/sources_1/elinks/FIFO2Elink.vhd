----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    17/08/2015 
--! Module Name:    FIFO2Elink
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee, work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.all;

--! consists of 1 E-path
entity FIFO2Elink is
generic (
    OutputDataRate  : integer := 80; -- 80 / 160 / 320 MHz
    elinkEncoding   : std_logic_vector (1 downto 0) -- 00-direct data / 01-8b10b encoding / 10-HDLC encoding 
    );
port ( 
    clk40       : in  std_logic;
    clk80       : in  std_logic;
    clk160      : in  std_logic;
    clk320      : in  std_logic;
    rst         : in  std_logic;
    fifo_flush  : in  std_logic;
    swap_output : in  std_logic;
    ------   
    efifoDin    : in  std_logic_vector (17 downto 0);   -- [data_code,2bit][data,16bit]
    efifoWe     : in  std_logic;
    efifoPfull  : out std_logic;
    efifoEmpty  : out std_logic; 
    efifoWclk   : in  std_logic; 
    ------
    DATA1bitOUT : out std_logic; -- serialized output
    elink2bit   : out std_logic_vector (1 downto 0); -- 2 bits @ clk40, can interface 2-bit of GBT frame
    elink4bit   : out std_logic_vector (3 downto 0); -- 4 bits @ clk40, can interface 4-bit of GBT frame
    elink8bit   : out std_logic_vector (7 downto 0)  -- 8 bits @ clk40, can interface 8-bit of GBT frame
    ------
    );
end FIFO2Elink;

architecture Behavioral of FIFO2Elink is

----
signal efifoRE, doutRdy : std_logic;
signal efifoDout : std_logic_vector(9 downto 0); 
signal dout2bit  : std_logic_vector(1 downto 0); 
signal bitCount1,dout2bit_r : std_logic := '0';
signal dout4bit, dout4bit_r : std_logic_vector(3 downto 0); 
signal dout8bit, dout8bit_r : std_logic_vector(7 downto 0); 
signal bitCount2 : std_logic_vector(1 downto 0) := "00";
signal bitCount3 : std_logic_vector(2 downto 0) := "000";
----

begin


------------------------------------------------------------
-- EPATH_FIFO
------------------------------------------------------------
UEF: entity work.upstreamEpathFifoWrap
port map(
    rst 	        => rst,
    fifoFLUSH       => fifo_flush,
    ---
    wr_clk 	=> efifoWclk,
    wr_en 	=> efifoWe,
    din     => efifoDin,
    ---
    rd_clk 	=> clk160,
    rd_en 	=> efifoRE, 
    dout 	=> efifoDout,
    doutRdy => doutRdy,
    ---
    full        => open,
    empty       => efifoEmpty,
    prog_full   => efifoPfull
    );
--

					

------------------------------------------------------------
-- E-PATH case 80 MHz
------------------------------------------------------------
OutputDataRate80: if OutputDataRate = 80 generate

EPROC_OUT2bit: entity work.EPROC_OUT2 
generic map (
    		do_generate             => true,
    		includeNoEncodingCase   => true
    		)
port map(
			bitCLK     => clk40,
			bitCLKx2   => clk80,
			bitCLKx4   => clk160,
			rst        => rst,
			ENA        => '1', -- always enabled here
			swap_outbits => swap_output, -- when '1', the output bits will be swapped
			getDataTrig => efifoRE,
			ENCODING   => ("00" & elinkEncoding), -- 0000-direct data / 0001-8b10b encoding / 0010-HDLC encoding / others are used for TTC formats
			EDATA_OUT  => dout2bit, -- @ 40MHz
			TTCin      => "00", -- not in use here
			DATA_IN    => efifoDout,  -- 10-bit data in
			DATA_RDY   => doutRdy
		);
--
-------------------------------------------
-- serialization of the 2-bit data output:
-------------------------------------------
process(clk80)
begin
    if rising_edge(clk80) then
        bitCount1 <= not bitCount1;
	end if;
end process;
--
process(clk80)
begin
    if rising_edge(clk80) then
        if bitCount1 = '0' then
            dout2bit_r <= dout2bit(1);
        end if;
	end if;
end process;
---
process(clk80) -- serialized output
begin
    if rising_edge(clk80) then
        if bitCount1 = '0' then
            DATA1bitOUT <= dout2bit(0);
        else
            DATA1bitOUT <= dout2bit_r;
        end if;
	end if;
end process;
---
elink2bit <= dout2bit; -- 2 bits @ clk40, can interface 2-bit of GBT frame
elink4bit <= (others=>'0'); -- 4 bits @ clk40, can interface 4-bit of GBT frame
elink8bit <= (others=>'0'); -- 8 bits @ clk40, can interface 8-bit of GBT frame
--
end generate OutputDataRate80; 





------------------------------------------------------------
-- E-PATH case 160 MHz
------------------------------------------------------------
OutputDataRate160: if OutputDataRate = 160 generate

EPROC_OUT4bit: entity work.EPROC_OUT4 
generic map (
    		do_generate             => true,
    		includeNoEncodingCase   => true
    		)
port map(
			bitCLK     => clk40,
			bitCLKx2   => clk80,
			bitCLKx4   => clk160,
			rst        => rst,
			ENA        => '1', -- always enabled here
			swap_outbits => swap_output, -- when '1', the output bits will be swapped
			getDataTrig => efifoRE,
			ENCODING   => ("00" & elinkEncoding), -- 0000-direct data / 0001-8b10b encoding / 0010-HDLC encoding / others are used for TTC formats
			EDATA_OUT  => dout4bit, -- @ 40MHz
			TTCin      => "00000", -- not in use here
			DATA_IN    => efifoDout, -- 10-bit data in
			DATA_RDY   => doutRdy
		);
--
-------------------------------------------
-- serialization of the 4-bit data output:
-------------------------------------------
process(clk160)
begin
    if rising_edge(clk160) then
        bitCount2 <= bitCount2 + 1;
	end if;
end process;
--
process(clk160)
begin
    if rising_edge(clk160) then
        if bitCount2 = "00" then
            dout4bit_r <= dout4bit;
        end if;
	end if;
end process;
---
process(clk160) -- serialized output
begin
    if rising_edge(clk160) then      
       case bitCount2 is 
          when "00" => DATA1bitOUT <= dout4bit(0);
          when "01" => DATA1bitOUT <= dout4bit_r(1);
          when "10" => DATA1bitOUT <= dout4bit_r(2);
          when "11" => DATA1bitOUT <= dout4bit_r(3);
          when others =>
       end case;
	end if;
end process;
---
elink2bit <= (others=>'0'); -- 2 bits @ clk40, can interface 2-bit of GBT frame
elink4bit <= dout4bit; -- 4 bits @ clk40, can interface 4-bit of GBT frame
elink8bit <= (others=>'0'); -- 8 bits @ clk40, can interface 8-bit of GBT frame
--
end generate OutputDataRate160; 






------------------------------------------------------------
-- E-PATH case 320 MHz
------------------------------------------------------------
OutputDataRate320: if OutputDataRate = 320 generate

EPROC_OUT8bit: entity work.EPROC_OUT8 
generic map (
    		do_generate             => true,
    		includeNoEncodingCase   => true
    		)
port map(
			bitCLK     => clk40,
			bitCLKx2   => clk80,
			bitCLKx4   => clk160,
			rst        => rst,
			ENA        => '1', -- always enabled here
			getDataTrig => efifoRE,
            swap_outbits => swap_output,
			ENCODING   => ("00" & elinkEncoding), -- 0000-direct data / 0001-8b10b encoding / 0010-HDLC encoding / others are used for TTC formats
			EDATA_OUT  => dout8bit, -- @ 40MHz
			TTCin      => "000000000", -- not in use here
			DATA_IN    => efifoDout, -- 10-bit data in
			DATA_RDY   => doutRdy
		);
--
-------------------------------------------
-- serialization of the 8-bit data output:
-------------------------------------------
process(clk320)
begin
    if rising_edge(clk320) then 
        bitCount3 <= bitCount3 + 1;
	end if;
end process;
--
process(clk320)
begin
    if rising_edge(clk320) then
        if bitCount3 = "000" then
            dout8bit_r <= dout8bit;
        end if;
	end if;
end process;
---
process(clk320) -- serialized output
begin
    if rising_edge(clk320) then     
       case bitCount3 is 
          when "000" => DATA1bitOUT <= dout8bit(0);
          when "001" => DATA1bitOUT <= dout8bit_r(1);
          when "010" => DATA1bitOUT <= dout8bit_r(2);
          when "011" => DATA1bitOUT <= dout8bit_r(3);
          when "100" => DATA1bitOUT <= dout8bit_r(4);
          when "101" => DATA1bitOUT <= dout8bit_r(5);
          when "110" => DATA1bitOUT <= dout8bit_r(6);
          when "111" => DATA1bitOUT <= dout8bit_r(7);
          when others =>
       end case;
	end if;
end process;
---
elink2bit <= (others=>'0'); -- 2 bits @ clk40, can interface 2-bit of GBT frame
elink4bit <= (others=>'0'); -- 4 bits @ clk40, can interface 4-bit of GBT frame
elink8bit <= dout8bit; -- 8 bits @ clk40, can interface 8-bit of GBT frame
--
end generate OutputDataRate320; 







------------------------------------------------------------
-- unsupported Data Rate
------------------------------------------------------------
unsupported_Data_Rate: if OutputDataRate /= 80 and OutputDataRate /= 160 and OutputDataRate /= 320 generate
---
DATA1bitOUT <= '0'; -- serialized output
elink2bit <= (others=>'0'); -- 2 bits @ clk40, can interface 2-bit of GBT frame
elink4bit <= (others=>'0'); -- 4 bits @ clk40, can interface 4-bit of GBT frame
elink8bit <= (others=>'0'); -- 8 bits @ clk40, can interface 8-bit of GBT frame
--
end generate unsupported_Data_Rate; 



end Behavioral;

