%% Radar parameters

% Environment
propSpeed = physconst('LightSpeed'); % Propagation speed
Fc = 10e9; % Operating/carrier frequency
lambda = propSpeed/Fc;

% Inherit sample rate
if ~exist('Fs','var')
    Fs = 250e6;
end
Ts = 1/Fs;




% Application parameters
pulseWidthSamples = 32;
pulseBw = Fs/2; % Pulse bandwidth

CPILength = 64; % Number of pulses in a Coherent Processing Interval

% totalSamplesPulse = Fs/PRF;
% = 4250;
RxActiveSamples = 256;
RngGateSamples  = 8346 - RxActiveSamples;

% Derived params
pulsePeriodSamples = RngGateSamples+RxActiveSamples;
pulseWidth = pulseWidthSamples*Ts; % Pulse width
pulsePeriod = pulsePeriodSamples*Ts; % Pulse repetition period
PRF = 1/pulsePeriod; % Pulse repetition frequency
CPIPeriod = CPILength*pulsePeriod;
RxActiveTime = RxActiveSamples*Ts;


%


RngGate = RngGateSamples*Ts; % Range gate start
RngMin = propSpeed*RngGate/2;
RngMax = propSpeed/(PRF*2); % Maximum unambiguous range
VelMax = propSpeed*PRF/(Fc*4); % Maximum unambiguous velocity

RngDimLen = RxActiveSamples;
VelDimLen = CPILength;
RngEstBins = linspace(RngMin,RngMax,RngDimLen);
VelEstBins = linspace(-VelMax,VelMax,VelDimLen);

% Matched filter parameters
hwav = phased.LinearFMWaveform(...
    'PulseWidth',pulseWidth,...
    'PRF',PRF,...
    'SweepBandwidth',pulseBw,...
    'SampleRate',Fs);
matchingCoeff = getMatchedFilter(hwav);
txSignalFullPeriod = hwav();
txSignal = txSignalFullPeriod(1:pulseWidthSamples);

%% Target parameters
target1Az = -47;
target1Dist = 4950;
target1Speed = 100;
target1RCS = 2.5;

target2Az = 50;
target2Dist = 4900;
target2Speed = -150;
target2RCS = 4;

target1Pos = [target1Dist*cosd(target1Az); target1Dist*sind(target1Az); 0];
target1Vel = [target1Speed*cosd(target1Az); target1Speed*sind(target1Az); 0];
target2Pos = [target2Dist*cosd(target2Az); target2Dist*sind(target2Az); 0];
target2Vel = [target2Speed*cosd(target2Az); target2Speed*sind(target2Az); 0];

targetPos = [target1Pos target2Pos];
targetVel = [target1Vel target2Vel];
targetRCS = [target1RCS target2RCS];

%% Rx Array / Beamforming parameters

numAntennaElements = 1;

antennaElement = phased.IsotropicAntennaElement(...
    'FrequencyRange',[Fc-1e8 Fc+1e8], 'BackBaffled', true);


% Beamforming scan angle
RxScanAngle = target2Az;


%% CFAR detection
CFARGuardVel = 1;
CFARGuardRng = 1;
CFARTrainVel = 8;
CFARTrainRng = 4;
CFARGuardRegion = [CFARGuardRng CFARGuardVel];
CFARTrainRegion = [CFARTrainRng CFARTrainVel];
CFARRngPad = CFARGuardRng+CFARTrainRng;
CFARVelPad = CFARGuardVel+CFARTrainVel;
CFARRngIdx = (1+CFARRngPad):(RngDimLen-CFARRngPad);
CFARRngBins = RngEstBins(CFARRngIdx);
CFARRngNumBins = numel(CFARRngIdx);
CFARVelIdx = [(1+CFARVelPad):(VelDimLen/2 - 2) ...
    (VelDimLen/2 + 3):(VelDimLen-CFARVelPad)];
CFARVelBins = VelEstBins(CFARVelIdx);
CFARVelNumBins = numel(CFARVelIdx);
CFARProb = 1e-12;
CFARIdx = zeros(2,CFARVelNumBins*CFARRngNumBins);
nn = 1;
for ii=CFARVelIdx
    for jj=CFARRngIdx
        CFARIdx(:,nn) = [jj;ii];
        nn=nn+1;
    end
end