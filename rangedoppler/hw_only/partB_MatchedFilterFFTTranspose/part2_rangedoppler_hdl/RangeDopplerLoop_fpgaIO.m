%--------------------------------------------------------------------------
% Constant Design parameters 
% 
%--------------------------------------------------------------------------
N1 = 256; % row
N2 = 64; % columns


%--------------------------------------------------------------------------
% Adjustable Design parameters 
% 
%--------------------------------------------------------------------------
% init parameters
range_doppler_system_param_init; 

% Number of coherent processing intervals (CPI) to run
NumCPI = 10;

% Create radar data cube
radarDataCube = createRadarDataCubeMod(...
    txSignalFullPeriod,antennaElement,Fs,Fc, ...
    targetPos, targetVel, targetRCS, ...
    RngMax, RxActiveTime, RngGate, ...
    CPILength, NumCPI, CPILength*pulsePeriod);

enableFullMatrixWrite = true;
debugInputFrame = false;

%% Create fpga object
hFPGA = fpga("Xilinx");


%% Setup fpga object
% This function configures the "fpga" object with the same interfaces as the generated IP core
frameLenWrite = 256*64;
frameLenRead = 256*64;

setup_fpgaIO(hFPGA,frameLenWrite,frameLenRead);
writePort(hFPGA, "resetIP", true);

debugRegInput.bypassFFT = false;
debugRegInput.bypassMatchedFilter = false;
writePort(hFPGA, "debugRegInput", debugRegInput);

%% Create Radar Cube frame
radarDataCube_fi = packBits(radarDataCube);
radarDataCube_fi_mat = reshape(radarDataCube_fi,256,64,NumCPI);
radarDataCube_fi_mat = fi(radarDataCube_fi_mat,0,64,0);

%% Setup Rx DMA
% setup rx dma by invoking a read. If this is not done then the DMA will
% NOT be setup to get data correctly and the first frame will get
% corrupted!
data_any = readPort(hFPGA, "axis_s2mm_tdata");

%% Write frame
for ii = 1:NumCPI 
    
    % Extract a radar cube slice
    waveformExtract = radarDataCube_fi_mat(:,:,ii);
    
    % Write the radar cube slice to FPGA as DMA data
    writePort(hFPGA, "axis_mm2s_tdata", waveformExtract(:));
    
    % Print some debug messages
    data_debugRead = readPort(hFPGA, "debugRead");
    data_ddrDoneCounter = readPort(hFPGA, "ddrDoneCounter");
    measuredValidCount = data_debugRead.FIFO_ValidWriteCount;
    fprintf('Total samples written to PL DDR4 memory = %d \n',double(measuredValidCount));    
    fprintf('DDR4 write count = %d \n', uint32(data_ddrDoneCounter));
    
    % Read back result of range-doppler data
    rangeDopplerRead = readPort(hFPGA, "axis_s2mm_tdata");
 
    % Format data to expected fixed-point complex data type format
    re = reinterpretcast(bitsliceget(rangeDopplerRead,32,1),numerictype(1,32,21)) ;
    imag = reinterpretcast(bitsliceget(rangeDopplerRead,64,33),numerictype(1,32,21)) ;
    rdMat = complex(re,imag);
        
    % Plot range-doppler
    img = reshape(double(rdMat),64,256);
    cubeOutput = fftshift(transpose(img),2);
    cubeOutput = 20*log10(abs(cubeOutput));

    imagesc([-VelMax VelMax],[RngMin RngMax],cubeOutput);
    title('Range-Doppler');
    xlabel('Velocity');
    ylabel('Range');
    colorbar;
    drawnow
end

%% Some debug port statements
data_debugRead = readPort(hFPGA, "debugRead");
fprintf('Number of samples FIFO outputted = %d \n',data_debugRead.FIFO_ValidWriteCount);
fprintf('Number of DDR4 write bursts completed = %d \n',data_debugRead.AXI4M_WrValidCnt);
fprintf('Number of times BRAM FSM  paused input FIFO = %d \n',data_debugRead.BRAM_FSM_StoppingFIFO_Counter);
fprintf('Number of lost samples = %d \n',data_debugRead.FIFO_LostSampleCount);
fprintf('Number of times back-pressure applied on MM2S DMA = %d \n',data_debugRead.FIFO_BackPressureAppliedOnMM2S);
fprintf('Number of times input FIFO was full = %d \n',data_debugRead.FIFO_FullEventCount);



%% Release hardware resources
release(hFPGA);


%% Helper functions

function output = packBits(waveformInput)

    waveformInput_fi = fi(waveformInput,1,20,18);
    % [real(waveformInput_fi) imag(waveformInput_fi)]
    output = bitconcat(real(waveformInput_fi(:)),imag(waveformInput_fi(:)));

end


