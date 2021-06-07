IPAddr = 'ip:192.168.2.101';
% Matrix Dimensions
% bad data:
% dim1 = 31;
% dim2 = 25;

% 
dim1 = 128;
dim2 = 128;

% dim1 = 1024*2;
% dim2 = 1024*2;
frameSize = dim1*dim2;
% if frameSize > 1024
%     error('cant use this right now because you didnt model TLAST')
% end

fprintf('Frame size is %d \n',frameSize);
% may need to enter the below on ZCU111 command line to increase IIO buffer
% size
% echo 67108864 > /sys/module/industrialio_buffer_dma/parameters/max_block_size
% matlabshared.libiio.internal.ContextManager.reset
%% AXI4 Stream IIO Write registers
% NOTE: This is a place holder based on auto-generated templates. Please modify these values according to your FPGA design
AXI4SReadObj = pspshared.libiio.axistream.read(...
                  'IPAddress',IPAddr,...
                  'SamplesPerFrame',frameSize,...
                  'DataType','ufix64',...
                  'Timeout',0);%,'TLASTMode','user_logic');
setup(AXI4SReadObj);

AXI4SWriteObj = pspshared.libiio.axistream.write(...
                  'IPAddress',IPAddr,...
                  'SamplesPerFrame',frameSize,...                  
                  'Timeout',0);
setup(AXI4SWriteObj,fi(zeros(frameSize,1),numerictype('uint64')));


%% AXI4 MM IIO Write registers
N1 =  pspshared.libiio.aximm.write(...
                   'IPAddress',IPAddr,...
                   'AddressOffset',hex2dec('100')); 
N2 =  pspshared.libiio.aximm.write(...
                   'IPAddress',IPAddr,...
                   'AddressOffset',hex2dec('104')); 


%% AXI4 MM IIO Read registers
Rd_MatrixDoneWrCount = pspshared.libiio.aximm.read(...
                 'IPAddress',IPAddr,...
                 'AddressOffset',hex2dec('108'),...
                 'DataType','uint32');
Rd_ColWriteCompleteCount = pspshared.libiio.aximm.read(...
                 'IPAddress',IPAddr,...
                 'AddressOffset',hex2dec('10C'),...
                 'DataType','uint32');
Rd_MatrixRdCount = pspshared.libiio.aximm.read(...
                 'IPAddress',IPAddr,...
                 'AddressOffset',hex2dec('110'),...
                 'DataType','uint32');
Rd_MatrixRdCmdCount = pspshared.libiio.aximm.read(...
                 'IPAddress',IPAddr,...
                 'AddressOffset',hex2dec('114'),...
                 'DataType','uint32');
Rd_WrAFullCounter = pspshared.libiio.aximm.read(...
                 'IPAddress',IPAddr,...
                 'AddressOffset',hex2dec('118'),...
                 'DataType','uint32');


%% Setup() AXI4 MM IIO Objects
% NOTE: These are placeholder values. Please update this section according to your design

% Setup AXI4MM Read IIO objects
setup(Rd_MatrixDoneWrCount); 
setup(Rd_ColWriteCompleteCount); 
setup(Rd_MatrixRdCount); 
setup(Rd_MatrixRdCmdCount); 
setup(Rd_WrAFullCounter); 
% Setup AXI4MM Write IIO objects
setup(N1,uint32(10)); 
setup(N2,uint32(10)); 


%% Step() AXI4 MM IIO Objects
% NOTE: These are placeholder values. Please update this section according to your design

% ---- Step AXI4MM Read IIO objects ---- 
% step(Rd_MatrixDoneWrCount); 
% step(Rd_ColWriteCompleteCount); 
% step(Rd_MatrixRdCount); 
% step(Rd_MatrixRdCmdCount); 
% step(Rd_WrAFullCounter); 
% ---- Step AXI4MM Write IIO objects ---- 


N1(dim1);
N2(dim2);


%%
MatrixInputArr = [1:dim1*dim2];
MatrixInput = reshape(MatrixInputArr,[dim1,dim2]);
MatrixInput = fi(MatrixInput,0,64,0);
pause(0.1)
AXI4SWriteObj(MatrixInput(:)); % write matrix
pause(0.1)
[rdMatrix,valid]= AXI4SReadObj();

if valid
    rdOut = reshape(rdMatrix,[dim2,dim1]);
    % compare matrices
    transposeRd = transpose(rdOut);
     plot([MatrixInput(:)-transposeRd(:)])
     
     MatrixWriteDone = Rd_MatrixDoneWrCount();
     MatrixColWrite = Rd_ColWriteCompleteCount();
     MatrixRdCount = Rd_MatrixRdCount();
     MatrixRdCmdCount = Rd_MatrixRdCmdCount();
     MatrixWrFIFOFull = Rd_WrAFullCounter();
     
     figure(1); clf;
     imagesc(double(rdOut));
     fprintf(['Matrix write done counter = %d \n',...
              'Matrix column writer count = %d \n',...
              'Matrix Valid Read Counter = %d \n',...
              'Matrix Read command counter = %d \n',...
              'Matrix Wr FIFO Full? = %d \n'],...
              MatrixWriteDone,MatrixColWrite,MatrixRdCount,MatrixRdCmdCount,MatrixWrFIFOFull)
    
          
     unequal_idx = find(MatrixInput(:) ~= transposeRd(:));
    if ~isempty(unequal_idx)
        fprintf('Indices = %d ',unequal_idx)
            %  uint32(rdOut)
        error('Bad transpose!')
    else
        fprintf('Matrix compare OK!\n');
    end
    
   
    
   
        
else
    error('no data!');
end

% clear all;

