# AM Super-Heterodyne Receiver — MATLAB Simulation

A full end-to-end simulation of an **AM (DSB-SC) modulation and super-heterodyne receiver** built in MATLAB, developed as part of the Analog Communications course at Cairo University — Faculty of Engineering, Electronics & Communications Department (2026).

---

## Overview

This project simulates a real radio broadcasting system where multiple audio stations are transmitted simultaneously over a shared frequency band using **Frequency Division Multiplexing (FDM)**, and a single station is recovered using a classic **super-heterodyne receiver** architecture.

The entire pipeline — from reading raw audio files to playing back the recovered signal — is implemented in MATLAB without any external toolboxes beyond the Signal Processing Toolbox.

---

## System Architecture

```
Audio Files (.wav)
      |
      v
 [Preprocessing]       — stereo to mono, zero-padding, upsampling ×10
      |
      v
 [DSB-SC Modulator]    — multiply each message by its assigned carrier
      |
      v
 [FDM Composite]       — sum all modulated stations into one signal
      |
      v
 [RF Stage — BPF]      — bandpass filter centered at desired station carrier
      |
      v
 [Mixer]               — multiply by local oscillator (Fc + F_IF)
      |
      v
 [IF Stage — BPF]      — bandpass filter centered at F_IF = 15 kHz
      |
      v
 [Baseband Detection]  — multiply by F_IF carrier, apply LPF
      |
      v
 [Recovered Audio]     — downsample and play with sound()
```

---

## Key Parameters

| Parameter | Value |
|---|---|
| Station 1 carrier (BBC Arabic) | 100 kHz |
| Station 2 carrier (FM 90.90) | 130 kHz |
| Carrier spacing (ΔF) | 30 kHz |
| IF frequency | 15 kHz |
| Upsampling factor | ×10 |
| Modulation type | DSB-SC (Double Sideband Suppressed Carrier) |
| Filter type | Butterworth |
| Filter order | 6 |

---

## Features

- Reads and processes real `.wav` audio files as input messages
- Converts stereo signals to mono and zero-pads to equal length
- Upsamples signals to satisfy the Nyquist criterion for high carrier frequencies
- Implements DSB-SC modulation and FDM multiplexing for two stations
- Automatic bandwidth detection using spectral energy thresholding
- Full super-heterodyne receiver chain with RF, IF, and baseband stages
- Frequency-domain spectrum plots at every stage using `fft` and `fftshift`
- Oscillator frequency offset experiment (0.1 kHz and 1 kHz) to study distortion effects
- Comparison experiment: receiver with and without RF BPF stage

---

## Project Structure

```
/
├── CODE.m                    # Main MATLAB simulation script
├── Short_BBCArabic2.wav      # Input audio — Station 1
├── Short_FM9090.wav          # Input audio — Station 2
└── README.md
```

---

## How to Run

1. Clone or download this repository
2. Place your `.wav` audio files in the same directory as `CODE.m`
3. Open MATLAB and navigate to the project directory
4. Run the script:
```matlab
run('CODE.m')
```
5. The script will automatically plot the spectrum at each stage and play back the recovered audio

> **Note:** MATLAB Signal Processing Toolbox is required for `bandpass`, `fdesign`, and `interp` functions.

---

## Spectrum Plots

The simulation generates the following figures:

| Figure | Description |
|---|---|
| Baseband spectra | Frequency content of both raw audio messages |
| FDM composite | Both stations visible as sidebands at 100 kHz and 130 kHz |
| After RF BPF | Only the selected station remains |
| After IF stage | Signal shifted down to 15 kHz band |
| Recovered baseband | Final demodulated signal centered at 0 Hz |

---

## Discussion Experiments

The project also includes the following experiments as required by the course:

- **Without RF BPF:** demonstrates the role of the RF stage in image rejection
- **Oscillator frequency offset:** shows how a 0.1 kHz and 1 kHz offset degrades audio quality
- **Bandwidth auto-detection:** automatically estimates signal bandwidth from the spectrum using a dB threshold

---

## Dependencies

- MATLAB R2020a or later
- Signal Processing Toolbox

---

## Author

**Marwan Mobarak**
Electronics & Communications Engineering
Cairo University — Faculty of Engineering
April 2026
