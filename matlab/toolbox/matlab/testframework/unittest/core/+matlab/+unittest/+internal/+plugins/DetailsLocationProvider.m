classdef(Abstract) DetailsLocationProvider < handle
    
    %
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    properties(Abstract, Hidden, SetAccess=immutable)
        PotentialAffectedIndices;
        DetailsStartIndex;
    end
    
    properties(Abstract, Hidden, SetAccess=private)
        DetailsEndIndex;
    end

    properties (Dependent, SetAccess=private)
        ActiveAffectedIndices;
    end
    
    events (NotifyAccess=protected)
        EndIndexSet;
    end

    methods
        function indices = get.ActiveAffectedIndices(locationProvider)
            if isempty(locationProvider.DetailsEndIndex)
                indices = locationProvider.PotentialAffectedIndices;
            else
                indices = locationProvider.DetailsStartIndex:locationProvider.DetailsEndIndex;
            end
        end
    end
end
