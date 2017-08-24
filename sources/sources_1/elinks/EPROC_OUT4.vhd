----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    18/03/2015
--! Module Name:    EPROC_OUT4
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library ieee,work;
use ieee.std_logic_1164.all;
use work.all;

--! E-link processor, 4bit output
entity EPROC_OUT4 is
generic (
    do_generate             : boolean := true;
    includeNoEncodingCase   : boolean := true
    );
port ( 
    bitCLK      : in  std_logic;
    bitCLKx2    : in  std_logic;
    bitCLKx4    : in  std_logic;
    rst         : in  std_logic;
    ENA         : in  std_logic;
	swap_outbits: in std_logic;
    getDataTrig : out std_logic; -- @ bitCLKx4
    ENCODING    : in  std_logic_vector (3 downto 0);
    EDATA_OUT   : out std_logic_vector (3 downto 0);
    TTCin       : in  std_logic_vector (4 downto 0);
    DATA_IN     : in  std_logic_vector (9 downto 0);
    DATA_RDY    : in  std_logic
    );
end EPROC_OUT4;

architecture Behavioral of EPROC_OUT4 is

constant zeros4bit  : std_logic_vector (3 downto 0) := (others=>'0');
signal EdataOUT_ENC8b10b_case, EdataOUT_direct_case, EdataOUT_HDLC_case, EdataOUT_TTC1_case, EdataOUT_TTC2_case : std_logic_vector (3 downto 0);
signal rst_s, rst_case000, rst_case001, rst_case010, rst_case011 : std_logic;
signal getDataTrig_ENC8b10b_case, getDataTrig_direct_case, getDataTrig_HDLC_case, getDataTrig_TTC_cases : std_logic;
signal edata_out_s : std_logic_vector (3 downto 0);

begin

gen_enabled: if do_generate = true generate

rst_s <= rst or (not ENA);

-------------------------------------------------------------------------------------------
-- case 0: direct data, no delimeter...
-------------------------------------------------------------------------------------------
direct_data_enabled: if includeNoEncodingCase = true generate
rst_case000 <= '0' when ((rst_s = '0') and (ENCODING(2 downto 0) = "000")) else '1';
direct_case: entity work.EPROC_OUT4_direct 
port map(
    bitCLK      => bitCLK,
    bitCLKx2    => bitCLKx2,
    bitCLKx4    => bitCLKx4,
    rst         => rst_case000, 
    getDataTrig => getDataTrig_direct_case,    
    edataIN     => DATA_IN,
    edataINrdy  => DATA_RDY,
    EdataOUT    => EdataOUT_direct_case
    );
end generate direct_data_enabled;
--
direct_data_disabled: if includeNoEncodingCase = false generate
EdataOUT_direct_case <= (others=>'0');
end generate direct_data_disabled;
--

-------------------------------------------------------------------------------------------
-- case 1: DEC8b10b
-------------------------------------------------------------------------------------------
rst_case001 <= '0' when ((rst_s = '0') and (ENCODING(2 downto 0) = "001")) else '1';
--
ENC8b10b_case: entity work.EPROC_OUT4_ENC8b10b
port map(
    bitCLK      => bitCLK,
    bitCLKx2    => bitCLKx2,
    bitCLKx4    => bitCLKx4,
    rst         => rst_case001, 
    getDataTrig => getDataTrig_ENC8b10b_case,  
    edataIN     => DATA_IN,
    edataINrdy  => DATA_RDY,
    EdataOUT    => EdataOUT_ENC8b10b_case
    );
--

-------------------------------------------------------------------------------------------
-- case 2: HDLC
-------------------------------------------------------------------------------------------
rst_case010 <= '0' when ((rst_s = '0') and (ENCODING(2 downto 0) = "010")) else '1';
--
getDataTrig_HDLC_case   <= '0'; --'1' when (ENCODING(2 downto 0) = "010") else '0';
EdataOUT_HDLC_case      <= (others=>'0'); --<---TBD
--

-------------------------------------------------------------------------------------------
-- case 3&4: TTC-1 & TTC-2  
-------------------------------------------------------------------------------------------
rst_case011 <= '0' when ((rst_s = '0') and ((ENCODING(2 downto 0) = "011") or (ENCODING(2 downto 0) = "100"))) else '1';
--
getDataTrig_TTC_cases <= '0'; --'1' when ((ENCODING(2 downto 0) = "011") or (ENCODING(2 downto 0) = "100")) else '0';
--
ttc_r: process(bitCLK)
begin
    if bitCLK'event and bitCLK = '1' then
        if rst_case011 = '1' then
            EdataOUT_TTC1_case <= zeros4bit;
            EdataOUT_TTC2_case <= zeros4bit;
        else
            EdataOUT_TTC1_case <= TTCin(1) & TTCin(3 downto 2) & TTCin(0);
            EdataOUT_TTC2_case <= TTCin(4 downto 2) & TTCin(0);
        end if;	   
	end if;
end process;
--

-------------------------------------------------------------------------------------------
-- output data and busy according to the encoding settings
-------------------------------------------------------------------------------------------
dataOUTmux: entity work.MUX8_Nbit 
generic map (N=>4)
port map( 
	data0    => EdataOUT_direct_case,
	data1    => EdataOUT_ENC8b10b_case,
	data2    => EdataOUT_HDLC_case,
	data3    => EdataOUT_TTC1_case,
	data4    => EdataOUT_TTC2_case,
	data5    => zeros4bit,
	data6    => zeros4bit,
	data7    => zeros4bit,
	sel      => ENCODING(2 downto 0),
	data_out => edata_out_s
	);
--
getDataTrig  <= ENA and (getDataTrig_TTC_cases or getDataTrig_HDLC_case or getDataTrig_ENC8b10b_case or getDataTrig_direct_case);
--

out_sel: process(swap_outbits,edata_out_s)
begin   
    if swap_outbits = '1' then
        EDATA_OUT <= edata_out_s(0) & edata_out_s(1) & edata_out_s(2) & edata_out_s(3);
    else
        EDATA_OUT <= edata_out_s;
    end if;	   
end process;

end generate gen_enabled;
--
--
gen_disabled: if do_generate = false generate
    EDATA_OUT   <= (others=>'0');
    getDataTrig <= '0';
end generate gen_disabled;

end Behavioral;

