library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use STD.TEXTIO.ALL;
use IEEE.NUMERIC_STD.ALL;


entity DUT is



generic( 
            nb_psi_word : integer :=  72;
            n_psi_chunk : integer := 16384;
            en_psi_freerun : bit := '0';
            nb_spi_addr : integer := 8;
            nb_spi_data : integer := 19);
port(       
            rst                 :   in std_logic;
            
            spi_clk_i           :   in std_logic;
            spi_data_i          :   in std_logic;
            spi_le_i            :   in std_logic;
            
            addr_o              :   out integer := 0;
            data_o              :   out integer := 0;
            spi_start_i         :   in std_logic;
            
            curr_state          :   out integer := 0;       --to talk with tb
            matlab_i            :   in std_logic;           --to talk with tb
            
            startPSI            :   out std_logic;
            
            psi_clk_o           :   in std_logic;
            psi_data_o          :   out std_logic := '0';
            psi_we_o            :   out std_logic := '0';
            psi_rdyn_o          :   out std_logic := '0');

end DUT;



architecture Behavioral of DUT is

type state_type is (IDLE, SEND_BITS, WORD_END, CHUNK_END);
signal state : state_type := IDLE;

signal reg : std_logic_vector((nb_spi_addr+nb_spi_data-1) downto 0);

signal start_psi : std_logic := '0';

signal bit_index : integer := 0;

begin

DUT_psi_process : process(psi_clk_o)                      
    begin
    if(rising_edge(psi_clk_o)) then 
            if(rst = '1') then
                state <= IDLE;
                psi_we_o <= '0';
                psi_rdyn_o <= '0';
                curr_state <= 0;
                
            else
                if(start_psi = '1') then 
                    case state is
                        when IDLE =>           
                            psi_we_o <= '0';
                            state <= SEND_BITS;
                            curr_state <= 1;
                            
                        when SEND_BITS => 
                            --used for test to trigger the psi data process in the TOP entity
                        when others =>  
                    end case;
                elsif(start_psi = '0') then 
                    curr_state <= 0;
                end if;   
        end if;
     end if;           
end process;

DUT_spi_process : process(spi_clk_i, spi_le_i)
    variable nb_tot : integer := nb_spi_addr + nb_spi_data;
    begin
        if(falling_edge(spi_clk_i)) then
            if(rst = '1') then
                    bit_index <= 0;
                    reg <= (others => '0');
                    addr_o <= 0;
                    data_o <= 0;
                    start_psi <= '0';
            else        
                if (spi_start_i = '1') then
                    if(bit_index < (nb_spi_data + nb_spi_addr) ) then
                                reg(bit_index) <= spi_data_i;
                                bit_index <= bit_index + 1;
                    end if;
                    if(spi_le_i = '1') then
                        addr_o <= to_integer(unsigned(reg(nb_spi_addr-1 downto 0)));
                        data_o <= to_integer(unsigned(reg(nb_tot-1 downto nb_spi_addr)));
                        if(to_integer(unsigned(reg(nb_spi_addr-1 downto 0))) = 50) then
                            start_psi <= '1';       --triggers the PSI started signal in the top entity
                        end if;
                    end if;
                end if;
            end if;
        end if; 
    end process;

    startPSI <= start_psi;

end Behavioral;
