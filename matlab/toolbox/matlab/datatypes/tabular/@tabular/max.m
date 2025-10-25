function varargout = max(a, varargin)
%

%   Copyright 2022-2024 The MathWorks, Inc.

funName = 'max';
isBinary = tabular.minMaxValidationHelper(nargout,@max,funName,a,varargin);
if isBinary
    % Binary syntax.
    fun = @(a,b)max(a,b,varargin{2:end});
    b = varargin{1};
    [varargout{1:nargout}] = tabular.binaryFunHelper(a,b,fun, ...
        @matlab.internal.tabular.math.plusUnitsHelper,funName);
else
    % Unary syntax.
    fun = @(a,varargin)max(a,[],varargin{:});
    [varargout{1:nargout}] = tabular.reductionFunHelper(a,fun, ...
        varargin(2:end),FunName=funName);
end
