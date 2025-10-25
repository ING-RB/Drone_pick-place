function h = fpolarplot(varargin)
%FPOLARPLOT   Plot 2-D function in polar axes
%   FPOLARPLOT(FUN) plots the function FUN in polar axes.
%
%   FPOLARLOT(FUN,LIMS) plots the function FUN between the theta-axis limits
%   specified by LIMS = [THETAMIN THETAMAX]. 
%
%   FPOLARPLOT(...,'LineSpec') plots with the given line specification.
%
%   H = FPOLARPLOT(...) returns a handle to the function line object created by FPOLARPLOT.
%
%   FPOLARPLOT(AX,...) plots into the axes AX instead of the current axes.
%
%   Examples:
%       fpolarplot(@sin)
%       fpolarplot(@(x) sin(x)+sin(3*x)/3+sin(5*x)/5)
%
%   If your function cannot be evaluated for multiple x values at once,
%   you will get a warning and somewhat reduced speed:
%       f = @(x,n) abs(exp(-1j*x*(0:n-1))*ones(n,1));
%       fpolarplot(@(x) f(x,10),[0 2*pi])
%
%   See also FPLOT, FPLOT3, FSURF, FCONTOUR, FIMPLICIT, PLOT, FUNCTION_HANDLE.

%   Copyright 2023-2024 The MathWorks, Inc.

% Convert string arguments, if any, to char.
if nargin > 0
    [varargin{:}] = convertStringsToChars(varargin{:});
end

    % Parse possible Axes input
    [cax, args] = axescheck(varargin{:});

    if numel(args) < 1
        error(message('MATLAB:narginchk:notEnoughInputs'));
    end

    if ~isempty(cax) && ~isa(cax, 'matlab.graphics.axis.PolarAxes')
        error(message('MATLAB:polarplot:AxesInput'));
    end

    cax = matlab.graphics.internal.prepareCoordinateSystem('polar', cax);

    hh = fplot(cax, args{:}, 'CalledForPolar');
    if nargout > 0
        h = hh;
    end
end
