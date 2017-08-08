----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    09:38:49 06/13/2011
-- Design Name:
-- Module Name:    UDP_ICMP_Complete_nomac - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - separated RX and TX clocks
-- Revision 0.03 - Added mac_tx_tfirst
-- Additional Comments: Added ICMP ping functionality (CB)
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.axi.all;
use work.ipv4_types.all;
use work.arp_types.all;

entity UDP_ICMP_Complete_nomac is
    generic (
			CLOCK_FREQ			: integer := 125000000;							-- freq of data_in_clk -- needed to timout cntr
			ARP_TIMEOUT			: integer := 60;									-- ARP response timeout (s)
			ARP_MAX_PKT_TMO	    : integer := 5;									-- # wrong nwk pkts received before set error
			MAX_ARP_ENTRIES 	: integer := 255									-- max entries in the ARP store
			);
    Port (
			-- UDP TX signals
			udp_tx_start			: in  std_logic;							-- indicates req to tx UDP
			udp_txi					: in  udp_tx_type;							-- UDP tx cxns
			udp_tx_result			: out std_logic_vector (1 downto 0);-- tx status (changes during transmission)
			udp_tx_data_out_ready   : out std_logic;							-- indicates udp_tx is ready to take data
			-- UDP RX signals
			udp_rx_start			: out std_logic;							-- indicates receipt of udp header
			udp_rxo					: out udp_rx_type;
            -- ICMP RX signals
            icmp_rx_start           : out std_logic;
            icmp_rxo                : out icmp_rx_type;
			-- IP RX signals
			ip_rx_hdr				: out ipv4_rx_header_type;
			-- system signals
			rx_clk					: in  std_logic;
			tx_clk					: in  std_logic;
			reset 					: in  std_logic;
			fifo_init               : in  std_logic;
			our_ip_address 		    : in  std_logic_vector (31 downto 0);
			our_mac_address 		: in  std_logic_vector (47 downto 0);
			control					: in  udp_control_type;
			-- status signals
			arp_pkt_count			: out std_logic_vector(7 downto 0);			-- count of arp pkts received
			ip_pkt_count			: out std_logic_vector(7 downto 0);			-- number of IP pkts received for us
			-- MAC Transmitter
			mac_tx_tdata            : out std_logic_vector(7 downto 0);	-- data byte to tx
			mac_tx_tvalid           : out std_logic;							-- tdata is valid
			mac_tx_tready           : in  std_logic;							-- mac is ready to accept data
			mac_tx_tfirst           : out std_logic;							-- indicates first byte of frame
			mac_tx_tlast            : out std_logic;							-- indicates last byte of frame
			-- MAC Receiver
			mac_rx_tdata            : in  std_logic_vector(7 downto 0);	-- data byte received
			mac_rx_tvalid           : in  std_logic;							-- indicates tdata is valid
			mac_rx_tready           : out std_logic;							-- tells mac that we are ready to take data
			mac_rx_tlast            : in  std_logic								-- indicates last byte of the trame
    );
end UDP_ICMP_Complete_nomac;





architecture structural of UDP_ICMP_Complete_nomac is

  ------------------------------------------------------------------------------
  -- Component Declaration for UDP TX
  ------------------------------------------------------------------------------

    COMPONENT UDP_TX
        PORT(
			-- UDP Layer signals
			udp_tx_start			: in  std_logic;							-- indicates req to tx UDP
			udp_txi					: in  udp_tx_type;							-- UDP tx cxns
			udp_tx_result			: out std_logic_vector (1 downto 0);-- tx status (changes during transmission)
			udp_tx_data_out_ready   : out std_logic;							-- indicates udp_tx is ready to take data
			-- system signals
			clk 					: in  STD_LOGIC;							-- same clock used to clock mac data and ip data
			reset 					: in  STD_LOGIC;
			-- IP layer TX signals
			ip_tx_start				: out std_logic;
			ip_tx					: out ipv4_tx_type;							-- IP tx cxns
			ip_tx_result			: in  std_logic_vector (1 downto 0);		-- tx status (changes during transmission)
			ip_tx_data_out_ready	: in  std_logic									-- indicates IP TX is ready to take data
        );
    END COMPONENT;

  ------------------------------------------------------------------------------
  -- Component Declaration for UDP RX
  ------------------------------------------------------------------------------

    COMPONENT UDP_RX
        PORT(
			-- UDP Layer signals
			udp_rx_start			: out std_logic;							-- indicates receipt of udp header
			udp_rxo					: out udp_rx_type;
			-- system signals
			clk 					: in  STD_LOGIC;
			reset 					: in  STD_LOGIC;
			-- IP layer RX signals
			ip_rx_start				: in  std_logic;							-- indicates receipt of ip header
			ip_rx					: in  ipv4_rx_type
        );
    END COMPONENT;

  ------------------------------------------------------------------------------
  -- Component Declaration for ICMP TX
  ------------------------------------------------------------------------------

    COMPONENT ICMP_TX
        PORT (
            -- ICMP layer signals
            icmp_tx_start           : in  std_logic;                       -- indicates req to tx ICMP
            icmp_txi                : in  icmp_tx_type;                    -- icmp tx cxns
            icmp_tx_data_out_ready  : out std_logic;                       -- indicates icmp_tx is ready to take data
            -- system signals
            clk                     : in  STD_LOGIC;                       -- same clock used to clock mac data and ip data
            reset                   : in  STD_LOGIC;
            icmp_tx_is_idle         : out STD_LOGIC;
            -- IP layer TX signals
            ip_tx_start             : out std_logic;
            ip_tx                   : out ipv4_tx_type;                    -- IP tx cxns
            ip_tx_result            : in  std_logic_vector (1 downto 0);   -- tx status (changes during transmission)
            ip_tx_data_out_ready    : in  std_logic                        -- indicates IP TX is ready to take data
            );
    END COMPONENT;

  ------------------------------------------------------------------------------
  -- Component Declaration for ICMP RX
  ------------------------------------------------------------------------------

    COMPONENT ICMP_RX
        PORT (
            -- ICMP Layer signals
            icmp_rx_start           : out std_logic;       -- indicates receipt of icmp header
            icmp_rxo                : out icmp_rx_type;
            -- system signals
            clk                     : in  std_logic;
            reset                   : in  std_logic;
            -- IP layer RX signals
            ip_rx_start             : in  std_logic;       -- indicates receipt of ip header
            ip_rx                   : in  ipv4_rx_type
            );
    END COMPONENT;

  ------------------------------------------------------------------------------
  -- Component Declaration for UDP_TX/ICMP_TX Multiplexer
  ------------------------------------------------------------------------------ 

    COMPONENT icmp_udp_mux
        PORT (
            -- from ping reply handler
            sel_icmp                : in  std_logic;
            -- from ICMP_TX 
            ip_tx_start_icmp        : in  std_logic;
            ip_tx_icmp              : in  ipv4_tx_type;
            -- from UDP_TX
            ip_tx_start_udp         : in  std_logic;
            ip_tx_udp               : in  ipv4_tx_type;
            -- to IP Layer
            ip_tx_start_IP          : out std_logic;
            ip_tx_IP                : out ipv4_tx_type
        );
    END COMPONENT;

  ------------------------------------------------------------------------------
  -- Component Declaration for the Ping Reply Handling Module
  ------------------------------------------------------------------------------ 

    COMPONENT ping_reply_processor
    PORT (
            -- ICMP RX interface
            icmp_rx_start           : in std_logic;
            icmp_rxi                : in icmp_rx_type;
            -- system signals
            tx_clk                  : in std_logic;
            rx_clk                  : in std_logic;
            reset                   : in std_logic;
            fifo_init               : in std_logic;
            -- ICMP/UDP mux interface
            sel_icmp                : out std_logic;
            -- ICMP TX interface
            icmp_tx_start           : out std_logic;
            icmp_tx_ready           : in  std_logic;
            icmp_txo                : out icmp_tx_type;
            icmp_tx_is_idle         : in  std_logic
        );
    END COMPONENT;

  ------------------------------------------------------------------------------
  -- Component Declaration for the IP layer
  ------------------------------------------------------------------------------

    component IP_complete_nomac
        generic (
			CLOCK_FREQ			: integer := 125000000;							-- freq of data_in_clk -- needed to timout cntr
			ARP_TIMEOUT			: integer := 60;								-- ARP response timeout (s)
			ARP_MAX_PKT_TMO	    : integer := 5;									-- # wrong nwk pkts received before set error
			MAX_ARP_ENTRIES 	: integer := 255								-- max entries in the ARP store
        );
        Port (
			-- IP Layer signals
			ip_tx_start				  : in std_logic;
			ip_tx					  : in ipv4_tx_type;						-- IP tx cxns
			ip_tx_result			  : out std_logic_vector (1 downto 0);		-- tx status (changes during transmission)
			ip_tx_data_out_ready	  : out std_logic;							-- indicates IP TX is ready to take data
			ip_rx_start				  : out std_logic;							-- indicates receipt of ip frame.
			ip_rx				      : out ipv4_rx_type;
			-- system signals
			rx_clk					  : in  STD_LOGIC;
			tx_clk					  : in  STD_LOGIC;
			reset 					  : in  STD_LOGIC;
			our_ip_address 		      : in STD_LOGIC_VECTOR (31 downto 0);
			our_mac_address 		  : in std_logic_vector (47 downto 0);
			control					  : in ip_control_type;
			-- status signals
			arp_pkt_count			  : out STD_LOGIC_VECTOR(7 downto 0);		-- count of arp pkts received
			ip_pkt_count			  : out STD_LOGIC_VECTOR(7 downto 0);		-- number of IP pkts received for us
			-- MAC Transmitter
			mac_tx_tdata              : out  std_logic_vector(7 downto 0);	    -- data byte to tx
			mac_tx_tvalid             : out  std_logic;							-- tdata is valid
			mac_tx_tready             : in std_logic;							-- mac is ready to accept data
			mac_tx_tfirst             : out  std_logic;							-- indicates first byte of frame
			mac_tx_tlast              : out  std_logic;							-- indicates last byte of frame
			-- MAC Receiver
			mac_rx_tdata              : in std_logic_vector(7 downto 0);	    -- data byte received
			mac_rx_tvalid             : in std_logic;							-- indicates tdata is valid
			mac_rx_tready             : out  std_logic;							-- tells mac that we are ready to take data
			mac_rx_tlast              : in std_logic							-- indicates last byte of the trame
        );
    end component;

	-- IP TX connectivity
    signal ip_tx_int 			 	  : ipv4_tx_type;
    signal ip_tx_start_int 			  : std_logic;
    signal ip_tx_int_icmp             : ipv4_tx_type;
    signal ip_tx_start_int_icmp       : std_logic;
    signal ip_tx_int_udp              : ipv4_tx_type;
    signal ip_tx_start_int_udp        : std_logic;
	signal ip_tx_result_int		      : std_logic_vector (1 downto 0);
	signal ip_tx_data_out_ready_int	  : std_logic;
	signal icmp_rx_start_int          : std_logic;
    signal icmp_rxo_int               : icmp_rx_type;
    signal icmp_tx_is_idle            : std_logic;
    
	-- IP RX connectivity
    signal ip_rx_int 			      : ipv4_rx_type;
    signal ip_rx_start_int	          : std_logic := '0';

    -- ICMP_TX / Ping Reply Handler connectivity
    signal icmp_tx_start              : std_logic := '0';
    signal icmp_tx_data_out_ready     : std_logic := '0';
    signal sel_icmp                   : std_logic := '0';
    signal icmp_tx_int                : icmp_tx_type;

begin

	-- output followers
	ip_rx_hdr <= ip_rx_int.hdr;

	-- Instantiate the UDP TX block
    udp_tx_block: UDP_TX
        PORT MAP (
            -- UDP Layer signals
            udp_tx_start 			=> udp_tx_start,
            udp_txi 				=> udp_txi,
            udp_tx_result			=> udp_tx_result,
            udp_tx_data_out_ready   => udp_tx_data_out_ready,
            -- system signals
            clk 					=> tx_clk,
            reset 					=> reset,
            -- IP layer TX signals
            ip_tx_start 			=> ip_tx_start_int_udp,
            ip_tx 					=> ip_tx_int_udp,
            ip_tx_result			=> ip_tx_result_int,
            ip_tx_data_out_ready	=> ip_tx_data_out_ready_int
    );

	-- Instantiate the UDP RX block
    udp_rx_block: UDP_RX 
        PORT MAP (
             -- UDP Layer signals
             udp_rxo 				=> udp_rxo,
             udp_rx_start 			=> udp_rx_start,
             -- system signals
             clk 					=> rx_clk,
             reset 					=> reset,
             -- IP layer RX signals
             ip_rx_start 			=> ip_rx_start_int,
             ip_rx 					=> ip_rx_int
    );

    -- Instantiate the ICMP TX block
    icmp_tx_block: ICMP_TX
        PORT MAP(
            -- ICMP layer signals
            icmp_tx_start           => icmp_tx_start,
            icmp_txi                => icmp_tx_int,
            icmp_tx_data_out_ready  => icmp_tx_data_out_ready,
            -- system signals
            clk                     => tx_clk,
            reset                   => reset,
            icmp_tx_is_idle         => icmp_tx_is_idle,
            -- IP layer TX signals
            ip_tx_start             => ip_tx_start_int_icmp,
            ip_tx                   => ip_tx_int_icmp,
            ip_tx_result            => ip_tx_result_int,
            ip_tx_data_out_ready    => ip_tx_data_out_ready_int            
    );

    -- Instantiate the ICMP RX block
    icmp_rx_block: ICMP_RX
        PORT MAP(
            -- ICMP Layer signals
            icmp_rx_start           => icmp_rx_start_int,
            icmp_rxo                => icmp_rxo_int,
            -- system signals
            clk                     => rx_clk,
            reset                   => reset,
            -- IP layer RX signals
            ip_rx_start             => ip_rx_start_int,
            ip_rx                   => ip_rx_int
    );
    

    -- Instantiate the UDP_TX/ICMP_TX multiplexer
    mux_block: icmp_udp_mux
        PORT MAP(
            -- from ping reply handler
            sel_icmp                => sel_icmp,
            -- from ICMP_TX 
            ip_tx_start_icmp        => ip_tx_start_int_icmp,
            ip_tx_icmp              => ip_tx_int_icmp,
            -- from UDP_TX
            ip_tx_start_udp         => ip_tx_start_int_udp,
            ip_tx_udp               => ip_tx_int_udp,
            -- to IP Layer
            ip_tx_start_IP          => ip_tx_start_int,
            ip_tx_IP                => ip_tx_int
    );

    -- Instantiate the Ping Reply Handler
    ping_reply_block: ping_reply_processor
    PORT MAP(
            -- ICMP RX interface
            icmp_rx_start           => icmp_rx_start_int,
            icmp_rxi                => icmp_rxo_int,
            -- system signals
            tx_clk                  => tx_clk,
            rx_clk                  => rx_clk,
            reset                   => reset,
            fifo_init               => fifo_init,
            -- ICMP/UDP mux interface
            sel_icmp                => sel_icmp,
            -- ICMP TX interface
            icmp_tx_start           => icmp_tx_start,
            icmp_tx_ready           => icmp_tx_data_out_ready,
            icmp_txo                => icmp_tx_int,
            icmp_tx_is_idle         => icmp_tx_is_idle
    );

   ------------------------------------------------------------------------------
   -- Instantiate the IP layer
   ------------------------------------------------------------------------------
    IP_block : IP_complete_nomac
		generic map (
			 CLOCK_FREQ			    => CLOCK_FREQ,
			 ARP_TIMEOUT		    => ARP_TIMEOUT,
			 ARP_MAX_PKT_TMO	    => ARP_MAX_PKT_TMO,
			 MAX_ARP_ENTRIES	    => MAX_ARP_ENTRIES)
		PORT MAP (
            -- IP interface
            ip_tx_start 			=> ip_tx_start_int,
            ip_tx 					=> ip_tx_int,
            ip_tx_result			=> ip_tx_result_int,
            ip_tx_data_out_ready	=> ip_tx_data_out_ready_int,
            ip_rx_start 			=> ip_rx_start_int,
            ip_rx 					=> ip_rx_int,
            -- System interface
            rx_clk 					=> rx_clk,
            tx_clk 					=> tx_clk,
            reset 					=> reset,
            our_ip_address 		    => our_ip_address,
            our_mac_address 		=> our_mac_address,
            control					=> control.ip_controls,
            -- status signals
            arp_pkt_count 			=> arp_pkt_count,
            ip_pkt_count			=> ip_pkt_count,
            -- MAC Transmitter
            mac_tx_tdata 			=> mac_tx_tdata,
            mac_tx_tvalid 			=> mac_tx_tvalid,
            mac_tx_tready 			=> mac_tx_tready,
            mac_tx_tfirst 			=> mac_tx_tfirst,
            mac_tx_tlast 			=> mac_tx_tlast,
            -- MAC Receiver
            mac_rx_tdata 			=> mac_rx_tdata,
            mac_rx_tvalid 			=> mac_rx_tvalid,
            mac_rx_tready 			=> mac_rx_tready,
            mac_rx_tlast 			=> mac_rx_tlast
        );
        
        icmp_rx_start <= icmp_rx_start_int;
        icmp_rxo      <= icmp_rxo_int;

end structural;


