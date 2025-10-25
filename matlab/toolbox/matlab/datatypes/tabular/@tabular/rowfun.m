function b = rowfun(fun,a,varargin)
%

%   Copyright 2012-2024 The MathWorks, Inc.

import matlab.internal.datatypes.ordinalString
import matlab.internal.datatypes.isScalarInt
import matlab.internal.datatypes.validateLogical

% Set default output for each input type and also set the list of allowed
% OutputFormats (for example, tables dont support timetable as the
% OutputFormat).
% Here table is a redundant OutputFormat for table inputs but it allows
% converting timetables and eventtables into tables. Similarly, timetable is a
% redundant OutputFormat for timetable inputs but it allows converting
% eventtables into timetables.
if isa(a, 'timetable') % timetable or eventtable input
    dfltOut = 5; % timetable
    allowedOutputFormats = {'auto' 'uniform' 'table' 'cell' 'timetable' };
else
    dfltOut = 3; % table
    allowedOutputFormats = {'auto' 'uniform' 'table' 'cell'};
end

pnames = {'GroupingVariables' 'InputVariables' 'OutputFormat' 'NumOutputs' 'OutputVariableNames' 'SeparateInputs' 'ExtractCellContents'  'ErrorHandler'};
dflts =  {                []               []        dfltOut            1                    {}             true                 false              [] };
[groupVars,dataVars,outputFormat,nout,outNames,separateArgs,extractCells,errHandler,supplied] ...
    = matlab.internal.datatypes.parseArgs(pnames, dflts, varargin{:});

% Do a grouped calculation if GroupingVariables is supplied, even if it's empty
% (the latter is the same as ungrouped but with a GroupCounts variable).
grouped = supplied.GroupingVariables;
if grouped
    groupVars = a.getVarOrRowLabelIndices(groupVars,false,true);
    isRowLabels = (groupVars == 0);
    groupByRowLabels = any(isRowLabels);
    
    [group,grpNames,grpRowLoc] = a.table2gidx(groupVars); % leave out categories not present in data
    ngroups = length(grpNames);
    grpRows = matlab.internal.datatypes.getGroups(group,ngroups);
    grpCounts = histc(group,1:ngroups); %#ok<HISTC> % ignores NaNs in group
else
    groupByRowLabels = false;
    ngroups = a.rowDim.length;
    grpRows = num2cell(1:ngroups);
end

if ~supplied.InputVariables
    dataVars = setdiff(1:a.varDim.length,groupVars);
elseif isa(dataVars,'function_handle')
    a_data = a.data;
    nvars = length(a_data);
    try
        isDataVar = zeros(1,nvars);
        for j = 1:nvars, isDataVar(j) = dataVars(a_data{j}); end
    catch ME
        matlab.internal.datatypes.throwInstead(ME, ...
            "MATLAB:matrix:singleSubscriptNumelMismatch", ...
            "MATLAB:table:rowfun:InvalidInputVariablesFun");
    end
    dataVars = find(isDataVar);
else
    try
        dataVars = a.varDim.subs2inds(dataVars);
    catch ME
        a.subs2indsErrorHandler(dataVars,ME,'rowfun');
    end
end

if ~isa(fun,'function_handle')
    error(message('MATLAB:table:rowfun:InvalidFunction'));
end
funName = func2str(fun);

if supplied.OutputFormat
    outputFormat = matlab.internal.datatypes.getChoice(outputFormat,allowedOutputFormats,a.specifyInvalidOutputFormatID("rowfun"));
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

if supplied.NumOutputs && ~isScalarInt(nout,0)
    error(message('MATLAB:table:rowfun:InvalidNumOutputs'));
end

if supplied.OutputVariableNames
    outNames = convertStringsToChars(outNames);
    if ischar(outNames), outNames = {outNames}; end
    if supplied.NumOutputs
        if length(outNames) ~= nout
            error(message('MATLAB:table:rowfun:OutputNamesWrongLength'));
        end
    else
        nout = length(outNames);
    end
else
    % If neither NumOutputs nor OutputVariableNames is given, we could use
    % nargout to try to guess the number of outputs, but that doesn't work for
    % anonymous or varargout functions, and for many ordinary functions will be
    % the wrong guess because the second, third, ... outputs are not wanted.
    
    if tabularOutput
        % Choose default names based on the locations in the output table
        if grouped
            ngroupVars = sum(~isRowLabels) + (tableOutput && groupByRowLabels);
            outNames = a.varDim.dfltLabels(ngroupVars+1+(1:nout));
        else
            outNames = a.varDim.dfltLabels(1:nout);
        end
    end
end

extractCells = validateLogical(extractCells,'ExtractCellContents');
separateArgs = validateLogical(separateArgs,'SeparateInputs');

if ~supplied.ErrorHandler
    errHandler = @(s,varargin) dfltErrHandler(grouped,funName,s,varargin{:});
end

% Each row of cells will contain the outputs from FUN applied to one
% row or group of rows in B.
b_data = cell(ngroups,nout);
grpNumRows = ones(ngroups,1); % assume, for now, one row for each group

a_dataVars = a.data(dataVars);
for igrp = 1:ngroups
    if separateArgs
        inArgs = extractRows(a_dataVars,grpRows{igrp},extractCells);
        try
            if nout > 0
                [b_data{igrp,:}] = fun(inArgs{:});
            else
                fun(inArgs{:});
            end
        catch ME
            % Leave 'identifier' and 'message' in the struct (even though it now has 'cause') for backwards compatibility.
            if nout > 0
                [b_data{igrp,:}] = errHandler(struct('identifier',ME.identifier, 'message',ME.message, 'index',igrp, 'cause',ME),inArgs{:});
            else
                errHandler(struct('identifier',ME.identifier, 'message',ME.message, 'index',igrp, 'cause',ME),inArgs{:});
            end
        end
    else
        inArgs = a{grpRows{igrp}, dataVars};
        try
            if nout > 0
                [b_data{igrp,:}] = fun(inArgs);
            else
                fun(inArgs);
            end
        catch ME
            % Leave 'identifier' and 'message' in the struct (even though it now has 'cause') for backwards compatibility.
            if nout > 0
                [b_data{igrp,:}] = errHandler(struct('identifier',ME.identifier, 'message',ME.message, 'index',igrp, 'cause',ME),inArgs);
            else
                errHandler(struct('identifier',ME.identifier, 'message',ME.message, 'index',igrp, 'cause',ME),inArgs);
            end
        end
    end
    if nout > 0
        if uniformOutput
            for jout = 1:nout
                if ~isscalar(b_data{igrp,jout})
                    if grouped
                        error(message('MATLAB:table:rowfun:NotAScalarOutputGrouped',funName,ordinalString(igrp)));
                    else
                        error(message('MATLAB:table:rowfun:NotAScalarOutput',funName,ordinalString(igrp)));
                    end
                end
            end
        elseif tabularOutput
            numRows = size(b_data{igrp,1},1);
            for jout = 1:nout % repeat j==1 to check any(n ~= 1)
                n = size(b_data{igrp,jout},1);
                if grouped
                    if any(n ~= numRows)
                        error(message('MATLAB:table:rowfun:GroupedRowSize',funName,ordinalString(igrp)));
                    end
                elseif any(n ~= 1) % ~grouped
                    error(message('MATLAB:table:rowfun:UngroupedRowSize',funName,ordinalString(igrp)));
                end
            end
            grpNumRows(igrp) = numRows;
        else
            % leave cell output alone
        end
    end
end

if uniformOutput
    if nout > 0 && ngroups > 0
        uniformClass = class(b_data{1});
        b = cell2matWithUniformCheck(b_data,uniformClass,funName,grouped);
    else
        % The function either produces no outputs, or there was nothing to call
        % it on, assume it would have produced a double result.
        b = zeros(ngroups,nout);
    end
    
elseif tabularOutput
    % Concatenate each of the function's outputs across groups of rows
    b_dataVars = cell(1,nout);
    for jout = 1:nout
        b_dataVars{jout} = vertcat(b_data{:,jout});
    end
    
    if grouped
        % Create the output by first concatenating the unique grouping var combinations, one
        % row per group, and the group counts. Replicate to match the number of rows from the
        % function output for each group, and concatenate that with the function output.
        
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
            % Save the leading row times for each group, as many as there
            % are output. Each cell in grpRows is a vector containing the
            % row numbers for the i'th group's rows. There may be more rows
            % in grpRows than there are output rows, so we need to get rid
            % of the extra rows. If there are more output rows than input
            % rows, error.
            for igrp = 1:ngroups
                grpSz = size(grpRows{igrp},1);
                if grpNumRows(igrp) > grpSz % Check that output doesn't grow beyond group size.
                    error(message('MATLAB:table:rowfun:TimetableCannotGrow'));
                elseif grpNumRows(igrp) < grpSz % Need to throw away extra rows in grpRows.
                    grpRows{igrp}((grpNumRows(igrp)+1):end) = [];
                end
            end
            b_time = a.rowDim.labels(vertcat(grpRows{:}));
            
            % When there are multiple rows per group in the output, subsrefParens will have
            % replicated values of the first row time within each group. That's correct when
            % grouping by time, but otherwise use the "leading" row times saved earlier.
            bg.rowDim = bg.rowDim.setLabels(b_time);
        end

        % Make sure that constructed var names don't clash with the grouping var names
        % or dim names. Specified output names that clash is an error.
        vnames = [{'GroupCount'} outNames(:)'];
        if ~supplied.OutputVariableNames
            avoidVarNames = [bg.metaDim.labels bg.varDim.labels];
            vnames = matlab.lang.makeUniqueStrings(vnames,avoidVarNames,namelengthmax);
        end
        
        % Create the output table by concatenating the grouping vars and the group
        % count var with the function output. Update the variable names,
        % using setLabels to validate that user-supplied outNames don't
        % clash.
        b = bg;
        b.data = [b.data {grpCounts} b_dataVars];
        newVarInds = (b.varDim.length+1):(b.varDim.length+length(vnames));
        % First, treat vnames as dummy names so that lengthTo doesn't have to
        % make dummy names and make them unique. Then, pass vnames into
        % setLabels to do the appropriate unique and valid checks.
        b.varDim = b.varDim.lengthenTo(newVarInds(end),vnames);
        b.varDim = b.varDim.setLabels(vnames,newVarInds,false,false,false);
        
    else % ungrouped
        if tableOutput && isa(a,'timetable') % table output from a timetable input
            newDimNames = table.defaultDimNames; newDimNames(2) = a.metaDim.labels(2);
            if ~supplied.OutputVariableNames
                % Make sure the auto-generated output var names don't clash with the dim names.
                outNames = matlab.lang.makeUniqueStrings(outNames,newDimNames,namelengthmax);
            end
            
            % Create a table the same height as the input, since the output rows correspond
            % 1:1 to the input rows.  Preserve number of rows even if there are no data variables.
            % Discard the input's row times and all per-variable metadata, but preserve the
            % second dim name (as long as it doesn't clash with supplied var names).
            b = table.init(b_dataVars, ...
                           a.rowDim.length, {}, ...
                           length(outNames), outNames, ...
                           newDimNames);
            b.arrayProps = a.arrayProps;
        else % output type same as input
            % Copy the input, but overwrite its variables with the function's output
            % variables. Preserve the row labels, since the output rows correspond 1:1 to
            % the input rows.
            b = a;
            b.data = b_dataVars; % already enforced one output row per input row
            
            % Update the var names, but discard per-variable metadata.
            if ~supplied.OutputVariableNames
                % Make sure the default output var names don't clash with the dim names.
                outNames = matlab.lang.makeUniqueStrings(outNames,a.metaDim.labels,namelengthmax);
            end
            b.varDim = b.varDim.createLike(length(outNames),outNames);
            a_customProps = a.varDim.customProps;
            pn = fieldnames(a_customProps);
            for ii = 1:numel(pn)
                a_customProps.(pn{ii}) = [];
            end
            b.varDim = b.varDim.setCustomProps(a_customProps);
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
    
    if supplied.OutputVariableNames
        % Detect conflicts between the var names and the dim names. Normally, conflicts
        % in a table's names would be resolved automatically with a warning, but for
        % timetable in/table out, behave as if the output was a timetable.
        if tableOutput && isa(a,'timetable')
            b.metaDim = b.metaDim.checkAgainstVarLabels(outNames,'error');
        else
            b.metaDim = b.metaDim.checkAgainstVarLabels(outNames);
        end
    end
    
else % cellOutput
    b = b_data;
end


%-------------------------------------------------------------------------------
function [varargout] = dfltErrHandler(grouped,funName,s,varargin) %#ok<STOUT>
import matlab.internal.datatypes.ordinalString
% May have guessed wrong about nargout for an anonymous function
if grouped
    m = message('MATLAB:table:rowfun:FunFailedGrouped',funName,ordinalString(s.index));
else
    m = message('MATLAB:table:rowfun:FunFailed',funName,ordinalString(s.index));
end
throwAsCaller(MException(m.Identifier,'%s',getString(m)).addCause(s.cause));


%-------------------------------------------------------------------------------
function outVals = cell2matWithUniformCheck(outVals,uniformClass,funName,grouped)
import matlab.internal.datatypes.ordinalString
[nrows,nvars] = size(outVals);
outValCols = cell(1,nvars);
for jvar = 1:nvars
    for irow = 1:nrows
        if ~isa(outVals{irow,jvar},uniformClass)
            c = class(outVals{irow,jvar});
            if grouped
                error(message('MATLAB:table:rowfun:MismatchInOutputTypesGrouped',funName,c,uniformClass,ordinalString(irow)));
            else
                error(message('MATLAB:table:rowfun:MismatchInOutputTypes',funName,c,uniformClass,ordinalString(irow)));
            end
        end
    end
    outValCols{jvar} = vertcat(outVals{:,jvar});
end
outVals = horzcat(outValCols{:});


%-------------------------------------------------------------------------------
function b = extractRows(t_data,rowIndices,extractCells)
%EXTRACTROWS Retrieve one or more rows from a table's data as a 1-by- cell vector.
nvars = length(t_data);
b = cell(1,nvars);
for j = 1:nvars
    var_j = t_data{j};
    if istabular(var_j) || ismatrix(var_j) 
        b{j} = var_j(rowIndices,:); % without using reshape, may not have one
    else
        % Each var could have any number of dims, no way of knowing,
        % except how many rows they have.  So just treat them as 2D to get
        % the necessary rows, and then reshape to their original dims.
        sizeOut = size(var_j); sizeOut(1) = numel(rowIndices);
        b{j} = reshape(var_j(rowIndices,:), sizeOut);
    end
    if extractCells && iscell(b{j})
        b{j} = vertcat(b{j}{:});
    end
end
