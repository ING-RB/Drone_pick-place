function [c,il,ir] = outerjoin(a,b,varargin) %#codegen
%OUTERJOIN Outer join between two tables or two timetables.

%   Copyright 2020-2023 The MathWorks, Inc.
coder.extrinsic('append', 'intersect', 'ismember', 'matches', 'matlab.lang.makeUniqueStrings', 'namelengthmax');

narginchk(2,inf);
coder.internal.assert(istabular(a) && istabular(b), 'MATLAB:table:join:InvalidInput');

keepOneCopy = [];
pnames = {'Type' 'Keys' 'LeftKeys' 'RightKeys' 'MergeKeys' 'LeftVariables' 'RightVariables'};
poptions = struct('CaseSensitivity', false, ...
                  'PartialMatching', 'unique', ...
                  'StructExpand',    false);
supplied = coder.internal.parseParameterInputs(pnames, poptions, varargin{:});
supplied.KeepOneCopy = 0;

type        = coder.internal.getParameterValue(supplied.Type,       'full', varargin{:});
keys        = coder.internal.getParameterValue(supplied.Keys,           [], varargin{:});
leftKeys    = coder.internal.getParameterValue(supplied.LeftKeys,       [], varargin{:});
rightKeys   = coder.internal.getParameterValue(supplied.RightKeys,      [], varargin{:});
mergeKeys   = coder.internal.getParameterValue(supplied.MergeKeys,   false, varargin{:});
leftVars    = coder.internal.getParameterValue(supplied.LeftVariables,  [], varargin{:});
rightVars   = coder.internal.getParameterValue(supplied.RightVariables, [], varargin{:});

coder.internal.assert(coder.internal.isConst(type),       'MATLAB:table:join:NonConstantArg', 'Type');
coder.internal.assert(coder.internal.isConst(keys),       'MATLAB:table:join:NonConstantArg', 'Keys');
coder.internal.assert(coder.internal.isConst(leftKeys),   'MATLAB:table:join:NonConstantArg', 'LeftKeys');
coder.internal.assert(coder.internal.isConst(rightKeys),  'MATLAB:table:join:NonConstantArg', 'RightKeys');
coder.internal.assert(coder.internal.isConst(mergeKeys),  'MATLAB:table:join:NonConstantArg', 'MergeKeys');
coder.internal.assert(coder.internal.isConst(leftVars),   'MATLAB:table:join:NonConstantArg', 'LeftVariables');
coder.internal.assert(coder.internal.isConst(rightVars),  'MATLAB:table:join:NonConstantArg', 'RightVariables');

coder.internal.assert(matlab.internal.coder.datatypes.isScalarText(type,false),'MATLAB:table:join:InvalidType'); % assume scalar text without missing/zerolength
types = {'inner' 'left' 'right' 'full'};
[i,type] = matlab.internal.coder.datatypes.getChoice(type,types,'MATLAB:table:join:InvalidType');

leftOuter = coder.const((i == 2) || (i >= 4));
rightOuter = coder.const(i >= 3);

mergeKeys = matlab.internal.coder.datatypes.validateLogical(mergeKeys,'MergeKeys');

[leftVars,rightVars_from_joinUtil,leftVarDim_from_joinUtil,rightVarDim_from_joinUtil,leftKeyVals,rightKeyVals,leftKeys,rightKeys,c_metaDim] ...
     = tabular.joinUtil(a,b,type,'','', ...
                        keys,leftKeys,rightKeys,leftVars,rightVars,keepOneCopy,mergeKeys,supplied);

if mergeKeys
    % A key pair with row labels from both is _always_ merged (in joinInnerOuter),
    % but row labels aren't among the data vars in the output, so no need to remove
    % them from the right's data vars or rename them in the left's.
    %
    % However, a row labels key may be paired with a key var in the other input.
    % Leave out any of B's key vars that correspond to a row labels key in A, the
    % key values from B will be merged into C's row labels (by joinInnerOuter).
    removeFromRight = coder.const(ismember(rightVars_from_joinUtil,rightKeys(leftKeys==0)));
    rightVars_without_a_rowname_keys = subsasgnParens(rightVars_from_joinUtil,removeFromRight,[]);
    rightVarDim_without_a_rowname_keys = rightVarDim_from_joinUtil.deleteFrom(coder.const(feval('find',removeFromRight)));
    % That still leaves a row labels key in B that corresponds to a key var in A,
    % those will be merged into C's key var below.
    
    % Find keys that appear in both leftVars and rightVars, and remove them from
    % rightVars. Remaining keys appear only once, either in leftVars or rightVars.
    inLeft = coder.const(ismember(leftKeys,leftVars));
    [inRight,locr] = coder.const(@ismember,rightKeys,rightVars_without_a_rowname_keys);
    inBoth = inLeft(:) & inRight(:);
    removeFromRight = locr(inBoth);
    rightVars_for_joinInnerOuter = subsasgnParens(rightVars_without_a_rowname_keys,removeFromRight,[]);
    rightVarDim_without_leftVars_keys = rightVarDim_without_a_rowname_keys.deleteFrom(removeFromRight);
    
    % Find the locations of keys in leftVars, keys from A will appear in the
    % output in those same locations. Find the (possibly thinned) locations of
    % keys in rightVars, keys from B will appear in the output in those same
    % locations, offset by length(leftVars). In other words, the order of the
    % keys in the output C, and the order in which keys are actually merged
    % below, is determined by their order in leftVars and rightVars, not their
    % order in the inputs A and B, or their order in leftKeys and rightKeys.
    [~,keyVarLocsInLeftVars,locl] = coder.const(@intersect,leftVars,leftKeys,'stable');
    [~,keyVarLocsInRightVars,locr] = coder.const(@intersect,rightVars_for_joinInnerOuter,rightKeys,'stable');
    keyVarLocsInOutput = [keyVarLocsInLeftVars; length(leftVars)+keyVarLocsInRightVars]; % where are the key vars in the output?
    numKeyVarsInOutputFromLeft = length(locl);
    numKeyVarsInOutputFromRight = length(locr);
    
    % Link the key vars in the output back to vars in A and B, using the same
    % order as keyVarLocsInOutput.
    keyVarLocsInLeftInput = leftKeys([locl; locr]); % where in A did the key vars come from?
    keyVarLocsInRightInput = rightKeys([locl; locr]); % where in B did the key vars come from?
    
    % When MergeKeys is true and a key pair appears in both leftVars and
    % rightVars, outerjoin creates the merged key as the dominant type. Keep
    % track of those, same order as keyVarLocsInOutput.
    castToDominantKeyType = inBoth([locl; locr]);
    
    % Create a concatenated key var name wherever the names differ between the right
    % and left, use leave the existing name alone wherever they don't. This merges
    % the names even if one of the key pair was explicitly left out of the specified
    % output vars.
    %
    % Key names that were common between the two inputs had a suffix added in
    % leftVarDim and rightVarDim by joinUtil. That's not needed when merging keys,
    % so go back to the original names from the two inputs.
    keyNamesFromLeftInput = getVarOrRowLabelsNames(a,keyVarLocsInLeftInput);
    keyNamesFromRightInput = getVarOrRowLabelsNames(b,keyVarLocsInRightInput);
    keyNames = keyNamesFromLeftInput;
    diffNames = ~coder.const(matches(keyNamesFromLeftInput,keyNamesFromRightInput));
    if any(diffNames)
        keyNames2 = subsasgnParens(keyNames,diffNames,coder.const(append(subsrefParens(keyNamesFromLeftInput,diffNames),'_',subsrefParens(keyNamesFromRightInput,diffNames))));
    else
        keyNames2 = keyNames;
    end
    
    % Unique the key names against the already unique left and right data var names.
    varNames = coder.const(feval('horzcat',leftVarDim_from_joinUtil.labels,rightVarDim_without_leftVars_keys.labels));
    varNames = subsasgnParens(varNames,keyVarLocsInOutput,[]); % remove names of keys
    otherNames = coder.const(feval('horzcat',varNames,c_metaDim.labels));
    keyNames2 = coder.const(matlab.lang.makeUniqueStrings(keyNames2,otherNames,coder.const(namelengthmax)));
    
    leftVarDimLabels = subsasgnParens(leftVarDim_from_joinUtil.labels,keyVarLocsInLeftVars,subsrefParens(keyNames2,1:numKeyVarsInOutputFromLeft));
    leftVarDim_for_joinInnerOuter = leftVarDim_from_joinUtil.createLike(length(leftVarDimLabels),leftVarDimLabels);
    rightVarDimLabels = subsasgnParens(rightVarDim_without_leftVars_keys.labels,keyVarLocsInRightVars,subsrefParens(keyNames2,numKeyVarsInOutputFromLeft+(1:numKeyVarsInOutputFromRight)));
    rightVarDim_for_joinInnerOuter = rightVarDim_without_leftVars_keys.createLike(length(rightVarDimLabels),rightVarDimLabels);
else
    rightVarDim_for_joinInnerOuter = rightVarDim_from_joinUtil;
    leftVarDim_for_joinInnerOuter = leftVarDim_from_joinUtil;
    rightVars_for_joinInnerOuter = rightVars_from_joinUtil;
end

mergeKeyProps = mergeKeys && (~supplied.LeftVariables && ~supplied.RightVariables);

[c,il,ir] = tabular.joinInnerOuter(a,b,leftOuter,rightOuter,leftKeyVals,rightKeyVals, ...
                                   leftVars,rightVars_for_joinInnerOuter,leftKeys,rightKeys,leftVarDim_for_joinInnerOuter,rightVarDim_for_joinInnerOuter, ...
                                   mergeKeyProps,c_metaDim);

if mergeKeys
    % A (non-row label) merged key var's type in C will be based on the key
    % from the left input A (if the key appears only in LeftVariables), or
    % from the right input B (if the key appears only in RightVariables), or
    % from whichever is dominant (if the key appears in both). In the first
    % two cases, joinInnerOuter creates the key var in C by broadcasting
    % values from the key var in A (or B) out to the correct height, and
    % then below, the missing values in the unmatched "right-only" (or
    % "left-only") rows in C are filled in with values broadcast from the
    % key var in B (or A). There may still be missing values in C's key var
    % if there were missing values in the original key vars, but those are
    % not due to "no source row". Even if no "right-only" (or "left-only")
    % rows need to be filled in, always do the assignment to get error
    % checking for mixed key types.
    %
    % In the third case, where the key appears in both LeftVariables and
    % RightVariables, joinInnerOuter initially creates the key var in C
    % based on the key var in A, but below, C's key is cast to B's key var
    % type if that is dominant.
    %
    % The key var properties from A and B have been merged B's-into-A's by
    % joinInnerOuter (regardless of which key makes it into C), however
    % properties are not merged into a row labels key.
    
    % Loop over keys in their order in C, first the keys that came from A,
    % then those that came from B.
    %
    % Merge B's key values into the key vars that came from A.
    a_data = a.data;
    b_data = b.data;
    c_data = c.data;
    useRight = (il == 0);
    coder.unroll();
    for i = 1:numKeyVarsInOutputFromLeft
        isrc = keyVarLocsInRightInput(i);
        idest = keyVarLocsInOutput(i);
        if isrc > 0 % var/var key pair
            b_keyVar = b_data{isrc};
        else % var/rowLabels key pair
            b_keyVar = b.rowDim.labels;
        end
        if castToDominantKeyType(i)
            % The key var in C has been created from the A's key var. In a
            % mixed-type key pair where the key appeared in both leftVars
            % and rightVars, B's key type may be dominant, cast before
            % making the assignment, by concatenating with an empty of B's
            % key's type.
            if ~iscell(c_data{idest}) && ~iscell(b_keyVar)
                c_data{idest} = [c_data{idest}; b_keyVar([])];
            else
                if iscell(c_data{idest}) && ~iscell(b_keyVar)
                    c_data{idest} = [c_data{idest}; b_keyVar([])];
                elseif ~iscell(c_data{idest}) && iscell(b_keyVar)
                    c_data{idest} = [c_data{idest}; {}];
                end
            end
        end
        % Copy values from B's key into unmatched "right-only" rows. If the
        % key appeared _only_ in leftVars, casting is not done and the
        % assignment may error for mixed-type key pairs.
        if ~iscell(c_data{idest}) && ~iscell(b_keyVar)
            c_data{idest}(useRight,:) = b_keyVar(ir(useRight),:);
        elseif ~iscell(c_data{idest}) && iscell(b_keyVar)
            for ii = 1:numel(useRight)
                if useRight(ii)
                    for j = 1:numel(c_data{idest}(ii,:))
                        c_data{idest}(ii,j) = b_keyVar{ir(ii),j};
                    end
                end
            end
        elseif iscell(c_data{idest}) && ~iscell(b_keyVar)
            for ii = 1:numel(useRight)
                if useRight(ii)
                    for j = 1:numel(c_data{idest}(ii,:))
                        c_data{idest}{ii,j} = b_keyVar(ir(ii),j);
                    end
                end
            end
        else % iscell(c_data{idest}) && iscell(b_keyVar)
            for ii = 1:numel(useRight)
                if useRight(ii)
                    sz_c_data_idest = size(c_data{idest});
                    for j = 1:prod(sz_c_data_idest(2:end))
                        c_data{idest}{ii,j} = b_keyVar{ir(ii),j};
                    end
                end
            end
        end
    end
    
    % Merge A's key values into the key vars that came from B.
    useLeft = (ir == 0);
    coder.unroll();
    for i = numKeyVarsInOutputFromLeft + (1:numKeyVarsInOutputFromRight)
        isrc = keyVarLocsInLeftInput(i);
        idest = keyVarLocsInOutput(i);
        % Copy values from A's key into unmatched "left-only" rows. No need
        % to worry about casting C's key var to the dominant type: If the
        % key appeared in both leftVars and rightVars, it was removed from
        % rightVars, and doesn't get here (although B's key may have been
        % used above to do the cast). If the key appeared _only_ in
        % rightVars, casting is not done, and the assignment may error for
        % mixed-type key pairs.
        if ~iscell(c_data{idest}) && ~iscell(a_data{isrc})
            c_data{idest}(useLeft,:) = a_data{isrc}(il(useLeft),:);
        elseif iscell(c_data{idest}) && iscell(a_data{isrc})
            idxUseLeft = find(useLeft);
            for k = 1:length(idxUseLeft)
                for m = 1:size(a_data{isrc},2)
                    c_data{idest}{idxUseLeft(k),m} = a_data{isrc}{il(idxUseLeft(k)),m};
                end
            end
        else % This case should have been caught in joinUtil.
            assert(false);
        end
    end
    c.data = c_data;
end

% If not merging, leftVariables or rightVariables indicates exactly which key
% variables are returned in the output (default is all). Neither the keys nor
% their properties are merged.


%-----------------------------------------------------------------------
function names = getVarOrRowLabelsNames(t,indices)
isRowLabels = (indices == 0);
names = subsasgnParens({},isRowLabels,{t.metaDim.labels{1}});
names = subsasgnParens(names,~isRowLabels,subsrefParens(t.varDim.labels,indices(~isRowLabels)));

%-----------------------------------------------------------------------
function C = subsasgnParens(A,idx,B)
coder.extrinsic('subsasgn', 'substruct');
C = coder.const(subsasgn(A,substruct('()',{idx}),B));

%-----------------------------------------------------------------------
function C = subsrefParens(A,idx)
coder.extrinsic('subsref', 'substruct');
C = coder.const(subsref(A,substruct('()',{idx})));
