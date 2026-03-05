**FPGA Musical Keyboard Implementation**
**Course Project Report**
**Due: December 5, 2025**

---

### Overview

This project implements a digital musical keyboard and basic music sequencer on an FPGA platform. What began as a simple switch-controlled tone generator evolved into a modular hardware design capable of generating multiple musical notes with accurate pitch and stable audio output. The system uses Direct Digital Synthesis (DDS) and pulse-width modulation (PWM) to generate audio signals, while maintaining precise timing derived from the FPGA’s onboard clock.

A key requirement for the design is the following constraint within the FPGA constraints file to ensure correct routing for the audio clock signal:

```
set_property -dict {PACKAGE_PIN N13 IOSTANDARD LVCMOS33} [get_ports {aud_dac_clk}]
```

---

### System Design

The design is driven by the FPGA board’s **100 MHz system clock**, from which a **48 kHz audio sample tick** is derived. This sampling rate was chosen to provide a stable reference for generating accurate musical frequencies. Early testing revealed that incorrect pitch values occurred when notes were generated directly from the system clock. By introducing the transformed **48 kHz sampling tick**, frequency generation stabilized and musical notes produced the correct pitch.

Each note is synthesized using **Direct Digital Synthesis (DDS)**. In this approach, tuning words define the phase increment of a phase accumulator. The upper bits of the accumulator drive the waveform generation, producing precise digital representations of musical tones. This method allows the system to generate different pitches efficiently while maintaining frequency stability.

The architecture is organized into multiple functional modules to improve clarity and scalability. These modules include:

* **Debouncing modules** for pushbuttons and switches
* **Note logic** to translate input signals into musical notes
* **Song playback control** for sequencing stored melodies
* **Audio mixing logic** for combining sound sources
* **PWM output module** for audio signal generation

This modular structure keeps the design organized and allows individual components to be modified or expanded without affecting the entire system.

---

### Features and Output

To extend the instrument’s playable range, **octave control** was implemented using debounced pushbuttons. This allows the user to shift the pitch range of the keyboard while preserving the same key layout.

The final audio signal is generated through **high-speed PWM at the full system clock rate**. When routed through the board’s DAC interface and filtered, this produces a smooth analog audio signal. Using PWM in this manner avoids many of the tolerance and crossover issues commonly encountered with simpler audio output methods.

---

### Conclusion

The completed design demonstrates how FPGA hardware can be used to implement real-time digital audio synthesis. By combining DDS-based tone generation, modular hardware architecture, and PWM audio output, the system functions as a compact digital musical keyboard and sequencer. The project highlights key principles of digital signal generation, timing control, and hardware modularity in FPGA-based systems.
