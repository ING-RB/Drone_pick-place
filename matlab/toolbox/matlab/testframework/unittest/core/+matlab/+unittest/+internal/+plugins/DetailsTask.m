classdef DetailsTask < matlab.mixin.Heterogeneous
    
    %
    
    %   Copyright 2020 The MathWorks, Inc.
    
    properties(Abstract, SetAccess=immutable)
        DetailsLocationProvider;
    end
    
    methods(Abstract)
        performTask(task);
    end
end

