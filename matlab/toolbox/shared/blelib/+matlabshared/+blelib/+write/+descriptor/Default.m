classdef Default < matlabshared.blelib.write.descriptor.Interface
%DEFAULT - Default interface that does not support write
    
% Copyright 2019 The MathWorks, Inc.
    methods
        function write(~, ~, varargin)
            matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:unsupportedOperation');
        end
    end
end