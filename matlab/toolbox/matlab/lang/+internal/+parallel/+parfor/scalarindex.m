function M = scalarindex(I,U)
% This function is undocumented and reserved for internal use. It may be
% removed in a future release.

% Copyright 2020 The MathWorks, Inc.
%
% M = scalarindex(I,U) returns [] if min(I,U) is 0, otherwise returns min(I,U).

    M = min(I,U);
    if M == 0
        M = [];
    end

end
