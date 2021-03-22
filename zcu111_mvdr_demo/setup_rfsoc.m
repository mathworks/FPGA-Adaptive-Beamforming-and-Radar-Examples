% This script was auto-generated from the HDL Coder Workflow Advisor for the ZCU111
% Edit this script as necessary to conform to your design specification or settings

%% Instantiate object and basic settings
rfobj = soc.RFDataConverter('zu28dr','192.168.1.101');
rfobj.MTSConfigure = true;

PLLSrc = 'External LMK/LMX';
ReferenceClock = 1966.08; % MHz 
ADCSamplingRate = 1966.08; % MHz 
DACSamplingRate = 1966.08; % MHz 
DecimationFactor = 8;
InterpolationFactor = 8;
DDC_DUC_LO = ADCSamplingRate/4; % MHz - Define LO Frequency (MHz) here
FineMixMode = true; 

%% User FPGA-logic settings
% Do not change
rfobj.FPGASamplesPerClock = 1;
rfobj.ConverterClockRatio = 2;

% Check if FPGA clock-rate exceeds timing used during synthesis
FPGAClockRate = ADCSamplingRate/DecimationFactor/1;
if FPGAClockRate > 245.76
    warning('Selected FPGA rate %3.3f MHz exceeds the timing that was used during synthesis (%3.3f MHz) for this design! Timing failures may occur which can lead to unexpected behavior. Re-synthesizing your design may be required to achieve faster rates.',...
            FPGAClockRate,245.76);
end

%% Establish TCP/IP connection
setup(rfobj)

%% Set required clocks for MTS
rfobj.LMKClkSelect = 'SYSREF';
rfobj.configureLMXPLL(ReferenceClock);



%% Setup ADC Tile sampling and PLL rates

% Tile 1 ADC
% syntax: configureADCTile(obj, tileId, PLLSrc, PLLRefClk, samplingRate)
configureADCTile(rfobj,1,PLLSrc,ReferenceClock,ADCSamplingRate);
% syntax: configureADCChannel(obj, tileId, channelID, decimationFactor)
configureADCChannel(rfobj, 1, 1, DecimationFactor); % Channel 1
configureADCChannel(rfobj, 1, 2, DecimationFactor); % Channel 2

% Tile 2 ADC
% syntax: configureADCTile(obj, tileId, PLLSrc, PLLRefClk, samplingRate)
configureADCTile(rfobj,2,PLLSrc,ReferenceClock,ADCSamplingRate);
% syntax: configureADCChannel(obj, tileId, channelID, decimationFactor)
configureADCChannel(rfobj, 2, 1, DecimationFactor); % Channel 1
configureADCChannel(rfobj, 2, 2, DecimationFactor); % Channel 2

% Tile 3 ADC
% syntax: configureADCTile(obj, tileId, PLLSrc, PLLRefClk, samplingRate)
configureADCTile(rfobj,3,PLLSrc,ReferenceClock,ADCSamplingRate);
% syntax: configureADCChannel(obj, tileId, channelID, decimationFactor)
configureADCChannel(rfobj, 3, 1, DecimationFactor); % Channel 1
configureADCChannel(rfobj, 3, 2, DecimationFactor); % Channel 2

% Tile 4 ADC
% syntax: configureADCTile(obj, tileId, PLLSrc, PLLRefClk, samplingRate)
configureADCTile(rfobj,4,PLLSrc,ReferenceClock,ADCSamplingRate);
% syntax: configureADCChannel(obj, tileId, channelID, decimationFactor)
configureADCChannel(rfobj, 4, 1, DecimationFactor); % Channel 1
configureADCChannel(rfobj, 4, 2, DecimationFactor); % Channel 2

%% Setup DAC Tiles sampling and PLL rates

% Tile 1 DAC
% syntax: configureDACTile(obj, tileId, PLLSrc, PLLRefClk, samplingRate)
configureDACTile(rfobj,1,PLLSrc,ReferenceClock,DACSamplingRate);
% syntax: configureDACChannel(obj, tileId, channelID, interpolationFactor)
configureDACChannel(rfobj, 1, 1, InterpolationFactor); % Channel 1
configureDACChannel(rfobj, 1, 2, InterpolationFactor); % Channel 2
configureDACChannel(rfobj, 1, 3, InterpolationFactor); % Channel 3
configureDACChannel(rfobj, 1, 4, InterpolationFactor); % Channel 4

% Tile 2 DAC
% syntax: configureDACTile(obj, tileId, PLLSrc, PLLRefClk, samplingRate)
configureDACTile(rfobj,2,PLLSrc,ReferenceClock,DACSamplingRate);
% syntax: configureDACChannel(obj, tileId, channelID, interpolationFactor)
configureDACChannel(rfobj, 2, 1, InterpolationFactor); % Channel 1
configureDACChannel(rfobj, 2, 2, InterpolationFactor); % Channel 2
configureDACChannel(rfobj, 2, 3, InterpolationFactor); % Channel 3
configureDACChannel(rfobj, 2, 4, InterpolationFactor); % Channel 4


%% ADC IQ mode settings 

ADC_DDC_LO = -DDC_DUC_LO; 
          

if rfobj.MTSConfigure
    EventMode = 'Sysref';
else   
    EventMode = 'Tile';
end

ADC_MixingScale = '1';
ADC_MixerPhase = 0.0;
for TileIdx = 1:rfobj.TotalADCTiles
    
    if FineMixMode %Fine Mixing Mode
        
        % syntax: configureADCMixer(obj, tileId, channelID, mixerType, mixerFrequency, eventSource, NCOPhase, fineMixerScale)
        configureADCMixer(rfobj, TileIdx, 1, 'Fine', ADC_DDC_LO, EventMode, ADC_MixerPhase, ADC_MixingScale); % Channel 1
        configureADCMixer(rfobj, TileIdx, 2, 'Fine', ADC_DDC_LO, EventMode, ADC_MixerPhase, ADC_MixingScale); % Channel 2
        
    else %Coarse Mixing Mode
        
        % syntax: configureADCMixer(obj, tileId, channelID, mixerType, mixerFrequency, eventSource)
        configureADCMixer(rfobj, TileIdx, 1, 'Coarse', '-Fs/4', EventMode); % Channel 1
        configureADCMixer(rfobj, TileIdx, 2, 'Coarse', '-Fs/4', EventMode); % Channel 2
        
    end
end

%% DAC IQ mode settings 

DAC_DUC_FREQ = DDC_DUC_LO;
          
DAC_MixingScale = '1';
DAC_MixerPhase = 0.0;

if rfobj.MTSConfigure
    EventMode = 'Sysref';
else   
    EventMode = 'Immediate';
end

for TileIdx = 1:rfobj.TotalDACTiles
    
    if FineMixMode %Fine Mixing Mode
        % syntax: configureDACMixer(obj, tileId, channelId, mixerType, mixerFrequency, eventSource, NCOPhase, fineMixerScale)
        configureDACMixer(rfobj, TileIdx, 1, 'Fine', DAC_DUC_FREQ, EventMode, DAC_MixerPhase, DAC_MixingScale); % Channel 1
        configureDACMixer(rfobj, TileIdx, 2, 'Fine', DAC_DUC_FREQ, EventMode, DAC_MixerPhase, DAC_MixingScale); % Channel 2
        configureDACMixer(rfobj, TileIdx, 3, 'Fine', DAC_DUC_FREQ, EventMode, DAC_MixerPhase, DAC_MixingScale); % Channel 3
        configureDACMixer(rfobj, TileIdx, 4, 'Fine', DAC_DUC_FREQ, EventMode, DAC_MixerPhase, DAC_MixingScale); % Channel 4
      

    else %Coarse Mixing Mode
        % syntax: configureDACMixer(obj, tileId, channelId, mixerType, mixerFrequency, eventSource)
        configureDACMixer(rfobj, TileIdx, 1, 'Coarse', 'Fs/4', EventMode); % Channel 1
        configureDACMixer(rfobj, TileIdx, 2, 'Coarse', 'Fs/4', EventMode); % Channel 2
        configureDACMixer(rfobj, TileIdx, 3, 'Coarse', 'Fs/4', EventMode); % Channel 3
        configureDACMixer(rfobj, TileIdx, 4, 'Coarse', 'Fs/4', EventMode); % Channel 4
    end

end



%% Apply settings to RFTool
applyConfiguration(rfobj)



%% Perform MTS capture
rfobj.enableMTS()

%% Disconnect and clear system object
release(rfobj)

