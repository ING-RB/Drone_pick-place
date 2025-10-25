classdef MATLABMethodCoverageInfo 
    % MATLABMethodCoverageInfo is used to get the method coverage information
    % for generated MATLAB files
    
    % Copyright 2024 The MathWorks, Inc.

    properties (SetAccess = private)
        FileCoverageInfo
    end

    methods
        function info = MATLABMethodCoverageInfo(fileCoverageInfo)
            info.FileCoverageInfo = fileCoverageInfo;
        end

        function methodCoverageInfo = getMethodCoverageInfoList(info)
            % For now, use the FileInformation
            % infrastructure to get the MethodInformation objects. (g2443865)

            import matlab.unittest.internal.fileinformation.FileInformation
            import matlab.unittest.internal.coverage.MethodCoverageInfo
        
            lineMetric = info.FileCoverageInfo.getCoverageData("matlab.unittest.internal.coverage.metrics.LineMetric");
            if isempty(lineMetric)
                % Since method information is used only to report line
                % coverage, return empty if line coverage data returns empty
                methodCoverageInfo = MethodCoverageInfo.empty;
                return;
            end

            fileExecLines = lineMetric.ExecutableLines;            
            fileInfo = FileInformation.forFile(info.FileCoverageInfo.FullName,fileExecLines);
            methodsInfo = fileInfo.MethodList;            
            methodCoverageInfo = MethodCoverageInfo(methodsInfo, info.FileCoverageInfo.Metrics);
        end
    end
end