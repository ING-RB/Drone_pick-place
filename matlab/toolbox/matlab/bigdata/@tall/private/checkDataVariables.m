function dataVars = checkDataVariables(tX, dataVars, fcnName, sortVars)
%checkDataVariables - Validate 'DataVariables' value against tall input tX

% Copyright 2017-2020 The MathWorks, Inc.

if nargin < 4
    sortVars = true;
end
inputClass = tX.Adaptor.Class;
inputIsTabular = any(strcmpi(inputClass, {'table', 'timetable'}));

if ~inputIsTabular
    error(message(['MATLAB:' fcnName ':DataVariablesArray']));
end

if isa(dataVars, 'function_handle')
    % TODO g1553956: Add support for function_handle input to rmmissing,
    % fillmissing, and standardizeMissing
    error(message('MATLAB:bigdata:array:UnsupportedDataVarsFcn'));
end

if isnumeric(dataVars) && ~isreal(dataVars)
    % tabular/subsref allows complex(1) for paren and braces, but not dot.
    % Use colon to slice off any zero complex component
    dataVars = dataVars(:);
end

varNames = getVariableNames(tX.Adaptor);

try
    if isa(dataVars,'vartype')
        dataVars = matlab.internal.math.checkDataVariables(tX.Adaptor.buildSample('double'), dataVars, fcnName);
    else
        [~, dataVars] = matlab.bigdata.internal.util.resolveTableVarSubscript(varNames, dataVars);
        if sortVars
            dataVars = unique(dataVars);
        else
            dataVars = unique(dataVars,'stable');
        end
    end
catch
    error(message(['MATLAB:' fcnName ':DataVariablesTableSubscript']));
end
end