function M = maskindex(I,U)
% This function is undocumented and reserved for internal use. It may be
% removed in a future release.

% Copyright 2019-2020 The MathWorks, Inc.
%
% M = maskindex(I,U) returns the non-false indexing element positions of
% the array I less-than or equal-to an upper bound U, otherwise maskindex(I,U)
% returns [].

    if islogical(I)
        I = find(I~=0);
    end
    M = I(I<=U);
end
