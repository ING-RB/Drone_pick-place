function tt = array2timetable(x,varargin)  %#codegen
%ARRAY2TIMETABLE Convert homogeneous array to timetable.

%   Copyright 2019-2022 The MathWorks, Inc.

coder.internal.prefer_const(varargin);
coder.internal.assert(ismatrix(x), 'MATLAB:array2timetable:NDArray');
dfltDimNames = matlab.internal.coder.timetable.defaultDimNames;
pnames = {'VariableNames' 'RowTimes'  'SampleRate'  'TimeStep'  'StartTime' 'DimensionNames'};
poptions = struct( ...
    'CaseSensitivity',false, ...
    'PartialMatching','unique', ...
    'StructExpand',false);
pstruct = coder.internal.parseParameterInputs(pnames,poptions,varargin{:});

varnames = coder.internal.getParameterValue(pstruct.VariableNames,{},varargin{:});
rowtimes = coder.internal.getParameterValue(pstruct.RowTimes,[],varargin{:});
sampleRate = coder.internal.getParameterValue(pstruct.SampleRate,[],varargin{:});
timeStep = coder.internal.getParameterValue(pstruct.TimeStep,[],varargin{:});
startTime = coder.internal.getParameterValue(pstruct.StartTime,seconds(0),varargin{:});
dimnames = coder.internal.getParameterValue(pstruct.DimensionNames,dfltDimNames,varargin{:});
useSampleRate = (pstruct.SampleRate ~= 0);

[rowtimesDefined,startTime,timeStep,sampleRate] ...
    = matlab.internal.coder.tabular.validateTimeVectorParams ((pstruct.RowTimes ~= 0),...
    startTime,(pstruct.StartTime ~= 0), timeStep, (pstruct.TimeStep ~= 0), sampleRate, useSampleRate);
% error if neither RowTimes, TimeStep, nor SampleRate was specified
coder.internal.assert(rowtimesDefined, 'MATLAB:timetable:NoTimeVector');

% codegen requires VariableNames to be defined and constant
coder.internal.assert(pstruct.VariableNames ~= 0, 'MATLAB:array2timetable:CodegenVarNames');
coder.internal.assert(coder.internal.isConst(varnames), 'MATLAB:array2timetable:NonconstantVariableNames');

% Verify that dimension names are constant
coder.internal.assert(coder.internal.isConst(dimnames), ...
                                    'MATLAB:table:NonconstantDimensionNames');

% Get the number of rows and variables
nrows = size(x,1);
sz2 = size(x,2);
if coder.internal.isConst(sz2)
    nvars = coder.const(sz2);
else
    % If the input array is variable sized in the second dimension, then use the
    % number of elements in the supplied varnames as nvars. Add a runtime check to
    % verify that the size of the second dimension and number of variable names,
    % match up. This is necessary to avoid creating variable sized timetables.
    nvars = coder.const(numel(varnames));
    coder.internal.assert(nvars == sz2, ...
        'MATLAB:table:IncorrectNumberOfVarNames');
end

% split the array into a cell array, with each column going into a
% separate cell
vars = cell(1,nvars);
if iscell(x)
    for i = 1:nvars
        col = cell(nrows,1);
        for j = 1:nrows
            col{j} = x{j,i};  
        end
        vars{i} = col;
    end
else
    for i = 1:nvars
        vars{i} = x(:,i);
    end
end

if pstruct.RowTimes
    % The input matrix defines the size of the output timetable. The time
    % vector must have the same length as the matrix has rows, even if
    % the matrix has no columns.
    coder.internal.assert(numel(rowtimes) == nrows, 'MATLAB:array2timetable:IncorrectNumberOfRowTimes');

    % No special case to create an Nx0 empty, assigning row times outweighs
    % advantage of using timetable.empty.
    tt = timetable.init(vars,nrows,rowtimes,nvars,varnames,dimnames);
else % pstruct.TimeStep || pstruct.SampleRate
    tt = timetable.initRegular(vars,nrows,startTime,timeStep,sampleRate,nvars,varnames,dimnames);
end
