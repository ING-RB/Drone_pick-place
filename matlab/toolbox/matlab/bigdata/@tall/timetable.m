function tt = timetable(varargin)
%TIMETABLE Build a tall timetable from tall arrays
%   TT =  TIMETABLE(TROWTIMES, TVAR1, TVAR2, ...) creates a tall timetable
%   TT from tall arrays TVAR1, TVAR2, ..., using the tall datetime or
%   duration vector TROWTIMES as the time vector. All arrays must be tall
%   and have the same number of rows.
%
%   TT = TIMETABLE(TVAR1, VTAR2, ..., 'RowTimes',TROWTIMES) creates a timetable
%   using the specified tall datetime or duration vector, TROWTIMES, as the time
%   vector. Other datetime or duration inputs become variables in TT.       
%
%   TT = TIMETABLE(..., 'VariableNames', {'name1', ..., 'name_M'}) creates a
%   timetable containing variables that have the specified variable names.
%   The names must be valid MATLAB identifiers, and unique.
%
%   TT = TIMETABLE(..., 'DimensionNames', {'dim1', 'dim2'}) creates a
%   timetable containing variables that have the specified dimension names.
%   The names must be valid MATLAB identifiers, and unique.
%
%   Limitations:
%   1. The parameters 'SampleRate', 'TimeStep', and 'StartTime' are not supported.
%   2. The 'Events' and 'VariableTypes' properties are not supported for tall timetables.
%
%   See also tall, timetable.

% Copyright 2016-2023 The MathWorks, Inc.

% Attempt to deal with trailing p-v pairs.
numVars = matlab.bigdata.internal.util.countTableVarInputs(varargin);
vars = varargin(1:numVars);

% Parse name-value pairs provided as name=value syntax. Name coming from
% Name=Value would be a scalar string. Convert it to char row vector,
% because tabular constructors don't allow scalar strings for name-value
% names.
import matlab.lang.internal.countNamedArguments
% Check if name=value syntax has been used, it must be done in the function
% called by the user.
try
    numNamedArguments = countNamedArguments();
catch
    % If countNamedArguments fails, no name-value pairs have been provided
    % with name=value syntax.
    numNamedArguments = 0;
end
args = matlab.bigdata.internal.util.parseNamedArguments(numNamedArguments, varargin{numVars+1:end});

pnames   = {'VariableNames' 'RowTimes'  'SampleRate'  'SamplingRate'  'TimeStep'  'StartTime'  'DimensionNames'}; % SamplingRate is legacy
dflts    = {            []         []            []              []          []   seconds(0)                 0 };
priority = [             0          0             1               0           0            1                 0 ]; % 'Sa' -> 'SampleRate', 'S' -> ambiguous
[varnames, rowtimes, ~, ~, ~, ~, dimNames, supplied] ...
    = matlab.internal.datatypes.parseArgsTabularConstructors(pnames, dflts, priority, ...
                                                             'MATLAB:timetable:StringParamNameNotSupported', ...
                                                             args{:});
if supplied.SampleRate || supplied.SamplingRate || supplied.TimeStep || supplied.StartTime
    error(message('MATLAB:bigdata:array:TimetableUnsupportedParam'));
end

if ~supplied.VariableNames
    % Get the workspace names of the input arguments from inputname if
    % variable names were not provided. Need these names before looking
    % through vars for the time vector.
    varnames = repmat({''},1,numVars);
    for i = 1:numVars
        varnames{i} = inputname(i);
    end
end

% Setup rowtimes 
rowtimesName = getString(message('MATLAB:timetable:uistrings:DfltRowDimName'));
if ~supplied.RowTimes
    rowtimes = vars{1};
    % Without rowtimes, first argument must be datetime or duration
    rowtimes = tall.validateType(rowtimes, mfilename, {'datetime', 'duration'}, 1);
    vars(1) = [];
    if ~supplied.VariableNames
        if ~isempty(varnames{1})
            rowtimesName = varnames{1};
        end
        varnames(1) = [];
    end
    numVars = numVars - 1;
end

% Check for tall
if ~istall(rowtimes)
    % rowtimes must be tall.
    error(message('MATLAB:bigdata:array:AllTableArgsTall'));
end
if ~all(cellfun(@istall, vars))
    % all data must be tall
    error(message('MATLAB:bigdata:array:AllTableArgsTall'));
end

if ~supplied.VariableNames
    % Fill in default names for data args where inputname couldn't. Do
    % this after removing the time vector from the other vars, to get the
    % default names numbered correctly.
    empties = cellfun('isempty',varnames);
    if any(empties)
        varnames(empties) = matlab.internal.tabular.defaultVariableNames(find(empties));
    end
    % Make sure default names or names from inputname don't conflict
    varnames = matlab.lang.makeUniqueStrings(varnames,{},namelengthmax);
end

if ~supplied.DimensionNames
    varDimNames = getString(message('MATLAB:timetable:uistrings:DfltVarDimName'));
    dimNames = {rowtimesName, varDimNames};
end

matlab.bigdata.internal.util.checkTableVariableNames(varnames, dimNames, numVars);

tt = makeTallTimetableWithDimensionNames(dimNames, rowtimes, varnames, ...
                                         MException.empty(), vars{:});
end
