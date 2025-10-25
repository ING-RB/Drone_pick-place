function [S,L] = bounds(A,in2,in3)
%BOUNDS Smallest and largest elements
%   [S,L] = bounds(A)
%   [S,L] = bounds(A,DIM)
%   [S,L] = bounds(...,NANFLAG)
%
%   See also BOUNDS, TALL.

%   Copyright 2017-2023 The MathWorks, Inc.

if nargin <= 1
    S = min(A);
    L = max(A);
elseif nargin == 2
    validOptions = ["all","omitnan","includenan","omitnat","includenat","omitundefined","includeundefined","omitmissing","includemissing"];
    if (ischar(in2) || isstring(in2)) && ...
            (~matlab.internal.datatypes.isScalarText(in2) ||...
            ~any(strncmpi(in2,validOptions,max(strlength(in2), 1))))
        error(message('MATLAB:bounds:unknownOption'));
    end
    S = min(A,[],in2);
    L = max(A,[],in2);
else
    if (ischar(in2) || isstring(in2)) && ...
            (~matlab.internal.datatypes.isScalarText(in2) ||...
            ~strncmpi(in2,'all',max(strlength(in2), 1)))
        error(message('MATLAB:getdimarg:invalidDim'));
    end
    validOptions = ["omitnan","includenan","omitnat","includenat","omitundefined","includeundefined","omitmissing","includemissing"];
    if ~(ischar(in3) || isstring(in3)) || ...
            (~matlab.internal.datatypes.isScalarText(in3) || ...
            ~any(strncmpi(in3,validOptions,max(strlength(in3), 1))))
        error(message('MATLAB:bounds:unknownNaNFlag'));
    end
    S = min(A,[],in2,in3);
    L = max(A,[],in2,in3);
end
end

