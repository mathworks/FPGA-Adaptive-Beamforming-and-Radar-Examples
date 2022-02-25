classdef RFSoCMVDRDemo < handle
 %RFSOCMVDRDEMO RFSoC MVDR Demo
 %   Copyright 2021 The MathWorks, Inc.
 
    properties
       enableSpectrum = false;
       enableConstellation = false;
    end
    
    properties (SetAccess = private)
        % Run status
        isRunning
        
        % User interface parameters
        SignalGain
        SignalAngle
        InterfererGain
        InterfererAngle
        SteeringAngle
        
        % MVDR data read from DMA
        beamData
        
        % QPSK data
        qpskData
    end
    
    properties (Hidden, Constant)
        % Update rate, in Hz
        UPDATE_RATE = 2;
    end
    
    properties (Access = private)

        % Derived user parameters
        SignalCoeff = complex(ones(4,1));
        SignalGainLin = 1;
        InterfererCoeff = complex(ones(4,1));
        InterfererGainLin = 1;
        SteeringCoeff = complex(ones(4,1));
        
        % Parameters imported from workspace
        steeringVector
        sensorArray
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
        
        % Viewers and listeners
        hSpecAn
        hSpecAnCloseListener
        hConstellation
        hConstellationCloseListener
        
        % Main update timer
        updateTimer    
    end
    
    %% Public methods
    methods
        function obj = RFSoCMVDRDemo()
            setup(obj);
            run(obj);
        end
        
        function delete(obj)
            if ~isempty(obj.hFPGA)
                release(obj.hFPGA);
            end
            if ~isempty(obj.hSpecAn)
                release(obj.hSpecAn);
            end
            if ~isempty(obj.hConstellation)
                release(obj.hConstellation);
            end
        end
        
        function run(obj)
            if ~obj.isRunning
                obj.isRunning = true;
            end
        end
        
        function stop(obj)
            if obj.isRunning            
                obj.isRunning = false;
            end
        end
        
        function [resp, weights] = getArrayResponse(obj,mode)
            switch mode
                case 'mvdr'
                    weightsVec = readPort(obj.hFPGA, "computedWeights");
                    weights = reshape(double(complex(weightsVec(1:4),weightsVec(5:8))),4,1);
                case 'phaseshift'
                    weights = obj.steeringVector(obj.centerFrequency,[obj.SteeringAngle; 0]);
            end
            resp=pattern(obj.sensorArray,obj.centerFrequency,-90:90,0,...
                'Weights',weights);
        end
    end
    
    %% UI set methods
    methods
        function setSignalAngle(obj,val)
            obj.SignalAngle = val;
            obj.SignalCoeff = obj.steeringVector(obj.centerFrequency,[obj.SignalAngle; 0]);
            writePort(obj.hFPGA, "tx_steering_coeffs_src1_re", real(obj.SignalCoeff));
            writePort(obj.hFPGA, "tx_steering_coeffs_src1_im", imag(obj.SignalCoeff));
        end
        
        function setInterfererAngle(obj,val)
            obj.InterfererAngle = val;
            obj.InterfererCoeff = obj.steeringVector(obj.centerFrequency,[obj.InterfererAngle; 0]);
            writePort(obj.hFPGA, "tx_steering_coeffs_src2_re", real(obj.InterfererCoeff));
            writePort(obj.hFPGA, "tx_steering_coeffs_src2_im", imag(obj.InterfererCoeff));
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
            writePort(obj.hFPGA, "rx_steering_coeffs_re", real(obj.SteeringCoeff));
            writePort(obj.hFPGA, "rx_steering_coeffs_im", imag(obj.SteeringCoeff));
        end
        
        function  [beamData,qpskData, sampleRate] = getUIData(obj)
            captureData(obj);
            qpskReceive(obj);
            beamData = obj.beamData;
            qpskData = obj.qpskData;
            sampleRate = obj.DataSampleRate;
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
            catch
                error(['Could not connect to RFSoC board! Ensure the board is powered on',...
                      'and you are connected over ethernet before running this application!']);
            end
            
            % Set registers to default states
            initializeRegisters(obj);
            
            % Set default UI parameters            
            obj.setSignalGain(-6);
            obj.setSignalAngle(-45);
            obj.setInterfererGain(0);
            obj.setInterfererAngle(17);
            obj.setSteeringAngle(-45);
            
            % Run calibration routine to align channels
            runCalibration(obj);
            
            % Initialize viewers
            setupViewers(obj);

        end
        
        function setupParameters(obj)
            % Set default run state
            obj.isRunning = false;
            
            % Run model parameter init and get parameters from workspace
            evalin('base','model_init');
            obj.DataSampleRate = evalin('base','DataSampleRate');
            obj.centerFrequency = evalin('base','fc');
            obj.FrameSize = evalin('base','S2MM_frame_size');
            obj.sensorArray = evalin('base','sensorArray');
            obj.steeringVector = evalin('base','steeringVector');
            obj.ncoInc = evalin('base','NCO_default_inc');
            obj.QPSKFrameLength = evalin('base','testSrc1.FrameLength');
            obj.QPSKSamplesPerSymbol = evalin('base','testSrc1.SamplesPerSymbol');
            obj.QPSKPreambleLength = evalin('base','testSrc1.PreambleLength');
            obj.QPSKmfCoeffs = evalin('base','testSrc1.mfCoeffs');
            obj.QPSKrrcCoeffs = evalin('base','testSrc1.rrcCoeffs');

            % write as 128-bit words, read from 32-bit pointer
            obj.DMAReadFrameSize = obj.FrameSize*4;
        end
 
        function setupViewers(obj)
            obj.hSpecAn = dsp.SpectrumAnalyzer('SampleRate', obj.DataSampleRate,...
                'FrequencyResolutionMethod','WindowLength', 'WindowLength', obj.FrameSize);
            obj.hConstellation = comm.ConstellationDiagram();
        end
        
        function setupListeners(obj)
            obj.updateTimer = timer('ExecutionMode','fixedRate',...
                'Period',round(1/obj.UPDATE_RATE,3),'TimerFcn',@(~,~) obj.updateCallback());          
            frmWrk = obj.hSpecAn.getFramework;
            obj.hSpecAnCloseListener = addlistener(frmWrk.Parent,'Close', @(~,~) obj.stopCallback());
            frmWrk = obj.hConstellation.getFramework;
            obj.hConstellationCloseListener = addlistener(frmWrk.Parent,'Close', @(~,~) obj.stopCallback());
        end

        function teardownListeners(obj)
            if isvalid(obj.updateTimer)
                delete(obj.updateTimer);
            end
            if isvalid(obj.hSpecAnCloseListener)
                delete(obj.hSpecAnCloseListener);
            end
            if isvalid(obj.hConstellationCloseListener)
                delete(obj.hConstellationCloseListener);
            end
        end
        
        function updateCallback(obj)
            captureData(obj);
            qpskReceive(obj) 
            updateViewers(obj);
        end
        
    
        
        function stopCallback(obj)
            stop(obj); 
        end
        
        function initializeRegisters(obj)
            writePort(obj.hFPGA, "BypassAnalog", false);
            writePort(obj.hFPGA, "rx_frame_size", obj.FrameSize);
            writePort(obj.hFPGA, "rx_auto_trig_en", false);
            writePort(obj.hFPGA, "rx_capture_trig", false);
        end
        
        function runCalibration(obj)
            
            % Reset cal coefficients
            writePort(obj.hFPGA, "rx_cal_coeffs_re", ones(4,1));
            writePort(obj.hFPGA, "rx_cal_coeffs_im", ones(4,1));

            % Setup NCO
            writePort(obj.hFPGA, "tx_nco_inc", obj.ncoInc);
            writePort(obj.hFPGA, "tx_nco_enable", true);

            % Bypass MVDR output to receive raw ADC channel data
            writePort(obj.hFPGA, "BypassMVDR", true);

            % Trigger a capture
            writePort(obj.hFPGA, "rx_capture_trig", true);
            writePort(obj.hFPGA, "rx_capture_trig", false);

            % Read a frame
            data = readPort(obj.hFPGA, "S2MM_Data");

            % Unpack uint32 to complex int16
            data = unpack_complex(data);

            % Reshape into individual channels
            data = reshape(data,4,[]);

            % Make channels as columns
            data = transpose(data);

            % Get calibration coefficients
            coeffs = calibrate_channels(data);

            % Apply calibration coefficients
            writePort(obj.hFPGA, "rx_cal_coeffs_re", real(coeffs));
            writePort(obj.hFPGA, "rx_cal_coeffs_im", imag(coeffs));

            % Disable NCO and bypass
            writePort(obj.hFPGA, "tx_nco_enable", false);
            writePort(obj.hFPGA, "BypassMVDR", false);
        end

        function captureData(obj)
            % Trigger a capture
            writePort(obj.hFPGA, "rx_capture_trig", true);
            writePort(obj.hFPGA, "rx_capture_trig", false);

            % Read a frame
            data = readPort(obj.hFPGA, "S2MM_Data");

            % reshape into individual channels
            data = reshape(uint32(data),4,[]);

            % grab real/imag from chan 1&2, discard chan 3&4
            data = complex(data(1,:), data(2,:));

            % make channels as columns
            data = transpose(data);

            % Cast to fi and reinterpret fraction length
            data = cast_to_fi(data);
            data = reinterpretcast(data, numerictype(1,32,30));

            % Convert to double and save to object property
            obj.beamData = double(data);
        end
        
        function qpskReceive(obj)
            if isempty(obj.agc)
                obj.agc = comm.AGC('AveragingLength',obj.QPSKFrameLength*4,...
                    'AdaptationStepSize', 1e-3, ...
                    'DesiredOutputPower', 1, ...
                    'MaxPowerGain', 60);
            end
            data = qpsk_receive(obj.beamData, obj.QPSKFrameLength, ...
                obj.QPSKSamplesPerSymbol,obj.QPSKPreambleLength,...
                obj.QPSKmfCoeffs,obj.QPSKrrcCoeffs);
            obj.qpskData = obj.agc(data);
        end
        
        function updateViewers(obj)
            if obj.enableSpectrum
                if ~obj.hSpecAn.isVisible
                   show(obj.hSpecAn);
                end
                obj.hSpecAn(obj.beamData);
            else
                hide(obj.hSpecAn);
            end
            if obj.enableConstellation
                if ~obj.hConstellation.isVisible
                   show(obj.hConstellation);
                end
                obj.hConstellation(obj.qpskData);
            else
                hide(obj.hConstellation);
            end
        end
        
        function setupFPGAIO(obj)
            
            obj.hFPGA = fpga("Xilinx");

            addAXI4SlaveInterface(obj.hFPGA, ...
                "InterfaceID", "AXI4", ...
                "BaseAddress", 0xA0000000, ...
                "AddressRange", 0x10000);

            hPort_tx_steering_coeffs_src1_re = hdlcoder.DUTPort("tx_steering_coeffs_src1_re", ...
                "Direction", "IN", ...
                "DataType", numerictype(1,18,16), ...
                "Dimension", [1 4], ...
                "IOInterface", "AXI4", ...
                "IOInterfaceMapping", "0x170");

            hPort_tx_steering_coeffs_src1_im = hdlcoder.DUTPort("tx_steering_coeffs_src1_im", ...
                "Direction", "IN", ...
                "DataType", numerictype(1,18,16), ...
                "Dimension", [1 4], ...
                "IOInterface", "AXI4", ...
                "IOInterfaceMapping", "0x190");

            hPort_tx_steering_coeffs_src2_re = hdlcoder.DUTPort("tx_steering_coeffs_src2_re", ...
                "Direction", "IN", ...
                "DataType", numerictype(1,18,16), ...
                "Dimension", [1 4], ...
                "IOInterface", "AXI4", ...
                "IOInterfaceMapping", "0x130");

            hPort_tx_steering_coeffs_src2_im = hdlcoder.DUTPort("tx_steering_coeffs_src2_im", ...
                "Direction", "IN", ...
                "DataType", numerictype(1,18,16), ...
                "Dimension", [1 4], ...
                "IOInterface", "AXI4", ...
                "IOInterfaceMapping", "0x1B0");

            hPort_rx_steering_coeffs_re = hdlcoder.DUTPort("rx_steering_coeffs_re", ...
                "Direction", "IN", ...
                "DataType", numerictype(1,16,14), ...
                "Dimension", [1 4], ...
                "IOInterface", "AXI4", ...
                "IOInterfaceMapping", "0x1D0");

            hPort_rx_steering_coeffs_im = hdlcoder.DUTPort("rx_steering_coeffs_im", ...
                "Direction", "IN", ...
                "DataType", numerictype(1,16,14), ...
                "Dimension", [1 4], ...
                "IOInterface", "AXI4", ...
                "IOInterfaceMapping", "0x1F0");

            hPort_rx_cal_coeffs_re = hdlcoder.DUTPort("rx_cal_coeffs_re", ...
                "Direction", "IN", ...
                "DataType", numerictype(1,18,16), ...
                "Dimension", [1 4], ...
                "IOInterface", "AXI4", ...
                "IOInterfaceMapping", "0x210");

            hPort_rx_cal_coeffs_im = hdlcoder.DUTPort("rx_cal_coeffs_im", ...
                "Direction", "IN", ...
                "DataType", numerictype(1,18,16), ...
                "Dimension", [1 4], ...
                "IOInterface", "AXI4", ...
                "IOInterfaceMapping", "0x230");

            hPort_tx_src_gains = hdlcoder.DUTPort("tx_src_gains", ...
                "Direction", "IN", ...
                "DataType", numerictype(1,16,14), ...
                "Dimension", [1 2], ...
                "IOInterface", "AXI4", ...
                "IOInterfaceMapping", "0x160");

            hPort_rx_frame_size = hdlcoder.DUTPort("rx_frame_size", ...
                "Direction", "IN", ...
                "DataType", numerictype(0,32,0), ...
                "Dimension", [1 1], ...
                "IOInterface", "AXI4", ...
                "IOInterfaceMapping", "0x104");

            hPort_rx_auto_trig_period = hdlcoder.DUTPort("rx_auto_trig_period", ...
                "Direction", "IN", ...
                "DataType", numerictype(0,32,0), ...
                "Dimension", [1 1], ...
                "IOInterface", "AXI4", ...
                "IOInterfaceMapping", "0x10C");

            hPort_rx_auto_trig_en = hdlcoder.DUTPort("rx_auto_trig_en", ...
                "Direction", "IN", ...
                "DataType", numerictype('boolean'), ...
                "Dimension", [1 1], ...
                "IOInterface", "AXI4", ...
                "IOInterfaceMapping", "0x110");

            hPort_rx_capture_trig = hdlcoder.DUTPort("rx_capture_trig", ...
                "Direction", "IN", ...
                "DataType", numerictype('boolean'), ...
                "Dimension", [1 1], ...
                "IOInterface", "AXI4", ...
                "IOInterfaceMapping", "0x100");

            hPort_tx_nco_enable = hdlcoder.DUTPort("tx_nco_enable", ...
                "Direction", "IN", ...
                "DataType", numerictype('boolean'), ...
                "Dimension", [1 1], ...
                "IOInterface", "AXI4", ...
                "IOInterfaceMapping", "0x108");

            hPort_tx_nco_inc = hdlcoder.DUTPort("tx_nco_inc", ...
                "Direction", "IN", ...
                "DataType", numerictype(0,32,0), ...
                "Dimension", [1 1], ...
                "IOInterface", "AXI4", ...
                "IOInterfaceMapping", "0x114");

            hPort_BypassMVDR = hdlcoder.DUTPort("BypassMVDR", ...
                "Direction", "IN", ...
                "DataType", numerictype('boolean'), ...
                "Dimension", [1 1], ...
                "IOInterface", "AXI4", ...
                "IOInterfaceMapping", "0x118");

            hPort_BypassAnalog = hdlcoder.DUTPort("BypassAnalog", ...
                "Direction", "IN", ...
                "DataType", numerictype('boolean'), ...
                "Dimension", [1 1], ...
                "IOInterface", "AXI4", ...
                "IOInterfaceMapping", "0x11C");
            
            hPort_computedWeights = hdlcoder.DUTPort("computedWeights", ...
                "Direction", "OUT", ...
                "DataType", numerictype(1,24,16), ...
                "Dimension", [1 8], ...
                "IOInterface", "AXI4", ...
                "IOInterfaceMapping", "0x260");

            mapPort(obj.hFPGA, [hPort_tx_steering_coeffs_src1_re, hPort_tx_steering_coeffs_src1_im, hPort_tx_steering_coeffs_src2_re, hPort_tx_steering_coeffs_src2_im, hPort_rx_steering_coeffs_re, hPort_rx_steering_coeffs_im, hPort_rx_cal_coeffs_re, hPort_rx_cal_coeffs_im, hPort_tx_src_gains, hPort_rx_frame_size, hPort_rx_auto_trig_period, hPort_rx_auto_trig_en, hPort_rx_capture_trig, hPort_tx_nco_enable, hPort_tx_nco_inc, hPort_BypassMVDR, hPort_BypassAnalog, hPort_computedWeights]);

            % AXI4-Stream DMA
            addAXI4StreamInterface(obj.hFPGA, ...
                "InterfaceID", "AXI4-Stream DMA", ...
                "WriteEnable", false, ...
                "ReadEnable", true, ...
                "ReadTimeout", 0, ...
                "ReadFrameLength", obj.DMAReadFrameSize);

            hPort_S2MM_Data = hdlcoder.DUTPort("S2MM_Data", ...
                "Direction", "OUT", ...
                "DataType", 'uint32', ...
                "Dimension", [1 1], ...
                "IOInterface", "AXI4-Stream DMA");

            mapPort(obj.hFPGA, hPort_S2MM_Data);

            % Run dummy read to force DMA setup
            readPort(obj.hFPGA, "S2MM_Data");
        end
        
    end
end

