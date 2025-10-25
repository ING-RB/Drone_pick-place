function A = unaryFunHelper(A,fun,requiresSort,mathArgs,supportsDimArg,funName,dropUnits)
%

% UNARYFUNHELPER Helper function to cumulative and unary functions on tabular inputs.
% This function is for internal use only and will change in a future release.
% Do not use this function.

%   Copyright 2022-2024 The MathWorks, Inc.

dim = 1;

if nargin < 5
    % Only the cumulative functions have a dim argument.
    supportsDimArg = false;
end
if nargin < 6
    funName = func2str(fun);
end
if nargin < 7
    dropUnits = true;
end

try
    
    for i = 1:numel(mathArgs)
        if isa(mathArgs{i},"tabular")
            error(message("MATLAB:table:math:TabularOption",i+1,class(mathArgs{i})));
        end
    end
    
    if supportsDimArg
        if ~isempty(mathArgs) && isnumeric(mathArgs{1})
            % If dim argument is provided, it will be the first trailing
            % argument.
            dim = mathArgs{1};
        else
            % If dim argument is not provided, mathArgs should be redefined
            % with the inferred dimension as the first trailing argument. 
            mathArgs = [{dim} mathArgs];
        end
    end

    if A.varDim.length == 0
        % When A has no variables, fun is never applied, so we need to
        % validate mathArgs by calling fun with empty data.
        try
            [vout{1:nargout}] = fun([],mathArgs{:}); %#ok<NASGU>
        catch ME
            m = MException(message("MATLAB:table:math:FunFailed",funName));
            m = m.addCause(ME);
            throw(m);
        end
    end
    
    tabular.validateTableAndDimUnary(A,dim);

    % For unary operations, the general rule is that we concatenate data
    % along the working dimension. When the dim == 1 or dim > 2, the
    % working dimension is always homogenous and does not need an actual
    % concatenation to take place. This makes dim == 2 a special case,
    % since it is the heterogenous dimension.
    if dim == 1 || dim >2
        if dim == 1 && requiresSort && isa(A,'timetable') && ~issorted(A.rowDim.labels)
            % The cumulative functions require that timetable row times be sorted.
            error(message("MATLAB:table:math:UnsortedRowtimes",funName));
        end

        for i = 1:A.varDim.length
            try
                Adata_i = fun(A.data{i},mathArgs{:});
            catch ME
                varname = A.varDim.labels{i};
                m = MException(message("MATLAB:table:math:VarFunFailed",funName,varname));
                m = m.addCause(ME);
                throw(m);
            end
            if ~isequal(size(A.data{i}),size(Adata_i))
                % Function output should match the size of the input.
                error(message("MATLAB:table:math:FunWrongSize"));
            end
            A.data{i} = Adata_i;
        end
    else %if dim == 2
        if A.varDim.hasUnits && ~isscalar(unique(A.varDim.units))
            % Applying function along rows is not allowed unless all units are the same.
            error(message("MATLAB:table:math:RowOperationUnitsMismatch"));
        end

        

        % Horizontally concatenate all the data.
        data = A.extractData(1:A.varDim.length);

        % Repackage data in the table.
        try
            A_data = fun(data,mathArgs{:});
        catch ME
            m = MException(message("MATLAB:table:math:RowFunFailed",funName));
            m = m.addCause(ME);
            throw(m);
        end
        A.data = num2cell(A_data,1);
    end
    
    if dropUnits
        A.varDim = A.varDim.setUnits({});
    end

    % Check for any cross variable incompatibility that could have been introduced
    % due to the type of the variables changing after the unary math operation.
    % Currently, this is only required for eventtables and is a no-op for other
    % tabular types.
    A.validateAcrossVars();
catch ME
    throwAsCaller(ME);
end
