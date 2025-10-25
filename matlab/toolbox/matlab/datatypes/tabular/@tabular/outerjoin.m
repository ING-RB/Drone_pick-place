function [c,il,ir] = outerjoin(a,b,varargin)
%

%   Copyright 2012-2024 The MathWorks, Inc.

import matlab.internal.datatypes.validateLogical

narginchk(2,inf);
if ~istabular(a) || ~istabular(b)
    error(message('MATLAB:table:join:InvalidInput'));
end

keepOneCopy = [];
pnames = {'Type' 'Keys' 'LeftKeys' 'RightKeys' 'MergeKeys' 'LeftVariables' 'RightVariables'};
dflts =  {'full'    []         []          []       false              []               [] };
[type,keys,leftKeys,rightKeys,mergeKeys,leftVars,rightVars,supplied] ...
         = matlab.internal.datatypes.parseArgs(pnames, dflts, varargin{:});
supplied.KeepOneCopy = 0;

if ~matlab.internal.datatypes.isScalarText(type,false) % assume scalar text without missing/zerolength
    error(message('MATLAB:table:join:InvalidType'));
end
types = {'inner' 'left' 'right' 'full'};
i = matlab.internal.datatypes.getChoice(type,types,'MATLAB:table:join:InvalidType');
type = types(i);

leftOuter = (i == 2) || (i >= 4);
rightOuter = (i >= 3);

mergeKeys = validateLogical(mergeKeys,'MergeKeys');

[leftVars,rightVars,leftVarDim,rightVarDim,leftKeyVals,rightKeyVals,leftKeys,rightKeys,c_metaDim] ...
     = tabular.joinUtil(a,b,type,inputname(1),inputname(2), ...
                        keys,leftKeys,rightKeys,leftVars,rightVars,keepOneCopy,supplied);

if mergeKeys
    % A key pair with row labels from both is _always_ merged (in joinInnerOuter),
    % but row labels aren't among the data vars in the output, so no need to remove
    % them from the right's data vars or rename them in the left's.
    %
    % However, a row labels key may be paired with a key var in the other input.
    % Leave out any of B's key vars that correspond to a row labels key in A, the
    % key values from B will be merged into C's row labels (by joinInnerOuter).
    removeFromRight = ismember(rightVars,rightKeys(leftKeys==0));
    rightVars(removeFromRight) = [];
    rightVarDim = rightVarDim.deleteFrom(removeFromRight);
    % That still leaves a row labels key in B that corresponds to a key var in A,
    % those will be merged into C's key var below.
    
    % Find keys that appear in both leftVars and rightVars, and remove them from
    % rightVars. Remaining keys appear only once, either in leftVars or rightVars.
    inLeft = ismember(leftKeys,leftVars);
    [inRight,locr] = ismember(rightKeys,rightVars);
    inBoth = inLeft(:) & inRight(:);
    removeFromRight = locr(inBoth);
    rightVars(removeFromRight) = [];
    rightVarDim = rightVarDim.deleteFrom(removeFromRight);
    
    % Find the locations of keys in leftVars, keys from A will appear in the
    % output in those same locations. Find the (possibly thinned) locations of
    % keys in rightVars, keys from B will appear in the output in those same
    % locations, offset by length(leftVars). In other words, the order of the
    % keys in the output C, and the order in which keys are actually merged
    % below, is determined by their order in leftVars and rightVars, not their
    % order in the inputs A and B, or their order in leftKeys and rightKeys.
    [~,keyVarLocsInLeftVars,locl] = intersect(leftVars,leftKeys,'stable');
    [~,keyVarLocsInRightVars,locr] = intersect(rightVars,rightKeys,'stable');
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
    diffNames = ~matches(keyNamesFromLeftInput,keyNamesFromRightInput);
    if any(diffNames)
        keyNames(diffNames) = append(keyNamesFromLeftInput(diffNames),'_',keyNamesFromRightInput(diffNames));
    end
    
    % Unique the key names against the already unique left and right data var names.
    varNames = [leftVarDim.labels rightVarDim.labels];
    varNames(keyVarLocsInOutput) = []; % remove names of keys
    otherNames = [varNames c_metaDim.labels];
    keyNames = matlab.lang.makeUniqueStrings(keyNames,otherNames,namelengthmax);
    
    leftVarDim = leftVarDim.setLabels(keyNames(1:numKeyVarsInOutputFromLeft),keyVarLocsInLeftVars);
    rightVarDim = rightVarDim.setLabels(keyNames(numKeyVarsInOutputFromLeft+(1:numKeyVarsInOutputFromRight)),keyVarLocsInRightVars);
end

mergeKeyProps = mergeKeys && (~supplied.LeftVariables && ~supplied.RightVariables);

[c,il,ir] = tabular.joinInnerOuter(a,b,leftOuter,rightOuter,leftKeyVals,rightKeyVals, ...
                                   leftVars,rightVars,leftKeys,rightKeys,leftVarDim,rightVarDim, ...
                                   mergeKeyProps,c_metaDim);

if mergeKeys
    try
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
                c_data{idest} = [c_data{idest}; b_keyVar([])];
            end
            % Copy values from B's key into unmatched "right-only" rows. If the
            % key appeared _only_ in leftVars, casting is not done and the
            % assignment may error for mixed-type key pairs.
            c_data{idest}(useRight,:) = b_keyVar(ir(useRight),:);
        end
        
        % Merge A's key values into the key vars that came from B.
        useLeft = (ir == 0);
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
            c_data{idest}(useLeft,:) = a_data{isrc}(il(useLeft),:);
        end
    catch ME
        if ME.identifier == "MATLAB:UnableToConvert"
            % Some pairs of key types that are compatible for concatenation as
            % used in joinUtil might not be compatible for assignment (e.g.
            % duration and double). Casting to the dominant type (should)
            % prevent this, but that's only done when both keys in a pair are
            % selected in LeftVariables/RightVariables.
            causes = ME.cause;
            destKeyName = c.varDim.labels{idest};
            ME = MException(message('MATLAB:table:join:KeyMergeFailed',destKeyName));
            for i = 1:length(causes), ME = addCause(ME,causes{i}); end
        end
        throw(ME)
    end
    c.data = c_data;
end

% If not merging, leftVariables or rightVariables indicates exactly which key
% variables are returned in the output (default is all). Neither the keys nor
% their properties are merged.


%-----------------------------------------------------------------------
function names = getVarOrRowLabelsNames(t,indices)
isRowLabels = (indices == 0);
names(isRowLabels) = t.metaDim.labels(1);
names(~isRowLabels) = t.varDim.labels(indices(~isRowLabels));
