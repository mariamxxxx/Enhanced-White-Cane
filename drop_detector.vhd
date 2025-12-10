library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity drop_detector is
    Port (
        system_on : in  STD_LOGIC;
        touch     : in  STD_LOGIC;
        blink     : in  STD_LOGIC;
        buzzer    : out STD_LOGIC;
        led_drop  : out STD_LOGIC
    );
end drop_detector;

architecture Behavioral of drop_detector is
begin

    process(system_on, touch, blink)
    begin
        if system_on = '1' and touch = '0' then
            buzzer   <= '1';
            led_drop <= blink;
        else
            buzzer   <= '0';
            led_drop <= '0';
        end if;
    end process;

end Behavioral;