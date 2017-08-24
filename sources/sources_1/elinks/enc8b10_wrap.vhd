----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    06/19/2014 
--! Module Name:    enc_8b10_wrap
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library IEEE, work;
use IEEE.STD_LOGIC_1164.ALL;
use work.centralRouter_package.all;
use work.all;

--! a wrap for 8b10b encoder
entity enc8b10_wrap is
port ( 	
	clk            : in  std_logic;
	rst            : in  std_logic;
	dataCode       : in  std_logic_vector (1 downto 0); -- 00"data, 01"eop, 10"sop, 11"comma
	dataIN         : in  std_logic_vector (7 downto 0);
	dataINrdy      : in  std_logic;
	encDataOut     : out  std_logic_vector (9 downto 0);
	encDataOutrdy  : out  std_logic
	);
end enc8b10_wrap;

architecture Behavioral of enc8b10_wrap is

----------------------------------
----------------------------------
component MUX4_Nbit 
generic (N : integer := 1);
port ( 
	data0    : in  std_logic_vector((N-1) downto 0);
	data1    : in  std_logic_vector((N-1) downto 0);
	data2    : in  std_logic_vector((N-1) downto 0);
	data3    : in  std_logic_vector((N-1) downto 0);
	sel      : in  std_logic_vector(1 downto 0);
	data_out : out std_logic_vector((N-1) downto 0)
	);
end component MUX4_Nbit;
----------------------------------
----------------------------------
component enc_8b10b 	 
port( 
    RESET : in std_logic ;		-- Global asynchronous reset (active high)  
clk : in std_logic ;
ena : in std_logic ;
--enaRise : in std_logic ;
--enaFall : in std_logic ;
    --SBYTECLK : in std_logic ;	-- Master synchronous send byte clock 
    KI : in std_logic ;			-- Control (K) input(active high) 
    AI, BI, CI, DI, EI, FI, GI, HI : in std_logic ;	-- Unencoded input data 
    JO, HO, GO, FO, IO, EO, DO, CO, BO, AO : out std_logic 	-- Encoded out  
    ); 
end component enc_8b10b; 
----------------------------------
----------------------------------

signal isk : std_logic := '1';
signal encoder_rst, enc_ena_s : std_logic;
signal enc_ena, encoder_rst_delayed, encoder_rst_clk1 : std_logic := '1';
signal dataINrdy_s : std_logic;

signal rst_state : std_logic := '1';
signal dataIN_s, byte : std_logic_vector(7 downto 0);
signal dataCode_s : std_logic_vector(1 downto 0) := (others => '1');


begin

dataINrdy_s <= dataINrdy and (not encoder_rst);

-------------------------------------------------------------------------------------------
-- input registers
-------------------------------------------------------------------------------------------
process(clk)
begin
	if clk'event and clk = '1' then	   
		rst_state <= rst;
	end if;
end process;
--
process(clk)
begin
	if clk'event and clk = '1' then	   
		if dataINrdy_s = '1' then
		  dataIN_s    <= dataIN;
		  dataCode_s  <= dataCode;
		  isk         <= dataCode(1) or dataCode(0);
		  --rst_state   <= '0';
--		else 
--		  dataIN_s    <= Kchar_comma;
--          dataCode_s  <= "11";
		end if;
	end if;
end process;
--
encoder_rst <= rst_state or rst;
--

-------------------------------------------------------------------------------------------
-- data code cases
-- 00"data, 01"eop, 10"sop, 11"comma
-------------------------------------------------------------------------------------------
inmux: MUX4_Nbit 
generic map (N=>8)
port map ( 
	data0    => dataIN_s,
	data1    => Kchar_eop,
	data2    => Kchar_sop,
	data3    => Kchar_comma,
	sel      => dataCode_s,
	data_out => byte
	);
--

-------------------------------------------------------------------------------------------
-- 8b10b encoder
-------------------------------------------------------------------------------------------
process(clk)
begin
	if clk'event and clk = '0' then	   
	   enc_ena <= dataINrdy_s or encoder_rst;
	   encoder_rst_clk1 <= encoder_rst;
	   encoder_rst_delayed <= encoder_rst_clk1;
	end if;
end process;
--
enc_ena_s <= enc_ena or encoder_rst_delayed;
--
enc_8b10bx: enc_8b10b 	 
port map( 
    RESET       => encoder_rst,		-- Global asynchronous reset (active high)   
    clk => clk,
    ena => enc_ena_s,     
    --SBYTECLK    => encClk_s, --clk, 	-- Master synchronous send byte clock 
    KI          => isk,		-- Control (K) input(active high) 
    AI=>byte(0), BI=>byte(1), CI=>byte(2), DI=>byte(3), EI=>byte(4), FI=>byte(5), GI=>byte(6), HI=>byte(7),	-- Unencoded input data 
    JO=>encDataOut(9),HO=>encDataOut(8),GO=>encDataOut(7),FO=>encDataOut(6),IO=>encDataOut(5),EO=>encDataOut(4),DO=>encDataOut(3),CO=>encDataOut(2),BO=>encDataOut(1),AO=>encDataOut(0) 	-- Encoded out  
    ); 
--
--
process(clk)
begin
	if clk'event and clk = '1' then	   
	   encDataOutrdy <= dataINrdy_s and (not encoder_rst);
	end if;
end process;
--

end Behavioral;

