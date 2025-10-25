function b = varfun(fun,a,varargin)
%

%   Copyright 2012-2024 The MathWorks, Inc.

import matlab.internal.datatypes.ordinalString
import matlab.internal.tabular.selectRows

if ~isa(fun,'function_handle')
    error(message('MATLAB:table:varfun:InvalidFunction'));
end

% Set default output for each input type and also set the list of allowed
% OutputFormats (for example, tables dont support timetable as the
% OutputFormat).
% Here table is a redundant OutputFormat for table inputs but it allows
% converting timetables and eventtables into tables. Similarly, timetable is a
% redundant OutputFormat for timetable inputs but it allows converting
% eventtables into timetables.
if isa(a, 'timetable') % timetable or eventtable input
    dfltOut = 5; % timetable
    allowedOutputFormats = {'auto' 'uniform' 'table' 'cell' 'timetable'};
else
    dfltOut = 3; % table
    allowedOutputFormats = {'auto' 'uniform' 'table' 'cell'};
end

pnames = {'GroupingVariables' 'InputVariables' 'OutputFormat'   'ErrorHandler'};
dflts =  {                []               []        dfltOut               [] };
[groupVars,dataVars,outputFormat,errHandler,supplied] ...
    = matlab.internal.datatypes.parseArgs(pnames, dflts, varargin{:});

% Do a grouped calculation if GroupingVariables is supplied, even if it's empty
% (the latter is the same as ungrouped but with a GroupCounts variable).
grouped = supplied.GroupingVariables;
if grouped
    groupVars = a.getVarOrRowLabelIndices(groupVars,false,true);
    isRowLabels = (groupVars == 0);
    groupByRowLabels = any(isRowLabels);
else
    groupByRowLabels = false;
end

if ~supplied.InputVariables
    if grouped
        dataVars = setdiff(1:a.varDim.length,groupVars);
    else
        dataVars = 1:a.varDim.length;
    end
elseif isa(dataVars,'function_handle')
    a_data = a.data;
    nvars = length(a_data);
    try
        isDataVar = zeros(1,nvars);
        for j = 1:nvars, isDataVar(j) = dataVars(a_data{j}); end
    catch ME
        matlab.internal.datatypes.throwInstead(ME, ...
            'MATLAB:matrix:singleSubscriptNumelMismatch', ...
            'MATLAB:table:varfun:InvalidInputVariablesFun');
    end
    dataVars = find(isDataVar);
else
    try
        dataVars = a.varDim.subs2inds(dataVars);
    catch ME
        a.subs2indsErrorHandler(dataVars,ME,'varfun');
    end
end
a_data = a.data;
a_varnames = a.varDim.labels;
ndataVars = length(dataVars);

if supplied.OutputFormat
    outputFormat = matlab.internal.datatypes.getChoice(outputFormat,allowedOutputFormats,a.specifyInvalidOutputFormatID("varfun"));
    autoOutput = (outputFormat == 1);
    if autoOutput
        % auto means output the same type as input.
        outputFormat = dfltOut;
    end
else
    % auto is the default when OutputFormat is not specified. The value of the
    % outputFormat will already be set to 3 (table) for table inputs and 5 (timetable)
    % for timetable or eventtable inputs.
    autoOutput = true;
end
uniformOutput = (outputFormat == 2);
tableOutput = (outputFormat == 3);
timetableOutput = (outputFormat == 5);
tabularOutput = (outputFormat == 3 || outputFormat == 5);


funName = func2str(fun);

if ~supplied.ErrorHandler
    errHandler = @(s,varargin) dfltErrHandler(grouped,funName,s,varargin{:});
end

% Create variable names for the output table based on the input
if tabularOutput
    % Anonymous/nested functions lead to unusable function names, use a default
    if isvarname(funName)
        funPrefix = funName;
    else
        funPrefix = 'Fun';
    end
    b_dataVarNames = a.varDim.makeValidName(append(funPrefix,'_',a_varnames(dataVars)),'warnLength');
end

if grouped
    [group,grpNames,grpRowLoc] = a.table2gidx(groupVars); % leave out categories not present in data
    ngroups = length(grpNames);
    grpRows = matlab.internal.datatypes.getGroups(group,ngroups);
    grpCounts = histc(group,1:ngroups); grpCounts = grpCounts(:); %#ok<HISTC>
    
    if uniformOutput || tabularOutput
        % Each cell will contain the result from applying FUN to one variable,
        % an ngroups-by-.. array with one row for each group's result
        b_data = cell(1,ndataVars);
    else % cellOutput
        % Each cell will contain the result from applying FUN to one group
        % within one variable
        b_data = cell(ngroups,ndataVars);
    end
    
    % Each cell will contain the result from applying FUN to one group
    % within the current variable
    outVals = cell(ngroups,1);
    if timetableOutput && ~groupByRowLabels
        outTime = cell(ngroups,1);
    end
    grpNumRows = ones(1,ngroups); % need this even when ndataVars is 0
    uniformClass = '';
    for jvar = 1:ndataVars
        jj = dataVars(jvar);
        varname_j = a_varnames{jj};
        if ngroups == 0
            % If not grouping by anything then apply method directly, consistent
            % with groupsummary behavior.
            try
                outVals = fun(a_data{jj});
            catch
                % For compatibility, if the function fails, rather than being
                % strict just return an empty double.
                outVals = [];
            end

            % outVals could be non-empty, but construct an empty for the output
            % because when there are no groups, the function should not really
            % be invoked. Build output of the right size empty of the class of
            % outVals.
            emptyConstr = str2func(class(outVals)+".empty");
            if uniformOutput
                % Uniform output requires a 0xN array of the right type, with as
                % many columns as there are data vars in the input tabular, so
                % create a 0x1 for each data var.
                b_data{jvar} = emptyConstr(0,1);
            elseif tabularOutput
                % Tabular output requires a 0xN tabular containing as many vars
                % of the right type as there are data vars in the input, but
                % each var can be 0x0.
                b_data{jvar} = emptyConstr(0,0);
            else % cell
                % Cell output requires a 0xN cell containing as many columns as
                % there are data vars in the input, but it has no cells, so no
                % need to fill it with anything.
            end
        else % ngroups > 0
            for igrp = 1:ngroups
                inArg = selectRows(a_data{jj},grpRows{igrp});
                try
                    outVals{igrp} = fun(inArg);
                catch ME
                    % Leave 'identifier' and 'message' in the struct (even though it now has 'cause') for backwards compatibility.
                    s = struct('identifier',ME.identifier, 'message',ME.message, 'index',jj, 'name',varname_j, 'group',igrp, 'cause',ME);
                    outVals{igrp} = errHandler(s,inArg);
                end
            end
            if uniformOutput
                % For each group of rows, fun's output must have the same type across all variables.
                if jvar == 1
                    uniformClass = class(outVals{1});
                end
                b_data{jvar} = vertcatWithUniformScalarCheck(outVals,uniformClass,funName,varname_j);
            elseif tabularOutput
                % For each group of rows, fun's output must have the same number of rows across
                % all variables. Only do this the first time through the loop over variables.
                if jvar == 1 && ngroups > 0
                    for igrp = 1:ngroups
                        grpNumRows(igrp) = size(outVals{igrp},1); 
                        if timetableOutput && ~groupByRowLabels
                            % Save the leading row times for each group, as many as there are output
                            % rows for each group.
                            if grpNumRows(igrp) <= size(grpRows{igrp},1)
                                outTime{igrp} = a.rowDim.labels(grpRows{igrp}(1:grpNumRows(igrp)));
                            else
                                error(message('MATLAB:table:varfun:TimetableCannotGrow',funName));
                            end
                        end
                    end
                end
                b_data{jvar} = vertcatWithNumRowsCheck(outVals,grpNumRows,funName,varname_j);                
            else % cellOutput
                b_data(:,jvar) = outVals;
            end
        end
    end
    
    if uniformOutput
        if ndataVars > 0
            b = [b_data{:}]; % already validated: all ngroups-by-1, same class
        else
            b = zeros(ngroups,0);
        end
    elseif tabularOutput
        % Create the output by first concatenating the unique grouping var combinations, one row
        % per group, and the group counts. Replicate to match the number of rows from the function
        % output for each group, and concatenate that with the function output.
        
        % Get the grouping variables for the output from the first row in each group of
        % rows in the input. If the grouping vars include input's row labels, i.e.
        % any(groupVars==0), the row labels part of the "unique grouping var combinations"
        % are automatically carried over.
        bg = a(grpRowLoc,groupVars(~isRowLabels));
        
        if tableOutput && isa(a,'timetable')
            % Convert to a table, discarding the row times but preserving the grouping
            % variable metadata and the second dim name. The generated output data
            % var names are unique'd against the grouping var and dim names below.
            newDimNames = table.defaultDimNames; newDimNames(2) = a.metaDim.labels(2);
            bg = table.init(bg.data, ...
                            bg.rowDim.length, {}, ...
                            bg.varDim.length, bg.varDim.labels, ...
                            newDimNames);
            bg.varDim = bg.varDim.moveProps(a.varDim,groupVars(~isRowLabels),find(~isRowLabels));
            bg.arrayProps = a.arrayProps;
        end
        if bg.rowDim.requireUniqueLabels
            assert(~bg.rowDim.requireLabels)
            % Remove existing row names. Could assign row names using grpNames, but when the
            % function returns multiple rows (e.g. a "within-groups" transformation
            % function), ensuring that the row names are unique is time-consuming, and in
            % any case group names are really only useful when there is only one grouping
            % variable.
            bg.rowDim = bg.rowDim.removeLabels();
            if groupByRowLabels
                % When grouping by row labels, add them as an explicit grouping
                % variable in the output table. There's no name collision possible
                % between that and the other grouping vars because a's var and dim
                % names are already unique. But if the input was a table, there's a
                % guaranteed collision between that added grouping var and the existing
                % row dim name (also possible if the input was a timetable whose row
                % times are named 'Row' and output type is 'table'). Modify the
                % existing row labels dim name if necessary to avoid the collision.
                gvnames = [bg.varDim.labels a.metaDim.labels(1)];
                bg.metaDim = bg.metaDim.checkAgainstVarLabels(gvnames,'silent');
                bg.data{end+1} = a.rowDim.labels(grpRowLoc);
                bg.varDim = bg.varDim.lengthenTo(bg.varDim.length+1,a.metaDim.labels(1));
                if ~isscalar(groupVars)
                    % Put the row labels grouping var in its specified order among the other
                    % grouping vars, insert multiple copies if specified more than once.
                    reord = repmat(bg.varDim.length,1,bg.varDim.length);
                    reord(~isRowLabels) = 1:sum(~isRowLabels);
                    bg = bg(:,reord);
                end
            end
        end
        
        % Replicate rows of the grouping vars and the group count var to match the
        % number of rows in the function output for each group.
        bg = bg(repelem(1:ngroups,grpNumRows),:);
        grpCounts = grpCounts(repelem(1:ngroups,grpNumRows),1);
        
        if timetableOutput && ~groupByRowLabels && any(grpNumRows > 1)
            % When there are multiple rows per group in the output, parenReference will have
            % replicated values of the first row time within each group. That's correct
            % when grouping by time, but otherwise use the "leading" row times saved earlier.
            b_time = vertcat(outTime{:});
            bg.rowDim = bg.rowDim.setLabels(b_time);
        end
        
        % Make sure that constructed var names don't clash with the grouping var names
        % or the dim names.
        vnames = [{'GroupCount'} b_dataVarNames];
        avoidVarNames = [bg.metaDim.labels bg.varDim.labels];
        vnames = matlab.lang.makeUniqueStrings(vnames,avoidVarNames,namelengthmax);
        
        b = bg;
        b.data = [b.data {grpCounts} b_data];
        b.varDim = b.varDim.lengthenTo(b.varDim.length+length(vnames),vnames);
    else % cellOutput
        b = b_data;
    end
    
else % ungrouped
    b_data = cell(1,ndataVars);
    for jvar = 1:ndataVars
        jj = dataVars(jvar);
        varname_j = a_varnames{jj};
        try
            b_data{jvar} = fun(a_data{jj});
        catch ME
            % Leave 'identifier' and 'message' in the struct (even though it now has 'cause') for backwards compatibility.
            s = struct('identifier',ME.identifier, 'message',ME.message, 'index',jj, 'name',varname_j, 'cause',ME);
            b_data{jvar} = errHandler(s,a_data{jj});
        end
    end
    if uniformOutput
        b = horzcatWithUniformScalarCheck(b_data,funName,a_varnames(dataVars));
    elseif isa(a,'timetable') && tableOutput % table output from a timetable; ungrouped case
        % Make sure the generated output var names don't clash with the dim names.
        b_dimnames = table.defaultDimNames; b_dimnames(2) = a.metaDim.labels(2);
        b_varnames = matlab.lang.makeUniqueStrings(b_dataVarNames,b_dimnames,namelengthmax);
        
        % Check that fun returned equal-length outputs for all vars, and create a table
        % from those outputs. Discard the input's row times and all per-variable metadata,
        % but preserve the second dim name.
        [b_data,b_height] = tabular.numRowsCheck(b_data);
        b = table.init(b_data, ...
                       b_height, {}, ...
                       ndataVars, b_varnames, ...
                       b_dimnames);
        b.arrayProps = a.arrayProps;
        % Keep CustomProperties names, but empty the fields.
        a_customProps = a.varDim.customProps;
        pn = fieldnames(a_customProps);
        for ii = 1:numel(pn)
            a_customProps.(pn{ii}) = [];
        end
        b.varDim = b.varDim.setCustomProps(a_customProps);
    elseif tabularOutput % table in -> table out, or timetable in -> timetable out
        if ndataVars > 0
            % Check that fun returned equal-length outputs for all vars, then copy the
            % input and overwrite its data with fun's outputs.
            b = a;
            [b.data,b_height] = tabular.numRowsCheck(b_data);
            
            % Update the var names, but discard per-variable metadata. Make sure the
            % generated output var names don't clash with the dim names.
            b_varnames = matlab.lang.makeUniqueStrings(b_dataVarNames,a.metaDim.labels,namelengthmax);
            b.varDim = b.varDim.createLike(length(b_varnames),b_varnames);
            % Keep CustomProperties names, but empty the fields.
            a_customProps = a.varDim.customProps;
            pn = fieldnames(a_customProps);
            for ii = 1:numel(pn)
                a_customProps.(pn{ii}) = [];
            end
            b.varDim = b.varDim.setCustomProps(a_customProps);
            
            % In general the output rows need not correspond to the input rows,
            % but if the output requires row labels (i.e. a timetable), preserve
            % as many as needed from the input (a safe bet in most cases).
            % Otherwise discard the input's row labels.
            a_height = a.rowDim.length;
            if a.rowDim.requireLabels % timetable in -> timetable out
                if b_height > a_height
                    error(message('MATLAB:table:varfun:TimetableCannotGrow',funName));
                end
            else % table in -> table out
                b.rowDim = b.rowDim.removeLabels();
            end
            % Lengthen or shorten the row dim to the output size as necessary.
            if b_height > a_height
                b.rowDim = b.rowDim.lengthenTo(b_height);
            elseif b_height < a_height
                b.rowDim = b.rowDim.shortenTo(b_height);
            end
        else
            % Ungrouped varfun on an Nx0 input results in a 0x0 output.
            b = a([],[]);
        end
    else % cellOutput
        b = b_data;
    end
end

if isa(a,'eventtable') && ~autoOutput && timetableOutput
    % Convert to a timetable, if the input was an eventtable and the
    % requested OutputFormat was timetable. Note that timetableOutput could be
    % set to true either if the OutputFormat was auto or if it was explicitly
    % set to timetable, do this conversion only if it was explicitly set to
    % timetable.
    b = convertToTimetable(b);
end


%-------------------------------------------------------------------------------
function [varargout] = dfltErrHandler(grouped,funName,s,varargin) %#ok<STOUT>
import matlab.internal.datatypes.ordinalString
if grouped
    m = message('MATLAB:table:varfun:FunFailedGrouped',funName,ordinalString(s.group),s.name);
else
    m = message('MATLAB:table:varfun:FunFailed',funName,s.name);
end
throwAsCaller(MException(m).addCause(s.cause));


%-------------------------------------------------------------------------------
function b_data = horzcatWithUniformScalarCheck(b_data,funName,varnames)
nvars = length(b_data);
if nvars > 0
    for jvar = 1:nvars
        if ~isscalar(b_data{jvar})
            error(message('MATLAB:table:varfun:NotAScalarOutput',funName,varnames{jvar}));
        elseif jvar == 1
            uniformClass = class(b_data{1});
        elseif ~isa(b_data{jvar},uniformClass)
            c = class(b_data{jvar});
            error(message('MATLAB:table:varfun:MismatchInOutputTypes',funName,c,uniformClass,varnames{jvar}));
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
function outVals = vertcatWithUniformScalarCheck(outVals,uniformClass,funName,varname)
import matlab.internal.datatypes.ordinalString
ngroups = length(outVals);
for igrp = 1:ngroups
    if ~isscalar(outVals{igrp})
        error(message('MATLAB:table:varfun:NotAScalarOutputGrouped',funName,ordinalString(igrp),varname));
    elseif ~isa(outVals{igrp},uniformClass)
        c = class(outVals{igrp});
        error(message('MATLAB:table:varfun:MismatchInOutputTypesGrouped',funName,c,uniformClass,ordinalString(igrp),varname));
    end
end
outVals = vertcat(outVals{:});



%-------------------------------------------------------------------------------
function outVals = vertcatWithNumRowsCheck(outVals,grpNumRows,funName,varname)
import matlab.internal.datatypes.ordinalString
ngroups = length(outVals);
for igrp = 1:ngroups
    if size(outVals{igrp},1) ~= grpNumRows(igrp)
        error(message('MATLAB:table:varfun:GroupRowsMismatch',funName,ordinalString(igrp),varname));
    end
end
try
    outVals = vertcat(outVals{:});
catch ME
    error(message('MATLAB:table:varfun:VertcatFailed',funName,varname,ME.message));
end
