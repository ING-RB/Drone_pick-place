classdef (Sealed) adis16505 < matlabshared.sensors.accelerometer & matlabshared.sensors.gyroscope &...
        matlabshared.sensors.TemperatureSensor & matlabshared.sensors.sensorUnit & matlabshared.sensors.SPISensorProperties
    %ADIS16505 connects to the ADIS16505 sensor connected to a hardware object
    %
    %   sensorObj = adis16505(hwObj,'SPIChipSelectPin',SPIChipSelectPin ) returns a System object that reads sensor
    %   data from the ADIS16505 sensor connected to the SPI bus of an hardware board. 'hwObj' is a hardware object.
    %
    %   SPIChipSelectPin is a mandatory name value pair argument for connecting to a SPI device.
    %   SPIChipSelectPin represents pin number that is used as the chip select pin on the hardware to communicate with the SPI device.
    %
    %   sensorObj = adis16505(a,'SPIChipSelectPin','D10','Name', Value, ...) returns a ADIS16505 System object
    %   with each specified property name set to the specified value. You
    %   can specify additional name-value pair arguments in any order as
    %   (Name1,Value1,...,NameN, ValueN).
    %
    %   adis16505 Properties
    %   SPIChipSelectPin      : Specify the chip select pin number on the hardware board
    %   Interface             : Specify the hardware interface through which the sensor is connected to the target
    %   NumTapsBartlettFilter : Specify the number of taps in each stage of the Bartlett window filter
    %   ReadMode              : Specify whether to return the latest or the oldest data samples during execution of read function.
    %                           ReadMode can be either 'latest' or 'oldest'.
    %                           Default value is 'latest'.
    %   SampleRate            : Rate at which samples are read from hardware.
    %                           Default value is 100 (samples/s).
    %   SamplesPerRead        : Number of samples returned per execution of read
    %                           function. Default value is 10.
    %   OutputFormat          : Format of output of read function. OutputFormat
    %                           can be either 'timetable' or 'matrix'. Default
    %                           value is 'timetable'.
    %   TimeFormat            : Format of time stamps returned by read function.
    %                           TimeFormat can be either 'datetime' or 'duration'
    %                           Default value is 'datetime'.
    %   SamplesAvailable      : Number of samples remaining in the buffer waiting
    %                           to be read.
    %   SamplesRead           : Number of samples read from the sensor.
    %
    %   adis16505 methods
    %
    %   readAcceleration      : Returns one sample of acceleration data on
    %                           x, y, and z axes read from the sensor along
    %                           with the timestamp.
    %   readAngularVelocity   : Returns one sample of angular velocity data on
    %                           x, y, and z axes read from the sensor along
    %                           with the timestamp.
    %   readTemperature       : Returns one sample of temperature data read
    %                           read from the sensor along  with the
    %                           timestamp.
    %   read                  : Read one frame of acceleration, angular velocity and temperature values from
    %                           the sensor along with time stamps and
    %                           overruns.
    %                           The number of samples depends on the
    %                           'SamplesPerRead' value specified while
    %                           creating the sensor object.
    %   stop/release          : Stop sending data from hardware and
    %                           allow changes to non-tunable properties
    %                           values and input characteristics.
    %   flush                 : Flushes all the data accumulated in the
    %                           buffers and resets the system object.
    %   info                  : Read sensor information such as odr,
    %                           bandwidth and so on.
    %
    %   Note : read(), flush(), release() and the properties SampleRate, ReadMode, SamplesPerRead,
    %          SamplesAvailable, SamplesRead, OutputFormat, and TimeFormat are required for real time data acquisition.
    %          Real-time data acquisition in only supported for Arduino.
    %
    %   Example 1: Read one sample of Acceleration value from ADIS16505 sensor
    %
    %   a = arduino('COM3','Uno','Libraries','SPI'); % Create arduino object with SPI library included
    %   sensorObj = adis16505(a,'SPIChipSelectPin','D10');
    %   accelData  =  sensorObj.readAcceleration;
    %
    %   Example 2: Read and plot acceleration values from an ADIS16505 sensor
    %
    %   a = arduino('COM3','Uno','Libraries','SPI'); % create arduino object with SPI library included
    %   sensorObj = adis16505(a,'SPIChipSelectPin','D10','SampleRate',120,'SamplesPerRead',15);
    %   sensorObj.OutputFormat = 'matrix';
    %   figure;
    %   xlabel('Samples read');
    %   ylabel('Acceleration (m/s^2)');
    %   title('Acceleration values from ADIS16505 sensor');
    %   x_val = animatedline('Color','r');
    %   y_val = animatedline('Color','g');
    %   z_val = animatedline('Color','b');
    %   axis tight;
    %   legend('Acceleration in X-axis','Acceleration in Y-axis',...
    %      'Acceleration in Z-axis');
    %   stop_time = 10; %  time in seconds
    %   count = 1;
    %   tic;
    %   while(toc <= stop_time)
    %     accel = read(sensorObj);
    %     addpoints(x_val,count:(count+sensorObj.SamplesPerRead-1),accel(:,1));
    %     addpoints(y_val,count:(count+sensorObj.SamplesPerRead-1),accel(:,2));
    %     addpoints(z_val,count:(count+sensorObj.SamplesPerRead-1),accel(:,3));
    %     count = count + sensorObj.SamplesPerRead;
    %     drawnow limitrate;
    %   end
    %   release(sensorObj);
    %   clear
    %
    %   See also icm20948, lsm9ds1, bno055, read, readAcceleration,
    %   readAngularVelocity, readTemperature

    %   Copyright 2023-2024 The MathWorks, Inc.

    %#codegen

    properties(SetAccess = protected, GetAccess = public, Hidden)
        MinSampleRate = 0.1;
        MaxSampleRate = 200;
    end

    properties(Nontunable, Hidden)
        DoF = [3;3;1];
    end

    properties(Access = protected, Constant)
        AccelerometerDataRegister = 0x10;
        TemperatureDataRegister = 0x1c;
        GyroscopeDataRegister = 0x04;
        ProductID = [64 121];
        ProductIdentificationRegister = 0x72;
        MiscellaneousControlLowRegister = 0x60;
        MiscellaneousControlHighRegister = 0x61;
        DecimationRateLowregister = 0x64;
        DecimationRateHighregister = 0x65;
        GlobalCommandLowRegister = 0x68;
        GlobalCommandHighRegister = 0x69;
        TemperatureLowRegister = 0x1C;
        TemperatureHighRegister = 0x1D;
        FilterControlLowRegister = 0x5C;
        FilterControlHighRegister = 0x5D;
        AccelerometerXLowRegister = 0x10;
        AccelerometerXOutRegister = 0x12;
        AccelerometerYLowRegister = 0x14;
        AccelerometerYOutRegister = 0x16;
        AccelerometerZLowRegister = 0x18;
        AccelerometerZOutRegister = 0x1A;
        GyroscopeXLowRegister = 0x04;
        GyroscopeXOutRegister = 0x06;
        GyroscopeYLowRegister = 0x08;
        GyroscopeYOutRegister = 0x0A;
        GyroscopeZLowRegister = 0x0C;
        GyroscopeZOutRegister = 0x0E;
        DataUpdateCounter = 0x22;
        ReadData=0x00;
        WriteData=0x80;
        InternalClockFreq = 2000; % Expressed in Hz
        SupportedODR =  2000./(1:2000);
        BytesToRead = 2;
    end

    properties(Access = protected, Constant)
        SupportedInterfaces = 'SPI';
    end

    properties(GetAccess = public,SetAccess = private)
        NumTapsBartlettFilter;
    end

    properties(Access = protected,Nontunable)
        % Sensitivity of 32bit accelereometer data
        AccelerometerSensitivity = 26756268; % units LSB/(m/sec^2)
        OutputDataRate;
        DataType = 'double';
        IsActiveTemperature = false;
        % Sensitivity of 32bit gyroscope data
        GyroscopeSensitivity = 2621440; % units LSB/degree/sec
        TemperatureSensitivity = 0.1; % LSB/degree/sec
        DataReadyPolarity = 0;
        InterruptType;
        SupportedBartlettTaps = {1,2,4,8,16,32,64};
        ChipSelectToggleFrequency = 2;
        DegreesPerSecToRadiansPerSec = 0.017453;
    end

    properties(Access = private)
        ReadStatusValue =0;
    end

    properties(Constant)
        InterruptPin = 'INT1';
    end

    methods
        function obj = adis16505(varargin)
            obj@matlabshared.sensors.sensorUnit(varargin{:})

            obj.BitOrder = 'msbfirst';
            obj.SPIMode = 3;
            if ~obj.isSimulink
                % Code generation does not support try-catch block. So init
                % function call is made separately in both codegen and IO
                % context.
                if ~coder.target('MATLAB')
                    [taps,argumentsForInit] = matlabshared.sensors.coder.matlab.adis16505.getParsedArguments(varargin{2:end});
                    obj.init(varargin{1},argumentsForInit{:});
                    obj.NumTapsBartlettFilter = taps;
                else
                    try
                        [taps,argumentsForInit] = getParsedArguments(obj,varargin{:});
                        obj.init(argumentsForInit{:});
                        obj.SCLPin = obj.Device.Device.SCLPin;
                        obj.SDIPin = obj.Device.Device.SDIPin;
                        obj.SDOPin = obj.Device.Device.SDOPin;
                        obj.Interface = obj.Device.Device.Interface;
                        obj.SPIChipSelectPin = obj.Device.Device.SPIChipSelectPin;
                        obj.NumTapsBartlettFilter = taps;
                    catch ME
                        throwAsCaller(ME);
                    end
                end
                obj.DataType = 'double';
                obj.DataReadyPolarity = 1;
            else
                names =     {'SPIChipSelectPin','DataType','InterruptType','NumTapsBartlettFilter','DesiredODR'};
                defaults =    {'D10','single','Active high',1,0};
                p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults ,false);
                p.parse(varargin{2:end});
                obj.init(varargin{1:3});
                obj.InterruptType = p.parameterValue('InterruptType');

                if matches(obj.InterruptType,"Active high")
                    obj.DataReadyPolarity = 1;
                elseif matches(obj.InterruptType,"Active low")
                    obj.DataReadyPolarity = 0;
                end

                obj.DataType = p.parameterValue('DataType');
                obj.NumTapsBartlettFilter = p.parameterValue('NumTapsBartlettFilter');
                obj.OutputDataRate = p.parameterValue('DesiredODR');
                obj.Interface = 'SPI';
            end
        end

        function set.OutputDataRate(obj,value)
            ODRinHz = min(obj.SupportedODR(obj.SupportedODR >= value));
            index = find(obj.SupportedODR==ODRinHz);
            obj.OutputDataRate = ODRinHz;
            valueToSet = index -1;
            [msb,lsb] = obj.extractuint16Bytes(valueToSet);
            writeRegister(obj.Device,bitor(obj.DecimationRateLowregister,obj.WriteData),lsb);
            writeRegister(obj.Device,bitor(obj.DecimationRateHighregister,obj.WriteData),msb);
        end

        function set.NumTapsBartlettFilter(obj,value)
            validateattributes(value,{'double'},{'nonempty','scalar'},'','NumTaps');
            if ~ismember(value,[1,2,4,8,16,32,64])
                error(message('matlab_sensors:general:InvalidTapValue'));
            end
            obj.NumTapsBartlettFilter = value;
            filterValue = log2(value);
            writeRegister(obj.Device,bitor(obj.FilterControlLowRegister,obj.WriteData),filterValue);
            writeRegister(obj.Device,bitor(obj.FilterControlHighRegister,obj.WriteData),0x00);
        end

        function set.DataReadyPolarity(obj, value)
            [val,~,~] = readRegisterData(obj.Device, obj.MiscellaneousControlLowRegister, 1,'uint16',obj.ChipSelectToggleFrequency);
            registerValue = typecast(uint16(val(2)),'uint8');

            writeRegister(obj.Device,bitor(obj.WriteData,obj.MiscellaneousControlLowRegister),value);
            writeRegister(obj.Device,bitor(obj.WriteData,obj.MiscellaneousControlHighRegister),registerValue(1));
            if ismethod(obj.Parent,'delayFunctionForHardware')
                delayFunctionForHardware(obj.Parent,0.0002);
            elseif coder.target('MATLAB')
                pause(0.0002);
            end
        end
    end

    methods(Access = protected)
        function initDeviceImpl(obj)
            softwareReset(obj);
            if ismethod(obj.Parent,'delayFunctionForHardware')
                delayFunctionForHardware(obj.Parent,0.255);
            elseif coder.target('MATLAB')
                pause(0.255);
            end

            % The last argument of the readRegisterData function specifies the chip select toggle frequency
            [deviceid_value,~,~] = readRegisterData(obj.Device, obj.ProductIdentificationRegister, 1,'uint16',obj.ChipSelectToggleFrequency);

            deviceid_value = typecast(uint16(deviceid_value),'uint8');
            if all(deviceid_value == 255)
                error(message('matlab_sensors:general:DeviceNotConnected'));
            end

            % Check for the Product ID : 0x4079 %
            if(~any(ismember(deviceid_value,obj.ProductID)))
                value = bitor(bitshift(uint16(obj.ProductID(1)), 8),uint16(obj.ProductID(2)));
                if coder.target('MATLAB')
                    matlabshared.sensors.internal.localizedWarning('matlab_sensors:general:invalidDeviceID','ADIS16505',num2str(value));
                end
            end
        end

        function initGyroscopeImpl(~)
        end

        function initAccelerometerImpl(~)
        end

        function initSensorImpl(~)
        end

        function softwareReset(obj)
            % Set bit 7 of GlobalCommandLowRegister
            writeRegister(obj.Device,bitor(obj.GlobalCommandLowRegister,obj.WriteData),0x80);
            writeRegister(obj.Device,bitor(obj.GlobalCommandHighRegister,obj.WriteData),0x00);

            writeRegister(obj.Device,bitor(obj.GlobalCommandLowRegister,obj.WriteData),0x2);
            writeRegister(obj.Device,bitor(obj.GlobalCommandHighRegister,obj.WriteData),0x00);
        end

        function [data,status,timestamp] = readAccelerationImpl(obj)
            % The last argument of the readRegisterData function specifies the chip select toggle frequency
            [accelData,status,timestamp] = readRegisterData(obj.Device, obj.AccelerometerXLowRegister, 6,'uint16',obj.ChipSelectToggleFrequency);
            data = convertAccelData(obj,accelData);
        end

        function [data,status,timestamp]  = readAngularVelocityImpl(obj)
            % The last argument of the readRegisterData function specifies the chip select toggle frequency
            [gyroData,status,timestamp] = readRegisterData(obj.Device, obj.GyroscopeXLowRegister, 6,'uint16',obj.ChipSelectToggleFrequency);
            data = convertGyroData(obj,gyroData);
        end

        function [data, status, timestamp] = readTemperatureImpl(obj)
            % The last argument of the readRegisterData function specifies the chip select toggle frequency
            [tempData,status,timestamp] = readRegisterData(obj.Device, obj.TemperatureLowRegister, 1,'uint16',obj.ChipSelectToggleFrequency);
            data = convertTemperatureData(obj,tempData);
        end

        function [data,status,timestamp]  = readSensorDataImpl(obj)
            [accelData,status,timestamp]  = readAccelerationImpl(obj);
            [gyroData,~,~] = readAngularVelocityImpl(obj);
            [tempData,~,~] = readTemperatureImpl(obj);
            data=[accelData,gyroData,tempData];
        end

        function data = convertAccelData(obj,value)
            accelSensorData = swapbytes(uint16(value(:,2:end)));
            sensorData = obj.convertSensorDataTo32BitData(accelSensorData);

            switch obj.DataType
                case 'double'
                    data = double((1/obj.AccelerometerSensitivity).*sensorData);
                case 'single'
                    data = single((1/obj.AccelerometerSensitivity).*sensorData);
                case 'int32'
                    data = int32((1/obj.AccelerometerSensitivity).*sensorData);
            end
        end

        function data = convertGyroData(obj,value)
            gyroSensorData = swapbytes(uint16(value(:,2:end)));
            sensorData = obj.convertSensorDataTo32BitData(gyroSensorData);

            switch obj.DataType
                case 'double'
                    data = double((obj.DegreesPerSecToRadiansPerSec * (1/obj.GyroscopeSensitivity)).*sensorData);
                case 'single'
                    data = single((obj.DegreesPerSecToRadiansPerSec * (1/obj.GyroscopeSensitivity)).*sensorData);
                case 'int32'
                    data = int32((obj.DegreesPerSecToRadiansPerSec * (1/obj.GyroscopeSensitivity)).*sensorData);
            end
        end

        function data = convertSensorDataTo32BitData(obj,sensorData)

            % combine the xlow and xhigh to a 32bit data
            xData = double(bitor(int32(bitshift(int32(sensorData(:,2)),16)),int32(sensorData(:,1))));

            % combine the ylow and yhigh to a 32bit data
            yData = double(bitor(int32(bitshift(int32(sensorData(:,4)),16)),int32(sensorData(:,3))));

            % combine the zlow and zhigh to a 32bit data
            zData = double(bitor(int32(bitshift(int32(sensorData(:,6)),16)),int32(sensorData(:,5))));

            data = [xData,yData,zData];
        end

        function data = convertTemperatureData(obj,value)
            tempData = swapbytes(uint16(value(:,2:end)));

            switch obj.DataType
                case 'double'
                    data = double(obj.TemperatureSensitivity * tempData);
                case 'single'
                    data = single(obj.TemperatureSensitivity * tempData);
                case 'int32'
                    data = int32(obj.TemperatureSensitivity * tempData);
            end
        end

        function data = convertSensorDataImpl(obj, sensorData)
            datatypeConv = typecast(uint8(sensorData(1:14)),'uint16');
            AccelData = convertAccelData(obj,datatypeConv);
            datatypeConv = typecast(uint8(sensorData(16:29)),'uint16');
            GyroData = convertGyroData(obj,datatypeConv);
            datatypeConv = typecast(uint8(sensorData(31:34)),'uint16');
            TempData = convertTemperatureData(obj,datatypeConv);
            data = [AccelData GyroData TempData];
        end

        function setODRImpl(obj)
            obj.OutputDataRate = obj.SampleRate;
        end

        function s = infoImpl(obj)
            s = struct('OutputDataRate', obj.OutputDataRate);
        end

        function names = getMeasurementDataNames(obj)
            names = [obj.AccelerometerDataName, obj.GyroscopeDataName,obj.TemperatureDataName];
        end
    end

    methods(Hidden)
        function [ret,timestamp] = readStatus(obj)
            % The last argument of the readRegisterData function specifies the chip select toggle frequency
            [data,~,~] = readRegisterData(obj.Device, obj.DataUpdateCounter, 1,'uint16',obj.ChipSelectToggleFrequency);
            tempData = swapbytes((data(:,2:end)));
            if(isequal((tempData-obj.ReadStatusValue),0))
                ret = uint8(1);
            else
                ret = uint8(0);
            end
            obj.ReadStatusValue = double(tempData);
            timestamp = 0;
        end
    end

    methods(Access = private)
        function [msb,lsb] = extractuint16Bytes(~,value)
            value = uint16(value);
            lsb = uint8(bitand(value, 0x00ff));
            msb = uint8(bitshift((bitand(value, 0xff00)),-8));
        end

        function [taps,argumentsForInit] = getParsedArguments(obj,varargin)
            p = inputParser;
            p.CaseSensitive = 0;
            p.PartialMatching = 1;
            p.KeepUnmatched = true;
            addParameter(p, 'NumTapsBartlettFilter', 1);
            parse(p, varargin{2:end});
            taps = p.Results.NumTapsBartlettFilter;
            fields = fieldnames(p.Unmatched);
            fieldValues = struct2cell(p.Unmatched);
            num = numel(fields)+numel(fieldValues);
            argumentsForInit{1} = varargin{1};
            if(numel(varargin)>2)
                k = 2;
                for i = 1:1:num/2
                    argumentsForInit{k} =  fields{i};
                    k = k+1;
                    argumentsForInit{k} =  fieldValues{i};
                    k = k+1;
                end
            elseif numel(varargin)>1
                argumentsForInit{2} = varargin{2};
            end
        end
    end

    methods(Hidden)
        function showSensorProperties(obj)
            fprintf(' NumTapsBartlettFilter: %d \n\n', obj.NumTapsBartlettFilter);
        end
    end
end
