classdef Default < matlabshared.blelib.read.descriptor.Interface
%DEFAULT - Default interface that does not support read
    
% Copyright 2019 The MathWorks, Inc.

    methods
        function value = read(~, ~) %#ok<STOUT>
            matlabshared.blelib.internal.localizedError('MATLAB:ble:ble:unsupportedOperation');
        end
    end
end