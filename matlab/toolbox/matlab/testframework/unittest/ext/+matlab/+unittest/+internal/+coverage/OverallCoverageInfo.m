classdef OverallCoverageInfo < matlab.unittest.internal.coverage.ContainerCoverageInfo

    % Class is undocumented and may change in a future release.
    
    %  Copyright 2021-2023 The MathWorks, Inc.
    
    properties (SetAccess = private)
        SourceCoverageInfoList matlab.unittest.internal.coverage.SourceCoverageInfo = matlab.unittest.internal.coverage.NamespaceCoverageInfo.empty(1,0); 
    end
    
    methods         
        function addCoverageSourceInfoElement(srcCoverageInfoElement,newCoverageElement)
            validateattributes(newCoverageElement,{'matlab.unittest.internal.coverage.SourceCoverageInfo'},{'row'});
            srcCoverageInfoElement.SourceCoverageInfoList = [srcCoverageInfoElement.SourceCoverageInfoList newCoverageElement];
        end
 
        function varargout = formatCoverageData(overallCoverageInfo,formatter,varargin)
            [varargout{1:nargout}] = formatter.formatOverallCoverageData(overallCoverageInfo,varargin{:});
        end
    end
    
    methods (Access = ?matlab.unittest.internal.coverage.FileCoverageInfo )
        function insertCoverageElement(overallCoverageInfo,fileCoverageInfo)
            import matlab.unittest.internal.coverage.NamespaceCoverageInfo
            
            namespace = fileCoverageInfo.Namespace;
            pkgIndex = find(strcmp({overallCoverageInfo.SourceCoverageInfoList.Namespace},namespace));
            if isempty(pkgIndex)
                namespaceCoverageInfo = NamespaceCoverageInfo(namespace);
                overallCoverageInfo.addCoverageSourceInfoElement(namespaceCoverageInfo);
            else
                namespaceCoverageInfo = overallCoverageInfo.SourceCoverageInfoList(pkgIndex);   
            end
            namespaceCoverageInfo.addCoverageElement(fileCoverageInfo);
        end
    end    
end
