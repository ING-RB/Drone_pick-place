function S = num2hex(X)
%

%   Copyright 1984-2023 The MathWorks, Inc.
narginchk(1,1);
if ~isreal(X)
    error(message('MATLAB:num2hex:realInput'))
end
if ~isfloat(X)
    error(message('MATLAB:num2hex:floatpointInput', class( X )))
end
if isa(X,'double')
    width = 16;
else
    width = 8;
end
N = typecast(X(end:-1:1),'uint8');
if isempty(X)
    S = '';
else
    S = sprintf('%02x',N(end:-1:1));
end
S = reshape(S,width,numel(X))';
