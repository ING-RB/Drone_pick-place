function varargout = min(a, varargin)
%

%   Copyright 2022-2024 The MathWorks, Inc.

funName = 'min';
isBinary = tabular.minMaxValidationHelper(nargout,@min,funName,a,varargin);
if isBinary
    % Binary syntax.
    fun = @(a,b)min(a,b,varargin{2:end});
    b = varargin{1};
    [varargout{1:nargout}] = tabular.binaryFunHelper(a,b,fun, ...
        @matlab.internal.tabular.math.plusUnitsHelper,funName);
else
    % Unary syntax.
    fun = @(a,varargin)min(a,[],varargin{:});
    [varargout{1:nargout}] = tabular.reductionFunHelper(a,fun, ...
        varargin(2:end),FunName=funName);
end
