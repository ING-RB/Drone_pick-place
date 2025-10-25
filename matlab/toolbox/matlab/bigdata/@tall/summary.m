function out = summary(t)
%SUMMARY Display summary information about tall table or tall timetable
%   SUMMARY(TT) displays a summary of all the variables in tall table or tall
%   timetable TT. This will take a long time to execute if there is a large
%   amount of data in TT.
%
%   S = SUMMARY(TT) returns a struct with the summary of the tall table or
%   tall timetable.
%
%   Limitations:
%   1. Only tall tables and tall timetables are supported.
%   2. Name-value arguments "Detail", "Statistics", and "DataVariables" are
%   not supported.
%   3. Some calculations in the summary might be slow to complete with
%   large data sets, such as the median and standard deviation, and are not
%   included.

% Copyright 2015-2024 The MathWorks, Inc.

t = tall.validateType(t, mfilename, {'table', 'timetable'}, 1);

gotSummary = false;
metadata = hGetMetadata(hGetValueImpl(t));
if ~isempty(metadata)
    [gotSummary, summaryInfo] = getValue(metadata, 'TableSummary');
end

if ~gotSummary
    summaryInfo = gather(aggregatefun( ...
        @matlab.bigdata.internal.util.calculateLocalSummary, ...
        @matlab.bigdata.internal.util.reduceSummary, ...
        t));
end

% Extract table information
tableInfo = summaryInfo{1};
summaryInfo(1) = [];

tableProperties = subsref( t, substruct( '.', 'Properties' ) );
isDisplay = nargout == 0;
outputStruct = matlab.bigdata.internal.util.emitSummary(summaryInfo, tableProperties, isDisplay);
if isDisplay
    % Default stats for tabular inputs without median or std
    statLabels = ["NumMissing" "Min" "Max" "Mean"];
    matlab.bigdata.internal.util.printTabularSummary( outputStruct, tableInfo, tableProperties, statLabels, true, inputname(1) );
else
    out = outputStruct;
end

end
