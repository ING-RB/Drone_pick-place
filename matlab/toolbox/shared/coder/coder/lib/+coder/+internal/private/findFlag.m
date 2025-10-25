function j = findFlag(flagNames,s)
%MATLAB Code Generation Private Function
%
%   Using case-insensitive partial matching, find the flag corresponding to
%   s in the flagNames cell array.  If j > 0, then flagNames{j} is the
%   match.  If j < 0, the match is ambiguous (there were -j candidates).
%   j = 0 indicates no match. Note that at least one character must match,
%   so an empty flagName can never be matched.

%   Copyright 2021 The MathWorks, Inc.
%#codegen


coder.internal.allowEnumInputs;
coder.internal.allowHalfInputs;
coder.internal.prefer_const(flagNames,s);
nFlagNames = coder.internal.indexInt(numel(flagNames));
j = coder.internal.indexInt(0);
if coder.internal.isTextRow(s)
    lens = coder.internal.indexInt(strlength(s));
    ncandidates = coder.internal.indexInt(0);
    coder.unroll;
    for k = 1:nFlagNames
        flag = flagNames{k};
        lenf = coder.internal.indexInt(length(flag));
        if lens > lenf
        elseif lens == lenf && strcmpi(flag,s)
            ncandidates = coder.internal.indexInt(1);
            j = k;
            break
        elseif strncmpi(flag,s,max(1,lens))
            ncandidates = ncandidates + 1;
            j = k;
        end
    end
    if ncandidates > 1
        j = coder.internal.indexInt(-1);
    end
end
