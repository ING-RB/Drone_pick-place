function tt = array2timetable(x,varargin)  %#codegen
%

%   Copyright 2016-2024 The MathWorks, Inc.

if ~coder.target('MATLAB')
    % codegen, redirect to codegen specific function and return
    tt = matlab.internal.coder.array2timetable(x, varargin{:});
    return
end

if ~ismatrix(x)
    error(message('MATLAB:array2timetable:NDArray'));
end
[nrows,nvars] = size(x);

pnames = {'VariableNames' 'DimensionNames' 'RowTimes'  'SampleRate'  'TimeStep'  'StartTime'};
dflts =  {            []               []         []            []          []   seconds(0) };
[varnames,dimnames,rowtimes,sampleRate,timeStep,startTime,supplied] ...
    = matlab.internal.datatypes.parseArgs(pnames, dflts, varargin{:}); 
[rowtimesDefined,rowtimes,startTime,timeStep,sampleRate] ...
    = matlab.internal.tabular.validateTimeVectorParams(supplied,rowtimes,startTime,timeStep,sampleRate);
if ~rowtimesDefined % neither RowTimes, TimeStep, nor SampleRate was specified
    error(message('MATLAB:timetable:NoTimeVector'));
end

if ~supplied.VariableNames
    if nvars > 0 % skip nvars==0 for performance
        baseName = inputname(1);
        if isempty(baseName)
            varnames = matlab.internal.tabular.defaultVariableNames(1:nvars);
        else
            if nvars == 1
                varnames = {baseName};
            else
                varnames = matlab.internal.datatypes.numberedNames(baseName,1:nvars);
            end
        end
    else
        varnames = cell(1,0);
    end
end

% Each column of X becomes a variable in TT. No need to check if they are all the
% same height, they are all columns in one array.
vars = mat2cell(x,nrows,ones(1,nvars));
if supplied.RowTimes
    % The input matrix defines the size of the output timetable. The time
    % vector must have the same length as the matrix has rows, even if
    % the matrix has no columns.
    if numel(rowtimes) ~= nrows
        error(message('MATLAB:array2timetable:IncorrectNumberOfRowTimes'));
    end

    % No special case to create an Nx0 empty, assigning row times outweighs
    % advantage of using timetable.empty.
    if supplied.DimensionNames
        tt = timetable.init(vars,nrows,rowtimes,nvars,varnames,dimnames);
    else
        tt = timetable.init(vars,nrows,rowtimes,nvars,varnames);
    end
else % supplied.TimeStep || supplied.SampleRate
    if supplied.DimensionNames
        tt = timetable.initRegular(vars,nrows,startTime,timeStep,sampleRate,nvars,varnames,dimnames);
    else
        tt = timetable.initRegular(vars,nrows,startTime,timeStep,sampleRate,nvars,varnames);
    end
    
end
