function N = minindex(I)
% This function is undocumented and reserved for internal use. It may be
% removed in a future release.

% Copyright 2019-2020 The MathWorks, Inc.

% N = minindex(I) returns the smallest non-false indexed element position of the
% array I, otherwise minindex(I) returns [].

    if islogical(I)
        N = find(I,1,'first');
    else
        N = min(I,[],'all');
    end

end
