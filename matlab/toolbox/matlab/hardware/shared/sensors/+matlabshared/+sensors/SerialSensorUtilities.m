classdef (Hidden, Abstract) SerialSensorUtilities < matlabshared.sensors.internal.Accessor
    
    % This class provides internal API to be used by GPS sensor
    % infrastructure. It should be inherited by the hardware class to
    % support GPS sensors. It has similar APIs as matlabshared.serial.controller.
    % So HWSDK based targets do not need to inherit this.
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    methods (Access = private, Static = true)
        function name = matlabCodegenRedirect(~)
            % Codegen redirector class. During codegen the current class
            % will willbe replaced by the following class
            name = 'matlabshared.sensors.coder.matlab.SerialSensorUtilities';
        end
    end
    
    methods(Abstract, Hidden)
        serialPorts = getAvailableSerialPortIDs(obj);
    end
end