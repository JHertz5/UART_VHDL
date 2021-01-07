-----------------------------------------------------------------------------------------------------------------------
-- Baud Rate Generator
-----------------------------------------------------------------------------------------------------------------------
-- Takes 8-bit value to set baud rate. Outputs a pulse every time one baud bit passes. Clock rate is 20 MHz and minimum
-- baud rate is 9600. Output baud rate is clock_rate/(16*(baud_rate_setting + 1)).
-----------------------------------------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

entity baud_rate_gen is
  port (
    clk_i           : in  std_logic;                    -- Clock In
    reset_i         : in  std_logic;                    -- Async Reset (actve high)
    baud_en_i       : in  std_logic;                    -- Baud Rate Generator Enable (active high)
    rx_rate_i       : in  std_logic;                    -- Run at 16x rate for data recovery
    baud_rate_set_i : in  std_logic_vector(7 downto 0); -- Baud rate setting
    baud_pulse_o    : out std_logic                     -- Baud Rate Pulse Out
  );
end entity baud_rate_gen;

architecture rtl of baud_rate_gen is

  -- Signal Declarations
  signal baud_rate_set_int : natural;
  signal baud_rate_cnt     : natural;
  signal rate_multiplier   : natural;

begin

  baud_rate_set_int <= to_integer(unsigned(baud_rate_set_i));

  rate_multiplier <= 1 when rx_rate_i = '1' else
                     16;

  proc_baud_rate_gen : process(clk_i) is
  begin
    if reset_i = '1' then
      baud_rate_cnt <= rate_multiplier * (baud_rate_set_int + 1);
      baud_pulse_o  <= '0';
    elsif rising_edge(clk_i) then

      if baud_en_i = '1' then
        baud_rate_cnt <= baud_rate_cnt - 1;
        baud_pulse_o  <= '0';

        -- When baud counter reaches 1, set pulse high and reset counter
        if baud_rate_cnt = 1 then
         baud_rate_cnt <= rate_multiplier * (baud_rate_set_int + 1);
         baud_pulse_o  <= '1';
        end if;
      else
        -- If not enabled, reset counter and set output to 0
        baud_rate_cnt <= rate_multiplier * (baud_rate_set_int + 1);
        baud_pulse_o  <= '0';
      end if;
    end if;
    
  end process proc_baud_rate_gen;
end architecture;