function b = splitvars(a, varargin)
%SPLITVARS Split multi-column variables in table or timetable.
%   T2 = SPLITVARS(T1)
%   T2 = SPLITVARS(T1, VARS)
%   T2 = SPLITVARS(T1, VARS, 'NewVariableNames', NEWNAMES)
%
%   See also TABLE, TALL.

%   Copyright 2018-2023 The MathWorks, Inc.

% Make sure that only the table/timetable input is tall
thisFcn = upper(mfilename);
tall.checkIsTall(thisFcn, 1, a);
if nargin>1
    tall.checkNotTall(thisFcn, 1, varargin{:});
end

% Use the in-memory version to do input checking
bProto = tall.validateSyntax(@splitvars, [{a},varargin], 'DefaultType', 'double');

if nargin<2
    varsToSplit = 1:width(a);
else
    varsToSplit = varargin{1};
    varargin(1) = [];
end
aAdap = a.Adaptor;
[~, toSplitIdx] = matlab.bigdata.internal.util.resolveTableVarSubscript(...
    aAdap.getVariableNames(), varsToSplit);

splitAdaps = aAdap.getVariableAdaptors(toSplitIdx);
widthToSplit = cellfun(@(adap) adap.getSizeInDim(2), splitAdaps);

% Split vars turns columns of table variables into unique variables. Since
% the number of variables *must* be known at dispatch time, we must ensure
% that the width of all variables is known before proceeding. This may
% cause evaluation.
if any(isnan(widthToSplit))
    % Force calculation of variable sizes. We calculate the full size since
    % we can only set the whole size vector, not just the width.
    varSizes = arrayfun(@(x) size(subsref(a, substruct('.', x))), toSplitIdx, 'UniformOutput', false);
    [varSizes{:}] = gather(varSizes{:});
    widthToSplit = cellfun(@(sz) sz(2), varSizes);
    % Push the sizes back into the table
    for outIdx=1:numel(varSizes)
        newAdap = aAdap.getVariableAdaptor(toSplitIdx(outIdx));
        newAdap = setKnownSize(newAdap, varSizes{outIdx});
        aAdap = aAdap.setVariableAdaptor(toSplitIdx(outIdx), newAdap);
    end
    a.Adaptor = aAdap;
    % Recalculate the prototype and reread the adaptors
    bProto = tall.validateSyntax(@splitvars, [{a},varsToSplit,varargin], 'DefaultType', 'double');
    splitAdaps = a.Adaptor.getVariableAdaptors(varsToSplit);
end

% If nothing needs splitting we are done
isTabular = cellfun(@(adap) ismember(adap.Class, {'table', 'timetable'}), splitAdaps);
toSplit = widthToSplit>1 | isTabular;
if ~any(toSplit)
    b = a;
    return;
end

% The split is actually slice-wise on each partition.
b = slicefun(@(x) splitvars(x, varsToSplit, varargin{:}), a);

% Use the prototype to build the new adaptor, then copy over the individual
% variable adaptors so that unknown types and sizes are preserved.
bAdap = copyTallSize(matlab.bigdata.internal.adaptors.getAdaptor(bProto), aAdap);

% Work out where each output variable originated in the input.
numTargetVars = ones(1,width(a));
numTargetVars(toSplitIdx) = widthToSplit;
outVarIdxInSource = repelem(1:width(a), numTargetVars);

% Copy the original adaptor but with size in second dim of 1
for outIdx=1:numel(outVarIdxInSource)
    sourceIdx = outVarIdxInSource(outIdx);
    varAdap = aAdap.getVariableAdaptor(sourceIdx);
    if ismember(sourceIdx, toSplitIdx)
        % Splitting, so need to modify the adaptor
        if ismember(varAdap.Class, ["table", "timetable"])
            % For tables we need the adaptor from the corresponding column
            columnInInput = nnz(outVarIdxInSource(1:outIdx)==outVarIdxInSource(outIdx));
            varAdap = varAdap.getVariableAdaptor(columnInInput);
        else
            % For all other types we end up with a single column
            varAdap = varAdap.setSizeInDim(2,1);
        end
    end
    bAdap = bAdap.setVariableAdaptor(outIdx, varAdap);
end


b.Adaptor = bAdap;

end

