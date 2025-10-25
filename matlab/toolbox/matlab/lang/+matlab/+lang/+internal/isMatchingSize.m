function tf = isMatchingSize(arraySize, sz)
%MATLAB.LANG.INTERNAL.ISMATCHINGSIZE Compares array size with specified size.
%   tf = MATLAB.LANG.INTERNAL.ISMATCHINGSIZE(A,B) compares size vectors A
%   and B. A is normally the result of calling function size on an array. B
%   is a coded size vector where value -1 represents unrestricted dimension
%   length that matches any demension length. The function returnes scalar
%   logic value true if all respective element values from the vectors
%   match. Trailing values of 1 from B are ignored.

%   Copyright 2019 The MathWorks, Inc.

if ~isvector(arraySize)
    tf = false;
    return;
end
if numel(sz) < numel(arraySize)
    % size(array) = [1,2,3], sz = [1,2]
    tf = false;
    return;
end
for i=1:numel(arraySize)
    if sz(i) ~= -1 && arraySize(i) ~= sz(i)
        % size(array) = [m,n], sz = [m,xn]
        % size(array) = [m,n], sz = [:,xn]
        tf = false;
        return;
    end
end
for i=numel(arraySize)+1:numel(sz)
    if sz(i) ~= -1 && sz(i) ~= 1
        % size(array) = [1,2], sz = [1,2,3]
        tf = false;
        return;
    end
end
% size(array) = [m,n], sz = [m,n]
% size(array) = [m,n], sz = [m,-1]
% size(array) = [m,n], sz = [m,n,1]
tf = true;
end
