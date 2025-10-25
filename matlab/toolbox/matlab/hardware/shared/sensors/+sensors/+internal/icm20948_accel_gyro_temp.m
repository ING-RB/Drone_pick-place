classdef (Sealed) icm20948_accel_gyro_temp < matlabshared.sensors.accelerometer & ...
        matlabshared.sensors.gyroscope & matlabshared.sensors.TemperatureSensor & ...
        matlabshared.sensors.sensorUnit & matlabshared.sensors.I2CSensorProperties
    %ICM20948_ACCEL_GYRO_TEMP connects to the ICM-20948 sensor connected to the I2C bus of the hardware board.
    %
    %   IMU = icm20948_accel_gyro_temp(hardwareObj) returns a ICM-20948
    %   System object with default property values. The argument 'hardwareObj'
    %   represents the connection to the hardware board. The icm20948_accel_gyro_temp
    %   object can be used to read sensor data from the ICM-20948 sensor
    %   connected to the I2C bus of the hardware board.
    %
    %   IMU = icm20948_accel_gyro_temp(hardwareObj, 'Name', Value, ...)
    %   returns a ICM-20948 System object with each specified property name
    %   set to the specified value. You can specify additional name-value
    %   pair arguments in any order as (Name1, Value1, ...,NameN, ValueN).
    %
    %   icm20948_accel_gyro_temp Properties:
    %
    %   I2CAddress      : Specify the I2C Address of the ICM-20948 sensor.
    %   Bus             : Specify the I2C Bus where sensor is connected.
    %   ReadMode        : Specify whether to return the latest available
    %                     sensor values or the values accumulated from the
    %                     beginning when the 'read' API is executed.
    %                     ReadMode can be either 'latest' or 'oldest'.
    %                     Default value is 'latest'.
    %   SampleRate      : Rate at which samples are read from hardware.
    %                     Default value is 100 (samples/s).
    %   SamplesPerRead  : Number of samples returned per execution of read
    %                     function. Default value is 10
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
    %   icm20948_accel_gyro_temp methods:
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
    %   read                  : Returns one frame of acceleration, angular
    %                           velocity, and temperature values read from
    %                           the sensor at the specified rate along
    %                           with timestamps and overruns.
    %                           The number of samples depends on the
    %                           'SamplesPerRead' value specified while
    %                           creating the sensor object.
    %  stop/release           : Stops sending data from the hardware and
    %                           allow changes to non-tunable properties
    %                           values.
    %  flush                  : Flushes all the data accumulated in the
    %                           buffers and resets the system object.
    %  info                   : Read sensor information such as output
    %                           data rate, bandwidth and so on.
    %
    %  Note: For Arduino, real-time data rate acquisition from ICM-20948
    %  sensor can be achieved by using the 'Samplerate' property and read
    %  function. For hardware boards other than Arduino,
    %  icm20948_accel_gyro_temp object is supported with limited functionality.
    %  For those hardware boards, you can use the readAcceleration,
    %  readAngularVelocity, and readTemperature functions, and the 'Bus'
    %  and 'I2CAddress' properties to acquire data from the ICM-20948 sensor.
    %
    %  Example 1: Read one sample of acceleration value from ICM-20948 sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % Create arduino object with I2C library included
    %   sensorObj = icm20948_accel_gyro_temp(a);
    %   accelData  =  sensorObj.readAcceleration;
    %
    %  Example 2: Read and plot acceleration values from an ICM-20948 sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % create arduino object with I2C library included
    %   sensorObj = icm20948_accel_gyro_temp(a,'SampleRate',120,'SamplesPerRead',15);
    %   sensorObj.OutputFormat = 'matrix';
    %   figure;
    %   xlabel('Samples read');
    %   ylabel('Acceleration (m/s^2)');
    %   title('Acceleration values from ICM20948 sensor');
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
    %     [accel,gyro,temp] = read(sensorObj);
    %     addpoints(x_val,count:(count+sensorObj.SamplesPerRead-1),accel(:,1));
    %     addpoints(y_val,count:(count+sensorObj.SamplesPerRead-1),accel(:,2));
    %     addpoints(z_val,count:(count+sensorObj.SamplesPerRead-1),accel(:,3));
    %     count = count + sensorObj.SamplesPerRead;
    %     drawnow limitrate;
    %   end
    %   release(sensorObj);
    %   clear
    %
    %   See also mpu6050, lsm9ds1, bno055, read, readAcceleration,
    %   readTemperature, readAngularVelocity

    %   Copyright 2021-2023 The MathWorks, Inc.

    %#codegen

    properties(SetAccess = protected, GetAccess = public, Hidden)
        MinSampleRate = 16;
        MaxSampleRate = 200;
    end

    properties(Nontunable, Hidden)
        DoF = [3;3;1]
    end

    properties(Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Constant)
        I2CAddressList = [0x69,0x68];
    end

    properties(Hidden,Nontunable)
        EnableAccelDLPF = true;
        AccelerometerODR;
        AccelerometerBW;
        AccelerometerRange = 4;
        EnableGyroDLPF = true;
        GyroscopeODR;
        GyroscopeBW;
        GyroscopeRange = 250;
        TemperatureBW
        IsActiveAccel = true;
        IsActiveSecondaryMag = true;
        IsActiveGyro = true;
        IsActiveTemp = true;
        EnableDRDY = false;
        IsActiveLow = false;
    end

    properties(Access = protected,Nontunable)
        AccelResolution;
        GyroResolution;
        TempResolution = 1/333.87;
        TempOffset = 21;
        IsOutDoubleType = true;
    end

     properties(Access = protected, Constant)
        SupportedInterfaces = 'I2C';
    end

    properties(Access = protected, Constant)
        DeviceName = 'ICM20948';
        REG_BANK_SEL = 0x7F;
        % Bank 0 registers and settings
        WHO_AM_I = 0x00;
        DeviceID = 0xEA;
        LP_CONFIG = 0x05;
        PWR_MGMT_1 = 0x06;
        PWR_MGMT_2 = 0x07;
        AccelerometerDataRegister = 0x2D;
        GyroscopeDataRegister = 0x33;
        TemperatureDataRegister = 0x39;
        % Interrupt registers in bank 0
        INT_PIN_CFG = 0x0F; % To enable auxilary compass and to configure registers
        INT_ENABLE_1 = 0x11 ; % To enable data ready interuppt
        INT_STATUS_1 = 0x1A; % Ready to be read.

        % Bank 2 registers and settings
        GYRO_SMPLRT_DIV = 0x00;
        GYRO_CONFIG_1 = 0x01;
        GyroODRParameters = struct('SupportedODR', 1125./(1:256), 'SampleRateDivider', 0:255);
        GyroBWParameters = struct('Bandwidth', [196.6, 151.8, 119.5, 51.2, 23.9, 11.6, 5.7,361.4], ...
            'DLPF', 0:7);  % Ignoring the 9 kHz sampling rate and the entries without LPF
        ODR_ALIGN_EN = 0x09;
        ACCEL_SMPLRT_DIV_1 = 0x10;
        ACCEL_SMPLRT_DIV_2 = 0x11;
        ACCEL_CONFIG = 0x14;
        AccelODRParameters = struct('SupportedODR', 1125./(1:4096), 'SampleRateDivider', 0:4095);
        AccelBWParameters = struct('Bandwidth', [246.0, 111.4, 50.4, 23.9, 11.5, 5.7, 473], ...
            'DLPF', 1:7);  % Ignoring the 9 kHz sampling rate and the entries without LPF
        TEMP_CONFIG = 0x53;
        TempBWParameters = struct('Bandwidth', [7932.0, 217.9, 123.5, 65.9, 34.1, 17.3, 8.8], ...
            'DLPF', 0:6);
        BytesToReadAccelGyro = 6;
    end

    properties(Access = protected)
        UserBank = -1;
    end

    methods
        function obj = icm20948_accel_gyro_temp(varargin)
            % Code generation does not support try-catch block. So init
            % function call is made separately in both codegen and IO
            % context.
            obj@matlabshared.sensors.sensorUnit(varargin{:});
            if ~obj.isSimulink
                % For MATLAB workflow, ensure only below name value pairs
                % are used.
                names = {'Bus','OutputFormat','TimeFormat','SamplesPerRead', 'SampleRate','ReadMode','I2CAddress'};
                defaults = {[],'timetable','datetime', 10, 100, 'latest',[]};
                p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults ,false);
                p.parse(varargin{2:end});
                obj.IsActiveSecondaryMag = true;
                if ~coder.target('MATLAB')
                    obj.init(varargin{:});
                else
                    try
                        obj.init(varargin{:});
                    catch ME
                        throwAsCaller(ME);
                    end
                end
                obj.AccelerometerRange = 2;
                obj.GyroscopeRange = 250;
                obj.IsActiveGyro = true;
                obj.IsActiveAccel = true;
                obj.IsActiveTemp = true;
                obj.IsOutDoubleType = true;
            else
                names = {'Bus','I2CAddress',...
                    'IsActiveAccel', 'IsActiveGyro', 'IsActiveTemp', 'IsActiveMag', ...
                    'AccelerometerRange', 'AccelerometerODR', 'AccelerometerBW',...
                    'GyroscopeRange', 'GyroscopeODR', 'GyroscopeBW','TemperatureBW',...
                    'EnableDRDY','IsActiveLow','IsOutDoubleType'};
                defaults = {0,[],true,true,true,true,2,100,23.9,250,100,23.9,34.1,false,false,true};
                p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults ,false);
                p.parse(varargin{2:end});
                % To enable secondary magnetometer
                obj.IsActiveSecondaryMag = p.parameterValue('IsActiveMag');
                obj.init(varargin{1},'Bus',p.parameterValue('Bus'),'I2CAddress',p.parameterValue('I2CAddress'));
                % Accel related properties
                obj.IsActiveAccel = p.parameterValue('IsActiveAccel');
                obj.AccelerometerRange = p.parameterValue('AccelerometerRange');
                obj.AccelerometerODR = p.parameterValue('AccelerometerODR');
                obj.AccelerometerBW = p.parameterValue('AccelerometerBW');
                % Gyro related properties
                obj.IsActiveGyro = p.parameterValue('IsActiveGyro');
                obj.GyroscopeRange = p.parameterValue('GyroscopeRange');
                obj.GyroscopeODR = p.parameterValue('GyroscopeODR');
                obj.GyroscopeBW = p.parameterValue('GyroscopeBW');
                % Temp related properties
                obj.IsActiveTemp = p.parameterValue('IsActiveTemp');
                obj.TemperatureBW = p.parameterValue('TemperatureBW');
                % Interrupt related properties
                obj.EnableDRDY = p.parameterValue('EnableDRDY');
                if obj.EnableDRDY == true
                    obj.IsActiveLow = p.parameterValue('IsActiveLow');
                    enableInterrupts(obj);
                end
                obj.IsOutDoubleType = p.parameterValue('IsOutDoubleType');
            end
            changeUserBank(obj,0);
        end

        %% Gyro settings
        function set.EnableGyroDLPF(obj,dlpfEnable)
            changeUserBank(obj,2);
            andMask = 0xFE;
            if dlpfEnable == true
                orValue = 0x01;
            else
                orValue = 0x00;
            end
            value = uint8(readRegister(obj.Device,obj.GYRO_CONFIG_1,1,'uint8'));
            value = uint8(bitor(bitand(value,andMask),orValue));
            writeRegister(obj.Device,obj.GYRO_CONFIG_1,value);
            obj.EnableGyroDLPF = dlpfEnable;
            if coder.target('rtw')
                % This function is only implemented for codegen workflows
                obj.Parent.delayFunctionForHardware(10);
            end
        end

        function set.GyroscopeODR(obj,value)
            changeUserBank(obj,2);
            ODR = min(obj.GyroODRParameters.SupportedODR(obj.GyroODRParameters.SupportedODR >= value));
            sampleRateDiv = uint8(obj.GyroODRParameters.SampleRateDivider(obj.GyroODRParameters.SupportedODR == ODR));
            writeRegister(obj.Device,obj.GYRO_SMPLRT_DIV,sampleRateDiv);
            obj.GyroscopeODR = ODR;
            if coder.target('rtw')
                % This function is only implemented for codegen workflows
                obj.Parent.delayFunctionForHardware(10);
            end
        end

        function set.GyroscopeBW(obj,bw)
            changeUserBank(obj,2);
            bw = min(obj.GyroBWParameters.Bandwidth(obj.GyroBWParameters.Bandwidth >= bw));
            dlpf = obj.GyroBWParameters.DLPF(obj.GyroBWParameters.Bandwidth == bw);
            andMask = 0xc7;
            switch dlpf
                case 0
                    orValue = 0x00;
                case 1
                    orValue = 0x08;
                case 2
                    orValue = 0x10;
                case 3
                    orValue = 0x18;
                case 4
                    orValue = 0x20;
                case 5
                    orValue = 0x28;
                case 6
                    orValue = 0x30;
                case 7
                    orValue = 0x38;
                otherwise
                    % Corresponds to 51.2Hz
                    orValue = 0x18;
            end
            value = uint8(readRegister(obj.Device,obj.GYRO_CONFIG_1,1,'uint8'));
            value = uint8(bitor(bitand(value,andMask),orValue));
            writeRegister(obj.Device,obj.GYRO_CONFIG_1,value);
            obj.GyroscopeBW = bw;
            if coder.target('rtw')
                % This function is only implemented for codegen workflows
                obj.Parent.delayFunctionForHardware(10);
            end
        end

        function set.GyroscopeRange(obj,range)
            changeUserBank(obj,2);
            andMask = 0xf9;
            switch range
                case 250
                    orValue = 0x00;
                    obj.GyroResolution = (1/131)*(pi/180);
                case 500
                    orValue = 0x02;
                    obj.GyroResolution = (1/65.5)*(pi/180);
                case 1000
                    orValue = 0x04;
                    obj.GyroResolution = (1/32.8)*(pi/180);
                case 2000
                    orValue = 0x06;
                    obj.GyroResolution = (1/16.4)*(pi/180);
                otherwise
                    % Corresponds to 250dps
                    orValue = 0x00;
                    obj.GyroResolution = (1/131)*(pi/180);
            end
            value = uint8(readRegister(obj.Device,obj.GYRO_CONFIG_1,1,'uint8'));
            value = uint8(bitor(bitand(value,andMask),orValue));
            writeRegister(obj.Device,obj.GYRO_CONFIG_1,value);
            obj.GyroscopeRange = range;
            if coder.target('rtw')
                % This function is only implemented for codegen workflows
                obj.Parent.delayFunctionForHardware(10);
            end
        end
        %% Accel Settings
        function set.EnableAccelDLPF(obj,dlpfEnable)
            changeUserBank(obj,2);
            andMask = 0xFE;
            if dlpfEnable == true
                orValue = 0x01;
            else
                orValue = 0x00;
            end
            value = uint8(readRegister(obj.Device,obj.ACCEL_CONFIG,1,'uint8'));
            value = uint8(bitor(bitand(value,andMask),orValue));
            writeRegister(obj.Device,obj.ACCEL_CONFIG,value);
            obj.EnableAccelDLPF = dlpfEnable;
            if coder.target('rtw')
                % This function is only implemented for codegen workflows
                obj.Parent.delayFunctionForHardware(10);
            end
        end

        function set.AccelerometerODR(obj,value)
            changeUserBank(obj,2);
            ODR = min(obj.AccelODRParameters.SupportedODR(obj.AccelODRParameters.SupportedODR >= value));
            sampleRateDiv = uint16(obj.AccelODRParameters.SampleRateDivider(obj.AccelODRParameters.SupportedODR == ODR));
            [upperByte, lowerByte] = extractuint16Bytes(obj,sampleRateDiv);
            % Some bits of ACCEL_SMPLRT_DIV_1 are reserved. Protect
            % these bits by using masks
            val = uint8(readRegister(obj.Device,obj.ACCEL_SMPLRT_DIV_1,1,'uint8'));
            andMask = 0xF8;
            val = uint8(bitor(bitand(val,andMask),upperByte));
            writeRegister(obj.Device,obj.ACCEL_SMPLRT_DIV_1,val);
            writeRegister(obj.Device,obj.ACCEL_SMPLRT_DIV_2,lowerByte);
            obj.AccelerometerODR = ODR;
            if coder.target('rtw')
                % This function is only implemented for codegen workflows
                obj.Parent.delayFunctionForHardware(10);
            end
        end

        function set.AccelerometerBW(obj,bw)
            changeUserBank(obj,2);
            bw = min(obj.AccelBWParameters.Bandwidth(obj.AccelBWParameters.Bandwidth >= bw));
            dlpf = obj.AccelBWParameters.DLPF(obj.AccelBWParameters.Bandwidth == bw);
            andMask = 0xc7;
            switch dlpf
                case 1
                    orValue = 0x08;
                case 2
                    orValue = 0x10;
                case 3
                    orValue = 0x18;
                case 4
                    orValue = 0x20;
                case 5
                    orValue = 0x28;
                case 6
                    orValue = 0x30;
                case 7
                    orValue = 0x38;
                otherwise
                    % Corresponds to 50.4Hz
                    orValue = 0x18;
            end
            value = uint8(readRegister(obj.Device,obj.ACCEL_CONFIG,1,'uint8'));
            value = uint8(bitor(bitand(value,andMask),orValue));
            writeRegister(obj.Device,obj.ACCEL_CONFIG,value);
            obj.AccelerometerBW = bw;
            if coder.target('rtw')
                % This function is only implemented for codegen workflows
                obj.Parent.delayFunctionForHardware(10);
            end
        end

        function set.AccelerometerRange(obj,range)
            changeUserBank(obj,2);
            andMask = 0xf9;
            switch range
                case 2
                    orValue = 0x00;
                    obj.AccelResolution = (1/16384)*9.8;
                case 4
                    orValue = 0x02;
                    obj.AccelResolution = (1/8192)*9.8;
                case 8
                    orValue = 0x04;
                    obj.AccelResolution = (1/4096)*9.8;
                case 16
                    orValue = 0x06;
                    obj.AccelResolution = (1/2048)*9.8;
                otherwise
                    % Corresponds to 2g
                    orValue = 0x00;
                    obj.AccelResolution = (1/16384)*9.8;
            end
            value = uint8(readRegister(obj.Device,obj.ACCEL_CONFIG,1,'uint8'));
            value = uint8(bitor(bitand(value,andMask),orValue));
            writeRegister(obj.Device,obj.ACCEL_CONFIG,value);
            obj.AccelerometerRange = range;
            if coder.target('rtw')
                % This function is only implemented for codegen workflows
                obj.Parent.delayFunctionForHardware(10);
            end
        end
        %% Temperature settings
        function set.TemperatureBW(obj,bw)
            changeUserBank(obj,2);
            obj.TemperatureBW = min(obj.TempBWParameters.Bandwidth(obj.TempBWParameters.Bandwidth >= bw));
            dlpf = obj.TempBWParameters.DLPF(obj.TempBWParameters.Bandwidth == obj.TemperatureBW);
            andMask = 0xF8;
            switch dlpf
                case 0
                    orValue = 0x00;
                case 1
                    orValue = 0x01;
                case 2
                    orValue = 0x02;
                case 3
                    orValue = 0x03;
                case 4
                    orValue = 0x04;
                case 5
                    orValue = 0x05;
                case 6
                    orValue = 0x06;
                otherwise
                    % Corresponds to 34.1Hz
                    orValue = 0x04;
            end
            value = uint8(readRegister(obj.Device,obj.TEMP_CONFIG,1,'uint8'));
            value = uint8(bitor(bitand(value,andMask),orValue));
            writeRegister(obj.Device,obj.TEMP_CONFIG,value);
            if coder.target('rtw')
                % This function is only implemented for codegen workflows
                obj.Parent.delayFunctionForHardware(10);
            end
        end
        %% Interrupt settings
        function enableInterrupts(obj)
            changeUserBank(obj,0);
            value = uint8(readRegister(obj.Device,obj.INT_PIN_CFG,1,'uint8'));
            andMask = 0x03;
            if obj.IsActiveLow
                orValue = 0x80;
            else
                orValue = 0x00;
            end
            value = uint8(bitor(bitand(value,andMask),orValue));
            writeRegister(obj.Device,obj.INT_PIN_CFG,value);
            writeRegister(obj.Device,obj.INT_ENABLE_1,0x01);
        end
    end

    methods(Access = protected)
        function initDeviceImpl(obj)
            obj.UserBank = -1;
            changeUserBank(obj,0)
            % Check if device ID in WHO_AM_Register is as expected
            deviceid_value = readRegister(obj.Device,obj.WHO_AM_I,1,'uint8');
            if(deviceid_value ~= obj.DeviceID)
                if coder.target('MATLAB')
                    matlabshared.sensors.internal.localizedWarning('matlab_sensors:general:invalidDeviceID',obj.DeviceName,num2str(obj.DeviceID));
                end
            end
            % Reset all registers
            writeRegister(obj.Device, obj.PWR_MGMT_1, 0x80);
            if coder.target('rtw')
                % This function is only implemented for codegen workflows
                obj.Parent.delayFunctionForHardware(10);
            end
            % wake the sensor from sleep mode
            % Set the bus clock for gyroscope performance
            writeRegister(obj.Device, obj.PWR_MGMT_1, 0x01);
            if coder.target('rtw')
                % This function is only implemented for codegen workflows
                obj.Parent.delayFunctionForHardware(10);
            end
            % Enable Accel-gyro axes
            writeRegister(obj.Device, obj.PWR_MGMT_2, 0x00);
            if coder.target('rtw')
                % This function is only implemented for codegen workflows
                obj.Parent.delayFunctionForHardware(10);
            end
            val = uint8(readRegister(obj.Device,obj.INT_PIN_CFG,1,'uint8'));
            orValue = 0x02;
            val = uint8(bitor(val,orValue));
            writeRegister(obj.Device,obj.INT_PIN_CFG,val);
            if coder.target('rtw')
                % This function is only implemented for codegen workflows
                obj.Parent.delayFunctionForHardware(10);
            end
            changeUserBank(obj,2);
            if coder.target('rtw')
                % This function is only implemented for codegen workflows
                obj.Parent.delayFunctionForHardware(10);
            end
            orValue = 0x01;
            value = uint8(readRegister(obj.Device,obj.ODR_ALIGN_EN,1,'uint8'));
            value = uint8(bitor(value,orValue));
            writeRegister(obj.Device,obj.ODR_ALIGN_EN,value);
            if coder.target('rtw')
                % This function is only implemented for codegen workflows
                obj.Parent.delayFunctionForHardware(10);
            end
        end

        function initAccelerometerImpl(obj)
            obj.EnableAccelDLPF = true;
        end

        function initGyroscopeImpl(obj)
            obj.EnableGyroDLPF = true;
        end

        function initSensorImpl(obj)
            initAccelerometerImpl(obj);
            initGyroscopeImpl(obj);
        end

        function [data,status,timestamp]  = readAccelerationImpl(obj)
            changeUserBank(obj,0);
            [tempData,status,timestamp] = obj.Device.readRegisterData(obj.AccelerometerDataRegister, obj.BytesToReadAccelGyro, "uint8");
            if(isequal(size(tempData,2),1))
                data = tempData';
                if(isequal(numel(data),obj.SamplesPerRead*obj.BytesToReadAccelGyro))
                    data = reshape(data,[obj.BytesToReadAccelGyro,obj.SamplesPerRead])';
                end
            else
                data = tempData;
            end
            data = convertAccelData(obj, data);
        end

        function [data,status,timestamp]  = readAngularVelocityImpl(obj)
            changeUserBank(obj,0);
            [tempData,status,timestamp] = obj.Device.readRegisterData(obj.GyroscopeDataRegister, obj.BytesToReadAccelGyro, "uint8");
            if(isequal(size(tempData,2),1))
                data = tempData';
                if(isequal(numel(data),obj.SamplesPerRead*obj.BytesToReadAccelGyro))
                    data = reshape(data,[obj.BytesToReadAccelGyro,obj.SamplesPerRead])';
                end
            else
                data = tempData;
            end
            data = convertGyroData(obj, data);
        end

        function [data,status,timestamp] = readTemperatureImpl(obj)
            changeUserBank(obj,0);
            [tempData,status,timestamp] = obj.Device.readRegisterData(obj.TemperatureDataRegister,2, "uint8");
            if(isequal(size(tempData,2),1))
                data = tempData';
                if(isequal(numel(data),obj.SamplesPerRead*2))
                    data = reshape(data,[2,obj.SamplesPerRead])';
                end
            else
                data = tempData;
            end
            data = convertTempData(obj,data);
        end

        function [data,status,timestamp]  = readSensorDataImpl(obj)
            % All the sensor values will have same timestamp
            [dataAccel,status,timestamp]  = readAccelerationImpl(obj);
            [dataGyro,~,~]  = readAngularVelocityImpl(obj);
            [dataTemp,~,~]  = readTemperatureImpl(obj);
            data = [dataAccel,dataGyro,dataTemp];
        end

        function data = convertSensorDataImpl(obj, data)
            data = [convertAccelData(obj, data(1:obj.BytesToReadAccelGyro)) convertGyroData(obj, data(obj.BytesToReadAccelGyro+1:2*obj.BytesToReadAccelGyro)) convertTempData(obj, data((2*obj.BytesToReadAccelGyro)+1:end))];
        end

        function setODRImpl(obj)
            % Set ODR based on sample rate
            maxBandwidth = obj.SampleRate/2;
            obj.GyroscopeBW = max(obj.GyroBWParameters.Bandwidth(obj.GyroBWParameters.Bandwidth <= maxBandwidth));
            obj.GyroscopeODR = min(obj.GyroODRParameters.SupportedODR(obj.GyroODRParameters.SupportedODR > 2*obj.GyroscopeBW));

            obj.AccelerometerBW = max(obj.AccelBWParameters.Bandwidth(obj.AccelBWParameters.Bandwidth <= maxBandwidth));
            obj.AccelerometerODR = min(obj.AccelODRParameters.SupportedODR(obj.AccelODRParameters.SupportedODR > 2*obj.AccelerometerBW));

            obj.TemperatureBW = max(obj.TempBWParameters.Bandwidth(obj.TempBWParameters.Bandwidth <= maxBandwidth));
        end

        function s = infoImpl(obj)
            if coder.target('MATLAB')
                s = struct('AccelerometerODR', obj.AccelerometerODR,'AccelerometerBandwidth',obj.AccelerometerBW, 'GyroscopeODR', obj.GyroscopeODR,'GyroscopeBandwidth',obj.GyroscopeBW,'TemperatureSensorBandwidth',obj.TemperatureBW);
            else
                coder.internal.errorIf(true, 'matlab_sensors:general:unsupportedFunctionSensorCodegen', 'info');
            end
        end

        function names = getMeasurementDataNames(obj)
            names = [obj.AccelerometerDataName, obj.GyroscopeDataName,obj.TemperatureDataName];
        end

    end

    methods(Access = private)

        function data = convertAccelData(obj,accelSensorData)
            xa = bitor(int16(accelSensorData(:, 2)), bitshift(int16(accelSensorData(:, 1)),8));
            ya = bitor(int16(accelSensorData(:, 4)), bitshift(int16(accelSensorData(:, 3)),8));
            za = bitor(int16(accelSensorData(:, 6)), bitshift(int16(accelSensorData(:, 5)),8));
            if obj.IsOutDoubleType
                data = double(obj.AccelResolution).*double([xa, ya, za]);
            else
                data = single(obj.AccelResolution).*single([xa, ya, za]);
            end
        end

        function data = convertGyroData(obj,gyroSensorData)
            xg = bitor(int16(gyroSensorData(:, 2)), bitshift(int16(gyroSensorData(:, 1)),8));
            yg = bitor(int16(gyroSensorData(:, 4)), bitshift(int16(gyroSensorData(:, 3)),8));
            zg = bitor(int16(gyroSensorData(:, 6)), bitshift(int16(gyroSensorData(:, 5)),8));
            if obj.IsOutDoubleType
                data = double(obj.GyroResolution).*double([xg, yg, zg]);
            else
                data = single(obj.GyroResolution).*single([xg, yg, zg]);
            end
        end

        function data = convertTempData(obj,data)
            data = bitor(int16(data(:, 2)), bitshift(int16(data(:, 1)),8));
            if obj.IsOutDoubleType
                tempOff = double(obj.TempOffset);
                data = (double(obj.TempResolution)*(double(data)-tempOff))+tempOff;
            else
                tempOff = single(obj.TempOffset);
                data = (single(obj.TempResolution)*(single(data)-tempOff))+tempOff;
            end
        end

        function [msb,lsb] = extractuint16Bytes(~,value)
            lsb = uint8(bitand(value, hex2dec('ff')));
            msb = uint8(bitshift((bitand(value, hex2dec('ff00'))),-8));
        end
    end

    methods (Hidden)

        function [statusData,timestamp]  = readStatus(obj)
            changeUserBank(obj,0);
            [tempData,~,timestamp] = obj.Device.readRegisterData(obj.INT_STATUS_1, 1, "uint8");
            if bitget(uint8(tempData),1)
                statusData = uint8(0);
            else
                statusData = uint8(1);
            end
        end


        function changeUserBank(obj, bankNo)
            if  obj.UserBank ~= bankNo
                andMask = 0xCF;
                switch bankNo
                    case 0
                        orValue = 0x00;
                    case 1
                        orValue = 0x10;
                    case 2
                        orValue = 0x20;
                    case 3
                        orValue = 0x30;
                    otherwise
                        orValue = 0x00;
                end
                value = uint8(readRegister(obj.Device,obj.REG_BANK_SEL,1,'uint8'));
                value = uint8(bitor(bitand(value,andMask),orValue));
                writeRegister(obj.Device,obj.REG_BANK_SEL,value);
                obj.UserBank = bankNo;
            end
        end
    end
end
