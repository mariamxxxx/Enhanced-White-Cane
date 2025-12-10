library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity WalkingStick is
    Port (
        MAX10_CLK1_50 : in  STD_LOGIC;

        switch_W           : in  STD_LOGIC;

        ir_sensor_W       : in  STD_LOGIC;  -- IR sensor
        touch_W        : in  STD_LOGIC;  -- Touch sensor

       -- LEDR0         : out STD_LOGIC;  -- Warning LED
			led_drop_W         : out STD_LOGIC;  -- Drop LED
			status_led_W	      : out STD_LOGIC;  -- status LED

			vibration_W        : out STD_LOGIC;  -- Vibration 
			buzzer_W        : out STD_LOGIC  -- Buzzer 
    );
end WalkingStick;

architecture Structural of WalkingStick is

    signal blink_sig : STD_LOGIC;

begin
  	status_led_W <= switch_W;
    -- Clock divider
    CDIV : entity work.clock_divider
        port map (
            clk   => MAX10_CLK1_50,
            blink => blink_sig
        );

    -- Obstacle Module
    OBS : entity work.obstacle
        port map (
            system_on   => switch_W,
            ir_sensor   => ir_sensor_W,
            blink       => blink_sig,
            vibration   => vibration_W
            --led_warning => LEDR0
        );

    -- Drop Detector
    DROP : entity work.drop_detector
        port map (
            system_on => switch_W,
            touch     => touch_W,
            blink     => blink_sig,
            buzzer    => buzzer_W,
            led_drop  => led_drop_W
        );

end Structural;