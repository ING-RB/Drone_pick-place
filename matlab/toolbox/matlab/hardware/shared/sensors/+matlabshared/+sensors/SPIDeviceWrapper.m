classdef (Hidden) SPIDeviceWrapper < matlabshared.sensors.internal.Accessor

    % This class provides a wrapper to adapt spi device objects for
    % non-hwsdk based targets in sensors. This class should be inherited to
    % create an spi device class, which should internally hold the spi
    % device object for that particular hardware.

    %  Copyright 2023-2024 The MathWorks, Inc.

    properties(GetAccess = public, SetAccess = protected)
        Interface = matlabshared.sensors.internal.SensorInterfaceEnum.SPI
    end

    properties(Abstract, GetAccess = public, SetAccess = protected)
        % Set of properties to be defined by the sub class. Sensor objects
        % access these properties directly.
        Bus
        bitRate
    end

    properties(GetAccess = public, SetAccess = protected)
        % If the target have an SPIDev class, and only signatures of the
        % class needs to be modified, they can use this object in the
        % inherited class to access SPIDev features.
        SPIDevObj;
    end

    methods
        function writeRegister(obj, registerAddress, data, precision)
            % Sensor object calls this method directly.
            if (nargin < 3)
                error(message('MATLAB:minrhs'));
            end
            if nargin == 3
                precision = "uint8";
            end
            writeRegisterImpl(obj, registerAddress, data, precision);
        end

        function write(obj, data, precision)
            % Sensor object calls this method directly.
            if (nargin < 2)
                error(message('MATLAB:minrhs'));
            end
            if nargin == 2
                precision = "uint8";
            end
            if isstring(data) || ischar(data)
                data = uint8(char(data));
            end
            writeImpl(obj, data, precision);
        end

        function [data,status,timestamp] = readRegister(obj, registerAddress, varargin)
            % Sensor object calls this method directly.
            narginchk(2, 4);
            if nargin < 3
                count = 2;
                precision = "uint8";
            end
            if nargin == 3
                if ischar(varargin{1}) || isstring(varargin{1})
                    precision = varargin{1};
                    count = 1;
                elseif isnumeric(varargin{1})
                    count = varargin{1};
                    precision = "uint8";
                else
                    error(message('MATLAB:maxrhs'));
                end
            end
            if nargin == 4
                count = varargin{1};
                precision = varargin{2};
            end
            [data,status,timestamp] = readRegisterImpl(obj, registerAddress, count, precision);
            if ~isrow(data)
                data = data';
            end
        end
    end
end