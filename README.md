# Compressed-Hadamard-Code
MATLAB code for Compressed Hadamard Imaging for optically sectioned high speed neuronal activity recordings.

# Supplementary Software and Data
Included in this repository are MATLAB programs and experimental datasets to describe implementation of all-optical electrophysiology recordings using Compressed Hadamard Imaging, a high temporal resolution version of Hadamard Microscopy.

Examples were tested on MATLAB R2017a in a Windows 7 computer with a 2.5 GHz CPU and 64GB RAM.	
Requirements: MATLAB R2016b or later; MATLAB Image Processing Toolbox.
Installation: Examples source codes can be run in MATLAB after copying the supplement folder locally, no installation is necessary. Download time is relatively short for example source codes and data (200 MB).

1.	**Acquisition**
    1.	**DMD pattern generation**. Code used to define Hadamard structured illumination patterns, and to format them for the VIALUX DMD.
  
1.	**Analysis**.
Compressed Hadamard Imaging analysis software, used to demodulate optical sections.

1.	**Examples**.
Two examples are included: 
    * “example_generate_hadamard_patterns.m” generates and displays Compressed Hadamard Imaging illumination patterns and their correlation maps with the Hadamard code. Run time was 2 seconds in the test computer.
    * “example_reconstruction_analysis.m” reads raw data and raw calibration, demodulates optical sections, extracts time-averaged images and region-of-interest integrated time traces, and replicates Fig 4b from “Compressed Hadamard Microscopy for high-speed optically sectioned neuronal activity recordings” by Vicente J. Parot*, Carlos Sing-Long*, Yoav Adam, Urs L. Böhm, Linlin Z. Fan, Samouil L. Farhi, and Adam E. Cohen. Run time was 17 seconds in the test computer.
    1.	**Raw data**. Contains example raw calibration and experimental data.
    1.	**"f04b - Copy.pdf"**. is a copy of the output file that example_reconstruction_analysis.m generates.

1.	**Other software**.
Additional custom libraries used for image processing and computation.
    1.	**@vm**. General purpose vectorized movie processing class. Replaces many native Matlab functions with streamlined syntax.
    1.	**Hadamard matrices**. Library to generate Hadamard matrices of flexible sizes.
