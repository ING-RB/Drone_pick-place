classdef Metric < matlab.mixin.Heterogeneous & handle
    % Interface class for different code coverage metric classes

    %  Copyright 2021-2023 The MathWorks, Inc.

    properties (Abstract, SetAccess = private)
        RawCoverageData
        ExecutableLines
        HitCount
        SourcePositionData
    end

    methods (Access = protected)
        function [uniqueReportableLines, nonUniqueReportableLines] = getReportableLines(metric)
            % The unique lines for all statements form the executable lines
            % in a file. In the static data, for each statement, the source
            % position is specified in the following vector format:
            %   {[lineNumber, startColNumber, lineNumber, endColNumber]}
            % For example:
            %   staticData = {[1 0 1 10]}
            %
            % For statements spanning multiple lines, multiple sets of
            % vector formats are used, one for each line. For example:
            %   staticData = {[1 0 1 10 ; 2 5 2 10]}


            allExecutableLinesMat = vertcat(metric.RawCoverageData{:,1});
            if isempty(allExecutableLinesMat)  % for files with no executable lines or statements
                nonUniqueReportableLines = [];
                uniqueReportableLines = [];
            else
                nonUniqueReportableLines = allExecutableLinesMat(:,1)';
                uniqueReportableLines = unique(nonUniqueReportableLines);
            end
        end
    end
    methods (Hidden)
        function metric = filterMetricForMethod(metric, ~)
        end
    end
end

