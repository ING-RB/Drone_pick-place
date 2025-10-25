function B = headtail(doHead, A, k)
%headtail Helper function for head and tail
%
%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.
%

%   Copyright 2016-2023 The MathWorks, Inc.

if nargin<3
    k = 8;
elseif ~(isnumeric(k) && isscalar(k) && isreal(k) && isfinite(k) && (k >= 0) && (k == round(k)))
    throwAsCaller(MException(message('MATLAB:headtail:InvalidK')));
end

sz = size(A);
if sz(1) <= k
    B = A;
else
    if doHead
        B = A(1:k,:);
    else
        B = A(end-k+1:end,:);
    end
    if numel(sz) > 2
        % The head or tail of a multidimensional array A has the same size
        % as A, except that the number of rows is k.
        sz(1) = k;
        B = reshape(B,sz);
    end
end