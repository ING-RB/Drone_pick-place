function b = convertvars(a,rawvars,rawtype) %#codegen
%CONVERTVARS Convert specified table variables to specified type.

%   Copyright 2020-2021 The MathWorks, Inc.

narginchk(3,3);

coder.internal.assert(coder.internal.isConst(rawtype), ...
    'MATLAB:table:convertvars:NonConstantArg','type');
coder.internal.assert(coder.internal.isConst(rawvars), ...
    'MATLAB:table:convertvars:NonConstantArg','vars');

if isa(rawvars,'function_handle')
    % Function handles are not supported in codegen, so this branch would never
    % compile.
    a_data = a.data;
    nvars = length(a_data);
    isDataVar = zeros(1,nvars);
    for j = 1:nvars, isDataVar(j) = rawvars(a_data{j}); end
    vars = find(isDataVar);
else
    % Subs type and data are passed in to accommodate for vartype
    vars = a.varDim.subs2inds(rawvars,matlab.internal.coder.tabular.private.tabularDimension.subsType.reference,a.data);
end

% If a class name is passed in for type, convert it to the proper function
% handle.

if ~isa(rawtype,'function_handle')
    % Must be scalar text
    coder.internal.assert(matlab.internal.coder.datatypes.isScalarText(rawtype,false), ...
        'MATLAB:table:convertvars:InvalidType');
    
    % Special cases for convenience
    if rawtype == "char"
        % Currently, cellstr function is not supported in codegen, so this will
        % eventually result in an error.
        type = @cellstr;
    elseif rawtype == "cell"
        % Currently, num2cell function is not supported in codegen, so this will
        % eventually result in an error.
        type = @num2cell;
    elseif rawtype == "table"
        % For codegen table requires that the variable names be provided at the
        % time of construction, so to avoid errors use the table construction
        % helper instead of directly calling the table constructor.
        type = @tableConstructionHelper;
    else
        type = str2func(rawtype);
    end 
else
    % This is a dead branch until function handles are supported
    type = rawtype;
end

% Create output tabular and copy every thing except the data
b = a.cloneAsEmpty();
b.metaDim = a.metaDim;
b.varDim = a.varDim;
b.rowDim = a.rowDim;
b.arrayProps = a.arrayProps;
b.data = cell(size(a.data));
convertVar = ismember(1:b.varDim.length,vars);
% Apply conversion function to the variables
for i = 1:b.varDim.length
    if convertVar(i)
        b.data{:,i} = type(a.data{i});
    else
        b.data{:,i} = a.data{i};
    end
end
end

function t = tableConstructionHelper(var)
    % Helper that creates the default variable names for the output table before
    % calling the table constructor. The output table will always have one
    % variable but still use the default variable name generator method instead
    % of hard coding it.
    varnames = matlab.internal.coder.tabular.private.varNamesDim.dfltLabels(1);
    t = table(var,'VariableNames',varnames);
end
