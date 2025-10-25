function N = numunique(A,rows)
%   Syntax:
%      N = numunique(A)
%      N = numunique(A,"rows")
%
%   For more information, see documentation

%   Copyright 2024 The MathWorks, Inc.

narginchk(1,2);
if nargin < 2
    byRows = istabular(A);
    if (isnumeric(A) || ischar(A) || islogical(A)) && ~isobject(A) || isstring(A)
        N = matlab.internal.math.numunique(A);
        return
    end
else
    if ~matlab.internal.math.checkInputName(rows,'rows')
        error(message("MATLAB:UNIQUE:OnlyRowsOption"));
    end
    if (isnumeric(A) || ischar(A) || islogical(A)) && ~isobject(A)
        N = matlab.internal.math.numuniqueRows(A);
        return
    else
        byRows = true;
    end
end

if byRows
    N = size(unique(A,'rows'),1);
else
    N = numel(unique(A));
end