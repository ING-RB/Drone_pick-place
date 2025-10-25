function b = de2bi(d, n)
%This function is for internal use only. It may be removed in the future.

%DE2BI This function converts a nonnegative integer into an 1-by-n vector
%    of 0's and 1's with most significant bit on the left. If the specified
%    n is too small, the number of column of the vector is determined by
%    the binary number converted from d.
%    This is similar to de2bi from communication system toolbox

%   Copyright 2018-2019 The MathWorks, Inc.

bchar = dec2bin(d);
L = length(bchar);
N = max(n, L);
b = zeros(1,N);
for i = 1:L
    if strcmp(bchar(L+1-i), '1')
        b(N+1-i) = 1;
    end
end
end
