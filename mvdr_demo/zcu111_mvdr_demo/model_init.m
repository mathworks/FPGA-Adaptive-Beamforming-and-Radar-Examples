% ADC/DAC sampling rate
%
%   Copyright 2021 The MathWorks, Inc.


ConverterSampleRate = 1966.08e6; 

% DDC/DUC factor
DecimInterpFactor = 8; 

% Effective data sampling rate
DataSampleRate = ConverterSampleRate/DecimInterpFactor;
Ts = 1/DataSampleRate;

% Samples per clock cycle
VectorSamplingFactor = 1; 

% FPGA clock rate
FPGAClkRate = DataSampleRate/VectorSamplingFactor;

% Number of ADC/DAC channels
NumChan = 4;

% Sample data width
SampleDataWidth = 16*2; % 16-bit I/Q samples

% Channel data width
ChannelDataWidth = SampleDataWidth*VectorSamplingFactor;

% Tx NCO parameters
NCO_bits = 14;
NCO_default_freq = 10e6;
NCO_default_inc = floor(NCO_default_freq*2^NCO_bits/DataSampleRate);

%% Create test source data

rng('default');

testSrc1 = struct();
testSrc1.NFrames=15;
testSrc1.FrameLength=256;
testSrc1.PreambleLength=24;
testSrc1.SamplesPerSymbol=4;

[testSrc1.Data,testSrc1.mfCoeffs,testSrc1.rrcCoeffs] = ...
    generate_qpsk_signal(testSrc1.NFrames,testSrc1.FrameLength,...
        testSrc1.PreambleLength,testSrc1.SamplesPerSymbol);

testSrc2 = struct();
testSrc2.NFrames=7;
testSrc2.FrameLength=128;
testSrc2.PreambleLength=24;
testSrc2.SamplesPerSymbol=16;
testSrc2.Data = ...
    generate_qpsk_signal(testSrc2.NFrames,testSrc2.FrameLength,...
        testSrc2.PreambleLength,testSrc2.SamplesPerSymbol);

%% DMA
S2MM_frame_size = testSrc1.FrameLength*testSrc1.SamplesPerSymbol*3;

%% Environment
propSpeed = physconst('LightSpeed');   % Propagation speed
fc = ConverterSampleRate/4;           % Operating frequency
lambda = propSpeed/fc;

%% Beamformer parameters

% Number of array elements
numArrayElements = 4;

% Uniform linar array
sensorArray = phased.ULA('NumElements',numArrayElements,'ElementSpacing',0.5*lambda);

% Steering vector computation for array
steeringVector = phased.SteeringVector('SensorArray',sensorArray);

% Moving average window size
% pick this to have a power of 2 square root
windowSize = 4096;

%% Fixed point datatypes

% RFSoC ADC is 12 bits
adc_dt = fixdt(1,12,11);

% RF Data converter interface pads to 16 bits
input_dt = fixdt(1,16,15);

% Covariance Matrix
covmat_dt = fixdt(1,18,16);

% Moving average
movavg_bitgrowth = nextpow2(windowSize);
movavg_accum_dt = fixdt(1,covmat_dt.WordLength+movavg_bitgrowth,covmat_dt.FractionLength);
movavg_bitshift = nextpow2(sqrt(windowSize));
movavg_out_dt = fixdt(1,movavg_accum_dt.WordLength-movavg_bitshift,movavg_accum_dt.FractionLength);

% Steering vector
sv_dt = fixdt(1,16,14);

% Matrix divide input
matrixdivin_dt = fixdt(1,22,11);

% Matrix divide back-substitition
matrixdivbacksub_dt = fixdt(1,32,15);

% Matrix divide output
matrixdivout_dt = fixdt(1,24,16);

% Weight vector
w_dt = fixdt(1,24,23);

% Rx/Tx channel coefficients
coeff_dt = fixdt(1,18,16);

% Output
output_dt = fixdt(1,32,30);

% Tx output gain
tx_gain_dt = fixdt(1,16,14);

%% CORDIC matrix divide parameters

% N<WordLength
NumberOfCORDICIterations = matrixdivin_dt.WordLength - 1; 

% Specify the data-type used in back-substitution
BackSubstitutePrototype = fi(0, matrixdivbacksub_dt);

%% Pipeline delays

covMatDelay = 6;

movAvgDelay = 2;%+windowSize/2;

% Delay due to CORDIC iterations and pipeline registers
% 10 CORDIC operations in QE decomp, 86 pipeline stages
matrixDivDelay = NumberOfCORDICIterations*10 + 86;

normResponseDelay = 50;

mvdrPipelineDelay = covMatDelay+movAvgDelay+matrixDivDelay+normResponseDelay;

%% Simulation parameters
frameTime = windowSize*Ts;
stoptime = frameTime*40;