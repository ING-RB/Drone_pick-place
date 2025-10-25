function tt = table(varargin)
%TABLE Build a tall table from tall arrays
%   TT = TABLE(T1,T2,...) creates a tall table TT from tall arrays
%   T1, T2, ... . All arrays must be tall and have the same number of
%   rows.
%
%   TT = TABLE(..., 'VariableNames', {'name1', ..., 'name_M'}) creates a
%   table containing variables that have the specified variable names.
%   The names must be valid MATLAB identifiers, and unique.
%
%   TT = TABLE(..., 'DimensionNames', {'dim1', 'dim2'}) creates a
%   table containing variables that have the specified dimension names.
%   The names must be valid MATLAB identifiers, and unique.
%
%   Limitations:
%   The 'VariableTypes' property is not supported for tall tables.
%
%   See also tall, table.

% Copyright 2015-2023 The MathWorks, Inc.

% Attempt to deal with trailing p-v pairs.
numVars = matlab.bigdata.internal.util.countTableVarInputs(varargin);
varValues = varargin(1:numVars);

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

pnames   = {'VariableNames', 'RowNames', 'DimensionNames'};
dflts    = {             [],         [],               []};
priority = [              0,          0,                0];
[varNames, ~, dimNames, supplied] ...
    = matlab.internal.datatypes.parseArgsTabularConstructors(pnames, dflts, priority, ...
                                                             'MATLAB:table:StringParamNameNotSupported', ...
                                                             args{:});
if supplied.RowNames
    error(message('MATLAB:bigdata:array:TableUnsupportedParam'));
end

if ~supplied.VariableNames
    varNames = arrayfun(@inputname, 1:numVars, 'UniformOutput', false);
    empties = cellfun('isempty', varNames);
    if any(empties)
        varNames(empties) = matlab.internal.tabular.defaultVariableNames(find(empties));
    end
    % Make sure default names or names from inputname don't conflict
    varNames = matlab.lang.makeUniqueStrings(varNames, {}, namelengthmax);
end

if ~supplied.DimensionNames
    rowDimName = getString(message('MATLAB:table:uistrings:DfltRowDimName'));
    varDimName = getString(message('MATLAB:table:uistrings:DfltVarDimName'));
    dimNames = {rowDimName, varDimName};
end

matlab.bigdata.internal.util.checkTableVariableNames(varNames, dimNames, numVars);

% Check for tall
if ~all(cellfun(@istall, varValues))
    error(message('MATLAB:bigdata:array:AllTableArgsTall'));
end

% Now to do the actual work
tt = slicefun(@(varargin) matlab.bigdata.internal.util.makeTabularChunk(...
    @table, varargin, {'VariableNames', varNames, 'DimensionNames', dimNames}), varValues{:});
adaptors = cellfun(@(tx) tx.Adaptor, varValues, 'UniformOutput', false);
unsizedAdaptor = matlab.bigdata.internal.adaptors.TableAdaptor(varNames, adaptors, dimNames);
tt.Adaptor = copySizeInformation(unsizedAdaptor, tt.Adaptor);
end
