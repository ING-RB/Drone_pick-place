function [c,ir] = join(a,b,varargin)
%

%   Copyright 2012-2024 The MathWorks, Inc.

import matlab.internal.tabular.selectRows

narginchk(2,inf);
if ~isa(a,'tabular') || ~isa(b,'tabular')
    error(message('MATLAB:table:join:InvalidInput'));
end

type = 'simple';
pnames = {'Keys' 'LeftKeys' 'RightKeys' 'LeftVariables' 'RightVariables' 'KeepOneCopy'};
dflts =  {   []         []          []              []               []            {} };
[keys,leftKeys,rightKeys,leftVars,rightVars,keepOneCopy,supplied] ...
         = matlab.internal.datatypes.parseArgs(pnames, dflts, varargin{:});
     
if supplied.KeepOneCopy
    % The names in keepOneCopy must be valid var names, but need not actually match a
    % duplicated variable, or even any variable.
    if isa(keepOneCopy,"pattern") && isscalar(keepOneCopy)
        keepOneCopy = a.varDim.labels(matches(a.varDim.labels,keepOneCopy));
    end
    if ~matlab.internal.datatypes.isText(keepOneCopy,false) || any(keepOneCopy == "",'all') % do not allow empty strings
        error(message('MATLAB:table:join:InvalidKeepOneCopy'));
    end
    try
        a.varDim.makeValidName(keepOneCopy,'error'); % error if invalid
    catch
        error(message('MATLAB:table:join:InvalidKeepOneCopy'));
    end
end

[leftVars,rightVars,leftVarDim,rightVarDim,leftKeyVals,rightKeyVals,leftKeys,rightKeys] ...
     = tabular.joinUtil(a,b,type,inputname(1),inputname(2), ...
                      keys,leftKeys,rightKeys,leftVars,rightVars,keepOneCopy,supplied);

if isSimpleJoinOnUniqueRowLabels(leftKeys,rightKeys,type,a,b)
    % Fast special case: row labels are unique, so joinUtil uses the right's row
    % indices as the key values, and leftKeyVals contains indices of the right's
    % rows that match the left's rows.
    ir = leftKeyVals;
else
    % Do the simple join C = [A(:,LEFTVARS) B(IB,RIGHTVARS)] by computing the row
    % indices into B for each row of C.  The row indices into A are just 1:n.

    % Check that B's key contains no duplicates.
    if length(unique(rightKeyVals)) < size(rightKeyVals,1)
        error(message('MATLAB:table:join:DuplicateRightKeyVarValues'));
    end
    
    % Use the key vars to find indices from A into B, and make sure every
    % row in A has a corresponding one in B.
    try
        [tf,ir] = ismember(leftKeyVals,rightKeyVals);
    catch me
        error(message('MATLAB:table:join:KeyIsmemberMethodFailed', me.message));
    end
    if ~isequal(size(tf),[length(leftKeyVals),1])
        error(message('MATLAB:table:join:KeyIsmemberMethodReturnedWrongSize'));
    elseif any(~tf)
        nkeys = numel(leftKeys);

        % First check if any keys, either vars or row labels, contain missing values.
        % Otherwise throw an error about unmatched key values.
        aKeys = a(:,leftKeys(leftKeys>0));
        missingInLeft = any(ismissing(aKeys),2);
        if any(leftKeys == 0) && a.rowDim.hasLabels
            missingInLeft = missingInLeft | ismissing(a.rowDim.labels);
        end
        bKeys = b(:,rightKeys(rightKeys>0));
        missingInRight = any(ismissing(bKeys),2);
        if any(rightKeys == 0) && b.rowDim.hasLabels
            missingInRight = missingInRight | ismissing(b.rowDim.labels);
        end
        if any(missingInLeft) || any(missingInRight)
            error(message('MATLAB:table:join:MissingKeyValues'));
        elseif nkeys == 1 %#ok<ISCL>
            error(message('MATLAB:table:join:LeftKeyValueNotFound'));
        else
            error(message('MATLAB:table:join:LeftKeyValuesNotFound'));
        end
    end
end

% Create a new table by combining the specified variables from A with those
% from B, the latter broadcasted out to A's length using the key variable
% indices.

c = a; % preserve all of a's per-array
if isa(c,"eventtable") && istimetable(b)
    b.rowDim = b.rowDim.setTimeEvents([]);
end
c.rowDim = c.rowDim.mergeProps(b.rowDim); % merge rowDim props
numLeftVars = length(leftVars);
numRightVars = length(rightVars);
c.data = [a.data(leftVars) cell(1,numRightVars)];
for j = 1:numRightVars
    var_j = b.data{rightVars(j)};
    c.data{numLeftVars+j} = selectRows(var_j,ir);
end

% Assign names and merge a's and b's per-var properties.
c_varDim = leftVarDim.lengthenTo(numLeftVars+numRightVars,rightVarDim.labels);
c.varDim = c_varDim.moveProps(rightVarDim,1:numRightVars,numLeftVars+(1:numRightVars));

% For key variables, per-variable properties need to be filled. However, if
% either leftvariables or rightvariables or both were supplied, everything
% will be handled automatically as it either means keys are not merged
if ~supplied.LeftVariables && ~supplied.RightVariables && ...
   ~isequal(leftKeys,0) && ~isequal(rightKeys,0) % no need to merge if joining on rownames
    %Must used b.varDim not rightVarDim, as rightVarDim may have been modified already to drop key variable
    c.varDim = c.varDim.fillEmptyProps(b.varDim,rightKeys,leftKeys); 
end

% Copy any tagged properties that may have been missed.
c.varDim = c.varDim.copyTags(a.varDim,b.varDim,leftVars,rightVars,c.rowDim,c.data);


%-----------------------------------------------------------------------
function tf = isSimpleJoinOnUniqueRowLabels(leftKeys,rightKeys,type,a,b)
tf = isequal(leftKeys,rightKeys,0) && matches(type,"simple","IgnoreCase",true) ...
    && a.rowDim.requireUniqueLabels && b.rowDim.requireUniqueLabels;
