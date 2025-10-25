function [b,ia] = unstack(a,dataVars,indicatorVar,varargin)  %#codegen
%UNSTACK Unstack data from a single variable into multiple variables

%   Copyright 2020 The MathWorks, Inc.

coder.extrinsic('setdiff', 'intersect', 'ismember', 'append', 'cellstr', 'matlab.internal.datatypes.isText', 'matlab.internal.datatypes.isScalarText');

narginchk(3,inf);

% constant checks
coder.internal.assert(coder.internal.isConst(dataVars), 'MATLAB:table:unstack:NonconstantDataVars');
coder.internal.assert(coder.internal.isConst(indicatorVar), 'MATLAB:table:unstack:NonconstantIndicatorVar');

pnames = {'GroupingVariables' 'ConstantVariables' 'NewDataVariableNames' ...
    'AggregationFunction'  'VariableNamingRule'};
poptions = struct( ...    
    'CaseSensitivity',false, ...    
    'PartialMatching','unique', ...    
    'StructExpand',false);
supplied = coder.internal.parseParameterInputs(pnames,poptions,varargin{:});

% codegen requires NewDataVariableNames to be defined
coder.internal.assert(supplied.NewDataVariableNames > 0, 'MATLAB:table:unstack:UndefinedNewDataVariableNames');

groupVarsInput = coder.internal.getParameterValue(supplied.GroupingVariables,[],varargin{:});
constVars = coder.internal.getParameterValue(supplied.ConstantVariables,[],varargin{:});
wideVarNamesInput = coder.internal.getParameterValue(supplied.NewDataVariableNames,[],varargin{:});
fun = coder.internal.getParameterValue(supplied.AggregationFunction,[],varargin{:}); 
variableNamingRule = coder.internal.getParameterValue(supplied.VariableNamingRule,'modify',varargin{:}); 

% more constant checks
coder.internal.errorIf(supplied.GroupingVariables && ~coder.internal.isConst(groupVarsInput), ...
    'MATLAB:table:unstack:NonconstantGroupingVars');
coder.internal.errorIf(supplied.ConstantVariables && ~coder.internal.isConst(constVars), ...
    'MATLAB:table:unstack:NonconstantConstantVars');
coder.internal.assert(coder.internal.isConst(wideVarNamesInput), ...
    'MATLAB:table:unstack:NonconstantNewDataVariableNames');
coder.internal.errorIf(supplied.AggregationFunction && ~coder.internal.isConst(fun), ...
    'MATLAB:table:unstack:NonconstantAggregationFun');

% Some error checking on NewDataVariableNames. In MATLAB, this is done
% within varDim.setLabels. In codegen, since we don't call setLabels, have
% to check for errors explicitly
if isstring(wideVarNamesInput)
    wideVarNames = coder.const(cellstr(wideVarNamesInput));
elseif isempty(wideVarNamesInput) && (isa(wideVarNamesInput,'double') || isa(wideVarNamesInput,'char'))
    wideVarNames = {};
elseif ischar(wideVarNamesInput) && ~isempty(wideVarNamesInput) && coder.const(matlab.internal.datatypes.isScalarText(wideVarNamesInput))
    wideVarNames = {wideVarNamesInput};
else
    wideVarNames = wideVarNamesInput;
end
coder.internal.assert(coder.const(matlab.internal.datatypes.isText(wideVarNames,true)),...
    'MATLAB:table:InvalidVarNames');  % only allow nonempty string scalar or cellstr

% Row labels are not allowed as a data variable or an indicator variable, but
% are allowed as a grouping variable. Otherwise they are treated as a constant
% variable.
rowLabelsName = a.metaDim.labels{1};
a.throwSubclassSpecificErrorIf(any(strcmp(rowLabelsName,dataVars)), 'unstack:CantUnstackRowLabels');
a.throwSubclassSpecificErrorIf(any(strcmp(rowLabelsName,indicatorVar)), ...
    'unstack:CantUnstackWithRowLabelsIndicator');

% Convert dataVars to indices. [] is valid, and does not indicate "default".
dataVars = a.varDim.subs2inds(dataVars); % a row vector
ntallVars = numel(dataVars);

% Tabular arrays are not allowed as data variables.
coder.unroll();
for i = 1:ntallVars
    coder.internal.errorIf(isa(a.data{dataVars(i)},'tabular'), ...
        'MATLAB:table:unstack:CantUnstackTabularVariable',a.varDim.labels{dataVars(i)});
end

% Convert indicatorVar to an index.
indicatorVar = a.varDim.subs2inds(indicatorVar);
coder.internal.assert(isscalar(indicatorVar), 'MATLAB:table:unstack:MultipleIndVar');

coder.internal.errorIf(supplied.AggregationFunction && ~isa(fun,'function_handle'), ...
    'MATLAB:table:unstack:InvalidAggregationFun');

% Reconcile groupVars and dataVars. The two must have no variables in common.
% If only dataVars is provided, groupVars defaults to "everything else except
% the indicator" for table, or to "only the row times" for timetables.
if supplied.GroupingVariables
    % Convert groupVars to indices. [] is valid, and does not indicate "default".
    groupVars0 = coder.const(a.getVarOrRowLabelIndices(groupVarsInput)); % a row vector
    coder.internal.assert(isempty(coder.const(intersect(groupVars0,dataVars))), ...
        'MATLAB:table:unstack:ConflictingGroupAndDataVars');
else
    % If the row labels are unique, there's no point in making them the default
    % grouping var. Otherwise use them by the default. This default for the grouping
    % vars may be adjusted below after looking at the specified constant vars.
    if a.rowDim.requireUniqueLabels
        groupVars0 = coder.const(setdiff(1:a.varDim.length,[indicatorVar dataVars]));
    else
        groupVars0 = 0;
    end
end

% indicatorVar must not appear in groupVars or dataVars.
coder.internal.errorIf(coder.const(ismember(indicatorVar,groupVars0)) || ...
    coder.const(ismember(indicatorVar,dataVars)), 'MATLAB:table:unstack:ConflictingIndVar');

% Reconcile constVars with everything else. [] is the default.
if supplied.ConstantVariables
    % Ignore empty row labels, they are always treated as a const var.
    constVars1 = coder.const(a.getVarOrRowLabelIndices(constVars,true)); % a row vector
    if ~supplied.GroupingVariables
        groupVars = coder.const(setdiff(groupVars0,constVars1));
    else
        coder.internal.errorIf(any(coder.const(ismember(constVars1,groupVars0))), ...
            'MATLAB:table:unstack:ConflictingConstVars');
        groupVars = groupVars0;
    end
    coder.internal.errorIf(any(coder.const(ismember(constVars1,dataVars))) || ...
        any(coder.const(ismember(constVars1,indicatorVar))), 'MATLAB:table:unstack:ConflictingConstVars');
    % If the specified constant vars include the input's row labels, i.e.
    % any(constVars==0), those will automatically be carried over as the
    % output's row labels, so clear those from constVars.
    constVarsNoRowNames = constVars1(constVars1~=0);
else
    constVarsNoRowNames = [];
    groupVars = groupVars0;
end

% Ensure that VariableNamingRule has the appropriate value
validatestring(variableNamingRule,{'modify','preserve'},'unstack','VariableNamingRule');

% Decide how to de-interleave the tall data, and at the same time create
% default names for the wide data vars.
aNames = a.varDim.labels;
[kdx,dfltWideVarNames] = a.table2gidx(indicatorVar);
if ntallVars > 0
coder.internal.assert(numel(dfltWideVarNames) == numel(wideVarNames), ...
    'MATLAB:table:unstack:NewDataVarNameLengthMismatch', numel(dfltWideVarNames));
end
nwideVars = numel(wideVarNames);

% Create the wide table from the unique grouping var combinations. This carries
% over properties of the tall table. If the grouping vars include input's row
% labels, i.e. any(groupVars==0), the row labels part of the "unique grouping
% var combinations" will automatically be carried over as the output's row
% labels, so clear those from groupVars after getting the group indices.
if isa(a.rowDim,'matlab.internal.coder.tabular.private.implicitRegularRowTimesDim') ...
        && coder.const(any(groupVars==0))
    % special branch for timetable with implicit row times and using row
    % times as a grouping variable. Rowtimes guaranteed to be unique, so
    % one group per row. Directly assigning to jdx and idx makes them more
    % easily constant folded, and output can be implicit
    jdx = (1:a.rowDimLength)';
    idx = ':';
    nrowsWide = a.rowDimLength;
else
    [jdx,~,idx] = a.table2gidx(groupVars);
    nrowsWide = numel(idx);
end
groupVarsNoRowNames = groupVars(groupVars~=0);
nrowsTall = size(a,1);

% Leave out rows with missing grouping or indicator var values
isMissing = isnan(jdx) | isnan(kdx);
jdx = jdx(~isMissing);
kdx = kdx(~isMissing);

% Append the constant variables
if ~isempty(constVarsNoRowNames)
    % b = a(idx,[groupVarsNoRowNames constVarsNoRowNames])
    b = parenReference(a, idx, [groupVarsNoRowNames constVarsNoRowNames]);  
else
    b = parenReference(a, idx, groupVarsNoRowNames); % b = a(idx,groupVarsNoRowNames)
end
b_varDim = b.varDim;
fillValueChanged = false;
nNewVars = ntallVars*nwideVars;
newVarNames = cell(1,nNewVars);
b_data = coder.nullcopy(cell(1,numel(b.data) + nNewVars));
coder.unroll();
for i = 1:numel(b.data)
    b_data{i} = b.data{i};
end 

if ntallVars > 0
    coder.unroll();
    for t = 1:ntallVars
        % For each tall var ...
        tallVar = a.data{dataVars(t)};
        szOut = size(tallVar); szOut(1) = nrowsWide;
        
        j0 = b_varDim.length + (t-1)*nwideVars;
        
        % De-interleave the tall variable into a group of wide variables. The
        % wide variables will have the same class as the tall variable.
        %
        % Handle numeric types directly with accumarray
        if isnumeric(tallVar) || islogical(tallVar) % but not char
            [~,ncols] = size(tallVar); % possibly N-D
            
            if ~isempty(fun)
                % The aggregation fun has to return something castable to tallVar's class.
                funVal = fun(tallVar(1));
                coder.internal.assert(isnumeric(funVal) || islogical(funVal), ...
                    'MATLAB:table:unstack:BadAggFunValueClass', aNames{ dataVars( t ) });
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
                    wideVars_k0 = accumarray({jdx,kdx},tallVar_k,[nrowsWide,nwideVars]);
                    % sum always returns a scalar for numeric; no catch for non-scalar needed.
                else
                    % ACCUMARRAY applies the function even when there's only one
                    % tall value for a wide element. The function is not applied for
                    % empty wide elements, but those get filled with fillVal anyway.
                    wideVars_k0 = accumarray({jdx,kdx},tallVar_k,[nrowsWide,nwideVars],fun);
                end
                
                % ACCUMARRAY sums integer/logical types in double, undo that. Or the
                % aggregation function may have returned a class different than tallVar.
                if ~isa(wideVars_k0,class(tallVar))
                    wideVars_k = cast(wideVars_k0,'like',tallVar);
                else
                    wideVars_k = wideVars_k0;
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
                    % The value must be something castable to tallVar
                    coder.internal.assert(isnumeric(val) || islogical(val), ...
                        'MATLAB:table:unstack:BadAggFunValueClass', aNames{ dataVars( t ) });
                    if ~isscalar(val)
                        coder.internal.assert(isempty(val), 'MATLAB:table:unstack:NonscalarAggFunValue');
                        % Use fill value if fun returned empty for empty bin
                        wideVars_k(fillLocs) = fillVal;
                    else
                        wideVars_k(fillLocs) = val;
                        fillValueChanged = fillValueChanged | ~isequaln(val,fillVal);
                    end
                end
                
                for j = 1:nwideVars
                    if k == 1
                        b_data{j0+j} = reshape(repmat(wideVars_k(:,j),1,ncols),szOut);
                    else
                        b_data{j0+j}(:,k) = wideVars_k(:,j);
                    end
                end
            end
            
            % Handle non-numeric types indirectly
        else
            % Create fillVal with same class as tallVar.
            fillVal = matlab.internal.coder.datatypes.defaultarrayLike([1 1], 'like', tallVar);
            
            tallRowIndices0 = (1:nrowsTall)';
            tallRowIndices = tallRowIndices0(~isMissing); % leave out rows with missing grouping/indicator
            
            if isempty(fun)
                if iscell(tallVar) 
                    coder.internal.assert(iscellstr(tallVar), 'MATLAB:table:unstack:CellArrayDataVars');
                    fun1 = @matlab.internal.coder.datatypes.cellstr_unique;
                else
                    fun1 = @unique;
                end
            else
                fun1 = fun;
            end
            
            % There may be empty bins, singleton bins, or bins with multiple values. The
            % aggregation function is applied in all cases, and must return a scalar.
            wideRowIndices = accumarray({jdx,kdx},tallRowIndices,[nrowsWide,nwideVars],@(x) {x}, {zeros(0,1)});
            if iscell(tallVar)
                % convert to homogeneous because nonconstant indexing is
                % necessary
                tallVarHomogeneous = tallVar;
                if coder.internal.isConst(size(tallVar))
                    coder.varsize('tallVarHomogeneous', [], [false false]);
                end
                coder.unroll();
                for j = 1:nwideVars
                    wideVar_j = cell(nrowsWide,size(tallVarHomogeneous,2));
                    for i = 1:nrowsWide
                        % These indices may not be in order, because ACCUMARRAY does
                        % not guarantee that
                        indices_ij = wideRowIndices{i,j};
                        [~,ncolsTallVar] = size(tallVarHomogeneous);
                        % Apply AggregationFunction to each column of tallVar
                        for k = 1:ncolsTallVar
                            tallVarIjk = cell(numel(indices_ij),1);
                            for kk = 1:numel(tallVarIjk)
                                tallVarIjk{kk} = tallVarHomogeneous{indices_ij(kk),k};
                            end
                            val = fun1(tallVarIjk);
                            nonScalarEmpty = ~(isscalar(val) || isempty(val));
                            coder.internal.errorIf(nonScalarEmpty && isempty(fun), 'MATLAB:table:unstack:MultipleRows');
                            coder.internal.errorIf(nonScalarEmpty && ~isempty(fun), 'MATLAB:table:unstack:NonscalarAggFunValue');
                            coder.internal.assert(iscell(val), 'MATLAB:table:unstack:AssignmentError',aNames{dataVars(t)});
                            if isscalar(val)
                                wideVar_j{i,k} = val{1};
                            else
                                wideVar_j{i,k} = fillVal{1};
                            end
                        end
                    end
                    b_data{j0+j} = reshape(wideVar_j,szOut);
                end
            else
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
                            val = fun1(tallVar(indices_ij,k));
                            nonScalarEmpty = ~(isscalar(val) || isempty(val));
                            coder.internal.errorIf(nonScalarEmpty && isempty(fun), 'MATLAB:table:unstack:MultipleRows');
                            coder.internal.errorIf(nonScalarEmpty && ~isempty(fun), 'MATLAB:table:unstack:NonscalarAggFunValue');
                            if isscalar(val)
                                wideVar_j(i,k) = val(1);
                            end
                        end
                    end
                    b_data{j0+j} = reshape(wideVar_j,szOut);
                end
                
            end
        end
        
        if ntallVars == 1
            wideNames = wideVarNames;
        else
            wideNames = coder.const(append(aNames{dataVars(t)},'_',wideVarNames));
        end
        
        % Caller-supplied wide var names given by NewDataVariableNames may be duplicate,
        % empty, or invalid; check for duplicates here and checkAgainstVarLabels
        % catches conflicts with dim names below. lengthenTo checks for invalid
        % names.
        [~, wideNamesIdx] = coder.const(@feval,'unique',coder.const(wideNames));
        dupIdx = coder.const(setdiff(1:numel(wideNames),wideNamesIdx));
        isunique = isempty(dupIdx);
        if isunique
            dupName = '';
        else
            dupName = wideNames{dupIdx(1)};
        end
        coder.internal.assert(isunique, 'MATLAB:table:DuplicateVarNames', dupName);
    
        for i = 1:numel(wideNames)
            newVarNames{(t-1)*nwideVars+i} = wideNames{i};
        end
    end
else
    coder.internal.errorIf(supplied.NewDataVariableNames && ~isempty(wideVarNames),'MATLAB:table:unstack:NewDataVarNamesEmptyDataVars');
end

% Display a warning at run time if the fill value has changed
if fillValueChanged
   coder.internal.warning('MATLAB:table:unstack:FillValueChange'); 
end

b_varDim = b_varDim.lengthenTo(b_varDim.length + nNewVars, newVarNames); 

% Check for conflicts between wide var names and original var names
coder.internal.assert(numel(coder.const(feval('unique',b_varDim.labels))) == numel(b_varDim.labels), ...
    'MATLAB:table:unstack:ConflictingNewDataVarNames');

% Detect conflicts between the wide var names (which may have been given by
% NewDataVariableNames) and the original dim names.
b.metaDim = b.metaDim.checkAgainstVarLabels(b_varDim.labels,'error');

% Copy tall per-variable properties, appropriately replicated, to wide. 
repDataVars = repmat(dataVars,nwideVars,1);
b_varDim = b_varDim.moveProps(a.varDim,[groupVarsNoRowNames constVarsNoRowNames repDataVars(:)'],1:b_varDim.length);

b = updateTabularProperties(b, b_varDim,  [], [], [], b_data);

% Put the wide table into "first occurrence" order of the tall table
if isnumeric(idx)   % not ':'
[~,idxInv] = sort(idx);
b = parenReference(b, idxInv, ':');  % b(idxInv,:)
if nargout > 1
    ia = idx(idxInv);
end
else  % ':'
    if nargout > 1
        ia = jdx;
    end
end

