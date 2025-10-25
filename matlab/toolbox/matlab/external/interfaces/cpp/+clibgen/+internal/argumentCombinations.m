function [res, cur] = argumentCombinations(args, currentCombination, idx, argCombinations)
%

%   Copyright 2020 The MathWorks, Inc.
if idx == (numel(args)+1)
    argCombinations{end+1} = currentCombination;
    res = argCombinations;
    cur = currentCombination;
    return;
end
    
for i= 1:numel(args(idx).MATLABType)
    argList = args(idx);
    currentCombination(end+1) = argList.MATLABType(i);
    [res, cur] = clibgen.internal.argumentCombinations(args, currentCombination, idx+1, argCombinations );
    argCombinations = res;
    cur(end) = [];
    currentCombination = cur;
end

