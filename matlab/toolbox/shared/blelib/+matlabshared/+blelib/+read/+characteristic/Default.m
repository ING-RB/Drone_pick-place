classdef Default < matlabshared.blelib.read.characteristic.Interface
%INTERFACE - Default interface that does not support read and notify
    
% Copyright 2019 The MathWorks, Inc.

    methods
        function [value, timestamp] = read(~, ~, varargin) %#ok<STOUT>
            matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:unsupportedOperation');
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
end