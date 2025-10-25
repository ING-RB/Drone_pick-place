function b = varfun(fun,a,varargin) %#codegen
%VARFUN Apply a function to each variable of a table or timetable.

%   Copyright 2020-2021 The MathWorks, Inc.

coder.extrinsic('setdiff','matlab.lang.makeUniqueStrings','namelengthmax',...
                'append','subsref','substruct','matlab.internal.coder.datatypes.varfunEmptyConstr');

% The function must be compile time constant.
coder.internal.assert(coder.internal.isConst(fun),'MATLAB:table:varfun:NonConstantFun');

% Varfun does not support varsize inputs
coder.internal.assert(coder.internal.isConst(size(a)),'MATLAB:table:varfun:VarsizeInput');

% Set default output for table or timetable.
if isa(a, 'timetable')
    dfltOut = 4; % timetable
    allowedOutputFormats = {'uniform' 'table' 'cell' 'timetable'};
else
    dfltOut = 2; % table
    allowedOutputFormats = {'uniform' 'table' 'cell'};
end

pnames = {'GroupingVariables' 'InputVariables' 'OutputFormat' 'ErrorHandler'};
poptions = struct( ...
    'CaseSensitivity',false, ...
    'PartialMatching','unique', ...
    'StructExpand',false);
supplied = coder.internal.parseParameterInputs(pnames,poptions,varargin{:});

groupVarsRaw = coder.internal.getParameterValue(supplied.GroupingVariables,[],varargin{:});
inputVars = coder.internal.getParameterValue(supplied.InputVariables,[],varargin{:});
outputFormat = coder.internal.getParameterValue(supplied.OutputFormat,dfltOut,varargin{:});

% Error handler is not supported in codegen.
coder.internal.assert(supplied.ErrorHandler == 0,...
    'MATLAB:table:varfun:ErrorHandlerNotSupported');

% outputFormat decides the output datatype, so it needs to be constant.
coder.internal.assert(coder.internal.isConst(outputFormat),...
    'MATLAB:table:varfun:NonConstantParamValue','OutputFormat');

% Grouping variables must be constant.
coder.internal.assert(coder.internal.isConst(groupVarsRaw),...
    'MATLAB:table:varfun:NonConstantParamValue','GroupingVariables');

% Input variables must be constant.
coder.internal.assert(coder.internal.isConst(inputVars),...
    'MATLAB:table:varfun:NonConstantParamValue','InputVariables');

% Do a grouped calculation if GroupingVariables is supplied, even if it's empty
% (the latter is the same as ungrouped but with a GroupCounts variable).
grouped = (supplied.GroupingVariables ~= 0);
if grouped
    groupVars = a.getVarOrRowLabelIndices(groupVarsRaw);
    isRowLabels = (groupVars == 0);
    groupByRowLabels = any(isRowLabels);
else
    groupByRowLabels = false;
end

if ~supplied.InputVariables
    if grouped
        % varDim length and groupVars are compile time constants so
        dataVars = coder.const(setdiff(1:a.varDim.length,groupVars));
    else
        dataVars = 1:a.varDim.length;
    end
elseif isa(inputVars,'function_handle')
    a_data = a.data;
    nvars = length(a_data);
    isDataVar = false(1,nvars);
    for j = 1:nvars, isDataVar(j) = inputVars(a_data{j}); end
    dataVars = find(isDataVar);
    % Check that the function handle gives a compile time constant value for
    % dataVars.
    coder.internal.assert(coder.internal.isConst(isDataVar),...
    'MATLAB:table:varfun:NonConstantInputVarsFun','InputVariables');
else
    dataVars = a.varDim.subs2inds(inputVars);
end
dataVars = coder.const(dataVars);
a_data = a.data;
a_varnames = a.varDim.labels;
ndataVars = length(dataVars);

if supplied.OutputFormat
    outputFormatIdx = matlab.internal.coder.datatypes.getChoice(outputFormat,allowedOutputFormats,a.specifyInvalidOutputFormatID('varfun'));
else
    outputFormatIdx = dfltOut;
end
uniformOutput = (outputFormatIdx == 1);
tableOutput = (outputFormatIdx == 2);
timetableOutput = (outputFormatIdx == 4);
tabularOutput = (outputFormatIdx == 2 || outputFormatIdx == 4);

coder.internal.assert(isa(fun,'function_handle'),'MATLAB:table:varfun:InvalidFunction');
funName = func2str(fun);

% Create variable names for the output table based on the input
if tabularOutput
    % Anonymous/nested functions lead to unusable function names, use a default
    if startsWith(funName,'@(')
        funPrefix = 'Fun';
    else
        funPrefix = funName;
    end
    subscripts = coder.const(substruct('()',{dataVars}));
    names = coder.const(append(funPrefix,'_',coder.const(subsref(a_varnames,subscripts))));
    b_dataVarNames = a.varDim.makeValidName(names,'warnLength');
end

if grouped
    [group,grpNames,grpRowLoc] = a.table2gidx(groupVars); % leave out categories not present in data
    nrows = a.rowDimLength;
    if coder.internal.isConstTrue(isempty(group))
        % If groups is empty, then ngroups would be zero. Since grpNames will
        % always be varsize, set ngroups explicitly to avoid indexing into empty
        % errors later on.
        ngroups = 0;
    else
        ngroups = length(grpNames);
    end
    grpRows = matlab.internal.coder.datatypes.getGroups(group,ngroups);
    grpCountsRaw = histc(group,1:ngroups); %#ok<HISTC>
    grpCounts = grpCountsRaw(:);
    
    if uniformOutput || tabularOutput
        % Each cell will contain the result from applying FUN to one variable,
        % an ngroups-by-.. array with one row for each group's result
        b_data = cell(1,ndataVars);
    else % cellOutput
        % Each cell will contain the result from applying FUN to one group
        % within one variable
        b_data = coder.nullcopy(cell(ngroups,ndataVars));
    end
    
    % Each cell will contain the result from applying FUN to one group
    % within the current variable
    
    
    if timetableOutput && ~groupByRowLabels
        outTime = coder.nullcopy(cell(nrows,1));
        for i = ngroups+1:nrows
            % Fill the elements after ngroups with values whose type is the same
            % as the rowDim labels and size is zero for the first dimension.
            % This will ensure that vertcating these values with others in the
            % cell array won't affect the output.
            outTime{i} = a.rowDim.labels([],:);
        end
    end
    grpNumRows = ones(1,ngroups); % need this even when ndataVars is 0
    for jvar = 1:ndataVars
        % Later on we would have to vertcat all the values obtained by unpacking
        % the outVals cell array. Since ngroups will not be known at compile
        % time and codegen does not allow unpacking varsize cell arrays, we
        % create outVals to be a fixed size nrows x 1 cell array. We would later
        % on fill all the elements after ngroups with dummy values that do not
        % affect the output of vertcat.
        outVals = coder.nullcopy(cell(nrows,1));
        jj = dataVars(jvar);
        varname_j = a_varnames{jj};
        for igrp = 1:ngroups
            inArg = matlab.internal.coder.tabular.selectRows(a_data{jj},grpRows{igrp});
            outVals{igrp} = fun(inArg);
        end
        tmp = fun(a_data{jj});
        sz = size(tmp);
        sz(1) = 0;
        for igrp = ngroups+1:nrows
            % Fill the elements after ngroups with values whose type is the same
            % as all the previous values and size is zero for the first
            % dimension and same for all the other dimensions. This will ensure
            % that vertcating these values with others in the cell array won't
            % affect the output.
            if ~isa(tmp,'matlab.internal.coder.tabular')
                outVals{igrp} = reshape(tmp([]), sz); 
            else
                % For tabular directly use indexing since it does not have a
                % reshape method.
                outVals{igrp} = tmp([],:);
            end
        end
        if coder.internal.isConstTrue(ngroups == 0)
            % If not grouping by anything then apply method directly, consistent
            % with groupsummary behavior. outVals could be non-empty, but
            % construct an empty for the output because when there are no
            % groups, the function should not really be invoked. Build output of
            % the right size empty of the class of outVals.
            outValsClass = class(fun(a_data{jj}));
            if uniformOutput
                % Uniform output requires a 0xN array of the right type, with as
                % many columns as there are data vars in the input tabular, so
                % create a 0x1 for each data var.
                b_data{jvar} = coder.const(matlab.internal.coder.datatypes.varfunEmptyConstr(outValsClass,[0,1]));
            elseif tabularOutput
                % Tabular output requires a 0xN tabular containing as many vars
                % of the right type as there are data vars in the input, but
                % each var can be 0x0.
                b_data{jvar} = coder.const(matlab.internal.coder.datatypes.varfunEmptyConstr(outValsClass,[0,0]));
            else % cell
                % Cell output requires a 0xN cell containing as many columns as
                % there are data vars in the input, but it has no cells, so no
                % need to fill it with anything.
            end
        else % ngroups > 0
            if jvar == 1
                if coder.internal.isConstTrue(ngroups <= 0)
                    uniformClass = coder.const('');
                else
                    uniformClass = coder.const(class(outVals{1}));
                end
            end
            
            if uniformOutput
                % For each group of rows, fun's output must have the same type across all variables.
                b_data{jvar} = vertcatWithUniformScalarCheck(outVals,uniformClass,funName,varname_j,ngroups);
            elseif tabularOutput
                % For each group of rows, fun's output must have the same number of rows across
                % all variables. Only do this the first time through the loop over variables.
                if jvar == 1
                    for igrp = 1:ngroups
                        grpNumRows(igrp) = size(outVals{igrp},1); 
                        if timetableOutput && ~groupByRowLabels
                            % Save the leading row times for each group, as many as there are output
                            % rows for each group.
                            
                            coder.internal.assert(grpNumRows(igrp) <= size(grpRows{igrp},1),...
                                'MATLAB:table:varfun:TimetableCannotGrow',funName);
                            
                            outTime{igrp} = a.rowDim.labels(grpRows{igrp}(1:grpNumRows(igrp)));
                        end
                    end
                end
                b_data{jvar} = vertcatWithNumRowsCheck(outVals,grpNumRows,funName,varname_j,ngroups);                
            else % cellOutput
                % If the values being added to the cell array output do not have the
                % same type, the assignment below would result in an error since
                % b_data would be a varsize heterogeneous cell array. So check the
                % types before the assignment and throw a helpful error if the types
                % do not match. When the number of rows is zero, types do not
                % matter.
                if nrows > 0
                   coder.internal.assert(isa(outVals{1},uniformClass),'MATLAB:table:varfun:GroupedMixedTypes');
                end
                for i = 1:ngroups
                    b_data{i,jvar} = outVals{i};
                end
            end
        end
    end
    
    if uniformOutput
        if coder.internal.isConstTrue(ndataVars == 0)
            b = zeros(ngroups,0);
        else
            b = [b_data{:}]; % already validated: all ngroups-by-1, same class
        end
    elseif tabularOutput
        % Create the output by first concatenating the unique grouping var combinations, one row
        % per group, and the group counts. Replicate to match the number of rows from the function
        % output for each group, and concatenate that with the function output.
        
        % Get the grouping variables for the output from the first row in each group of
        % rows in the input. If the grouping vars include input's row labels, i.e.
        % any(groupVars==0), the row labels part of the "unique grouping var combinations"
        % are automatically carried over.
        
        % Only do the indexing below if necessary to avoid cases when
        % parenReference might end up generating non-const output.
        if groupByRowLabels
            groupVarsExceptRowLabels = groupVars(~isRowLabels);
        else
            groupVarsExceptRowLabels = groupVars;
        end
        
        bgRaw = parenReference(a,grpRowLoc,groupVarsExceptRowLabels);
        
        if tableOutput && isa(a,'timetable')
            % Convert to a table, discarding the row times but preserving the grouping
            % variable metadata and the second dim name. The generated output data
            % var names are unique'd against the grouping var and dim names below.
            newDimNames = {table.defaultDimNames{1}, a.metaDim.labels{2}};
            bg0 = table.init(bgRaw.data, ...
                            bgRaw.rowDim.length, {}, ...
                            bgRaw.varDim.length, bgRaw.varDim.labels, ...
                            newDimNames);
            varDim = bg0.varDim.moveProps(a.varDim,groupVarsExceptRowLabels,find(~isRowLabels));
            bg0 = bg0.updateTabularProperties(varDim,[],[],a.arrayProps);
        else
            bg0 = bgRaw;
        end
        if bg0.rowDim.requireUniqueLabels
            assert(~bg0.rowDim.requireLabels)
            % Remove existing row names. Could assign row names using grpNames, but when the
            % function returns multiple rows (e.g. a "within-groups" transformation
            % function), ensuring that the row names are unique is time-consuming, and in
            % any case group names are really only useful when there is only one grouping
            % variable.
            bg1 = bg0.updateTabularProperties([],[],bg0.rowDim.createLike(bg0.rowDimLength,{}),[]);
            if groupByRowLabels
                % When grouping by row labels, add them as an explicit grouping
                % variable in the output table. There's no name collision possible
                % between that and the other grouping vars because a's var and dim
                % names are already unique. But if the input was a table, there's a
                % guaranteed collision between that added grouping var and the existing
                % row dim name (also possible if the input was a timetable whose row
                % times are named 'Row' and output type is 'table'). Modify the
                % existing row labels dim name if necessary to avoid the collision.
                if iscellstr(a.rowDim.labels)
                    rowLabels = matlab.internal.coder.datatypes.cellstr_parenReference(a.rowDim.labels,grpRowLoc);
                else
                    rowLabels = a.rowDim.labels(grpRowLoc);
                end
                % In MATLAB metaDim.checkAgainstVarLabels resolves name conflict
                % but in codegen, it errors, so for now explicitly resolve
                % conflict over here.
                gvnames = coder.const(feval('horzcat',bg1.varDim.labels,a.metaDim.labels{1}));
                dimnames = coder.const(matlab.lang.makeUniqueStrings(bg1.metaDim.labels,gvnames,namelengthmax));
                metaDim = matlab.internal.coder.tabular.private.metaDim(2,dimnames);
                bg2 = bg1.updateTabularProperties([],metaDim,[],[]);
                bg = addvars(bg2,rowLabels,'NewVariableNames',a.metaDim.labels{1});
                if ~isscalar(groupVars) 
                    reord = repmat(bg.varDim.length,1,bg.varDim.length);
                    reord(~isRowLabels) = 1:sum(~isRowLabels);
                    bg = parenReference(bg,':',reord);
                end
            else
                bg = bg1;
            end
        else
            bg = bg0;
        end
        
        % Replicate rows of the grouping vars and the group count var to match the
        % number of rows in the function output for each group.
        bg = parenReference(bg,repelem(1:ngroups,grpNumRows),':');
        grpCounts = grpCounts(repelem(1:ngroups,grpNumRows),1);
        
        if timetableOutput && ~groupByRowLabels && any(grpNumRows > 1)
            % When there are multiple rows per group in the output, subsrefParens will have
            % replicated values of the first row time within each group. That's correct
            % when grouping by time, but otherwise use the "leading" row times saved earlier.
            b_time = vertcat(outTime{:});
            bg.rowDim = bg.rowDim.setLabels(b_time,[],length(b_time));
        end
        
        % Make sure that constructed var names don't clash with the grouping var names
        % or the dim names.
        vnames = coder.const(feval('horzcat',{'GroupCount'},b_dataVarNames));
        avoidVarNames = coder.const(feval('horzcat',bg.metaDim.labels,bg.varDim.labels));
        vnames = coder.const(matlab.lang.makeUniqueStrings(vnames,avoidVarNames,namelengthmax));
        
        numGrpVars = bg.varDim.length;
        data = coder.nullcopy(cell(numGrpVars+length(vnames),1));
        % Equivalent to data = [bg.data {grpCounts} b_data]
        for i = 1:length(data)
            if i <= numGrpVars
                data{i} = bg.data{i};
            elseif i == numGrpVars + 1
                data{i} = grpCounts;
            else
                data{i} = b_data{i-(numGrpVars+1)};
            end
        end
        varDim = bg.varDim.lengthenTo(numGrpVars+length(vnames),vnames);
        b = updateTabularProperties(bg,varDim,[],[],[],data);
    else % cellOutput
        b = b_data;
    end  
else % ungrouped
    b_data = cell(1,ndataVars);
    for jvar = 1:ndataVars
        jj = dataVars(jvar);
        b_data{jvar} = fun(a_data{jj});
    end
    if uniformOutput
        varNames = coder.nullcopy(cell(1,ndataVars));
        for i = 1:ndataVars
            varNames{i} = a_varnames{dataVars(i)};
        end
        b = horzcatWithUniformScalarCheck(b_data,funName,varNames);
    elseif isa(a,'timetable') && tableOutput % table output from a timetable; ungrouped case
        % Make sure the generated output var names don't clash with the dim names.
        b_dimnames = {table.defaultDimNames{1}, a.metaDim.labels{2}};
        b_varnames = coder.const(matlab.lang.makeUniqueStrings(...
            b_dataVarNames,coder.const(b_dimnames),namelengthmax));
        
        % Check that fun returned equal-length outputs for all vars, and create a table
        % from those outputs. Discard the input's row times and all per-variable metadata,
        % but preserve the second dim name.
        [b_data,b_height] = numRowsCheck(b_data);
        b = table.init(b_data, ...
                       b_height, {}, ...
                       ndataVars, b_varnames, ...
                       b_dimnames);
        b = b.updateTabularProperties([],[],[],a.arrayProps);
        
        % Custom properties are not supported in codegen, so do not have to
        % worry about copying them.
    elseif tabularOutput % table in -> table out, or timetable in -> timetable out
        if ndataVars > 0
            % Check that fun returned equal-length outputs for all vars, then copy the
            % input and overwrite its data with fun's outputs.
            b = a.cloneAsEmpty();
            b.metaDim = a.metaDim;
            b.arrayProps = a.arrayProps;
            [b.data,b_height] = numRowsCheck(b_data);
            
            % Update the var names, but discard per-variable metadata. Make sure the
            % generated output var names don't clash with the dim names.
            b_varnames = coder.const(matlab.lang.makeUniqueStrings(b_dataVarNames,a.metaDim.labels,namelengthmax));
            b.varDim = matlab.internal.coder.tabular.private.varNamesDim(length(b_varnames),b_varnames);
            
            % Custom properties are not supported in codegen, so do not have to
            % worry about copying them.
            
            % In general the output rows need not correspond to the input rows,
            % but if the output requires row labels (i.e. a timetable), preserve
            % as many as needed from the input (a safe bet in most cases).
            % Otherwise discard the input's row labels.
            a_height = a.rowDimLength;
            if a.rowDim.requireLabels % timetable in -> timetable out
                coder.internal.errorIf(b_height > a_height, ...
                    'MATLAB:table:varfun:TimetableCannotGrow',funName);
                b_rowDim = a.rowDim;
            else % table in -> table out
                b_rowDim = a.rowDim.createLike(a.rowDimLength,{});
            end
            % Lengthen or shorten the row dim to the output size as necessary.
            if coder.internal.isConstTrue(b_height == a_height)
                b.rowDim = b_rowDim;
            elseif b_height <= a_height
                b.rowDim = b_rowDim.shortenTo(b_height);
            else
                b.rowDim = b_rowDim.lengthenTo(b_height);
            end
        else
            % Ungrouped varfun on an Nx0 input results in a 0x0 output.
            b = parenReference(a,[],[]);
        end
    else % cellOutput
        b = b_data;
    end
end


%-------------------------------------------------------------------------------
function b_data = horzcatWithUniformScalarCheck(b_data,funName,varnames)
nvars = length(b_data);
if nvars > 0
    for jvar = 1:nvars
        coder.internal.assert(isscalar(b_data{jvar}), ...
            'MATLAB:table:varfun:NotAScalarOutput',funName,varnames{jvar});
        if jvar == 1
            uniformClass = class(b_data{1});
        else
            c = class(b_data{jvar});
            coder.internal.assert(isa(b_data{jvar},uniformClass), ...
                'MATLAB:table:varfun:MismatchInOutputTypes',funName,c,uniformClass,varnames{jvar});
        end
    end
    b_data = horzcat(b_data{:});
else
    % fun is assumed to return a scalar, so in general this function returns a row
    % vector, and this empty edge case should be continuous as a 1x0. If there are
    % no vars, then fun has not been applied to anything, so no way to know what type
    % fun would return. Default to double.
    b_data = zeros(1,0);
end


%-------------------------------------------------------------------------------
function out = vertcatWithUniformScalarCheck(outVals,uniformClass,funName,varname,ngroups)
coder.internal.prefer_const(ngroups);
for igrp = 1:ngroups
    coder.internal.assert(isscalar(outVals{igrp}),...
        'MATLAB:table:varfun:NotAScalarOutputGrouped',funName,igrp,varname);
    coder.internal.assert(isa(outVals{igrp},uniformClass),...
        'MATLAB:table:varfun:MismatchInOutputTypesGrouped',funName,...
        class(outVals{igrp}),uniformClass,igrp,varname);
end
out = vertcat(outVals{:});


%-------------------------------------------------------------------------------
function out = vertcatWithNumRowsCheck(outVals,grpNumRows,funName,varname,ngroups)
coder.internal.prefer_const(ngroups);
for igrp = 1:ngroups
    coder.internal.assert(size(outVals{igrp},1) == grpNumRows(igrp),...
        'MATLAB:table:varfun:GroupRowsMismatch',funName,igrp,varname);
end
out = vertcat(outVals{:});


%-------------------------------------------------------------------------------
function [outVals,n] = numRowsCheck(outVals)
nvars = length(outVals);
if nvars > 0
    n = size(outVals{1},1);
    for j = 2:nvars
        coder.internal.assert(size(outVals{j},1) == n, 'MATLAB:table:UnequalVarLengths');
    end
else
    n = 0;
end
