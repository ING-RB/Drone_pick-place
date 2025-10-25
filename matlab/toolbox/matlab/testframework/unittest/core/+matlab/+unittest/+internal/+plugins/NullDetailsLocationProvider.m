classdef(Hidden) NullDetailsLocationProvider < matlab.unittest.internal.plugins.DetailsLocationProvider
    
    %
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties(Hidden, SetAccess=immutable)
        PotentialAffectedIndices = 0;
        DetailsStartIndex = 0;
    end
    
    properties(Hidden, SetAccess=private)
        DetailsEndIndex = 0;
    end
end
