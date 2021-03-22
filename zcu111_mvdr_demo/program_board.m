% program_board Utility script to program the board after bitstream generation

bitstream = 'hdl_prj\vivado_ip_prj\vivado_prj.runs\impl_1\system_wrapper.bit';
devicetree = 'devicetree_adi_axistream_32.dtb';
rdName = 'I/Q';

% Create board connection object
z = zynq;

% Upload customer devicetree to board
z.putFile(devicetree,'/mnt');

% Program the board
ZynqRF.common.internal.downloadBitstreamToRFSoC(z,bitstream,devicetree,rdName,{});