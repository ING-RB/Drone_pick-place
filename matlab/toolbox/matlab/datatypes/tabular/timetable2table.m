function t = timetable2table(tt,varargin)  %#codegen
%

%   Copyright 2016-2024 The MathWorks, Inc.

if ~coder.target('MATLAB')
    % codegen, redirect to codegen specific function and return
    t = matlab.internal.coder.timetable2table(tt, varargin{:});
    return
end

if ~istimetable(tt)
    error(message('MATLAB:timetable2table:NonTimetable'))
end

varNames = tt.Properties.VariableNames;

if nargin == 1
    convertRowTimes = true;
else
    pnames = {'ConvertRowTimes'};
    dflts =  {            true };
    convertRowTimes = matlab.internal.datatypes.parseArgs(pnames, dflts, varargin{:});
end

% Use the default table row dim name and take the var dim name from the timetable.
% Make sure the former doesn't conflict with the input timetable's var names or dim names.
dimNames = tt.Properties.DimensionNames;
rowsDimName = getString(message('MATLAB:table:uistrings:DfltRowDimName')); % table.defaultDimNames{1}
rowsDimName = matlab.lang.makeUniqueStrings(rowsDimName,[varNames dimNames(2)],namelengthmax);
dimNames{1} = rowsDimName;

% Create a table from the timetable's variables. No need to check if they are
% all the same height, they are all vars in one timetable.
t = table.init(getVars(tt,false),height(tt),{},width(tt),varNames,dimNames);

% Copy over the per-array and per-var metadata, but not the row or dim names.
t = transferNonRowProperties(tt,t);

if convertRowTimes
    % Create a variable from the row times, named according to the input's row
    % dim name, at the front of the table. Add this _after_ copying the other
    % vars' props from tt to t. Make sure the existing dim names are unique with
    % respect to new var name and (if modified) the other var names.
    rowTimesVarName = tt.Properties.DimensionNames{1};
    [dimNames,modified] = matlab.lang.makeUniqueStrings(dimNames,[rowTimesVarName varNames],namelengthmax);
    if any(modified)
        t.Properties.DimensionNames = dimNames;
    end
    t.(rowTimesVarName) = tt.Properties.RowTimes;
    nvars = width(t);
    t = t(:,[nvars 1:nvars-1]);
end
