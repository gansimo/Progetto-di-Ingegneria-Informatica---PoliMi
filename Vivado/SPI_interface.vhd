library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use STD.TEXTIO.ALL;
use ieee.numeric_std.all;

entity SPI_interface is

generic(
            nb_spi_addr : integer := 8;
            nb_spi_data : integer := 19);
port(
    rst             : in std_logic;

    spi_start_i     : in std_logic := '0';
    
    addr_i          : in std_logic_vector(7 downto 0) := "00110010";
    data_i          : in std_logic_vector(18 downto 0) := "1010011100100101001";
    
    spi_clk_i       : in std_logic;
    spi_data_o      : out std_logic := '0';
    spi_le_i        : out std_logic := '0'
    );
end SPI_interface;

architecture RTL of SPI_interface is

signal bit_index : integer := 0;
signal flag : std_logic := '0';

begin
    
    ioINTERFACE_spi: process(spi_clk_i)     --forwards the spi data to the mock-up DUT
        begin
            if(rising_edge(spi_clk_i)) then
                if(rst = '1') then
                    bit_index <= 0;
                    flag <= '0';
                    spi_le_i <= '0';
                    spi_data_o <= '0';
                elsif spi_start_i = '1' then
                    if(bit_index < nb_spi_addr) then
                        spi_data_o <= addr_i(bit_index);
                        bit_index <= bit_index + 1;
                    elsif(bit_index < nb_spi_addr + nb_spi_data) then
                        spi_data_o <= data_i(bit_index - nb_spi_addr);
                        bit_index <= bit_index + 1;
                    else    
                        spi_le_i <= '1';
                        spi_data_o <= '0';
                        flag <= '1';
                    end if;
                    if(flag = '1') then
                        spi_data_o <= '0';
                    end if;
                end if;
            end if;
        end process;
               

end RTL;
