function [S,M] = std(a, varargin)
%

%   Copyright 2022-2024 The MathWorks, Inc.

if nargout > 1
    [S,M] = stdVarHelper(a,@std,varargin);
else

    S = stdVarHelper(a,@std,varargin);
end
