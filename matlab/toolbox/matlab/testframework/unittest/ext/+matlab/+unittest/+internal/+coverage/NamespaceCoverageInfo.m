classdef NamespaceCoverageInfo <  matlab.unittest.internal.coverage.ContainerCoverageInfo
    % Class is undocumented and may change in a future release.
    
    %  Copyright 2021-2023 The MathWorks, Inc.
    
    properties (SetAccess = private)
        Namespace = char.empty;
    end
    properties (Dependent, SetAccess = private)
        SourceCoverageInfoList matlab.unittest.internal.coverage.SourceCoverageInfo
    end
    properties (Access = private)
        CoverageListCell = {}
    end

    methods
        function coverage = NamespaceCoverageInfo(namespace)
            coverage.Namespace = namespace;
        end
        
        function addCoverageElement(srcCoverageElement,newCoverageElement)
            srcCoverageElement.CoverageListCell{end+1} = newCoverageElement;
        end

        function varargout = formatCoverageData(namespaceCoverageInfo,formatter,varargin)
            [varargout{1:nargout}] = formatter.formatNamespaceCoverageData(namespaceCoverageInfo,varargin{:});
        end
        
        function filecovInfo = get.SourceCoverageInfoList(pkgcovInfo)
            import matlab.unittest.internal.coverage.FileCoverageInfo;
            filecovInfo = [FileCoverageInfo.empty(1,0), pkgcovInfo.CoverageListCell{:}];
        end
    end
end

% LocalWords:  filecov pkgcov
