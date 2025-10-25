classdef mag3110 < matlabshared.sensors.magnetometer & matlabshared.sensors.sensorUnit & matlabshared.sensors.I2CSensorProperties
    % Magnetometer sensor class
    % Usage:
    % a = arduino;
    % mField = mag3110(a);
    % readMagneticField(mField);
    %
    % m = microbit;
    % readMagneticField(m);
    
    % Copyright 2017-2020 The MathWorks, Inc.
    
    properties(Hidden, Constant)
        MagnetometerCTRL_REG1 = '10'
        MagnetometerCTRL_REG2 = '11'
    end
    
    properties(Access = protected)
        MagnetometerODR
        MagnetometerResolution = 0.1;
    end
    
    properties(Access = protected, Constant)
        MagnetometerDataRegister = '01'
        MagnetometerRange = '1000uT' % default value
    end

    properties(Access = protected, Constant)
        SupportedInterfaces = 'I2C';
    end
    
    properties(Access = {?matlabshared.sensors.coder.matlab.sensorInterface, ?matlabshared.sensors.sensorInterface}, Constant)
        I2CAddressList = 0x0E;
    end
    
    properties(SetAccess = protected, GetAccess = public, Hidden)
        % irrelevant here. Useful only for streaming
        MinSampleRate = 10;
        MaxSampleRate = 200;
    end
    
    properties(Nontunable, Hidden)
        DoF = 3;
    end
    
    methods(Hidden, Access = public)
        function obj = mag3110(varargin)
            obj.init(varargin{:});
        end
    end
    
    methods(Access = protected)
        %% matlabshared.sensors.magnetometer
        function initDeviceImpl(~)
            %TODO
        end
        
        function initSensorImpl(obj)
            initMagnetometerImpl(obj)
        end
        
        function s = infoImpl(~)
            % Creating the structure so that it doesn't affect the caller
            s = struct;
        end
        
        function initMagnetometerImpl(obj)
            % Mag_RST = 1 -> Initiate sensor reset cycle
            writeRegister(obj.Device, hex2dec(obj.MagnetometerCTRL_REG2), hex2dec('10'));
            % Wait until sensor reset cycle completes
            magRST = 1;
            while magRST == 1
                magRST = uint8(readRegister(obj.Device, hex2dec(obj.MagnetometerCTRL_REG2)));
                magRST = bitand(magRST, 16, 'uint8');
            end
            % RAW=1; User needs to employ Zero flux offset and Hard
            % iron corrections
            writeRegister(obj.Device, hex2dec(obj.MagnetometerCTRL_REG2), hex2dec('20'));
            % Standby
            ctrlReg1 = readRegister(obj.Device, hex2dec(obj.MagnetometerCTRL_REG1), 'uint8');
            writeRegister(obj.Device, hex2dec(obj.MagnetometerCTRL_REG1), bitand(ctrlReg1, bitcmp(1,'uint8'), 'uint8'));
        end
        
        function setODRImpl(obj)
            % Not streaming currently.
            % Use the sample rate of the sensor to calculate ODR. For now
            % ODR is set to 80 (fixed).
            % Any change in the sample rate will result into the setODRImpl
            % function call.
            % ODR 80 Hz, Active
            obj.MagnetometerODR = 80;
            writeRegister(obj.Device, hex2dec(obj.MagnetometerCTRL_REG1), 1);
        end
        
        function [data,status,timestamp] = readMagneticFieldImpl(obj)
            % |xx|xx|LSBZ|MSBZ|LSBY|MSBY|LSBX|MSBX|
            [mag,status,timestamp]  = obj.Device.readRegisterData(hex2dec(obj.MagnetometerDataRegister), 1, "uint64");
            % |xxxx|,|LSBZ|MSBZ|,|LSBY|MSBY|,|LSBX|MSBX|
            mag = typecast(mag, 'uint16');
            % |MSBZ|LSBZ|,|MSBY|LSBY|,|MSBX|LSBX|
            mag = swapbytes(mag(1:3));
            % Find out negative Magnetic Fields
            negativeMags = mag > intmax('int16');
            % 1s complement negative Magnetic Fields
            mag(negativeMags) = bitcmp(mag(negativeMags));
            % 2s complement negative Magnetic Fields
            mag(negativeMags) = mag(negativeMags) + 1;
            % convert them to negative
            mag = double(mag);
            mag(negativeMags) = int16(mag(negativeMags)) * -1;
            % Sensitivity -> 0.1uT/bit
            data = double(mag) * obj.MagnetometerResolution;
        end
        
        function [data,status,timestamp] = readSensorDataImpl(obj)
            [data,status,timestamp] = readMagneticFieldImpl(obj);
        end
        
        function data = convertSensorDataImpl(~, ~)
            % this function is used in 'showLatestValues' during streaming
            % in 'oldest' read mode. Keeping this empty until streaming is
            % enabled in this sensor.
            data = [];
        end
        
        function names = getMeasurementDataNames(obj)
            names = obj.MagnetometerDataName;
        end
        
    end
end

% LocalWords:  matlabshared