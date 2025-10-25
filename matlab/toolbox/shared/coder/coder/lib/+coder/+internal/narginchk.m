function narginchk(low, high, n)
%MATLAB Code Generation Library Function

%   Copyright 2012-2020 The MathWorks, Inc.
%#codegen
coder.internal.prefer_const(low, high, n);

if isempty(coder.target)
    flr = @floor;
else
    flr = @coder.internal.scalar.floor;
end

% Argument checking
coder.internal.assert(isa(low,'numeric') && isscalar(low) && flr(low(1)) == low(1), ...
                      'MATLAB:IntVal');
coder.internal.assert(isa(high,'numeric') && isscalar(high) && flr(high(1)) == high(1), ...
                      'MATLAB:IntVal');
coder.internal.assert(isa(n,'numeric') && isscalar(n) && flr(n(1)) == n(1), ...
                      'MATLAB:IntVal');

% Ensure nargin is within range
coder.internal.assert(low <= n, ...
                      'MATLAB:narginchk:notEnoughInputs');
coder.internal.assert(high >= n, ...
                      'MATLAB:narginchk:tooManyInputs');
