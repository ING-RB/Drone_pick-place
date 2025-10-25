classdef LSM6DSBase < matlabshared.sensors.accelerometer & ...
        matlabshared.sensors.gyroscope & ...
        matlabshared.sensors.TemperatureSensor & ...
        matlabshared.sensors.sensorUnit & ...
        matlabshared.sensors.I2CSensorProperties
    % Base class for LSM6DS family of 6-axis sensor with accelerometer and gyroscope.
    
    %Copyright 2020-2021 The MathWorks, Inc.
    %#codegen
    properties(SetAccess = protected, GetAccess = public, Hidden)
        MinSampleRate = 12.5; % Minimum ODR that can be set
        MaxSampleRate = 200;
    end
    
    properties(Nontunable, Hidden)
        DoF = [3;3;1]; % x, y z values of accel, x, y and z values of gyro and temperature
    end
    
    properties(Nontunable,AbortSet,Hidden)
        GyroscopeRange ; % range of Gyroscope
        AccelerometerRange; % range of Accelerometer
    end
    
    properties(Hidden,Access = protected)
        AccelerometerResolution = 1/16384; % corresponds to default values in the sensor
        GyroscopeResolution =  4.375e-03;
    end

    properties(Access = protected, Constant)
        SupportedInterfaces = 'I2C';
    end
    
    properties(Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Constant)
        I2CAddressList = [0x6A,0x6B];
    end
    
    properties(Access = protected, Constant)
        GyroscopeDataRegister = 0x22;
        AccelerometerDataRegister = 0x28;
        TemperatureDataRegister = 0x20;
        StatusRegister = 0x1E;
        TempOffset = 25;
    end
    
    properties(Hidden, Constant, Access = protected)
        CTRL1_XL = 0x10;
        CTRL8_XL = 0x17;
        CTRL9_XL = 0x18;
        CTRL2_G  = 0x11;
        CTRL7_G = 0x16;
        CTRL4_C  = 0x13;
        CTRL6_C  = 0x15;
        CTRL10_C = 0x19;
        TAP_CFG = 0x58;
        WHO_AM_I = 0x0F;
        STATUS_REG = 0x1E;
        BytesToRead = 6;
    end
    
    properties(Abstract, Access = protected, Constant)
        ODRParametersGyro;
        ODRParametersAccel;
    end
    
    properties(Abstract,Constant,Hidden)
        DeviceName;
        DeviceID; % Value in WHO_AM_I register in hex
    end
    
    properties(Hidden, Nontunable)
        isActiveAccel = true;
        isActiveGyro = true;
        isActiveTemp = true;
    end
    
    properties(Abstract, Access = protected,Nontunable)
        TemperatureResolution;
    end
    
    methods(Hidden)
        function obj = LSM6DSBase(varargin)
            obj@matlabshared.sensors.sensorUnit(varargin{:})
        end
    end
    
    methods
        function set.isActiveAccel(obj,value)
            if value
                % enable accel axis
                writeRegister(obj.Device, obj.CTRL9_XL, 0x38);
            end
            obj.isActiveAccel = value;
        end
        
        function set.isActiveGyro(obj,value)
            if value
                writeRegister(obj.Device, obj.CTRL10_C , uint8(0x38)); % enable axis
            end
            obj.isActiveGyro = value;
        end
        
        function set.isActiveTemp(obj,value)
            setIsActiveTemp(obj,value);
            obj.isActiveTemp = value;
        end
        
        function set.AccelerometerRange(obj ,value)
            setAccelerometerRange(obj ,value)
            obj.AccelerometerRange = value;
        end
        
        function set.GyroscopeRange(obj,value)
            setGyroscopeRange(obj,value)
            obj.GyroscopeRange = value;
        end
    end
    
    methods(Hidden)
        function [status, timestamp] = readStatus(obj)
            status = int8([-1,-1,-1]);
            [temp,~,timestamp] = obj.Device.readRegisterData(obj.StatusRegister, 1, 'uint8');
            % last 3 bits represent the status of accel,gyro and temp
            statusValues = bitget(uint8(temp),3:-1:1);
            % 0 represents, new data
            % 1 represents, old data
            % -1 represent, sensor not activated
            if obj.isActiveAccel
                status(1) = int8(~statusValues(3));
            end
            if obj.isActiveGyro
                status(2) = int8(~statusValues(2));
            end
            if obj.isActiveTemp
                status(3) = int8(~statusValues(1));
            end
        end
    end
    
    methods(Access = protected)
        function initDeviceImpl(obj)
            % All the LSM6 sensors have same I2C Address, who_am_I register
            % can be used to differentiate them
            deviceid_value = readRegister(obj.Device, obj.WHO_AM_I,1,'uint8');
            if(deviceid_value ~= obj.DeviceID)
                if coder.target('MATLAB')
                    matlabshared.sensors.internal.localizedWarning('matlab_sensors:general:invalidDeviceID',obj.DeviceName,num2str(obj.DeviceID));
                end
            end
        end
        
        function  initAccelerometerImpl(~)
        end
        
        function  initGyroscopeImpl(~)
        end
        
        function initSensorImpl(~)
        end
        
        function [data,status,timestamp] = readAccelerationImpl(obj)
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
        
        function [data,status,timestamp] = readAngularVelocityImpl(obj)
            [tempData,status,timestamp] = obj.Device.readRegisterData(obj.GyroscopeDataRegister, obj.BytesToRead, "uint8");
            if(isequal(size(tempData,2),1))
                data = tempData';
                if(isequal(numel(data),obj.SamplesPerRead*obj.BytesToRead))
                    data = reshape(data, [obj.BytesToRead,obj.SamplesPerRead])';
                end
            else
                data = tempData;
            end
            data = convertGyroData(obj, data);
        end
        
        function [data,status,timestamp] = readTemperatureImpl(obj)
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
        
        function [data,status,timestamp] = readSensorDataImpl(obj)
            % Both Accel and Gyro will have same timestamp
            [dataAccel,status,timestamp]  = readAccelerationImpl(obj);
            [dataAngularVelocity,~,~]  = readAngularVelocityImpl(obj);
            [dataTemp,~,~]  = readTemperatureImpl(obj);
            data = [dataAccel,dataAngularVelocity,dataTemp];
        end
        
        function data = convertSensorDataImpl(obj, data)
            data = [convertAccelData(obj, data(1:obj.BytesToRead)) convertGyroData(obj, data(obj.BytesToRead+1:2*obj.BytesToRead)),convertTempData(obj,data(2*obj.BytesToRead+1:end))];
        end
        
        function s = infoImpl(obj)
            s = struct('AccelerometerODR', obj.AccelerometerODR, 'GyroscopeODR', obj.GyroscopeODR);
        end
        
        function names = getMeasurementDataNames(obj)
            names = [obj.AccelerometerDataName, obj.GyroscopeDataName, obj.TemperatureDataName];
        end
    end
    
    methods(Access = protected)
        function data = convertAccelData(obj, accel_data)
            accel_x = double(bitor(int16(accel_data(:, 1)), bitshift(int16(accel_data(:, 2)),8)));
            accel_y = double(bitor(int16(accel_data(:, 3)), bitshift(int16(accel_data(:, 4)),8)));
            accel_z = double(bitor(int16(accel_data(:, 5)), bitshift(int16(accel_data(:, 6)),8)));
            data = obj.AccelerometerResolution.*[accel_x, accel_y, accel_z];
            % Convert the data from g-scale to m/s^2 scale
            data = data.*9.81;
        end
        
        function data = convertGyroData(obj, gyroData)
            gyro_x = double(bitor(int16(gyroData(:, 1)), bitshift(int16(gyroData(:, 2)),8)));
            gyro_y = double(bitor(int16(gyroData(:, 3)), bitshift(int16(gyroData(:, 4)),8)));
            gyro_z = double(bitor(int16(gyroData(:, 5)), bitshift(int16(gyroData(:, 6)),8)));
            data = obj.GyroscopeResolution.*[gyro_x, gyro_y, gyro_z];
            % Convert the data from degrees/sec to rad/sec scale
            data = data*pi/180;
        end
        
        function data = convertTempData(obj,data)
            data = double(bitor(int16(data(:, 1)), bitshift(int16(data(:, 2)),8)));
            data = obj.TemperatureResolution*(data)+obj.TempOffset;
        end
    end
    
    methods(Access = private)
        function setIsActiveTemp(obj,value)
            if value
                % For temperature sensor to work either accel or gyro needs
                % to be on, turn on accel if both are off.
                if ~obj.isActiveAccel && ~obj.isActiveGyro
                    writeRegister(obj.Device, obj.CTRL9_XL, uint8(0x38)); % enable accel axis
                    % set a ODR value to power on accel
                    ByteMask_CTRL1_XL = 0x10;
                    val_CTRL1_XL = readRegister(obj.Device, obj.CTRL1_XL);
                    writeRegister(obj.Device,obj.CTRL1_XL, bitor(bitand(val_CTRL1_XL, uint8(0x0F)), uint8(ByteMask_CTRL1_XL)));
                end
            end
        end
        
        function setAccelerometerRange(obj ,value)
            if obj.isActiveAccel
                switch value
                    case '+/- 2g'
                        ByteMask = 0x00;
                        obj.AccelerometerResolution = 1/16384;
                    case '+/- 4g'
                        ByteMask = 0x08;
                        obj.AccelerometerResolution = 1/8192;
                    case '+/- 8g'
                        ByteMask = 0x0C;
                        obj.AccelerometerResolution = 1/4096;
                    case '+/- 16g'
                        ByteMask = 0x04;
                        obj.AccelerometerResolution = 1/2048;
                    otherwise
                        ByteMask = 0x00;
                        obj.AccelerometerResolution = 1/16384;
                end
                val = readRegister(obj.Device, obj.CTRL1_XL);
                writeRegister(obj.Device, obj.CTRL1_XL, bitor(bitand(val, 0xF3), uint8(ByteMask)));
            end
        end
        
        function setGyroscopeRange(obj,value)
            if obj.isActiveGyro
                switch value
                    case '125 dps'
                        ByteMask = 0x02;
                        obj.GyroscopeResolution =  4.375e-03;
                    case '250 dps'
                        ByteMask = 0x00;
                        obj.GyroscopeResolution = 8.75e-03;
                    case '500 dps'
                        ByteMask = 0x04;
                        obj.GyroscopeResolution = 17.50e-03;
                    case '1000 dps'
                        ByteMask = 0x08;
                        obj.GyroscopeResolution =  35e-03;
                    case '2000 dps'
                        ByteMask = 0x0C;
                        obj.GyroscopeResolution =  70e-03;
                    case '4000 dps'
                        % Gyro Range of 4000dps is only available in LSM6DSR
                        if (strcmp("LSM6DSR", obj.DeviceName))
                            ByteMask = 0x01;
                            obj.GyroscopeResolution = 140e-03;
                        else
                            warningString = obj.DeviceName+" doesn't support Gyroscope Range of 4000dps. Setting maximum available range of 2000dps.";
                            warning(warningString)
                            ByteMask = 0x0C; % ByteMask corresponding to 2000dps
                        end
                    otherwise
                        ByteMask = 0x02;
                        obj.GyroscopeResolution =  4.375e-03;
                end
                val = readRegister(obj.Device, obj.CTRL2_G);
                writeRegister(obj.Device, obj.CTRL2_G, bitor(bitand(val, 0xF0), uint8(ByteMask)));
            end
        end
    end
end