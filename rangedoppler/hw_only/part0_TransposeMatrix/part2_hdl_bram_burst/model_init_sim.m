% model_init for DL model
if ~exist('numCols','var')
    numCols = 320;
    numRows = 200;
end
pixelcontrolbus;
frm2pix = visionhdl.FrameToPixels;
frm2pix.VideoFormat = '1080p';
[~, ~, totalPixels] = getparamfromfrm2pix(frm2pix);
Ts = 1/(totalPixels*60);
clear frm2pix;

run AXIBusObjects;
pAXIDataWidthBytes = 4; % number of bytes (128 bits) for AXI Data-Width
inputImageDDROffset = uint32(hex2dec('00000000')); % addr = 0x8000-0000

pMaxBankLines = 8;
pMaxNumBanks = 3;

pNumCols = 30;
pNumRows = 30;
% Note: based on a 1080p frame and the pNumRows/Cols are sub-ROI
% dimensions, define blanking vars to simulate this
% hBlank = frm2pix.TotalPixelsPerLine - pNumCols;
% vBlank = frm2pix.TotalVideoLines - pNumRows;

% Note: for demonstration purposes, re-define blanking vars
hBlank = 20;
vBlank = 8;

%% create input image in case you want defined data to push
clear imageIn;

% uncomment these lines to just see integers in the LA
imageIn(:,:,1) = repmat(zeros(pNumRows,1,'uint8'),1,pNumCols);
imageIn(:,:,2) = repmat(zeros(pNumRows,1,'uint8'),1,pNumCols);
imageIn(:,:,3) = repmat(uint8([1:pNumRows]'),1,pNumCols);

% uncomment these lines to just see a yellow gradient in the video viewer
% imageIn(:,:,1) = repmat(linspace(0,255,pNumRows)',1,pNumCols);
% imageIn(:,:,2) = repmat(linspace(0,255,pNumRows)',1,pNumCols);
% imageIn(:,:,3) = repmat([1:pNumRows]',1,pNumCols);

% testImage = uint8([repmat(1:pNumCols,pNumRows,1,3)]);

%% BRAM savings
bramAddrWidth = ceil(log2(pMaxBankLines*pMaxNumBanks*pNumCols));
bramSaving = (  1 - pMaxBankLines*pMaxNumBanks*pNumCols / (pNumCols*pNumRows))*100;
fprintf('By using DDR4 memory we reduced BRAM usage of the transpose by %2.1f percent. Address width is %d-bits \n',bramSaving,bramAddrWidth);

%% State machine labeling
% LINEBUFFER = fi(1,0,4,0);
% LINESTART = fi(3,0,4,0);
Simulink.defineIntEnumType('stateBRAMfsm', {'IDLE','LINEBUFFER', 'LINESTART'}, [0 1 3]);


% BURSTSTART = fi(1,0,4,0);
% BURSTNEXT  = fi(3,0,4,0);
% WAITBURSTCOMPLETE = fi(4,0,4,0);
% WAITBURSTREADY = fi(5,0,4,0);
% WAITONBANKRDY =fi(2,0,4,0);
Simulink.defineIntEnumType('stateAXI4Mfsm', {'IDLE',...
                                             'BURSTSTART',...
                                             'WAITONBANKRDY',...
                                             'BURSTNEXT',...
                                             'WAITBURSTCOMPLETE',...
                                             'WAITBURSTREADY'}, [0 1 2 3 4 5]);
