%model_init Setup for TxSteering_RxMVDR_4x4_HDL_IQ.slx
%
%   Copyright 2021-2023 The MathWorks, Inc.

%% Add common folder to path
thisDir = fileparts(mfilename('fullpath'));
addpath(fullfile(thisDir,'..','common'));

%% RF Data Converter parameters

% RF ADC/DAC sampling rate
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

%% Create test source data

rng('default');

testSrc1 = struct();
testSrc1.NFrames=15;
testSrc1.FrameLength=256;
testSrc1.PreambleLength=13;
testSrc1.SamplesPerSymbol=4;

[testSrc1.Data,testSrc1.mfCoeffs,testSrc1.rrcCoeffs] = ...
    generate_qpsk_signal(testSrc1.NFrames,testSrc1.FrameLength,...
        testSrc1.PreambleLength,testSrc1.SamplesPerSymbol);

testSrc2 = struct();
testSrc2.NFrames=7;
testSrc2.FrameLength=128;
testSrc2.PreambleLength=13;
testSrc2.SamplesPerSymbol=16;
testSrc2.Data = ...
    generate_qpsk_signal(testSrc2.NFrames,testSrc2.FrameLength,...
        testSrc2.PreambleLength,testSrc2.SamplesPerSymbol);

%% DMA capture parameters

% For QPSK demod we capture 3 frames of data so that it contains at least
% one full contigious frame

% S2MM DMA frame size
s2mmFrameSize = testSrc1.FrameLength*testSrc1.SamplesPerSymbol*3;

% Length of FIFO to handle backpressure from DMA
dmaFIFOLength = 2^nextpow2(testSrc1.FrameLength*testSrc1.SamplesPerSymbol*2);

%% Environment
propSpeed = physconst('LightSpeed');   % Propagation speed
fc = ConverterSampleRate*7/16;           % Operating frequency
lambda = propSpeed/fc;

%% Beamformer parameters

% Number of array elements
numArrayElements = 4;

% Uniform linar array
sensorArray = phased.ULA('NumElements',numArrayElements,'ElementSpacing',0.5*lambda);

% Steering vector computation for array
steeringVector = phased.SteeringVector('SensorArray',sensorArray);

% Moving average window size
windowSize = 4096;

% Diagonal loading value
diagLoading = 5e-3;

% Use internal directivity object for pattern calculation
elemPosition = sensorArray.getElementPosition();
angstep = phased.internal.getPatternIntegrationStepSize(elemPosition,lambda);
beamPattern = phased.internal.Directivity('Sensor',sensorArray,...
    'PropagationSpeed',propSpeed,'WeightsInputPort',true,...
    'AzimuthAngleStepSize',angstep,'ElevationAngleStepSize',angstep);

%% Calibration Tx NCO parameters

NCO_bits = 14;
NCO_default_freq = 10e6;
NCO_default_inc = fi(floor(NCO_default_freq*2^NCO_bits/DataSampleRate), 1,NCO_bits,0);

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
movavg_bitshift = nextpow2(windowSize);
movavg_out_dt = fixdt(1,movavg_accum_dt.WordLength-movavg_bitshift,movavg_accum_dt.FractionLength);

% Use helper function to select types for matrix solver
max_abs_A = sqrt(2);  % Upper bound on max(abs(A(:))
max_abs_B = sqrt(2);  % Upper bound on max(abs(B(:))
matrix_solve_precision = 18;   % Number of bits of precision
T = fixed.complexQRMatrixSolveFixedpointTypes(numArrayElements,numArrayElements,...
    max_abs_A,max_abs_B,matrix_solve_precision);

% Matrix solve input
matrixdivin_dt = fixed.extractNumericType(T.A);

% Matrix solve back-substitition
matrixdivbacksub_dt = fixed.extractNumericType(T.X);

% Matrix solve output
matrixdivout_dt = fixdt(1,24,matrix_solve_precision);

% Steering vector
sv_dt = fixdt(1,18,16);

% Inner product bit growth
ip_bitgrowth = (matrixdivout_dt.WordLength-matrixdivout_dt.FractionLength) + ...
    (sv_dt.WordLength - sv_dt.FractionLength) + 2;

% Reciprocal input
reciprocalin_wl = 26;
reciprocalin_dt = fixdt(1,reciprocalin_wl,reciprocalin_wl-ip_bitgrowth);

% Reciprocal output
reciprocalout_dt = fixdt(1,reciprocalin_dt.WordLength,reciprocalin_dt.WordLength-4);

% Weight vector
w_dt = fixdt(1,26,22);

% Rx/Tx channel coefficients
coeff_dt = fixdt(1,18,16);

% Output
output_dt = fixdt(1,32,26);

% Tx output gain
tx_gain_dt = fixdt(1,16,14);

%% Rx magnitude measurement parameters

rx_mag_window_size = 256;
rx_mag_sum_growth = nextpow2(rx_mag_window_size);

rx_mag_dt = fixdt(0,input_dt.WordLength,input_dt.FractionLength);
rx_mag_inv_dt = fixdt(1,27,16);
rx_gain_dt = fixdt(1,rx_mag_inv_dt.WordLength-1,rx_mag_inv_dt.FractionLength);

rx_mag_delay = input_dt.WordLength + 2 + ceil(log2(NumChan)) + 1 + rx_mag_window_size;
rx_mag_inverse_delay = nextpow2(rx_mag_dt.WordLength) + 1 + rx_mag_dt.WordLength + 2 + 7;

%% CORDIC matrix solve parameters

% N<WordLength
NumberOfCORDICIterations = matrixdivin_dt.WordLength - 1; 

% Specify the data-type used in back-substitution
BackSubstitutePrototype = fi(0, matrixdivbacksub_dt);

% Matrix solver update rate
% Formulas taken from documentation for "Complex Partial-Systolic Matrix Solve Using QR Decomposition"
wl = matrixdivin_dt.WordLength;
n = numArrayElements;
matrixSolveValidToReady = max((wl + 9), ceil((3.5*n^2 + n*(nextpow2(wl) + wl + 9.5) + 1)/n));
matrixSolveValidInToOut = (wl + 7.5)*2*n + 3.5*n^2 + n*(nextpow2(wl) + wl + 9.5) + 9 - n;
matrixSolveThroughput = matrixSolveValidToReady*numArrayElements;

%% Pipeline delays

covMatDelay = 6;

movAvgDelay = 2;

matrixSolveDelay = matrixSolveValidToReady*numArrayElements + matrixSolveValidInToOut;

reciprocalDelay = nextpow2(reciprocalin_dt.WordLength) + 1 + reciprocalin_dt.WordLength + 2 ...
    - strcmp(reciprocalin_dt.Signedness,'Signed') + 7;

normResponseDelay = 15+reciprocalDelay;

mvdrPipelineDelay = covMatDelay+movAvgDelay+matrixSolveDelay+normResponseDelay;

%% Simulation parameters
frameTime = windowSize*Ts;
stoptime = frameTime*20;