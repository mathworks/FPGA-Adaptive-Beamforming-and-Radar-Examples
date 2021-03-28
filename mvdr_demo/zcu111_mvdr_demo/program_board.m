%   program_board Utility script to program the board after bitstream generation
%
%   Copyright 2021 The MathWorks, Inc.

vivado_path = fullfile(fileparts(hdlget_param(bdroot,'TargetDirectory')),'vivado_ip_prj');
bitstream_path = fullfile(vivado_path,'vivado_prj.runs','impl_1','system_wrapper.bit');
if isempty(ls(bitstream_path))
    error('Bitstream not found! Ensure that synthesis, place/route and bitstream creation has fully completed!');
end

devicetree = 'devicetree.dtb';
rdName = 'IQ ADC/DAC Interface';

% Create board connection object
z = zynq;

% Program the board
%                                            
hRDParams = [];
hRDParams.MW_ADD_DDR4 = 'false';
hRDParams.MW_AXIS_DATA_WIDTH = '32';
[status, result]= ZynqRFSoC.common.internal.downloadBitstreamToRFSoC(z,bitstream_path,devicetree,'',rdName,hRDParams);
disp(result);