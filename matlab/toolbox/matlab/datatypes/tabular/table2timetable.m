function tt = table2timetable(t,varargin)  %#codegen
%

%   Copyright 2016-2024 The MathWorks, Inc.

if ~coder.target('MATLAB')
    % codegen, redirect to codegen specific function and return
    tt = matlab.internal.coder.table2timetable(t, varargin{:});
    return
end

if ~istable(t)
    error(message('MATLAB:table2timetable:NonTable'));
end

varnames = t.Properties.VariableNames;
dimnames = t.Properties.DimensionNames;
rowsDimname = getString(message('MATLAB:timetable:uistrings:DfltRowDimName')); % timetable.defaultDimNames{1}
getRowtimesFromTable = false;

if nargin == 1
    % Take the time vector as the first datetime/duration variable in the table.
    % If the table is n-by-p, the timetable will be n-by-(p-1).
    isTime = @(x) isa(x,'datetime') || isa(x,'duration');
    rowtimesCandidates = varfun(isTime,t,'OutputFormat','uniform');
    rowtimesIndex = find(rowtimesCandidates,1);
    if isempty(rowtimesIndex)
        error(message('MATLAB:table2timetable:NoTimeVarFound'));
    end
    rowsDimname = varnames{rowtimesIndex};
    getRowtimesFromTable = true;
    supplied.RowTimes = true;
else
    % Take the time vector as the RowTimes input, or as the specified variable in the table.
    % If the table is n-by-p, the timetable will be n-by-p, or n-by-(p-1), respectively.
    pnames = {'VariableNames' 'RowTimes'  'SampleRate'  'TimeStep'  'StartTime'};
    dflts =  {            []         []            []          []   seconds(0) };
    [~,rowtimes,sampleRate,timeStep,startTime,supplied] ...
        = matlab.internal.datatypes.parseArgs(pnames, dflts, varargin{:});    
    [rowtimesDefined,rowtimes,startTime,timeStep,sampleRate] ...
        = matlab.internal.tabular.validateTimeVectorParams(supplied,rowtimes,startTime,timeStep,sampleRate);
    
    if supplied.VariableNames
        error(message('MATLAB:table2timetable:VariableNamesNotAccepted'));
    end
    if ~rowtimesDefined % neither RowTimes, TimeStep, nor SampleRate was specified
        error(message('MATLAB:timetable:NoTimeVector'));
    end

    if supplied.RowTimes
        % If the RowTime parameter is supplied, figure out if it's an
        % explicit vector, or a reference to a table variable.
        if isa(rowtimes,'datetime') || isa(rowtimes,'duration')
            % The input table defines the size of the output timetable. The time
            % vector must have the same length as the table has rows, even if
            % the table has no vars.
            if numel(rowtimes) ~= height(t)
                error(message('MATLAB:table2timetable:IncorrectNumberOfRowTimes'));
            end
        elseif matlab.internal.datatypes.isScalarText(rowtimes)
            % The row times are specified as a variable in the table.
            rowsDimname = convertStringsToChars(rowtimes);
            rowtimesIndex = find(matches(varnames,rowtimes));
            if isempty(rowtimesIndex)
                error(message('MATLAB:table:UnrecognizedVarName',rowsDimname));
            end
            getRowtimesFromTable = true;
        elseif matlab.internal.datatypes.isScalarInt(rowtimes,1)
            rowtimesIndex = rowtimes;
            if rowtimesIndex > width(t)
                error(message('MATLAB:table:VarIndexOutOfRange'));
            end
            rowsDimname = varnames{rowtimesIndex};
            getRowtimesFromTable = true;
        else
            error(message('MATLAB:table2timetable:InvalidRowTimes'));
        end
    end
end

% If the row times were specified as a variable in the table, take that var out
% of the table
vars = getVars(t,false);
if getRowtimesFromTable
    rowtimes = vars{rowtimesIndex};
    vars(rowtimesIndex) = [];
    varnames(rowtimesIndex) = [];
    t.(rowtimesIndex) = []; % remove it from the table, updating the metadata in the process.
end

nvars = length(vars);
% Need to look at the original table for number of rows, in case there are no vars
% from which to get this info.
nrows = height(t);

% Make sure the new row dim name doesn't conflict with any of the input tables varnames or dimnames
rowsDimname = matlab.lang.makeUniqueStrings(rowsDimname,[varnames dimnames(2)],namelengthmax);

% Use the specified table var name (or the default) for the row dim name, and
% take the var dim name from the timetable.
dimnames{1} = rowsDimname;

if supplied.RowTimes
    tt = timetable.init(vars,nrows,rowtimes,nvars,varnames,dimnames);
else % supplied.TimeStep || supplied.SampleRate
    tt = timetable.initRegular(vars,nrows,startTime,timeStep,sampleRate,nvars,varnames,dimnames);
end

% Copy over the per-array and per-var metadata, but not the row or dim names.
tt = transferNonRowProperties(t,tt);

% Include the table's row names, if any
rownames = t.Properties.RowNames;
if isvector(rownames)
    % Create a variable from the row names, named according to the input's row
    % dim name, at the front of the table. Add this _after_ copying the other
    % vars' props from tt to t. Make sure the existing dim names are unique with
    % respect to new var name and (if modified) wth the other var names.
    rowNamesVarName = t.Properties.DimensionNames{1};
    [dimnames,modified] = matlab.lang.makeUniqueStrings(dimnames,[rowNamesVarName varnames],namelengthmax);
    if any(modified)
        tt.Properties.DimensionNames = dimnames;
    end
    tt.(rowNamesVarName) = rownames;
    nvars = width(tt);
    tt = tt(:,[nvars 1:nvars-1]);
end
