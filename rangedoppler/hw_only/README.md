# Range-Doppler FPGA Examples

## Overview

These models demonstrate how two-dimensional transpose using external DDR4 
memory can be used for range-doppler processing for radar applications such as
range-doppler. Some examples will require SoC Blockset for memory simulation.

## Demo Files

### partA_TransposeMatrix ###

State-machine logic simulation for handling matrix transpose. Examples in these folders use SoC Blockset for simulating PL-DDR4 access and HDL Coder for deploying a matrix transpose example on the ZCU111. Incremental improvements to DDR4 corner turn memory access is shown by taking advantage of "wr-ready" and using a BRAM memory burst approach instead of bursting in one sample into memory at a time.


<img src = "bandwidth_cornerturn.jpg" width="400">

In the BRAM burst approach, several rows of the matrix is stored in block ram first. After accumulation of several rows, a column of data is bursted in. Management of these blockram memory "banks" is done with state machine logic. The above plot comes from analyzing the throughputs of writing memory using BRAM burst transposed then reading it back out. 

### partB_MatchedFilterFFTTranspose ###

Building on top of the previous example, this demo shows how a two-dimensional range-doppler processing example can be accomplished on an FPGA using HDL Coder. Similar to the previous example, this can also run on the ZCU111. BRAM Burst writes into memory are done to increase memory write throughputs.

<img src = "RangeDoppler.jpg" width="400">

This demo will start with MATLAB code first of running a matched FIR filter then transposing the data and performing an FFT over several radar cubes. An HDL implementation of this is then done to compute the FIR and FFT along with the transpose.

The license used in this contribution is the XSLA license, which is the most common license for MathWorks staff contributions.
