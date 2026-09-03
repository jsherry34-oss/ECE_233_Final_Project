# ECE 233 Project 4: Beam Training with Analog True-Time-Delay Arrays

## Overview

This project attempts to implement a single-shot beam training algorithm for wideband millimeter-wave (mmWave) OFDM systems using True-Time-Delay (TTD) arrays. The implementation follows the reference paper:

> V. Boljanovic, H. Yan, E. Ghaderi, D. Heo, S. Gupta and D. Cabric, "Design of Millimeter-Wave Single-Shot Beam Training for True-Time-Delay Array," 2020 IEEE 21st International Workshop on Signal Processing Advances in Wireless Communications (SPAWC), pp. 1-5, 2020. [IEEE Xplore](https://ieeexplore.ieee.org/document/9154313)

## Project Structure

```
ECE 233 - Final Project/
├── main_project.m                    % master script
├── verify_bugfixes.m                 % verification script for bug fixes
├── run_plot1_beam_patterns.m 
├── run_plot2_rmse_vs_snr.m    
├── run_plot3_rmse_vs_gain_error.m  
├── run_plot4_rmse_vs_phase_error.m 
├── functions/                        % helper functions
│   ├── array_response.m              
│   ├── generate_channel.m            
│   ├── design_ttd_codebook.m        
│   ├── compute_ttd_awv.m            
│   ├── generate_received_signal.m    
│   ├── build_dictionary.m            
│   ├── estimate_angle.m              
│   ├── add_hardware_impairments.m    
│   └── compute_subcarrier_sets.m    
├── utils/
│   └── set_system_parameters.m       % set parameters
├── results/                          % generated plots
│   ├── plot1_beam_patterns.fig/.png
│   ├── plot2_rmse_vs_snr.fig/.png
│   ├── plot3_rmse_vs_gain_error.fig/.png
│   └── plot4_rmse_vs_phase_error.fig/.png
├── BUGFIXES.md                       % documentation of bug fixes
└── README.md                         
```

## System Parameters

All system parameters are defined in `utils/set_system_parameters.m` following [R-5, Section V]:

| Parameter | Symbol | Value |
|-----------|--------|-------|
| Carrier Frequency | fc | 60 GHz |
| Bandwidth | BW | 2 GHz |
| OFDM Subcarriers | Mtot | 4096 |
| BS Antennas | NT | 128 |
| UE Antennas | NR | 16 |
| Training Directions | D | 32 |
| Dictionary Size | Q | 1024 |
| Channel Clusters | L | 3 |
| Power Ratio | σ₁²/σ₂² | 10 dB |
| Monte Carlo Trials | N_trials | 1000 |

## Results

### Plot 1: Beam Patterns of TTD Codebook
- **Location:** `results/plot1_beam_patterns.png`
- **Shows:** 32 uniformly spaced directional beams created by TTD array

### Plot 2: RMSE vs SNR
- **Location:** `results/plot2_rmse_vs_snr.png`
- **Shows:** Angle estimation accuracy vs. SNR for diversity factors R = 1, 2, 4

### Plot 3: RMSE vs Gain Error
- **Location:** `results/plot3_rmse_vs_gain_error.png`
- **Shows:** Impact of magnitude/gain mismatch (σA = 0 to 4.5 dB)

### Plot 4: RMSE vs Phase Error
- **Location:** `results/plot4_rmse_vs_phase_error.png`
- **Shows:** Impact of phase mismatch (σP = 0° to 50°)

## Implementation Details

### Key Algorithms

1. **TTD Codebook Design** ([R-5, Eq. 9])
   - Delay taps: τₙ = (n-1) × R / BW
   - Phase taps: φₙ = (n-1) × [sgn(ψ)π - ψ]
   - Enables frequency-dependent beamforming

2. **Frequency-Dependent AWVs** ([R-5, Eq. 4])
   - w[m]ₙ = exp[j(2πfₘτₙ + φₙ)]
   - Each subcarrier probes a different direction

3. **Channel Model** ([R-5, Eq. 1])
   - H[k] = Σₗ Gₗ[k] aR(θₗ⁽ᴿ⁾) aT^H(θₗ⁽ᵀ⁾)
   - L = 3 paths, dominant path 10 dB stronger

4. **Angle Estimation** ([R-5, Algorithm 1])
   - Step 1: p̂d = (1/R) Σ|Y[m]|² for m ∈ Md
   - Step 2: θ̂ = argmax [p̂ᵀB[:,q] / ||B[:,q]||]

5. **Hardware Impairments** ([R-5, Eq. 5])
   - Baseband (BB) architecture: more robust to delay errors
   - Gain error: 10log₁₀(αₙ) ~ N(0, σA²)
   - Phase error: φ̃ₙ ~ N(φₙ, σP²)
   - Delay error: τ̃ₙ ~ N(τₙ, σT²)

## Bug Fixes (September 2026)

**Critical bugs have been identified and fixed.** See [BUGFIXES.md](BUGFIXES.md) for details.

### Issues Corrected:
1. **Phase convention errors** - Changed all exponentials from `-1j` to `+1j` to match paper convention
2. **Frequency spacing formula** - Fixed OFDM subcarrier spacing: `BW/(Mtot-1)` instead of `BW/Mtot`
3. **SNR calculation** - Corrected noise power normalization (removed erroneous `M` factor)
4. **Dictionary construction** - Fixed DFT beam phase signs

### Verification:
Run `verify_bugfixes.m` to test all corrections before generating plots.

```matlab
>> verify_bugfixes
```