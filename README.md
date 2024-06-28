# WS2812_LED
Trying to drive a single RGB LED WS2812 with an FPGA using VHDL


# Tools and devices
- FPGA Spartan 3 XCS400-4FT256 (50 MHz)
- LED RGB WS2812
- Oscilloscope Tektronix TDS1001B
- ISE Xilinx


# RTL Schematic

Here the RTL schematic of the project.
All signals are 1 bit signal less **color** that is a 24 bit signal (in order to drive just one LED).

![alt text](https://github.com/frarixeddu555/WS2812_LED/blob/main/TX_WS2812_schematic.jpg)


# Finite state machine (FSM)
There are **two trial version** of this FSM: 
- one changes the color of the LED though changes in the state of the **switch** signal.
- other uses a **btn** signal to light up the LED of the color indicated by the **switch** signal at that moment (_the commented part in the code_);

In red on the right, there are the FSM's outputs for each state.

![alt text](https://github.com/frarixeddu555/WS2812_LED/blob/main/TX_WS2812_finite_state_machine.jpg)


# Issues
Disclaimer: all my considerations concern the trial without btn signal input.

As far as concerned timing requirements, coding a "1" or "0" with high and low pulses seems work fine. 
I attached some oscilloscope's photos in the folder "Oscilloscope output" if you want to check it out.

Anyway WS2812 doesn't work. It doesn't light on neither driving FPGA's switches nor with reset button. I attached constraints file.

LED respond only if I desconnect and reconnect the **Data_in** cable (**s_out** in the code). At the exactly contact moment, the LED gets a color. But still remain insensitive to switch or reset signals changes. To assign it another color you have to desconnect e reconnect again.

What if I measure signal with the oscilloscope while wires from FPGA are hooked up at the LED? If I leave oscilloscope's ground connected to the GND signal, same behavior of before. If I desconnect ground, LED begins turning on with randomly color. 
