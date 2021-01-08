-----------------------------------------------------------------------------------------------------------------------
-- UART Package
-----------------------------------------------------------------------------------------------------------------------
-- Package of constants for UART code
-----------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;

package uart_pkg is

  -- Constant Declarations

  -- Ratio of data recovery rate to baud rate
  constant c_DATA_RECOVERY_RATIO : natural := 16;

  -- Value of start and stop bits
  constant c_SERIAL_OUT_IDLE  : std_logic := '1';
  constant c_SERIAL_OUT_START : std_logic := '0';
  constant c_SERIAL_OUT_STOP  : std_logic := '1';
end uart_pkg;