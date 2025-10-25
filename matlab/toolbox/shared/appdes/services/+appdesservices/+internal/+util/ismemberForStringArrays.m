function boolArray = ismemberForStringArrays(A,B)
%   ISMEMBERFORSTRINGARRAYS Returns true when A is a member of B.
%     LIA = ismemberforstringarrays(A,B) for string arrays A and B returns an array of the same
%     size as A containing true where the elements of A are in B and false
%     otherwise.
%
%     Validation in this function is minimal because the main role of this
%     function is to improve performance
%     A and B are expected to be vector string arrays
%
%   Examples:
%
%      a = ["Property1", "Property4", "Property5"]
%      b = ["Property1", "Property2", "Property3"]
%
%      result = ismember(a,b)
%      % returns
%      result = [1 0 0]
%
%      result = ismember("Property2",b)
%      % returns
%      result = [1]

%   Copyright 2018-2021 The MathWorks, Inc.

if ~isstring(A) || ~isstring(B)
    error("IsMemberForStringArrays:BadInput","Error: Expected string array inputs to  ismemberForStringArrays");
end

boolArray = ismemberForStringArraysBuiltin(A,B);
end