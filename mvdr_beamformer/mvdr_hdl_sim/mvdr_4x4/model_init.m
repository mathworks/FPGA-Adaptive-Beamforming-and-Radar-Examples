% model_init Setup for MVDR HDL models and testbench

%% Add common folder to path
thisDir = fileparts(mfilename('fullpath'));
addpath(fullfile(thisDir,'..','..','common'));

%% Sampling rate
fs = 245.76e6;
Ts = 1/fs;

%% Environment
propSpeed = physconst('LightSpeed');   % Propagation speed
fc = 860.16e6;           % Operating frequency
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

%% Generate signal of interest and interferer

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

% Output
output_dt = fixdt(1,32,26);

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

%% Generate testbench input signals

signalAngle = 40; % degrees
signalGain = 1;
interfererAngle = -30; % degrees
interfererGain = 1;
noiseGain = 0.1;

% Test data length
testLen = 1.5e4;

% Generate input signal
testSig1 = repmat(testSrc1.Data,ceil(testLen/length(testSrc1.Data)),1);
testSig1 = testSig1(1:testLen)*signalGain;
testSig1 = repmat(testSig1,1,numArrayElements);
testSig2 = repmat(testSrc2.Data,ceil(testLen/length(testSrc2.Data)),1);
testSig2 = testSig2(1:testLen)*interfererGain;
testSig2 = repmat(testSig2,1,numArrayElements);

% Steering vectors
signalWeights = steeringVector(fc,[signalAngle; 0]);
interfererWeights = steeringVector(fc,[interfererAngle; 0]);

% Apply steering vector weights
temp1 = bsxfun(@times,testSig1,signalWeights.');
temp2 = bsxfun(@times,testSig2,interfererWeights.');

% Generate noise
noise = complex(randn([testLen numArrayElements]),randn([testLen numArrayElements]))*noiseGain;

% Combine source signals and noise
X = temp1+temp2+noise;

% Normalize magnitude and scale to 50%
X = X/maxabs(X) * 0.5;

% Quantize input
X = double(fi(X, adc_dt));

%% Simulation parameters

% Data/valid input
sim_data_in = fi(X, input_dt);
sim_valid_in = true([testLen 1]);

% Steering vector input
sv = double(fi(signalWeights, sv_dt));

% Simulation stop time
stoptime = testLen + mvdrPipelineDelay;