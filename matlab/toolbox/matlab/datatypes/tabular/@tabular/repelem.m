function B = repelem(A,M,N,varargin)
%

%   Copyright 2014-2024 The MathWorks, Inc.

if nargin ~= 3
    error(message('MATLAB:table:repelem:WrongRHS'));
else
    B = matlab.internal.builtinhelper.repelem(A,M,N);
end
