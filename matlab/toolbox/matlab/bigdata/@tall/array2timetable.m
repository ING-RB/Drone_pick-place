function tt = array2timetable(ta, varargin)
%ARRAY2TIMETABLE Convert tall matrix to timetable
%   TT = ARRAY2TIMETABLE(TX,"RowTimes",ROWTIMES)
%   TT = ARRAY2TIMETABLE(TX,"RowTimes",ROWTIMES,"VariableNames",VARNAMES)
%   TT = ARRAY2TIMETABLE(TX,"RowTimes",ROWTIMES,"DimensionNames",DIMNAMES)
%   TT = ARRAY2TIMETABLE(TX,"RowTimes",ROWTIMES,"VariablesNames",VARNAMES,"DimensionNames",DIMNAMES)
%
%   See also ARRAY2TIMETABLE, TALL, TIMETABLE.

% Copyright 2017-2020 The MathWorks, Inc.

tall.checkIsTall(mfilename, 1, ta);
ta = tall.validateMatrix(ta, 'MATLAB:array2timetable:NDArray');

pnames = {'VariableNames' 'RowTimes'  'SampleRate'  'SamplingRate'  'TimeStep'  'StartTime'  'DimensionNames'}; % SamplingRate is legacy
dflts =  {            []         []            []              []          []   seconds(0)                [] };
[varNames, rowTimes, ~, ~, ~, ~, dimNames, supplied] ...
    = matlab.internal.datatypes.parseArgs(pnames, dflts, varargin{:});
if supplied.SampleRate || supplied.SamplingRate || supplied.TimeStep || supplied.StartTime
    error(message('MATLAB:bigdata:array:TimetableUnsupportedParam'));
end

if ~supplied.RowTimes
    error(message("MATLAB:array2timetable:RowTimeRequired"));
end
if ~istall(rowTimes)
    error(message('MATLAB:bigdata:array:Array2timetableInvalidRowTimes'));
end
rowTimes = tall.validateColumn(rowTimes, 'MATLAB:array2timetable:IncorrectNumberOfRowTimes');
[ta, rowTimes] = validateSameTallSize(ta, rowTimes);

aAdaptor = ta.Adaptor;
numVars = aAdaptor.getSizeInDim(2);
if ~supplied.VariableNames
    if isnan(numVars)
        numVars = gather(size(ta, 2));
    end
    baseName = inputname(1);
    if isempty(baseName) || (numVars == 0)
        varNames = matlab.internal.tabular.defaultVariableNames(1:numVars);
    elseif numVars == 1
        varNames = {baseName};
    else
        varNames = matlab.internal.datatypes.numberedNames(baseName, 1:numVars);
    end
end

if ~supplied.DimensionNames
    rowDimName = getString(message('MATLAB:timetable:uistrings:DfltRowDimName'));
    varDimName = getString(message('MATLAB:timetable:uistrings:DfltVarDimName'));
    dimNames = {rowDimName, varDimName};
end

matlab.bigdata.internal.util.checkTableVariableNames(varNames, dimNames, numVars);

% Apply the transformation
tt = slicefun(@(a,t) array2timetable(a, "RowTimes", t, "VariableNames", varNames, "DimensionNames", dimNames), ...
    ta, rowTimes);

% We must correctly set the adaptor for both the timetable and all of its
% constituent variables.
adaptor = resetSizeInformation(ta.Adaptor);
adaptor = copyTallSize(adaptor, ta.Adaptor);
adaptor = setSmallSizes(adaptor, 1);
varAdaptors = repmat({adaptor}, 1, numel(varNames));
tt.Adaptor = matlab.bigdata.internal.adaptors.TimetableAdaptor( ...
    varNames, varAdaptors, dimNames, rowTimes.Adaptor);
end
