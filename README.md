# FPGA Adaptive Beamforming with HDL Coder and Zynq RFSoC

## Overview

This seminar will demonstrate how to design and implement the minimum-variance
distortionless-response (MVDR) adaptive beamforming algorithm on the Xilinx®
Zynq UltraScale+™ RFSoC platform. By following a Model-Based Design strategy, 
we show how the MVDR beamformer can be articulated in MATLAB, Simulink, 
Fixed-Point and HDL. We further demonstrate a prototyping workflow by deploying
the beamformer to the ZCU111 RFSoC evaluation board for run-time testing, 
debugging and visualization.


## Agenda


### Introduction: Motivation and Challenges
- Applications: Radar, Comms and Wireless (5G)
- Hardware FPGA challenges

### Theory and Implementation
- Linear algebra
- QR Decomposition
- Matrix Divide

### Zynq RFSoC and HDL Coder Implementation
- MATLAB MVDR reference code
- HDL Coder implementation
- Hardware Prototyping – live demo