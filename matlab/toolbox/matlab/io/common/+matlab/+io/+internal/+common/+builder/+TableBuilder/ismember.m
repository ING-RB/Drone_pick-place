function [isfound, indices] = ismember(needle, haystack)
%TableBuilder/ismember   An implementation of ismember for string vectors that
%   performs "exhaustive deduplication" behavior, which is more intuitive
%   for IO VariableNames-related code.
%
%   Basically:
%      >> [a, b] = TableBuilder.ismember(["OutageTime" "Data" "Data"], ["Data" "Data" "OutageTime"])
%   returns a=[1 1 1] and b=[3 1 2]. Normal ismember returns b=[3 1 1] instead.
%
%   This function will always returns unique match indices from the haystack if
%   it finds a corresponding duplicate match. Additionally, duplicate
%   matches will always be done in increasing order:
%      >> [a, b] = TableBuilder.ismember(["Data" "Data" "Data"], ["Data" "Data" "Data"])
%   returns a=[1 1 1] and b=[1 2 3]. Normal ismember returns b=[1 1 1] instead.
%
%   If there are insufficient duplicates in the haystack for the
%   needles, then this function treats that as a non-match:
%     >> [a, b] = TableBuilder.ismember(["Data" "Data" "Data"], ["Data" "Data" "OutageTime"])
%   this function returns a=[1 1 0] and b=[1 2 0]. Normal ismember returns a=[1 1 1] and b=[1 1 1] instead.
%
%   Similar to normal ismember, the "isfound" and "indices" outputs from this
%   function match the size of the first input. i.e. if you pass a 2D
%   matrix in, you get a 2D matrix back out.
%
%   This function also matches the behavior of normal ismember for missing
%   strings in the input. missing strings are always treated as
%   non-matches.
%
%   This function allows char vectors and treats them as scalar
%   strings. This is different from normal ismember where char vectors in
%   both the needle and haystack perform elementwise (char-by-char)
%   comparison, which is not what we usually want in IO code.

%   Copyright 2022 The MathWorks, Inc.

    % Avoid arguments block and do direct validation instead to avoid
    % implicit casting. We really want to make sure only text types get
    % into this code.
    funcname = "matlab.io.internal.common.builder.TableBuilder.ismember";
    validateattributes(convertCharsToStrings(needle),   "string", {}, funcname, "needle",   1);
    validateattributes(convertCharsToStrings(haystack), "string", {}, funcname, "haystack", 1);
    % Don't use convertCharsToStrings here since it'll turn 2D char into a
    % scalar string, while the string ctor turns it into a vector string.
    needle   = string(needle);
    haystack = string(haystack);

    % Preallocate the output vector.
    indices = zeros(size(needle));

    % Use a 2D expansion trick to find duplicate indices.
    needle = reshape(needle(:), [], 1);
    haystack = reshape(haystack(:), 1, []);
    needleHaystackMatches = haystack == needle;

    % Iterate over each needle and find the first available match in the haystack.
    for needleIndex = 1:numel(needle)
        haystackIndex = find(needleHaystackMatches(needleIndex, :), 1, "first");

        if isempty(haystackIndex)
            % Name not found.
            indices(needleIndex) = 0;
        else
            % Store the index of the matching name.
            indices(needleIndex) = haystackIndex;

            % Clear out all other matches for this variable index. So any
            % subsequent duplicate variable names must use a different
            % variable index.
            needleHaystackMatches(:, haystackIndex) = 0;
        end
    end

    isfound = indices ~= 0;
end
