function TF = allunique(A,rows)
%   Syntax:
%      TF = allunique(A)
%      TF = allunique(A,"rows")
%
%   For more information, see documentation

%   Copyright 2024 The MathWorks, Inc.

narginchk(1,2);
if nargin < 2
    byRows = istabular(A);
    if (isnumeric(A) || ischar(A) || islogical(A)) && ~isobject(A) || isstring(A)
        TF = matlab.internal.math.allunique(A);
        return
    end
else
    if ~matlab.internal.math.checkInputName(rows,'rows')
        error(message("MATLAB:UNIQUE:OnlyRowsOption"));
    end
    if (isnumeric(A) || ischar(A) || islogical(A)) && ~isobject(A)
        TF = matlab.internal.math.alluniqueRows(A);
        return
    else
        byRows = true;
    end
end

if byRows
    TF = size(unique(A,'rows'),1) == size(A,1);
else
    TF = numel(unique(A)) == numel(A);
end