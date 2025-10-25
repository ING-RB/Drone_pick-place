function b = mergevars(a, vars, varargin)
%MERGEVARS Combine table or timetable variables into a multi-column variable.
%   T2 = MERGEVARS(T1, VARS)
%   T2 = MERGEVARS(..., 'NewVariableName', NEWNAME)
%   T2 = MERGEVARS(..., 'MergeAsTable', true)
%
%   See also TABLE, TALL.

%   Copyright 2018-2024 The MathWorks, Inc.

% Use the in-memory version to do input checking
bProto = tall.validateSyntax(@mergevars, [{a},{vars},varargin], 'DefaultType', 'double');

% Make sure that only the table/timetable input is tall
thisFcn = upper(mfilename);
tall.checkIsTall(thisFcn, 1, a);
tall.checkNotTall(thisFcn, 1, vars, varargin{:});

% If varlist is empty there is nothing to do
if isempty(vars)
    b = a;
    return;
end

% The merge is actually slice-wise on each partition, but we need to do
% some fancy work to get the adaptors right.
b = slicefun(@(x) mergevars(x, vars, varargin{:}), a);

% Use the prototype to work out the new adaptor, but replace the adaptor for the
% new variable with the concatenated input adaptors.
aAdap = a.Adaptor;
bAdap = copyTallSize(matlab.bigdata.internal.adaptors.getAdaptor(bProto), aAdap);

[~, mergeVarIdx] = matlab.bigdata.internal.util.resolveTableVarSubscript(...
    aAdap.getVariableNames(), vars);

% Resolving may have resulted in no matches in which case this is a no-op.
if isempty(mergeVarIdx)
    b = a;
    return;
end

% We have work to do
outVarIdx = mergeVarIdx(1);
mergeInputAdap = aAdap.getVariableAdaptors(mergeVarIdx);

% Might need to merge as array or table
if iMergeAsTableRequested(varargin)
    % Set the new variable's table variable adaptors to the input ones
    mergedAdap = bAdap.getVariableAdaptor(outVarIdx);
    for ii=1:numel(mergeInputAdap)
        mergedAdap = mergedAdap.setVariableAdaptor(ii, mergeInputAdap{ii});
    end
    
else
    % This should not error since validateSyntax has already checked the combination
    mergedAdap = matlab.bigdata.internal.adaptors.combineAdaptors(2, mergeInputAdap);
end
b.Adaptor = setVariableAdaptor(bAdap, outVarIdx, mergedAdap);
end


function tf = iMergeAsTableRequested(args)
% Determine whether we are merging into a table (i.e. called
% with (..., "MergeAsTable", true, ...)
argIdx = find(cellfun(@(x) startsWith("MergeAsTable", x, "IgnoreCase", true), args(1:2:end)));
tf = ~isempty(argIdx) && isequal(args{argIdx*2}, true);
end