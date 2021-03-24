%   program_board Utility script to program the board after bitstream generation
%
%   Copyright 2021 The MathWorks, Inc.


bitstream = fullfile('binaries','system_wrapper.bit');
devicetree = 'devicetree.dtb';
rdName = 'IQ ADC/DAC Interface';

% Create board connection object
z = zynq;

% Program the board
%                                            
hRDParams = [];
hRDParams.MW_ADD_DDR4 = 'false';
hRDParams.MW_AXIS_DATA_WIDTH = '32';
[status, result]= ZynqRFSoC.common.internal.downloadBitstreamToRFSoC(z,bitstream,devicetree,'',rdName,hRDParams);
disp(result);