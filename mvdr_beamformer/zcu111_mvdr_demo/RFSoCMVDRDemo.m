classdef RFSoCMVDRDemo < handle
 %RFSOCMVDRDEMO RFSoC MVDR Demo
 %   Copyright 2021 The MathWorks, Inc.
 
    properties
       IPAddress = '';
    end
    
    properties (SetAccess = private)        
        % User interface parameters
        SignalGain
        SignalAngle
        InterfererGain
        InterfererAngle
        SteeringAngle
        InternalLoopbackEnabled = false;
    end

    properties (Access = private)

        % Derived user parameters
        SignalCoeff = complex(ones(4,1));
        SignalGainLin = 1;
        InterfererCoeff = complex(ones(4,1));
        InterfererGainLin = 1;
        SteeringCoeff = complex(ones(4,1));
        DiagonalLoading = 0;
        
        % Parameters imported from workspace
        steeringVector
        beamPattern
        centerFrequency
        ncoInc
        DataSampleRate
        DMAReadFrameSize
        FrameSize
        QPSKFrameLength
        QPSKSamplesPerSymbol
        QPSKPreambleLength
        QPSKmfCoeffs
        QPSKrrcCoeffs
        
        % AGC for QPSK
        agc

        % FPGA register and DMA interface
        hFPGA
        rx_capture_start_reg
        dma_read

        % Capture source state 
        captureSource = 0;

        % Debug print mode
        DebugMode = false;
    end
    
    properties (Hidden, Constant)
        SRC_MVDR_OUT = 0;
        SRC_MVDR_IN = 1;
        SRC_ADC = 2;

        AZ_SWEEP = -90:90;
    end

    %% Public methods
    methods
        function obj = RFSoCMVDRDemo(varargin)
            p = inputParser;
            p.addParameter('IPAddress','');
            p.addParameter('DebugMode', false);
            p.KeepUnmatched = true;
            p.parse(varargin{:});
            args = p.Results;

            obj.IPAddress = args.IPAddress;
            obj.DebugMode = args.DebugMode;

            setup(obj);
        end
        
        function delete(obj)
            if ~isempty(obj.hFPGA)
                release(obj.hFPGA);
            end
        end
        
        function [resp, weights] = getArrayResponse(obj,mode)
            switch mode
                case 'mvdr'
                    weightsVec = readPort(obj.hFPGA, "computed_weights");
                    weights = reshape(double(deinterleave_complex(weightsVec)),[],1);
                case 'phaseshift'
                    weights = obj.steeringVector(obj.centerFrequency,[obj.SteeringAngle; 0]);
            end
            resp = obj.beamPattern(obj.centerFrequency, obj.AZ_SWEEP, weights);
        end

        function  [beamData,qpskData,sampleRate] = getUIData(obj)
            beamData = captureBeamData(obj);
            qpskData = qpskReceive(obj,beamData);
            sampleRate = obj.DataSampleRate;
        end

        function data = captureBeamData(obj)

            % Set capture source
            setCaptureSource(obj,obj.SRC_MVDR_OUT);

            % Capture data
            data = captureData(obj);

            % reshape into individual channels
            data = reshape(data,4,[]);

            % grab real/imag from chan 1&2, discard chan 3&4
            data = complex(data(1,:), data(2,:));

            % make channels as columns
            data = transpose(data);

            % Convert to double and scale
            data = double(data)/2^26;
        end

        function data = captureInputData(obj,getRawData)

            if nargin < 2
                getRawData = false;
            end

            % Set capture source
            if getRawData
                setCaptureSource(obj,obj.SRC_ADC);
            else
                setCaptureSource(obj,obj.SRC_MVDR_IN);
            end

            % Read a frame
            data = captureData(obj);

            % Unpack uint32 to complex int16
            data = unpack_complex(data);

            % Convert to double and scale
            data = double(data)*2^-15;

            % Reshape into individual channels
            data = reshape(data,4,[]);

            % Make channels as columns
            data = transpose(data);
        end

        function constellation = qpskReceive(obj,data)
            if isempty(obj.agc)
                obj.agc = comm.AGC('AveragingLength',obj.QPSKFrameLength*4,...
                    'AdaptationStepSize', 1e-3, ...
                    'DesiredOutputPower', 1, ...
                    'MaxPowerGain', 60);
            end
            constellation = qpsk_receive(data, obj.QPSKFrameLength, ...
                obj.QPSKSamplesPerSymbol,obj.QPSKPreambleLength,...
                obj.QPSKmfCoeffs,obj.QPSKrrcCoeffs);
            constellation = obj.agc(constellation);
        end

    end
    
    %% UI set methods
    methods
        function setSignalAngle(obj,val)
            obj.SignalAngle = val;
            obj.SignalCoeff = obj.steeringVector(obj.centerFrequency,[obj.SignalAngle; 0]);
            writePort(obj.hFPGA, "tx_steering_coeffs_src1", interleave_complex(obj.SignalCoeff));
        end
        
        function setInterfererAngle(obj,val)
            obj.InterfererAngle = val;
            obj.InterfererCoeff = obj.steeringVector(obj.centerFrequency,[obj.InterfererAngle; 0]);
            writePort(obj.hFPGA, "tx_steering_coeffs_src2", interleave_complex(obj.InterfererCoeff));
        end
        
        function setSignalGain(obj,val)
            obj.SignalGain = val;
            obj.SignalGainLin = 10.^(obj.SignalGain/20);
            writePort(obj.hFPGA, "tx_src_gains", [obj.SignalGainLin obj.InterfererGainLin]);
        end
        
        function setInterfererGain(obj,val)
            obj.InterfererGain = val;
            obj.InterfererGainLin = 10.^(obj.InterfererGain/20);
            writePort(obj.hFPGA, "tx_src_gains", [obj.SignalGainLin obj.InterfererGainLin]);
        end
        
        function setSteeringAngle(obj,val)
            obj.SteeringAngle = val;
            obj.SteeringCoeff = obj.steeringVector(obj.centerFrequency,[obj.SteeringAngle; 0]);
            writePort(obj.hFPGA, "rx_steering_coeffs", interleave_complex(obj.SteeringCoeff));
        end

        function setDiagonalLoading(obj,val)
            obj.DiagonalLoading = val;
            writePort(obj.hFPGA, "diag_loading", val);
        end

    end
    
    %% Private methods
    
    methods (Access = private)

        function setup(obj)
         
            % Initialize parameters
            setupParameters(obj);

            % Setup FPGA interface
            try
                setupFPGAIO(obj);
            catch e
                error(['Could not connect to RFSoC board! Ensure the board is powered on',...
                      'and connected over Ethernet before running this application!' newline e.message]);
            end
            
            % Set registers to default states
            initializeRegisters(obj);
            
            % Set default UI parameters
            obj.setDiagonalLoading(5e-3);
            obj.setSignalGain(-6);
            obj.setSignalAngle(-45);
            obj.setInterfererGain(0);
            obj.setInterfererAngle(35);
            obj.setSteeringAngle(-45);
            
            % Run calibration routine to align channels
            runChannelCalibration(obj);
        end
        
        function setupParameters(obj)            
            % Run model parameter init and get parameters from workspace
            evalin('base','model_init');
            obj.DataSampleRate = evalin('base','DataSampleRate');
            obj.centerFrequency = evalin('base','fc');
            obj.FrameSize = evalin('base','s2mmFrameSize');
            obj.steeringVector = evalin('base','steeringVector');
            obj.beamPattern = evalin('base','beamPattern');
            obj.ncoInc = evalin('base','NCO_default_inc');
            obj.QPSKFrameLength = evalin('base','testSrc1.FrameLength');
            obj.QPSKSamplesPerSymbol = evalin('base','testSrc1.SamplesPerSymbol');
            obj.QPSKPreambleLength = evalin('base','testSrc1.PreambleLength');
            obj.QPSKmfCoeffs = evalin('base','testSrc1.mfCoeffs');
            obj.QPSKrrcCoeffs = evalin('base','testSrc1.rrcCoeffs');

            % write as 128-bit words, read from 32-bit pointer
            obj.DMAReadFrameSize = obj.FrameSize*4;
        end
        
        function initializeRegisters(obj)
            writePort(obj.hFPGA, "IP_Reset", true);
            writePort(obj.hFPGA, "internal_loopback", obj.InternalLoopbackEnabled);
            writePort(obj.hFPGA, "rx_capture_length", obj.FrameSize);
        end
        
        function runChannelCalibration(obj)
            
            % Disable MVDR
            writePort(obj.hFPGA, "rx_mvdr_enable", false);

            % Reset cal coefficients
            writePort(obj.hFPGA, "rx_cal_coeffs", interleave_complex(ones(4,1)));

            % Setup NCO
            writePort(obj.hFPGA, "tx_nco_inc", obj.ncoInc);
            writePort(obj.hFPGA, "tx_nco_enable", true);

            % Capture raw ADC data
            data = captureInputData(obj,true);

            % Get calibration coefficients
            coeffs = calibrate_channels(data);

            if obj.DebugMode
                fprintf('### Applying channel calibration:\n')
                for ii=1:4
                    fprintf('\t%d: scale %.2f, phase %.2f degrees\n',int32(ii),...
                        abs(coeffs(ii)),rad2deg(angle(coeffs(ii))));
                end
            end

            % Apply calibration coefficients
            writePort(obj.hFPGA, "rx_cal_coeffs", interleave_complex(coeffs));

            % Disable NCO
            writePort(obj.hFPGA, "tx_nco_enable", false);

            % Enable MVDR
            writePort(obj.hFPGA, "rx_mvdr_enable", true);
        end

        function setCaptureSource(obj,val)
            if obj.captureSource ~= val
                obj.captureSource = val;
                writePort(obj.hFPGA, "rx_capture_src", val);
            end
        end

        function data = captureData(obj)
            obj.rx_capture_start_reg(uint32(0));
            obj.rx_capture_start_reg(uint32(1));
            data = obj.dma_read();
        end
        
        function setupFPGAIO(obj)
            if isempty(obj.IPAddress)
                hBoardParams = codertarget.hdlcxilinx.internal.BoardParameters;
                obj.IPAddress = hBoardParams.getIPAddress;
            end

            % Initialize FPGA connection object
            hw = xilinxsoc(obj.IPAddress,'root','root');
            obj.hFPGA = fpga(hw);

            % Setup interface mapping
            setup_fpgaio(obj.hFPGA,obj.DMAReadFrameSize);

            % Use LibIIO objects for data capture directly to optimize performance
            obj.rx_capture_start_reg = matlabshared.libiio.aximm.write( ...
                uri=['ip:' obj.IPAddress], AddressOffset=0x134);
            setup(obj.rx_capture_start_reg,uint32(0));
            obj.dma_read = matlabshared.libiio.axistream.read( ...
                uri=['ip:' obj.IPAddress],...
                SamplesPerFrame=obj.DMAReadFrameSize, ...
                dataTypeStr='int32', ...
                DataTimeout=0);
            setup(obj.dma_read);
        end
        
    end
end

