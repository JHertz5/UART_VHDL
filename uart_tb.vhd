-----------------------------------------------------------------------------------------------------------------------
-- UART Transmitter Testbench
-----------------------------------------------------------------------------------------------------------------------
-- Takes byte of data through parallel input, with optional 9th bit, and
-- transmits over serial data output.
-----------------------------------------------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
library work;
use std.env.finish;

entity uart_tb is
end entity uart_tb;

architecture rtl of uart_tb is

    -- Constant Declarations
    constant c_CLK_PERIOD_20MHZ : time := 50 ns;

    -- Type Declarations
    type t_uart_tx is record
        data_write_en : std_logic;
        data_par      : std_logic_vector(7 downto 0);
        data_bit9     : std_logic;
        config        : std_logic_vector(4 downto 0);
        status        : std_logic_vector(1 downto 0);
        data_ser      : std_logic;
    end record t_uart_tx;

    -- Signal Declarations
    signal clk     : std_logic;
    signal reset   : std_logic;
    signal uart_tx : t_uart_tx;

begin


    proc_clk_gen : process is
    begin
        loop
            clk <= '0';
            wait for c_CLK_PERIOD_20MHZ/2;
            clk <= '1';
            wait for c_CLK_PERIOD_20MHZ/2;
        end loop;
    end process proc_clk_gen;

    -- UART Tx Instantiaion
    cmp_uart_tx : entity work.uart_tx(rtl)
    port map(
        clk_i           => clk,
        reset_i         => reset,
        data_write_en_i => uart_tx.data_write_en,
        data_par_i      => uart_tx.data_par,
        data_bit9_i     => uart_tx.data_bit9,
        config_i        => uart_tx.config,
        status_o        => uart_tx.status,
        data_ser_o      => uart_tx.data_ser
    );

    proc_test_sequence : process is
    begin
        reset <= '1';
        uart_tx.data_write_en <= '0';
        uart_tx.data_par <= (others => '0');
        uart_tx.data_bit9 <= '0';
        uart_tx.config <= b"00000";
        wait for c_CLK_PERIOD_20MHZ;

        reset <= '0';
        wait for c_CLK_PERIOD_20MHZ;

        uart_tx.data_par <= x"55";
        uart_tx.data_write_en <= '1';
        uart_tx.config <= b"00011";

        wait for c_CLK_PERIOD_20MHZ;
        uart_tx.data_par <= x"00";
        uart_tx.data_write_en <= '0';


        wait for 10000 * c_CLK_PERIOD_20MHZ;
        report "Test";
        finish;
    end process proc_test_sequence;

end architecture;
