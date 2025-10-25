function [V, M] = var(a, varargin)
%

%   Copyright 2022-2024 The MathWorks, Inc.

if nargout > 1
    [V, M] = stdVarHelper(a,@var,varargin);
else
    V = stdVarHelper(a,@var,varargin);
end

% Drop units for the first output (variance).
% 
% We drop units inside this method, as opposed to setting DropUnits = true
% in the call to reductionFunHelper above, so that we can set the correct
% variable units for the second output (weighted mean) above, which
% preserves units.
V.varDim = V.varDim.setUnits({});
