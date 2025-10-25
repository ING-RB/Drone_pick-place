function m = pickTransformLength(m)
% PICKTRANSFORMLENGTH  Select an optimized transform length.
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%
%   N = PICKTRANSFORMLENGTH(M) returns a value N that greater than or equal
%   to M that has prime factors no larger than 7.

%   Copyright 2019, The MathWorks Inc.

while true
    r = m;
    for p = [2 3 5 7]
        while (r > 1) && (mod(r, p) == 0)
            r = r / p;
        end
    end
    if r == 1
        break;
    end
    m = m + 1;
end