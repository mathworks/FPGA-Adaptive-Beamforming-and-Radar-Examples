%% Call setup scripts

if ~exist('REG_MAP','var')
    host_io_init;
end
if ~calDone
    host_io_run_cal; 
end

%% Derived parameters
fc_sv = fc + SignalFreq*1e6;
TxNCOFreqs = [SignalFreq InterfererFreq]*1e6;
TxNCOGains = 10.^([SignalGain InterfererGain]/20);
TxNCOInc = floor(TxNCOFreqs*(2^NCO_bits/DataSampleRate));
RxCoeff =  steeringVector(fc_sv,[SignalAngle; 0]);
Tx1Coeff =  steeringVector(fc_sv,[SignalAngle; 0]);
Tx2Coeff =  steeringVector(fc_sv,[InterfererAngle; 0]);

%% Parameter check
assert(all(TxNCOFreqs > 0));
assert(all(abs(TxNCOGains) <= 1));

%% Register setup

regWr(false,REG_MAP.BypassMVDR);
regWr(BypassAnalog,REG_MAP.BypassAnalog);
regWr_TxNCOInc(TxNCOInc);
regWr_TxNCOGain(TxNCOGains);
regWr_Tx1CoeffRe(real(Tx1Coeff));
regWr_Tx1CoeffIm(imag(Tx1Coeff));
regWr_Tx2CoeffRe(real(Tx2Coeff));
regWr_Tx2CoeffIm(imag(Tx2Coeff));
regWr_RxCoeffRe(real(RxCoeff));
regWr_RxCoeffIm(imag(RxCoeff));

if strcmp(viewerUpdateTimer.Running,'off')
    start(viewerUpdateTimer);
end
if ~hSpecAn.isVisible
   show(hSpecAn);
end
