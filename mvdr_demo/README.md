# FPGA Adaptive Beamforming with HDL Coder and Zynq RFSoC

## Overview

These models will demonstrate how to design and implement the minimum-variance
distortionless-response (MVDR) adaptive beamforming algorithm on the Xilinx®
Zynq UltraScale+™ RFSoC platform. By following a Model-Based Design strategy, 
we show how the MVDR beamformer can be articulated in MATLAB, Simulink, 
Fixed-Point and HDL. We further demonstrate a prototyping workflow by deploying
the beamformer to the ZCU111 RFSoC evaluation board for run-time testing, 
debugging and visualization.


## Files

### mvdr_hdl_sim ###

This model uses the phased array toolbox to demonstrate high-level modeling 
of adaptive beamforming processing. Comparisons are made to various elaborated 
versions of the same design starting originally in floating point then
to eventual fixed-point HDL. Blocks from the fixed-point toolbox were used 
to aid in this design for computing the adaptive weights using QR decomposition.

### zcu111_mvdr_demo ###

This HDL model uses the same algorithm from the previous design but now integrates 
it for a ZCU111 RFSoC evaluation kit. Using 4 channels of ADC and DAC looped 
back on itself, a beam is electronically steered out the DAC and then processed
by the ADC. Using four inputs, a 4x4 covariance matrix is composed and then 
QR decomposition is applied to yield optimal steering weights that augment the 
desired steering angle. A QPSK signal of interest is resolved in the presence of 
interference which is artificially  introduced in the transmit signal.


Demo instructions:
- Ensure you have the "HDL Coder support package for RFSoC" support package installed https://www.mathworks.com/hardware-support/rfsoc-hdl-coder.html
- Run the HDL Coder Workflow Advisor for the model "TxSteering_RxMVDR_4x4_HDL_IQ.slx"
- Program the FPGA after bitstream creation is completed
- For the cable setup, you will need differential SMA connector DC blockers. 
Connect the differential ADC cables for the ADC Tile 2 (Ch 0 and 1) and Tile 3 (Ch 0 and 1)
to the DAC Tile 0 Channel 0 1 2 and 3.
- With the board booted fully and powered on, run the RFSoC_MVDR_Demo.mlapp

ADC/DAC Loopback Wiring Details:
To loop back the 4 DAC and ADC channels with the XM500 board you will need to make the following connections
<img src = "xm500_wiring.png" align="center" width="400">

Because these connections are differential, you will need SMA DC Blockers

Connection details: 
- RFMC_ADC_04 connects to RFMC_DAC_00
- RFMC_ADC_05 connects to RFMC_DAC_01
- RFMC_ADC_06 connects to RFMC_DAC_02
- RFMC_ADC_07 connects to RFMC_DAC_03 

Note that you will want to make sure the PN differential connections pair up such that P connects to N


## Documentation PDF

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

The license used in this contribution is the XSLA license, which is the most common license for MathWorks staff contributions.
