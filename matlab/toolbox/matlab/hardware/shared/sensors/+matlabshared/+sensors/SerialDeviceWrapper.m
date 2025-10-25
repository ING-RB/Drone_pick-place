classdef (Hidden) SerialDeviceWrapper < matlabshared.sensors.internal.Accessor
    
    % This class provides a wrapper to adapt serial device objects for
    % non-hwsdk based targets in sensors. This class should be inherited to
    % create an i2c device class, which should internally hold the serial
    % device object for that particular hardware.
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties(GetAccess = public, SetAccess = protected)
        Interface = matlabshared.sensors.internal.SensorInterfaceEnum.Serial
    end
    
    properties(Abstract, GetAccess = public, SetAccess = protected)
        % Set of properties to be defined by the subclass. GPS objects
        % access these properties directly.
        SerialPort
        BaudRate
        Timeout
        TxPin char
        RxPin char
        
    end
    properties(GetAccess = public, SetAccess = protected)
        % GPS object accesses this property
        NumBytesAvailable
    end
    
    properties(Abstract, Access = ?matlabshared.sensors.internal.Accessor)
        % It holds the IO Client object that is used by Serial Device class.
        SerialDriverObj
    end
    
    methods
        function val = get.NumBytesAvailable(obj)
            val = getNumBytesAvailableImpl(obj);
        end
    end
    
    methods(Abstract, Access = protected)
        % Implement these methods in the subclass
        writeImpl(obj, data, precision);
        data = readImpl(obj, count, precision);
        val = getNumBytesAvailableImpl(obj);
    end
    
    methods
        function write(obj, data, precision)
            % Sensor object calls this method directly.
            if (nargin < 2)
                error(message('MATLAB:minrhs'));
            end
            if nargin == 2
                precision = "uint8";
            end
            writeImpl(obj, data, precision);
        end
        
        function data = read(obj, count, precision)
            % Sensor object calls this method directly.
            if nargin < 3
                precision = "uint8";
            end
            data = readImpl(obj, count, precision);
            if ~isrow(data)
                data = data';
            end
        end
    end
end