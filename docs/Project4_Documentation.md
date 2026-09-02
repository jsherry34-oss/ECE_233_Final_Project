# ECE 233 Project 4: Beam Training with Analog True-Time-Delay Arrays

## Project Overview

This project investigates beam training in wideband millimeter-wave (mmWave) systems using true-time-delay (TTD) arrays. Unlike conventional phase-shifter arrays that apply the same phase shift to all frequencies, TTD arrays can synthesize frequency-dependent beams by delaying signals in all antenna branches. This enables single-shot beam training using frequency-domain digital signal processing.

**Due Date:** Friday, September 4, 2026 by 11:59 PM

**Reference Paper:** V. Boljanovic et al., "Design of Millimeter-Wave Single-Shot Beam Training for True-Time-Delay Array," 2020 IEEE 21st International Workshop on Signal Processing Advances in Wireless Communications (SPAWC)

---

## Project Objectives

1. Design a frequency-dependent beam training codebook for analog TTD arrays
2. Implement a dictionary-based angle estimation algorithm
3. Study the impact of hardware impairments on beam training performance
4. Generate required plots to visualize codebook performance and estimation accuracy

---

## System Model

### Basic Setup

**Communication System:**
- **Modulation:** Orthogonal Frequency Division Multiplexing (OFDM) with cyclic prefix (CP)
- **Scenario:** Downlink beam training from base station (BS) to user equipment (UE)
- **Architecture:** 
  - Base station: Digital array with fixed precoder
  - User equipment: Analog TTD array (receiver-side beam training)

**System Parameters (from [R-5, Sec. V]):**

| Parameter | Symbol | Value |
|-----------|--------|-------|
| Carrier Frequency | fc | 60 GHz |
| Bandwidth | BW | 2 GHz |
| Total Subcarriers | Mtot | 4096 |
| BS Antennas | NT | 128 |
| UE Antennas | NR | 16 |
| Training Directions | D | 32 |
| Dictionary Size | Q | 1024 |
| ADC Resolution | - | 5 bits |

### Array Configuration

Both BS and UE use **uniform linear arrays (ULA)** with half-wavelength spacing:

**Array Response Vectors (Frequency-Flat):**

```
Receiver: aR(θ) ∈ ℂ^(NR×1)
  [aR(θ)]n = NR^(-1/2) exp[j(n-1)π sin(θ)],  n = 1, ..., NR

Transmitter: aT(θ) ∈ ℂ^(NT×1)  
  [aT(θ)]n = NT^(-1/2) exp[j(n-1)π sin(θ)],  n = 1, ..., NT
```

Where:
- θ is the angle in radians
- j is the imaginary unit
- The half-wavelength spacing is normalized (d/λ = 1/2)

---

## Channel Model

### Geometric Channel with Frequency Selectivity

The channel model considers **L = 3 multipath clusters** with frequency-selective fading.

**Channel Matrix for k-th Sub-band ([R-5, Eq. 1]):**

```
H[k] = Σ(l=1 to L) Gl[k] aR(θl^(R)) aT^H(θl^(T))
```

Where:
- **H[k] ∈ ℂ^(NR×NT)**: Channel matrix for sub-band k
- **Gl[k]**: Complex gain of l-th cluster at sub-band k
- **θl^(R)**: Angle of arrival (AoA) of l-th cluster
- **θl^(T)**: Angle of departure (AoD) of l-th cluster
- **L = 3**: Number of multipath clusters

### Sub-band Structure

The bandwidth BW is divided into **Kc** distinct sub-bands with coherence bandwidth BWc:

```
Kc = ⌈BW / BWc⌉
```

**Sub-band to Subcarrier Mapping:**

```
k = ⌈(m × Kc) / Mtot⌉
```

Where:
- k: Sub-band index (1 to Kc)
- m: Subcarrier index (1 to Mtot)

### Channel Gain Statistics

**Complex Gains ([R-5, Eq. 2]):**

```
Gl[k] ~ CN(0, σl²)  for all k
```

**Covariance Structure:**

```
E[Gl1[k1] Gl2*[k2]] = { σl1²,  if l1 = l2 and k1 = k2
                      { 0,     otherwise
```

**Power Ordering:**
```
σ1² ≥ σ2² ≥ ... ≥ σL²
```

**Project Specification:**
- Dominant path (l=1) is **10 dB stronger** than the other two paths (l=2, 3)
- Therefore: σ1² / σ2² = σ1² / σ3² = 10^(10/10) = 10

### Channel Fading Parameters

From [R-5, Sec. V]:
- Fading simulated by **20 rays per cluster** with **10 ns spread**
- This gives approximately Kc ≈ 20 independent channel realizations
- No intra-cluster angular spread assumed

---

## TTD Array Architecture

### Frequency-Dependent Beamforming

The key advantage of TTD arrays is that they create **frequency-dependent antenna weight vectors (AWVs)**.

**TTD Antenna Weight Vector ([R-5, Eq. 4]):**

```
w[m] ∈ ℂ^(NR×1)

[w[m]]n = exp[j(2πfm·τn + φn)]
```

Where:
- **m**: OFDM subcarrier index
- **n**: Antenna element index (1 to NR)
- **fm**: Frequency of m-th subcarrier
- **τn**: True-time delay for n-th antenna branch
- **φn**: Phase shift for n-th antenna branch

**Subcarrier Frequency:**

```
fm = fc - BW/2 + (m-1) × BW/(Mtot - 1)
```

### Received Signal Model

**Received Signal at m-th Subcarrier ([R-5, Eq. 3]):**

```
Y[m] = M^(-1/2) w^H[m] H[k] v + w^H[m] n[m],  m ∈ 𝓜
```

Where:
- **Y[m]**: Received signal at subcarrier m
- **w[m]**: TTD AWV for subcarrier m
- **H[k]**: Channel matrix for corresponding sub-band k
- **v = aT(θ̂^(T))**: Fixed BS precoder (designed for known AoD)
- **n[m] ~ CN(0, σN² INR)**: Thermal noise
- **M = |𝓜|**: Number of training subcarriers
- **𝓜**: Set of selected subcarrier indices for training

**Training Pilot:**
```
X[m] = M^(-1/2)  for all m ∈ 𝓜
```
Power normalized across M training subcarriers.

---

## TTD Codebook Design with Frequency Diversity

### Design Objectives

1. Create **D = 32** uniformly spaced directional beams
2. Introduce **frequency diversity factor R** to improve robustness
3. Map multiple subcarriers to each direction for independent channel realizations

### Codebook Structure

**DFT Beam Patterns ([R-5, Eq. 6]):**

```
fd ∈ ℂ^(NR×1),  d = 1, ..., D

[fd]n = exp[j2π(n-1)(d-1-D/2)/D]
```

These are standard DFT beamforming vectors that provide uniform angular coverage.

### Subcarrier Selection with Diversity

**Subcarrier Set for Direction d ([R-5, Eq. 7]):**

```
𝓜d = { m | m = 1 + (d-1)⌊Mtot/(D×R)⌋ + (r-1)Mtot/R, r = 1, ..., R }
```

Where:
- **R**: Diversity order (number of independent channel realizations per direction)
- **D**: Number of sounding directions
- **𝓜d**: Set of R subcarriers mapped to direction d

**Total Training Subcarriers:**
```
𝓜 = ⋃(d=1 to D) 𝓜d
M = D × R
```

### Design Goal

Design delay taps τn and phase taps φn such that:

```
w[m] = fd  for all m ∈ 𝓜d
```

This means all R subcarriers in 𝓜d synthesize the same directional beam fd.

### TTD Tap Solutions

**Uniformly Spaced Delay and Phase Taps ([R-5, Proposition 1, Eq. 9]):**

```
τn = (n - 1) × R / BW

φn = (n - 1) × [sgn(ψ)π - ψ]
```

Where:
```
ψ = mod(2πR(fc - BW/2)/BW + π, 2π) - π
```

And:
- **sgn(·)**: Sign function
- **mod(·, 2π)**: Modulo 2π operation

**Notes:**
- Delay spacing inversely proportional to bandwidth
- Higher diversity R → larger delay spacing → more relaxed hardware requirements
- Phase pattern compensates for frequency-dependent phase terms

---

## Angle Estimation Algorithm

### Super-Resolution Dictionary-Based Method

The proposed algorithm ([R-5, Algorithm 1, Section IV]) improves upon simple peak-power detection by using a dictionary matching approach.

### Step 1: Power Estimation per Direction

**Maximum Likelihood Power Estimate ([R-5, Eq. 15]):**

```
p̂d = (1/R) Σ(m∈𝓜d) |Y[m]|²
```

Where:
- **p̂d**: Estimated received power in direction d
- **R**: Diversity order (number of independent samples)
- **𝓜d**: Set of subcarriers mapped to direction d

Collect all power estimates:
```
p̂ = [p̂1, p̂2, ..., p̂D]^T ∈ ℝ^(D×1)
```

### Step 2: Dictionary Construction

**Power Model ([R-5, Eq. 13]):**

```
p = B·g + NR·σN²·1
```

Where:
- **p ∈ ℝ^(D×1)**: Expected power vector
- **B ∈ ℝ^(D×Q)**: Dictionary matrix
- **g ∈ ℝ^(Q×1)**: Sparse gain vector (one significant element)
- **Q**: Dictionary size (angular grid resolution)

**Dictionary Element ([R-5, Eq. 14]):**

```
[B]d,q = |fd^H aR(ξq)|²
```

Where:
- **ξq**: q-th angle in dictionary grid
- **fd**: DFT beam for direction d
- **aR(ξq)**: Array response at angle ξq

**Dictionary Grid:**
```
ξq uniformly spaced over angle range [-π/2, π/2]
Q = 1024 grid points
```

### Step 3: Angle Estimation

**Dictionary Matching ([R-5, Eq. 16]):**

```
θ̂^(R) = ξq*

where q* = argmax_q [ p̂^T [B]:,q / ||[B]:,q|| ]
```

This finds the dictionary column with highest normalized correlation to measured powers.

### Algorithm Summary

```
Algorithm 1: TTD Array Based Super-Resolution Beam Training

Input:
  - UE analog array settings: τn, φn from Eq. (9)
  - Pre-computed dictionary matrix B from Eq. (14)
  - Received OFDM symbol Y[m] for m ∈ 𝓜

Output:
  - AoA estimate θ̂^(R)

Steps:
  1. Compute direction powers p̂d using Eq. (15)
  2. Find AoA estimate θ̂^(R) using Eq. (16)
```

**Computational Complexity:** O(M + D×Q)

**Resolution:** Limited by dictionary size Q
- Accuracy: ±π/(2Q) radians
- High-SNR RMSE floor: √[(π/Q)²/12]

---

## Hardware Impairments

### Two TTD Architectures

**RF TTD Array:**
- Group delay introduced in Radio Frequency (RF) domain
- More sensitive to delay errors

**Baseband (BB) TTD Array:**
- Group delay introduced in analog baseband domain
- More robust to delay errors (as shown in [R-5, Fig. 5])

### Impairment Models

Three types of hardware impairments are considered ([R-5, Eq. 5, Section II-A]):

#### 1. Frequency-Flat Magnitude/Gain Error

```
10 log10(αn) ~ N(0, σA²)
```

Where:
- **αn**: Magnitude mismatch for n-th antenna branch
- **σA**: Standard deviation of gain error in dB
- Log-normal distribution model

#### 2. Frequency-Flat Phase Error

```
φ̃n ~ N(φn, σP²)
```

Where:
- **φ̃n**: Actual phase shift (with error)
- **φn**: Intended phase shift
- **σP**: Standard deviation of phase error

#### 3. TTD Delay Error

```
τ̃n ~ N(τn, σT²)
```

Where:
- **τ̃n**: Actual time delay (with error)
- **τn**: Intended time delay
- **σT**: Standard deviation of delay error

### Impaired AWVs

**RF TTD Array with Impairments ([R-5, Eq. 5]):**

```
[wRF[m]]n = αn exp[j(2πfm·τ̃n + φ̃n)]
```

**Baseband TTD Array with Impairments:**

```
[wBB[m]]n = αn exp[j(2π(fm - fc)·τ̃n + φ̃n)]
```

**Note:** Without impairments (σA² = σP² = σT² = 0), both architectures are equivalent except for a frequency-flat phase term that can be absorbed in φn.

### Performance Impact

From [R-5, Figs. 4-5]:

**Gain and Phase Errors (both architectures equivalent):**
- Severe degradation when σA ≥ 2.5 dB
- Severe degradation when σP ≥ 30° (≈ 0.52 radians)

**Delay Errors (architecture-dependent):**
- **BB TTD:** Robust up to σT ≈ 125 ps
- **RF TTD:** Severe degradation at σT ≥ 1.5 ps
- **Conclusion:** BB implementation has much more relaxed specifications

---

## Required Results and Plots

### Plot 1: Beam Patterns of TTD Codebook

**Requirement:** Visualize the designed training codebook for analog TTD arrays.

**What to Plot:**
- Beam patterns for all D = 32 DFT beams {fd}
- Show frequency-dependent behavior across selected subcarriers
- Demonstrate uniform angular coverage

**Suggested Visualization:**
- Multiple subplots or overlay plots
- Angular range: [-90°, 90°] or [-π/2, π/2]
- Magnitude of beam gain vs. angle
- Show how different frequencies map to same/different directions

### Plot 2: RMSE vs. SNR (Without Hardware Impairments)

**Requirement:** Plot RMSE of angle estimation vs. SNR for diversity factors R = 1, 2, 4, without hardware impairments.

**Parameters:**
- **SNR Range:** -20 dB to 20 dB (suggest steps of 5 dB)
- **Diversity Factors:** R ∈ {1, 2, 4}
- **Hardware Impairments:** σA = σP = σT = 0 (no errors)
- **Monte Carlo:** Multiple trials per SNR point for statistical averaging

**Expected Behavior:**
- Higher diversity R → lower RMSE
- Performance improves with SNR until hitting resolution floor
- Resolution floor: RMSE ≈ √[(π/Q)²/12] ≈ √[(π/1024)²/12] ≈ 0.00088 rad ≈ 0.05°

**Plot Format:**
- X-axis: SNR (dB), range [-20, 20]
- Y-axis: RMSE (degrees), log scale
- Multiple curves for R = 1, 2, 4
- Compare with [R-5, Fig. 3]

### Plot 3: RMSE vs. Gain Error σA

**Requirement:** Plot RMSE vs. standard deviation of gain error σA in the range 0 dB to 4.5 dB.

**Parameters:**
- **σA Range:** 0 dB to 4.5 dB (suggest 0.5 dB steps)
- **Fixed Parameters:** 
  - SNR = 0 dB (as in [R-5, Fig. 4])
  - R = 4 (diversity order)
  - σP = 0 (no phase error)
  - σT = 0 (no delay error)
- **Architecture:** Both RF and BB TTD behave identically for gain/phase errors

**Expected Behavior:**
- Minimal impact for σA < 2.5 dB
- Severe degradation for σA ≥ 2.5 dB
- Compare with red dashed line with stars in [R-5, Fig. 4]

**Plot Format:**
- X-axis: σA (dB), range [0, 4.5]
- Y-axis: RMSE (degrees), log scale
- Should match the trend in [R-5, Fig. 4]

### Plot 4 (BONUS): RMSE vs. Phase Error σP

**Requirement:** Plot RMSE vs. standard deviation of phase error σP in the range 0° to 50°.

**Parameters:**
- **σP Range:** 0° to 50° (suggest 5° steps)
- **Fixed Parameters:**
  - SNR = 0 dB
  - R = 4 (diversity order)
  - σA = 0 (no gain error)
  - σT = 0 (no delay error)
- **Architecture:** Both RF and BB TTD behave identically for gain/phase errors

**Expected Behavior:**
- Minimal impact for σP < 30°
- Severe degradation for σP ≥ 30°
- Compare with red dashed line with diamonds in [R-5, Fig. 4]

**Plot Format:**
- X-axis: σP (degrees), range [0, 50]
- Y-axis: RMSE (degrees), log scale
- Should match the trend in [R-5, Fig. 4]

---

## Implementation Guidelines

### Key Equations Summary

| Component | Equation Reference | Description |
|-----------|-------------------|-------------|
| Array Response | Section II | aR(θ), aT(θ) with half-wavelength spacing |
| Channel Model | Eq. (1) | H[k] with L=3 clusters |
| TTD AWV | Eq. (4) | w[m] with frequency dependence |
| Received Signal | Eq. (3) | Y[m] for each training subcarrier |
| TTD Tap Design | Eq. (9) | τn, φn for diversity order R |
| Subcarrier Selection | Eq. (7) | 𝓜d mapping subcarriers to directions |
| Power Estimation | Eq. (15) | p̂d from received signals |
| Dictionary | Eq. (14) | B matrix for angle grid |
| AoA Estimation | Eq. (16) | Dictionary matching |
| Hardware Impairments | Eq. (5) | αn, φ̃n, τ̃n models |

### SNR Definition

From [R-5, Section V]:

```
SNR = (Σ(l=1 to L) σl²) / σN²
```

Total channel power divided by noise power.

### Suggested Implementation Order

1. **Array responses and basic geometry**
   - Implement aR(θ) and aT(θ)
   - Test with known angles

2. **Channel generation**
   - Generate H[k] for k = 1, ..., Kc
   - Verify power ordering (dominant path +10 dB)

3. **TTD codebook design**
   - Calculate τn and φn from Eq. (9)
   - Generate w[m] for all training subcarriers
   - Verify mapping: w[m] ≈ fd for m ∈ 𝓜d
   - **Generate Plot 1**

4. **Signal generation**
   - Generate Y[m] using Eq. (3)
   - Add noise for specified SNR
   - Handle different sub-bands k correctly

5. **Dictionary construction**
   - Pre-compute B matrix with Q = 1024
   - Can be done once and reused

6. **Angle estimation**
   - Implement Algorithm 1
   - Compute p̂d from Eq. (15)
   - Find best match using Eq. (16)

7. **Monte Carlo simulation**
   - Run multiple trials for each parameter set
   - Compute RMSE from true vs. estimated angles
   - **Generate Plots 2, 3, 4**

8. **Hardware impairments**
   - Add error models from Eq. (5)
   - Implement for both RF and BB architectures
   - Compare performance

### Validation Checkpoints

- **Channel power:** Verify σ1² / σ2² = 10 (10 dB difference)
- **Codebook:** Verify w[m] creates D uniform beams
- **Dictionary:** Verify B has size D × Q = 32 × 1024
- **Power estimates:** Verify p̂d has exponential distribution
- **Figures:** Compare trends with [R-5, Figs. 3, 4, 5]

---

## Performance Metrics

### Root Mean Square Error (RMSE)

```
RMSE = √(E[(θ̂^(R) - θtrue^(R))²])
```

Estimated via Monte Carlo:
```
RMSE ≈ √[(1/Ntrials) Σ(i=1 to Ntrials) (θ̂i - θtrue)²]
```

Where:
- **Ntrials:** Number of Monte Carlo trials (suggest ≥ 1000)
- **θ̂i:** Estimated AoA in trial i
- **θtrue:** True AoA of dominant path

### Expected Performance

From [R-5, Section V]:

**Without Hardware Impairments (R = 4):**
- SNR = -10 dB: RMSE ≈ 3-5°
- SNR = 0 dB: RMSE ≈ 0.5-1°
- SNR = 10 dB: RMSE ≈ 0.1-0.3°
- SNR = 20 dB: RMSE ≈ 0.05° (approaching resolution floor)

**With Hardware Impairments (SNR = 0 dB, R = 4):**
- No impairments: RMSE ≈ 0.5-1°
- σA = 2.5 dB: RMSE ≈ 2-5° (degradation begins)
- σP = 30°: RMSE ≈ 2-5° (degradation begins)
- Larger errors cause severe degradation

---

## Additional Notes

### Assumptions

1. **Narrowband array response:** Array response is frequency-flat across BW
2. **Known AoD:** Base station precoder v designed for known angle of departure
3. **Fixed precoder:** Same v used across all subcarriers at BS
4. **Long CP:** Cyclic prefix longer than combined channel + TTD delay spread
5. **Independent clusters:** Channel gains uncorrelated across clusters
6. **No intra-cluster spread:** Each cluster has single AoA/AoD
7. **Time-invariant impairments:** Hardware errors constant during training

### Practical Considerations

From [R-5, Section VI]:

**Delay Requirements (for R = 4, NR = 16, BW = 2 GHz):**
- Delay resolution: Δτ = R/BW = 2 ns
- Maximum delay range: τmax = (NR-1) × Δτ = 30 ns
- Range-to-resolution ratio: 15:1

**Baseband TTD Implementation:**
- More energy efficient than RF TTD
- Uses discrete-time sampling-based delay
- Leverages digital-friendly time-based circuits
- Can achieve specifications with nanometer CMOS technology

### References to Paper Sections

- **Section II:** System model, channel, TTD array
- **Section III:** TTD codebook design with frequency diversity
- **Section IV:** Super-resolution angle estimation algorithm
- **Section V:** Performance results, impairments study
- **Section VI:** Hardware implementation discussion

---

## Deliverables Checklist

- [ ] Implement channel model with L=3 paths
- [ ] Design TTD codebook (calculate τn, φn)
- [ ] Implement dictionary-based angle estimation
- [ ] Generate Plot 1: Beam patterns
- [ ] Generate Plot 2: RMSE vs. SNR for R = 1, 2, 4
- [ ] Generate Plot 3: RMSE vs. gain error σA
- [ ] (Bonus) Generate Plot 4: RMSE vs. phase error σP
- [ ] Verify results match trends in reference paper
- [ ] Document code and methods
- [ ] Submit by Friday, September 4, 2026, 11:59 PM

---

## Summary of Key Parameters

```matlab
% System Parameters
fc = 60e9;           % Carrier frequency (Hz)
BW = 2e9;            % Bandwidth (Hz)
Mtot = 4096;         % Total subcarriers
NT = 128;            % BS antennas
NR = 16;             % UE antennas
D = 32;              % Training directions
Q = 1024;            % Dictionary size
L = 3;               % Number of paths
power_ratio_dB = 10; % Dominant path advantage

% Channel Parameters
Kc = 20;             % Approximate number of sub-bands
ray_per_cluster = 20;
delay_spread = 10e-9; % 10 ns

% Variable Parameters
R = [1, 2, 4];       % Diversity factors
SNR_range = -20:5:20; % SNR in dB
sigma_A_range = 0:0.5:4.5;   % Gain error std (dB)
sigma_P_range = 0:5:50;      % Phase error std (deg)
```

---

*End of Documentation*
