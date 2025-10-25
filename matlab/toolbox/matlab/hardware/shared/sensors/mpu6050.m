classdef (Sealed) mpu6050 < matlabshared.sensors.accelerometer & matlabshared.sensors.gyroscope & matlabshared.sensors.sensorUnit &...
        matlabshared.sensors.I2CSensorProperties
    %MPU6050 connects to the MPU9250 sensor connected to a hardware object
    %
    %   IMU = mpu6050(a) returns a System object, IMU that reads sensor
    %   data from the MPU6050 sensor connected to the I2C bus of an
    %   hardware board. 'a' is a hardware object.
    %
    %   IMU = mpu6050(a, 'Name', Value, ...) returns a MPU6050 System object
    %   with each specified property name set to the specified value. You
    %   can specify additional name-value pair arguments in any order as
    %   (Name1,Value1,...,NameN, ValueN).
    %
    %   mpu6050 Properties
    %   I2CAddress      : Specify the I2C Address of the MPU6050.
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
    %   mpu6050 methods
    %
    %   readAcceleration      : Read one sample of acceleration data from
    %                           sensor.
    %   readAngularVelocity   : Read one sample of angular velocity values from
    %                           sensor.
    %   read                  : Read one frame of acceleration and angular
    %                           velocity  from the sensor along with time
    %                           stamps and overruns.
    %  stop/release           : Stop sending data from hardware and
    %                           allow changes to non-tunable properties
    %                           values and input characteristics.
    %  flush                  : Flushes all the data accumulated in the
    %                           buffers and resets the system object.
    %  info                   : Read sensor information such as output
    %                           data rate, bandwidth and so on.
    %
    %  Note: For targets other than Arduino, mpu6050 object is supported 
    %  with limited functionality. For those targets, you can use the
    %  'readAcceleration', and 'readAngularVelocity' functions, and the
    %  the 'Bus' and 'I2CAddress' properties.
    %
    %   Example 1: Read one sample of acceleration value from MPU6050 sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % Create arduino object with I2C library included
    %   sensorObj = mpu6050(a);
    %   accelData  =  sensorObj.readAcceleration;
    %
    %   Example 2: Read and plot acceleration values from an MPU9250 sensor
    %
    %   a = arduino('COM3','Uno','Libraries','I2C'); % create arduino object with I2C library included
    %   sensorObj = mpu6050(a,'SampleRate',100,'SamplesPerRead',50);
    %   sensorObj.OutputFormat = 'matrix';
    %   figure;
    %   xlabel('Samples read');
    %   ylabel('Acceleration (m/s^2)');
    %   title('Acceleration values from MPU6050 sensor');
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
    %     [accel,gyro] = read(sensorObj);
    %     addpoints(x_val,count:(count+sensorObj.SamplesPerRead-1),accel(:,1));
    %     addpoints(y_val,count:(count+sensorObj.SamplesPerRead-1),accel(:,2));
    %     addpoints(z_val,count:(count+sensorObj.SamplesPerRead-1),accel(:,3));
    %     count = count + sensorObj.SamplesPerRead;
    %     drawnow limitrate;
    %   end
    %   release(sensorObj);
    %   clear
    %
    %   See also mpu9250, lsm9ds1, bno055, read, readAcceleration,
    %   readAngularVelocity, readMagneticField
    
    %   Copyright 2018-2021 The MathWorks, Inc.
    %#codegen
    
    properties(SetAccess = protected, GetAccess = public, Hidden)
        MinSampleRate = 10;
        MaxSampleRate = 200;
    end
    
    properties(Nontunable, Hidden)
        DoF = [3;3];
    end
    
    properties(Access = protected, Constant)
        AccelerometerRange = '2 g';
        GyroscopeRange = '250 dps';
        % value stored in WHO_AM_I register.
        DeviceID = '68';
        AccelerometerDataRegister = 0x3B;
        GyroscopeDataRegister = 0x43;
    end

    properties(Access = protected, Constant)
        SupportedInterfaces = 'I2C';
    end

    properties(Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Constant)
        I2CAddressList = [0x68,0x69];
    end

    properties(Access = protected)
        AccelerometerResolution;
        GyroscopeResolution;
        %single Sample rate for Gyro and accel
        AccelerometerODR;
        GyroscopeODR;
        AccelerometerBandwidth;
        GyroscopeBandwidth;
    end
    
    properties(Hidden, Constant)
        PWR_MGMT_1 = 0x6B;
        SMPLRT_DIV = 0x19;
        CONFIG = 0x1A;
        GYRO_CONFIG = 0x1B;
        ACCEL_CONFIG = 0x1C;
        WHO_AM_I = 0x75;
        %only one DLPF config register for accel and gyro
        GyroscopeParameters = struct('Bandwidth', [256, 188, 98, 42, 20, 10, 5], ...
            'DLPF', 0:6);  % Ignoring the 8 kHz sampling rate
        AccelerometerParameters = struct('Bandwidth', [260, 184, 94, 44, 21, 10,5], ...
            'DLPF', 0:6);
        ODRParameters = struct('SupportedODR', 1000./(1:256), 'SampleRateDivider', 0:255);
        BytesToRead = 6;
    end
    
    methods
        
        function obj = mpu6050(varargin)
            % Code generation does not support try-catch block. So init
            % function call is made separately in both codegen and IO
            % context.
            obj@matlabshared.sensors.sensorUnit(varargin{:})
            if ~coder.target('MATLAB')
                obj.init(varargin{:});
            else
                try
                    obj.init(varargin{:});
                catch ME
                    throwAsCaller(ME);
                end
            end
        end
    end
    
    methods(Access = protected)
        
        function initDeviceImpl(obj)
            writeRegister(obj.Device , obj.PWR_MGMT_1, 0);
            % check the device ID of MPU6050 is as expected.Other I2C
            % sensors can be created with the same API, if they have the
            % same I2C address.
            deviceid_value = readRegister(obj.Device, obj.WHO_AM_I);
            coder.extrinsic('matlabshared.sensors.internal.localizedWarning');
            if(strcmp(dec2hex(deviceid_value),obj.DeviceID)== false)
                matlabshared.sensors.internal.localizedWarning('matlab_sensors:general:invalidDeviceID','MPU6050',num2str(0x68));
            end
        end
        
        function initAccelerometerImpl(obj)
            writeRegister(obj.Device, obj.ACCEL_CONFIG, uint8(0));
            setAccelRangeByte(obj, obj.AccelerometerRange);
            obj.AccelerometerResolution = getAsPerLSB(obj);
        end
        
        function initGyroscopeImpl(obj)
            writeRegister(obj.Device, obj.GYRO_CONFIG, uint8(0));
            setGyroRangeByte(obj, obj.GyroscopeRange);
            obj.GyroscopeResolution = getGsPerLSB(obj);
        end
        
        function initSensorImpl(obj)
            initAccelerometerImpl(obj);
            initGyroscopeImpl(obj);
        end
        
        function [data,status,timestamp] = readAccelerationImpl(obj)
            [tempData,status,timestamp]  = obj.Device.readRegisterData(obj.AccelerometerDataRegister, obj.BytesToRead, "uint8");
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
        
        function [data,status,timestamp]  = readAngularVelocityImpl(obj)
            [tempData,status,timestamp]  = obj.Device.readRegisterData(obj.GyroscopeDataRegister, obj.BytesToRead, "uint8");
            if(isequal(size(tempData,2),1))
                data = tempData';
                if(isequal(numel(data),obj.SamplesPerRead*obj.BytesToRead))
                    data = reshape(data,[obj.BytesToRead,obj.SamplesPerRead])';
                end
            else
                data = tempData;
            end
            data = convertGyroData(obj, data);
        end
        
        function [data,status,timestamp]  = readSensorDataImpl(obj)
            % Both Accel and Gyro will have same timestamp
            [dataAccel,status,timestamp]  = readAccelerationImpl(obj);
            [dataAngularVelocity,~,~]  = readAngularVelocityImpl(obj);
            data = [dataAccel,dataAngularVelocity];
        end
        
        function data = convertSensorDataImpl(obj, data)
            data = [convertAccelData(obj, data(1:obj.BytesToRead)) convertGyroData(obj, data(obj.BytesToRead+1:2*obj.BytesToRead))];
        end
        
        function setODRImpl(obj)
            maxBandwidth = obj.SampleRate/2;
            gyro_SupportedBandwidth = max(obj.GyroscopeParameters.Bandwidth(obj.GyroscopeParameters.Bandwidth <= maxBandwidth));
            accel_SupportedBandwidth = max(obj.AccelerometerParameters.Bandwidth(obj.AccelerometerParameters.Bandwidth <= maxBandwidth));
            %   single DLPF config register for accelerometer and gyroscope,hence select the lowest bandwidth among gyroscope supported BW and accelerometer supported BW
            if(gyro_SupportedBandwidth<accel_SupportedBandwidth)
                dlpf_cfg_val = obj.GyroscopeParameters.DLPF(obj.GyroscopeParameters.Bandwidth == gyro_SupportedBandwidth);
                accelBW = obj.AccelerometerParameters.Bandwidth(dlpf_cfg_val+1);  %   matlab indexing starts from 1
                gyroBW = gyro_SupportedBandwidth;
            else
                dlpf_cfg_val = obj.AccelerometerParameters.DLPF(obj.AccelerometerParameters.Bandwidth == accel_SupportedBandwidth);
                accelBW = accel_SupportedBandwidth;
                gyroBW = obj.GyroscopeParameters.Bandwidth(dlpf_cfg_val+1);
            end
            SampleRate_min= 2*max(gyroBW,accelBW);
            % only one DLPF config register and sampleRateDivider for accel and gyro
            accelODR =min(obj.ODRParameters.SupportedODR(obj.ODRParameters.SupportedODR >= SampleRate_min));
            sampleRateDivider = (obj.ODRParameters.SampleRateDivider(obj.ODRParameters.SupportedODR==accelODR));
            
            writeRegister(obj.Device, obj.SMPLRT_DIV, sampleRateDivider);
            val=readRegister(obj.Device, obj.CONFIG);
            writeRegister(obj.Device, obj.CONFIG, bitand(bitor(val,7),uint8(dlpf_cfg_val)));
            obj.AccelerometerBandwidth = accelBW;
            obj.GyroscopeBandwidth = gyroBW;
            obj.AccelerometerODR = accelODR;
            obj.GyroscopeODR = obj.AccelerometerODR;
        end
        
        function s = infoImpl(obj)
            if coder.target('MATLAB')
                s = struct('AccelerometerODR', obj.AccelerometerODR,'AccelerometerBandwidth',obj.AccelerometerBandwidth, 'GyroscopeODR', obj.GyroscopeODR,'GyroscopeBandwidth',obj.GyroscopeBandwidth);
            else
                coder.internal.errorIf(true, 'matlab_sensors:general:unsupportedFunctionSensorCodegen', 'info');
            end
        end
        
        function names = getMeasurementDataNames(obj)
            names = [obj.AccelerometerDataName, obj.GyroscopeDataName];
        end
    end
    
    methods(Access = private)
        
        function setAccelRangeByte(obj,range)
            switch range
                case '2 g'
                    ByteMask = 0x00;
                case '4 g'
                    ByteMask = 0x08;
                case '8 g'
                    ByteMask = 0x10;
                case '16 g'
                    ByteMask = 0x18;
            end
            val = readRegister(obj.Device,obj.ACCEL_CONFIG);
            writeRegister(obj.Device,obj.ACCEL_CONFIG,bitor(uint8(val),ByteMask));
        end
        
        function setGyroRangeByte(obj, range)
            switch range
                case sprintf('250 dps')
                    ByteMask =  0x00;
                case sprintf('500 dps')
                    ByteMask =  0x08;
                case sprintf('1000 dps')
                    ByteMask =  0x10;
                case sprintf('2000 dps')
                    ByteMask =  0x18;
            end
            val = readRegister(obj.Device,obj.GYRO_CONFIG);
            writeRegister(obj.Device,obj.GYRO_CONFIG,bitor(uint8(val),ByteMask));
        end
        
        function g = getAsPerLSB(obj)
            switch  obj.AccelerometerRange
                case sprintf('2 g')
                    g = 1/16384;
                case sprintf('4 g')
                    g = 1/8192;
                case sprintf('8 g')
                    g = 1/4096;
                case sprintf('16 g')
                    g = 1/2048;
            end
        end
        
        function g=getGsPerLSB(obj)
            switch obj.GyroscopeRange
                case '250 dps'
                    g =  1/131;
                case '500 dps'
                    g = 1/65.5;
                case '1000 dps'
                    g = 1/32.5;
                case '2000 dps'
                    g = 1/16.4;
            end
        end
        
        function data = convertAccelData(obj, accel_data)
            accel_x = double(bitor(int16(accel_data(:, 2)), bitshift(int16(accel_data(:, 1)),8)));
            accel_y = double(bitor(int16(accel_data(:, 4)), bitshift(int16(accel_data(:, 3)),8)));
            accel_z = double(bitor(int16(accel_data(:, 6)), bitshift(int16(accel_data(:, 5)),8)));
            data = obj.AccelerometerResolution.*[accel_x, accel_y, accel_z];
            % Convert the data from g-scale to m/s^2 scale
            data = data.*9.81;
        end
        
        function data = convertGyroData(obj,gyroData)
            gyro_x = double(bitor(int16(gyroData(:, 2)), bitshift(int16(gyroData(:, 1)),8)));
            gyro_y = double(bitor(int16(gyroData(:, 4)), bitshift(int16(gyroData(:, 3)),8)));
            gyro_z = double(bitor(int16(gyroData(:, 6)), bitshift(int16(gyroData(:, 5)),8)));
            data = obj.GyroscopeResolution.*[gyro_x, gyro_y, gyro_z];
            % Convert the data from degrees/sec to rad/sec scale
            data = data*pi/180;
        end
    end
end
