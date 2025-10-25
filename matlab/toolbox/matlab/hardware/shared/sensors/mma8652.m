classdef mma8652 < matlabshared.sensors.accelerometer & matlabshared.sensors.sensorUnit & matlabshared.sensors.I2CSensorProperties
    % Accelerometer sensor class
    % Usage:
    % a = arduino;
    % accel = mma8652(a);
    % readAcceleration(accel);
    %
    % m = microbit;
    % readAcceleration(m);
    
    % Copyright 2017-2020 The MathWorks, Inc.
    
    properties(Hidden, Constant)
        AccelerometerCTRL_REG1 = '2A'
        AccelerometerCTRL_REG2 = '2B'
    end
    
    properties(SetAccess = protected, GetAccess = public, Hidden)
        % irrelevant here. Useful only for streaming
        MinSampleRate = 10;
        MaxSampleRate = 200;
    end
    
    properties(Nontunable, Hidden)
        DoF = 3;
    end
    
    properties(Access = protected)
        AccelerometerODR
        AccelerometerResolution = 1/1024;
    end
    
    properties(Access = protected, Constant)
        AccelerometerRange = '2g';
        AccelerometerDataRegister = '01';
    end

    properties(Access = protected, Constant)
        SupportedInterfaces = 'I2C';
    end
    
    properties(Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Constant)
        I2CAddressList = 0x1D;
    end
    
    methods(Hidden, Access = public)
        function obj = mma8652(varargin)
            obj.init(varargin{:});
        end
    end
    
    methods(Access = protected)
        %% matlabshared.sensors.accelerometer
        function initDeviceImpl(~)
            %TODO
        end
        
        function initSensorImpl(obj)
            initAccelerometerImpl(obj);
        end
        
        function s = infoImpl(~)
            % Creating the structure so that it doesn't affect the caller
            s = struct;
        end
        
        function initAccelerometerImpl(obj)
            % Software Reset
            writeRegister(obj.Device, hex2dec(obj.AccelerometerCTRL_REG2), uint8(hex2dec('40')));
        end
        
        function [data,status,timestamp] = readSensorDataImpl(obj)
           [data,status,timestamp] = readAccelerationImpl(obj);
        end
        
        function data = convertSensorDataImpl(~, ~)
            % this function is used in 'showLatestValues' during streaming
            % in 'oldest' read mode. Keeping this empty until streaming is
            % enabled in this sensor.
            data = [];
        end
        
        function setODRImpl(obj)
            % Not streaming currently.
            % Use the sample rate of the sensor to calculate ODR. For now
            % ODR is set to 800 (fixed).
            % Any change in the sample rate will result into the setODRImpl
            % function call.
            % ODR 800 Hz, Active
            obj.AccelerometerODR = 800;
            writeRegister(obj.Device, hex2dec(obj.AccelerometerCTRL_REG1), 1);
        end
        
        function [data, status,timestamp] = readAccelerationImpl(obj)
            % |LSBZ|MSBZ|,|LSBY|MSBY|,|LSBX|MSBX|
            [accel,status,timestamp]  = obj.Device.readRegisterData(hex2dec(obj.AccelerometerDataRegister), 3, "int16");
            accel = int16(accel);
            % |MSBZ|LSBZ|,|MSBY|LSBY|,|MSBX|LSBX|
            accel = swapbytes(accel(1:3));
            % 12-bit Left alligned -> 12-bit right alligned.
            accel = bitshift(accel(1:3),-4);
            % Sensitivity 1024 LSB/g for 12-bit
            accel = double(accel) * obj.AccelerometerResolution;
            % SI Units - g -> ms^-2
            data = accel * 9.80665;
        end
        
        function names = getMeasurementDataNames(obj)
            names = obj.AccelerometerDataName;
        end
        
    end
end

% LocalWords:  matlabshared