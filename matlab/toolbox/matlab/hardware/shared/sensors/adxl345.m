classdef (Sealed) adxl345 < matlabshared.sensors.accelerometer & matlabshared.sensors.sensorUnit & matlabshared.sensors.I2CSensorProperties
    %ADXL345 connects to any of these sensors connected to a hardware object - ADXL343, ADXL344, ADXL345 or ADXL346
    %
    %   sensorObj = adxl345(a) returns a System object that reads sensor
    %   data from the ADXL345 sensor connected to the I2C bus of an
    %   hardware board. 'a' is a hardware object.
    %
    %   sensorObj = adxl345(a, 'Name', Value, ...) returns a ADXL345 System object
    %   with each specified property name set to the specified value. You
    %   can specify additional name-value pair arguments in any order as
    %   (Name1,Value1,...,NameN, ValueN).
    %
    %   adxl345 Properties
    %   I2CAddress      : Specify the I2C Address of the ADXL345.
    %   Bus             : Specify the I2C Bus where sensor is connected.
    %   ReadMode        : Specify whether to return the latest available
    %                     sensor values or the values accumulated from the
    %                     beginning when the 'read' API is executed.
    %                     ReadMode can be either 'latest' or 'oldest'.
    %                     Default value is 'latest'.
    %   SampleRate      : Rate at which samples are read from hardware.
    %                     Default value is 100 (samples/s).
    %   SamplesPerRead  : Number of samples returned per execution of read
    %                     function. Default value is 10.
    %   OutputFormat    : Format of output of read function. OutputFormat
    %                     can be either 'timetable' or 'matrix'. Default
    %                     value is 'timetable'.
    %   TimeFormat      : Format of time stamps returned by read function.
    %                     TimeFormat can be either 'datetime' or 'duration'
    %                     Default value is 'datetime'.
    %   SamplesAvailable: Number of samples remaining in the buffer waiting
    %                     to be read.
    %   SamplesRead     : Number of samples read from the sensor.
    %
    %   adxl345 methods
    %
    %   readAcceleration      : Read one sample of acceleration data from
    %                           sensor.
    %   read                  : Returns one frame of acceleration values 
    %                           along the three axis read from the sensor 
    %                           at the specified rate along with timestamps 
    %                           and overruns.
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
    %   Note: For Arduino, real-time data rate acquisition from ADXL345 
    %   sensor can be achieved by using the 'Samplerate' property and read 
    %   function. For hardware boards other than Arduino, adxl345 object is 
    %   supported with limited functionality. For those hardware boards, you 
    %   can use the readAcceleration function, and the 'Bus' and 'I2CAddress' 
    %   properties to acquire data from the ADXL345 sensor.
    %   
    %   Example 1: Read one sample of Acceleration value from ADXL345 sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % Create arduino object with I2C library included
    %   sensorObj = adxl345(a);
    %   accelData  =  sensorObj.readAcceleration;
    %
    %   Example 2: Read and plot acceleration values from an ADXL345 sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % create arduino object with I2C library included
    %   sensorObj = adxl345(a,'SampleRate',120,'SamplesPerRead',15);
    %   sensorObj.OutputFormat = 'matrix';
    %   figure;
    %   xlabel('Samples read');
    %   ylabel('Acceleration (m/s^2)');
    %   title('Acceleration values from ADXL345 sensor');
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

    %   See also icm20948, lsm9ds1, bno055, read, readAcceleration

    %   Copyright 2021-2022 The MathWorks, Inc.

    %#codegen

    properties(SetAccess = protected, GetAccess = public, Hidden)
        MinSampleRate = 0.1;
        MaxSampleRate = 200;
    end

    properties(Nontunable, Hidden)
        DoF = 3;
    end

    properties(Access = protected, Constant)
        AccelerometerDataRegister = 0x32;
        DeviceID = [0xE5,0xE6];
        CMD_REG = 0X7E;
        WHO_AM_I = 0x00;
        AccelerometerODRRegister = 0x2C;
        PowerCtlRegister = 0x2D;
        AccelerometerRangeRegister = 0x31;
        InterruptEnableRegister = 0x2E;
        InterruptMapRegister = 0x2F;
        InterruptSourceRegister = 0x30;
        ODRParametersAccel = [0.10,0.20,0.39,0.78,1.56,3.13,6.25,12.5,25,50,100,200,400,800,1600];
    end

    properties(Access = protected, Constant)
        SupportedInterfaces = 'I2C';
    end

    properties(Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Constant)
        I2CAddressList = [0x1D,0x53];
    end

    properties(Access = protected,Nontunable)
        AccelerometerRange = '+/- 4g';
        AccelerometerResolution = 1/256;
        AccelerometerODR;
        IsActiveInterrupt = false;
        InterruptPin = 'INT1';
        DataType = 'double';
    end

    properties(Hidden, Constant)
        BytesToRead = 6;
    end

    methods
        function obj = adxl345(varargin)
            obj@matlabshared.sensors.sensorUnit(varargin{:})
            if ~obj.isSimulink
                % Code generation does not support try-catch block. So init
                % function call is made separately in both codegen and IO
                % context.
                if ~coder.target('MATLAB')
                    obj.init(varargin{:});
                else
                    try
                        obj.init(varargin{:});
                    catch ME
                        throwAsCaller(ME);
                    end
                end
                obj.AccelerometerRange = '+/- 4g';
                enableFullResolutionMode(obj);
                obj.IsActiveInterrupt = false;
                obj.InterruptPin = 'INT1';
                obj.DataType = 'double';
            else
                names =     {'Bus','I2CAddress',...
                    'AccelerometerRange','AccelerometerODR','IsActiveInterrupt','InterruptPin','DataType'};
                defaults =    {0,obj.I2CAddressList(2),...
                    '+/- 4g', 25,false,'INT1','double'};
                p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults ,false);
                p.parse(varargin{2:end});
                i2cAddress = p.parameterValue('I2CAddress');
                bus =  p.parameterValue('Bus');
                obj.init(varargin{1},'I2CAddress',i2cAddress,'Bus',bus);
                obj.AccelerometerRange = p.parameterValue('AccelerometerRange');
                obj.AccelerometerODR = p.parameterValue('AccelerometerODR');
                enableFullResolutionMode(obj);
                obj.IsActiveInterrupt = p.parameterValue('IsActiveInterrupt');
                obj.InterruptPin = p.parameterValue('InterruptPin');
                obj.DataType = p.parameterValue('DataType');
            end
            %Measurement mode has to be enabled after all the settings
            %hence adding it here
            enableMeasurementMode(obj);
        end

        function set.AccelerometerODR(obj, value)
            switch value
                case '0.10 Hz'
                    ByteMask = 0x00;
                case '0.20 Hz'
                    ByteMask = 0x01;
                case '0.39 Hz'
                    ByteMask = 0x02;
                case '0.78 Hz'
                    ByteMask = 0x03;
                case '1.56 Hz'
                    ByteMask = 0x04;
                case '3.13 Hz'
                    ByteMask = 0x05;
                case '6.25 Hz'
                    ByteMask = 0x06;
                case '12.5 Hz'
                    ByteMask = 0x07;
                case '25 Hz'
                    ByteMask = 0x08;
                case '50 Hz'
                    ByteMask = 0x09;
                case '100 Hz'
                    ByteMask = 0x0A;
                case '200 Hz'
                    ByteMask = 0x0B;
                case '400 Hz'
                    ByteMask = 0x0C;
                case '800 Hz'
                    ByteMask = 0x0D;
                case '1600 Hz'
                    ByteMask = 0x0E;
                otherwise
                    ByteMask = 0x0A;
            end
            ByteMaskOr = 0xF0;
            val_CTRL1_XL = readRegister(obj.Device, obj.AccelerometerODRRegister);
            writeRegister(obj.Device,obj.AccelerometerODRRegister, bitor(bitand(val_CTRL1_XL, uint8(ByteMaskOr)), uint8(ByteMask)));
            obj.AccelerometerODR = value;
        end

        function set.AccelerometerRange(obj, value)
            setAccelRange(obj,value);
            obj.AccelerometerRange=value;
        end

        function set.IsActiveInterrupt(obj, value)
            obj.IsActiveInterrupt = value;
        end

        function set.InterruptPin(obj, value)
            enableInterrupts(obj,value);
            obj.InterruptPin = value;
        end
    end

    methods(Access = protected)
        function initDeviceImpl(obj)
            writeRegister(obj.Device, obj.PowerCtlRegister, uint8(0)); % Setting mode to Stand By after power on
            deviceid_value = readRegister(obj.Device, obj.WHO_AM_I);
            if(~any(ismember(deviceid_value,obj.DeviceID)))
                if coder.target('MATLAB')
                    matlabshared.sensors.internal.localizedWarning('matlab_sensors:general:invalidDeviceID','ADXL34x',num2str(obj.DeviceID));
                end
            end
        end

        function enableInterrupts(obj,value)
            if obj.IsActiveInterrupt
                interruptPinMapping(obj,value);
                activateInterrupts(obj);
                interruptEnable(obj);
            end
        end

        function initAccelerometerImpl(obj)
        end

        function initSensorImpl(obj)
            initAccelerometerImpl(obj);
        end

        function [data,status,timestamp]  = readAccelerationImpl(obj)
            if obj.IsActiveInterrupt
                interruptDisable(obj);
                [tempData,status,timestamp] = obj.Device.readRegisterData(obj.AccelerometerDataRegister, obj.BytesToRead, "uint8");
                if(isequal(size(tempData,2),1))
                    data = tempData';
                    if(isequal(numel(data),obj.SamplesPerRead*obj.BytesToRead))
                        data = reshape(data,[obj.BytesToRead,obj.SamplesPerRead])';
                    end
                else
                    data = tempData;
                end
                data = convertAccelData(obj, data);
                interruptSource(obj);
                interruptEnable(obj);
            else
                [tempData,status,timestamp] = obj.Device.readRegisterData(obj.AccelerometerDataRegister, obj.BytesToRead, "uint8");
                if(isequal(size(tempData,2),1))
                    data = tempData';
                    if(isequal(numel(data),obj.SamplesPerRead*obj.BytesToRead))
                        data = reshape(data,[obj.BytesToRead,obj.SamplesPerRead])';
                    end
                else
                    data = tempData;
                end
                data = convertAccelData(obj, data);
            end
        end

        function [accelData,status,timestamp]  = readSensorDataImpl(obj)
            [accelData,status,timestamp]  = readAccelerationImpl(obj);
        end

        function data = convertSensorDataImpl(obj, data)
            data=convertAccelData(obj, data(1:obj.BytesToRead));
        end

        function setODRImpl(obj)
            % used only for MATLAB
            accelODR = obj.ODRParametersAccel(obj.ODRParametersAccel<=obj.SampleRate);
            obj.AccelerometerODR = accelODR(end);
        end

        function s = infoImpl(obj)
            s = struct('AccelerometerODR',obj.AccelerometerODR);
        end

        function names = getMeasurementDataNames(obj)
            names = [obj.AccelerometerDataName];
        end
    end

    methods(Access = private)
        function data = convertAccelData(obj,accelSensorData)
            %little endian
            if strcmp(obj.DataType,'double')
                xa = double(bitor(int16(accelSensorData(:, 1)), bitshift(int16(accelSensorData(:, 2)),8))) ;
                ya = double(bitor(int16(accelSensorData(:, 3)), bitshift(int16(accelSensorData(:, 4)),8))) ;
                za = double(bitor(int16(accelSensorData(:, 5)), bitshift(int16(accelSensorData(:, 6)),8))) ;
                data = obj.AccelerometerResolution.*[xa, ya, za];
                data = data*9.81;
            else
                xa = single(bitor(int16(accelSensorData(:, 1)), bitshift(int16(accelSensorData(:, 2)),8))) ;
                ya = single(bitor(int16(accelSensorData(:, 3)), bitshift(int16(accelSensorData(:, 4)),8))) ;
                za = single(bitor(int16(accelSensorData(:, 5)), bitshift(int16(accelSensorData(:, 6)),8))) ;
                data = single(obj.AccelerometerResolution.*[xa, ya, za]);
                data = single(data*9.81);
            end
        end

        function enableMeasurementMode(obj)
            %This method enables sensor to transition from standby to measurement
            %mode
            ByteMask = 0x08;
            ByteMaskOr = 0xF7;
            val = readRegister(obj.Device,obj.PowerCtlRegister);
            writeRegister(obj.Device,obj.PowerCtlRegister,bitor(bitand(val, uint8(ByteMaskOr)),uint8(ByteMask)));
        end

        function enableFullResolutionMode(obj)
            %This method enables 13 bit resolution or full resolution mode
            ByteMask = 0x08;
            ByteMaskOr = 0xF7;
            val = readRegister(obj.Device,obj.AccelerometerRangeRegister);
            writeRegister(obj.Device,obj.AccelerometerRangeRegister,bitor(bitand(val, uint8(ByteMaskOr)),uint8(ByteMask)));
        end

        function activateInterrupts(obj)
            %This method  sets the Interrupts to active high state
            ByteMask = 0x00;
            ByteMaskOr = 0xCF;
            val = readRegister(obj.Device,obj.AccelerometerRangeRegister);
            writeRegister(obj.Device,obj.AccelerometerRangeRegister,bitor(bitand(val, uint8(ByteMaskOr)),uint8(ByteMask)));
        end

        function interruptEnable(obj)
            %This method enables Data ready interrupt
            ByteMask = 0x80;
            ByteMaskOr = 0x7F;
            val = readRegister(obj.Device,obj.InterruptEnableRegister);
            writeRegister(obj.Device,obj.InterruptEnableRegister,bitor(bitand(val, uint8(ByteMaskOr)),uint8(ByteMask)));
        end

        function interruptDisable(obj)
            %This method disables the interrupts
            ByteMask = 0x00;
            ByteMaskOr = 0x7F;
            val = readRegister(obj.Device,obj.InterruptEnableRegister);
            writeRegister(obj.Device,obj.InterruptEnableRegister,bitor(bitand(val, uint8(ByteMaskOr)),uint8(ByteMask)));
        end

        function interruptPinMapping(obj,value)
            %This method maps External Interrupt to PIN1 or PIN2 based
            if strcmp(value,'INT1')
                ByteMask = 0x00;
            else
                ByteMask = 0x80;
            end
            ByteMaskOr = 0x7F;
            val = readRegister(obj.Device,obj.InterruptMapRegister);
            writeRegister(obj.Device,obj.InterruptMapRegister,bitor(bitand(val, uint8(ByteMaskOr)),uint8(ByteMask)));
        end

        function interruptSource(obj)
            val = readRegister(obj.Device,obj.InterruptSourceRegister);
        end

        function setAccelRange(obj,Range)
            switch Range
                case '+/- 2g'
                    ByteMask = 0x00;
                case '+/- 4g'
                    ByteMask = 0x01;
                case '+/- 8g'
                    ByteMask = 0x02;
                case '+/- 16g'
                    ByteMask = 0x03;
            end
            ByteMaskOr = 0xFC;
            val = readRegister(obj.Device,obj.AccelerometerRangeRegister);
            writeRegister(obj.Device,obj.AccelerometerRangeRegister,bitor(bitand(val, uint8(ByteMaskOr)),uint8(ByteMask)));
        end
    end
end