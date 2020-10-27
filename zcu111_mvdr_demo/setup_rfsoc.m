% This script was auto-generated from the HDL Coder Workflow Advisor for the ZCU111
% Edit this script as necessary to conform to your design specification or settings

%% Instantiate object and basic settings
rfobj = ZynqRF.comm.rfcontrol;
rfobj.RemoteIPAddr = '192.168.1.101';
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
rfobj.SetLMXExtPLL(ReferenceClock);



%% Setup ADC Tile sampling and PLL rates

% Tile 1 ADC
rfobj.Tile1_ADC.PLLSrc = PLLSrc;
rfobj.Tile1_ADC.PLLReferenceClk = ReferenceClock;
rfobj.Tile1_ADC.PLLSampleRate = ADCSamplingRate;
rfobj.Tile1_ADC.Ch0.DecimationMode = DecimationFactor;
rfobj.Tile1_ADC.Ch1.DecimationMode = DecimationFactor;

% Tile 2 ADC
rfobj.Tile2_ADC.PLLSrc = PLLSrc;
rfobj.Tile2_ADC.PLLReferenceClk = ReferenceClock;
rfobj.Tile2_ADC.PLLSampleRate = ADCSamplingRate;
rfobj.Tile2_ADC.Ch0.DecimationMode = DecimationFactor;
rfobj.Tile2_ADC.Ch1.DecimationMode = DecimationFactor;

% Tile 3 ADC
rfobj.Tile3_ADC.PLLSrc = PLLSrc;
rfobj.Tile3_ADC.PLLReferenceClk = ReferenceClock;
rfobj.Tile3_ADC.PLLSampleRate = ADCSamplingRate;
rfobj.Tile3_ADC.Ch0.DecimationMode = DecimationFactor;
rfobj.Tile3_ADC.Ch1.DecimationMode = DecimationFactor;

% Tile 4 ADC
rfobj.Tile4_ADC.PLLSrc = PLLSrc;
rfobj.Tile4_ADC.PLLReferenceClk = ReferenceClock;
rfobj.Tile4_ADC.PLLSampleRate = ADCSamplingRate;
rfobj.Tile4_ADC.Ch0.DecimationMode = DecimationFactor;
rfobj.Tile4_ADC.Ch1.DecimationMode = DecimationFactor;

%% Setup DAC Tiles sampling and PLL rates

% Tile 1 DAC
rfobj.Tile1_DAC.PLLSrc = PLLSrc;
rfobj.Tile1_DAC.PLLReferenceClk = ReferenceClock;
rfobj.Tile1_DAC.PLLSampleRate = DACSamplingRate;
rfobj.Tile1_DAC.Ch0.InterpolationMode = InterpolationFactor;
rfobj.Tile1_DAC.Ch1.InterpolationMode = InterpolationFactor;
rfobj.Tile1_DAC.Ch2.InterpolationMode = InterpolationFactor;
rfobj.Tile1_DAC.Ch3.InterpolationMode = InterpolationFactor;

% Tile 1 DAC
rfobj.Tile2_DAC.PLLSrc = PLLSrc;
rfobj.Tile2_DAC.PLLReferenceClk = ReferenceClock;
rfobj.Tile2_DAC.PLLSampleRate = DACSamplingRate;
rfobj.Tile2_DAC.Ch0.InterpolationMode = InterpolationFactor;
rfobj.Tile2_DAC.Ch1.InterpolationMode = InterpolationFactor;
rfobj.Tile2_DAC.Ch2.InterpolationMode = InterpolationFactor;
rfobj.Tile2_DAC.Ch3.InterpolationMode = InterpolationFactor;


%% ADC IQ mode settings 

ADC_DDC_LO = -DDC_DUC_LO; 
AdcTileArr = {rfobj.Tile1_ADC,...
              rfobj.Tile2_ADC,...
              rfobj.Tile3_ADC,...
              rfobj.Tile4_ADC};
          
ADC_IQ_To_Real_Format = 'Real->IQ'; 

if rfobj.MTSConfigure
    EventMode = 'Sysref';
else   
    EventMode = 'Tile';
end

ADC_MixingScale = '1';
ADC_MixerPhase = 0.0;
for TileIdx = 1:rfobj.ADCNumTiles
    
    AdcTileArr{TileIdx}.Ch0.MixerSettings.DataFormatType = 'IQ';
    AdcTileArr{TileIdx}.Ch1.MixerSettings.DataFormatType = 'IQ';
    
    if FineMixMode %Fine Mixing Mode
        
        AdcTileArr{TileIdx}.Ch0.MixerSettings.MixerType = 'Fine';
        AdcTileArr{TileIdx}.Ch0.MixerSettings.MixerMode = ADC_IQ_To_Real_Format;
        AdcTileArr{TileIdx}.Ch0.MixerSettings.NCOFrequency = ADC_DDC_LO;
        AdcTileArr{TileIdx}.Ch0.MixerSettings.NCOPhase = ADC_MixerPhase;
        AdcTileArr{TileIdx}.Ch0.MixerSettings.EventSource = EventMode;
        AdcTileArr{TileIdx}.Ch0.MixerSettings.FineMixerScale = ADC_MixingScale;
        
        AdcTileArr{TileIdx}.Ch1.MixerSettings.MixerType = 'Fine';
        AdcTileArr{TileIdx}.Ch1.MixerSettings.MixerMode = ADC_IQ_To_Real_Format;
        AdcTileArr{TileIdx}.Ch1.MixerSettings.NCOFrequency = ADC_DDC_LO;
        AdcTileArr{TileIdx}.Ch1.MixerSettings.NCOPhase = ADC_MixerPhase;
        AdcTileArr{TileIdx}.Ch1.MixerSettings.EventSource = EventMode;
        AdcTileArr{TileIdx}.Ch1.MixerSettings.FineMixerScale = ADC_MixingScale;
        
    else %Coarse Mixing Mode
        
        AdcTileArr{TileIdx}.Ch0.MixerSettings.MixerType = 'Coarse';
        AdcTileArr{TileIdx}.Ch0.MixerSettings.MixerMode = ADC_IQ_To_Real_Format;
        AdcTileArr{TileIdx}.Ch0.MixerSettings.CoarseFreq = '-Fs/4';     
        AdcTileArr{TileIdx}.Ch0.MixerSettings.EventSource = EventMode;
        
        AdcTileArr{TileIdx}.Ch1.MixerSettings.MixerType = 'Coarse';
        AdcTileArr{TileIdx}.Ch1.MixerSettings.MixerMode = ADC_IQ_To_Real_Format;
        AdcTileArr{TileIdx}.Ch1.MixerSettings.CoarseFreq = '-Fs/4';
        AdcTileArr{TileIdx}.Ch1.MixerSettings.EventSource = EventMode;
        
    end
end

%% DAC IQ mode settings 

DAC_DUC_FREQ = DDC_DUC_LO;
DacTileArr = {rfobj.Tile1_DAC,...
              rfobj.Tile2_DAC};
          
DAC_IQ_To_Real_Format = 'IQ->Real';          
DAC_MixingScale = '1';
DAC_MixerPhase = 0.0;

if rfobj.MTSConfigure
    EventMode = 'Sysref';
else   
    EventMode = 'Immediate';
end

for TileIdx = 1:rfobj.DACNumTiles
    DacTileArr{TileIdx}.Ch0.MixerSettings.DataFormatType = 'IQ';
    DacTileArr{TileIdx}.Ch1.MixerSettings.DataFormatType = 'IQ';
    DacTileArr{TileIdx}.Ch2.MixerSettings.DataFormatType = 'IQ';
    DacTileArr{TileIdx}.Ch3.MixerSettings.DataFormatType = 'IQ';
    
    if FineMixMode %Fine Mixing Mode
        DacTileArr{TileIdx}.Ch0.MixerSettings.MixerType = 'Fine';
        DacTileArr{TileIdx}.Ch0.MixerSettings.MixerMode = DAC_IQ_To_Real_Format;
        DacTileArr{TileIdx}.Ch0.MixerSettings.NCOFrequency = DAC_DUC_FREQ;
        DacTileArr{TileIdx}.Ch0.MixerSettings.NCOPhase = DAC_MixerPhase;
        DacTileArr{TileIdx}.Ch0.MixerSettings.FineMixerScale = DAC_MixingScale; 
        DacTileArr{TileIdx}.Ch0.MixerSettings.EventSource = EventMode;
       

        DacTileArr{TileIdx}.Ch1.MixerSettings.MixerType = 'Fine';
        DacTileArr{TileIdx}.Ch1.MixerSettings.MixerMode = DAC_IQ_To_Real_Format;
        DacTileArr{TileIdx}.Ch1.MixerSettings.NCOFrequency = DAC_DUC_FREQ;
        DacTileArr{TileIdx}.Ch1.MixerSettings.NCOPhase = DAC_MixerPhase;
        DacTileArr{TileIdx}.Ch1.MixerSettings.FineMixerScale = DAC_MixingScale; 
        DacTileArr{TileIdx}.Ch1.MixerSettings.EventSource = EventMode;
       

        DacTileArr{TileIdx}.Ch2.MixerSettings.MixerType = 'Fine';
        DacTileArr{TileIdx}.Ch2.MixerSettings.MixerMode = DAC_IQ_To_Real_Format;
        DacTileArr{TileIdx}.Ch2.MixerSettings.NCOFrequency = DAC_DUC_FREQ;
        DacTileArr{TileIdx}.Ch2.MixerSettings.NCOPhase = DAC_MixerPhase;
        DacTileArr{TileIdx}.Ch2.MixerSettings.FineMixerScale = DAC_MixingScale;
        DacTileArr{TileIdx}.Ch2.MixerSettings.EventSource = EventMode;
     

        DacTileArr{TileIdx}.Ch3.MixerSettings.MixerType = 'Fine';
        DacTileArr{TileIdx}.Ch3.MixerSettings.MixerMode = DAC_IQ_To_Real_Format;
        DacTileArr{TileIdx}.Ch3.MixerSettings.NCOFrequency = DAC_DUC_FREQ;
        DacTileArr{TileIdx}.Ch3.MixerSettings.NCOPhase = DAC_MixerPhase;
        DacTileArr{TileIdx}.Ch3.MixerSettings.FineMixerScale = DAC_MixingScale;
        DacTileArr{TileIdx}.Ch3.MixerSettings.EventSource = EventMode;
      

    else %Coarse Mixing Mode
        DacTileArr{TileIdx}.Ch0.MixerSettings.MixerType = 'Coarse';
        DacTileArr{TileIdx}.Ch0.MixerSettings.MixerMode = DAC_IQ_To_Real_Format;
        DacTileArr{TileIdx}.Ch0.MixerSettings.CoarseFreq = 'Fs/4';       
        DacTileArr{TileIdx}.Ch0.MixerSettings.EventSource = EventMode;       
        
        DacTileArr{TileIdx}.Ch1.MixerSettings.MixerType = 'Coarse';
        DacTileArr{TileIdx}.Ch1.MixerSettings.MixerMode = DAC_IQ_To_Real_Format;
        DacTileArr{TileIdx}.Ch1.MixerSettings.CoarseFreq = 'Fs/4';
        DacTileArr{TileIdx}.Ch1.MixerSettings.EventSource = EventMode;   
        
        DacTileArr{TileIdx}.Ch2.MixerSettings.MixerType = 'Coarse';
        DacTileArr{TileIdx}.Ch2.MixerSettings.MixerMode = DAC_IQ_To_Real_Format;
        DacTileArr{TileIdx}.Ch2.MixerSettings.CoarseFreq = 'Fs/4';       
        DacTileArr{TileIdx}.Ch2.MixerSettings.EventSource = EventMode;   
        
        DacTileArr{TileIdx}.Ch3.MixerSettings.MixerType = 'Coarse';
        DacTileArr{TileIdx}.Ch3.MixerSettings.MixerMode = DAC_IQ_To_Real_Format;
        DacTileArr{TileIdx}.Ch3.MixerSettings.CoarseFreq = 'Fs/4';
        DacTileArr{TileIdx}.Ch3.MixerSettings.EventSource = EventMode;   
    end

end



%% Apply settings to RFTool
step(rfobj)



%% Perform MTS capture
rfobj.SetupMTS()

%% Disconnect and clear system object
release(rfobj)

