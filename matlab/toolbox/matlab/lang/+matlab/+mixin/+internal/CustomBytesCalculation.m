classdef (Abstract, Hidden) CustomBytesCalculation
    % Mixin to use if a class needs to provide a custom calculation for the
    % size of its data in bytes as shown by WHOS, etc.
    
    % Copyright 2021 The MathWorks, Inc.
    
    methods(Hidden, Abstract)
        bytes = getDataSizeInBytes(obj)
    end
end