----------------------------------------------------------------------------------
--! Company:  EDAQ WIS.  
--! Engineer: juna
--! 
--! Create Date:    06/19/2014 
--! Module Name:    dec_8b10_wrap
--! Project Name:   FELIX
----------------------------------------------------------------------------------
--! Use standard library
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.centralRouter_package.all;

--! a wrap for 8b10b decoder
entity dec_8b10_wrap is
port ( 
	RESET          : in  std_logic;
	RBYTECLK       : in  std_logic;
	ABCDEIFGHJ_IN  : in  std_logic_vector (9 downto 0);
	HGFEDCBA       : out std_logic_vector (7 downto 0);
	ISK            : out std_logic_vector (1 downto 0);
	BUSY           : out std_logic 
	);
end dec_8b10_wrap;

architecture Behavioral of dec_8b10_wrap is

----------------------------------
----------------------------------
COMPONENT dec_8b10b
PORT(
	RESET : IN std_logic;
	RBYTECLK : IN std_logic;
	AI : IN std_logic;
	BI : IN std_logic;
	CI : IN std_logic;
	DI : IN std_logic;
	EI : IN std_logic;
	II : IN std_logic;
	FI : IN std_logic;
	GI : IN std_logic;
	HI : IN std_logic;
	JI : IN std_logic;          
	KO : OUT std_logic;
	HO : OUT std_logic;
	GO : OUT std_logic;
	FO : OUT std_logic;
	EO : OUT std_logic;
	DO : OUT std_logic;
	CO : OUT std_logic;
	BO : OUT std_logic;
	AO : OUT std_logic
	);
END COMPONENT;
----------------------------------
----------------------------------

signal ISK_falling_edge : std_logic;
signal BUSY_s : std_logic := '0';
signal HGFEDCBA_falling_edge : std_logic_vector(7 downto 0);
signal HGFEDCBA_sig : std_logic_vector(7 downto 0) := (others => '0');
signal ISKcode : std_logic_vector(1 downto 0);
signal ISK_sig : std_logic_vector(1 downto 0) := (others => '0');
signal ISK_comma, ISK_soc, ISK_eoc, ISK_sob, ISK_eob : std_logic;

begin

-- 8b10b decoder
dec_8b10b_INST: dec_8b10b 
PORT MAP(
	RESET    => RESET,
	RBYTECLK => RBYTECLK,
	AI => ABCDEIFGHJ_IN(9),
	BI => ABCDEIFGHJ_IN(8),
	CI => ABCDEIFGHJ_IN(7),
	DI => ABCDEIFGHJ_IN(6),
	EI => ABCDEIFGHJ_IN(5),
	II => ABCDEIFGHJ_IN(4),
	FI => ABCDEIFGHJ_IN(3),
	GI => ABCDEIFGHJ_IN(2),
	HI => ABCDEIFGHJ_IN(1), 
	JI => ABCDEIFGHJ_IN(0),
	KO => ISK_falling_edge,
	HO => HGFEDCBA_falling_edge(7),
	GO => HGFEDCBA_falling_edge(6),
	FO => HGFEDCBA_falling_edge(5),
	EO => HGFEDCBA_falling_edge(4),
	DO => HGFEDCBA_falling_edge(3),
	CO => HGFEDCBA_falling_edge(2),
	BO => HGFEDCBA_falling_edge(1),
	AO => HGFEDCBA_falling_edge(0)
);

------------------------------------------------------------------------------------------------------
ISK_comma   <=  '1' when (ABCDEIFGHJ_IN = COMMAp or ABCDEIFGHJ_IN = COMMAn) else '0';
ISK_soc     <=  '1' when (ABCDEIFGHJ_IN = SOCp or ABCDEIFGHJ_IN = SOCn) else '0';
ISK_eoc     <=  '1' when (ABCDEIFGHJ_IN = EOCp or ABCDEIFGHJ_IN = EOCn) else '0';
ISK_sob     <=  '1' when (ABCDEIFGHJ_IN = SOBp or ABCDEIFGHJ_IN = SOBn) else '0';
ISK_eob     <=  '1' when (ABCDEIFGHJ_IN = EOBp or ABCDEIFGHJ_IN = EOBn) else '0';
---
ISKcode(0) <= ((not ISK_soc) and (ISK_eoc xor ISK_comma)) or ISK_sob or ISK_eob;
ISKcode(1) <= ((not ISK_eoc) and (ISK_soc xor ISK_comma)) or ISK_sob or ISK_eob;
------------------------------------------------------------------------------------------------------
process(RBYTECLK)
begin
	if RBYTECLK'event and RBYTECLK = '1' then	   
		if ISK_falling_edge = '1' then
		  ISK_sig <= ISKcode; 
		else 
		  ISK_sig <= "00";
		end if;
	end if;
end process;
--
process(RBYTECLK)
begin
	if RBYTECLK'event and RBYTECLK = '1' then	    
		HGFEDCBA_sig <= HGFEDCBA_falling_edge;
	end if;
end process;
------------------------------------------------------------------------------------------------------

ISK      <= ISK_sig;
HGFEDCBA <= HGFEDCBA_sig;

------------------------------------------------------------------------------------------------------
process(RBYTECLK)
begin
    if RBYTECLK'event and RBYTECLK = '1' then	          
        if RESET = '1' or ISK_eob = '1' then
            BUSY_s <= '0'; 
        elsif ISK_sob = '1' then
            BUSY_s <= '1';     
        end if;
    end if;
end process;
--
BUSY <= BUSY_s;
--

end Behavioral;

