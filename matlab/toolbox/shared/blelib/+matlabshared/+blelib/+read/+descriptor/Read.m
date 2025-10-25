classdef Read < matlabshared.blelib.read.descriptor.Interface
%READ - Concrete read interface class for descriptor that has "Read" property
    
% Copyright 2019 The MathWorks, Inc.

    methods
        function value = read(~, client)
            try
                value = execute(client, matlabshared.blelib.internal.ExecuteCommands.READ_DESCRIPTOR);
                value = double(value);
            catch e
                if string(e.identifier).startsWith("MATLAB:ble:ble:gattCommunication") || ...
                   ismember(e.identifier, ["MATLAB:ble:ble:failToExecuteDeviceDisconnected", ...
                                           "MATLAB:ble:ble:deviceProfileChanged"])
                    throwAsCaller(e);
                else
                    matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:failToReadDescriptor');
                end
            end
        end
    end
end