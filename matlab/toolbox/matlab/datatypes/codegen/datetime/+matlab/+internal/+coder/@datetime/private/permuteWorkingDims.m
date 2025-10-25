function [Aout,szOut,perm] = permuteWorkingDims(A,dim) %#codegen
% PERMUTEWORKINGDIMS

%   Copyright 2020 The MathWorks, Inc.

% Make sure dim is a row vector
dimrow = reshape(dim, 1, []);

% Remove dims > ndims

for i = 1:numel(dimrow)
    if dimrow(i) > ndims(A)
        dimrow(i) = nan;
    end
end


% Set output size to 1 along the working dimensions
szIn = size(A);
szOut = szIn;
szOut(dimrow(isfinite(dimrow))) = 1;

% Permute working dims to the front if there are some dims <= ndims
if isempty(dimrow)
    perm = 1:ndims(A); % Need this for median
else

    n = 1:length(size(A));
    
    perm = zeros(1,numel(n));
    k = 0;
    coder.unroll()
    for i = 1:numel(dimrow)
        if isfinite(dimrow(i))
         k = k+1;
        perm(k) = dimrow(i);
        n(dimrow(i)) = nan;
        end
    end
    
    
    for j = 1:numel(n)
       if isfinite(n(j))
           k = k+1;
           perm(k) = n(j);
       end
    end
    
  
    
    Aperm = permute(A, perm);
end

Aout = reshape(Aperm, [prod(szIn(dimrow(isfinite(dimrow)))), prod(szOut)]);
