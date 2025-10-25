function idx = memberindex(A,B)
%MEMBERINDEX find the index of elements of A in B.
%   Return the index of the elements of A in the array B. 0 for missing.
%   Assumes both A and B are cell arrays of chars.

%   Copyright 2021 The MathWorks, Inc.      

%#codegen 

Na = numel(A);
Nb = numel(B);
idx = zeros(1,Na);
% No sorting because these are small arrays. Just do 2 passes.
for aa=1:Na
    for bb=1:Nb
        if strcmpi(A{aa}, B{bb})
            idx(aa) = bb;
            break;
        end
    end
end
end
