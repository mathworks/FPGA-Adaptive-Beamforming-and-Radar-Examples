%% Model setup
nRows = 256; % samples to capture per pulse
nCols = 64; % Number of pulses

% create an input matrix  - currently not used
rowWindowFun = taylorwin(nRows,10,-35);%.*(-1.^(1:nRows)'); 
% window function for the 2nd FFT
columnWindowFun = taylorwin(nCols,10,-40);%.*(-1.^(1:nCols)');

DTWindowFun = numerictype(1,16+4,13+4);
DTsig_in = numerictype(1,20,18);
DToutput = numerictype(1,32,22);


%% Define Radar Matrix cube
% init parameters
range_doppler_system_param_init; 

% Number of coherent processing intervals (CPI) to run
NumCPI = 1;

%% Setup processing blocks
% Create radar data cube
radarDataCube = createRadarDataCubeMod(...
    txSignalFullPeriod,antennaElement,Fs,Fc, ...
    targetPos, targetVel, targetRCS, ...
    RngMax, RxActiveTime, RngGate, ...
    CPILength, NumCPI, CPILength*pulsePeriod);

