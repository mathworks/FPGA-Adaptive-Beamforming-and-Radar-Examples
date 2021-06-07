# Range-Doppler FPGA Examples

## Overview

These models demonstrate how two-dimensional transpose using external DDR4 
memory can be used for range-doppler processing for radar applications such as
range-doppler. Some examples will require SoC Blockset for memory simulation.

## Demo Files

### TransposeMatrix ###

State-machine logic simulation for handling matrix transpose. Examples in these
folders use SoC Blockset and HDL Coder for deploying a matrix transpose example
on the ZCU111.

### 2dFFT ###

Building on top of the previous example, this demo shows how a two-dimensional FFT
can be be accomplished in HDL Coder. Similar to the previous example, this can also 
run on the ZCU111.
<img src = "2dFFT.jpg" width="600">

### 2dMatchedFilterFFT ###

Work in progress demo that performs range-doppler using a combination of a 
matched filter followed by a matrix transpose and FFT.

The license used in this contribution is the XSLA license, which is the most common license for MathWorks staff contributions.
