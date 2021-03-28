function dataOut = qpsk_receive(dataIn, ...
    FrameLength, SamplesPerSymbol, PreambleLength, ...
    mfCoeffs, rrcCoeffs)
% QPSK symbol alignment and decoding 
%
%   Copyright 2021 The MathWorks, Inc.

% Upsampled Frame/Preamble lengths
FrameLengthUp = FrameLength*SamplesPerSymbol;
PreambleLengthUp = PreambleLength*SamplesPerSymbol;

% match filter against preamble
correlatorOut = filter(mfCoeffs,1,dataIn);

% compute magnitude squared
correlatorMagSq = real(correlatorOut).^2+imag(correlatorOut).^2;

% search through 2nd window to avoid OOB alignment in 1st/3rd windows
searchIdx = FrameLengthUp + (1:FrameLengthUp);

% find max correlator location
maxIdx = find(correlatorMagSq==max(correlatorMagSq(searchIdx)),1);
if isempty(maxIdx)
    maxIdx = 1;
else
    maxIdx = maxIdx(1);
end

% rotation angle to correct
rotationAngle=angle(correlatorOut(maxIdx));

% index of aligned frame
idxOut = (1:FrameLengthUp) + maxIdx - PreambleLengthUp/2;

% get aligned rx frame and correct rotation
rxDataAligned = dataIn(idxOut);

% apply rotation correction
rxRotated = rxDataAligned*conj(exp(1j*rotationAngle));

% Apply RRC filter
rxFiltered = filter(rrcCoeffs,1,rxRotated);

% Downsample after RRC filter
dataOut = rxFiltered(1:SamplesPerSymbol:end);

end

