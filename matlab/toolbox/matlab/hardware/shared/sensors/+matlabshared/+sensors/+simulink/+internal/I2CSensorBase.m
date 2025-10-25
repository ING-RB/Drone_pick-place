classdef I2CSensorBase < handle
    %I2CSensorBase class which have I2C Specific Implementations

    %   Copyright 2020-2021 The MathWorks, Inc.

    %#codegen
    properties(Abstract)
        I2CAddress
        I2CModule char
    end

    properties(Abstract,Access = protected)
        I2CBus; % numeric value of I2C module
    end

    properties
        BitRate = 1000000;
    end

     methods(Hidden,Access = {?matlabshared.sensors.simulink.internal.SensorBlockBase,?matlabshared.sensors.simulink.internal.I2CSensorBase})
        function setValidatedI2CBus(obj)
            coder.extrinsic('matlabshared.sensors.simulink.internal.I2CSensorBase.getValidatedI2CModuleBase');
            obj.I2CBus = coder.const(@matlabshared.sensors.simulink.internal.I2CSensorBase.getValidatedI2CModuleBase,obj.I2CModule);
        end
    end

    methods(Static)
        function numericBusVal = getValidatedI2CModuleBase(module)
            %getValidatedI2CModuleBase() is used to call the target specific I2C Module
            % validation function. The function returns numeric bus value which is
            % required for C function
            targetname = matlabshared.sensors.simulink.internal.getTargetHardwareName;
            fileLocation = matlabshared.sensors.simulink.internal.getTargetSpecificFileLocationForSensors(targetname);
            numericBusVal = 0;
            funcName = [fileLocation,'.getValidatedI2CModuleInfo'];
            % check if function exists
            functionPath = which(funcName);
            if ~isempty(functionPath)
                funcHandle = str2func(funcName);
                numericBusVal = funcHandle(module);
                validateattributes(numericBusVal, {'numeric'},{ 'real','nonempty','integer', 'scalar'}, '', 'I2C bus value');
            end
        end
    end
end