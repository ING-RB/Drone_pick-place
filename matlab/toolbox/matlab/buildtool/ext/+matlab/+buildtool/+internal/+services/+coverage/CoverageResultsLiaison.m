classdef CoverageResultsLiaison < handle
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023-2024 The MathWorks, Inc.

    properties (SetAccess = immutable)
        ResultPath (1,1) string
        ResultFormat string {mustBeScalarOrEmpty} = string.empty()
    end

    properties (Abstract, Constant)
        ResultVarName (1,1) string {mustBeValidVariableName}
        CatalogKey (1,1) string {mustBeValidVariableName}
    end

    properties (Dependent, SetAccess = private)
        Extension
    end

    methods
        function liaison = CoverageResultsLiaison(resultPath, options)
            arguments
                resultPath (1,1) string
                options.CoverageFormat string {mustBeScalarOrEmpty} = string.empty()
            end
            liaison.ResultPath = resultPath;
            liaison.ResultFormat = options.CoverageFormat;
        end

        function extension = get.Extension(liaison)
            [~, ~, extension] = fileparts(liaison.ResultPath);
        end
    end
end