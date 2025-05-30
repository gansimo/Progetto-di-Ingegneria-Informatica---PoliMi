library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity AXI_interface_PSI is
generic ( packet_data_length : integer := 1400);
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
            startPSI : in std_logic;

            ip2intc_irpt  : in STD_LOGIC
        );
end AXI_interface_PSI;

architecture Behavioral of AXI_interface_PSI is

component fifo_generator_0 is
    PORT (
    wr_clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0');
    wr_en : IN STD_LOGIC := '0';
    rd_en : IN STD_LOGIC := '0';
    dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
end component;

type axi_state_t is (IDLE, WRITE_ADDR, WRITE_DATA, WRITE_RESP, READ_ADDR, READ_DATA, READ_COMPLETE);
signal axi_state : axi_state_t := IDLE;
signal curraddr : std_logic_vector(12 downto 0);
signal counter : integer := 0;

signal data_buf1 : std_logic_vector(31 downto 0) := (others => '0');
signal data_buf2 : std_logic_vector(31 downto 0) := (others => '0');
signal counter64 : integer := 0;

signal buffer1_ready : std_logic := '0';
signal buffer2_ready : std_logic := '0';
signal done : std_logic := '0';
signal interrupt: std_logic := '1';
signal ping_pong: std_logic := '0'; -- 0 -> ping, 1 -> pong
signal interrupt_ok: std_logic := '0';
signal reset_flag : std_logic := '0';


--fifo signals
signal din : std_logic_vector(31 downto 0);
signal wr_en : std_logic;
signal dout : std_logic_vector(31 downto 0);
signal rd_en : std_logic;
signal fifo_reset: std_logic;
signal empty : std_logic;
signal full: std_logic;

signal state: std_logic_vector(2 downto 0);
signal empty_counter : integer := 0;  -- Counter for empty FIFO cycles
signal last_pckt : std_logic;
signal started : std_logic;

signal ip2intc_irpt_s1    : std_logic := '0';
signal ip2intc_irpt_s2    : std_logic := '0'; -- signal ip2intc_irpt synchronized
signal ip2intc_irpt_pulse : std_logic := '0'; -- impulse of a clock cycle at the rising edge of ip2intc_irpt

signal pckt_len : std_logic_vector(15 downto 0);

begin

fifo_reset <= not s_axi_aresetn;

fifo: fifo_generator_0 
    port map(
        wr_clk => psi_clk_i,
        rd_clk => axi_clk_i,
        rst => fifo_reset,
        din => din,
        wr_en => wr_en,
        rd_en => rd_en,
        dout => dout,
        empty => empty,
        full => full
        ); 
        
sync_and_edge_detect_proc: process(axi_clk_i)
begin
    if rising_edge(axi_clk_i) then
        if s_axi_aresetn = '0' then -- reset active low
            ip2intc_irpt_s1    <= '0';
            ip2intc_irpt_s2    <= '0';
            ip2intc_irpt_pulse <= '0';
        else
            --  2 flip-flop synchronizer
            ip2intc_irpt_s1 <= ip2intc_irpt;
            ip2intc_irpt_s2 <= ip2intc_irpt_s1;

            --  ip2intc_irpt rising edge detector (impulse of 1 cycle)
            -- impulse happens when s1 (new value) is '1' and s2 (old value) was '0'.
            ip2intc_irpt_pulse <= ip2intc_irpt_s1 and not ip2intc_irpt_s2;
        end if;
    end if;
end process sync_and_edge_detect_proc;

axi_process: process(axi_clk_i, ip2intc_irpt)
    begin
        if rising_edge(axi_clk_i) then
            if s_axi_aresetn = '0' then
                axi_state <= IDLE;
                state <= "000";
                curraddr <= "0000000010000";
                counter <= 0;
                s_axi_bready <= '0';
                reset_flag <= '1';
                done <= '0';
                ping_pong <= '0';
                interrupt <= '1';
                last_pckt <= '0';
                rd_en <= '0';
                started <= '0';
                pckt_len <= std_logic_vector(to_unsigned(packet_data_length, 16));
                
            else
                if ip2intc_irpt_pulse = '1' then
                    interrupt <= '1'; -- internal interrupt flag
                end if;
                
                if start = '1' then
                    case axi_state is
                        when IDLE =>
                            -- default state, no transaction
                            s_axi_awvalid <= '0';
                            s_axi_wvalid <= '0';
                            s_axi_arvalid <= '0';
                            s_axi_rready <= '0';
                            
                            if s_axi_bvalid = '0' then
                                s_axi_bready <= '0';
                            end if;
   
                            if s_axi_bvalid = '0' or reset_flag = '1' then
                                reset_flag <= '0';
                                if counter < 11 then
                                    axi_state <= WRITE_ADDR;
                                    state <= "001";
                                elsif counter > 10 and counter <= (packet_data_length/4 + 10) and empty = '0' then
                                    started <= '1';
                                    rd_en <= '1';
                                    axi_state <= WRITE_ADDR;
                                    state <= "001";
                                    empty_counter <= 0;
                                elsif counter > 10 and counter <= (packet_data_length/4 + 10) and empty = '1' and last_pckt = '0' and started = '1' then
                                    empty_counter <= empty_counter + 1;
                                    if empty_counter >= 127 then  -- after 128 empty cycles
                                        counter <= (packet_data_length/4 + 11);
                                        empty_counter <= 0;
                                        last_pckt <= '1';
                                    end if;
                                elsif counter = (packet_data_length/4 + 11) and interrupt = '1' then
                                    axi_state <= WRITE_ADDR;
                                    state <= "001";
                                    interrupt <= '0';
                                elsif counter = (packet_data_length/4 + 12) then
                                    counter <= 11;
                                    ping_pong <= not ping_pong;
                                    if ping_pong = '0' then         --previous buffer used, it's a signal so the "not" isn't updated yet
                                        curraddr <= "0100000010000";
                                    else
                                        curraddr <= "0000000010000";
                                    end if;
                                end if;
                                done <= '0';
                            end if;
                           
                        when WRITE_ADDR =>
                            -- write address phase
                            
                            s_axi_awvalid <= '1';
                            
                            if counter = 0 then
                                s_axi_awaddr <= "0000000000000";
                                s_axi_wdata <= x"FFFFFFFF";     --First 4 Bytes of dest address
                            elsif counter = 1 then
                                s_axi_awaddr <= "0000000000100";
                                s_axi_wdata <= x"0000FFFF";     --Last 2 Bytes of dest address + First 2 Bytes of src address
                            elsif counter = 2 then
                                s_axi_awaddr <= "0000000001000";
                                s_axi_wdata <= x"CEFA005E";     --Last 4 Bytes of src address
                            elsif counter = 3 then
                                s_axi_awaddr <= "0000000001100";
                                s_axi_wdata <= std_logic_vector(to_unsigned(0, 32));   --std_logic_vector(to_unsigned(0, 16)) & pckt_len(7 downto 0) & pckt_len(15 downto 8);     --2 Bytes of lenght of data slot of packet
                                
                            elsif counter = 4 then
                                s_axi_awaddr <= "0100000000000";
                                s_axi_wdata <= x"FFFFFFFF";     --First 4 Bytes of source address
                            elsif counter = 5 then
                                s_axi_awaddr <= "0100000000100";
                                s_axi_wdata <= x"0000FFFF";     --Last 2 Bytes of source address + First 2 Bytes of dest address
                            elsif counter = 6 then
                                s_axi_awaddr <= "0100000001000";
                                s_axi_wdata <= x"CEFA005E";     --Last 4 Bytes of dest address
                            elsif counter = 7 then
                                s_axi_awaddr <= "0100000001100";
                                s_axi_wdata <= std_logic_vector(to_unsigned(0, 32)); --2 Bytes of lenght of data slot of packet    
                                
                            elsif counter = 8 then
                                s_axi_awaddr <= "0011111110100";
                                s_axi_wdata <= std_logic_vector(to_unsigned(packet_data_length + 16, 32));     --DATA + ADDRESSES BYTES(12B) + TYPE/LEN(2B) !!!!! ALL THE DATA WRITTEN INTO THE REGISTER!!!    
                            elsif counter = 9 then
                                s_axi_awaddr <= "0111111110100";
                                s_axi_wdata <= std_logic_vector(to_unsigned(packet_data_length + 16, 32));     --DATA + ADDRESSES BYTES(12B) + TYPE/LEN(2B) !!!!! ALL THE DATA WRITTEN INTO THE REGISTER!!!    
                            elsif counter = 10 then 
                                s_axi_awaddr <= "0011111111000";        --global interrupt
                                s_axi_wdata <= x"80000000";    
                            
                            elsif counter > 10 and counter <= (packet_data_length/4 + 10) then 
                                s_axi_awaddr <= curraddr;
                                s_axi_wdata <= dout(7 downto 0) & dout(15 downto 8) & dout(23 downto 16) & dout(31 downto 24);      --payload
                                rd_en <= '0';
                                done <= '1';
                                
                                
                            
                            elsif counter = (packet_data_length/4 + 11) then 
                                if ping_pong = '0' then
                                    s_axi_awaddr <= "0011111111100";
                                    s_axi_wdata <= x"00000009";
                                else
                                    s_axi_awaddr <= "0111111111100";
                                    s_axi_wdata <= x"00000001";
                                end if;
                                interrupt_ok <= '0';
                            end if;
                            
                            s_axi_wvalid <= '1';
                           
                           
                            if s_axi_awready = '1' and s_axi_wready = '1' then
                                s_axi_awvalid <= '0';
                                s_axi_wvalid <= '0';
                                axi_state <= WRITE_RESP;
                                state <= "011";
                            end if;
                           
                        when WRITE_RESP =>
                            -- write response phase
                            s_axi_bready <= '1';
                           
                            if s_axi_bvalid = '1' then
                                s_axi_awvalid <= '0';
                                s_axi_wvalid <= '0';
                                counter <= counter + 1;
                                axi_state <= IDLE;
                                state <= "000";
                                if counter > 10 then
                                    curraddr <= std_logic_vector(unsigned(curraddr) + 4);
                                end if;
                            end if;
                        when others => 
                        end case;
                    end if;
                end if;
        end if;
    end process;
    
    data: process(psi_clk_i)        --handles psi data coming from mock-up DUT. Data is written into the FIFO asynchronously to reading phase
        variable skip : std_logic;
        begin
            if rising_edge(psi_clk_i) then
                if s_axi_aresetn = '0' then
                    counter64 <= 0;
                    buffer1_ready <= '0';
                    buffer2_ready <= '0';
                    wr_en <= '0';
                    din <= (others => '0');
                    skip := '1';
                elsif startPSI = '1' then
                    if skip = '0' then
                        skip := '1';
                   
                    elsif counter64 < 32 then
                        wr_en <= '0';
                        data_buf1(31 - counter64) <= psi_data_i;
                        buffer1_ready <= '0';
                        counter64 <= counter64 + 1;
                        if counter64 = 31 then
                            data_buf2 <= (others => '1');
                            buffer1_ready <= '1';
                            din <= data_buf1;
                            wr_en <= '1';
                        end if;
                    elsif counter64 < 64 then
                        wr_en <= '0';
                        data_buf2(31 - (counter64 - 32)) <= psi_data_i;
                        buffer2_ready <= '0';
                        counter64 <= counter64 + 1;
                        if counter64 = 63 then
                            data_buf1 <= (others => '1');
                            counter64 <= 0;
                            buffer2_ready <= '1';
                            din <= data_buf2;
                            wr_en <= '1';
                        end if;
                    end if;
                    
                    if done = '1' then
                        buffer1_ready <= '0';
                        buffer2_ready <= '0';
                    end if;
                else 
                    wr_en <= '0';  --comment to activate freerun!
                end if;
            end if;
        end process; 
end Behavioral;