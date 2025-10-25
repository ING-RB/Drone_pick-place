classdef (Hidden) I2CDeviceWrapper < matlab.System & matlabshared.sensors.internal.Accessor

    % This class provides a wrapper to adapt i2c device objects for
    % non-hwsdk based targets in sensors. This class should be inherited to
    % create an i2c device class, which should internally hold the i2c
    % device object for that particular hardware.

    %  Copyright 2020-2024 The MathWorks, Inc.
    %#codegen
    properties(GetAccess = public, SetAccess = protected)
        Interface = matlabshared.sensors.internal.SensorInterfaceEnum.I2C
    end

    properties(Abstract, GetAccess = public, SetAccess = protected)
        % Set of properties to be defined by the sub class. Sensor objects
        % access these properties directly.
        I2CAddress
        Bus
        BitRate
    end

    properties(Access = protected)
        Parent
    end

    properties(Access = private)
        InterfaceObj  % I2C or SPI driver object
    end

    properties(Abstract, Access = ?matlabshared.sensors.internal.Accessor)
        % It holds the IO Client object that is used by I2C Device class.
        I2CDriverObj
    end

    properties(GetAccess = public, SetAccess = protected)
        % If the target have an I2CDev class, and only signatures of the
        % class needs to be modified, they can use this object in the
        % inherited class to access I2CDev features.
        I2CDevObj;
    end

    methods(Abstract,Access=protected)
        % Implement these methods in the subclass
        writeRegisterImpl(obj, registerAddress, data, precision);
        data = readRegisterImpl(obj, registerAddress, count, precision);
        writeImpl(obj, data, precision);
    end
    methods(Access = protected)
        function initFunction(obj, parent, varargin)
            if coder.target('Rtw')
                narginchk(3, inf);
                i2cAddress = varargin{1};
                bus = varargin{2};
            else
                narginchk(1, inf);
                names = {'Bus', 'I2CAddress'};
                defaults = {[], []};
                p = matlabshared.sensors.internal.NameValueParserInternal(names, defaults);
                % p.parse(varargin{:});
                i2cAddress = varargin{2};
                bus = varargin{4};
            end
            obj.Parent = parent;
            obj.I2CAddress = i2cAddress;
            obj.Bus = bus;
            obj.BitRate = obj.Parent.BitRate;
        end
    end
    methods
       
        function I2CAddressesFound = scanI2CBusSensor(obj,I2CAddresslist)
            % Scan the I2C bus for devices
            % Returns list of found I2C addresses
            I2CAddressesFound = [];
            for idx = 1:numel(I2CAddresslist)
                % writing the address values to the bus and seeing if there is correct response
                % data = 0
                addr = I2CAddresslist(idx);
                status=  obj.write(addr,0,'uint8');
                if  status == 0
                    I2CAddressesFound = [I2CAddressesFound, I2CAddresslist(idx)];
                end
            end
        end
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

        function varargout = write(obj,varargin)
            % Sensor object calls this method directly.
            if (nargin < 2)
                error(message('MATLAB:minrhs'));
            end
            if nargin == 2
                register = varargin{1};
                data = [];
                precision = "uint8";
            elseif nargin == 3
                register = varargin{1};
                data = varargin{2};
                precision = "uint8";
            elseif nargin == 4
                register = varargin{1};
                data = varargin{2};
                precision = varargin{3};
            end
            if isstring(data) || ischar(data)
                data = uint8(char(data));
            end
            if nargout > 0
                [varargout{1:nargout}] = writeImpl(obj, register, data, precision);
            else
                writeImpl(obj, register, data, precision);
            end
        end
        function [data,status,timestamp]=registerI2CRead(varargin)
            obj = varargin{1};
            registerAddress = varargin{5};
            numBytes = varargin{6};
            [data, status,timestamp]=readRegisterImpl(obj,registerAddress,numBytes);
        end

        function data = readRegister(obj, registerAddress, varargin)
            % Sensor object calls this method directly.
            narginchk(2, 4);
            if nargin < 3
                count = 1;
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
            data = readRegisterImpl(obj, registerAddress, count, precision);
            if ~coder.target('Rtw')
                % Only reshape data if not in code generation
                if ~isrow(data)
                    data = data';
                end
            end
        end
    end
end
