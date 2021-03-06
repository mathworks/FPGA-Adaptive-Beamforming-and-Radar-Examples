function setup_fpgaIO(hFPGA,framesize_wr, framesize_rd)
%--------------------------------------------------------------------------
% Software Interface Script Setup
% 
% Generated with MATLAB 9.10 (R2021a) at 02:53:28 on 20/06/2021.
% This function was created for the IP Core generated from design 'bramBurst_TransposeMatrix'.
% 
% Run this function on an "fpga" object to configure it with the same interfaces as the generated IP core.
%--------------------------------------------------------------------------

%% AXI4
addAXI4SlaveInterface(hFPGA, ...
	"InterfaceID", "AXI4", ...
	"BaseAddress", 0xA0000000, ...
	"AddressRange", 0x10000);

hPort_resetIPCore = hdlcoder.DUTPort("resetIP", ...
	"Direction", "IN", ...
	"DataType", numerictype(0,32,0), ...
	"Dimension", [1 1], ...
	"IOInterface", "AXI4", ...
	"IOInterfaceMapping", "0x0");

hPort_inputImageDDROffset = hdlcoder.DUTPort("inputImageDDROffset", ...
	"Direction", "IN", ...
	"DataType", numerictype(0,32,0), ...
	"Dimension", [1 1], ...
	"IOInterface", "AXI4", ...
	"IOInterfaceMapping", "0x100");

hPort_debugRegInput_bypassFFT = hdlcoder.DUTPort("bypassFFT", ...
	"Direction", "IN", ...
	"DataType", numerictype('boolean'), ...
	"Dimension", [1 1], ...
	"IOInterface", "AXI4", ...
	"IOInterfaceMapping", "0x104");

hPort_debugRegInput_bypassMatchedFilter = hdlcoder.DUTPort("bypassMatchedFilter", ...
	"Direction", "IN", ...
	"DataType", numerictype('boolean'), ...
	"Dimension", [1 1], ...
	"IOInterface", "AXI4", ...
	"IOInterfaceMapping", "0x130");

hPort_debugRegInput = hdlcoder.DUTPort("debugRegInput", ...
	"Direction", "IN", ...
	"DataType", "Bus", ...
	"Dimension", [1 1], ...
	"IOInterface", "AXI4", ...
	"SubPorts", [hPort_debugRegInput_bypassFFT, hPort_debugRegInput_bypassMatchedFilter]);

hPort_ddrDoneCounter = hdlcoder.DUTPort("ddrDoneCounter", ...
	"Direction", "OUT", ...
	"DataType", numerictype(1,32,0), ...
	"Dimension", [1 1], ...
	"IOInterface", "AXI4", ...
	"IOInterfaceMapping", "0x108");

hPort_fifo_full_event = hdlcoder.DUTPort("fifo_full_event", ...
	"Direction", "OUT", ...
	"DataType", numerictype(0,32,0), ...
	"Dimension", [1 1], ...
	"IOInterface", "AXI4", ...
	"IOInterfaceMapping", "0x10C");

hPort_debugRead_AXI4M_WrValidCnt = hdlcoder.DUTPort("AXI4M_WrValidCnt", ...
	"Direction", "OUT", ...
	"DataType", numerictype(0,32,0), ...
	"Dimension", [1 1], ...
	"IOInterface", "AXI4", ...
	"IOInterfaceMapping", "0x110");

hPort_debugRead_BRAM_FSM_BankRdCompleteCnt = hdlcoder.DUTPort("BRAM_FSM_BankRdCompleteCnt", ...
	"Direction", "OUT", ...
	"DataType", numerictype(0,32,0), ...
	"Dimension", [1 1], ...
	"IOInterface", "AXI4", ...
	"IOInterfaceMapping", "0x114");

hPort_debugRead_BRAM_FSM_StoppingFIFO_Counter = hdlcoder.DUTPort("BRAM_FSM_StoppingFIFO_Counter", ...
	"Direction", "OUT", ...
	"DataType", numerictype(0,32,0), ...
	"Dimension", [1 1], ...
	"IOInterface", "AXI4", ...
	"IOInterfaceMapping", "0x118");

hPort_debugRead_AXI4M_WriteCounter = hdlcoder.DUTPort("AXI4M_WriteCounter", ...
	"Direction", "OUT", ...
	"DataType", numerictype(0,32,0), ...
	"Dimension", [1 1], ...
	"IOInterface", "AXI4", ...
	"IOInterfaceMapping", "0x11C");

hPort_debugRead_BRAM_FSM_Concat = hdlcoder.DUTPort("BRAM_FSM_Concat", ...
	"Direction", "OUT", ...
	"DataType", numerictype(0,8,0), ...
	"Dimension", [1 1], ...
	"IOInterface", "AXI4", ...
	"IOInterfaceMapping", "0x120");

hPort_debugRead_FIFO_FullEventCount = hdlcoder.DUTPort("FIFO_FullEventCount", ...
	"Direction", "OUT", ...
	"DataType", numerictype(0,32,0), ...
	"Dimension", [1 1], ...
	"IOInterface", "AXI4", ...
	"IOInterfaceMapping", "0x124");

hPort_debugRead_FIFO_LostSampleCount = hdlcoder.DUTPort("FIFO_LostSampleCount", ...
	"Direction", "OUT", ...
	"DataType", numerictype(0,32,0), ...
	"Dimension", [1 1], ...
	"IOInterface", "AXI4", ...
	"IOInterfaceMapping", "0x128");

hPort_debugRead_FIFO_BackPressureAppliedOnMM2S = hdlcoder.DUTPort("FIFO_BackPressureAppliedOnMM2S", ...
	"Direction", "OUT", ...
	"DataType", numerictype(0,32,0), ...
	"Dimension", [1 1], ...
	"IOInterface", "AXI4", ...
	"IOInterfaceMapping", "0x12C");

hPort_debugRead_FIFO_ValidWriteCount = hdlcoder.DUTPort("FIFO_ValidWriteCount", ...
	"Direction", "OUT", ...
	"DataType", numerictype(0,32,0), ...
	"Dimension", [1 1], ...
	"IOInterface", "AXI4", ...
	"IOInterfaceMapping", "0x134");

hPort_debugRead = hdlcoder.DUTPort("debugRead", ...
	"Direction", "OUT", ...
	"DataType", "Bus", ...
	"Dimension", [1 1], ...
	"IOInterface", "AXI4", ...
	"SubPorts", [hPort_debugRead_AXI4M_WrValidCnt, hPort_debugRead_BRAM_FSM_BankRdCompleteCnt, hPort_debugRead_BRAM_FSM_StoppingFIFO_Counter, hPort_debugRead_AXI4M_WriteCounter, hPort_debugRead_BRAM_FSM_Concat, hPort_debugRead_FIFO_FullEventCount, hPort_debugRead_FIFO_LostSampleCount, hPort_debugRead_FIFO_BackPressureAppliedOnMM2S, hPort_debugRead_FIFO_ValidWriteCount]);

mapPort(hFPGA, [hPort_resetIPCore hPort_inputImageDDROffset, hPort_debugRegInput, hPort_ddrDoneCounter, hPort_fifo_full_event, hPort_debugRead]);

%% AXI4-Stream DMA
addAXI4StreamInterface(hFPGA, ...
	"InterfaceID", "AXI4-Stream DMA", ...
	"WriteEnable", true, ...
	"WriteDataWidth", 64, ...
	"WriteFrameLength", framesize_wr, ...
	"ReadEnable", true, ...
	"ReadDataWidth", 64, ...
	"ReadFrameLength", framesize_rd,...
    "WriteTimeout",0,...
    "ReadTimeout",0);

hPort_axis_mm2s_tdata = hdlcoder.DUTPort("axis_mm2s_tdata", ...
	"Direction", "IN", ...
	"DataType", numerictype(1,64,0), ...
	"Dimension", [1 1], ...
	"IOInterface", "AXI4-Stream DMA");

hPort_axis_s2mm_tdata = hdlcoder.DUTPort("axis_s2mm_tdata", ...
	"Direction", "OUT", ...
	"DataType", numerictype(0,64,0), ...
	"Dimension", [1 1], ...
	"IOInterface", "AXI4-Stream DMA");

mapPort(hFPGA, [hPort_axis_mm2s_tdata, hPort_axis_s2mm_tdata]);

end
