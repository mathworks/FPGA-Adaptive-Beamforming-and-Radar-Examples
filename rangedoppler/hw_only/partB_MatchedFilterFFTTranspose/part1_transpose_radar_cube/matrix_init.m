%% Model coefficients
N1 = 256; % row
N2 = 64; % columns
Ts = 1;
MatrixInputArr = [1:N1*N2];
MatrixInput = reshape(MatrixInputArr,[N1,N2]);


pNumCols = N1;
pNumRows = N2;
run AXIBusObjects;
pAXIDataWidthBytes = 8; % number of bytes (64 bits) for AXI Data-Width
pMaxBankLines = 6;
pMaxNumBanks = 3;

%Bram address width
pBramAddrWidth = ceil(log2(pMaxBankLines*pMaxNumBanks*pNumCols));

%% BRAM savings

bramSaving = (  1 - pMaxBankLines*pMaxNumBanks*pNumCols / (pNumCols*pNumRows))*100;
fprintf('By using DDR4 memory we reduced BRAM usage of the transpose by %2.1f percent. Address width is %d-bits \n',bramSaving,pBramAddrWidth);

%% State machine labeling
% LINEBUFFER = fi(1,0,4,0);
% LINESTART = fi(3,0,4,0);
Simulink.defineIntEnumType('stateBRAMfsm', {'IDLE','LINEBUFFER', 'LINESTART'}, [0 1 3]);


% BURSTSTART = fi(1,0,4,0);
% BURSTNEXT  = fi(3,0,4,0);
% WAITBURSTCOMPLETE = fi(4,0,4,0);
% WAITBURSTREADY = fi(5,0,4,0);
% WAITONBANKRDY =fi(2,0,4,0);
Simulink.defineIntEnumType('stateAXI4Mfsm', {'IDLE',...
                                             'BURSTSTART',...
                                             'WAITONBANKRDY',...
                                             'BURSTNEXT',...
                                             'WAITBURSTCOMPLETE',...
                                             'WAITBURSTREADY'}, [0 1 2 3 4 5]);
                                         
                                         
%% Radar cube 

% init parameters
range_doppler_system_param_init; 

% Number of coherent processing intervals (CPI) to run
NumCPI = 1;


% Create radar data cube
radarDataCube = createRadarDataCubeMod(...
    txSignalFullPeriod,antennaElement,Fs,Fc, ...
    targetPos, targetVel, targetRCS, ...
    RngMax, RxActiveTime, RngGate, ...
    CPILength, NumCPI, CPILength*pulsePeriod);

