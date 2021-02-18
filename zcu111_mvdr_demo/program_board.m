%   program_board Utility script to program the board after bitstream generation
%
%   Copyright 2021 The MathWorks, Inc.


bitstream = fullfile('binaries','zcu111_mvdr.bit');
devicetree = 'devicetree_adi_axistream_32.dtb';
rdName = 'I/Q';

% Create board connection object
z = zynq;

% Upload customer devicetree to board
z.putFile(fullfile('binaries',devicetree),'/mnt');

% Program the board
ZynqRF.common.internal.downloadBitstreamToRFSoC(z,bitstream,devicetree,rdName,{});