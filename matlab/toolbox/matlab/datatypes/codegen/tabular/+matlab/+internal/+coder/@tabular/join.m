function [c,ir] = join(a,b,varargin) %#codegen
%JOIN Merge tables or timetables by matching up rows using key variables.

%   Copyright 2020-2021 The MathWorks, Inc.

coder.extrinsic('matlab.internal.datatypes.isText');

narginchk(2,inf);
coder.internal.errorIf(~isa(a,'tabular') || ~isa(b,'tabular'),'MATLAB:table:join:InvalidInput');

type = 'simple';
mergeKeys = [];
pnames = {'Keys' 'LeftKeys' 'RightKeys' 'LeftVariables' 'RightVariables' 'KeepOneCopy'};
poptions = struct('CaseSensitivity', false, ...
                  'PartialMatching', 'unique', ...
                  'StructExpand',    false);
supplied = coder.internal.parseParameterInputs(pnames, poptions, varargin{:});

keys        = coder.internal.getParameterValue(supplied.Keys,           [], varargin{:});
leftKeys    = coder.internal.getParameterValue(supplied.LeftKeys,       [], varargin{:});
rightKeys   = coder.internal.getParameterValue(supplied.RightKeys,      [], varargin{:});
leftVars    = coder.internal.getParameterValue(supplied.LeftVariables,  [], varargin{:});
rightVars   = coder.internal.getParameterValue(supplied.RightVariables, [], varargin{:});
keepOneCopy = coder.internal.getParameterValue(supplied.KeepOneCopy,    {}, varargin{:});

coder.internal.assert(coder.internal.isConst(keys),        'MATLAB:table:join:NonConstantArg', 'Keys');
coder.internal.assert(coder.internal.isConst(leftKeys),    'MATLAB:table:join:NonConstantArg', 'LeftKeys');
coder.internal.assert(coder.internal.isConst(rightKeys),   'MATLAB:table:join:NonConstantArg', 'RightKeys');
coder.internal.assert(coder.internal.isConst(leftVars),    'MATLAB:table:join:NonConstantArg', 'LeftVariables');
coder.internal.assert(coder.internal.isConst(rightVars),   'MATLAB:table:join:NonConstantArg', 'RightVariables');
coder.internal.assert(coder.internal.isConst(keepOneCopy), 'MATLAB:table:join:NonConstantArg', 'KeepOneCopy');

if supplied.KeepOneCopy
    % The names in keepOneCopy must be valid var names, but need not actually match a
    % duplicated variable, or even any variable.
    coder.internal.assert(coder.const(matlab.internal.datatypes.isText(keepOneCopy,false)) && ~any(keepOneCopy == "",'all'),'MATLAB:table:join:InvalidKeepOneCopy'); % do not allow empty strings
    a.varDim.makeValidName(keepOneCopy,'error'); % error if invalid
end

[leftVars,rightVars,leftVarDim,rightVarDim,leftKeyVals,rightKeyVals,leftKeys,rightKeys] ...
     = tabular.joinUtil(a,b,type,'','', ...
                      keys,leftKeys,rightKeys,leftVars,rightVars,keepOneCopy,mergeKeys,supplied);

if isSimpleJoinOnUniqueRowLabels(leftKeys,rightKeys,type,a,b)
    % Fast special case: row labels are unique, so joinUtil uses the right's row
    % indices as the key values, and leftKeyVals contains indices of the right's
    % rows that match the left's rows.
    ir = leftKeyVals;
else
    % Do the simple join C = [A(:,LEFTVARS) B(IB,RIGHTVARS)] by computing the row
    % indices into B for each row of C.  The row indices into A are just 1:n.

    % Check that B's key contains no duplicates.
    coder.internal.errorIf(length(unique(rightKeyVals)) < size(rightKeyVals,1),'MATLAB:table:join:DuplicateRightKeyVarValues');
    
    % Use the key vars to find indices from A into B, and make sure every
    % row in A has a corresponding one in B.
    [tf,ir] = ismember(leftKeyVals,rightKeyVals);
    coder.internal.errorIf(~isequal(size(tf),[length(leftKeyVals),1]),'MATLAB:table:join:KeyIsmemberMethodReturnedWrongSize');
    anyNotTf = any(~tf,'all');
    if anyNotTf
        nkeys = numel(leftKeys);

        % First check if any keys, either vars or row labels, contain missing values.
        % Otherwise throw an error about unmatched key values.
        aKeys = a.parenReference(':',leftKeys(leftKeys>0));
        missingInLeft = any(ismissing(aKeys),2);
        if any(leftKeys == 0) && a.rowDim.hasLabels
            missingInLeft = missingInLeft | ismissing(a.rowDim.labels);
        end
        bKeys = b.parenReference(':',rightKeys(rightKeys>0));
        missingInRight = any(ismissing(bKeys),2);
        if any(rightKeys == 0) && b.rowDim.hasLabels
            missingInRight = missingInRight | ismissing(b.rowDim.labels);
        end
        coder.internal.errorIf(anyNotTf && (any(missingInLeft) || any(missingInRight)),'MATLAB:table:join:MissingKeyValues');
        coder.internal.errorIf(anyNotTf && nkeys == 1 && ~(any(missingInLeft) || any(missingInRight)),'MATLAB:table:join:LeftKeyValueNotFound');
        coder.internal.errorIf(anyNotTf && ~((any(missingInLeft) || any(missingInRight)) || nkeys == 1),'MATLAB:table:join:LeftKeyValuesNotFound');
    end
end

% Create a new table by combining the specified variables from A with those
% from B, the latter broadcasted out to A's length using the key variable
% indices.
c = a.cloneAsEmpty; % preserve all of a's per-array and per-row properties
c.metaDim = a.metaDim;
c.rowDim = a.rowDim;
c.arrayProps = a.arrayProps;
numLeftVars = length(leftVars);
numRightVars = length(rightVars);
c.data = cell(1,numLeftVars+numRightVars);
for j = 1:numLeftVars
    c.data{j} = a.data{leftVars(j)};
end
for j = 1:numRightVars
    var_j = b.data{rightVars(j)};
    c.data{numLeftVars+j} = matlab.internal.coder.tabular.selectRows(var_j,ir);
end

% Assign names and merge a's and b's per-var properties.
c_varDim = leftVarDim.lengthenTo(numLeftVars+numRightVars,rightVarDim.labels);
c_varDim = c_varDim.moveProps(rightVarDim,1:numRightVars,numLeftVars+(1:numRightVars));

% For key variables, per-variable properties need to be filled. However, if
% either leftvariables or rightvariables or both were supplied, everything
% will be handled automatically as it either means keys are not merged
if ~supplied.LeftVariables && ~supplied.RightVariables && ...
   ~isequal(leftKeys,0) && ~isequal(rightKeys,0) % no need to merge if joining on rownames
    %Must used b.varDim not rightVarDim, as rightVarDim may have been modified already to drop key variable
    c.varDim = c_varDim.fillEmptyProps(b.varDim,rightKeys,leftKeys);
else
    c.varDim = c_varDim;
end



%-----------------------------------------------------------------------
function tf = isSimpleJoinOnUniqueRowLabels(leftKeys,rightKeys,type,a,b)
coder.extrinsic('matches');
tf = isequal(leftKeys,rightKeys,0) && coder.const(matches(type,"simple","IgnoreCase",true)) ...
    && a.rowDim.requireUniqueLabels && b.rowDim.requireUniqueLabels;
