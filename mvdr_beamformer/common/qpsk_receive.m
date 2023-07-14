function dataOut = qpsk_receive(dataIn, varargin)
% QPSK symbol alignment and decoding 
%
%   Copyright 2021 The MathWorks, Inc.

if nargin == 2
    assert(isstruct(varargin{1}),'Second argument must be a parameter struct');
    paramStruct = varargin{1};
    FrameLength = paramStruct.FrameLength;
    SamplesPerSymbol = paramStruct.SamplesPerSymbol;
    PreambleLength = paramStruct.PreambleLength;
    mfCoeffs = paramStruct.mfCoeffs;
    rrcCoeffs = paramStruct.rrcCoeffs;
else
    assert(nargin == 6,'Invalid number of arguments');
    FrameLength = varargin{1};
    SamplesPerSymbol = varargin{2};
    PreambleLength = varargin{3};
    mfCoeffs = varargin{4};
    rrcCoeffs = varargin{5};
end

% Upsampled Frame/Preamble lengths
FrameLengthUp = FrameLength*SamplesPerSymbol;
PreambleLengthUp = PreambleLength*SamplesPerSymbol;

% match filter against preamble
correlatorOut = filter(mfCoeffs,1,dataIn);

% compute magnitude squared
correlatorMagSq = real(correlatorOut).^2+imag(correlatorOut).^2;

% Input contains 3 frames of data.
% Search through 1st+2nd frame to avoid OOB alignment in 3rd frame
searchIdx = 1:(2*FrameLengthUp);

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
idxOut = (1:FrameLengthUp) + maxIdx - PreambleLengthUp/2 - 1;

% get aligned rx frame and correct rotation
rxDataAligned = dataIn(idxOut);

% apply rotation correction
rxRotated = rxDataAligned*conj(exp(1j*rotationAngle));

% Apply RRC filter
rxFiltered = filter(rrcCoeffs,1,rxRotated);

% Downsample after RRC filter (and discard filter transient)
dataOut = rxFiltered((SamplesPerSymbol*8):SamplesPerSymbol:end);

end

