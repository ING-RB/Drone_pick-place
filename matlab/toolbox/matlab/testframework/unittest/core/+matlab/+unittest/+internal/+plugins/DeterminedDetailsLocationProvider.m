classdef(Hidden) DeterminedDetailsLocationProvider < matlab.unittest.internal.plugins.DetailsLocationProvider
    
    %
    
    % Copyright 2020 The MathWorks, Inc.
    
    properties(Hidden, SetAccess=immutable)
        PotentialAffectedIndices;
        DetailsStartIndex;
    end
    
    properties(Hidden, SetAccess=private)
        DetailsEndIndex;
    end
    
    methods(Hidden)
        function indicesHolder = DeterminedDetailsLocationProvider(startIdx, endIdx)
            indicesHolder.DetailsStartIndex = startIdx;
            indicesHolder.DetailsEndIndex = endIdx;
            indicesHolder.PotentialAffectedIndices = startIdx:endIdx;
        end
    end
end
