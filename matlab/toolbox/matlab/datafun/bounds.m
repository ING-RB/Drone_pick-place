function [S,L] = bounds(A,in2,in3)
%BOUNDS Smallest and largest elements
%   [S,L] = BOUNDS(A) returns the smallest element S and largest element L
%   for a vector A. If A is a matrix, S and L are the smallest and largest 
%   elements of each column. For N-D arrays, BOUNDS(A) operates along the 
%   first array dimension not equal to 1.
%
%   [S,L] = BOUNDS(A,"all") returns the smallest element and largest
%   element of A.
%
%   [S,L] = BOUNDS(A,DIM) operates along the dimension DIM.
%
%   [S,L] = BOUNDS(A,VECDIM) operates on the dimensions specified in the 
%   vector VECDIM. For example, BOUNDS(A,[1 2]) operates on the elements
%   contained in the first and second dimensions of A.
%
%   [S,L] = BOUNDS(...,NANFLAG) also specifies how NaN values are treated:
%
%       "omitmissing" / "omitnan"       -
%                      (default) Ignores all NaN values and returns the
%                      minimum and maximum of the non-NaN elements.
%       "includemissing" / "includenan" -
%                      Returns NaN for both outputs if there is any NaN
%                      value.
%
%   See also MIN, MAX, SORT.

%   Copyright 2016-2023 The MathWorks, Inc.

if nargin <= 1
    S = min(A);
    L = max(A);
elseif nargin == 2
    validOptions = ["all","omitnan","includenan","omitnat","includenat","omitundefined","includeundefined","omitmissing","includemissing"];
    if (ischar(in2) || isstring(in2)) && ...
            (isInvalidText(in2) || ~any(strncmpi(in2,validOptions,max(strlength(in2), 1))))
        error(message('MATLAB:bounds:unknownOption'));
    end
    S = min(A,[],in2);
    L = max(A,[],in2);
else
    if (ischar(in2) || isstring(in2)) && ...
            (isInvalidText(in2) || ~strncmpi(in2,'all',max(strlength(in2), 1)))
        error(message('MATLAB:getdimarg:invalidDim'));
    end
    validOptions = ["omitnan","includenan","omitnat","includenat","omitundefined","includeundefined","omitmissing","includemissing"];
    if ~(ischar(in3) || isstring(in3)) || ...
            (isInvalidText(in3) || ~any(strncmpi(in3,validOptions,max(strlength(in3), 1))))
        error(message('MATLAB:bounds:unknownNaNFlag'));
    end
    S = min(A,[],in2,in3);
    L = max(A,[],in2,in3);
end

function tf = isInvalidText(str)
tf = (ischar(str) && ~isrow(str)) || ...
     (isstring(str) && ~(isscalar(str) && (strlength(str) > 0)));
