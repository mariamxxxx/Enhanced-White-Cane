# Enhanced White Cane

## Project Overview
The Enhanced White Cane (code name `WalkingStick`) is an FPGA-based assistive device for people with visual impairments. It combines obstacle sensing, drop detection, tactile and audible feedback, and a status-oriented user interface. The design targets Intel MAX 10 development boards (e.g., DE10-Lite) and integrates infrared sensors, vibration motors, touch sensors, buzzers, and a 7-segment time display into a single deterministic hardware platform.

## Key Capabilities
- `ON/OFF` master switch enables or disables every downstream module and drives the status LED.
- IR obstacle sensor feeds a vibration motor (and optional warning LED) whenever an object is detected within range.
- Touch/drop sensor triggers a self-resetting buzzer plus blinking drop LED to locate the cane if it slips from the user’s hand.
- Shared clock divider generates a human-visible blink signal (~0.75 Hz) reused by the warning indicators and by the 7-segment multiplex timing.
- Seven-segment display shows minutes and seconds derived from a cascaded BCD counter so the user knows how long the cane has been active.
- Modular VHDL architecture allows independent verification of each feature and straightforward reuse in other assistive devices.

## Hardware Platform and Bill of Materials
| Category | Component | Notes |
| --- | --- | --- |
| FPGA board | Intel MAX 10 (DE10-Lite) | Provides `MAX10_CLK1_50`, GPIO headers, 7-segment display, LEDs, and power rails. |
| Obstacle sensor | IR proximity module (digital output) | Active-low output tied to `ir_sensor_W`. Range tuned to ~1 m. |
| Drop/touch sensor | Capacitive or metal touch plate | Active-low output (touch released = `0`). |
| Haptics | 3 V vibration motor with MOSFET driver | Driven by `vibration_W`. |
| Audio | 5 V piezo buzzer with transistor driver | Driven by `buzzer_W`. |
| Indicators | Status LED, drop LED, optional warning LED | Status LED mirrors master switch; drop LED blinks via `blink_sig`. |
| Power | 5 V supply shared between board and peripherals | Motors and buzzers are isolated with transistors and flyback diodes. |

## Repository Layout
| File | Purpose |
| --- | --- |
| `WalkingStick.vhd` | Top-level structural netlist wiring every module together. |
| `clock_divider.vhd` | Generates the shared blink/multiplex signal from the 50 MHz system clock. |
| `obstacle.vhd` | Combinational logic that asserts the vibration output while an obstacle is detected. |
| `drop_detector.vhd` | Drives the beeper and drop LED whenever the cane is released. |
| `WalkingStick.qpf/.qsf` | Quartus Prime project and pin assignments for MAX 10 targets. |
| `simulation/` | Placeholder for testbenches (add your own waveform-based tests here). |

## Architectural Overview
```
	 +-----------------+         +----------------+
	 | clock_divider  |----blink|                |
	 | 50 MHz -> 0.75 |         | WalkingStick   |
	 +----------------+         | top-level      |
				 ^                 |                |
				 |                 |  +----------+  |--> vibration motor
50 MHz input |                 |  | obstacle |--|
				 |                 |  +----------+  |
				 |                 |  +--------------|--> buzzer
				 |                 |  | drop_detect |--|--> drop LED
				 |                 |  +--------------|
				 |                 |  +--------------|--> 7-seg display
				 |                 |  | time_ctr/mux |--|
				 v                 +----------------+
```

The master switch (`switch_W`) feeds every process. When the switch is low the cane is effectively in deep sleep: outputs are forced low, the status LED is off, and downstream actuators idle. Once the switch turns on, the clock divider creates a slow square wave ($f_{blink} = \frac{50\,\text{MHz}}{2^{26}} \approx 0.75\,\text{Hz}$) that doubles as a blink source and as a multiplex tick for the 7-segment module.

### Module Responsibilities
- **`clock_divider`**: Counts every rising edge of the 50 MHz oscillator and exposes bit 25 as `blink_sig`. This bit changes state roughly every 0.67 s, giving a comfortable blink cadence.
- **`obstacle`**: Monitors `ir_sensor_W`. When the sensor reports logic-low (obstacle present) and the cane is armed, `vibration_W` is forced high. An optional warning LED can be tied to the same block (currently commented in the code).
- **`drop_detector`**: Watches `touch_W`. If the cane loses contact (`0`), it engages the buzzer continuously and toggles `led_drop_W` with the shared blink so that the cane is both audible and visible on the ground.
- **`time_counter + 7-seg multiplexer`**: Maintains minutes and seconds using cascaded BCD counters and refreshes the four HEX displays on the MAX 10 board at >1 kHz. This logic shares the clock-divider output for blink effects while using the raw 50 MHz clock for accurate timing.
- **`WalkingStick`** top level: Routes the signals, exposes board pins, and mirrors the master switch onto `status_led_W` so users can confirm the cane is armed.

### Signal Map
| Port | Direction | Connected Device | Description |
| --- | --- | --- | --- |
| `MAX10_CLK1_50` | in | Board oscillator | Drives all synchronous logic. |
| `switch_W` | in | Slide switch / push button | Global enable; also feeds status LED. |
| `ir_sensor_W` | in | IR obstacle sensor | Active-low on detection. |
| `touch_W` | in | Touch/drop sensor | Active-low when cane leaves the hand. |
| `status_led_W` | out | Green LED | Indicates cane armed state. |
| `vibration_W` | out | Motor driver | Alerts user to obstacles. |
| `buzzer_W` | out | Buzzer driver | Sounds alarm when cane is dropped. |
| `led_drop_W` | out | Red LED | Blinks while buzzer is active. |
| `HEX[3:0]` | out | 7-segment digits | Shows MM:SS runtime (declared inside the time-display block). |

## Build and Deployment
1. **Open Quartus Prime:** Use the same major version that created `WalkingStick.qpf` (Quartus Prime Lite for MAX 10).
2. **Load the project:** `File → Open Project → WalkingStick.qpf`.
3. **Verify pin assignments:** `Assignments → Pin Planner` to map the logical ports above to your board’s GPIO header or on-board LED/buzzer pins.
4. **Compile:** `Processing → Start Compilation`. Resolve any fitter warnings caused by custom pinouts.
5. **Program the FPGA:** Launch Programmer, select the MAX 10, add `WalkingStick.sof` from `output_files/`, then click *Start* with the board connected over USB-Blaster.
6. **Attach peripherals:** Wire the IR sensor, touch pad, motor driver, and buzzer through transistor buffers to the assigned pins. Ensure common ground and proper flyback diodes on inductive loads.

## Operating Scenarios
- **Inactive:** `switch_W = 0`. All actuators remain low, buzzer silent, LEDs off, timer halted.
- **Obstacle detected:** `switch_W = 1`, `ir_sensor_W = 0`. Vibration motor energizes immediately, providing haptic feedback. Optional warning LED can blink using `blink_sig`.
- **Cane dropped:** `switch_W = 1`, `touch_W = 0`. Buzzer sounds continuously, drop LED blinks, assisting the user in finding the cane.
- **Standard walking:** `switch_W = 1`, sensors idle. Status LED is solid, timer increments, and HEX display shows elapsed time in MM:SS.

## Testing and Validation
1. **Module simulation:** Use ModelSim/Questa to simulate `obstacle` and `drop_detector` with exhaustive sensor combinations to confirm outputs change without glitches.
2. **Clock divider introspection:** Inspect `blink_sig` in simulation to confirm duty cycle and period. In hardware, probe the pin with a logic analyzer.
3. **Hardware-in-the-loop:**
	- Place an object in front of the IR sensor to confirm vibration response.
	- Release the cane from the touch sensor to verify buzzer/LED behavior.
	- Compare the 7-seg timer against a stopwatch for at least 5 minutes to ensure drift <1 s.
4. **Environmental tests:** Evaluate in bright light and low light to characterize IR sensor reliability; adjust threshold potentiometer if necessary.

## Future Enhancements
- Add ultrasonic or stereo vision sensing for longer-range obstacle detection.
- Incorporate Bluetooth Low Energy to forward alerts to a caregiver’s phone.
- Add a rechargeable Li-ion battery pack and onboard charging IC with current sensing.
- Log usage duration via on-board flash and expose it over USB for analytics.
- Implement adaptive vibration patterns to represent obstacle distance or orientation.

## Acknowledgements
Developed by the Enhanced White Cane team for the Digital System Design course (Semester 5). Sensors and actuators were sourced from standard maker-friendly modules; HDL was authored in VHDL and synthesized with Quartus Prime Lite.