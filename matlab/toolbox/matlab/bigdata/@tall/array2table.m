function tt = array2table(ta, varargin)
%ARRAY2TABLE Convert tall matrix to table
%   TT = ARRAY2TABLE(TA)
%   TT = ARRAY2TABLE(..., 'VariableNames', {'name1', ..., 'name_M'}) 
%   TT = ARRAY2TABLE(..., 'DimensionNames', {'dim2', 'dim2'}) 
%
%   Limitations:
%   The parameter 'RowNames' is not supported.
%
%   See also ARRAY2TABLE, TALL, TABLE.

% Copyright 2016-2020 The MathWorks, Inc.

tall.checkIsTall(mfilename, 1, ta);
tall.checkNotTall(mfilename, 1, varargin{:});
ta = tall.validateMatrix(ta, 'MATLAB:array2table:NDArray');

pnames = {'VariableNames', 'RowNames', 'DimensionNames'};
dflts =  {             [],         [],               []};
[varNames, ~, dimNames, supplied] ...
    = matlab.internal.datatypes.parseArgs(pnames, dflts, varargin{:});
if supplied.RowNames
    error(message('MATLAB:bigdata:array:TableUnsupportedParam'));
end

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
    rowDimName = getString(message('MATLAB:table:uistrings:DfltRowDimName'));
    varDimName = getString(message('MATLAB:table:uistrings:DfltVarDimName'));
    dimNames = {rowDimName, varDimName};
end

matlab.bigdata.internal.util.checkTableVariableNames(varNames, dimNames, numVars);

tt = slicefun(@(a) array2table(a, 'VariableNames', varNames, 'DimensionNames', dimNames), ta);
adaptor = resetSizeInformation(ta.Adaptor);
adaptor = copyTallSize(adaptor, ta.Adaptor);
adaptor = setSmallSizes(adaptor, 1);
adaptors = repmat({adaptor}, 1, numel(varNames));
tt.Adaptor = matlab.bigdata.internal.adaptors.TableAdaptor(varNames, adaptors, dimNames);
end
