function e = end(a,k,n) %#codegen
%END Last index in an indexing expression for a categorical array.

%   Copyright 2018-2020 The MathWorks, Inc.

dims = ndims(a.codes);
if k == n && k <= dims
    e = 1;
    coder.unroll();
    for i = k:dims
        % Collapse the dimensions beyond N and return the end.
        % Use an explicit for loop to look at the size of each
        % dim individually to avoid issues for varsize inputs. 
        e = e * size(a.codes,i);
    end
else % k > n || k < n || k > ndims(a)
    % for k > n or k > ndims(a), e is 1
    e = size(a.codes,k);
end

