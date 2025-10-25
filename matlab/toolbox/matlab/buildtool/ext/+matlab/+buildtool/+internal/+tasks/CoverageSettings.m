classdef CoverageSettings
    % This class is unsupported and might change or be removed without notice
    % in a future version.

    % Copyright 2023-2024 The MathWorks, Inc.

    properties (SetAccess=immutable)
        Results (1,:) {mustBeFileOrCoverageFormat} = matlab.buildtool.io.File.empty()
    end

    properties (Dependent, SetAccess=private)
        ResultFiles
    end

    properties (Abstract, Dependent, SetAccess=private)
        ResultFormats
    end

    properties (Abstract, Constant)
        DefaultFileExtension (1,1) string
    end

    methods (Access = protected)
        function s = CoverageSettings(results)
            arguments
                results (1,:) {mustBeFileOrCoverageFormat}
            end
            s.Results = results;
        end
    end

    methods
        function resultFiles = get.ResultFiles(s)
            arguments (Output)
                resultFiles (1,:) matlab.buildtool.io.File
            end

            import matlab.buildtool.internal.tasks.addExtensionIfNeeded

            results = s.Results;
            resultFiles = matlab.buildtool.io.File.empty();

            if isa(results, "matlab.unittest.plugins.codecoverage.CoverageFormat")
                for format = results
                    if isprop(format, "Filename")
                        resultFiles = [resultFiles; matlab.buildtool.io.File(format.Filename)]; %#ok<AGROW
                    end
                end
                return;
            end

            if ~isa(results, "matlab.buildtool.io.File")
                results = matlab.buildtool.io.File(results);
            end
            resultFiles = results.transform(@(p)addExtensionIfNeeded(p, s.DefaultFileExtension));
        end
    end
end

function mustBeFileOrCoverageFormat(varargin)
matlab.buildtool.internal.tasks.mustBeFileOrCoverageFormat(varargin{:});
end