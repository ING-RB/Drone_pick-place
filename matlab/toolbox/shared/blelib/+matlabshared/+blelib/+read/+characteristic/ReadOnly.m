classdef ReadOnly < matlabshared.blelib.read.characteristic.Interface
%READONLY - Concrete read interface class for characteristic that only
%has "Read" but no "Notify" or "Indicate" property
    
% Copyright 2019 The MathWorks, Inc.

    methods
        function [value, timestamp] = read(obj, client, varargin)
            narginchk(2, 3);
            
            % Validate mode
            validateMode(obj, varargin{:});
            try
                output = execute(client,matlabshared.blelib.internal.ExecuteCommands.READ_CHARACTERISTIC);
                value = double(output.Value.Data);
                timestamp = datetime(output.Value.Timestamp,'InputFormat','MM/dd/uuuu HH:mm:ss.SSSS');
            catch e
                if string(e.identifier).startsWith("MATLAB:ble:ble:gattCommunication") || ...
                   ismember(e.identifier, ["MATLAB:ble:ble:failToExecuteDeviceDisconnected", ...
                                           "MATLAB:ble:ble:deviceProfileChanged"])
                    throwAsCaller(e);
                else
                    matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:failToReadCharacteristic');
                end
            end
        end
        
        function fcn = getDataAvailableFcn(~) %#ok<STOUT>
            matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:noDataAvailableFcnAccess');
        end
        
        function setDataAvailableFcn(~, ~, ~)
            matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:noDataAvailableFcnAccess');
        end
        
        function subscribe(~, ~, ~, ~)
            matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:unsupportedOperation');
        end
        
        function unsubscribe(~, ~)
            matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:unsupportedOperation');
        end
        
        function displayDataAvailableFcn(~)
            % Display nothing by default
        end
        
        function resetSubscription(~, ~)
            matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:unsupportedOperation');
        end
    end
    
    methods(Access = private)
        function validateMode(~, varargin)
            % For characteristic that only supports Read, only valid mode
            % is "latest"
            if nargin > 1
                supportedModes = matlabshared.blelib.internal.Constants.SupportedReadModesReadOnly;
                try
                    validatestring(varargin{1}, supportedModes);
                catch
                    matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:invalidModeReadOnly', supportedModes);
                end
            end
        end
    end
end