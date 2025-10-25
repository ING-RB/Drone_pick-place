classdef LIS3DHBlock < matlabshared.sensors.simulink.internal.SensorBlockBase...
        & matlabshared.sensors.simulink.internal.I2CSensorBase
    %LIS3DH accelerometer sensor.
    %
    %<a href="https://www.st.com/resource/en/datasheet/lis3dh.pdf">Device Datasheet</a>
    %
    %Copyright 2022-2023 The MathWorks, Inc.

    %#codegen
    properties(Access = protected, Constant)
        SensorName = "LIS3DH";
    end

    properties(Nontunable)
        I2CModule = '';
        I2CAddress = '0x18';
        IsActiveAccelerometer (1, 1) logical = true;
        FIFOSample = 2;
        SensorMode(1,:) char {matlab.system.mustBeMember(SensorMode,{'8-bit','10-bit','12-bit'})} = '12-bit';
        % +/-2g for range and 400Hz for ODR are chosen because of advanced interrupt feature. 
        % The default values for the parameters of advanced interrupt feature is calculated based on these ODRs.
        AccelerationRange(1,:) char {matlab.system.mustBeMember(AccelerationRange,{'+/-2g', '+/-4g', '+/-8g','+/-16g'})} = '+/-2g';
        AccelerometerODR1(1,:) char {matlab.system.mustBeMember(AccelerometerODR1,{'1','10','25','50','100','200','400','1600','5376'})} = '400'; 
        AccelerometerODR2(1,:) char {matlab.system.mustBeMember(AccelerometerODR2,{'1','10','25','50','100','200','400','1344'})} = '400';
        cutoffFrequency1(1,:) char {matlab.system.mustBeMember(cutoffFrequency1,{'0.02', '0.008', '0.004', '0.002'})} = '0.02';
        cutoffFrequency2(1,:) char {matlab.system.mustBeMember(cutoffFrequency2,{'0.2', '0.08', '0.04', '0.02'})} = '0.2';
        cutoffFrequency3(1,:) char {matlab.system.mustBeMember(cutoffFrequency3,{'0.5', '0.2', '0.1', '0.05'})} = '0.5';
        cutoffFrequency4(1,:) char {matlab.system.mustBeMember(cutoffFrequency4,{'1', '0.5', '0.2', '0.1'})} = '1';
        cutoffFrequency5(1,:) char {matlab.system.mustBeMember(cutoffFrequency5,{'2', '1', '0.5', '0.2'})} = '2';
        cutoffFrequency6(1,:) char {matlab.system.mustBeMember(cutoffFrequency6,{'4', '2', '1', '0.5'})} = '4';
        cutoffFrequency7(1,:) char {matlab.system.mustBeMember(cutoffFrequency7,{'8', '4', '2', '1'})} = '8';
        cutoffFrequency8(1,:) char {matlab.system.mustBeMember(cutoffFrequency8,{'32', '16', '8', '4'})} = '32';
        cutoffFrequency9(1,:) char {matlab.system.mustBeMember(cutoffFrequency9,{'100', '50', '25', '12'})} = '100';
        DataType(1,:) char {matlab.system.mustBeMember(DataType,{'single','double','int16'})} = 'single';
        IsADC3(1,:) char {matlab.system.mustBeMember(IsADC3,{'None','Temperature','Voltage (external input)'})} = 'None';
        cutoffFrequency=8;
        IsStatus (1, 1) logical              = true;
        IsOverrun (1,1) logical              = true;
        IsADC1 (1,1) logical                 = false;
        IsADC2 (1,1) logical                 = false;
        IsPendingFIFOSamples (1,1) logical   = false;
        IsFIFOEnabled (1,1) logical = false;
        HPF (1,1) logical = false;
    end
          
    properties(Nontunable)
        ClickInterrupt(1,:) char{matlab.system.mustBeMember(ClickInterrupt,{'INT1','INT2'})} = 'INT1';
        ConfigurableDetections1Interrupt(1,:) char{matlab.system.mustBeMember(ConfigurableDetections1Interrupt,{'INT1','INT2'})} = 'INT1';
        ConfigurableDetections2Interrupt(1,:) char{matlab.system.mustBeMember(ConfigurableDetections2Interrupt,{'INT1','INT2'})} = 'INT1';
    end 

    properties(Nontunable)
        IsActiveDataReadyInterrupt (1,1) logical = false;
        IsActiveFIFOOverrunInterrupt (1,1) logical = false;
        IsActiveClickInterrupt (1,1) logical = false;
        IsActiveConfigurableDetections1Interrupt (1,1) logical = false;
        IsActiveConfigurableDetections2Interrupt (1,1) logical = false;
    end 

    properties(Nontunable)
        IsClickEnable (1,1) logical = false;
        IsClickStatus (1,1) logical = false;
        ClickType(1,:) char {matlab.system.mustBeMember(ClickType,{'Single click','Double click'})} = 'Single click';
        ClickThreshold = 1.5;
        ClickTimeLimit = 0.3;
        ClickTimeLatency = 0.3;
        ClickTimeWindow = 0.3;
        ClickX (1,1) logical = true;  
        ClickY (1,1) logical = true;
        ClickZ (1,1) logical = false;
    end

    properties(Nontunable)
        NumberOfConfigurableDetections(1,:) char {matlab.system.mustBeMember(NumberOfConfigurableDetections,{'0','1','2'})} = '0';
        IsConfigurableDetections1Enable (1,1) logical = false;
        IsConfigurableDetections1Status (1,1) logical = false;
        ConfigurableDetections1Threshold = 1.5;
        ConfigurableDetections1Duration = 0.3;
        ConfigurableDetections1XLow (1,1) logical = false;
        ConfigurableDetections1XHigh (1,1) logical = true;
        ConfigurableDetections1YLow (1,1) logical = false;
        ConfigurableDetections1YHigh (1,1) logical = true;
        ConfigurableDetections1ZLow (1,1) logical = false;
        ConfigurableDetections1ZHigh (1,1) logical = true;
        ConfigurableDetections1Type(1,:) char {matlab.system.mustBeMember(ConfigurableDetections1Type,{'Inertial wake-up','Free-fall','6D position','6D movement','4D position','4D movement'})} = 'Inertial Wake-up';
    end 

    properties(Nontunable)
        IsConfigurableDetections2Enable (1,1) logical = false;
        IsConfigurableDetections2Status (1,1) logical = false;
        ConfigurableDetections2Threshold = 1.5;
        ConfigurableDetections2Duration = 0.3;
        ConfigurableDetections2XLow (1,1) logical = false;
        ConfigurableDetections2XHigh (1,1) logical = true;
        ConfigurableDetections2YLow (1,1) logical = false;
        ConfigurableDetections2YHigh (1,1) logical = true;
        ConfigurableDetections2ZLow (1,1) logical = false;
        ConfigurableDetections2ZHigh (1,1) logical = true;
        ConfigurableDetections2Type(1,:) char {matlab.system.mustBeMember(ConfigurableDetections2Type,{'Inertial wake-up','Free-fall','6D position','6D movement','4D position','4D movement'})} = 'Free-fall';
    end 

    properties(Nontunable, Access = protected)
        I2CBus
        AccelerometerODR =  400;
    end

    properties(Access = protected)
        PeripheralType = 'I2C'
    end

    properties(Hidden, Constant)
        I2CAddressSet = matlab.system.StringSet({'0x18','0x19'});
        cutoff1 = [0.02, 0.008, 0.004, 0.002];
        cutoff2 = [0.2, 0.08, 0.04, 0.02];
        cutoff3 = [0.5, 0.2, 0.1, 0.05];
        cutoff4 = [1, 0.5, 0.2, 0.1];
        cutoff5 = [2, 1, 0.5, 0.2];
        cutoff6 = [4, 2, 1, 0.5];
        cutoff7 = [8, 4, 2, 1];
        cutoff8 = [32, 16, 8, 4];
        cutoff9 = [100, 50, 25, 12];
        CutoffSet = [8,72,136,200];
    end
    
    methods 
        function set.IsActiveDataReadyInterrupt(obj,val)
            obj.IsActiveDataReadyInterrupt = obj.IsActiveAccelerometer*val;
        end 

        function set.ConfigurableDetections2Type(obj,val)
            if coder.target('MATLAB')
                if str2double(obj.NumberOfConfigurableDetections)==2
                    if strcmpi(obj.ConfigurableDetections1Type,val)
                        error(message('matlab_sensors:blockmask:lis3dhSameConfigurableDetections'));
                    end
                end
            end 
            obj.ConfigurableDetections2Type = val;
        end 

        function set.IsConfigurableDetections1Status(obj,val)
            obj.IsConfigurableDetections1Status = obj.IsConfigurableDetections1Enable * val;
        end 

        function set.IsConfigurableDetections2Status(obj,val)
            obj.IsConfigurableDetections2Status = obj.IsConfigurableDetections2Enable * val;
        end 
        
        function set.IsClickStatus(obj,val)
            obj.IsClickStatus = obj.IsClickEnable * val;
        end 
        
        function set.NumberOfConfigurableDetections(obj,val)
            obj.NumberOfConfigurableDetections = val;
            obj.IsConfigurableDetections1Enable = str2double(obj.NumberOfConfigurableDetections) >= 1;
            obj.IsConfigurableDetections2Enable = str2double(obj.NumberOfConfigurableDetections) == 2;
        end

        %The status output must not appear when accelerometer is not
        %selected
        function set.IsStatus(obj,val)
            obj.IsStatus = val*obj.IsActiveAccelerometer;
        end

        function set.FIFOSample(obj,val)
            if coder.target('MATLAB')
            validateattributes(val, {'numeric'}, ...
                { '>=', 1, '<=', 32, 'real', 'nonnan','nonempty','integer', 'scalar'}, ...
                    '',message('matlab_sensors:blockmask:lis3dhFIFOSamplesValidation').getString);
            end
            obj.FIFOSample = double(val);
        end

        function setPendingSamples(obj,val)
            obj.IsPendingFIFOSamples=val;
        end
        
        %FIFO and pending samples output must not appear when accelerometer
        %is not selected
        function set.IsFIFOEnabled(obj,val)
            obj.IsFIFOEnabled=val*obj.IsActiveAccelerometer;
            setPendingSamples(obj,obj.IsFIFOEnabled);
        end
    
        function set.ClickThreshold(obj,val)
             switch obj.AccelerationRange
                 case '+/-2g'
                      maximumvalue = 19.62;
                      minimumvalue = 0.1544;
                 case '+/-4g'
                      maximumvalue = 39.24;
                      minimumvalue = 0.3089;
                 case '+/-8g'
                      maximumvalue = 78.48;
                      minimumvalue = 0.6179;
                 case '+/-16g'
                      maximumvalue = 156.96;
                      minimumvalue = 1.2359;
                 otherwise 
                      maximumvalue = 156.96;
                      minimumvalue = 1.2359;
             end
            
             %This validation is performed only if the user selects click in output section. 
             %Without this check, updating the ODR or range will result in unwanted validation errors under click detection
            if obj.IsClickEnable
                if coder.target('MATLAB')
             validateattributes(val, {'numeric'}, ...
                { '>=', minimumvalue, '<=', maximumvalue, 'real', 'nonnan','nonempty','scalar'}, ...
                        '',message('matlab_sensors:blockmask:lis3dhClickThresholdValidation').getString);
                end
             end
             obj.ClickThreshold = val;
        end

       function set.ClickTimeLimit(obj,val)
            if strcmpi(obj.SensorMode,'8-bit')
                tempODR = obj.AccelerometerODR1;
            else
                tempODR = obj.AccelerometerODR2;
            end 
            switch str2double(tempODR)
                case 1
                    minimumvalue = 1.0000;
                    maximumvalue = 127.0000;
                case 10
                    minimumvalue = 0.1000;
                    maximumvalue = 12.7000;
                case 25
                    minimumvalue = 0.0400;
                    maximumvalue = 5.0800;
                case 50
                    minimumvalue = 0.0200;
                    maximumvalue = 2.5400;
                case 100
                    minimumvalue = 0.0100;
                    maximumvalue = 1.2700;
                case 200
                    minimumvalue = 0.0050;
                    maximumvalue = 0.6350;
                case 400
                    minimumvalue = 0.0025;
                    maximumvalue = 0.3175;
                case 1600
                    minimumvalue = 0.0006;
                    maximumvalue = 0.0794;
                case 1344
                    minimumvalue = 0.0007;
                    maximumvalue = 0.0945;
                case 5376
                    minimumvalue = 0.0002;
                    maximumvalue = 0.0236;
                otherwise
                    minimumvalue = 0.0007;
                    maximumvalue = 0.0945;
            end 

            %This validation is performed only if the user selects click in output section. 
            %Without this check, updating the ODR or range will result in unwanted validation errors under click detection
            if obj.IsClickEnable
                if coder.target('MATLAB')
                validateattributes(val, {'numeric'}, ...
                    { '>=', minimumvalue, '<=', maximumvalue, 'real', 'nonnan','nonempty','scalar'}, ...
                        '',message('matlab_sensors:blockmask:lis3dhClickTimelimitValidation').getString);
                end
            end
            obj.ClickTimeLimit = val;
        end 

       function set.ClickTimeLatency(obj,val)
            if strcmpi(obj.SensorMode,'8-bit')
                tempODR = obj.AccelerometerODR1;
            else
                tempODR = obj.AccelerometerODR2;
            end 
            switch str2double(tempODR)
                case 1
                    minimumvalue = 1.0000;
                    maximumvalue = 225.0000;
                case 10
                    minimumvalue = 0.1000;
                    maximumvalue = 22.5000;
                case 25
                    minimumvalue = 0.0400;
                    maximumvalue = 9.0000;
                case 50
                    minimumvalue = 0.0200;
                    maximumvalue = 4.5000;
                case 100
                    minimumvalue = 0.0100;
                    maximumvalue = 2.2500;
                case 200
                    minimumvalue = 0.0050;
                    maximumvalue = 1.1250;
                case 400
                    minimumvalue = 0.0025;
                    maximumvalue = 0.5625;
                case 1600
                    minimumvalue = 0.0006;
                    maximumvalue = 0.1406;
                case 1344
                    minimumvalue = 0.0007;
                    maximumvalue = 0.1674;
                case 5376
                    minimumvalue = 0.0002;
                    maximumvalue = 0.0419;
                otherwise
                    minimumvalue = 0.0007;
                    maximumvalue = 0.1674;
            end 
            
            %This validation is performed only if the user selects click in output section and the click type to be double click. 
            %Without this check, updating the ODR or range will result in unwanted validation errors under click detection.
            if obj.IsClickEnable
                if coder.target('MATLAB')
                    if strcmpi(obj.ClickType,'Double click')
                    validateattributes(val, {'numeric'}, ...
                        { '>=', minimumvalue, '<=', maximumvalue, 'real', 'nonnan','nonempty','scalar'}, ...
                            '',message('matlab_sensors:blockmask:lis3dhClickTimeLatencyValidation').getString);
                    end
                end 
            end 

            obj.ClickTimeLatency = val;
        end 

        function set.ClickTimeWindow(obj,val)
            if strcmpi(obj.SensorMode,'8-bit')
                tempODR = obj.AccelerometerODR1;
            else
                tempODR = obj.AccelerometerODR2;
            end 
            switch str2double(tempODR)
                case 1
                    minimumvalue = 1.0000;
                    maximumvalue = 225.0000;
                case 10
                    minimumvalue = 0.1000;
                    maximumvalue = 22.5000;
                case 25
                    minimumvalue = 0.0400;
                    maximumvalue = 9.0000;
                case 50
                    minimumvalue = 0.0200;
                    maximumvalue = 4.5000;
                case 100
                    minimumvalue = 0.0100;
                    maximumvalue = 2.2500;
                case 200
                    minimumvalue = 0.0050;
                    maximumvalue = 1.1250;
                case 400
                    minimumvalue = 0.0025;
                    maximumvalue = 0.5625;
                case 1600
                    minimumvalue = 0.0006;
                    maximumvalue = 0.1406;
                case 1344
                    minimumvalue = 0.0007;
                    maximumvalue = 0.1674;
                case 5376
                    minimumvalue = 0.0002;
                    maximumvalue = 0.0419;
                otherwise
                    minimumvalue = 0.0007;
                    maximumvalue = 0.1674;
            end

            %This validation is performed only if the user selects click in output section and the click type to be double click. 
            %Without this check, updating the ODR or range will result in unwanted validation errors under click detection.            
            if obj.IsClickEnable
                if coder.target('MATLAB')
                    if strcmpi(obj.ClickType,'Double click')
                    validateattributes(val, {'numeric'}, ...
                        { '>=', minimumvalue, '<=', maximumvalue, 'real', 'nonnan','nonempty','scalar'}, ...
                            '',message('matlab_sensors:blockmask:lis3dhClickTimeWindowValidation').getString);
                    end
                end 
            end
            obj.ClickTimeWindow = val;
        end         
        
        function set.ConfigurableDetections1Threshold(obj,val)
             switch obj.AccelerationRange
                 case '+/-2g'
                      maximumvalue = 19.62;
                      minimumvalue = 0.1544;
                 case '+/-4g'
                      maximumvalue = 39.24;
                      minimumvalue = 0.3089;
                 case '+/-8g'
                      maximumvalue = 78.48;
                      minimumvalue = 0.6179;
                 case '+/-16g'
                      maximumvalue = 156.96;
                      minimumvalue = 1.2359;
                 otherwise 
                      maximumvalue = 156.96;
                      minimumvalue = 1.2359;
             end

            %This validation is performed only if the user selects configurable event1 in output section. 
            %Without this check, updating the ODR or range will result in unwanted validation errors under configurable event1 detection.
            if obj.IsConfigurableDetections1Enable
                if coder.target('MATLAB')
                 validateattributes(val, {'double'}, ...
                    { '>=', minimumvalue, '<=', maximumvalue, 'real', 'nonnan','nonempty','scalar'}, ...
                        '',message('matlab_sensors:blockmask:lis3dhConfigurableDetections1ThresholdValidation').getString);
                end
             end
            obj.ConfigurableDetections1Threshold = val;
        end 

        function set.ConfigurableDetections1Duration(obj,val)
            if strcmpi(obj.SensorMode,'8-bit')
                tempODR = obj.AccelerometerODR1;
            else
                tempODR = obj.AccelerometerODR2;
            end 
            switch str2double(tempODR)
                case 1
                    minimumvalue = 1.0000;
                    maximumvalue = 127.0000;
                case 10
                    minimumvalue = 0.1000;
                    maximumvalue = 12.7000;
                case 25
                    minimumvalue = 0.0400;
                    maximumvalue = 5.0800;
                case 50
                    minimumvalue = 0.0200;
                    maximumvalue = 2.5400;
                case 100
                    minimumvalue = 0.0100;
                    maximumvalue = 1.2700;
                case 200
                    minimumvalue = 0.0050;
                    maximumvalue = 0.6350;
                case 400
                    minimumvalue = 0.0025;
                    maximumvalue = 0.3175;
                case 1600
                    minimumvalue = 0.0006;
                    maximumvalue = 0.0794;
                case 1344
                    minimumvalue = 0.0007;
                    maximumvalue = 0.0945;
                case 5376
                    minimumvalue = 0.0002;
                    maximumvalue = 0.0236;
                otherwise
                    minimumvalue = 0.0007;
                    maximumvalue = 0.0945;
            end 

            %This validation is performed only if the user selects configurable event1 in output section. 
            %Without this check, updating the ODR or range will result in unwanted validation errors under configurable event1 detection.
            if obj.IsConfigurableDetections1Enable
                if coder.target('MATLAB')
                validateattributes(val, {'numeric'}, ...
                    { '>=', minimumvalue, '<=', maximumvalue, 'real', 'nonnan','nonempty', 'scalar'}, ...
                        '',message('matlab_sensors:blockmask:lis3dhConfigurableDetections1DurationValidation').getString);
                end
            end
            obj.ConfigurableDetections1Duration = val;
            
        end 

        function set.ConfigurableDetections2Threshold(obj,val)
             switch obj.AccelerationRange
                 case '+/-2g'
                      maximumvalue = 19.62;
                      minimumvalue = 0.1544;
                 case '+/-4g'
                      maximumvalue = 39.24;
                      minimumvalue = 0.3089;
                 case '+/-8g'
                      maximumvalue = 78.48;
                      minimumvalue = 0.6179;
                 case '+/-16g'
                      maximumvalue = 156.96;
                      minimumvalue = 1.2359;
                 otherwise 
                      maximumvalue = 156.96;
                      minimumvalue = 1.2359;
             end 

            %This validation is performed only if the user selects configurable event2 in output section. 
            %Without this check, updating the ODR or range will result in unwanted validation errors under configurable event2 detection.
            if obj.IsConfigurableDetections2Enable
                if coder.target('MATLAB')
                 validateattributes(val, {'numeric'}, ...
                    { '>=', minimumvalue, '<=', maximumvalue, 'real', 'nonnan','nonempty','scalar'}, ...
                        '',message('matlab_sensors:blockmask:lis3dhConfigurableDetections2ThresholdValidation').getString);
                end
             end 
            obj.ConfigurableDetections2Threshold = val;
        end 

        function set.ConfigurableDetections2Duration(obj,val)
            if strcmpi(obj.SensorMode,'8-bit')
                tempODR = obj.AccelerometerODR1;
            else
                tempODR = obj.AccelerometerODR2;
            end 
            switch str2double(tempODR)
                case 1
                    minimumvalue = 1.0000;
                    maximumvalue = 127.0000;
                case 10
                    minimumvalue = 0.1000;
                    maximumvalue = 12.7000;
                case 25
                    minimumvalue = 0.0400;
                    maximumvalue = 5.0800;
                case 50
                    minimumvalue = 0.0200;
                    maximumvalue = 2.5400;
                case 100
                    minimumvalue = 0.0100;
                    maximumvalue = 1.2700;
                case 200
                    minimumvalue = 0.0050;
                    maximumvalue = 0.6350;
                case 400
                    minimumvalue = 0.0025;
                    maximumvalue = 0.3175;
                case 1600
                    minimumvalue = 0.0006;
                    maximumvalue = 0.0794;
                case 1344
                    minimumvalue = 0.0007;
                    maximumvalue = 0.0945;
                case 5376
                    minimumvalue = 0.0002;
                    maximumvalue = 0.0236;
                otherwise
                    minimumvalue = 0.0007;
                    maximumvalue = 0.0945;
            end 

            %This validation is performed only if the user selects configurable event2 in output section. 
            %Without this check, updating the ODR or range will result in unwanted validation errors under configurable event2 detection.            
            if obj.IsConfigurableDetections2Enable
                if coder.target('MATLAB')
                validateattributes(val, {'numeric'}, ...
                    { '>=', minimumvalue, '<=', maximumvalue, 'real', 'nonnan','nonempty', 'scalar'}, ...
                        '',message('matlab_sensors:blockmask:lis3dhConfigurableDetections2DurationValidation').getString);
                end
            end
            obj.ConfigurableDetections2Duration = val;
        end 
    end

    methods(Access = protected)
        function out = getActiveOutputsImpl(obj)
            out = cell(1,obj.IsActiveAccelerometer+obj.IsADC1+obj.IsADC2+obj.IsPendingFIFOSamples+obj.IsStatus+~strcmpi(obj.IsADC3,'None')+obj.IsClickStatus+obj.IsConfigurableDetections1Status+obj.IsConfigurableDetections2Status);
            count = 1;
            if obj.IsActiveAccelerometer
                out{count} = matlabshared.sensors.simulink.internal.Acceleration;
                switch obj.DataType
                    case 'single'
                        out{count}.OutputDataType = 'single';
                    case 'double'
                        out{count}.OutputDataType = 'double';
                    case 'int16'
                        out{count}.OutputDataType = 'int16';
                end
                if obj.IsFIFOEnabled
                    out{count}.OutputSize = [obj.FIFOSample,3];
                else
                    out{count}.OutputSize = [1,3];
                end
                count = count + 1;
            end

            if strcmpi(obj.IsADC3,'Temperature')
                out{count} = matlabshared.sensors.simulink.internal.Temperature;
                switch obj.DataType
                    case 'single'
                        out{count}.OutputDataType = 'single';
                    case 'double'
                        out{count}.OutputDataType = 'double';
                    case 'int16'
                        out{count}.OutputDataType = 'int16';
                end
                count = count + 1;
            end

            if obj.IsADC1
                out{count} = matlabshared.sensors.simulink.internal.Voltage;
                switch obj.DataType
                    case 'single'
                        out{count}.OutputDataType = 'single';
                    case 'double'
                        out{count}.OutputDataType = 'double';
                    case 'int16'
                        out{count}.OutputDataType = 'int16';
                end
                out{count}.pinNumber = "ADC1";
                out{count}.OutputName = 'ADC1 Voltage';
                count = count + 1;
            end

            if obj.IsADC2
                out{count} = matlabshared.sensors.simulink.internal.Voltage;
                switch obj.DataType
                    case 'single'
                        out{count}.OutputDataType = 'single';
                    case 'double'
                        out{count}.OutputDataType = 'double';
                    case 'int16'
                        out{count}.OutputDataType = 'int16';
                end
                out{count}.pinNumber = "ADC2";
                out{count}.OutputName = 'ADC2 Voltage';
                count = count + 1;
            end

            if strcmpi(obj.IsADC3,'Voltage (external input)')
                out{count} = matlabshared.sensors.simulink.internal.Voltage;
                switch obj.DataType
                    case 'single'
                        out{count}.OutputDataType = 'single';
                    case 'double'
                        out{count}.OutputDataType = 'double';
                    case 'int16'
                        out{count}.OutputDataType = 'int16';
                end
                out{count}.pinNumber = "ADC3";
                out{count}.OutputName = 'ADC3 Voltage';
                count = count + 1;
            end

            if obj.IsPendingFIFOSamples
                out{count} = matlabshared.sensors.simulink.internal.PendingSamples;
                out{count}.OutputDataType = 'uint8';
                out{count}.OutputName = 'Samples pending';
                count = count + 1;
            end

            if obj.IsClickStatus
                out{count} = matlabshared.sensors.simulink.internal.EventStatus;
                out{count}.Event = 'Click';
                out{count}.OutputName = 'Click status [X, Y, Z]';
                out{count}.OutputSize = [1,3];
                count = count + 1;
            end 

            if obj.IsConfigurableDetections1Status
                out{count} = matlabshared.sensors.simulink.internal.EventStatus;
                out{count}.Event = 'ConfigurableDetections1';
                %Incase of 4D detection, the output is of size 1x4 otherwise it is 1x6
                if strcmpi(obj.ConfigurableDetections1Type,'4D position') || strcmpi(obj.ConfigurableDetections1Type,'4D movement')
                    out{count}.OutputSize = [1,4];
                    out{count}.OutputName = obj.ConfigurableDetections1Type + " status [X, -X, Y, -Y]";
                else
                    if strcmpi(obj.ConfigurableDetections1Type,'6D position') || strcmpi(obj.ConfigurableDetections1Type,'6D movement')
                    out{count}.OutputSize = [1,6];
                        out{count}.OutputName = obj.ConfigurableDetections1Type + " status [X, -X, Y, -Y, Z, -Z]";
                    else
                        if strcmpi(obj.ConfigurableDetections1Type,'Inertial wake-up')
                            out{count}.OutputSize = [1,3];
                            out{count}.OutputName = obj.ConfigurableDetections1Type + " status [X, Y, Z]";
                        else
                            if strcmpi(obj.ConfigurableDetections1Type,'Free-fall')
                                out{count}.OutputSize = 1;
                                out{count}.OutputName = obj.ConfigurableDetections1Type + " status";
                            end
                        end
                    end
                end 
                count = count + 1;            
            end 

            if obj.IsConfigurableDetections2Status
                out{count} = matlabshared.sensors.simulink.internal.EventStatus;
                out{count}.Event = 'ConfigurableDetections2';
                %Incase of 4D detection, the output is of size 1x4 otherwise it is 1x6                

                if strcmpi(obj.ConfigurableDetections2Type,'4D position') || strcmpi(obj.ConfigurableDetections2Type,'4D movement')
                    out{count}.OutputSize = [1,4];
                    out{count}.OutputName = obj.ConfigurableDetections2Type + " status [X, -X, Y, -Y]";
                else
                    if strcmpi(obj.ConfigurableDetections2Type,'6D position') || strcmpi(obj.ConfigurableDetections2Type,'6D movement')
                    out{count}.OutputSize = [1,6];
                        out{count}.OutputName = obj.ConfigurableDetections2Type + " status [X, -X, Y, -Y, Z, -Z]";
                    else
                        if strcmpi(obj.ConfigurableDetections2Type,'Inertial wake-up')
                            out{count}.OutputSize = [1,3];
                            out{count}.OutputName = obj.ConfigurableDetections2Type + " status [X, Y, Z]";
                        else
                            if strcmpi(obj.ConfigurableDetections2Type,'Free-fall')
                                out{count}.OutputSize = 1;
                                out{count}.OutputName = obj.ConfigurableDetections2Type + " status";
                            end
                        end
                    end
                end 
                count = count + 1;
            end 

            if obj.IsStatus
                out{count} = matlabshared.sensors.simulink.internal.Status;
                out{count}.OutputName = 'Acceleration status';
                out{count}.OutputDataType = 'uint8';
            end
        end

        function createSensorObjectImpl(obj)
            switch obj.SensorMode
                case '8-bit'
                    obj.AccelerometerODR = obj.AccelerometerODR1;
                otherwise
                    obj.AccelerometerODR = obj.AccelerometerODR2;
            end

            switch obj.AccelerometerODR
                case '1'
                    obj.cutoffFrequency = obj.CutoffSet(obj.cutoff1==str2double(obj.cutoffFrequency1));
                case '10'
                    obj.cutoffFrequency = obj.CutoffSet(obj.cutoff2==str2double(obj.cutoffFrequency2));
                case '25'
                    obj.cutoffFrequency = obj.CutoffSet(obj.cutoff3==str2double(obj.cutoffFrequency3));
                case '50'
                    obj.cutoffFrequency = obj.CutoffSet(obj.cutoff4==str2double(obj.cutoffFrequency4));
                case '100'
                    obj.cutoffFrequency = obj.CutoffSet(obj.cutoff5==str2double(obj.cutoffFrequency5));
                case '200'
                    obj.cutoffFrequency = obj.CutoffSet(obj.cutoff6==str2double(obj.cutoffFrequency6));
                case '400'
                    obj.cutoffFrequency = obj.CutoffSet(obj.cutoff7==str2double(obj.cutoffFrequency7));
                case '1344'
                    obj.cutoffFrequency = obj.CutoffSet(obj.cutoff9==str2double(obj.cutoffFrequency9));
                case '1600'
                    obj.cutoffFrequency = obj.CutoffSet(obj.cutoff8==str2double(obj.cutoffFrequency8));
                case '5376'
                    obj.cutoffFrequency = obj.CutoffSet(obj.cutoff9==str2double(obj.cutoffFrequency9));
                otherwise
                    obj.cutoffFrequency =8;
            end

            coder.extrinsic('matlabshared.sensors.simulink.internal.getNumericValue');
            coder.extrinsic('sscanf');
            coder.extrinsic('strcmpi');
            accelrange = coder.const(sscanf(obj.AccelerationRange,'+/-%fg'));

            adc_enable = obj.IsADC1+obj.IsADC2+strcmp(obj.IsADC3,'Voltage (external input)');
            
            %The click, configurable event1 and configurable event2 parameters are passed to lis3dh as structures
            event1data.IsEvent = obj.IsConfigurableDetections1Enable;
            event1data.EventType = obj.ConfigurableDetections1Type;
            event1data.EventAxis = double([obj.ConfigurableDetections1XLow,obj.ConfigurableDetections1XHigh,obj.ConfigurableDetections1YLow,obj.ConfigurableDetections1YHigh,obj.ConfigurableDetections1ZLow,obj.ConfigurableDetections1ZHigh]);
            event1data.EventThreshold = obj.ConfigurableDetections1Threshold;
            event1data.EventDuration = obj.ConfigurableDetections1Duration;
            event1data.EventInterrupt = obj.IsActiveConfigurableDetections1Interrupt;
            event1data.EventInterruptPin = obj.ConfigurableDetections1Interrupt;

            event2data.IsEvent = obj.IsConfigurableDetections2Enable;
            event2data.EventType = obj.ConfigurableDetections2Type;
            event2data.EventAxis = double([obj.ConfigurableDetections2XLow,obj.ConfigurableDetections2XHigh,obj.ConfigurableDetections2YLow,obj.ConfigurableDetections2YHigh,obj.ConfigurableDetections2ZLow,obj.ConfigurableDetections2ZHigh]);
            event2data.EventThreshold = obj.ConfigurableDetections2Threshold;
            event2data.EventDuration = obj.ConfigurableDetections2Duration;
            event2data.EventInterrupt = obj.IsActiveConfigurableDetections2Interrupt;
            event2data.EventInterruptPin = obj.ConfigurableDetections2Interrupt;

            clickdata.IsClick = obj.IsClickEnable;
            clickdata.ClickType = obj.ClickType;
            clickdata.ClickAxis = [obj.ClickX,obj.ClickY,obj.ClickZ];
            clickdata.ClickThreshold = obj.ClickThreshold;
            clickdata.ClickTimeLimit = obj.ClickTimeLimit;
            clickdata.ClickTimeLatency = obj.ClickTimeLatency;
            clickdata.ClickTimeWindow = obj.ClickTimeWindow;
            clickdata.ClickInterrupt = obj.IsActiveClickInterrupt;
            clickdata.ClickInterruptPin = obj.ClickInterrupt;

            %str2double conversion causes real and imaginary values during codegen
            %Only real part is passed to lis3dh.m
            obj.SensorObject = lis3dh(obj.HwUtilityObject, ...
                'Bus',obj.I2CBus,'I2CAddress',obj.I2CAddress,'AccelerometerRange',accelrange,'AccelerometerODR',real(str2double(obj.AccelerometerODR)), ...
                'IsActiveDataReadyInterrupt',obj.IsActiveDataReadyInterrupt,'IsActiveFIFOOverrunInterrupt',obj.IsActiveFIFOOverrunInterrupt,'DataType',obj.DataType, ...
                'Mode',obj.SensorMode,'HPF',obj.HPF,'Cutoff',obj.cutoffFrequency,'FIFO',obj.IsFIFOEnabled,'FiFoSamples',obj.FIFOSample,'Temperature',double(strcmp(obj.IsADC3,'Temperature')),'Status',obj.IsStatus,'ADC',adc_enable,'ADCPinCount',obj.IsADC1+obj.IsADC2+strcmp(obj.IsADC3,'Voltage (external input)'),'Click',clickdata,'ConfigurableDetections1',event1data,'ConfigurableDetections2',event2data);
            
        end
    end

    methods(Access = protected)
        function varargout = readSensorDataHook(obj)
            % when status is enabled, status register
            % needs to be read before other measurements. Making this change
            % in getActiveOutputsImpl to read the status first will result in
            % status coming on top of the block display, hence overloading
            % the readSensorDataHook
            timestamp = 0;
            idx = 0;
            if obj.IsStatus
                [out,timestamp] = obj.OutputModules{end}.readSensor(obj);
                % Check if outputs other than status is required
                if obj.NumOutputs>1
                    for i = 1:obj.NumOutputs-1
                        [varargout{i},timestamp] = obj.OutputModules{i}.readSensor(obj);
                    end
                    idx = i;
                end
                idx = idx + 1;
                varargout{idx} = out;
            else
                for i = 1:obj.NumOutputs
                    [varargout{i},timestamp] = obj.OutputModules{i}.readSensor(obj);
                end
                idx = i;
            end
            idx = idx + 1 ;
            varargout{idx} = timestamp;
        end
    end

    methods(Access = protected)
        % Block mask display
        function maskDisplayCmds = getMaskDisplayImpl(obj)
            outport_label = [];
            num = getNumOutputsImpl(obj);
            if num > 0
                outputs = cell(1,num);
                [outputs{1:num}] = getOutputNamesImpl(obj);
                for i = 1:num
                    outport_label = [outport_label 'port_label(''output'',' num2str(i) ',''' outputs{i} ''');' ]; %#ok<AGROW>
                end
            end
            maskDisplayCmds = [ ...
                ['color(''white'');',newline],...
                ['plot([100,100,100,100]*1,[100,100,100,100]*1);',newline]...
                ['plot([100,100,100,100]*0,[100,100,100,100]*0);',newline]...
                ['color(''blue'');',newline] ...
                ['text(38, 92, ','''',obj.Logo,'''',',''horizontalAlignment'', ''right'');',newline],...
                ['color(''black'');',newline], ...
                ['image(imread(fullfile(matlabshared.sensors.internal.getSensorRootDir,''+matlabshared'',''+sensors'',''+simulink'',''+internal'',''IMU_image.png'')),''center'');', newline], ...
                ['text(52,12,' [''' ' 'LIS3DH' ''',''horizontalAlignment'',''right'');' newline]]   ...
                outport_label
                ];
        end

        function validatePropertiesImpl(obj)
            %Validate related or interdependent property values
            %Check whether all outputs are disabled. In that case an error is
            %thrown asking user to enable atleast one output
            if ~obj.IsActiveAccelerometer && ~obj.IsADC1 && ~obj.IsADC2 && strcmpi(obj.IsADC3,'None') && ~obj.IsClickStatus && ~obj.IsConfigurableDetections1Status && ~obj.IsConfigurableDetections2Status
                error(message('matlab_sensors:general:SensorsNoOutputs'));
            end
        end

        function flag = isInactivePropertyImpl(obj, prop)
            flag = false;
            switch prop
                case "IsStatus"
                    flag = ~obj.IsActiveAccelerometer;
                case "FIFOSample"
                        if obj.IsFIFOEnabled
                            flag = false;
                        else
                            flag = true;
                        end
                case "IsFIFOEnabled"
                        flag = false;
                case "BitRate"
                    flag = false;
                case "SensorMode"
                    flag = false;
                case "AccelerationRange"
                    flag = false;
                case "HPF"
                    flag = false;
                case "AccelerometerODR1"
                     flag = ~strcmpi(obj.SensorMode,"8-bit");
                case "AccelerometerODR2"
                     flag = strcmpi(obj.SensorMode,"8-bit");
                case "cutoffFrequency1"
                        if strcmpi(obj.SensorMode,"8-bit")
                            if strcmpi(obj.AccelerometerODR1,'1')
                                flag = false | ~obj.HPF ;
                            else
                                flag = true;
                            end
                        else
                            if strcmpi(obj.AccelerometerODR2,'1')
                                flag = false | ~obj.HPF;
                            else
                                flag = true;
                            end
                        end
                case "cutoffFrequency2"
                        if strcmpi(obj.SensorMode,"8-bit")
                            if strcmpi(obj.AccelerometerODR1,'10')
                                flag = false | ~obj.HPF;
                            else
                                flag = true;
                            end
                        else
                            if strcmpi(obj.AccelerometerODR2,'10')
                                flag = false | ~obj.HPF;
                            else
                                flag = true;
                            end
                        end
                case "cutoffFrequency3"
                        if strcmpi(obj.SensorMode,"8-bit")
                            if strcmpi(obj.AccelerometerODR1,'25')
                                flag = false | ~obj.HPF;
                            else
                                flag = true;
                            end
                        else
                            if strcmpi(obj.AccelerometerODR2,'25')
                                flag = false | ~obj.HPF;
                            else
                                flag = true;
                            end
                        end
                case "cutoffFrequency4"
                        if strcmpi(obj.SensorMode,"8-bit")
                            if strcmpi(obj.AccelerometerODR1,'50')
                                flag = false | ~obj.HPF;
                            else
                                flag = true;
                            end
                        else
                            if strcmpi(obj.AccelerometerODR2,'50')
                                flag = false | ~obj.HPF;
                            else
                                flag = true;
                            end
                        end
                case "cutoffFrequency5"
                        if strcmpi(obj.SensorMode,"8-bit")
                            if strcmpi(obj.AccelerometerODR1,'100')
                                flag = false | ~obj.HPF;
                            else
                                flag = true;
                            end
                        else
                            if strcmpi(obj.AccelerometerODR2,'100')
                                flag = false | ~obj.HPF;
                            else
                                flag = true;
                            end
                        end
                case "cutoffFrequency6"
                        if strcmpi(obj.SensorMode,"8-bit")
                            if strcmpi(obj.AccelerometerODR1,'200')
                                flag = false | ~obj.HPF;
                            else
                                flag = true;
                            end
                        else
                            if strcmpi(obj.AccelerometerODR2,'200')
                                flag = false | ~obj.HPF;
                            else
                                flag = true;
                            end
                        end
                case "cutoffFrequency7"
                        if strcmpi(obj.SensorMode,"8-bit")
                            if strcmpi(obj.AccelerometerODR1,'400')
                                flag = false | ~obj.HPF;
                            else
                                flag = true;
                            end
                        else
                            if strcmpi(obj.AccelerometerODR2,'400')
                                flag = false | ~obj.HPF;
                            else
                                flag = true;
                            end
                        end
                case "cutoffFrequency8"
                        if strcmpi(obj.SensorMode,"8-bit")
                            if strcmpi(obj.AccelerometerODR1,'1600')
                                flag = false | ~obj.HPF;
                            else
                                flag = true;
                            end
                        else
                                flag = true;
                        end
                case "cutoffFrequency9"
                        if strcmpi(obj.SensorMode,"8-bit")
                            if strcmpi(obj.AccelerometerODR1,'5376')
                                flag = false | ~obj.HPF;
                            else
                                flag = true;
                            end
                        else
                            if strcmpi(obj.AccelerometerODR2,'1344')
                                flag = false | ~obj.HPF;
                            else
                                flag = true;
                            end
                        end
                case "Click"
                    flag = ~obj.IsClickEnable;
                case "ClickType"
                    flag = ~obj.IsClickEnable;
                case "ClickThreshold"
                    flag = ~obj.IsClickEnable ;
                case "ClickTimeLimit"
                    flag = ~obj.IsClickEnable;
                case "ClickTimeLatency"
                    flag = ~ ( obj.IsClickEnable && strcmpi(obj.ClickType,"Double click") );
                case "ClickTimeWindow" 
                    flag = ~ ( obj.IsClickEnable && strcmpi(obj.ClickType,"Double click") );
                case "ClickX" 
                    flag = ~obj.IsClickEnable;
                case "ClickY" 
                    flag = ~obj.IsClickEnable;
                case "ClickZ"       
                    flag = ~obj.IsClickEnable;
                case "ConfigurableDetections1Type"
                    flag = ~obj.IsConfigurableDetections1Enable;
                case "ConfigurableDetections2Type"
                    flag = ~obj.IsConfigurableDetections2Enable;
                case "ConfigurableDetections1Threshold"
                    flag = ~obj.IsConfigurableDetections1Enable;
                case "ConfigurableDetections1Duration"
                    flag = ~obj.IsConfigurableDetections1Enable;
                case "ConfigurableDetections2Threshold"
                    flag = ~obj.IsConfigurableDetections2Enable;
                case "ConfigurableDetections2Duration"
                    flag = ~obj.IsConfigurableDetections2Enable;
                case "IsActiveClickInterrupt"
                    flag = ~obj.IsClickEnable;
                case "IsActiveConfigurableDetections1Interrupt"
                    flag = ~obj.IsConfigurableDetections1Enable;
                case "IsActiveConfigurableDetections2Interrupt"
                    flag = ~obj.IsConfigurableDetections2Enable;
                case "ClickInterrupt"
                    if obj.IsClickEnable
                        flag = ~obj.IsActiveClickInterrupt;
                    else
                        flag = true;
                    end
                case "ConfigurableDetections1Interrupt"
                    if obj.IsConfigurableDetections1Enable
                        flag = ~obj.IsActiveConfigurableDetections1Interrupt;
                    else
                        flag = true;
                    end
                case "ConfigurableDetections2Interrupt"
                    if obj.IsConfigurableDetections2Enable
                        flag = ~obj.IsActiveConfigurableDetections2Interrupt;
                    else
                        flag = true;
                    end
                case "IsActiveFIFOOverrunInterrupt"
                    if obj.IsFIFOEnabled
                        flag = false; %flag = ~obj.IsActiveAccelerometer;
                    else
                        flag = true;
                    end
                case "IsActiveDataReadyInterrupt"
                    flag = false; %flag =  ~obj.IsActiveAccelerometer ;
                case "IsConfigurableDetections1Status"
                    flag = ~obj.IsConfigurableDetections1Enable;
                case "IsConfigurableDetections2Status"
                    flag = ~obj.IsConfigurableDetections2Enable;
                case "IsClickStatus"
                    flag = ~obj.IsClickEnable;
                case "ConfigurableDetections1XLow"
                    if obj.IsConfigurableDetections1Enable
                        flag = strcmpi(obj.ConfigurableDetections1Type,'Free-fall') || strcmpi(obj.ConfigurableDetections1Type,'Inertial wake-up');
                    else
                        flag = true;
                    end
                case "ConfigurableDetections1XHigh"
                    if obj.IsConfigurableDetections1Enable
                        flag = strcmpi(obj.ConfigurableDetections1Type,'Free-fall');
                    else
                        flag = true;
                    end
                case "ConfigurableDetections2XLow"
                    if obj.IsConfigurableDetections2Enable
                        flag = strcmpi(obj.ConfigurableDetections2Type,'Free-fall') || strcmpi(obj.ConfigurableDetections2Type,'Inertial wake-up');
                    else
                        flag = true;
                    end
                case "ConfigurableDetections2XHigh"
                    if obj.IsConfigurableDetections2Enable
                        flag = strcmpi(obj.ConfigurableDetections2Type,'Free-fall');
                    else
                        flag = true;
                    end

                case "ConfigurableDetections1YLow"
                    if obj.IsConfigurableDetections1Enable
                        flag = strcmpi(obj.ConfigurableDetections1Type,'Free-fall') || strcmpi(obj.ConfigurableDetections1Type,'Inertial wake-up');
                    else
                        flag = true;
                    end
                case "ConfigurableDetections1YHigh"
                    if obj.IsConfigurableDetections1Enable
                        flag = strcmpi(obj.ConfigurableDetections1Type,'Free-fall');
                    else
                        flag = true;
                    end
                case "ConfigurableDetections2YLow"
                    if obj.IsConfigurableDetections2Enable
                        flag = strcmpi(obj.ConfigurableDetections2Type,'Free-fall') || strcmpi(obj.ConfigurableDetections2Type,'Inertial wake-up');
                    else
                        flag = true;
                    end
                case "ConfigurableDetections2YHigh"
                    if obj.IsConfigurableDetections2Enable
                        flag = strcmpi(obj.ConfigurableDetections2Type,'Free-fall');
                    else
                        flag = true;
                    end
                case "ConfigurableDetections1ZLow"
                    if obj.IsConfigurableDetections1Enable
                        flag = strcmpi(obj.ConfigurableDetections1Type,'4D position') || strcmpi(obj.ConfigurableDetections1Type,'4D movement');
                        flag = flag || strcmpi(obj.ConfigurableDetections1Type,'Free-fall') || strcmpi(obj.ConfigurableDetections1Type,'Inertial wake-up');
                    else
                        flag = true;
                    end
                case "ConfigurableDetections1ZHigh"
                    if obj.IsConfigurableDetections1Enable
                        flag = strcmpi(obj.ConfigurableDetections1Type,'4D position') || strcmpi(obj.ConfigurableDetections1Type,'4D movement');
                        flag = flag || strcmpi(obj.ConfigurableDetections1Type,'Free-fall');
                    else
                        flag = true;
                    end
                case "ConfigurableDetections2ZLow"
                    if obj.IsConfigurableDetections2Enable
                        flag = strcmpi(obj.ConfigurableDetections2Type,'4D position') || strcmpi(obj.ConfigurableDetections2Type,'4D movement');
                        flag = flag || strcmpi(obj.ConfigurableDetections2Type,'Free-fall') || strcmpi(obj.ConfigurableDetections2Type,'Inertial wake-up');
                    else
                        flag = true;
                    end
                case "ConfigurableDetections2ZHigh"
                    if obj.IsConfigurableDetections2Enable
                        flag = strcmpi(obj.ConfigurableDetections2Type,'4D position') || strcmpi(obj.ConfigurableDetections2Type,'4D movement');
                        flag = flag || strcmpi(obj.ConfigurableDetections2Type,'Free-fall');
                    else
                        flag = true;
                    end
            end
        end
    end

    methods(Access = protected, Static)
        function header = getHeaderImpl()
            header = matlab.system.display.Header(mfilename('class'), 'Title',...
                'LIS3DH Accelerometer Sensor','Text',message('matlab_sensors:blockmask:lis3dhMaskDescription').getString,'ShowSourceLink',false);
        end

        function groups = getPropertyGroupsImpl()
            i2cModule = matlab.system.display.internal.Property('I2CModule', 'Description', 'I2C module');
            i2cAddress = matlab.system.display.internal.Property('I2CAddress', 'Description',  'matlab_sensors:blockmask:lis3dhI2CAddress');
            bitRate=matlab.system.display.internal.Property('BitRate', 'Description', 'Bit rate','IsGraphical',false);
            i2cProperties = matlab.system.display.Section('PropertyList', {i2cModule,i2cAddress,bitRate});

            acclerometerProp = matlab.system.display.internal.Property('IsActiveAccelerometer', 'Description', 'matlab_sensors:blockmask:lis3dhAcceleration');
            ADCPin1Prop      = matlab.system.display.internal.Property('IsADC1', 'Description','matlab_sensors:blockmask:lis3dhADC1'); %'Enable ADC1 (External input)');
            ADCPin2Prop      = matlab.system.display.internal.Property('IsADC2', 'Description', 'matlab_sensors:blockmask:lis3dhADC2','Row',matlab.system.display.internal.Row.current);
            ADCPin3Prop      = matlab.system.display.internal.Property('IsADC3','Description', 'matlab_sensors:blockmask:lis3dhADC3','Row',matlab.system.display.internal.Row.current);
            statusProp       = matlab.system.display.internal.Property('IsStatus','Description', 'matlab_sensors:blockmask:lis3dhStatus');
            mainSelectOutputs    = matlab.system.display.Section('Title', 'Select outputs', 'PropertyList', {acclerometerProp,ADCPin3Prop,ADCPin1Prop,ADCPin2Prop,statusProp});

            accelerometerODR1 = matlab.system.display.internal.Property('AccelerometerODR1','Description', 'matlab_sensors:blockmask:lis3dhODR');
            accelerometerODR2 = matlab.system.display.internal.Property('AccelerometerODR2','Description', 'matlab_sensors:blockmask:lis3dhODR');
            sensorMode=matlab.system.display.internal.Property('SensorMode', 'Description', 'matlab_sensors:blockmask:lis3dhResolution','IsGraphical',true);
            accelerationRange = matlab.system.display.internal.Property('AccelerationRange','Description', 'matlab_sensors:blockmask:lis3dhRange');
            HPF = matlab.system.display.internal.Property('HPF','Description','matlab_sensors:blockmask:lis3dhHPF');
            cutoffFrequency1 = matlab.system.display.internal.Property('cutoffFrequency1','Description','matlab_sensors:blockmask:lis3dhCutoff');
            cutoffFrequency2 = matlab.system.display.internal.Property('cutoffFrequency2','Description','matlab_sensors:blockmask:lis3dhCutoff');
            cutoffFrequency3 = matlab.system.display.internal.Property('cutoffFrequency3','Description','matlab_sensors:blockmask:lis3dhCutoff');
            cutoffFrequency4 = matlab.system.display.internal.Property('cutoffFrequency4','Description','matlab_sensors:blockmask:lis3dhCutoff');
            cutoffFrequency5 = matlab.system.display.internal.Property('cutoffFrequency5','Description','matlab_sensors:blockmask:lis3dhCutoff');
            cutoffFrequency6 = matlab.system.display.internal.Property('cutoffFrequency6','Description','matlab_sensors:blockmask:lis3dhCutoff');
            cutoffFrequency7 = matlab.system.display.internal.Property('cutoffFrequency7','Description','matlab_sensors:blockmask:lis3dhCutoff');
            cutoffFrequency8 = matlab.system.display.internal.Property('cutoffFrequency8','Description','matlab_sensors:blockmask:lis3dhCutoff');
            cutoffFrequency9 = matlab.system.display.internal.Property('cutoffFrequency9','Description','matlab_sensors:blockmask:lis3dhCutoff');
            FIFOSample = matlab.system.display.internal.Property('FIFOSample','Description', 'matlab_sensors:blockmask:lis3dhFIFOSamples');
            fifoProp = matlab.system.display.internal.Property('IsFIFOEnabled', 'Description', 'matlab_sensors:blockmask:lis3dhEnableFIFO');
            interruptProp    = matlab.system.display.internal.Property('IsActiveDataReadyInterrupt', 'Description', 'matlab_sensors:blockmask:lis3dhDataInterrupt');
            IsActiveFIFOOverrunInterrupt = matlab.system.display.internal.Property('IsActiveFIFOOverrunInterrupt', 'Description', 'matlab_sensors:blockmask:lis3dhFIFOOverrunInterrupt');
            commonSettingSection = matlab.system.display.Section('Title', '', 'PropertyList', {sensorMode,accelerometerODR1,accelerometerODR2,accelerationRange,fifoProp,FIFOSample,IsActiveFIFOOverrunInterrupt,HPF,cutoffFrequency1,cutoffFrequency2, cutoffFrequency3, cutoffFrequency4, cutoffFrequency5, cutoffFrequency6, cutoffFrequency7, cutoffFrequency8, cutoffFrequency9,interruptProp});
            
            ClickEnable = matlab.system.display.internal.Property('IsClickEnable','Description','matlab_sensors:blockmask:lis3dhEnableClick');
            clickProp        = matlab.system.display.internal.Property('IsClickStatus', 'Description', 'matlab_sensors:blockmask:lis3dhClickProp');
            ClickType = matlab.system.display.internal.Property('ClickType','Description','matlab_sensors:blockmask:lis3dhClickType');
            ClickThreshold = matlab.system.display.internal.Property('ClickThreshold','Description','matlab_sensors:blockmask:lis3dhThreshold');
            ClickTimeLimit = matlab.system.display.internal.Property('ClickTimeLimit','Description','matlab_sensors:blockmask:lis3dhTimeLimit');
            ClickTimeLatency = matlab.system.display.internal.Property('ClickTimeLatency','Description','matlab_sensors:blockmask:lis3dhTimeLatency');
            ClickTimeWindow = matlab.system.display.internal.Property('ClickTimeWindow','Description','matlab_sensors:blockmask:lis3dhTimeWindow');
            ClickX = matlab.system.display.internal.Property('ClickX','Description', 'matlab_sensors:blockmask:lis3dhPositiveXDirection');
            ClickY = matlab.system.display.internal.Property('ClickY','Description', 'matlab_sensors:blockmask:lis3dhPositiveYDirection','Row',matlab.system.display.internal.Row.current);
            ClickZ = matlab.system.display.internal.Property('ClickZ','Description', 'matlab_sensors:blockmask:lis3dhPositiveZDirection','Row',matlab.system.display.internal.Row.current);
            IsActiveClickInterrupt = matlab.system.display.internal.Property('IsActiveClickInterrupt', 'Description', 'matlab_sensors:blockmask:lis3dhClickInterrupt');
            ClickInterrupt = matlab.system.display.internal.Property('ClickInterrupt','Description','matlab_sensors:blockmask:lis3dhInterruptPin','Row',matlab.system.display.internal.Row.current);
            clickSection = matlab.system.display.Section('Title','Click detection','PropertyList', {ClickEnable,ClickType,ClickThreshold,ClickTimeLimit,ClickTimeLatency,ClickTimeWindow,ClickX,ClickY,ClickZ,IsActiveClickInterrupt,ClickInterrupt,clickProp});

            EventEnable = matlab.system.display.internal.Property('NumberOfConfigurableDetections','Description','matlab_sensors:blockmask:lis3dhEnableConfigurableDetections');
            eventSection = matlab.system.display.Section('Title','','PropertyList', {EventEnable});
            
            ConfigurableDetections1Prop = matlab.system.display.internal.Property('IsConfigurableDetections1Status','Description','Detection status');
            ConfigurableDetections1Type = matlab.system.display.internal.Property('ConfigurableDetections1Type','Description','Detect','Row',matlab.system.display.internal.Row.current);
            ConfigurableDetections1Threshold = matlab.system.display.internal.Property('ConfigurableDetections1Threshold','Description','matlab_sensors:blockmask:lis3dhThreshold');
            ConfigurableDetections1Duration = matlab.system.display.internal.Property('ConfigurableDetections1Duration','Description','matlab_sensors:blockmask:lis3dhDuration');
            ConfigurableDetections1XHigh = matlab.system.display.internal.Property('ConfigurableDetections1XHigh','Description','matlab_sensors:blockmask:lis3dhPositiveXDirection');
            ConfigurableDetections1YHigh = matlab.system.display.internal.Property('ConfigurableDetections1YHigh','Description','matlab_sensors:blockmask:lis3dhPositiveYDirection','Row',matlab.system.display.internal.Row.current);
            ConfigurableDetections1ZHigh = matlab.system.display.internal.Property('ConfigurableDetections1ZHigh','Description','matlab_sensors:blockmask:lis3dhPositiveZDirection','Row',matlab.system.display.internal.Row.current);
            ConfigurableDetections1XLow = matlab.system.display.internal.Property('ConfigurableDetections1XLow','Description','matlab_sensors:blockmask:lis3dhNegativeXDirection');
            ConfigurableDetections1YLow = matlab.system.display.internal.Property('ConfigurableDetections1YLow','Description','matlab_sensors:blockmask:lis3dhNegativeYDirection','Row',matlab.system.display.internal.Row.current);
            ConfigurableDetections1ZLow = matlab.system.display.internal.Property('ConfigurableDetections1ZLow','Description','matlab_sensors:blockmask:lis3dhNegativeZDirection','Row',matlab.system.display.internal.Row.current);
            IsActiveConfigurableDetections1Interrupt = matlab.system.display.internal.Property('IsActiveConfigurableDetections1Interrupt', 'Description', 'Generate interrupt');
            ConfigurableDetections1Interrupt = matlab.system.display.internal.Property('ConfigurableDetections1Interrupt','Description','matlab_sensors:blockmask:lis3dhInterruptPin','Row',matlab.system.display.internal.Row.current);
            event1Section = matlab.system.display.Section('Title','Configurable detections 1','PropertyList', {ConfigurableDetections1Type,ConfigurableDetections1XHigh,ConfigurableDetections1YHigh,ConfigurableDetections1ZHigh,ConfigurableDetections1XLow,ConfigurableDetections1YLow,ConfigurableDetections1ZLow,ConfigurableDetections1Threshold,ConfigurableDetections1Duration,IsActiveConfigurableDetections1Interrupt,ConfigurableDetections1Interrupt,ConfigurableDetections1Prop});

            ConfigurableDetections2Prop = matlab.system.display.internal.Property('IsConfigurableDetections2Status','Description','Detection status');
            ConfigurableDetections2Type = matlab.system.display.internal.Property('ConfigurableDetections2Type','Description','Detect','Row',matlab.system.display.internal.Row.current);
            ConfigurableDetections2Threshold = matlab.system.display.internal.Property('ConfigurableDetections2Threshold','Description','matlab_sensors:blockmask:lis3dhThreshold');
            ConfigurableDetections2Duration = matlab.system.display.internal.Property('ConfigurableDetections2Duration','Description','matlab_sensors:blockmask:lis3dhDuration');
            ConfigurableDetections2XHigh = matlab.system.display.internal.Property('ConfigurableDetections2XHigh','Description','matlab_sensors:blockmask:lis3dhPositiveXDirection');
            ConfigurableDetections2YHigh = matlab.system.display.internal.Property('ConfigurableDetections2YHigh','Description','matlab_sensors:blockmask:lis3dhPositiveYDirection','Row',matlab.system.display.internal.Row.current);
            ConfigurableDetections2ZHigh = matlab.system.display.internal.Property('ConfigurableDetections2ZHigh','Description','matlab_sensors:blockmask:lis3dhPositiveZDirection','Row',matlab.system.display.internal.Row.current);
            ConfigurableDetections2XLow = matlab.system.display.internal.Property('ConfigurableDetections2XLow','Description','matlab_sensors:blockmask:lis3dhNegativeXDirection');
            ConfigurableDetections2YLow = matlab.system.display.internal.Property('ConfigurableDetections2YLow','Description','matlab_sensors:blockmask:lis3dhNegativeYDirection','Row',matlab.system.display.internal.Row.current);
            ConfigurableDetections2ZLow = matlab.system.display.internal.Property('ConfigurableDetections2ZLow','Description','matlab_sensors:blockmask:lis3dhNegativeZDirection','Row',matlab.system.display.internal.Row.current);
            IsActiveConfigurableDetections2Interrupt = matlab.system.display.internal.Property('IsActiveConfigurableDetections2Interrupt', 'Description', 'Generate interrupt');
            ConfigurableDetections2Interrupt = matlab.system.display.internal.Property('ConfigurableDetections2Interrupt','Description','matlab_sensors:blockmask:lis3dhInterruptPin','Row',matlab.system.display.internal.Row.current);
            event2Section = matlab.system.display.Section('Title','Configurable detections 2','PropertyList', {ConfigurableDetections2Type,ConfigurableDetections2XHigh,ConfigurableDetections2YHigh,ConfigurableDetections2ZHigh,ConfigurableDetections2XLow,ConfigurableDetections2YLow,ConfigurableDetections2ZLow,ConfigurableDetections2Threshold,ConfigurableDetections2Duration,IsActiveConfigurableDetections2Interrupt,ConfigurableDetections2Interrupt,ConfigurableDetections2Prop});
            
            dataType =  matlab.system.display.internal.Property('DataType', 'Description', 'matlab_sensors:blockmask:lis3dhDataType');
            SampleTimeProp = matlab.system.display.internal.Property('SampleTime', 'Description', 'matlab_sensors:blockmask:lis3dhSampleTime');
            bottomSection = matlab.system.display.Section('PropertyList', {dataType,SampleTimeProp});

            clickGroup = matlab.system.display.SectionGroup('Title','Click detection','Sections',clickSection);
            MainGroup = matlab.system.display.SectionGroup('Title','Main','Sections', [i2cProperties,mainSelectOutputs,commonSettingSection,bottomSection]);
            AdvancedGroup = matlab.system.display.SectionGroup('Title','Configurable detections','Sections', [eventSection,event1Section,event2Section]);
            groups=[ MainGroup, clickGroup, AdvancedGroup ];
        end
    end
end