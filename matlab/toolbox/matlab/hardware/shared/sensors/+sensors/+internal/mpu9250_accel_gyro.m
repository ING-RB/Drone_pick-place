classdef (Sealed) mpu9250_accel_gyro < matlabshared.sensors.accelerometer & ...
        matlabshared.sensors.gyroscope & matlabshared.sensors.sensorUnit & matlabshared.sensors.I2CSensorProperties
    
    %   Copyright 2017-2020 The MathWorks, Inc.
    
    %#codegen
    
    properties(SetAccess = protected, GetAccess = public, Hidden)
        MinSampleRate = 11;
        MaxSampleRate = 200;
    end
    
    properties(Nontunable, Hidden)
        DoF = [3;3]
    end
    
    properties(Access = protected, Constant)
        AccelerometerRange = '2 g'
        GyroscopeRange = '250 dps'
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
        AccelerometerODR;
        GyroscopeODR;
        AccelerometerBandwidth;
        GyroscopeBandwidth;
    end
    
    properties(Hidden, Constant)
        PWR_MGMT_1 = 0x6B;
        MPU9250_INT_CONFIG = 0x37;
        SMPLRT_DIV = 0x19;
        CONFIG = 0x1A;
        GYRO_CONFIG = 0x1B;
        ACCEL_CONFIG = 0x1D;
        GyroscopeParameters = struct('Bandwidth', [250, 184, 92, 41, 20, 10, 5], ...
            'DLPF', 0:6);  % Ignoring the 8 kHz sampling rate and the entries without LPF
        AccelerometerParameters = struct('Bandwidth', [218.1, 99, 44.8, 21.2, 10.2, 5.05, 420], ...
            'DLPF', 1:7);
        ODRParameters = struct('SupportedODR', 1000./(1:256), 'SampleRateDivider', 0:255);
        BytesToRead = 6;
    end
    
    methods
        function obj = mpu9250_accel_gyro(varargin)
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
            writeRegister(obj.Device , obj.PWR_MGMT_1 , 0);
            writeRegister(obj.Device ,obj.MPU9250_INT_CONFIG ,  0x2);
        end
        function initAccelerometerImpl(obj)
            % Set accel_fchoice_b as 0. This is required for using the DLPF
            writeRegister(obj.Device, obj.ACCEL_CONFIG, uint8(0));
            setRangeByte(obj , obj.AccelerometerRange);
            obj.AccelerometerResolution = getGsPerLSB(obj);
        end
        function initGyroscopeImpl(obj)
            % Set Fchoice_b as 0 and gyro scale as 250 dps.
            writeRegister(obj.Device, obj.GYRO_CONFIG, uint8(0));
            % Set resolution
            setResolution(obj);
        end
        function initSensorImpl(obj)
            initAccelerometerImpl(obj);
            initGyroscopeImpl(obj);
        end
        function [data,status,timestamp]  = readAccelerationImpl(obj)
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
        function [data,status,timestamp]  = readAngularVelocityImpl(obj)
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
        function [data,status,timestamp]  = readSensorDataImpl(obj)
            % Both Accel and Gyro will have same timestamp
            [dataAccel,status,timestamp]  = readAccelerationImpl(obj);
            [dataAngularVelocity,~,~]  = readAngularVelocityImpl(obj);
            data = [dataAccel,dataAngularVelocity];
        end
        function data = convertSensorDataImpl(obj, data)
            data = [convertAccelData(obj, data(1:obj.BytesToRead)) convertGyroData(obj, data(obj.BytesToRead+1:end))];
        end
        function setODRImpl(obj)
            % Set ODR based on sample rate
            maxBandwidth = obj.SampleRate/2;
            gyroBW = max(obj.GyroscopeParameters.Bandwidth(obj.GyroscopeParameters.Bandwidth <= maxBandwidth));
            gyro_dlpf_cfg_val = obj.GyroscopeParameters.DLPF(obj.GyroscopeParameters.Bandwidth == gyroBW);
            setGyroDLPF(obj, gyro_dlpf_cfg_val);
            
            accelBW = max(obj.AccelerometerParameters.Bandwidth(obj.AccelerometerParameters.Bandwidth <= maxBandwidth));
            accel_dlpf_cfg_val = obj.AccelerometerParameters.DLPF(obj.AccelerometerParameters.Bandwidth == accelBW);
            setAccelDLPF(obj, accel_dlpf_cfg_val);
            
            accelODR = min(obj.ODRParameters.SupportedODR(obj.ODRParameters.SupportedODR > 2*accelBW));
            gyroODR = min(obj.ODRParameters.SupportedODR(obj.ODRParameters.SupportedODR > 2*gyroBW));
            sampleRateDivider = obj.ODRParameters.SampleRateDivider(obj.ODRParameters.SupportedODR == max(gyroODR,accelODR));
            writeRegister(obj.Device, obj.SMPLRT_DIV, sampleRateDivider);
            obj.AccelerometerBandwidth = accelBW;
            obj.GyroscopeBandwidth = gyroBW;
            obj.AccelerometerODR = accelODR;
            obj.GyroscopeODR = gyroODR;
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
        
        
        function setAccelDLPF(obj, accel_dlpf_cfg_val)
            registerValue = uint8(readRegister(obj.Device, obj.ACCEL_CONFIG, 1));
            % Lowest 3 bits are used to configure LPF.
            byteMask = bin2dec('11111000');
            registerValue = bitor(bitand(uint8(byteMask), registerValue), uint8(accel_dlpf_cfg_val));
            writeRegister(obj.Device, obj.ACCEL_CONFIG, registerValue);
        end
        
        function setRangeByte(obj , range)
            
            MPU9250_ACCEL_ACCEL_CONFIG     = 0x1C;
            
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
            
            val = readRegister(obj.Device,MPU9250_ACCEL_ACCEL_CONFIG);
            writeRegister(obj.Device,MPU9250_ACCEL_ACCEL_CONFIG ,bitor(uint8(val),ByteMask));
        end
        
        function g = getGsPerLSB(obj)
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
        
        function setGyroDLPF(obj, gyro_dlpf_cfg_val)
            registerValue = uint8(readRegister(obj.Device, obj.CONFIG, 1));
            % Lowest 3 bits are used to configure LPF.
            byteMask = bin2dec('11111000');
            registerValue = bitor(bitand(uint8(byteMask), registerValue), uint8(gyro_dlpf_cfg_val));
            writeRegister(obj.Device, obj.CONFIG, registerValue);
        end
        
        function setResolution(obj)
            switch obj.GyroscopeRange
                case sprintf('250 dps')
                    obj.GyroscopeResolution =  0.0076;
                    ByteMask =  0x00;
                case sprintf('500 dps')
                    obj.GyroscopeResolution = 0.0153;
                    ByteMask =  0x08;
                case sprintf('1000 dps')
                    obj.GyroscopeResolution = 0.0305;
                    ByteMask =  0x10;
                case sprintf('2000 dps')
                    obj.GyroscopeResolution = 0.061;
                    ByteMask =  0x18;
            end
            % Sometimes 250 dps might not be enough to measure rotation.
            % Consider changing it to 2000 dps.
            
            MPU6050_GYRO_GYRO_CONFIG      = 0x1B;
            bOld = readRegister(obj.Device,MPU6050_GYRO_GYRO_CONFIG);
            bNew = bitor(uint8(bOld),ByteMask);
            writeRegister(obj.Device,MPU6050_GYRO_GYRO_CONFIG,bNew);
        end
        
        function data = convertAccelData(obj,accelSensorData)
            xa = double(bitor(int16(accelSensorData(:, 2)), bitshift(int16(accelSensorData(:, 1)),8))) ;
            ya = double(bitor(int16(accelSensorData(:, 4)), bitshift(int16(accelSensorData(:, 3)),8))) ;
            za = double(bitor(int16(accelSensorData(:, 6)), bitshift(int16(accelSensorData(:, 5)),8))) ;
            data = obj.AccelerometerResolution.*[xa, ya, za];
            % Convert the data from g-scale to m/s^2 scale
            data = data*9.81;
        end
        
        function data = convertGyroData(obj,gyroSensorData)
            xg = double((bitor(int16(gyroSensorData(:, 2)), bitshift(int16(gyroSensorData(:, 1)),8))));
            yg = double((bitor(int16(gyroSensorData(:, 4)), bitshift(int16(gyroSensorData(:, 3)),8))));
            zg = double((bitor(int16(gyroSensorData(:, 6)), bitshift(int16(gyroSensorData(:, 5)),8))));
            data = obj.GyroscopeResolution.*[xg, yg, zg];
            % Convert the data from degree/s to rad/s
            data = data*pi/180;
        end
    end
end