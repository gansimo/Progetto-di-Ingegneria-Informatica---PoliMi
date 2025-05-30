library UNISIM;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use UNISIM.vcomponents.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TOP_entity is
 port (
        reset   :   IN STD_LOGIC;
        
        sys_clk : IN STD_LOGIC;
        
        start : IN STD_LOGIC;
        
        psi_data : OUT STD_LOGIC;
        psi_clk : OUT STD_LOGIC;
        
        eth_col : IN STD_LOGIC;
        eth_crs : IN STD_LOGIC;
        eth_rstn : OUT STD_LOGIC;
        eth_rx_clk : IN STD_LOGIC;
        eth_rx_dv : IN STD_LOGIC;
        eth_rxerr : IN STD_LOGIC;
        eth_rxd : IN STD_LOGIC_VECTOR(3 downto 0);
        eth_tx_clk : IN STD_LOGIC;
        eth_tx_en : OUT STD_LOGIC;
        eth_txd : OUT STD_LOGIC_VECTOR(3 downto 0);
        
        eth_ref_clk_out : out std_logic;
        eth_rst : in std_logic;
        
        spi_start : IN STD_LOGIC;
        spi_data : OUT STD_LOGIC;
        spi_le  : OUT STD_LOGIC;
        spi_clk_o : OUT STD_LOGIC
        
         );
end TOP_entity;

architecture Behavioral of TOP_entity is

component AXI_interface_PSI
port (
            axi_clk_i     : in STD_LOGIC;
            psi_clk_i     : in STD_LOGIC;
            psi_data_i    : in STD_LOGIC;

            s_axi_aresetn : in  STD_LOGIC;

            s_axi_awaddr  : out  STD_LOGIC_VECTOR(12 downto 0) := (others => '0');
            s_axi_awvalid : out  STD_LOGIC;
            s_axi_awready : in STD_LOGIC;
            s_axi_wdata   : out  STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
            s_axi_wstrb   : out  STD_LOGIC_VECTOR(3 downto 0) := "1111";
            s_axi_wvalid  : out  STD_LOGIC;
            s_axi_wready  : in STD_LOGIC;
            s_axi_bresp   : in STD_LOGIC_VECTOR(1 downto 0);
            s_axi_bvalid  : in STD_LOGIC;
            s_axi_bready  : out  STD_LOGIC := '0';
            s_axi_araddr  : out  STD_LOGIC_VECTOR(12 downto 0) := (others => '0');
            s_axi_arvalid : out  STD_LOGIC := '0';
            s_axi_arready : in STD_LOGIC;
            s_axi_rdata   : in STD_LOGIC_VECTOR(31 downto 0);
            s_axi_rresp   : in STD_LOGIC_VECTOR(1 downto 0);
            s_axi_rvalid  : in STD_LOGIC;
            s_axi_rready  : out  STD_LOGIC := '0';

            start : in std_logic;
            startPSI: in std_logic;

            ip2intc_irpt  : in STD_LOGIC
        );
end component;

component axi_ethernetlite_0 is
PORT (
      s_axi_aclk : IN STD_LOGIC;
    s_axi_aresetn : IN STD_LOGIC;
    ip2intc_irpt : OUT STD_LOGIC;
    s_axi_awaddr : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
    s_axi_awvalid : IN STD_LOGIC;
    s_axi_awready : OUT STD_LOGIC;
    s_axi_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axi_wstrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    s_axi_wvalid : IN STD_LOGIC;
    s_axi_wready : OUT STD_LOGIC;
    s_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi_bvalid : OUT STD_LOGIC;
    s_axi_bready : IN STD_LOGIC;
    s_axi_araddr : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
    s_axi_arvalid : IN STD_LOGIC;
    s_axi_arready : OUT STD_LOGIC;
    s_axi_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi_rvalid : OUT STD_LOGIC;
    s_axi_rready : IN STD_LOGIC;
    phy_tx_clk : IN STD_LOGIC;
    phy_rx_clk : IN STD_LOGIC;
    phy_crs : IN STD_LOGIC;
    phy_dv : IN STD_LOGIC;
    phy_rx_data : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    phy_col : IN STD_LOGIC;
    phy_rx_er : IN STD_LOGIC;
    phy_rst_n : OUT STD_LOGIC;
    phy_tx_en : OUT STD_LOGIC;
    phy_tx_data : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
end component;

component clk_wiz_0 is
PORT(
    clk_in1 : IN STD_LOGIC;
    reset   : IN STD_LOGIC;
    locked  : OUT STD_LOGIC;
    clk_out1: OUT STD_LOGIC;
    clk_out2: OUT STD_LOGIC;
    clk_out3: OUT STD_LOGIC;
    clk_out4: OUT STD_LOGIC
    );
end component;

component SPI_interface is
port(
    rst             : in std_logic;

    spi_start_i     : in std_logic := '0';
    
    addr_i          : in std_logic_vector(7 downto 0) := "00110010";
    data_i          : in std_logic_vector(18 downto 0) := "1010011100100101001";
    
    spi_clk_i       : in std_logic;
    spi_data_o      : out std_logic := '0';
    spi_le_i        : out std_logic := '0'
    );
end component;

component DUT is
        port(
            rst                 :   in std_logic;
        
            spi_clk_i           :   in std_logic ;
            spi_data_i          :   in std_logic;
            spi_le_i            :   inout std_logic;
            addr_o              :   out integer := 0;
            data_o              :   out integer := 0;
            spi_start_i         :   in std_logic;
            
            curr_state          :   out integer;
            matlab_i            :   in std_logic;
            startPSI            :   out std_logic;           
            
            psi_clk_o           :   in std_logic;
            psi_data_o          :   out std_logic := '0';
            psi_we_o            :   out std_logic := '0';
            psi_rdyn_o          :   out std_logic := '0');          
end component;
     
    

signal state : std_logic_vector(2 downto 0);

signal axi_clk : STD_LOGIC;
 
signal             s_axi_awaddr  :   STD_LOGIC_VECTOR(12 downto 0);
signal             s_axi_awvalid :   STD_LOGIC;
signal             s_axi_awready :  STD_LOGIC;
signal             s_axi_wdata   :   STD_LOGIC_VECTOR(31 downto 0);
signal             BUFFER1       : std_logic_vector(31 downto 0);
signal             BUFFER2       : std_logic_vector(31 downto 0);
signal             s_axi_wstrb   :   STD_LOGIC_VECTOR(3 downto 0);
signal             s_axi_wvalid  :   STD_LOGIC;
signal             s_axi_wready  :  STD_LOGIC;
signal             s_axi_bresp   :  STD_LOGIC_VECTOR(1 downto 0);
signal             s_axi_bvalid  :  STD_LOGIC;
signal             s_axi_bready  :   STD_LOGIC;
signal             s_axi_araddr  :   STD_LOGIC_VECTOR(12 downto 0);
signal             s_axi_arvalid :   STD_LOGIC;
signal             s_axi_arready :  STD_LOGIC;
signal             s_axi_rdata   :  STD_LOGIC_VECTOR(31 downto 0);
signal             s_axi_rresp   :  STD_LOGIC_VECTOR(1 downto 0);
signal             s_axi_rvalid  :  STD_LOGIC;
signal             s_axi_rready  :   STD_LOGIC;

signal             ping0_pong1   : STD_LOGIC;

signal             ip2intc_irpt  :  STD_LOGIC;


signal              phy_crs :  STD_LOGIC;
signal              phy_rx_data :  STD_LOGIC_VECTOR(3 DOWNTO 0);
signal              phy_col :  STD_LOGIC := '0';
signal              phy_rx_er :  STD_LOGIC;
signal              phy_rst_n :  STD_LOGIC;
signal              phy_tx_en :  STD_LOGIC;
signal              phy_tx_data :  STD_LOGIC_VECTOR(3 DOWNTO 0);
signal              s_axi_phy_mdio_i : std_logic;
signal              s_axi_phy_mdio_o : std_logic;
signal              s_axi_phy_mdio_t : std_logic;
signal              s_axi_phy_mdc    : std_logic;

signal              s_eth_ref_clk : std_logic;

signal              spi_clk : STD_LOGIC;

signal              not_rst : std_logic;

signal              matlab : std_logic;
signal              spi_data_DUT: std_logic;
signal              spi_le_DUT: std_logic;
signal              start_psi_DUT : std_logic;
signal              startPSI: std_logic;
signal              psi_clk_pll: std_logic;
signal              curr_state : integer;


signal              skip : std_logic;

-- sine lookup table
type sine_table_type is array (0 to 63) of std_logic_vector(15 downto 0);
constant sine_table : sine_table_type := (
    "0000000000000000", "0000001100100100", "0000011001000100", "0000100101010100",  
    "0000110001100010", "0000111101100010", "0001001001010010", "0001010100110100",  
    "0001100000001000", "0001101011001010", "0001110101111010", "0010000011100100",  
    "0010001001101100", "0010010010010100", "0010011010011000", "0010100011111000",  
    "0010101101001000", "0010110110110100", "0011000000011000", "0011001001101000",  
    "0011010010110100", "0011011011111000", "0011100100110100", "0011101101101000",  
    "0011110110010100", "0011111110111000", "0100000111010100", "0100001111101000",  
    "0100010111110100", "0100011111111000", "0100100111110100", "0100101111101000",  
    "0100110111010100", "0100111110111000", "0101000110010100", "0101001101101000",  
    "0101010100110100", "0101011011111000", "0101100010110100", "0101101001101000",  
    "0101110000011000", "0101110110110100", "0101111101001000", "0110000011011000",  
    "0110001001100100", "0110001111101000", "0110010101100100", "0110011011011000",  
    "0110100001000100", "0110100110101000", "0110101100000100", "0110110001011000",  
    "0110110110100100", "0110111011101000", "0111000000100100", "0111000101011000",  
    "0111001010000100", "0111001110101000", "0111010011000100", "0111010111011000",  
    "0111011011100100", "0111011111101000", "0111100011100100", "0111100111011000"   
);

-- signals for sine wave generation
signal table_index : integer range 0 to 63 := 0;
signal direction : std_logic := '0';  -- '0' for forward, '1' for reverse
signal sign : std_logic := '0';       -- '0' for positive, '1' for negative
signal cycle_count : integer := 0;    -- count complete sine wave cycles
signal bit_counter : integer range 0 to 15 := 0;  -- counter for current bit in 16-bit word
signal test_completed : std_logic := '0';  -- signal to indicate test completion

signal not_eth_rst : std_logic;

begin

not_rst <= not reset;
not_eth_rst <= not eth_rst;

interface: AXI_interface_PSI
    port map (
        psi_clk_i => psi_clk_pll,
        psi_data_i => matlab,
        axi_clk_i => axi_clk,
    
        s_axi_aresetn => not_rst,
       
        -- AXI Lite slave interface
        s_axi_awaddr  => s_axi_awaddr,
        s_axi_awvalid => s_axi_awvalid,
        s_axi_awready => s_axi_awready,
        s_axi_wdata   => s_axi_wdata,
        s_axi_wstrb   => s_axi_wstrb,
        s_axi_wvalid  => s_axi_wvalid,
        s_axi_wready  => s_axi_wready,
        s_axi_bresp   => s_axi_bresp,
        s_axi_bvalid  => s_axi_bvalid,
        s_axi_bready  => s_axi_bready,
        s_axi_araddr  => s_axi_araddr,
        s_axi_arvalid => s_axi_arvalid,
        s_axi_arready => s_axi_arready,
        s_axi_rdata   => s_axi_rdata,
        s_axi_rresp   => s_axi_rresp,
        s_axi_rvalid  => s_axi_rvalid,
        s_axi_rready  => s_axi_rready,
        start => start,
        startPSI => startPSI,
       
        -- Interrupt output
        ip2intc_irpt  => ip2intc_irpt
    );
    
    
    eth: axi_ethernetlite_0
     port map (
        s_axi_aclk    => axi_clk,
        s_axi_aresetn => not_eth_rst,
       
        -- AXI Lite slave interface
        s_axi_awaddr  => s_axi_awaddr,
        s_axi_awvalid => s_axi_awvalid,
        s_axi_awready => s_axi_awready,
        s_axi_wdata   => s_axi_wdata,
        s_axi_wstrb   => s_axi_wstrb,
        s_axi_wvalid  => s_axi_wvalid,
        s_axi_wready  => s_axi_wready,
        s_axi_bresp   => s_axi_bresp,
        s_axi_bvalid  => s_axi_bvalid,
        s_axi_bready  => s_axi_bready,
        s_axi_araddr  => s_axi_araddr,
        s_axi_arvalid => s_axi_arvalid,
        s_axi_arready => s_axi_arready,
        s_axi_rdata   => s_axi_rdata,
        s_axi_rresp   => s_axi_rresp,
        s_axi_rvalid  => s_axi_rvalid,
        s_axi_rready  => s_axi_rready,
        
        phy_tx_clk => eth_tx_clk,
        phy_rx_clk =>eth_rx_clk,
        phy_crs => eth_crs,
        phy_dv => eth_rx_dv,
        phy_rx_data => eth_rxd,
        phy_col => eth_col,
        phy_rx_er => eth_rxerr,
        phy_rst_n => eth_rstn,
        phy_tx_en => eth_tx_en,
        phy_tx_data => eth_txd,
       
        -- Interrupt output
        ip2intc_irpt  => ip2intc_irpt
    );
    
    pll: clk_wiz_0
     port map (
        clk_in1 => sys_clk,
        reset => '0',
        clk_out1 => axi_clk,
        clk_out2 => spi_clk,
        clk_out3 => psi_clk_pll,
        clk_out4 => s_eth_ref_clk
    );
    
    eth_ref_clk_out <= s_eth_ref_clk;
    
    SPI: SPI_interface
     port map (
        rst => reset,
        spi_start_i => spi_start,
        addr_i => "00110010",               -- pre-set address and data
        data_i => "1010011100100101001",
        spi_clk_i => spi_clk,
        spi_data_o => spi_data_DUT,
        spi_le_i => spi_le_DUT
    );
    
    D:  DUT port map(
        rst => reset,
        spi_clk_i => spi_clk, 
        psi_clk_o => psi_clk_pll,
        spi_start_i => spi_start,
        spi_data_i => spi_data_DUT,
        spi_le_i => spi_le_DUT,
        curr_state => curr_state,
        startPSI => start_psi_DUT,
        matlab_i => matlab);
        
    matlab_file_process: process(psi_clk_pll)
    
        begin
        if(falling_edge(psi_clk_pll)) then
            if reset = '1' then
                skip <= '0';
                table_index <= 0;
                direction <= '0';
                sign <= '0';
                cycle_count <= 0;
                bit_counter <= 15;  -- Start from MSB (15) to scan numbers correctly
                test_completed <= '0';
            else
                if(start_psi_DUT = '1' and skip = '0') then
                    startPSI <= '1';
                    skip <= '1';
                end if;
                
                if(start_psi_DUT = '1' and test_completed = '0') then
                    -- generate sine wave bit
                    if direction = '0' then
                        -- forward reading
                       matlab <= sine_table(table_index)(bit_counter) xor sign;
                       if bit_counter = 0 then 
                            bit_counter <= 15; 
                            if table_index = 63 then
                                direction <= '1';
                                table_index <= 62;
                            else
                                table_index <= table_index + 1;
                            end if;
                        else
                            bit_counter <= bit_counter - 1;
                        end if;
                    else
                        -- reverse reading
                        matlab <= sine_table(table_index)(bit_counter) xor sign;
                        if bit_counter = 0 then 
                            bit_counter <= 15;
                            if table_index = 0 then
                                direction <= '0';
                                if sign = '0' then
                                    sign <= '1';
                                else
                                    sign <= '0';
                                    cycle_count <= cycle_count + 1;
                                end if;
                            else
                                table_index <= table_index - 1;
                            end if;
                        else
                            bit_counter <= bit_counter - 1;
                        end if;
                    end if;
    
                    -- stop after 4 complete cycles
                    if cycle_count >= 4 then
                        -- set test as completed and stop sending data
                        test_completed <= '1';
                        matlab <= '0';  -- ensure we send 0 after test completion
                        startPSI <= '0';
                    end if;
                elsif test_completed = '1' then
                    -- keep sending 0 after test completion
                    matlab <= '0';
                end if;
            end if;
        end if;
        end process;
    
    spi_clk_o <= spi_clk;
    spi_data <= spi_data_DUT;
    spi_le <= spi_le_DUT;
    psi_data <= matlab;
    psi_clk <= psi_clk_pll;
    
   
end Behavioral;