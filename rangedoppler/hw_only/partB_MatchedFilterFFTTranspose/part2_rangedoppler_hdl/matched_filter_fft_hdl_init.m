%% Model coefficients
N1 = 256; % row
N2 = 64; % columns
Ts = 1;
MatrixInputArr = [1:N1*N2];
MatrixInput = reshape(MatrixInputArr,[N1,N2]);

%% Burst Transpose parameters

hdlbramBurst.pNumCols = N1; %NOTE: the convention here is BRAM burst writes along the column and 
hdlbramBurst.pNumRows = N2; % will burst along the rows, hence why N1 and N2 are swapped around...
run AXIBusObjects;
hdlbramBurst.pAXIDataWidthBytes = 8; % number of bytes (64 bits) for AXI Data-Width
hdlbramBurst.pMaxBankLines = 6;
hdlbramBurst.pMaxNumBanks = 3;

%Bram address width
hdlbramBurst.pBramAddrWidth = ceil(log2(hdlbramBurst.pMaxBankLines*hdlbramBurst.pMaxNumBanks*hdlbramBurst.pNumCols));

%BRAM savings
bramSaving = (  1 - hdlbramBurst.pMaxBankLines*hdlbramBurst.pMaxNumBanks*hdlbramBurst.pNumCols / (hdlbramBurst.pNumCols*hdlbramBurst.pNumRows))*100;
fprintf('By using DDR4 memory we reduced BRAM usage of the transpose by %2.1f percent. Address width is %d-bits \n',bramSaving,hdlbramBurst.pBramAddrWidth);

% State machine labeling
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


%% Windowing parameters for FFT/Matched Filter

columnWindowFun = taylorwin(N2,10,-40);%.*(-1.^(1:nCols)');

DTWindowFun = numerictype(1,16+4,13+4);
DTsig_in = numerictype(1,20,18);
DToutput = numerictype(1,32,22);
DTTransposeInOut = numerictype(1,32,24);
DT_fftColOutput = numerictype(1,32,21);


