# WS2812_LED
Trying to drive a single RGB LED WS2812 with an FPGA using VHDL

# Tools and devices
- FPGA Spartan 3 XCS400-4FT256 (50 MHz)
- LED RGB WS2812
- Oscilloscope Tektronix TDS1001B
- ISE Xilinx

# RTL Schematic

# Finite state machine (FSM)
There are **two trial version** of this FSM: 
- one changes the color of the LED though changes in the state of the **switch** signal.
- other uses a **btn** signal to light up the LED of the color indicated by the **switch** signal at that moment (_the commented part in the code_);

In red on the right, there are the FSM's outputs for each state.

![alt text](https://github.com/frarixeddu555/WS2812_LED/blob/main/finite_state_machine.jpg)
