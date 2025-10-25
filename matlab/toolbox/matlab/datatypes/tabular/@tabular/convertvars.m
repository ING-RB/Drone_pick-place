function a = convertvars(a,vars,type)
%

%   Copyright 2018-2024 The MathWorks, Inc.

% Change vars to indices

% Avoid unsharing of shared-data copy across function call boundary
import matlab.lang.internal.move
import matlab.internal.datatypes.throwInstead
narginchk(3,3);

if isa(vars,'function_handle')
    a_data = a.data;
    nvars = length(a_data);
    isDataVar = zeros(1,nvars);
    try
        for j = 1:nvars, isDataVar(j) = vars(a_data{j}); end
    catch ME
        throwInstead(ME, ...
            "MATLAB:matrix:singleSubscriptNumelMismatch", ...
            "MATLAB:table:convertvars:InvalidVars");
    end
    vars = find(isDataVar);
else
    try
        % Call tabular subs2inds to accommodate for vartype.
        vars = a.subs2inds(vars,'varDim'); 
    catch ME
        a.subs2indsErrorHandler(vars,ME,'convertvars');
    end
end

% If a class name is passed in for type, convert it to the proper function
% handle.

if ~isa(type,'function_handle')
    if ~matlab.internal.datatypes.isScalarText(type,false) % Do not allow empty
        error(message('MATLAB:table:convertvars:InvalidType'));
    end
    
    % Special cases for convenience
    if type == "char"
        % Throw a warning that we are using cellstr instead of char.
        warning(message('MATLAB:table:convertvars:ConvertCharWarning'));
        type = @cellstr;
    elseif type == "cell"
        type = @num2cell;
    else
        type = str2func(type);
    end  
end

% Apply conversion function to the variables
a_varDim_labels = a.varDim.labels; %v save this for err handling in case a is cleared by move
try
    for i = 1:length(vars)
        rhs_i = type(a.data{vars(i)});
        % Explicitly call dotAssign to always dispatch to subscripting code, even
        % when the variable name matches an internal tabular property/method.
        a = move(a).dotAssign(vars(i),rhs_i); % a.(vars(i)) = rhs_i
    end
catch ME
    ME = throwInstead(ME,"MATLAB:table:RowDimensionMismatch","MATLAB:table:convertvars:IncorrectNumRows"); % becomes a cause below
    if strcmp(ME.identifier,"MATLAB:UndefinedFunction")
        % The ID MATLAB:UndefinedFunction might be constructed from any one of several
        % different msg texts. In any case, wrap it in a convertvars-specific error.
        ME = addCause(MException(message('MATLAB:table:convertvars:InvalidTextType',a_varDim_labels{vars(i)},func2str(type))),ME);
    else
        % Wrap any other error in a convertvars-specific error.
        ME = addCause(MException(message('MATLAB:table:convertvars:VariableTypesConversionFailed',a_varDim_labels{vars(i)},func2str(type))),ME);
    end
    throwAsCaller(ME);
end
