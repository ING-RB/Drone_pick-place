classdef(Hidden) UndeterminedDetailsLocationProvider < matlab.unittest.internal.plugins.DetailsLocationProvider
    
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
        function indicesHolder = UndeterminedDetailsLocationProvider(startIdx, endIdx)
            indicesHolder.DetailsStartIndex = startIdx;
            indicesHolder.PotentialAffectedIndices = startIdx:endIdx;
        end
        
        function supplyEndIndex(locationProvider, endIndex)
            locationProvider.DetailsEndIndex = endIndex;
            locationProvider.notify("EndIndexSet");
        end
    end
end
