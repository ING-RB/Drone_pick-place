function [b,ia] = unstack(a,dataVars,indicatorVar,varargin)
%

%   Copyright 2012-2024 The MathWorks, Inc.

pnames = {'GroupingVariables' 'ConstantVariables' 'NewDataVariableNames' 'AggregationFunction'  'VariableNamingRule'};
dflts =  {                []                  []                     []                    []               'modify'};

[groupVars,constVars,wideVarNames,fun,variableNamingRule,supplied] ...
    = matlab.internal.datatypes.parseArgs(pnames,dflts,varargin{:});

% Row labels are not allowed as a data variable or an indicator variable, but
% are allowed as a grouping variable. Otherwise they are treated as a constant
% variable.
rowLabelsName = a.metaDim.labels(1);
if any(strcmp(rowLabelsName,dataVars))
    a.throwSubclassSpecificError('unstack:CantUnstackRowLabels');
end
if any(strcmp(rowLabelsName,indicatorVar))
    a.throwSubclassSpecificError('unstack:CantUnstackWithRowLabelsIndicator');
end

% Convert dataVars to indices. [] is valid, and does not indicate "default".
dataVars = a.varDim.subs2inds(dataVars); % a row vector
ntallVars = length(dataVars);

% Tabular arrays are not allowed as data variables.
for i = 1:length(dataVars)
    if isa(a.data{dataVars(i)},'tabular')
        error(message('MATLAB:table:unstack:CantUnstackTabularVariable',a.varDim.labels{dataVars(i)}));
    end
end

% Convert indicatorVar to an index.
if isa(indicatorVar,"pattern")
    error(message('MATLAB:table:unstack:PatternIndVar'));
end
indicatorVar = a.varDim.subs2inds(indicatorVar);
if ~isscalar(indicatorVar)
    error(message('MATLAB:table:unstack:MultipleIndVar'));
end

if supplied.AggregationFunction && ~isa(fun,'function_handle')
    error(message('MATLAB:table:unstack:InvalidAggregationFun'));
end

% Reconcile groupVars and dataVars. The two must have no variables in common.
% If only dataVars is provided, groupVars defaults to "everything else except
% the indicator" for table, or to "only the row times" for timetables.
if supplied.GroupingVariables
    % Convert groupVars to indices. [] is valid, and does not indicate "default".
    groupVars = a.getVarOrRowLabelIndices(groupVars,false,true); % a row vector
    if ~isempty(intersect(groupVars,dataVars))
        error(message('MATLAB:table:unstack:ConflictingGroupAndDataVars'));
    end
else
    % If the row labels are unique, there's no point in making them the default
    % grouping var. Otherwise use them by the default. This default for the grouping
    % vars may be adjusted below after looking at the specified constant vars.
    if a.rowDim.requireUniqueLabels
        groupVars = setdiff(1:size(a,2),[indicatorVar dataVars]);
    else
        groupVars = 0;
    end
end

% indicatorVar must not appear in groupVars or dataVars.
if ismember(indicatorVar,groupVars) || ismember(indicatorVar,dataVars)
    error(message('MATLAB:table:unstack:ConflictingIndVar'));
end

% Reconcile constVars with everything else. [] is the default.
if supplied.ConstantVariables
    % Ignore empty row labels, they are always treated as a const var.
    constVars = a.getVarOrRowLabelIndices(constVars,true); % a row vector
    if ~supplied.GroupingVariables
        groupVars = setdiff(groupVars,constVars);
    elseif any(ismember(constVars,groupVars))
        error(message('MATLAB:table:unstack:ConflictingConstVars'));
    end
    if any(ismember(constVars,dataVars)) || any(ismember(constVars,indicatorVar))
        error(message('MATLAB:table:unstack:ConflictingConstVars'));
    end
    % If the specified constant vars include the input's row labels, i.e.
    % any(constVars==0), those will automatically be carried over as the
    % output's row labels, so clear those from constVars.
    constVars(constVars==0) = [];
else
    constVars = [];
end

% Ensure that VariableNamingRule has the appropriate value
variableNamingRule = validatestring(variableNamingRule,{'modify','preserve'},'unstack','VariableNamingRule');

% Decide how to de-interleave the tall data, and at the same time create
% default names for the wide data vars.
aNames = a.varDim.labels;
[kdx,dfltWideVarNames] = a.table2gidx(indicatorVar);
nwideVars = length(dfltWideVarNames);

% Use default names for the wide data vars if needed.
useDfltWideVarNames = ~supplied.NewDataVariableNames;
if useDfltWideVarNames
    % Check if wide var names need to be modified.
    if strcmp(variableNamingRule,'preserve')
        % Call makeValidName to handle long names and names conflicting with reserved
        % names.
        wideVarNames = a.varDim.makeValidName(dfltWideVarNames(:)','resolveConflict'); 
    else
        % Convert the names to valid MATLAB identifiers
        if supplied.VariableNamingRule
            % Do not display any warning as VariableNamingRule has been specified
            wideVarNames = a.varDim.makeValidName(dfltWideVarNames(:)','silent');
        else
            wideVarNames = a.varDim.makeValidName(dfltWideVarNames(:)','warnUnstack');
        end
    end
elseif isempty(wideVarNames) && isa(wideVarNames,'double')
    wideVarNames = {};
end

% Create the wide table from the unique grouping var combinations. This carries
% over properties of the tall table. If the grouping vars include input's row
% labels, i.e. any(groupVars==0), the row labels part of the "unique grouping
% var combinations" will automatically be carried over as the output's row
% labels, so clear those from groupVars after getting the group indices.
[jdx,~,idx] = a.table2gidx(groupVars);
groupVars(groupVars==0) = [];
b = a(idx,groupVars);
nrowsWide = size(b,1);
nrowsTall = size(a,1);

% Leave out rows with missing grouping or indicator var values
isMissing = isnan(jdx) | isnan(kdx);
jdx(isMissing) = [];
kdx(isMissing) = [];

% Append the constant variables
if ~isempty(constVars)
    c = a(idx,constVars);
    if istable(a)
        b = [b c];
    else % istimetable
        c_inds = b.varDim.length+1:b.varDim.length+c.varDim.length;
        b(:,c_inds) = c;
        b.varDim = b.varDim.setLabels(c.varDim.labels, c_inds);
    end
end
b_varDim = b.varDim;
fillValueChanged = false;

if ntallVars ~= 0
    for t = 1:ntallVars
        % For each tall var ...
        tallVar = a.data{dataVars(t)};
        szOut = size(tallVar); szOut(1) = nrowsWide;
        
        % Preallocate room in the table
        j0 = b_varDim.length;
        wideVarIndices = j0 + (1:nwideVars);
        b_varDim = b_varDim.lengthenTo(j0+nwideVars); % fill the names in later
        b.data(wideVarIndices) = cell(1,nwideVars);
        
        % De-interleave the tall variable into a group of wide variables. The
        % wide variables will have the same class as the tall variable.
        %
        % Handle numeric types directly with accumarray
        if isnumeric(tallVar) || islogical(tallVar) % but not char
            [~,ncols] = size(tallVar); % possibly N-D
            
            if ~isempty(fun)
                % The aggregation fun has to return something castable to tallVar's class.
                funVal = fun(tallVar(1));
                if ~(isnumeric(funVal) || islogical(funVal))
                    error(message('MATLAB:table:unstack:BadAggFunValueClass', aNames{ dataVars( t ) }));
                end
            end
            
            % The wide variables will be the same type as the tall (stacked)
            % variable. Create a fillVal appropriate for that type. This value is
            % written into elements of the wide (unstacked) variables that receive
            % no values from the tall (stacked) variable
            if isfloat(tallVar)
                fillVal = nan(1,'like',tallVar);
            elseif isnumeric(tallVar)
                fillVal = zeros(1,'like',tallVar);
            else % islogical(tallVar)
                fillVal = false;
            end
    
            for k = 1:ncols
                tallVar_k = tallVar(~isMissing,k); % leave out rows with missing grouping/indicator
                % If no aggregation function was supplied, let ACCUMARRAY copy/sum data from
                % tall to wide. If an aggregation function _was_ supplied, let ACCUMARRAY apply
                % that to all non-empty bins. In either case, let ACCUMARRAY fill wide elements
                % corresponding to empty bins with zeros, faster. Overwrite those elements with
                % the correct fillVal below.
                if isempty(fun)
                    wideVars_k = accumarray({jdx,kdx},tallVar_k,[nrowsWide,nwideVars]);
                    % sum always returns a scalar for numeric; no catch for non-scalar needed.
                else
                    % ACCUMARRAY applies the function even when there's only one
                    % tall value for a wide element. The function is not applied for
                    % empty wide elements, but those get filled with fillVal anyway.
                    try
                        wideVars_k = accumarray({jdx,kdx},tallVar_k,[nrowsWide,nwideVars],fun);
                    catch ME
                        % The user-supplied returned a non-scalar value.
                        matlab.internal.datatypes.throwInstead(ME, ...
                            'MATLAB:accumarray:nonscalarFunOutput','MATLAB:table:unstack:NonscalarAggFunValue')
                    end
                end
                
                % ACCUMARRAY sums integer/logical types in double, undo that. Or the
                % aggregation function may have returned a class different than tallVar.
                if ~isa(wideVars_k,class(tallVar))
                    wideVars_k = cast(wideVars_k,'like',tallVar);
                end
                
                % Explicitly fill in elements of the wide variable that received no
                % tall values.
                fillLocs = ~accumarray({jdx,kdx},1,[nrowsWide,nwideVars]);
                if isempty(fun)
                    wideVars_k(fillLocs) = fillVal;
                elseif any(fillLocs,'all')
                    % Create an empty 0x1 array of the same type as tallVar and
                    % apply the aggregation function
                    val = fun(zeros([0,1],'like',tallVar));
                    if ~(isnumeric(val) || islogical(val))
                        % The value must be something castable to tallVar
                        error(message('MATLAB:table:unstack:BadAggFunValueClass', aNames{ dataVars( t ) }));
                    elseif ~isscalar(val)
                        if isempty(val)
                            % Use fill value if fun returned empty for empty bin
                            wideVars_k(fillLocs) = fillVal;
                        else
                            % The fill value must be a scalar
                            error(message('MATLAB:table:unstack:NonscalarAggFunValue'));
                        end
                    else
                        wideVars_k(fillLocs) = val;
                        fillValueChanged = fillValueChanged | ~isequaln(val,fillVal);
                    end
                end
    
                for j = 1:nwideVars
                    if k == 1
                        b.data{j0+j} = reshape(repmat(wideVars_k(:,j),1,ncols),szOut);
                    else
                        b.data{j0+j}(:,k) = wideVars_k(:,j);
                    end
                end
            end
            
        % Handle non-numeric types indirectly
        else
            % Create fillVal with same class as tallVar.
            if iscellstr(tallVar) %#ok<ISCLSTR>
                % Need explicit empty string
                fillVal = {''};
            else
                % Let the variable define the fill value for empty cells
                tmp = tallVar(1); tmp(3) = tmp(1); fillVal = tmp(2); % intentionally a scalar
            end
            
            tallRowIndices = (1:nrowsTall)';
            tallRowIndices(isMissing) = []; % leave out rows with missing grouping/indicator
            
            % If an aggregation function is not supplied and we have bins with
            % multiple values, then use @unique as our aggregation function
            if ~supplied.AggregationFunction
                cellCounts = accumarray({jdx,kdx},1,[nrowsWide,nwideVars]);
                if any(cellCounts(:) > 1)
                    fun = @unique;
                end
            end
            
            % If no aggregation is needed, just copy data from tall to wide without calling
            % any aggregation function. If aggregation is needed (either a user-supplied
            % function, and/or some bins have multiple values), the aggregation function
            % will be called on all bins.
            if isempty(fun) % No aggregation function
                % At most one tall value per bin, possibly none. Pivot the tall row indices of
                % the non-empty bins into a matrix that maps to the rows/cols of the wide var.
                % Accumarray leaves the indices for empty bins equal to 0.
                wideRowIndices = accumarray({jdx,kdx},tallRowIndices,[nrowsWide,nwideVars]);
                for j = 1:nwideVars
                    wideRowIndices_j = wideRowIndices(:,j);
                    zeroInds = (wideRowIndices_j == 0);
                    if any(zeroInds)
                        % Store a fill value at the end of tallVar for the zero indices, and
                        % update those indices to point to that fill value.
                        tallVar(nrowsTall+1,:) = fillVal;
                        wideRowIndices_j(zeroInds) = nrowsTall + 1;
                    end
                    % Copy data out of the tall var to create the wide var with the same class.
                    b.data{j0+j} = reshape(tallVar(wideRowIndices_j,:),szOut);
                end   
            else % User supplied aggregation function or @unique
                % There may be empty bins, singleton bins, or bins with multiple values. The
                % aggregation function is applied in all cases, and must return a scalar.
                wideRowIndices = accumarray({jdx,kdx},tallRowIndices,[nrowsWide,nwideVars],@(x) {x});
                for j = 1:nwideVars
                    % Create the wideVar with the same class as tallVar.
                    wideVar_j = repmat(fillVal,[nrowsWide,size(tallVar,2)]);
                    for i = 1:nrowsWide
                        % These indices may not be in order, because ACCUMARRAY does
                        % not guarantee that
                        indices_ij = wideRowIndices{i,j};
                        [~,ncolsTallVar] = size(tallVar);
                        % Apply AggregationFunction to each column of tallVar
                        for k = 1:ncolsTallVar
                            val = fun(tallVar(indices_ij,k));
                            % If the aggregation function returns an empty for
                            % empty bins, then we want to use the fillVal for
                            % that bin. Since wideVar_j is already initialized
                            % with the fillVal, avoid the extra work of going
                            % into the try-catch to do the assignment. So only do
                            % the assignment if either the function returned a
                            % non-empty value or the current bin is non-empty.
                            if ~isempty(val) || ~isempty(indices_ij)
                                try
                                    wideVar_j(i,k) = val;
                                catch ME
                                    if isscalar(val)
                                        % Assignment failed due to type mismatch
                                        throw(addCause(MException(message('MATLAB:table:unstack:AssignmentError',aNames{dataVars(t)})),ME));
                                    else
                                        if ~supplied.AggregationFunction
                                            % Unique returned non-scalar value
                                            error(message('MATLAB:table:unstack:MultipleRows'));
                                        else
                                            % User-supplied function returned non-scalar value
                                            error(message('MATLAB:table:unstack:NonscalarAggFunValue'));
                                        end
                                    end
                                end
                            end
                        end
                    end
                    b.data{j0+j} = reshape(wideVar_j,szOut);
                end
            end
        end
        
        if ntallVars == 1
            wideNames = wideVarNames;
        else
            wideNames = append(aNames{dataVars(t)},'_',wideVarNames);
        end
        if useDfltWideVarNames
            % If the wide var names have been constructed automatically, make sure
            % they don't conflict with the existing var names or the dim names.
            avoidNames = [b_varDim.labels(1:j0) b.metaDim.labels];
            wideNames = matlab.lang.makeUniqueStrings(cellstr(wideNames),avoidNames,namelengthmax);
        end
        
        % Called-supplied wide var names given by NewDataVariableNames may be duplicate,
        % empty, or invalid; setLabels catches errors here and checkAgainstVarLabels
        % catches conflicts with dim names below. Default names (those taken from the
        % indicator var's values) should never be duplicate or empty; they may have been
        % invalid, but they've already been fixed.
        try
            b_varDim = b_varDim.setLabels(wideNames,wideVarIndices); % error if invalid, duplicate, or empty
        catch me
            if ( length(string(wideNames)) ~= length(wideVarIndices) )
                error(message('MATLAB:table:unstack:NewDataVarNameLengthMismatch',length(wideVarIndices)));
            elseif isequal(me.identifier,'MATLAB:table:DuplicateVarNames') ...
                    && length(unique(wideNames)) == length(wideNames)
                % The wide var names must have been supplied, not the defaults. Give
                % a more detailed err msg than the one from setLabels if there's a
                % conflict with existing var names
                error(message('MATLAB:table:unstack:ConflictingNewDataVarNames'));
            else
                rethrow(me);
            end
        end
    end
else % ntallVars == 0
    if ~matlab.internal.datatypes.isText(wideVarNames,false)
        error(message('MATLAB:table:InvalidVarNames'));
    end
    if supplied.NewDataVariableNames && ~isempty(wideVarNames)
        error(message('MATLAB:table:unstack:NewDataVarNamesEmptyDataVars'));
    end
end

% Display a warning if the fill value has changed
if fillValueChanged
   matlab.internal.datatypes.warningWithoutTrace(message('MATLAB:table:unstack:FillValueChange')); 
end

% Detect conflicts between the wide var names (which may have been given by
% NewDataVariableNames) and the original dim names.
b.metaDim = b.metaDim.checkAgainstVarLabels(b_varDim.labels,'error');

% Copy tall per-variable properties, appropriately replicated, to wide. 
repDataVars = repmat(dataVars,nwideVars,1);
b.varDim = b_varDim.moveProps(a.varDim,[groupVars constVars repDataVars(:)'],1:b_varDim.length);

% Put the wide table into "first occurrence" order of the tall table
[~,idxInv] = sort(idx);
b = b(idxInv,:);
if nargout > 1
    ia = idx(idxInv);
end
