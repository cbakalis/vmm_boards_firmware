----------------------------------------------------------------------------------
-- Company: NTU Athens - BNL
-- Engineer: Christos Bakalis (christos.bakalis@cern.ch)
-- 
-- Create Date: 19.02.2017 12:07:30
-- Design Name: 
-- Module Name: clk_gen_wrapper - RTL
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: Wrapper that contains the CKTP and CKBC generators. It also 
-- instantiates a skewing module with 2 ns resolution. See skew_gen for more
-- information.
-- 
-- Dependencies: "Configurable CKBC/CKTP Constraints" .xdc snippet must be added to 
-- the main .xdc file of the design. Can be found at the project repository.
-- 
-- Changelog: 
-- 23.02.2017 Slowed down the skewing process to 500 Mhz. (Christos Bakalis)
--
----------------------------------------------------------------------------------
library IEEE;
library UNISIM;
use IEEE.STD_LOGIC_1164.ALL;
use UNISIM.VComponents.all;


entity clk_gen_wrapper is
    Port(
        ------------------------------------
        ------- General Interface ----------
        clk_500             : in  std_logic;
        clk_160             : in  std_logic;
        rst                 : in  std_logic;
        mmcm_locked         : in  std_logic;
        ------------------------------------
        ----- Configuration Interface ------
        ckbc_ready          : in  std_logic;
        cktp_enable         : in  std_logic;
        cktp_primary        : in  std_logic;
        cktp_pulse_width    : in  std_logic_vector(31 downto 0);
        cktp_period         : in  std_logic_vector(31 downto 0);
        cktp_skew           : in  std_logic_vector(15 downto 0);        
        ckbc_freq           : in  std_logic_vector(7 downto 0);
        ------------------------------------
        ---------- VMM Interface -----------
        CKTP                : out std_logic;
        CKBC                : out std_logic
    );
end clk_gen_wrapper;

architecture RTL of clk_gen_wrapper is

    component cktp_gen
    port(
        clk_160         : in  std_logic;
        cktp_start      : in  std_logic;
        vmm_ckbc        : in  std_logic; -- CKBC clock currently dynamic
        cktp_primary    : in  std_logic;
        ckbc_freq       : in  std_logic_vector(7 downto 0);
        skew            : in  std_logic_vector(15 downto 0);
        pulse_width     : in  std_logic_vector(31 downto 0);
        period          : in  std_logic_vector(31 downto 0);
        CKTP            : out std_logic
    );
    end component;

    component ckbc_gen
    port(  
        clk_160       : in std_logic;
        duty_cycle    : in std_logic_vector(7 downto 0);
        freq          : in std_logic_vector(7 downto 0);
        ready         : in std_logic;
        ckbc_out      : out std_logic
    );
    end component;
    
    component skew_gen
    port(
        clk_500         : in std_logic;
        CKTP_preSkew    : in std_logic;
        skew            : in std_logic_vector(4 downto 0);
        CKTP_skew       : out std_logic
    );    
    end component;

    signal ckbc_start       : std_logic := '0';
    signal cktp_start       : std_logic := '0';

    signal CKBC_preBuf      : std_logic := '0';
    signal CKBC_glbl        : std_logic := '0';
    
    signal CKTP_from_gen    : std_logic := '0';
    signal CKTP_from_skew   : std_logic := '0';
    signal CKTP_glbl        : std_logic := '0';
    
    signal sel_skew_gen     : std_logic := '0';
    signal skew_cktp_gen    : std_logic_vector(15 downto 0) := (others => '0');
    
begin

ckbc_generator: ckbc_gen
    port map(  
        clk_160       => clk_160,
        duty_cycle    => (others => '0'), -- unused
        freq          => ckbc_freq,
        ready         => ckbc_start,
        ckbc_out      => CKBC_preBuf
    );
      
CKBC_BUFGCE: BUFGCE
    port map(O => CKBC_glbl,  CE => ckbc_start, I => CKBC_preBuf);

cktp_generator: cktp_gen
    port map(
        clk_160         => clk_160,
        cktp_start      => cktp_start,
        cktp_primary    => cktp_primary,
        vmm_ckbc        => CKBC_preBuf, -- CKBC_glbl
        ckbc_freq       => ckbc_freq,
        skew            => skew_cktp_gen,
        pulse_width     => cktp_pulse_width,
        period          => cktp_period,
        CKTP            => CKTP_from_gen
    );

    
skewing_module: skew_gen
    port map(
        clk_500         => clk_500,
        CKTP_preSkew    => CKTP_from_gen,
        skew            => cktp_skew(4 downto 0),
        CKTP_skew       => CKTP_from_skew
    );

CKTP_BUFGMUX: BUFGMUX
    port map(O => CKTP_glbl, I0 => CKTP_from_gen, I1 => CKTP_from_skew, S => sel_skew_gen);
    
skew_sel_proc: process(ckbc_freq, cktp_skew)
begin
    case ckbc_freq is
    when "00101000" => -- 40
        skew_cktp_gen   <= (others => '0'); -- skewing controlled by skew_gen
        if(cktp_skew = x"0000")then
            sel_skew_gen <= '0'; -- no skew
        else
            sel_skew_gen <= '1'; -- select high granularity skewing module (2 ns step size)
        end if;
             
    when others =>
        sel_skew_gen    <= '0'; -- select low granularity skewing from cktp_gen (6.125 ns step size)
        skew_cktp_gen   <= cktp_skew;
    end case;
end process;

    cktp_start      <= not rst and ckbc_ready and cktp_enable and mmcm_locked;
    ckbc_start      <= not rst and ckbc_ready and mmcm_locked;

    CKBC            <= CKBC_glbl;
    CKTP            <= CKTP_glbl;
    
end RTL;
