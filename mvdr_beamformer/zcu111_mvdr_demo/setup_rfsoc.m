% This script was auto-generated from the HDL Coder Workflow Advisor for the ZCU111 and ZCU216
% Edit this script as necessary to conform to your design specification or settings
%
%   Copyright 2021 The MathWorks, Inc.


%% Instantiate object and basic settings
IPAddr = '192.168.1.101';
rfobj = soc.RFDataConverter('ZU28DR',IPAddr);

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
FPGAClockRate = ADCSamplingRate/DecimationFactor/rfobj.FPGASamplesPerClock;
if FPGAClockRate > 245.76
    warning('Selected FPGA rate %3.3f MHz exceeds the timing that was used during synthesis (%3.3f MHz) for this design! Timing failures may occur which can lead to unexpected behavior. Re-synthesizing your design may be required to achieve faster rates.',...
            FPGAClockRate,245.76);
end

%% Establish TCP/IP connection
setup(rfobj)

%% Tile / Channels

%% Set External Clocking Options
%% Set required clocks for MTS
rfobj.LMKClkSelect = 'SYSREF';
rfobj.configureLMXPLL(ReferenceClock);



%% Setup ADC/DAC Tile sampling and PLL rates
for TileId = 0:(rfobj.TotalADCTiles-1)
	rfobj.configureADCTile(TileId,PLLSrc,ReferenceClock,ADCSamplingRate);
    for ChId = 0:(rfobj.ADCChannelsPerTile-1)
		rfobj.configureADCChannel(TileId,ChId,DecimationFactor);
    end
end

for TileId = 0:(rfobj.TotalDACTiles-1)
    rfobj.configureDACTile(TileId,PLLSrc,ReferenceClock,DACSamplingRate);
    for ChId = 0:(rfobj.DACChannelsPerTile-1)        
		rfobj.configureDACChannel(TileId,ChId,InterpolationFactor);        
    end
end

%% ADC IQ mode settings 

ADC_DDC_LO = -DDC_DUC_LO; 
ADC_MixingScale = '1';
ADC_MixerPhase = 0.0;

if rfobj.MTSConfigure
    EventMode = 'Sysref';
else   
    EventMode = 'Tile';
end

for TileId = 0:(rfobj.TotalADCTiles-1)
    for ChId = 0:(rfobj.ADCChannelsPerTile-1)           
        if FineMixMode %Fine Mixing Mode            
			configureADCMixer(rfobj, TileId, ChId, 'Fine', ADC_DDC_LO, EventMode, ADC_MixerPhase, ADC_MixingScale); 
        else %Coarse Mixing Mode
			configureADCMixer(rfobj, TileId, ChId, 'Coarse', '-Fs/4', EventMode, ADC_MixerPhase, ADC_MixingScale); 
        end
    end
end

%% DAC IQ mode settings 

DAC_DDC_LO = DDC_DUC_LO;
DAC_MixingScale = '1';
DAC_MixerPhase = 0.0;

if rfobj.MTSConfigure
    EventMode = 'Sysref';
else   
    EventMode = 'Immediate';
end

for TileId = 0:(rfobj.TotalDACTiles-1)
    for ChId = 0:(rfobj.DACChannelsPerTile-1) 
		if FineMixMode %Fine Mixing Mode            
			configureDACMixer(rfobj, TileId, ChId, 'Fine', DAC_DDC_LO, EventMode, DAC_MixerPhase, DAC_MixingScale); 
        else %Coarse Mixing Mode
			configureDACMixer(rfobj, TileId, ChId, 'Coarse', 'Fs/4', EventMode, DAC_MixerPhase, ADC_MixingScale); 
        end
    end

end




%% Apply settings to RFTool
applyConfiguration(rfobj)



%% Perform MTS capture
rfobj.enableMTS()

%% Disconnect and clear system object
release(rfobj)

