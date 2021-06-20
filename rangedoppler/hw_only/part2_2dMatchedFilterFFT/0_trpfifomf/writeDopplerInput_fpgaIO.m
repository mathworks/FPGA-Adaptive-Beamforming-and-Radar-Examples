%--------------------------------------------------------------------------
% Constant Design parameters 
% 
%--------------------------------------------------------------------------

N1 = 256; % row
N2 = 64; % columns

enableFullMatrixWrite = false;
debugInputFrame = true;
%--------------------------------------------------------------------------
% Adjustable Design parameters 
% 
%--------------------------------------------------------------------------

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

%% Create fpga object
hFPGA = fpga("Xilinx");



%% Setup fpga object
% This function configures the "fpga" object with the same interfaces as the generated IP core
if enableFullMatrixWrite
    frameLenWrite = 256*64;
    frameLenRead = 256*64;
else    
    frameLenWrite = 256;
    frameLenRead = 256*64;
end
setup_fpgaIO(hFPGA,frameLenWrite,frameLenRead);
writePort(hFPGA, "resetIP", true);

if debugInputFrame
    debugRegInput.bypassFFT = true;
    debugRegInput.bypassMatchedFilter = true;
    writePort(hFPGA, "debugRegInput", debugRegInput);
else
    debugRegInput.bypassFFT = false;
    debugRegInput.bypassMatchedFilter = false;
    writePort(hFPGA, "debugRegInput", debugRegInput);
end

%% Create frame
radarDataCube_fi = packBits(radarDataCube);
radarDataCube_fi_mat = reshape(radarDataCube_fi,256,64);
radarDataCube_fi_mat = fi(radarDataCube_fi_mat,0,64,0);

if debugInputFrame
    radarDataCube_fi = fi(1:(256*64),0,64,0);
    radarDataCube_fi_mat = reshape(radarDataCube_fi,256,64);    
end


%% Write frame
if ~enableFullMatrixWrite
    prevValidCount = 0;
    for ii = 1:64
        writePort(hFPGA, "axis_mm2s_tdata", radarDataCube_fi_mat(:,ii));
        data_debugRead = readPort(hFPGA, "debugRead");
        measuredValidCount = data_debugRead.FIFO_ValidWriteCount;
        fprintf('valid count diff = %d \n',double(measuredValidCount) - double(prevValidCount));
        prevValidCount = measuredValidCount;
    end
else
    writePort(hFPGA, "axis_mm2s_tdata", radarDataCube_fi(:));
    data_debugRead = readPort(hFPGA, "debugRead");
    measuredValidCount = data_debugRead.FIFO_ValidWriteCount;
    fprintf('valid count diff = %d \n',double(measuredValidCount) - 256*64);

end
%%  read and Unpack
rangeDopplerRead = readPort(hFPGA, "axis_s2mm_tdata");

if ~debugInputFrame
    re = reinterpretcast(bitsliceget(rangeDopplerRead,32,1),numerictype(1,32,21)) ;
    imag = reinterpretcast(bitsliceget(rangeDopplerRead,64,33),numerictype(1,32,21)) ;
    rdMat = complex(re,imag);
else
    output_data = reshape(rangeDopplerRead,64,256);
    
    % do a diff:
    
    expectedTranspose = double(radarDataCube_fi_mat.');
    plot(output_data(:) - expectedTranspose(:))
    
end
%% Write/read DUT ports
% Uncomment the following lines to write/read DUT ports in the generated IP Core.
% Update the example data in the write commands with meaningful data to write to the DUT.
%% AXI4
% writePort(hFPGA, "inputImageDDROffset", zeros([1 1]));
data_ddrDoneCounter = readPort(hFPGA, "ddrDoneCounter");
fprintf('DDR4 write count = %d \n', uint32(data_ddrDoneCounter));
data_fifo_full_event = readPort(hFPGA, "fifo_full_event");

fprintf('Number of samples FIFO outputted = %d \n',data_debugRead.FIFO_ValidWriteCount);
fprintf('Number of bursts completed for writes = %d \n',data_debugRead.AXI4M_WrValidCnt);
fprintf('Number of times BRAM FSM  paused input FIFO = %d \n',data_debugRead.BRAM_FSM_StoppingFIFO_Counter);
fprintf('Number of lost samples = %d \n',data_debugRead.FIFO_LostSampleCount);
fprintf('Number of times back-pressure applied on MM2s = %d \n',data_debugRead.FIFO_BackPressureAppliedOnMM2S);
fprintf('Number of times FIFO was full = %d \n',data_debugRead.FIFO_FullEventCount);


%%
img = reshape(double(rdMat),64,256);
 
cubeOutput = fftshift(transpose(img),2);
cubeOutput = 20*log10(abs(cubeOutput));

nexttile([1,2]);
imagesc([-VelMax VelMax],[RngMin RngMax],cubeOutput);
title('Range-Doppler');
xlabel('Velocity');
ylabel('Range');
colorbar;



%% Release hardware resources
release(hFPGA);


%% Helper functions

function output = packBits(waveformInput)

    waveformInput_fi = fi(waveformInput,1,20,18);
    % [real(waveformInput_fi) imag(waveformInput_fi)]
    output = bitconcat(real(waveformInput_fi(:)),imag(waveformInput_fi(:)));

end

function output = unpackBits(waveformInput)
    
end

