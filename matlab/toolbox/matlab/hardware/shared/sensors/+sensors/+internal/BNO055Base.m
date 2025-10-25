classdef BNO055Base < matlabshared.sensors.accelerometer & matlabshared.sensors.gyroscope & ...
        matlabshared.sensors.magnetometer & matlabshared.sensors.Orientation & ...
        matlabshared.sensors.sensorUnit & matlabshared.sensors.I2CSensorProperties
    
    %Base class for bno055
    
    %   Copyright 2020 The MathWorks, Inc.
    
    %#codegen
    properties(Access = protected)
        ConfigMode = uint8(3); % prorties of sensor can only be set when sensor is in config mode.
    end
    
    properties(SetAccess = protected, GetAccess = public, Hidden)
        % Minimum bandwidth for accel is 7.81hz (SampleRate = 15.6),
        % minimum bandwidth for gyro is 12 Hz (sampleRate = 24)
        % minimum ODR for mag is 2hz. MinSampleRate is set as the maxinum
        % of the above 3 minimum samplerate.
        MinSampleRate = 24;
        MaxSampleRate = 200;
    end
        
    properties(Access = protected)
        AccelerometerResolution;
        AccelUnit = 'm/s^2'; % possible options are [m/s2,mg]
        GyroscopeResolution;
        GyroUnit = 'Rps'; % possible options are [Rps,Dps]
        MagnetometerResolution = 1/16;
        EulerUnit = 'radians'; %possible options are [radians, degress]
        EulerAngleResolution = 1/900;
        MagnetometerODR; % For setting of ODR of magnetometer
        AccelerometerBandwidth;
        GyroscopeBandwidth;
    end
    
    properties(Access = protected, Constant)
        SupportedModes = {'ndof','amg'};
        % Default accel range is 4g
        AccelerometerRange = '4g';
        % Default Gyro range is 2000dps
        GyroscopeRange = '2000 dps';
        % Fixed Range,1300ut for x, y axis and 2500ut for z axis
        MagnetometerRange	 = 1300;
        % Data Registers to read the value from
        AccelerometerDataRegister = 0x08;
        GyroscopeDataRegister = 0x14;
        MagnetometerDataRegister = 0x0E;
        CalibrationStatusRegister = 0x35;
        OrientationDataRegister = 0x1A;
        % Page ID has to be selected before reading or writing from any
        % register.
        PAGE_ID_Register = 0x07;
        % Registers in page 0
        OPR_MODE_Register = 0x3D;
        PWR_MODE_Register = 0x3E;
        UNIT_SEL_Register = 0x3B;
        % Registers in page 1
        ACC_Config_Register = 0x08;
        GYRO_Config_0Register = 0x0A;
        GYRO_Config_1Register = 0x0B;
        MAG_Config_Register = 0x09;
        AccelParameters = struct('Bandwidth',[7.81,15.63,31.25,62.5,125,250,500,1000]); % all possible values for accel bandwidth
        GyroParameters = struct('Bandwidth',[523,230,116,47,23,12,64,32]);% all possible values for gyro bandwidth
        MagParameters = struct('SupportedODR',[2,6,8,10,15,20,25,30]);% all possible values for mag ODR
        BytesToRead = 6;
        NdofSampleRate = 100; % value determined from datasheet.SampleRate in Ndof cannot be changed as the ODR and BW for sensor in this mode is autocontrolled
    end
    
    methods(Access = protected)
        function initDeviceImpl(obj)
            % take page 0
            writeRegister(obj.Device, obj.PAGE_ID_Register, uint8(0));
            % power mode to normal
            val = readRegister(obj.Device, obj.PWR_MODE_Register);
            % Do not change the 7-2 bits of the register as they are reserved.
            % Protect the bits using bytemask 
            ByteMask = 0xFC;
            writeRegister(obj.Device, obj.PWR_MODE_Register, bitand(val,ByteMask));
        end
        
        function initSensorImpl(obj)
            initAccelerometerImpl(obj);
            initGyroscopeImpl(obj);
            initMagnetometerImpl(obj);
            % set the units of all measurements
            setMeasurementUnit(obj);
            % set the resolution of the measurements
            setMeasurementResolution(obj);
        end
        
        function initAccelerometerImpl(obj)
            setAccelRangeAndNormalPowerMode(obj, obj.AccelerometerRange);
        end
        
        function initGyroscopeImpl(obj)
            setGyroRangeAndNormalPowerMode(obj, obj. GyroscopeRange);
        end
        
        function initMagnetometerImpl(obj)
            % Range fixed for Mag
            setMagPowerMode(obj);
        end
        
        function [data,status,timestamp] = readAccelerationImpl(obj)
            % Read Acceleration value in m/s^2
            [tempData,status,timestamp]  = obj.Device.readRegisterData(obj.AccelerometerDataRegister,obj.BytesToRead,"uint8");
            if(isequal(size(tempData,2),1))
                data = tempData';
                % For streaming
                if(isequal(numel(data),obj.SamplesPerRead*obj.BytesToRead))
                    data = reshape(data,[obj.BytesToRead,obj.SamplesPerRead])';
                end
            else
                % For OnDemand
                data = tempData;
            end
            data = convertAccelData(obj, data);
        end
        
        function [data,status,timestamp] = readAngularVelocityImpl(obj)
            % Read Angular velocity value in rps
            [tempData,status,timestamp]  = obj.Device.readRegisterData(obj.GyroscopeDataRegister, obj.BytesToRead, "uint8");
            if(isequal(size(tempData,2),1))
                data = tempData';
                % For streaming
                if(isequal(numel(data),obj.SamplesPerRead*obj.BytesToRead))
                    data = reshape(data,[obj.BytesToRead,obj.SamplesPerRead])';
                end
            else
                % For OnDemand
                data = tempData;
            end
            data = convertGyroData(obj, data);
        end
        
        function [data,status,timestamp] = readMagneticFieldImpl(obj)
            % Read heading,pitch and roll in value in radians
            [tempData,status,timestamp]  = obj.Device.readRegisterData(obj.MagnetometerDataRegister, obj.BytesToRead, "uint8");
            if(isequal(size(tempData,2),1))
                data = tempData';
                % For streaming
                if(isequal(numel(data),obj.SamplesPerRead*obj.BytesToRead))
                    data = reshape(data,[obj.BytesToRead,obj.SamplesPerRead])';
                end
            else
                % For OnDemand
                data = tempData;
            end
            data = convertMagData(obj, data);
        end
        
        function [data,status,timestamp] = readOrientationImpl(obj)
            [tmpdata,status,timestamp] = obj.Device.readRegisterData(obj.OrientationDataRegister,obj.BytesToRead,"uint8");
            if(isequal(size(tmpdata,2),1))
                data = tmpdata';
                % for streaming
                if(isequal(numel(data),obj.SamplesPerRead*obj.BytesToRead))
                    data = reshape(data,[obj.BytesToRead,obj.SamplesPerRead])';
                end
            else
                % For OnDemand
                data = tmpdata;
            end
            data = convertEulData(obj, data);
        end
        
        function [data,status,timestamp]  = readSensorDataImpl(obj)
            % Both Accel and Gyro will have same timestamp
            [dataAccel,status,timestamp]  = readAccelerationImpl(obj);
            [dataAngularVelocity,~,~]  = readAngularVelocityImpl(obj);
            [dataMagneticField,~,~]  = readMagneticFieldImpl(obj);
            if obj.OperatingModeEnum == matlabshared.sensors.internal.BNO055OperatingMode.ndof
                [dataOrientation,~,~]  = readOrientationImpl(obj);
                data = [dataAccel,dataAngularVelocity,dataMagneticField,dataOrientation];
            else
                data = [dataAccel,dataAngularVelocity,dataMagneticField];
            end
        end
        
        function [numericStatus] = readCalibrationStatusInternal(obj)
            writeRegister(obj.Device, obj.PAGE_ID_Register, 0);
            val = readRegister(obj.Device, obj.CalibrationStatusRegister);
            val = dec2bin(val,8);
            magStatus = bin2dec(val(7:8));
            accelStatus = bin2dec(val(5:6));
            gyroStatus = bin2dec(val(3:4));
            systemStatus = bin2dec(val(1:2));
            numericStatus = [systemStatus,accelStatus,gyroStatus,magStatus];
        end
        
        function data = convertSensorDataImpl(obj, data)
            % convert the raw values into suitable format.
             if obj.OperatingModeEnum == matlabshared.sensors.internal.BNO055OperatingMode.ndof
                data = [convertAccelData(obj, data(1:obj.BytesToRead)) convertGyroData(obj, data(obj.BytesToRead+1:2*obj.BytesToRead)) convertMagData(obj, data((2*obj.BytesToRead)+1:3*obj.BytesToRead)),convertEulData(obj, data((3*obj.BytesToRead)+1:end))];
             else
               data = [convertAccelData(obj, data(1:obj.BytesToRead)) convertGyroData(obj, data(obj.BytesToRead+1:2*obj.BytesToRead)) convertMagData(obj, data((2*obj.BytesToRead)+1:3*obj.BytesToRead))];
             end
        end
        
        function setODRImpl(obj)
            if obj.OperatingModeEnum == matlabshared.sensors.internal.BNO055OperatingMode.amg
                % Before any configuration Mode has to be be changed to
                % ConfigMode
                changeMode(obj,obj.ConfigMode);
                writeRegister(obj.Device, obj.PAGE_ID_Register, 1);
                maxBW = obj.SampleRate/2;
                obj.AccelerometerBandwidth = max(obj.AccelParameters.Bandwidth(obj.AccelParameters.Bandwidth <= maxBW));
                obj.GyroscopeBandwidth  = max(obj.GyroParameters.Bandwidth(obj.GyroParameters.Bandwidth <= maxBW));
                AndMaskAccel = 0xE3;
                switch obj.AccelerometerBandwidth
                    case 7.81
                        ByteMask = 0x00;
                    case 15.63
                        ByteMask = 0x04;
                    case 31.25
                        ByteMask = 0x08;
                    case 62.5
                        ByteMask = 0x0C;
                    case 125
                        ByteMask = 0x10;
                    case 250
                        ByteMask = 0x14;
                    case 500
                        ByteMask = 0x18;
                    case 1000
                        ByteMask = 0x1C;
                    otherwise
                        % corresponding to samplerate/2 = 50.Default
                        % sample rate is 100
                        ByteMask = 0x08;
                end
                val = readRegister(obj.Device,obj.ACC_Config_Register);
                val = bitand(uint8(val),uint8(AndMaskAccel));
                writeRegister(obj.Device,obj.ACC_Config_Register,bitor(uint8(val),uint8(ByteMask)));
                
                AndMaskGyro = 0xC7;
                switch obj.GyroscopeBandwidth
                    case 523
                        ByteMask = 0x00;
                    case 230
                        ByteMask = 0x08;
                    case 116
                        ByteMask = 0x10;
                    case 47
                        ByteMask = 0x18;
                    case 23
                        ByteMask = 0x20;
                    case 12
                        ByteMask = 0x28;
                    case 64
                        ByteMask = 0x30;
                    case 32
                        ByteMask = 0x38;
                    otherwise
                        % corresponding to samplerate/2 = 50.Default
                        % sample rate is 100
                        ByteMask = 0x18;
                end
                val = readRegister(obj.Device,obj.GYRO_Config_0Register);
                val = bitand(uint8(val),uint8(AndMaskGyro));
                writeRegister(obj.Device,obj.GYRO_Config_0Register,bitor(uint8(val),uint8(ByteMask)));
                
                magODR = obj.MagParameters.SupportedODR(obj.SampleRate >= obj.MagParameters.SupportedODR);
                obj.MagnetometerODR = max(magODR);
                AndMaskMag = 0xF8;
                switch obj.MagnetometerODR
                    case 2
                        ByteMask = 0x00;
                    case 6
                        ByteMask = 0x01;
                    case 8
                        ByteMask = 0x02;
                    case 10
                        ByteMask = 0x03;
                    case 15
                        ByteMask = 0x04;
                    case 20
                        ByteMask = 0x05;
                    case 25
                        ByteMask = 0x06;
                    case 30
                        ByteMask = 0x07;
                    otherwise
                        %corresponding to Default sanmplerate
                        ByteMask = 0x07;
                end
                val = readRegister(obj.Device,obj.MAG_Config_Register);
                val = bitand(uint8(val),uint8(AndMaskMag));
                writeRegister(obj.Device,obj.MAG_Config_Register,bitor(uint8(val),uint8(ByteMask)));
            end
            changeMode(obj,obj.OperatingModeEnum);
            writeRegister(obj.Device, obj.PAGE_ID_Register, 0);
        end
        
        function names = getMeasurementDataNames(obj)
            if obj.OperatingModeEnum == matlabshared.sensors.internal.BNO055OperatingMode.amg
                names = [obj.AccelerometerDataName, obj.GyroscopeDataName, obj.MagnetometerDataName];
            else
                names = [obj.AccelerometerDataName, obj.GyroscopeDataName, obj.MagnetometerDataName,obj.OrientationDataName];
            end
        end
    end
    
    methods(Access = private)
        function setAccelRangeAndNormalPowerMode(obj, range)
            changeMode(obj,obj.ConfigMode);
            % Use AndMask to guard the unused bits for this setting and to
            % reset the bits for the setting to 0. This will ensure using bitOr
            % to write byte will give correct setting
            AndMask = 0x1C;
            switch range
                case '2g'
                    ByteMask = 0x00;
                case '4g'
                    ByteMask = 0x01;
                case '8g'
                    ByteMask = 0x02;
                case '16g'
                    ByteMask = 0x03;
                otherwise
                    ByteMask = 0x00;
            end
            % take page 1
            writeRegister(obj.Device, obj.PAGE_ID_Register, uint8(1));
            val = readRegister(obj.Device,obj.ACC_Config_Register);
            val = bitand(uint8(val),uint8(AndMask));
            writeRegister(obj.Device,obj.ACC_Config_Register,bitor(uint8(val),uint8(ByteMask)));
            writeRegister(obj.Device, obj.PAGE_ID_Register, uint8(0));
            changeMode(obj,obj.OperatingModeEnum);
        end
        
        function setGyroRangeAndNormalPowerMode(obj, range)
            % auto controlled in fusion mode
            if obj.OperatingModeEnum == matlabshared.sensors.internal.BNO055OperatingMode.amg
             changeMode(obj,obj.ConfigMode);
            % Use AndMask to guard the unused bits for this setting and to
            % reset the bits for the setting to 0. This will ensure using bitOr
            % to write byte will give correct setting
                AndMask = 0xF8;
                switch range
                    case '2000dps'
                        ByteMask = 0x00;
                    case '1000dps'
                        ByteMask = 0x01;
                    case '500dps'
                        ByteMask = 0x02;
                    case '250dps'
                        ByteMask = 0x03;
                    case '125dps'
                        ByteMask = 0x04;
                    otherwise
                        ByteMask = 0x00;
                end
                % take page 1
                writeRegister(obj.Device, obj.PAGE_ID_Register, uint8(1));
                val = readRegister(obj.Device,obj. GYRO_Config_0Register);
                val = bitand(uint8(val),uint8(AndMask));
                writeRegister(obj.Device,obj.GYRO_Config_0Register,bitor(uint8(val),uint8(ByteMask)));
                % Set the gyro mode as normal
                val = readRegister(obj.Device,obj.GYRO_Config_1Register);
                mask = 0xF8;
                writeRegister(obj.Device,obj.GYRO_Config_1Register,bitand(val,mask));
                writeRegister(obj.Device, obj.PAGE_ID_Register, uint8(0));
                changeMode(obj,obj.OperatingModeEnum);
            end
        end
       
         function setMagPowerMode(obj)
            % Use AndMask to guard the unused bits for this setting and to
            % reset the bits for the setting to 0. This will ensure using bitOr
            % to write byte will give correct setting
            changeMode(obj,obj.ConfigMode);
            AndMask = 0x87; % Normal PowerMode
            % take page 1
            writeRegister(obj.Device, obj.PAGE_ID_Register, uint8(1));
            val = readRegister(obj.Device,obj.MAG_Config_Register);
            val = bitand(uint8(val),uint8(AndMask));
            writeRegister(obj.Device,obj.MAG_Config_Register,val);
            writeRegister(obj.Device, obj.PAGE_ID_Register, uint8(0));
            changeMode(obj,obj.OperatingModeEnum);
          end
        
        function setMeasurementUnit(obj)
            changeMode(obj,obj.ConfigMode);
            writeRegister(obj.Device, obj.PAGE_ID_Register, uint8(0));
            val = readRegister(obj.Device,obj.UNIT_SEL_Register);
            writeRegister(obj.Device,obj.UNIT_SEL_Register,bitand(uint8(val),0xF8));
            changeMode(obj,obj.OperatingModeEnum);
        end
        
        function setMeasurementResolution(obj)
            setAccelResolution(obj);
            setGyroResolution(obj);
            % Mag units of resolution can not be changed
             if obj.OperatingModeEnum == matlabshared.sensors.internal.BNO055OperatingMode.ndof
               setEulerResolution(obj); 
             end
        end
        
       function setAccelResolution(obj)
            switch obj.AccelUnit
                case 'm/s^2'
                    obj.AccelerometerResolution = 1/100;
                case 'mg'
                    obj.AccelerometerResolution = (1/100)*10000;
                otherwise
                    obj.AccelerometerResolution = 1/100;
            end
        end
        
        function setGyroResolution(obj)
            switch obj.GyroUnit
                case 'Dps'
                    obj.GyroscopeResolution = 1/16;
                case 'Rps'
                    obj.GyroscopeResolution = (1/16)*(pi/180);
                otherwise
                    obj.GyroscopeResolution = 1/900;
            end
        end
        
          function setEulerResolution(obj)
            switch obj.EulerUnit
                case 'degrees'
                    obj.EulerAngleResolution = 1/16;
                case 'radians'
                    obj.EulerAngleResolution = (1/16)*(pi/180);
                otherwise
                    obj.EulerAngleResolution = 1/900;
            end
          end
          
        function data = convertAccelData(obj, accel_data)
            accel_x = double(bitor(int16(accel_data(:, 1)), bitshift(int16(accel_data(:, 2)),8)));
            accel_y = double(bitor(int16(accel_data(:, 3)), bitshift(int16(accel_data(:, 4)),8)));
            accel_z = double(bitor(int16(accel_data(:, 5)), bitshift(int16(accel_data(:, 6)),8)));
            data = obj.AccelerometerResolution.*[accel_x, accel_y, accel_z];
        end
        
        function data = convertGyroData(obj, gyroData)
            gyro_x = double(bitor(int16(gyroData(:, 1)), bitshift(int16(gyroData(:, 2)),8)));
            gyro_y = double(bitor(int16(gyroData(:, 3)), bitshift(int16(gyroData(:, 4)),8)));
            gyro_z = double(bitor(int16(gyroData(:, 5)), bitshift(int16(gyroData(:, 6)),8)));
            data = obj.GyroscopeResolution.*[gyro_x, gyro_y, gyro_z];
        end
        
        function data = convertMagData(obj,data)
            mag_x = double(bitor(int16(data(:, 1)), bitshift(int16(data(:, 2)),8)));
            mag_y = double(bitor(int16(data(:, 3)), bitshift(int16(data(:, 4)),8)));
            mag_z = double(bitor(int16(data(:, 5)), bitshift(int16(data(:, 6)),8)));
            data = obj.MagnetometerResolution.*[mag_x,mag_y,mag_z];
        end
        
        function data = convertEulData(obj,data)
            heading = double(bitor(int16(data(:, 1)), bitshift(int16(data(:, 2)),8)));
            roll = double(bitor(int16(data(:, 3)), bitshift(int16(data(:, 4)),8)));
            pitch = double(bitor(int16(data(:, 5)), bitshift(int16(data(:, 6)),8)));
            data = obj.EulerAngleResolution.*[heading,pitch,roll];
        end
        
        function changeMode(obj,mode)
            % change the operating mode
            % take page 0
            writeRegister(obj.Device, obj.PAGE_ID_Register, uint8(0));
            val = readRegister(obj.Device, obj.OPR_MODE_Register);
            % Use AndMask to guard the unused bits for this setting and to
            % reset the bits for the setting to 0. This will ensure using bitOr
            % to write byte will give correct setting
            AndMask = 0xF0;
            switch mode
                case matlabshared.sensors.internal.BNO055OperatingMode.amg
                    ByteMask = 0x07;
                case matlabshared.sensors.internal.BNO055OperatingMode.ndof
                    ByteMask = 0x0C;
                case obj.ConfigMode
                    ByteMask = 0x00;
                otherwise
                    ByteMask = 0x07;
            end
            val = bitand(uint8(val),uint8(AndMask));
            writeRegister(obj.Device,obj.OPR_MODE_Register,bitor(uint8(val),uint8(ByteMask)));
        end
    end
end