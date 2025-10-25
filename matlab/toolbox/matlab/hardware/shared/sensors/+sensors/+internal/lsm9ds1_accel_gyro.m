classdef (Sealed) lsm9ds1_accel_gyro < matlabshared.sensors.accelerometer & matlabshared.sensors.gyroscope & matlabshared.sensors.sensorUnit &...
        matlabshared.sensors.I2CSensorProperties
    
    %   Copyright 2017-2020 The MathWorks, Inc.
    
    %#codegen
    
    properties(SetAccess = protected, GetAccess = public, Hidden)
        MinSampleRate = 28;
        MaxSampleRate = 200;
    end
    
    properties(Nontunable, Hidden)
        DoF = [3;3];
    end
    
    properties(Access = protected, Constant)
        AccelerometerRange = '2 g'
        GyroscopeRange = '245 dps'
        GyroscopeDataRegister = 0x18;
        AccelerometerDataRegister = 0x28;
        WHO_AM_I = 0x0F;
        DeviceID = 0x68;
    end

    properties(Access = protected, Constant)
        SupportedInterfaces = 'I2C';
    end
    
    properties(Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Constant)
        I2CAddressList = [0x6B,0x6A];
    end
    
    properties(Access = protected)
        AccelerometerResolution;
        GyroscopeResolution;
        AccelerometerODR;
        GyroscopeODR;
        GyroscopeBandwidth;
    end
    
    properties(Hidden, Constant, Access = private)
        CTRL_REG1_G = 0x10;
        GyroscopeParameters = struct('LPF2BandWidth',[16,16,16,16;14,31,31,31;14,29,63,78;21,28,57,100;33,40,58,100], ...
            'HPFBandWidth',[]);
        ODRParameters = struct('SupportedODR',[59.5,119,238,476,952]); % ODR for both accel-gyro
        BytesToRead = 6;
    end
    
    methods
        function obj = lsm9ds1_accel_gyro(varargin)
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
        end
    end
    
    methods(Access = protected)
        
        function initDeviceImpl(obj)
            if coder.target('MATLAB')
                deviceid_value = readRegister(obj.Device, obj.WHO_AM_I,1,'uint8');
                if(deviceid_value ~= obj.DeviceID)
                    matlabshared.sensors.internal.localizedWarning('matlab_sensors:general:invalidDeviceID','LSM9DS1 accelerometer/gyroscope',num2str(obj.DeviceID));
                end
            end
        end
        
        function initAccelerometerImpl(obj)
            setAccelRangeByte(obj, obj.AccelerometerRange);
            obj.AccelerometerResolution = getAsPerLSB(obj);
        end
        
        function initGyroscopeImpl(obj)
            setGyroRangeByte(obj, obj.GyroscopeRange);
            obj.GyroscopeResolution = getGsPerLSB(obj);
        end
        
        function initSensorImpl(obj)
            initAccelerometerImpl(obj);
            initGyroscopeImpl(obj);
        end
        
        function setODRImpl(obj)
            maxBandWidth = obj.SampleRate/2;
            gyroBW = max(obj.GyroscopeParameters.LPF2BandWidth(obj.GyroscopeParameters.LPF2BandWidth <= maxBandWidth));
            [r,c] = find(gyroBW == obj.GyroscopeParameters.LPF2BandWidth,1,'first');
            accelODR = obj.ODRParameters.SupportedODR(r);
            switch accelODR
                case 59.5
                    ByteMask = bitor(0x40,uint8(c-1)); % decrementing c by 1 because of difference in MATLAB and binary indexing. (see table 47)
                case 119
                    ByteMask = bitor(0x60,uint8(c-1));
                case 238
                    ByteMask = bitor(0x80,uint8(c-1));
                case 476
                    ByteMask = bitor(0xA0,uint8(c-1));
                case 952
                    ByteMask = bitor(0xC0,uint8(c-1));
            end
            val = readRegister(obj.Device,obj.CTRL_REG1_G);
            writeRegister(obj.Device,obj.CTRL_REG1_G ,bitor(uint8(val),ByteMask));
            obj.GyroscopeBandwidth = gyroBW;
            obj.AccelerometerODR = accelODR;
            obj.GyroscopeODR = accelODR; % Because they are same
        end
        
        function [data,status,timestamp] = readAccelerationImpl(obj)
            [tempData,status,timestamp] = obj.Device.readRegisterData(obj.AccelerometerDataRegister, obj.BytesToRead, "uint8");
            if(isequal(size(tempData,2),1))
                data = tempData'; % To take care of the streaming data and the on Demand data which comes in Nx1 form
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
                    data = reshape(data,[obj.BytesToRead,obj.SamplesPerRead])';
                end
            else
                data = tempData;
            end
            data = convertGyroData(obj, data);
        end
        
        function [data,status,timestamp] = readSensorDataImpl(obj)
            % Both Accel and Gyro will have same timestamp
            [dataAccel,status,timestamp]  = readAccelerationImpl(obj);
            [dataAngularVelocity,~,~]  = readAngularVelocityImpl(obj);
            data = [dataAccel,dataAngularVelocity];
        end
        
        function data = convertSensorDataImpl(obj, data)
            data = [convertAccelData(obj, data(1:obj.BytesToRead)) convertGyroData(obj, data(obj.BytesToRead+1:end))];
        end
        
        function s = infoImpl(obj)
            % lsm9ds1 datasheet doesnt specify about accel Bandwidth when
            % both accel and gyro are activated
            if coder.target('MATLAB')
                s = struct('AccelerometerODR',obj.AccelerometerODR, 'GyroscopeODR', obj.GyroscopeODR,'GyroscopeBandwidth',obj.GyroscopeBandwidth);
            else
                coder.internal.errorIf(true, 'matlab_sensors:general:unsupportedFunctionSensorCodegen', 'info');
            end
        end
        
        function names = getMeasurementDataNames(obj)
            names = [obj.AccelerometerDataName, obj.GyroscopeDataName];
        end
    end
    
    methods(Access = private)
        
        function setAccelRangeByte(obj , range)
            
            LSM9DS1_ACCEL_CONFIG     = 0x20;
            
            switch range
                case '2 g'
                    ByteMask = 0x00;
                case '4 g'
                    ByteMask = 0x10;
                case '8 g'
                    ByteMask = 0x18;
                case '16 g'
                    ByteMask = 0x08;
            end
            
            val = readRegister(obj.Device,LSM9DS1_ACCEL_CONFIG);
            writeRegister(obj.Device,LSM9DS1_ACCEL_CONFIG ,bitor(uint8(val),ByteMask));
        end
        
        function setGyroRangeByte(obj, range)
            
            LSM9DS1_GYRO_CONFIG     = obj.CTRL_REG1_G;
            
            switch range
                case '245 dps'
                    ByteMask = 0x00;
                case '500 dps'
                    ByteMask = 0x08;
                case '2000 dps'
                    ByteMask = 0x18;
            end
            
            val = readRegister(obj.Device,LSM9DS1_GYRO_CONFIG);
            writeRegister(obj.Device,LSM9DS1_GYRO_CONFIG ,bitor(uint8(val),ByteMask));
            
        end
        
        function g = getAsPerLSB(obj)
            switch  obj.AccelerometerRange
                case '2 g'
                    g = 1/16384;
                case '4 g'
                    g = 1/8192;
                case '8 g'
                    g = 1/4096;
                case '16 g'
                    g = 1/2048;
            end
        end
        
        function g = getGsPerLSB(obj)
            switch  obj.GyroscopeRange
                case '245 dps'
                    g = 8.75*(10^-3);
                case '500 dps'
                    g = 17.50*(10^-3);
                case '2000 dps'
                    g = 70*(10^-3);
            end
        end
        
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
    end
end