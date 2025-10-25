classdef I2CDevice < matlabshared.sensors.I2CDeviceWrapper
    %I2CDevice class is used create a lightweight device object to use in
    %Simulink IO

    %  Copyright 2020-2024 The MathWorks, Inc.

    %#codegen
    properties(GetAccess = public, SetAccess = protected)
        % Set of properties to be defined by the sub class. Sensor objects
        % access these properties directly.
        I2CAddress
        Bus
        BitRate
        SCLPin string
        SDAPin string
    end

    properties(Access = ?matlabshared.sensors.internal.Accessor)
        % It holds the IO Client object that is used by I2C Device classs.
        I2CDriverObj
    end


    methods (Access = private, Static = true)
        function name = matlabCodegenRedirect(~)
            name = 'matlabshared.sensors.coder.matlab.device';
        end
    end

    methods
        function obj = I2CDevice(parent, varargin)
            obj.initFunction(parent, varargin{:});
            obj.I2CDriverObj = getI2CDriverObj(obj.Parent);
            startI2C(obj);
        end

        function delete(obj)
            % Check if the objects are not deleted or is made empty in any earlier stages
            if isvalid(obj.I2CDriverObj) && isvalid(obj.Parent)
                if ~isempty(obj.I2CDriverObj) && ~isempty(obj.Parent.ProtocolObj)
                    closeI2CBus(obj.I2CDriverObj, obj.Parent.ProtocolObj, obj.Bus);
                end
            end
        end
    end

    methods(Access = protected)
        function writeRegisterImpl(obj, registerAddress, data,varargin)
            if ~isrow(data)
                data = data';
            end
            registerI2CWrite(obj.I2CDriverObj, obj.Parent.ProtocolObj, obj.Bus, obj.I2CAddress, registerAddress, uint8(data));
        end

        function writeImpl(obj, data,varargin)
            if ~isrow(data)
                data = data';
            end
            rawI2CWrite(obj.I2CDriverObj, obj.Parent.ProtocolObj,  obj.Bus, obj.I2CAddress, data);
        end

        function data = readRegisterImpl(obj, registerAddress, count, varargin)
            data = registerI2CRead(obj.I2CDriverObj, obj.Parent.ProtocolObj, obj.Bus, obj.I2CAddress, registerAddress, count);
        end
    end

    methods(Access = private)
        function startI2C(obj)
            openI2CBus(obj.I2CDriverObj, obj.Parent.ProtocolObj, obj.Bus, 'I2CFrequency', obj.BitRate);
        end
    end
end
