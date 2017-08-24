--!-----------------------------------------------------------------------------
--!                                                                           --
--!                    Weizmann Institute of Science                          --
--!                Electronics & Data Acquisition Group                       --
--!                                                                           --
--!-----------------------------------------------------------------------------
--!
--! unit name: centralRouter package
--!
--! author: 	juna@weizmann.ac.il
--!
--! date: $10/12/2014    $: created
--!
--! version: $Rev 0      $:
--!
--! description: package file for the centralRouter interface
--!   
--!-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


package centralRouter_package is

-------------------------------------------------------------------
-- general use type definitions
-------------------------------------------------------------------
type array7_std_logic_vector_15 is array (0 to 6) of std_logic_vector(14 downto 0); 
type array8_std_logic_vector_15 is array (0 to 7) of std_logic_vector(14 downto 0); 
type array8_std_logic_vector_16 is array (0 to 7) of std_logic_vector(15 downto 0);
type array7_std_logic_vector_8 is array (0 to 6) of std_logic_vector(7 downto 0);
type array8_std_logic_vector_8 is array (0 to 7) of std_logic_vector(7 downto 0);
type array15_std_logic_vector_7 is array (0 to 14) of std_logic_vector(6 downto 0);
type array15_std_logic_vector_8 is array (0 to 14) of std_logic_vector(7 downto 0);
type array15_std_logic_vector_6 is array (0 to 14) of std_logic_vector(5 downto 0);
type array15_std_logic_vector_3 is array (0 to 14) of std_logic_vector(2 downto 0);


-------------------------------------------------------------------
-- EPROC internal type definitions
-------------------------------------------------------------------
type isk_2array_type is array (0 to 1) of std_logic_vector(1 downto 0);         -- 2 words of 2bit
type word8b_2array_type is array (0 to 1) of std_logic_vector(7 downto 0);      -- 2 words of 8bit
type word10b_2array_type is array (0 to 1) of std_logic_vector(9 downto 0);     -- 2 words of 10bit
type word10b_2array_4array_type is array (0 to 3) of word10b_2array_type;       -- 4 groups of {2 words of 10bit}, one group per alignment
--
type isk_4array_type is array (0 to 3) of std_logic_vector(1 downto 0);         -- 4 words of 2bit
type word8b_4array_type is array (0 to 3) of std_logic_vector(7 downto 0);      -- 4 words of 8bit
type word10b_4array_type is array (0 to 3) of std_logic_vector(9 downto 0);     -- 4 words of 10bit
type word10b_4array_8array_type is array (0 to 7) of word10b_4array_type;       -- 8 groups of {4 words of 10bit}, one group per alignment
--
type isk_8array_type is array (0 to 7) of std_logic_vector(1 downto 0);         -- 8 words of 2bit
type word8b_8array_type is array (0 to 7) of std_logic_vector(7 downto 0);      -- 8 words of 8bit
type word10b_8array_type is array (0 to 7) of std_logic_vector(9 downto 0);     -- 8 words of 10bit
type word10b_8array_16array_type is array (0 to 15) of word10b_8array_type;     -- 16 groups of {8 words of 10bit}, one group per alignment


-------------------------------------------------------------------
-- 7 and 5 entry arrays of 16 input lines, 16bit line per EGROUP
-------------------------------------------------------------------
type from1GBTdata_array_type    is array (0 to 6) of std_logic_vector(15 downto 0);
type to1GBTdata_array_type      is array (0 to 4) of std_logic_vector(15 downto 0);
type to1GBTdataNcode_array_type      is array (0 to 4) of std_logic_vector(17 downto 0);

-------------------------------------------------------------------
-- N entry array of 16 output lines, 16bit output line per EGROUP
-------------------------------------------------------------------
type GBTdata_array_type is array ( NATURAL RANGE <>) of std_logic_vector(15 downto 0);

-------------------------------------------------------------------
-- GBT_NUM entry arrays
-------------------------------------------------------------------
type ic_data_array_type is array ( NATURAL RANGE <>) of std_logic_vector(7 downto 0); 

type cr_DIN_array_type is array ( NATURAL RANGE <>) of from1GBTdata_array_type;
type cr_DOUT_array_type is array ( NATURAL RANGE <>) of to1GBTdata_array_type;

type cr_8MSbs_array_type is array ( NATURAL RANGE <>) of std_logic_vector(7 downto 0);
type cr_4bit_array_type is array ( NATURAL RANGE <>) of std_logic_vector(3 downto 0);
type TTCin_array_type is array ( NATURAL RANGE <>) of std_logic_vector(9 downto 0);

type DownFifoFull_mon_array_type is array ( NATURAL RANGE <>) of std_logic_vector(58 downto 0);
type fmch_monitor_array_type is array ( NATURAL RANGE <>) of std_logic_vector(7 downto 0);

type busyOut_array_type is array ( NATURAL RANGE <>) of std_logic_vector(56 downto 0);

-------------------------------------------------------------------
-- Central Router configuration register arrays
-------------------------------------------------------------------
type crDownstreamConfig_type is array (0 to 7) of std_logic_vector(63 downto 0); 
type crUpstreamConfig_type is array (0 to 5) of std_logic_vector(63 downto 0); 

-------------------------------------------------------------------
-- 256-bit fifo out, one per GBT
-------------------------------------------------------------------
type d256b_array_type is array (natural range <>) of std_logic_vector(255 downto 0);

type txrx33b_type is array (natural range <>) of std_logic_vector(32 downto 0);

type GBTdm_data_array_type is array ( NATURAL RANGE <>) of std_logic_vector(255 downto 0);
type GBTdm_dsdata_array_type is array ( NATURAL RANGE <>) of std_logic_vector(31 downto 0);

type d32bit_array_type is array (0 to 255) of std_logic_vector(31 downto 0);
type d32bit_array32_type is array (0 to 31) of std_logic_vector(31 downto 0);

-------------------------------------------------------------------
-- 8 entry array of 8bit input
-------------------------------------------------------------------
type EPROC_FIFO_DIN_array_type is array (0 to 7) of std_logic_vector(7 downto 0);
type EPROC_FIFO_DIN_CODE_array_type is array (0 to 7) of std_logic_vector(1 downto 0);

-------------------------------------------------------------------
-- BLOCK size definition [in 16bit words]
-- chunck can span on part of a BLOCK or on several BLOCKs
-------------------------------------------------------------------
constant BLOCK_WORDn    : std_logic_vector(9 downto 0) := "1000000000";  -- = 512 (number of 16-bit words in a block) 
constant BLOCK_WORD32n  : std_logic_vector(8 downto 0) := "100000000";  -- = 256 (number of 32-bit words in a block) 

-------------------------------------------------------------------
-- 8b10b encoding / decoding parameters
-------------------------------------------------------------------
-- 1. 10-bit values 
--- comma / idle character
constant COMMAp : std_logic_vector (9 downto 0) := "0011111010"; -- -K.28.5
constant COMMAn : std_logic_vector (9 downto 0) := "1100000101"; -- +K.28.5
--- start-of-chunk and end-of-chunk characters
constant EOCp   : std_logic_vector (9 downto 0) := "0011110110"; -- -K.28.6 
constant EOCn   : std_logic_vector (9 downto 0) := "1100001001"; -- +K.28.6 
constant SOCp   : std_logic_vector (9 downto 0) := "0011111001"; -- -K.28.1
constant SOCn   : std_logic_vector (9 downto 0) := "1100000110"; -- +K.28.1
--- start-of-busy and end-of-busy characters
constant SOBp   : std_logic_vector (9 downto 0) := "0011110101"; -- -K.28.2 
constant SOBn   : std_logic_vector (9 downto 0) := "1100001010"; -- +K.28.2 
constant EOBp   : std_logic_vector (9 downto 0) := "0011110011"; -- -K.28.3 
constant EOBn   : std_logic_vector (9 downto 0) := "1100001100"; -- +K.28.3 

-- 2. 8-bit values 
constant Kchar_comma  : std_logic_vector (7 downto 0) := "10111100"; -- K28.5
constant Kchar_eop    : std_logic_vector (7 downto 0) := "11011100"; -- K28.6
constant Kchar_sop    : std_logic_vector (7 downto 0) := "00111100"; -- K28.1
constant Kchar_sob    : std_logic_vector (7 downto 0) := "01011100"; -- K28.2
constant Kchar_eob    : std_logic_vector (7 downto 0) := "01111100"; -- K28.3


-------------------------------------------------------------------
-- HDLC encoding / decoding parameters
-------------------------------------------------------------------
constant HDLC_flag : std_logic_vector(7 downto 0) := "01111110";


-------------------------------------------------------------------
-- TTC ToHost Data type
-------------------------------------------------------------------
type TTC_ToHost_data_type is record
    FMT          : std_logic_vector(7 downto 0);  --byte0
    LEN          : std_logic_vector(7 downto 0);  --byte1
    reserved0    : std_logic_vector(3 downto 0);  --byte2
    BCID         : std_logic_vector(11 downto 0); --byte2,3
    XL1ID        : std_logic_vector(7 downto 0);  --byte4
    L1ID         : std_logic_vector(23 downto 0); --byte 5,6,7
    orbit        : std_logic_vector(31 downto 0); --byte 8,9,10,11
    trigger_type : std_logic_vector(15 downto 0); --byte 12,13
    reserved1    : std_logic_vector(15 downto 0); --byte 14,15
    L0ID         : std_logic_vector(31 downto 0); --byte 16,17,18,19
    data_rdy     : std_logic;
end record;

----------------------------------------------------------------------------------
-- 7 EGROUPs configuration parameters:
----------------------------------------------------------------------------------

-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
-- MATLAB generated parameters, consistent with GBT LINK DATA EMULATOR .coe files
--<< begin
--
-- 1. EPROC_ENA_bits 15 bit vector per EGROUP (15 EPROCs in one EGROUP)
--   [EPROC_IN2 EPROC_IN2 EPROC_IN2 EPROC_IN2 EPROC_IN2 EPROC_IN2 EPROC_IN2 EPROC_IN2 EPROC_IN4 EPROC_IN4 EPROC_IN4 EPROC_IN4 EPROC_IN8 EPROC_IN8 EPROC_IN16]
--
type EPROC_ENA_bits_array_type is array (0 to 7) of std_logic_vector(14 downto 0);
constant EPROC_ENA_bits_array : EPROC_ENA_bits_array_type :=( 
"000000000000110",
"000000001111000",
"000000000000001",
"111111110000000",
"110011000101000",
"001100111010000",
"110011000101000",
"100000000000000");
--"000000000000000", -- IG: enables E-path 0 with 4 bits e-link configuration
--"000000000001000",
--"000000000000000",
--"000000000000000",
--"000000000000000",
--"000000000000000",
--"000000000000000",
--"000000000000000");
--
-- 2. PATH_ENCODING, 16 bit vector per EGROUP (2 bits per PATH, 8 PATHs in one EGROUP)
--   for each of 8 output paths: "00"=non,  "01"=8b10b,  "10"=HDLC
--
type EPROC_ENCODING_array_type is array (0 to 7) of std_logic_vector(15 downto 0);
constant PATH_ENCODING_array  : EPROC_ENCODING_array_type :=(
"0101010101010101",
"0101010101010101",
"0101010101010101",
"0101010101010101",
"0101010101010101",
"0101010101010101",
"0101010101010101",
"1000000000000000");
--
-- 3. Maximal valid CHUNK length for data truncation 
--   per GBT channel, 3MSBs per Eproc type 
--
constant MAX_CHUNK_LEN_array : std_logic_vector(11 downto 0) := "000000000000";
--<< end
-- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constant zeros17bits : std_logic_vector(16 downto 0) := (others=>'0');                                                                   
constant zeros21bits : std_logic_vector(20 downto 0) := (others =>'0');


-------------------------------------------------------------------
-- initial conf. constants for the case of {TTC_test_mode = false}
--
-- NOT a TTC test, initial configuration is generated using Matlab,
-- according to the selected options in a gui. 
-------------------------------------------------------------------
constant CR_TH_EGROUP0_CTRL_C :std_logic_vector(63 downto 0) :=(    
    zeros21bits &                   -- 17 + 4 bit: (63 downto 43)
    MAX_CHUNK_LEN_array &        -- 12 bit: (42 downto 31)
    PATH_ENCODING_array(0) &        -- 16 bit: (30 downto 15)
    EPROC_ENA_bits_array(0));       -- 15 bit: (14 downto 0)

constant CR_TH_EGROUP1_CTRL_C :std_logic_vector(63 downto 0) :=(    
    zeros21bits &                   -- 17 + 4 bit: (63 downto 43)
    MAX_CHUNK_LEN_array &        -- 12 bit: (42 downto 31)
    PATH_ENCODING_array(1) &        -- 16 bit: (30 downto 15)
    EPROC_ENA_bits_array(1));       -- 15 bit: (14 downto 0)

constant CR_TH_EGROUP2_CTRL_C :std_logic_vector(63 downto 0) :=(    
    zeros21bits &                   -- 17 + 4 bit: (63 downto 43)
    MAX_CHUNK_LEN_array &        -- 12 bit: (42 downto 31)
    PATH_ENCODING_array(2) &        -- 16 bit: (30 downto 15)
    EPROC_ENA_bits_array(2));       -- 15 bit: (14 downto 0)

constant CR_TH_EGROUP3_CTRL_C :std_logic_vector(63 downto 0) :=(    
    zeros21bits &                   -- 17 + 4 bit: (63 downto 43)
    MAX_CHUNK_LEN_array &        -- 12 bit: (42 downto 31)
    PATH_ENCODING_array(3) &        -- 16 bit: (30 downto 15)
    EPROC_ENA_bits_array(3));       -- 15 bit: (14 downto 0)

constant CR_TH_EGROUP4_CTRL_C :std_logic_vector(63 downto 0) :=(    
    zeros21bits &                   -- 17 + 4 bit: (63 downto 43)
    MAX_CHUNK_LEN_array &        -- 12 bit: (42 downto 31)
    PATH_ENCODING_array(4) &        -- 16 bit: (30 downto 15)
    EPROC_ENA_bits_array(4));       -- 15 bit: (14 downto 0)                                  

constant CR_TH_EGROUP5_CTRL_C :std_logic_vector(63 downto 0) :=(    
    zeros21bits &                   -- 17 + 4 bit: (63 downto 43)
    MAX_CHUNK_LEN_array &        -- 12 bit: (42 downto 31)
    PATH_ENCODING_array(5) &        -- 16 bit: (30 downto 15)
    EPROC_ENA_bits_array(5));       -- 15 bit: (14 downto 0)

constant CR_TH_EGROUP6_CTRL_C :std_logic_vector(63 downto 0) :=(    
    zeros21bits &                   -- 17 + 4 bit: (63 downto 43)
    MAX_CHUNK_LEN_array &        -- 12 bit: (42 downto 31)
    PATH_ENCODING_array(6) &        -- 16 bit: (30 downto 15)
    EPROC_ENA_bits_array(6));       -- 15 bit: (14 downto 0)   
    
constant CR_TH_EGROUP7_CTRL_C :std_logic_vector(63 downto 0) :=(    
    zeros21bits &                   -- 17 + 4 bit: (63 downto 43)
    MAX_CHUNK_LEN_array &        -- 12 bit: (42 downto 31)
    PATH_ENCODING_array(7) &        -- 16 bit: (30 downto 15)
    EPROC_ENA_bits_array(7));       -- 15 bit: (14 downto 0)   
                                                                
-------------------------------------------------------------------
-- Initial configuration of the from-host path: 
-- matched the initial configuration of the to-host path 
-- (and the initial contents of the GBT data emulators)
-- this allows for the loop-back test without reconfiguration 
-------------------------------------------------------------------
constant CR_FH_EGROUP0_CTRL_C : std_logic_vector(63 downto 0) := (zeros17bits & 
"00" & PATH_ENCODING_array(0)(15 downto 14) & 
"00" & PATH_ENCODING_array(0)(13 downto 12) & 
"00" & PATH_ENCODING_array(0)(11 downto 10) & 
"00" & PATH_ENCODING_array(0)(9 downto 8) & 
"00" & PATH_ENCODING_array(0)(7 downto 6) & 
"00" & PATH_ENCODING_array(0)(5 downto 4) & 
"00" & PATH_ENCODING_array(0)(3 downto 2) & 
"00" & PATH_ENCODING_array(0)(1 downto 0) & 
EPROC_ENA_bits_array(0));

constant CR_FH_EGROUP1_CTRL_C : std_logic_vector(63 downto 0) := (zeros17bits & 
"00" & PATH_ENCODING_array(1)(15 downto 14) & 
"00" & PATH_ENCODING_array(1)(13 downto 12) & 
"00" & PATH_ENCODING_array(1)(11 downto 10) & 
"00" & PATH_ENCODING_array(1)(9 downto 8) & 
"00" & PATH_ENCODING_array(1)(7 downto 6) & 
"00" & PATH_ENCODING_array(1)(5 downto 4) & 
"00" & PATH_ENCODING_array(1)(3 downto 2) & 
"00" & PATH_ENCODING_array(1)(1 downto 0) & 
EPROC_ENA_bits_array(1));

constant CR_FH_EGROUP2_CTRL_C : std_logic_vector(63 downto 0) := (zeros17bits & 
"00" & PATH_ENCODING_array(2)(15 downto 14) & 
"00" & PATH_ENCODING_array(2)(13 downto 12) & 
"00" & PATH_ENCODING_array(2)(11 downto 10) & 
"00" & PATH_ENCODING_array(2)(9 downto 8) & 
"00" & PATH_ENCODING_array(2)(7 downto 6) & 
"00" & PATH_ENCODING_array(2)(5 downto 4) & 
"00" & PATH_ENCODING_array(2)(3 downto 2) & 
"00" & PATH_ENCODING_array(2)(1 downto 0) & 
EPROC_ENA_bits_array(2));

constant CR_FH_EGROUP3_CTRL_C : std_logic_vector(63 downto 0) := (zeros17bits & 
"00" & PATH_ENCODING_array(3)(15 downto 14) & 
"00" & PATH_ENCODING_array(3)(13 downto 12) & 
"00" & PATH_ENCODING_array(3)(11 downto 10) & 
"00" & PATH_ENCODING_array(3)(9 downto 8) & 
"00" & PATH_ENCODING_array(3)(7 downto 6) & 
"00" & PATH_ENCODING_array(3)(5 downto 4) & 
"00" & PATH_ENCODING_array(3)(3 downto 2) & 
"00" & PATH_ENCODING_array(3)(1 downto 0) & 
EPROC_ENA_bits_array(3));

constant CR_FH_EGROUP4_CTRL_C : std_logic_vector(63 downto 0) := (zeros17bits & 
"00" & PATH_ENCODING_array(4)(15 downto 14) & 
"00" & PATH_ENCODING_array(4)(13 downto 12) & 
"00" & PATH_ENCODING_array(4)(11 downto 10) & 
"00" & PATH_ENCODING_array(4)(9 downto 8) & 
"00" & PATH_ENCODING_array(4)(7 downto 6) & 
"00" & PATH_ENCODING_array(4)(5 downto 4) & 
"00" & PATH_ENCODING_array(4)(3 downto 2) & 
"00" & PATH_ENCODING_array(4)(1 downto 0) & 
EPROC_ENA_bits_array(4));

constant CR_FH_EGROUP5_CTRL_C : std_logic_vector(63 downto 0) := (zeros17bits & 
"00" & PATH_ENCODING_array(7)(15 downto 14) & 
"00" & PATH_ENCODING_array(7)(13 downto 12) & 
"00" & PATH_ENCODING_array(7)(11 downto 10) & 
"00" & PATH_ENCODING_array(7)(9 downto 8) & 
"00" & PATH_ENCODING_array(7)(7 downto 6) & 
"00" & PATH_ENCODING_array(7)(5 downto 4) & 
"00" & PATH_ENCODING_array(7)(3 downto 2) & 
"00" & PATH_ENCODING_array(7)(1 downto 0) & 
EPROC_ENA_bits_array(7));


-------------------------------------------------------------------
-- initial configuration of the from- and to-host paths 
-- for the case of {TTC_test_mode = true}
-- TTC test mode, normal GBT mode only! 
-- Central Router generic 'wideMode' has to be set false.
-- Congifuration of TTC-from-host matches 
-- the direct-to-host congifuration.
-- Trom-Host is TTC, to-Host is direct data.
-------------------------------------------------------------------
--
-- egroup0: 8 x EPROCx2s. direct data: TTC-0 (2bit) [B-chan L1A]
constant CR_FH_EGROUP0_CTRL_C_TTC_test : std_logic_vector(63 downto 0) := zeros17bits & x"33333333" & "111111110000000"; -- TTC-0
constant CR_TH_EGROUP0_CTRL_C_TTC_test : std_logic_vector(63 downto 0) := zeros21bits & "000000000000" & "0000000000000000" & "111111110000000";            
-- egroup1: 4 x EPROCx4s. direct data: TTC-1 (4bit) [B-chan ECR BCR L1A]
constant CR_FH_EGROUP1_CTRL_C_TTC_test : std_logic_vector(63 downto 0) := zeros17bits & x"03030303" & "000000001111000";  -- TTC-1
constant CR_TH_EGROUP1_CTRL_C_TTC_test : std_logic_vector(63 downto 0) := zeros21bits & "000000000000" & "0000000000000000" & "000000001111000";  
-- egroup2: 4 x EPROCx4s. direct data: TTC-2 (4bit) [Brcst[2] ECR BCR L1A] 
constant CR_FH_EGROUP2_CTRL_C_TTC_test : std_logic_vector(63 downto 0) := zeros17bits & x"04040404" & "000000001111000";  -- TTC-2
constant CR_TH_EGROUP2_CTRL_C_TTC_test : std_logic_vector(63 downto 0) := zeros21bits & "000000000000" & "0000000000000000" & "000000001111000";  
-- egroup3: 2 x EPROCx8s. direct data: TTC-3 (8bit) [B-chan Brcst[5] Brcst[4] Brcst[3] Brcst[2] ECR BCR L1A]
constant CR_FH_EGROUP3_CTRL_C_TTC_test : std_logic_vector(63 downto 0) := zeros17bits & x"00300030" & "000000000000110";  -- TTC-3
constant CR_TH_EGROUP3_CTRL_C_TTC_test : std_logic_vector(63 downto 0) := zeros21bits & "000000000000" & "0000000000000000" & "000000000000110";  
-- egroup4: 2 x EPROCx8s. direct data: TTC-4 (8bit) [Brcst[6] Brcst[5] Brcst[4] Brcst[3] Brcst[2] ECR BCR L1A]
constant CR_FH_EGROUP4_CTRL_C_TTC_test : std_logic_vector(63 downto 0) := zeros17bits & x"00400040" & "000000000000110";  -- TTC-4
constant CR_TH_EGROUP4_CTRL_C_TTC_test : std_logic_vector(63 downto 0) := zeros21bits & "000000000000" & "0000000000000000" & "000000000000110";  
-- egroup7: 8 x EPROCx2s. direct data: TTC-0 (2bit) [B-chan L1A]
constant CR_FH_EGROUP5_CTRL_C_TTC_test : std_logic_vector(63 downto 0) := zeros17bits & x"33333333" & "111111110000000"; -- TTC-0
constant CR_TH_EGROUP7_CTRL_C_TTC_test : std_logic_vector(63 downto 0) := zeros21bits & "000000000000" & "0000000000000000" & "000000000000110";  
--
--
constant CR_TH_EGROUP5_CTRL_C_TTC_test : std_logic_vector(63 downto 0) := (others=>'0');
constant CR_TH_EGROUP6_CTRL_C_TTC_test : std_logic_vector(63 downto 0) := (others=>'0');
--
--

end package centralRouter_package ;

    
  
