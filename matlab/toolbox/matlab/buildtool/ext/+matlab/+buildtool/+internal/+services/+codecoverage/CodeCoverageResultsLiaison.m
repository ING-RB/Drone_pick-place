classdef CodeCoverageResultsLiaison < matlab.buildtool.internal.services.coverage.CoverageResultsLiaison
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023-2024 The MathWorks, Inc.

    properties (Constant)
        ResultVarName = "coverage"
        CatalogKey = "InvalidCodeCoverageResultsFormat"
    end

    methods
        function liaison = CodeCoverageResultsLiaison(varargin)
            liaison@matlab.buildtool.internal.services.coverage.CoverageResultsLiaison(varargin{:});
        end
    end
end