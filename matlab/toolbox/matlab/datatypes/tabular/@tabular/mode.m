function varargout = mode(a, varargin)
%

%   Copyright 2022-2024 The MathWorks, Inc.

[varargout{1:nargout}] = tabular.reductionFunHelper(a,@mode,varargin);

% Preserve units for the third output (vector of all values that have the
% same frequency as the corresponding element of the first output).
if nargout > 2
    varargout{3}.varDim = varargout{3}.varDim.setUnits(varargout{1}.varDim.units);
end
