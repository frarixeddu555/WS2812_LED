# WS2812_LED
Driving a single RGB LED WS2812 with an FPGA using VHDL

# Tools and devices
- FPGA Spartan 3 XCS400-4FT256 (50 MHz)
- LED RGB WS2812
- Oscilloscope Tektronix TDS1001B
- ISE Xilinx


# Main input-features
The input **color** signal can be provided with 4 different modules:
- Driving the LED by 3 switches (deconding 24 bit with 3bit);
- Driving the brightness of one single LED's color with 8 switches (to unlock the 256 brightness levels for one color);
- Fading one single LED's color;
- Fading all the LED's colors in sequence.

Some parts of the vhdl code are commented: you must comment or decomment one of these to unlock the input-feature you want.

# RTL Schematic
Here the RTL schematic of the main project.

The signal **color** is the sole vector signal (color is a [23:0] signal).

The darker signals are **input** and **output** signals.

Here is represented the main schematic to wich the other modules I described earlier can be hooked up to **color** signal to drive the LED in different ways.

![alt text](https://github.com/frarixeddu555/WS2812_LED/blob/main/main_schematic_data_to_LED.png)


# Finite state machine (FSM)
Here the FSM that provides the handy signals to realize the protocol used by the WS2812 to receive the 24bit datas. 
In red on the right, there are the FSM's outputs for each state.

![alt text](https://github.com/frarixeddu555/WS2812_LED/blob/main/TX_WS2812_finite_state_machine.jpg).


# s_out timing
Here the timing produced by the code for a period of T = 1.25 us + 0.1 us for 1 bit transmitted

|    s_out    |    time (ISE testbench) |  time (by oscilloscope)  |
|-------------|-------------------------|--------------------------|
| TH1 (UP1)   |    0.80 us              |          0.81 us         |
| TL1 (DOWN1) |    0.50 us              |          0.46 us         |
| TH0 (UP0)   |    0.36 us              |          0.37 us         |
| TL0 (DOWN0) |    0.94 us              |          0.91 us         |
| RST_TIME    |    20.02 us             |          20.8 us         |  

