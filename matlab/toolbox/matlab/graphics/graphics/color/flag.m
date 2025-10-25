function map = flag(m)
%

%   C. Moler, 7-4-91, 8-19-92.
%   Copyright 1984-2024 The MathWorks, Inc.

arguments
    m (1,1) double {mustBeInteger, mustBeNonnegative} = matlab.graphics.internal.colormapheight
end

% f = [red; white; blue; black]
f = [1 0 0; 1 1 1; 0 0 1; 0 0 0];
% Generate m/4 vertically stacked copies of f with Kronecker product.
e = ones(ceil(m/4),1);
map = kron(e,f);
map = map(1:m,:);
end