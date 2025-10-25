function b = squeeze(a)
%SQUEEZE Remove singleton dimensions.
%   B = SQUEEZE(A) returns an array B with the same elements as
%   A but with all the singleton dimensions removed.  A singleton
%   is a dimension such that size(A,dim)==1.  2-D arrays are
%   unaffected by squeeze so that row vectors remain rows.
%
%   For example,
%       squeeze(rand(2,1,3))
%   is 2-by-3.
%
%   See also SHIFTDIM.

%   Copyright 1984-2020 The MathWorks, Inc.

if ~ismatrix(a)
    siz = size(a);       % siz has at least one element not equal to 1
    siz(siz == 1) = [];  % remove singleton dimensions
    if isscalar(siz)
        b = reshape(a,siz,1);  % reshape to 2-D
    else
        b = reshape(a,siz);
    end
else
    b = a;
end
