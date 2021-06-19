%--------------------------------------------------------------------------
% Software Interface Script
% 
% Generated with MATLAB 9.10 (R2021a) at 19:37:54 on 13/06/2021.
% This script was created for the IP Core generated from design 'ddrxpose_21a_generic_fft_rdy2'.
% 
% Use this script to access DUT ports in the design that were mapped to compatible IP core interfaces.
% You can write to input ports in the design and read from output ports directly from MATLAB.
% To write to input ports, use the "writePort" command and specify the port name and input data. The input data will be cast to the DUT port's data type before writing.
% To read from output ports, use the "readPort" command and specify the port name. The output data will be returned with the same data type as the DUT port.
% Use the "release" command to release MATLAB's control of the hardware resources.
%--------------------------------------------------------------------------

%% Create fpga object
hFPGA = fpga("Xilinx");

%% Setup fpga object
% This function configures the "fpga" object with the same interfaces as the generated IP core
N1 = 65;
N2 = 60;
frameSize = 65*60;
transpose_fpgaIO_setup(hFPGA,frameSize);

%% Write/read DUT ports
% Uncomment the following lines to write/read DUT ports in the generated IP Core.
% Update the example data in the write commands with meaningful data to write to the DUT.
%% AXI4
% writePort(hFPGA, "inputImageDDROffset", zeros([1 1]));
% data_ddrDoneCounter = readPort(hFPGA, "ddrDoneCounter");
% data_fifo_full_event = readPort(hFPGA, "fifo_full_event");

%% AXI4-Stream DMA
% writePort(hFPGA, "DataIn", zeros([1 1024]));
% data_tdata_o = readPort(hFPGA, "tdata_o");
for ii = 1:50
    MatrixInputArr = [1:N1*N2]*ii;
    MatrixInput = reshape(MatrixInputArr,[N1,N2]);


    writePort(hFPGA, "DataIn", MatrixInput);

%     pause(1);
    data_ddrDoneCounter = readPort(hFPGA, "ddrDoneCounter");
    fprintf('DDR4 write done count = %d \n',data_ddrDoneCounter);
    data_tdata_o = readPort(hFPGA, "tdata_o");
    c = reshape(data_tdata_o,N2,N1); %<--- note we swap N2 and N1 because this is transposed..
    diff_data = double(MatrixInput.') - double(c(:,:));
%     plot(diff(:))
    if any(diff_data~=0)
        warning('bad transpose!')
    end
end
%% Release hardware resources
release(hFPGA);

