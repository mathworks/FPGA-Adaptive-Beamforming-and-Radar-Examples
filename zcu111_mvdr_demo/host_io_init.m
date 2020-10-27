model_init;

IPAddress = '192.168.1.101';

FrameSize = 10e3;
S2MM_frame_size = FrameSize*4; % 128bit DMA, read as 32bit

%% Register mapping from HDL WFA
REG_MAP = struct();
REG_MAP.IPCore_PacketSize = hex2dec('008');
REG_MAP.rx_capture_trig = hex2dec('100');
REG_MAP.rx_frame_size = hex2dec('104');
REG_MAP.rx_stream_en = hex2dec('108');
REG_MAP.rx_trigger_freq = hex2dec('10C');
REG_MAP.rx_auto_trig_en = hex2dec('110');
REG_MAP.S2MM_BackPressure_Count = hex2dec('114');
REG_MAP.BypassMVDR = hex2dec('118');
REG_MAP.BypassAnalog = hex2dec('11C');
REG_MAP.tx_nco_increment = hex2dec('120');
REG_MAP.tx_nco_gain = hex2dec('160');
REG_MAP.tx_steering_coeffs_tone1_re = hex2dec('170');
REG_MAP.tx_steering_coeffs_tone1_im = hex2dec('190');
REG_MAP.tx_steering_coeffs_tone2_re = hex2dec('130');
REG_MAP.tx_steering_coeffs_tone2_im = hex2dec('1B0');
REG_MAP.rx_steering_coeffs_re = hex2dec('1D0');
REG_MAP.rx_steering_coeffs_im = hex2dec('1F0');
REG_MAP.rx_cal_coeffs_re = hex2dec('210');
REG_MAP.rx_cal_coeffs_im = hex2dec('230');

%% IIO object init

streamRd = pspshared.libiio.axistream.read('IPAddress',IPAddress,...
    'SamplesPerFrame',S2MM_frame_size,'DataType','uint32','Timeout',0,...
    'TLASTMode','user_logic');
setup(streamRd);

regWr = pspshared.libiio.aximm.write('IPAddress',IPAddress,...
    'AddressOffsetSrc','Input port');
setup(regWr,uint32(0),0);

% Tx NCO
regWr_TxNCOInc = pspshared.libiio.aximm.write('IPAddress',IPAddress,...
    'AddressOffset',REG_MAP.tx_nco_increment,'vectorModeEn',true);
setup(regWr_TxNCOInc,fi(zeros(2,1), 0,14,0));
regWr_TxNCOGain = pspshared.libiio.aximm.write('IPAddress',IPAddress,...
    'AddressOffset',REG_MAP.tx_nco_gain,'vectorModeEn',true);
setup(regWr_TxNCOGain,fi(zeros(2,1), 1,16,15));

% Rx Steering Coeff
regWr_RxCoeffRe = pspshared.libiio.aximm.write('IPAddress',IPAddress,...
    'AddressOffset',REG_MAP.rx_steering_coeffs_re,'vectorModeEn',true);
setup(regWr_RxCoeffRe,fi(zeros(4,1), sv_dt));
regWr_RxCoeffIm = pspshared.libiio.aximm.write('IPAddress',IPAddress,...
    'AddressOffset',REG_MAP.rx_steering_coeffs_im,'vectorModeEn',true);
setup(regWr_RxCoeffIm,fi(zeros(4,1), sv_dt));

% Rx Calibration Coeff
regWr_RxCalCoeffRe = pspshared.libiio.aximm.write('IPAddress',IPAddress,...
    'AddressOffset',REG_MAP.rx_cal_coeffs_re,'vectorModeEn',true);
setup(regWr_RxCalCoeffRe,fi(zeros(4,1), coeff_dt));
regWr_RxCalCoeffIm = pspshared.libiio.aximm.write('IPAddress',IPAddress,...
    'AddressOffset',REG_MAP.rx_cal_coeffs_im,'vectorModeEn',true);
setup(regWr_RxCalCoeffIm,fi(zeros(4,1), coeff_dt));

% Tx 1 Coeff
regWr_Tx1CoeffRe = pspshared.libiio.aximm.write('IPAddress',IPAddress,...
    'AddressOffset',REG_MAP.tx_steering_coeffs_tone1_re,'vectorModeEn',true);
setup(regWr_Tx1CoeffRe,fi(zeros(4,1), coeff_dt));
regWr_Tx1CoeffIm = pspshared.libiio.aximm.write('IPAddress',IPAddress,...
    'AddressOffset',REG_MAP.tx_steering_coeffs_tone1_im,'vectorModeEn',true);
setup(regWr_Tx1CoeffIm,fi(zeros(4,1), coeff_dt));

% Tx 2 Coeff
regWr_Tx2CoeffRe = pspshared.libiio.aximm.write('IPAddress',IPAddress,...
    'AddressOffset',REG_MAP.tx_steering_coeffs_tone2_re,'vectorModeEn',true);
setup(regWr_Tx2CoeffRe,fi(zeros(4,1), coeff_dt));
regWr_Tx2CoeffIm = pspshared.libiio.aximm.write('IPAddress',IPAddress,...
    'AddressOffset',REG_MAP.tx_steering_coeffs_tone2_im,'vectorModeEn',true);
setup(regWr_Tx2CoeffIm,fi(zeros(4,1), coeff_dt));

%% Viewer setup
viewerUpdateRate = 20; % Hz
viewerUpdateTimer = timer('ExecutionMode','fixedRate',...
    'Period',round(1/viewerUpdateRate,3),'TimerFcn',@(~,~)capture_update);
hSpecAn = dsp.SpectrumAnalyzer('SampleRate', DataSampleRate,...
    'FrequencyResolutionMethod','WindowLength', 'WindowLength', S2MM_frame_size/4, ...
    'FrequencySpan','Start and stop frequencies','StartFrequency',0,...
    'StopFrequency',DataSampleRate/2);
frmWrk = hSpecAn.getFramework;
addlistener(frmWrk.Parent,'Close', @(~,~)evalin('base', 'stop(viewerUpdateTimer)'));

%% Register initialization
regWr(FrameSize,REG_MAP.IPCore_PacketSize);
regWr(false,REG_MAP.BypassAnalog);
regWr(FrameSize,REG_MAP.rx_frame_size);
regWr(true,REG_MAP.rx_stream_en);
regWr(false,REG_MAP.rx_auto_trig_en);
regWr(false,REG_MAP.rx_capture_trig);

% Cal flag
calDone = false;
