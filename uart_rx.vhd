-----------------------------------------------------------------------------------------------------------------------
-- UART Transmitter
-----------------------------------------------------------------------------------------------------------------------
-- Receives UART packets and translates them in to full byte of data with, with optional 9th bit.
-----------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
library uart_pkg;
  use uart_pkg.uart_pkg.all;
library work;

entity uart_rx is
  port (
    clk_i           : in  std_logic;                    -- Clock In
    reset_i         : in  std_logic;                    -- Async Reset (actve high)
    data_ser_i      : in  std_logic;                     -- Data Serial In
    config_i        : in  std_logic_vector(4 downto 0); -- Config Register
    status_o        : out std_logic_vector(1 downto 0); -- Status Register
    data_par_o      : out std_logic_vector(7 downto 0); -- Data Parallel Out
    data_bit9_i     : out std_logic;                    -- Data Bit 9 Out (optional)
    data_valid_i    : out std_logic                     -- Data Output Valid
  );
end entity uart_rx;

architecture rtl of uart_rx is

  type t_rx_shift_reg is record
    data      : std_logic_vector(7 downto 0);
    shift_en  : std_logic;
    shift_cnt : natural;
    full      : std_logic;
  end record t_rx_shift_reg;

  -- Signal Declarations

  -- Baud rate generator signals
  signal baud_en               : std_logic;
  signal baud_pulse            : std_logic;
  -- Data recovery shift
  signal data_recovery_shift_reg : std_logic_vector(7 downto 0);
  -- Generic config signals
  signal rx_2_stop_bits        : std_logic;
  signal serial_en             : std_logic;
  signal rx_en                 : std_logic;

begin


  -- Baud Rate Generator. Generates a pulse to mark the beginning of a new bit at the configured baud rate.
  cmp_baud_rate_gen : entity work.baud_rate_gen(rtl)
    generic map(
      g_DATA_RECOVERY => '1'
    )
    port map(
      clk_i           => clk_i,
      reset_i         => reset_i,
      baud_en_i       => baud_en,
      baud_rate_set_i => x"14", -- TODO test/implement variable baud rate
      baud_pulse_o    => baud_pulse
    );

    proc_data_recovery_shift_reg : process(clk_i, reset_i) is
    begin
      if reset_i = '1' then

      elsif rising_edge(clk_i) then

      end if;
    end process proc_data_recovery_shift_reg;

  -- Framing Error if stop bit is 0
  -- Data recovery via 16x shift reg. If start bit lasts > 1/2 baud bit, it is counted as a start bit.
  -- Read centre of incoming bits. Start counter halfway through start bit.
  -- Double buffer output to allow reading to occur while receiving is ongoing.
end architecture;