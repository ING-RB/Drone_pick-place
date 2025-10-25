function [b, varargout] = reductionFunHelper(a, fun, args, NameValueArgs)
%

% This function is for internal use only and will change in a
% future release.  Do not use this function.

% Helper for reduction functions.

%   Copyright 2022-2024 The MathWorks, Inc.

arguments
    a, fun, args
    NameValueArgs.FunName = func2str(fun)
    NameValueArgs.DropUnits = false
end
funName = NameValueArgs.FunName;

try
   
    for i = 1:numel(args)
        if isa(args{i},"tabular")
            error(message("MATLAB:table:math:TabularOption",i+1,class(args{i})));
        end
    end

    [dim,workingDim,args] = parseDim(args);
    validateInputs(a,dim,workingDim);
    
    if workingDim == 1
        [b,varargout{1:nargout-1}] = varReduction(a,fun,funName,dim,args);
    elseif workingDim == 2
        [b,varargout{1:nargout-1}] = rowReduction(a,fun,funName,dim,args);
    elseif isequal(workingDim,1:2)
        [b,varargout{1:nargout-1}] = rowAndVarReduction(a,fun,funName,dim,args);
    else % workingDim == [] (i.e. all(dim < 1 | dim > 2) )
        [b,varargout{1:nargout-1}] = noopReduction(a,fun,funName,dim,args);
    end

    % Check for any cross variable incompatibility that could have been introduced
    % due to the type of the variables changing after the reduction operation.
    % Currently, this is only required for eventtables and is a no-op for other
    % tabular types.
    b.validateAcrossVars(); 
catch ME
    throwAsCaller(ME);
end

if NameValueArgs.DropUnits
    b.varDim = b.varDim.setUnits({});
    % Reduction always discards per-variable metadata for optional outputs.
end

end

function [dim, workingDim, args] = parseDim(args)
    % Find the dim in the optional arguments.
    % - args       - the optional args with dim removed.
    % - dim        - the raw dim value passed to the user-facing function (default = 1).
    % - workingDim - used for control flow. workingDim can only have the following values:
    %   - 1     -> Perform a variable reduction         because raw dim contains 1 (or dim was not provided).
    %   - 2     -> Perform a row reduction              because raw dim contains 2.
    %   - [1 2] -> Perform a row and variable reduction because raw dim contains 1 and 2 (or was "all"/'all' or a prefix thereof).
    %   - []    -> Perform a no-op reduction            because raw dim contains neither 1 nor 2.
    
    import matlab.internal.datatypes.isScalarText

    dim = 1;
    workingDim = 1;
    if ~isempty(args)
        if isScalarText(args{1},false)
            if startsWith("all",args{1},IgnoreCase=true)
                dim = "all";
                workingDim = 1:2;
                args = args(2:end);
            end
        elseif isnumeric(args{1})
            if isempty(args{1})
                if isvector(args{1})
                    % Treat 0x1 and 1x0 as empty vecdim -> no-op reduction.
                    dim = args{1};
                    workingDim = [];
                else
                    % Treat non-vector empty dim arguments as invalid for
                    % consistency with most reduction functions on core
                    % types.
                    error(message("MATLAB:getdimarg:invalidDim"));
                end
            else
                dim = args{1};
                workingDim = dim(floor(dim) == dim);                        % filter out non-integer values
                workingDim = unique(workingDim,"sorted");                   % sort and de-dupe
                workingDim = workingDim(1 <= workingDim & workingDim <= 2); % remove values outside the range [1,2]
            end
            args = args(2:end);
        end
    end
end

function validateInputs(a, dim, workingDim)
    tabular.validateTableAndDimUnary(a,dim);

    % Reduction along rows is not allowed unless all units are the same.
    if any(workingDim == 2) && a.varDim.hasUnits && ~isscalar(unique(a.varDim.units))
        error(message("MATLAB:table:math:RowOperationUnitsMismatch"));
    end
end

function [b, varargout] = varReduction(a, fun, funName, dim, args)
    a_data = a.data;
    a_varnames = a.varDim.labels;
    nvars = a.varDim.length;
    if isa(a,"table") && nvars == 0
        validateOptionalArguments(fun,funName,nargout,dim,args);
        [b,varargout{1:nargout-1}] = emptyVarReduction(a);
        return
    end
    
    b_data = cell(1,nvars);
    varargout = {};
    for i = nargout-1:-1:1
        varargout{i} = b_data;
    end
    for jvar = 1:nvars
        varname_j = a_varnames{jvar};
        try
            % Avoid incurring the cost of varargout for the common case of nargout == 1.
            [b_data{jvar},additionalOutputs_jvar{1:nargout-1}] = fun(a_data{jvar},dim,args{:});
            for i = nargout-1:-1:1
                varargout{i}{jvar} = additionalOutputs_jvar{i};
            end
        catch ME
            m = MException(message("MATLAB:table:math:VarFunFailed",funName,varname_j));
            m = m.addCause(ME);
            throw(m);
        end
        validateOutputSize_varReduction(b_data{jvar},additionalOutputs_jvar,funName,varname_j);
    end
    % Check that fun returned equal-length outputs for all vars.
    [b_data, b_height] = tabular.numRowsCheck(b_data);
    for i = 1:numel(varargout)
        tabular.numRowsCheck(varargout{i});
    end

    if isa(a,'timetable') % timetable in -> table out
        % Make sure the generated output var names don't clash with the dim names.
        b_dimnames = table.defaultDimNames; b_dimnames(2) = a.metaDim.labels(2);
        
        % Create a table from function outputs. Discard the input's row
        % times, but preserve all per-variable metadata and the second dim
        % name.
        b = table.init(b_data,b_height,{},nvars,a_varnames,b_dimnames);
        b.arrayProps = a.arrayProps;
        additionalOutputTemplate = b; % Discard per-variable metadata for optional outputs.
        b.varDim = moveProps(b.varDim,a.varDim,1:b.varDim.length,1:a.varDim.length);
    else % table in -> table out
        % Copy the input and overwrite its data with fun's outputs.
        b = a;
        b.data = b_data;
        b.rowDim = b.rowDim.removeLabels();
        
        % Lengthen or shorten the row dim to the output size as necessary.
        a_height = a.rowDim.length;
        if b_height > a_height
            b.rowDim = b.rowDim.lengthenTo(b_height);
        elseif b_height < a_height
            b.rowDim = b.rowDim.shortenTo(b_height);
        end

        % Discard per-variable metadata for optional outputs.
        additionalOutputTemplate = table.init(b_data,b_height,{},nvars,a_varnames,a.metaDim.labels);
        additionalOutputTemplate.arrayProps = b.arrayProps;
    end

    out_customProps = setStructFieldsEmpty(a.varDim.customProps);
    additionalOutputTemplate.varDim = additionalOutputTemplate.varDim.setCustomProps(out_customProps);
    for i = nargout-1:-1:1
        additionalOutputTemplate.data = varargout{i};
        varargout{i} = additionalOutputTemplate;
    end
end

function validateOptionalArguments(fun, funName, nArgOut, dim, args)
    try
        [outputs{1:nArgOut}] = fun([],dim,args{:}); %#ok<NASGU>
    catch ME
        m = MException(message("MATLAB:table:math:FunFailed",funName));
        m = m.addCause(ME);
        throw(m);
    end
end

function [b, varargout] = emptyVarReduction(a)
    % Reduction on an Nx0 input results in a 0x0 output.
    b = a([],[]);

    % No need to discard per-variable metadata for optional outputs
    % because a has no variables.
    for i = nargout-1:-1:1
        varargout{i} = b;
    end
end

function validateOutputSize_varReduction(b_var_data, out, funName, varName)
    % Check that fun returned outputs of length no greater than 1 for a given var.
    if size(b_var_data,1) > 1
        error(message("MATLAB:table:math:VarReductionWrongHeight",funName,varName));
    end
    for i = 1:numel(out)
        if size(out{i},1) > 1
            error(message("MATLAB:table:math:VarReductionWrongHeight",funName,varName));
        end
    end
end

function s = setStructFieldsEmpty(s)
    % Keep field names, but empty the values.
    pn = fieldnames(s);
    for i = 1:numel(pn)
        s.(pn{i}) = [];
    end
end

function [b, varargout] = rowReduction(a, fun, funName, dim, args)
    b_data = cell(1,1);
    varargout = {};
    for i = nargout-1:-1:1
        varargout{i} = b_data;
    end
    
    inArgs = a.extractData(1:a.varDim.length);
    try
        % Avoid incurring the cost of varargout for the common case of nargout == 1.
        [b_data{1},varargout{1:nargout-1}] = fun(inArgs,dim,args{:});
    catch ME
        m = MException(message("MATLAB:table:math:RowFunFailed",funName));
        m = m.addCause(ME);
        throw(m);
    end
    validateOutputSize_rowReduction(b_data,a.rowDim.length,varargout,funName);
    
    % Copy the input, but overwrite its variables with the function's
    % output variables. Preserve the row labels, since the output rows
    % correspond 1:1 to the input rows.
    b = a;
    b.data = b_data; % already enforced one output row per input row

    % Make sure the generated output var name doesn't clash with the dim names.
    b_varnames = matlab.lang.makeUniqueStrings({funName},a.metaDim.labels,namelengthmax);
    
    % Discard per-variable metadata.
    b.varDim = b.varDim.createLike(1,b_varnames);
    a_customProps = a.varDim.customProps;
    a_customProps = setStructFieldsEmpty(a_customProps);
    b.varDim = b.varDim.setCustomProps(a_customProps);

    additionalOutputTemplate = b;
    for i = nargout-1:-1:1
        additionalOutputTemplate.data = varargout(i);
        varargout{i} = additionalOutputTemplate;
    end

    % Preserve units if present.
    if b.varDim.length > 0 && a.varDim.hasUnits
        b_units = unique(a.varDim.units);
        b.varDim = b.varDim.setUnits(b_units);
    end
end

function validateOutputSize_rowReduction(b_data, a_height, out, funName)
    if size(b_data{1},1) ~= a_height
        error(message("MATLAB:table:math:RowReductionWrongHeight",funName));
    end
    if size(b_data{1},2) > 1
        error(message("MATLAB:table:math:ReductionWrongWidth",funName));
    end
    for i = 1:numel(out)
        if size(out{i},1) ~= a_height
            error(message("MATLAB:table:math:RowReductionWrongHeight",funName));
        end
        if size(out{i},2) > 1
            error(message("MATLAB:table:math:ReductionWrongWidth",funName));
        end
    end
end

function [b, varargout] = rowAndVarReduction(a, fun, funName, dim, args)
    nvars = a.varDim.length;
    if isa(a,"table") && nvars == 0
        validateOptionalArguments(fun,funName,nargout,dim,args);
        [b,varargout{1:nargout-1}] = emptyVarReduction(a);
        return
    end
    
    b_data = cell(1,1);
    varargout = {};
    for i = nargout-1:-1:1
        varargout{i} = b_data;
    end
    
    inArgs = a.extractData(1:nvars);
    try
        % Avoid incurring the cost of varargout for the common case of nargout == 1.
        [b_data{1},varargout{1:nargout-1}] = fun(inArgs,dim,args{:});
    catch ME
        m = MException(message("MATLAB:table:math:FunFailed",funName));
        m = m.addCause(ME);
        throw(m);
    end
    b_height = validateOutputSize_rowAndVarReduction(b_data,varargout,funName);
    
    if isa(a,'timetable') % timetable in -> table out
        % Make sure the generated output var names don't clash with the dim names.
        b_dimnames = table.defaultDimNames; b_dimnames(2) = a.metaDim.labels(2);
        b_varnames = matlab.lang.makeUniqueStrings({funName},b_dimnames,namelengthmax);
        
        % Create a table from function outputs. Discard the input's row
        % times and all per-variable metadata, but preserve the second dim
        % name.
        b = table.init(b_data,b_height,{},1,b_varnames,b_dimnames);
        b.arrayProps = a.arrayProps;
    else % table in -> table out
        % Copy the input and overwrite its data with fun's outputs.
        b = a;
        b.data = b_data;
        b.rowDim = b.rowDim.removeLabels();
        
        % Lengthen or shorten the row dim to the output size as necessary.
        a_height = a.rowDim.length;
        if b_height > a_height
            b.rowDim = b.rowDim.lengthenTo(b_height);
        elseif b_height < a_height
            b.rowDim = b.rowDim.shortenTo(b_height);
        end

        % Make sure the generated output var name doesn't clash with the dim names.
        b_varnames = matlab.lang.makeUniqueStrings({funName},a.metaDim.labels,namelengthmax);
        
        % Update the var names, but discard per-variable metadata.
        b.varDim = matlab.internal.tabular.private.varNamesDim(1,b_varnames);
    end

    b_customProps = setStructFieldsEmpty(a.varDim.customProps);
    b.varDim = b.varDim.setCustomProps(b_customProps);

    additionalOutputTemplate = b;
    for i = nargout-1:-1:1
        additionalOutputTemplate.data = varargout(i);
        varargout{i} = additionalOutputTemplate;
    end

    % Preserve units if present.
    if b.varDim.length > 0 && a.varDim.hasUnits
        b_units = unique(a.varDim.units);
        b.varDim = b.varDim.setUnits(b_units);
    end
end

function b_height = validateOutputSize_rowAndVarReduction(b_data, out, funName)
    % Check that fun returned equal-length outputs for all vars.
    [~,b_height] = tabular.numRowsCheck(b_data);
    if b_height > 1
        error(message("MATLAB:table:math:ReductionWrongHeight",funName));
    end
    if numel(b_data) > 0 && size(b_data{1},2) > 1
        error(message("MATLAB:table:math:ReductionWrongWidth",funName));
    end
    for i = 1:numel(out)
        if size(out{i},1) > 1
            error(message("MATLAB:table:math:ReductionWrongHeight",funName));
        end
        if size(out{i},2) > 1
            error(message("MATLAB:table:math:ReductionWrongWidth",funName));
        end
    end
end

function [a, varargout] = noopReduction(a, fun, funName, dim, args)
    a_data = a.data;
    a_height = a.rowDim.length;
    nvars = a.varDim.length;
    if nvars == 0
        validateOptionalArguments(fun,funName,nargout,dim,args);
        [a,varargout{1:nargout-1}] = emptyNoopReduction(a);
        return
    end

    varargout = {};
    for i = nargout-1:-1:1
        varargout{i} = a_data;
    end
    for jvar = 1:numel(a_data)
        try
            % Avoid incurring the cost of varargout for the common case of nargout == 1.
            [a_data{jvar},additionalOutputs_jvar{1:nargout-1}] = fun(a_data{jvar},dim,args{:});
            for i = nargout-1:-1:1
                varargout{i}{jvar} = additionalOutputs_jvar{i};
            end
        catch ME
            varname_j = a.varDim.labels{jvar};
            m = MException(message("MATLAB:table:math:VarFunFailed",funName,varname_j));
            m = m.addCause(ME);
            throw(m);
        end
    end
    a.data = validateOutputHeight_noopReduction(a_data,a_height,varargout,funName);
    
    if nargout-1 > 0
        % Discard per-variable metadata for optional outputs.
        additionalOutputTemplate = a;
        a_customProps = a.varDim.customProps;
        a_customProps = setStructFieldsEmpty(a_customProps);
        additionalOutputTemplate_varDim = a.varDim.createLike(a.varDim.length,a.varDim.labels);
        additionalOutputTemplate.varDim = additionalOutputTemplate_varDim.setCustomProps(a_customProps);
        
        for i = nargout-1:-1:1
            additionalOutputTemplate.data = varargout{i};
            varargout{i} = additionalOutputTemplate;
        end
    end
end

function [b, varargout] = emptyNoopReduction(a)
    % Reduction on an Nx0 input results in a 0x0 output.
    b = a;

    % No need to discard per-variable metadata for optional outputs
    % because a has no variables.
    for i = nargout-1:-1:1
        varargout{i} = b;
    end
end

function b_data = validateOutputHeight_noopReduction(b_data, a_height, out, funName)
    [~,b_height] = tabular.numRowsCheck(b_data);
    if b_height ~= a_height
        error(message("MATLAB:table:math:NoopReductionWrongHeight",funName));
    end
    for i = 1:numel(out)
        [~,out_height] = tabular.numRowsCheck(out{i});
        if out_height ~= a_height
            error(message("MATLAB:table:math:NoopReductionWrongHeight",funName));
        end
    end
end
