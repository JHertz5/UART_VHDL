-----------------------------------------------------------------------------------------------------------------------
-- UART Transmitter
-----------------------------------------------------------------------------------------------------------------------
-- Takes byte of data through parallel input, with optional 9th bit, and
-- transmits over serial data output.
-----------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
library work;

entity uart_tx is
  port (
    clk_i           : in  std_logic;                    -- Clock In
    reset_i         : in  std_logic;                    -- Async Reset (actve high)
    data_write_en_i : in  std_logic;                    -- Data In Write Enable (active high)
    data_par_i      : in  std_logic_vector(7 downto 0); -- Data Parallel In
    data_bit9_i     : in  std_logic;                    -- Data Bit 9 In (optional)
    config_i        : in  std_logic_vector(4 downto 0); -- Config Register
    status_o        : out std_logic_vector(1 downto 0); -- Status Register
    data_ser_o      : out std_logic                     -- Data Serial Out
  );
end entity uart_tx;

architecture rtl of uart_tx is

begin

  -- Framing Error if stop bit is 0

  -- Baud Rate Generator. Generates a pulse to mark the beginning of a new bit at the configured baud rate.
  cmp_baud_rate_gen : entity work.baud_rate_gen(rtl)
    port map(
      clk_i           => clk_i,
      reset_i         => reset_i,
      baud_en_i       => baud_en,
      baud_rate_set_i => x"14", -- TODO test/implement variable baud rate
      baud_pulse_o    => baud_pulse
    );

  -- Data recovery via 16x shift reg. If start bit lasts > 1/2 baud bit, it is counted as a start bit.
  -- Read centre of incoming bits.
  -- Double buffer output to allow reading to occur while receiving is ongoing.
end architecture;