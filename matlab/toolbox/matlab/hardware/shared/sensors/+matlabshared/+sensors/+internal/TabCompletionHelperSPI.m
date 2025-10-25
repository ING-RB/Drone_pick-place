classdef TabCompletionHelperSPI < matlabshared.sensors.internal.Accessor

    methods(Static)
        function cspins = getAvailableSPIChipSelectPins(hardwareObj)
            cspins  = hardwareObj.getAvailableSPIChipSelectPins;
        end
    end
end