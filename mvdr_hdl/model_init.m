%% Environment
propSpeed = physconst('LightSpeed');   % Propagation speed
fc = 915e6;           % Operating frequency
lambda = propSpeed/fc;

%% Receiver
numArrayElements = 4;
sensorArray = phased.ULA('NumElements',numArrayElements,'ElementSpacing',0.5*lambda);
fs = 128e6;
Ts = 1/fs;
windowSize = 1024; % pick this to have a power of 2 square root
frameTime = windowSize*Ts;

%% Tracked Signals

srcAngles = [20 60];

% start freq, end freq, sweep time
srcSignalParam1 = [5e6 10e6 5e-6]; 
srcSignalParam2 = [20e6 25e6 5e-6];

%% Beamforming parameters
scanAngle = srcAngles(1);

% calculate the matrix of steering vectors
steeringVector = phased.SteeringVector(...
            'SensorArray',sensorArray,...
            'PropagationSpeed',propSpeed,...
            'NumPhaseShifterBits',0);
sv = step(steeringVector,fc,[scanAngle; 0]);

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

% Output
output_dt = fixdt(1,32,30);

%% CORDIC matrix divide parameters

% N<WordLength
NumberOfCORDICIterations = matrixdivin_dt.WordLength - 1; 

% Specify the data-type used in back-substitution
BackSubstitutePrototype = fi(0, matrixdivbacksub_dt);

%% Pipeline delays

covMatDelay = 6;

movAvgDelay = 2;

% Delay due to CORDIC iterations and pipeline registers
% 10 CORDIC operations in QE decomp, 86 pipeline stages
matrixDivDelay = NumberOfCORDICIterations*10 + 86;

normResponseDelay = 50;

if measureDelays
    mvdrPipelineDelay = 0;
else
    mvdrPipelineDelay = covMatDelay+movAvgDelay+matrixDivDelay+normResponseDelay;
end

%% Simulation parameters
stoptime = frameTime*6;