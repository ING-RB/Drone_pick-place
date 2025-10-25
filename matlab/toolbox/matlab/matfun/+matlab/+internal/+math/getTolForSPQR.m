function tol = getTolForSPQR(A)
%getTolForSPQR Get default tolerance for SPQR
% tol = getTolForSingleSPQR(A) returns the tolerance SPQR would
% use internally. We need to set this ourselves until we have native
% support for single SPQR (g3363686).

%   Copyright 2024 The MathWorks, Inc.
    
    tol = min(20*sum(size(A))*eps(class(A))*max(sqrt(sum(abs(A).^2, 1))), realmax(class(A)));
end
