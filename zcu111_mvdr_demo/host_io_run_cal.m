%% Run calibration

% Make sure init script ran
if ~exist('REG_MAP','var')
    host_io_init;
end

fprintf('Running channel calbration...\n');

% Register init
regWr_TxNCOInc([2666 3333]);
regWr_TxNCOGain([0.8 0]);
regWr_Tx1CoeffRe(ones(4,1));
regWr_Tx1CoeffIm(ones(4,1));
regWr_Tx2CoeffRe(ones(4,1));
regWr_Tx2CoeffIm(ones(4,1));
regWr_RxCalCoeffRe(ones(4,1));
regWr_RxCalCoeffIm(ones(4,1));
regWr_RxCoeffRe(ones(4,1));
regWr_RxCoeffIm(ones(4,1));

% Bypass MVDR output to receive raw ADC channel data
regWr(true,REG_MAP.BypassMVDR);
regWr(false,REG_MAP.BypassAnalog);

% Trigger a capture
regWr(true,REG_MAP.rx_capture_trig);
regWr(false,REG_MAP.rx_capture_trig);

% Read a frame
data = streamRd();

% Unpack uint32 to complex int16
data = unpack_complex(data);

% Reshape into individual channels
data = reshape(data,4,[]);

% Make channels as columns
data = transpose(data);

% In-memory ordering is ch4, ch3, ch2, ch1 so we flip
data = fliplr(data); 

% Get calibration coefficients
cal_coeffs = calibrate_channels(data);

% Apply calibration coefficients
regWr_RxCalCoeffRe(real(cal_coeffs));
regWr_RxCalCoeffIm(imag(cal_coeffs));

calDone = true;