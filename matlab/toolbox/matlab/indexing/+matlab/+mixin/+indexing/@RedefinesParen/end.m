%END  Compute size in given dimension
%   END(obj,K,N) is called for indexing expressions involving the
%   object obj when end is part of the K-th index out of N
%   indices. For example, the expression obj(end-1,:) calls
%   the END method for obj with END(obj,1,2).
%

%   Copyright 2020-2021 The MathWorks, Inc.

function ind = end(obj, k, n)
    sz = size(obj);
    if k < n
        ind = sz(k);
    else
        ind = prod(sz(k:end));
    end
end
