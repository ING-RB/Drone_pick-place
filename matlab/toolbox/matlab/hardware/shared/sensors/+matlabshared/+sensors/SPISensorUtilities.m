classdef SPISensorUtilities < matlabshared.sensors.internal.Accessor

    % This class provides internal API to be used by SPI sensor
    % infrastructure. It should be inherited by the hardware class to
    % support SPI sensors. It has similar APIs as matlabshared.spi.controller.
    % So HWSDK based targets do not need to inherit this.

    % Copyright 2023 The MathWorks, Inc.
    %#codegen
    methods (Access = private, Static = true)
        function name = matlabCodegenRedirect(~)
            % Codegen redirector class. During codegen the current class
            % will willbe replaced by the following class
            name = 'matlabshared.sensors.coder.matlab.SPISensorUtilities';
        end
    end

    properties(GetAccess = public, SetAccess = protected)
        % Set of properties to be defined by the sub class. Sensor objects
        % access these properties directly.
        Bus
        bitRate
        MOSIPin
        MISOPin
        ChipSelectPin
        ClockPin
        SPIMode
        isCSPinActiveLow
        isSPIDeviceMaster
        SPIRegisterSize
        bitOrder
    end

    properties(Access = ?matlabshared.sensors.internal.Accessor)
        % It holds the IO Client object that is used by SPI Device classs.
        SPIDriverObj
    end

     methods(Abstract, Access = public)
        % Implement the following methods in the hardware class
        spiChipSelectPins = getAvailableSPIChipSelectPins(obj, bus);
    end

    properties(Access = private)
        Parent
        Protocol
    end
end
