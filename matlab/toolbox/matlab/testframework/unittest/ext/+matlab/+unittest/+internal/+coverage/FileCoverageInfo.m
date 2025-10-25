classdef FileCoverageInfo < matlab.unittest.internal.coverage.SourceCoverageInfo

    properties (Abstract, SetAccess = private)
        SourceList
        Complexity
        Metrics
    end

    methods (Sealed)
        function sourceInfoComposite = buildPackageList(fileCoverageInfoArray)
            import matlab.unittest.internal.coverage.OverallCoverageInfo
            sourceInfoComposite = OverallCoverageInfo;

            for idx = 1:numel(fileCoverageInfoArray)
                sourceInfoComposite.insertCoverageElement(fileCoverageInfoArray(idx));
            end
        end
    end

    methods
        function varargout  = formatCoverageData(fileCoverageInfo,formatter,varargin)
            [varargout{1:nargout}] = formatter.formatFileCoverageData(fileCoverageInfo,varargin{:});
        end
    end
end