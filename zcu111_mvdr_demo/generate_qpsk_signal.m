function [txData,matchedFilterCoeffs,rrcFilterCoeffs] = generate_qpsk_signal( ...
    NFrames,FrameLength,PreambleLength,SamplesPerSymbol)

% Use QPSK modulation
M=4;

% Calculate payload length
NPayloadLength=FrameLength-PreambleLength; 

% use random data for preamble
preamble=randi([0 M-1],PreambleLength,1);

% copy preamble so it can be inserted at start of each frame
preamble_frames=preamble*ones(1,NFrames);

% QPSK payload data
payload=randi([0 M-1],NPayloadLength,NFrames);

% append preamble to payload data
txdata=[preamble_frames;payload];    

% QPSK modulation data
txconstdata=pskmod(txdata(:),M,pi/M);

% upsample constellation data
txconstdata_up=upsample(txconstdata,SamplesPerSymbol);

% generate Root Raised Cosine (RRC) Tx/Rx Filer 
rrcFilterCoeffs = rcosdesign(0.25,6,SamplesPerSymbol);

% apply RRC on tx data
txData=filter(rrcFilterCoeffs,1,txconstdata_up);                      

% extract preamble
preamble_temp=filter(rrcFilterCoeffs,1,txconstdata_up(1:PreambleLength*SamplesPerSymbol));

% convert to matched filter
matchedFilterCoeffs=conj(flipud(preamble_temp));

end

