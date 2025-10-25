classdef (Sealed) lsm9ds1_mag < matlabshared.sensors.magnetometer & matlabshared.sensors.sensorUnit &...
        matlabshared.sensors.I2CSensorProperties
    
    %   Copyright 2017-2020 The MathWorks, Inc.
    
    %#codegen
    
    properties(SetAccess = protected, GetAccess = public, Hidden)
        MinSampleRate = 28;
        MaxSampleRate = 200;
    end
    
    properties(Nontunable, Hidden)
        DoF = 3;
    end
    
    properties(Access = protected, Constant)
        MagnetometerRange = '4 gauss';
        MagnetometerDataRegister = 0x28;
    end

    properties(Access = protected, Constant)
        SupportedInterfaces = 'I2C';
    end
    
    properties(Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Constant)
        I2CAddressList = [0x1E, 0x1C];
    end
    
    properties(Access = protected)
        MagnetometerResolution;
        MagnetometerODR;
    end
    
    properties(Access = protected, Constant)
        WHO_AM_I = 0x0F;
        DeviceID = 0x3D;
        CTRL_REG1 = 0x20;
        CTRL_REG2 = 0x21;
        CTRL_REG3 = 0x22; % for operating mode selection and I2C/SPI mode selection
        ODRParameters = struct('SupportedODR',[0.625,1.25,2.5,5,10,20,40,80,155,300,560,1000]);
        BytesToRead = 6;
    end
    
    methods
        
        function obj = lsm9ds1_mag(varargin)
            % Code generation does not support try-catch block. So init
            % function call is made separately in both codegen and IO
            % context.
            if ~coder.target('MATLAB')
                obj.init(varargin{:});
            else
                try
                    obj.init(varargin{:});
                catch ME
                    throwAsCaller(ME)
                end
            end
        end
    end
    methods(Access = protected)
        function initDeviceImpl(obj)
            if coder.target('MATLAB')
                deviceid_value = readRegister(obj.Device, obj.WHO_AM_I,1,'uint8');
                if(deviceid_value ~= obj.DeviceID)
                    matlabshared.sensors.internal.localizedWarning('matlab_sensors:general:invalidDeviceID','LSM9DS1 magnetometer',num2str(obj.DeviceID));
                end
            end
        end
        
        function initSensorImpl(obj)
            initMagnetometerImpl(obj);
        end
        
        function initMagnetometerImpl(obj)
            writeRegister(obj.Device, obj.CTRL_REG3, uint8(0)); % continuous conversion mode
            writeRegister(obj.Device, obj.CTRL_REG1, uint8(0)); % Resetting this register to set the default DO[2:0] bits to 0
            setMagRangeByte(obj);
            getMsPerLSB(obj);
        end
        
        function setODRImpl(obj)
            validMagODRList = obj.ODRParameters.SupportedODR(obj.SampleRate >= obj.ODRParameters.SupportedODR);
            magODR = max(validMagODRList);
            switch magODR
                case 0.625
                    ByteMask = 0x00;
                case 1.25
                    ByteMask = 0x04;
                case 2.5
                    ByteMask = 0x08;
                case 5
                    ByteMask = 0x0C;
                case 10
                    ByteMask = 0x10;
                case 20
                    ByteMask = 0x14;
                case 40
                    ByteMask = 0x18;
                case 80
                    ByteMask = 0x1C;
                case 155
                    ByteMask = 0x62; % UHP mode
                case 300
                    ByteMask = 0x42; % HP mode
                case 560
                    ByteMask = 0x22; % MP mode
                case 1000
                    ByteMask = 0x02; % LP mode
            end
            val = readRegister(obj.Device, obj.CTRL_REG1);
            writeRegister(obj.Device, obj.CTRL_REG1,bitor(uint8(val),ByteMask));
            obj.MagnetometerODR = magODR;
        end
        
        function [magData,status,timestamp] = readMagneticFieldImpl(obj)
            [tempData,status,timestamp] = obj.Device.readRegisterData(obj.MagnetometerDataRegister, obj.BytesToRead, "uint8");
            if(isequal(size(tempData,2),1))
                magData = tempData';
                if(isequal(numel(magData),obj.SamplesPerRead*obj.BytesToRead))
                    magData = reshape(magData,[obj.BytesToRead,obj.SamplesPerRead])';
                end
            else
                magData = tempData;
            end
            magData = convertMagData(obj,magData);
        end
        
        function [data,status,timestamp] = readSensorDataImpl(obj)
            [data,status,timestamp] = readMagneticFieldImpl(obj);
        end
        
        function data = convertSensorDataImpl(obj, data)
            data = convertMagData(obj, data(1:obj.BytesToRead));
        end
        
        function s = infoImpl(obj)
            if coder.target('MATLAB')
                s = struct('MagnetometerODR', obj.MagnetometerODR);
            else
                coder.internal.errorIf(true, 'matlab_sensors:general:unsupportedFunctionSensorCodegen', 'info');
            end
        end
        
        function names = getMeasurementDataNames(obj)
            names = obj.MagnetometerDataName;
        end
    end
    
    methods(Access = private)
        
        function setMagRangeByte(obj)
            switch obj.MagnetometerRange
                case '4 gauss'
                    ByteMask = 0x00;
                case '8 gauss'
                    ByteMask = 0x20;
                case '12 gauss'
                    ByteMask = 0x40;
                case '16 gauss'
                    ByteMask = 0x60;
            end
            val = readRegister(obj.Device,obj.CTRL_REG2);
            writeRegister(obj.Device,obj.CTRL_REG2,bitor(uint8(val),ByteMask));
        end
        
        function getMsPerLSB(obj)
            switch obj.MagnetometerRange
                case '4 gauss'
                    obj.MagnetometerResolution = 0.14*(10^-3);
                case '8 gauss'
                    obj.MagnetometerResolution = 0.29*(10^-3);
                case '12 gauss'
                    obj.MagnetometerResolution = 0.43*(10^-3);
                case '16 gauss'
                    obj.MagnetometerResolution = 0.58*(10^-3);
            end
        end
        
        function data = convertMagData(obj,data)
            mag_x = double(bitor(int16(data(:, 1)), bitshift(int16(data(:, 2)),8)));
            mag_y = double(bitor(int16(data(:, 3)), bitshift(int16(data(:, 4)),8)));
            mag_z = double(bitor(int16(data(:, 5)), bitshift(int16(data(:, 6)),8)));
            data = [mag_x,mag_y,mag_z].*obj.MagnetometerResolution;
            data = data.*100; % conversion from gauss to microTesla (1 gauss = 100 microTesla)
        end
        
    end
end