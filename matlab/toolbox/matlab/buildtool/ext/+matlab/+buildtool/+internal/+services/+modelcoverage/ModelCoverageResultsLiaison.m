classdef ModelCoverageResultsLiaison < matlab.buildtool.internal.services.coverage.CoverageResultsLiaison
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023-2024 The MathWorks, Inc.

    properties (Constant)
        ResultVarName = "modelcoverage"
        CatalogKey = "InvalidModelCoverageResultsFormat"
    end

    methods
        function liaison = ModelCoverageResultsLiaison(varargin)
            liaison@matlab.buildtool.internal.services.coverage.CoverageResultsLiaison(varargin{:});
        end
    end
end