classdef (Sealed) ak8963 < matlabshared.sensors.magnetometer & matlabshared.sensors.sensorUnit & ...
        matlabshared.sensors.I2CSensorProperties
    
    %   Copyright 2017-2021 The MathWorks, Inc.
    
    %#codegen
    
    properties(SetAccess = protected, GetAccess = public, Hidden)
        MinSampleRate = 11;
        MaxSampleRate = 200;
    end
    
    properties(Nontunable, Hidden)
        DoF = 3;
    end
    
    properties(Access = protected, Constant)
        MagnetometerRange = '4900 uT';
        MagnetometerDataRegister = 0x03;
    end

    properties(Access = protected, Constant)
        SupportedInterfaces = 'I2C';
    end
    
    properties(Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Constant)
        I2CAddressList = 0x0C;
    end
    
    properties(Access = protected)
        MagnetometerResolution = 0.6;
        MagnetometerODR;
    end
    
    properties(Access = private)
        SensitivityAdjustment
    end
    
    properties(Access = private, Hidden, Constant)
        SupportedODR = [8, 100];
        CNTL1 = 0x0A;
        ASAX = 0x10; % Read sensitivity adjustment values from here
        BytesToRead = 6;
    end
    
    methods
        function obj = ak8963(varargin)
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
        function initDeviceImpl(~)
        end
        
        function initSensorImpl(obj)
            initMagnetometerImpl(obj);
        end
        
        function initMagnetometerImpl(obj)
            writeRegister(obj.Device, obj.CNTL1, uint8(0));
            writeRegister(obj.Device, obj.CNTL1, uint8(15));
            obj.SensitivityAdjustment = double(readRegister(obj.Device , obj.ASAX, 3, "uint8"));
        end
        
        function [data,status,timestamp] = readMagneticFieldImpl(obj)
            numBytes = obj.BytesToRead+1;
            [tempData,status,timestamp] = obj.Device.readRegisterData(obj.MagnetometerDataRegister, numBytes, "uint8");  % 7th byte indicates data is read
            coder.extrinsic('error', 'message');
            if(isequal(tempData,0))
                error(message('matlab_sensors:general:sensorNotResponding'));
            end
            if(isequal(size(tempData,2),1))
                data = tempData';
                if(isequal(numel(data),obj.SamplesPerRead*numBytes))
                    data = reshape(data,[numBytes,obj.SamplesPerRead])';
                end
            else
                data = tempData;
            end
            data = data(:,1:obj.BytesToRead);
            data = convertMagnetometerData(obj, data);
        end
        function setODRImpl(obj)
            % AK8963 has two supported ODR rates - 8 Hz and 100 Hz. We are
            % always choosing 100 Hz irrespective of the sample rate
            obj.MagnetometerODR = 100;
            writeRegister(obj.Device, obj.CNTL1, uint8(0));
            writeRegister(obj.Device, obj.CNTL1, uint8(6));
        end
        
        function [data,status,timestamp] = readSensorDataImpl(obj)
            [data,status,timestamp] = readMagneticFieldImpl(obj);
        end
        
        function data = convertSensorDataImpl(obj, data)
            data = convertMagnetometerData(obj, data(1:obj.BytesToRead));
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
        function data = convertMagnetometerData(obj, magSensorData)
            xm = double(bitor(int16(magSensorData(:, 1)), bitshift(int16(magSensorData(:, 2)),8)));
            ym = double(bitor(int16(magSensorData(:, 3)), bitshift(int16(magSensorData(:, 4)),8)));
            zm = double(bitor(int16(magSensorData(:, 5)), bitshift(int16(magSensorData(:, 6)),8)));
            xm = xm*((obj.SensitivityAdjustment(1) - 128)*0.5/128 + 1);
            ym = ym*((obj.SensitivityAdjustment(2) - 128)*0.5/128 + 1);
            zm = zm*((obj.SensitivityAdjustment(3) - 128)*0.5/128 + 1);
            data = [xm, ym, zm]*obj.MagnetometerResolution;
        end
    end
end

% LocalWords:  ODR
