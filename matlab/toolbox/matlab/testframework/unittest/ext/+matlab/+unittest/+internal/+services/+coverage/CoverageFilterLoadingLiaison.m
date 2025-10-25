classdef CoverageFilterLoadingLiaison < handle
    % This class is undocumented and will change in a future release.
    % CoverageFilterManagerLiaison - Class to handle coverage filtering data between CoverageMetricsService classes.

    % Copyright 2024 The MathWorks, Inc.

    properties (SetAccess = immutable)
        FilterFiles
    end

    properties 
        JustificationArray 
    end

    methods
        function liaison = CoverageFilterLoadingLiaison(filenameArray)
            arguments 
                filenameArray (1,:) string
            end

            liaison.FilterFiles = filenameArray;
        end
    end
end
