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

  -- Type Declarations
  type t_tx_data_buffer is record
    data_byte   : std_logic_vector(7 downto 0);
    bit9        : std_logic;
    bit9_en     : std_logic;
    bit9_config : std_logic;
    write_en    : std_logic;
    empty       : std_logic;
  end record t_tx_data_buffer;
  type t_tx_shift_reg is record
    data      : std_logic_vector(7 downto 0);
    shift_en  : std_logic;
    shift_cnt : natural;
    empty     : std_logic;
  end record t_tx_shift_reg;
  type t_tx_state is (s_IDLE, s_START, s_DATA_BYTE, s_BIT9, s_STOP, s_2STOP);

  -- Constant Declarations
  -- Value of start and stop bits
  constant c_SERIAL_OUT_IDLE  : std_logic := '1';
  constant c_SERIAL_OUT_START : std_logic := '0';
  constant c_SERIAL_OUT_STOP  : std_logic := '1';

  -- Signal Declarations

  -- Baud Rate Generator signals
  signal baud_en               : std_logic;
  signal baud_pulse            : std_logic;
  -- Transmit data buffer signals
  signal tx_data_buffer        : t_tx_data_buffer;
  signal data_write_en_q1      : std_logic;
  signal tx_shift_reg_empty_q1 : std_logic;
  -- Transmit shift register signals
  signal tx_shift_reg          : t_tx_shift_reg;
  -- Transmit control state machine signals
  signal tx_state              : t_tx_state;
  signal next_state            : t_tx_state;
  signal data_ser              : std_logic;
  -- Generic config signals
  signal tx_2_stop_bits        : std_logic;
  signal serial_en             : std_logic;
  signal tx_en                 : std_logic;

begin

  -- config_i mapping:
  tx_2_stop_bits             <= config_i(4); -- 2 Stop Bit Enable (1 = 2 stop bits, 0 = 1 stop bit)
  tx_data_buffer.bit9_config <= config_i(3); -- Bit 9 Config (1 = parity bit, 0 = data bit)
  tx_data_buffer.bit9_en     <= config_i(2); -- Bit 9 Enable
  serial_en                  <= config_i(1); -- Serial Port Enable (SPEN)
  tx_en                      <= config_i(0); -- Transmit Enable (TXEN)

  -- status_o mapping:
  status_o <= (
    1 => tx_shift_reg.empty,  -- Transmit Shift Reg is empty (TRMT)
    0 => tx_data_buffer.empty -- Transmit Buffer Reg is empty (TXIF)
  );

  -- Baud Rate Generator. Generates a pulse to mark the beginning of a new bit at the configured baud rate.
  cmp_baud_rate_gen : entity work.baud_rate_gen(rtl)
    port map(
      clk_i           => clk_i,
      reset_i         => reset_i,
      baud_en_i       => baud_en,
      rx_rate_i       => '0',
      baud_rate_set_i => x"14", -- TODO test/implement variable baud rate
      baud_pulse_o    => baud_pulse
    );

  -- Buffer holds data to be transmitted. When the write enable is high, load data in
  -- to buffer. Once the data has been written, i.e. the write enable has returned to low, and the transmit shift register is
  -- empty, the buffer is emptied in to transmit shift register. empty is set low when buffer is filled and
  -- high when buffer is emptied.
  proc_tx_buffer : process(clk_i, reset_i) is
  begin
    if reset_i = '1' then
      tx_data_buffer.data_byte <= (others => '0');
      tx_data_buffer.bit9      <= '0';
      tx_data_buffer.empty     <= '1';
      data_write_en_q1         <= '0';
      tx_shift_reg_empty_q1    <= '1';

    elsif rising_edge(clk_i) then
      -- Track edges of write enable to tell when write is complete, and shift register empty to tell when the
      -- shift register has loaded the buffer contents.
      data_write_en_q1      <= tx_data_buffer.write_en;
      tx_shift_reg_empty_q1 <= tx_shift_reg.empty;

      -- Empty flag is cleared on falling edge of write enable
      if tx_data_buffer.write_en = '0' and data_write_en_q1 = '1' then
        tx_data_buffer.empty <= '0';
      end if;

      if tx_data_buffer.write_en = '1' then
        -- Write byte buffer
        tx_data_buffer.data_byte <= data_par_i;
        
        -- Write bit9 buffer
        if tx_data_buffer.bit9_en = '1' then
          if tx_data_buffer.bit9_config = '1' then
            -- Write bit 9 buffer with parity of data byte
            tx_data_buffer.bit9 <= xor data_par_i;
          else
            -- Write bit 9 buffer with bit 9 data
            tx_data_buffer.bit9 <= data_bit9_i;
          end if;
        end if;
  
      elsif tx_shift_reg.empty = '0' and tx_shift_reg_empty_q1 = '1' then
        -- Empty buffer when shift reg has been loaded
        tx_data_buffer.empty     <= '1';
        tx_data_buffer.data_byte <= (others => '0');
      end if;
      
    end if;
  end process proc_tx_buffer;

  tx_data_buffer.write_en <= data_write_en_i;

  -- Load data from data buffer. When transmission is enabled, shift bits out on every baud rate pulse. Set empty
  -- flag when emptied, clear empty flag when data is loaded in.
  proc_tx_shift_reg : process(clk_i, reset_i) is
  begin
    if reset_i = '1' then
      tx_shift_reg.data  <= (others => '0');
      tx_shift_reg.empty <= '1';
    elsif rising_edge(clk_i) then

      if tx_data_buffer.empty = '0' and tx_shift_reg.empty = '1' then
      -- Load data
        tx_shift_reg.data      <= tx_data_buffer.data_byte;
        tx_shift_reg.empty     <= '0';
        tx_shift_reg.shift_cnt <= tx_shift_reg.data'length-1;
      elsif tx_shift_reg.shift_en = '1' and baud_pulse = '1' then
      -- Shift data
        tx_shift_reg.data      <= '0' & tx_shift_reg.data(tx_shift_reg.data'left downto tx_shift_reg.data'right+1);
        tx_shift_reg.shift_cnt <= tx_shift_reg.shift_cnt - 1;
        if tx_shift_reg.shift_cnt = 1 then
        -- When last bit is shifted out, set empty flag
          tx_shift_reg.empty <= '1';
        end if;
      end if;

    end if;
  end process proc_tx_shift_reg;

  -- State machine controls serial output. The states will set the start bit, shift out data bits, set the 9th data
  -- bit, set the parity bit, and set the stop bit.
  proc_tx_control_next_state : process(all) is
  begin
    case tx_state is

      when s_IDLE =>
        data_ser              <= c_SERIAL_OUT_IDLE;
        baud_en               <= '0';
        tx_shift_reg.shift_en <= '0';
        -- Transmission starts when the data buffer is not empty and transmission is enabled.
        if tx_data_buffer.empty = '0' and tx_en = '1' then
          next_state <= s_START;
        end if;

      when s_START =>
        data_ser <= c_SERIAL_OUT_START;
        baud_en  <= '1';
        if baud_pulse = '1' then
          next_state <= s_DATA_BYTE;
        end if;

      when s_DATA_BYTE =>
        data_ser              <= tx_shift_reg.data(0);
        tx_shift_reg.shift_en <= '1';
        if baud_pulse = '1' then
          if tx_shift_reg.shift_cnt = 0 then
            tx_shift_reg.shift_en <= '0';
            if tx_data_buffer.bit9_en = '1' then
              next_state <= s_BIT9;
            else
              next_state <= s_STOP;
            end if;
          end if;
        end if;

      when s_BIT9 =>
        data_ser <= tx_data_buffer.bit9;
        if baud_pulse = '1' then
          next_state <= s_STOP;
        end if;

      when s_STOP =>
        data_ser <= c_SERIAL_OUT_STOP;
        if baud_pulse = '1' then
          if tx_2_stop_bits = '0' then
            -- If last bit, prepare for the end of the packet
            if tx_shift_reg.empty = '1' then
              next_state <= s_IDLE;
            else
              next_state <= s_START;
            end if;
          else
            next_state <= s_2STOP;
          end if;
        end if;

      when s_2STOP =>
        data_ser   <= c_SERIAL_OUT_STOP;
        if baud_pulse = '1' then
          -- Prepare for the end of the packet
          if tx_shift_reg.empty = '1' then
            next_state <= s_IDLE;
          else
            next_state <= s_START;
          end if;
        end if;

      when others =>
        next_state <= s_IDLE;

    end case;
  end process proc_tx_control_next_state;

  -- Synchronously update the state of the transmit state machine
  proc_tx_control_current_state : process(clk_i, reset_i) is
  begin
    if reset_i = '1' then
      tx_state <= s_IDLE;
    elsif rising_edge(clk_i) then
      tx_state <= next_state;
    end if;
  end process proc_tx_control_current_state;

  -- Set serial output to serial data if serial output is enabled
  data_ser_o <= data_ser and serial_en;

end architecture;
