%run_Range_Doppler Testbench for Range Doppler processing

%% Parameters

% Common parameters
range_doppler_system_param_init;

% Number of coherent processing intervals (CPI) to run
NumCPI = 10;

%% Setup processing blocks
% Create radar data cube
radarDataCube = createRadarDataCubeMod(...
    txSignalFullPeriod,antennaElement,Fs,Fc, ...
    targetPos, targetVel, targetRCS, ...
    RngMax, RxActiveTime, RngGate, ...
    CPILength, NumCPI, CPILength*pulsePeriod);

% Range Doppler processing
RangeDopplerResponse = phased.RangeDopplerResponse( ...
    'OperatingFrequency', Fc, ...
    'RangeMethod','Matched filter', ...
    'PropagationSpeed', propSpeed, ...
    'SampleRate', Fs, ...
    'DopplerFFTLengthSource','Property', ...
    'DopplerFFTLength', VelDimLen, ...
    'DopplerWindow', 'Hamming', ...
    'DopplerOutput', 'Speed');


%% Simulate radar targets and run Range Doppler processing

hd = dfilt.dffir(matchingCoeff.');
for CPIIdx = 1:NumCPI
    cubeSegment = radarDataCube(:,:,CPIIdx);    
    cubeSegmentMatched =  zeros(RxActiveSamples,CPILength);
    
    % Matched Filter
    for ii = 1:CPILength
        cubeSegmentMatched(:,ii) = filter(hd,cubeSegment(:,ii));
    end
    
    % Transpose
    cubeTranspose = transpose(cubeSegmentMatched);
    
    % FFT
    cubeTransposeFFT = fft(cubeTranspose.*hamming(64),64,1);
    cubeOutput = fftshift(transpose(cubeTransposeFFT),2);
    cubeOutput = 20*log10(abs(cubeOutput));
    
    % Display Targets
    displayTargets(VelMax, RngMin, RngMax, cubeOutput);
   
    pause(0.5);
end


function displayTargets(VelMax, RngMin, RngMax, rangeDopplerInput)
    imagesc([-VelMax VelMax],[RngMin RngMax],rangeDopplerInput);
    title('Range-Doppler');
    xlabel('Velocity');
    ylabel('Range');
end



