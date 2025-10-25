classdef SPISensorBase < handle
    %SPISensorBase class which have SPI Specific Implementations

    %   Copyright 2023 The MathWorks, Inc.

    %#codegen
    properties(Abstract)
        SlaveSelectPin
    end

    methods(Hidden,Access = {?matlabshared.sensors.simulink.internal.SensorBlockBase,?matlabshared.sensors.simulink.internal.SPISensorBase})
        function setValidatedSPIslaveselect(obj)
            coder.extrinsic('matlabshared.sensors.simulink.internal.SPISensorBase.getValidatedSPIChipSelectPin');
            obj.SlaveSelectPin = coder.const(@matlabshared.sensors.simulink.internal.SPISensorBase.getValidatedSPIChipSelectPin,obj.SlaveSelectPin);
        end
    end

    methods(Static)
        function val = getValidatedSPIChipSelectPin(chipselect)
            %getValidatedSPIChipSelectPin() is used to call the target
            %specific SPI chip select pin validation function.
            val = 0;
            if coder.target('MATLAB')
                targetname = matlabshared.sensors.simulink.internal.getTargetHardwareName;
                fileLocation = matlabshared.sensors.simulink.internal.getTargetSpecificFileLocationForSensors(targetname);
                val = 0;
                funcName = [fileLocation,'.getValidatedSPIChipSelect'];
                % check if function exists
                functionPath = which(funcName);
                if ~isempty(functionPath)
                    funcHandle = str2func(funcName);
                    val = funcHandle(chipselect);
                    validateattributes(chipselect, {'char'},{ 'nonempty'}, '', 'SPI chip select pin');
                end
            end
        end
    end
end