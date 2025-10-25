function tf = isSizeCompatible(X, Y)
%isSizeCompatible return true if input dimensions are compatible 
%    for implicit expansion, and false otherwise

%   Copyright 2023 The MathWorks, Inc.
tf = true;
if ~(isscalar(X) || isscalar(Y))
    % compatible size for implicit expansion
    for i = 1:min(ndims(X), ndims(Y))
        sXi = size(X,i);
        sYi = size(Y,i);
        if ~(sXi == sYi || sXi == 1 || sYi == 1)
            tf = false;
            return
        end
    end
end
