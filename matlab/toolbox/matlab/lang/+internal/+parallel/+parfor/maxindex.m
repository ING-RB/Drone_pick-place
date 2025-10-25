function N = maxindex(I)
% This function is undocumented and reserved for internal use. It may be
% removed in a future release.

% Copyright 2019-2020 The MathWorks, Inc.

% N = maxindex(I) returns the largest non-false indexed element position of the
% array I, otherwise maxindex(I) returns [].

    if islogical(I)
        N = find(I,1,'last');
    else
        N = max(I,[],'all');
    end

end
