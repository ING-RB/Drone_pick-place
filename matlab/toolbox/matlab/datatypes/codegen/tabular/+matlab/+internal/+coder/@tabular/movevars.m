function b = movevars(a,vars,varargin) %#codegen
%MOVEVARS Move the specified table variables to a new location.

%   Copyright 2020 The MathWorks, Inc.

% TODO ==> Assert that VARS is constant

pnames = {'Before'  'After' };
poptions = struct('CaseSensitivity', false, ...
                  'PartialMatching', 'unique', ...
                  'StructExpand',    false);
supplied = coder.internal.parseParameterInputs(pnames, poptions, varargin{:});

% Exactly _one_ of BEFORE or AFTER (not both) must be specified
coder.internal.assert(~(supplied.After && supplied.Before), 'MATLAB:table:addmovevars:BeforeAndAfter');

% Get BEFORE/AFTER parameter values
before = coder.internal.getParameterValue(supplied.Before, [],              varargin{:});
after = coder.internal.getParameterValue(supplied.After,   a.varDim.length, varargin{:});

% BEFORE/AFTER must be constant size
coder.internal.assert(coder.internal.isConst(size(before)) && coder.internal.isConst(size(after)), ...
    'MATLAB:table:addmovevars:NoVarSizeBeforeAndAfter')

% Special case for empty tables
if a.varDim.length == 0
    % When a is an empty table, the only allowed LOCATIONs are:
    % - the end: 'Before', width(t)+1, 'After' width(t),
    % - the beginning: 'After' 0, or 'Before' 1, or 'After' false
    % ('After', false is consistent with table subscripting.)
    % Note that these are degenerate for width(t) = 0
    % If before/after are not a valid value, pass it to subs2inds in order
    % to throw the right error.
    if supplied.Before
        % allow movevars(t,[],'Before',width(t)+1) or 'Before', [true false false ...]
        isValidNumericBefore = isscalar(before) && (before == 1);
        isValidLogicalBefore = islogical(before) && isvector(before) && before(1);
        if  isValidNumericBefore || isValidLogicalBefore
            b = a;
        else % get subs2inds to throw the right error
            a.varDim.subs2inds(before);
        end
    else %supplied.After
        % allow movevars(t,[],'After',0) or 'After', [false false false...]
        isValidNumericAfter = isscalar(after) && after == 0;
        isValidLogicalAfter = islogical(after) && isvector(after) && ~any(after);
        if isValidNumericAfter || isValidLogicalAfter 
            b = a;
        else % get subs2inds to throw the right error
            a.varDim.subs2inds(after);
        end
    end
    % Having validated vars (must be []) and LOCATION, we are moving
    % nothing, so return.
    return
end

% Support edge cases of 'After' 0 and 'Before' width(t)+1 which could be
% hit programmatically with empty tables.
if supplied.Before
    if isnumeric(before) && isscalar(before) && before == a.varDim.length + 1
        pos = before - 1;
        supplied.Before = zeros(1,'like',supplied.Before);
        supplied.After = ones(1,'like',supplied.After); %% 0 = not supplied; >0 = idx into arg array
    elseif islogical(before)
        pos = find(before);
    else
        pos = before;
    end
else % supplied.After
    if isnumeric(after) && isscalar(after) && after == 0
        pos = 1;
        supplied.Before = ones(1,'like',supplied.After); %% 0 = not supplied; >0 = idx into arg array
        supplied.After = zeros(1,'like',supplied.Before);
    elseif islogical(after)
        pos = find(after);
    else
        pos = after;
    end
end

coder.internal.errorIf(isa(pos,'vartype'), 'MATLAB:table:addmovevars:InvalidLocation','vartype subscripter');
pos = a.varDim.subs2inds(pos);
coder.internal.assert(isscalar(pos), 'MATLAB:table:addmovevars:NonscalarPosition');

if isempty(vars) % Nothing needs to be moved
    coder.internal.errorIf(ischar(vars), 'MATLAB:table:InvalidVarName'); % VARS cannot be ''
    b = a;
else % Rearrange indices to reference from original table
    coder.internal.errorIf(isa(vars,'vartype'), 'MATLAB:table:addmovevars:VartypeInvalidVars');
    
    if ischar(vars)
        vars = a.varDim.subs2inds(vars);
    else % make sure non-char indices are vector
        vars = a.varDim.subs2inds(reshape(vars,numel(vars),[]));
    end

    % Unify both before/after into after, with 0 indicating front.
    % If location is in vars, treat before the same as after (both mean 'at').
    if supplied.Before && coder.internal.scalarizedAll(@(v)v~=pos,vars) % supplied.Before && ~any(vars==pos)
        pos = pos - 1;
    end
    
    % Update destination, POS, based on the index after discounting indices to
    % be moved. If LOCATION is in VARS, need to account for that.
    % Compute STAYINGIDX, numeric indices for variables that are not moving
    % by excluding VARS from array of all indices, ALLIDX
    allIdx = 1:a.varDim.length;
    if islogical(vars)
        pos = pos - nnz(vars(1:pos));
        stayingIdx = allIdx(~vars);
    else
        coder.internal.assert(...
            length(matlab.internal.coder.datatypes.constUnique(vars)) == length(vars),...
            'MATLAB:table:addmovevars:DuplicatedVariablesNotSupported');
        pos = pos - nnz(vars <= pos);        
        stayingIdx = coder.const(feval('setdiff', 1:a.varDim.length, vars));
    end
        
    % Compute rearranged indices. To fill REARRANGEDIDX, iterate along both
    % REARRANGEDIDX and STAYINGIDX. When iteration on REARRANGEDIDX...
    % - reaches target move position, POS+1, insert all of MOVEIDX
    % - outside the range of move position, i.e. (pos:pos+movingIdx_count],
    %   copy from stayingIDX __until__ all stayingIDX have been copied over
    numMovingVars = nnz(vars);
    rearrangedIdx_count = length(stayingIdx) + numMovingVars; % If no duplicate, this equals a.varDim.length
    rearrangedIdx = zeros(1,rearrangedIdx_count); % preallocate array of rearranged indices
    stayingIdx_ptr = 1; % reset pointer to array of stayingIdx
    for rearrangedIdx_ptr = coder.unroll(1:rearrangedIdx_count)
        if (rearrangedIdx_ptr == pos + 1) % reaches target move location
            rearrangedIdx = matlab.internal.coder.datatypes.constIndexAssign(...
                rearrangedIdx,...
                rearrangedIdx_ptr : rearrangedIdx_ptr+numMovingVars-1,...
                allIdx(vars));
            
        elseif stayingIdx_ptr<=length(stayingIdx)
            if (rearrangedIdx_ptr<pos+1) || (rearrangedIdx_ptr > pos + numMovingVars)
                rearrangedIdx(rearrangedIdx_ptr) = stayingIdx(stayingIdx_ptr);
                stayingIdx_ptr = stayingIdx_ptr + 1;
            end
        end
    end
    
    % Return a new table with rearranged variables using REARRANGEDIDX
    b = a.parenReference(':', coder.const(rearrangedIdx));
end