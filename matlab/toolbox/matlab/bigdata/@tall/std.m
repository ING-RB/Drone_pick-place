function [stdX, meanX] = std(x, flag, varargin)
%STD Standard deviation
%   Y = STD(X)
%   Y = STD(X,FLAG) where FLAG is 0 or 1
%   Y = STD(X,FLAG,DIM)
%   Y = STD(...,MISSING)
%   [Y,M] = STD(X,...)
%
%   Limitations:
%   1) Weight vector is not supported.
%   2) Tall table and timetable inputs are not supported.
%
%   See also: STD, TALL.

%   Copyright 2015-2022 The MathWorks, Inc.

% Explicit error for disabled tabular maths
if istabular(x)
    error(message("MATLAB:bigdata:array:TabularMathUnsupported", upper(mfilename)))
end

x = tall.validateType(x, mfilename, {'numeric', 'logical', 'duration', 'datetime'}, 1);
if nargin < 2
    flag = 0;
end
tall.checkNotTall(upper(mfilename), 1, flag, varargin{:});

if nargin == 2 && isNonTallScalarString(flag)
    % Presume 'flag' is actually a 'missing' indicator
    varargin = {flag};
    flagArg = {};
else
    flagArg = {flag};
end

if strcmp(tall.getClass(x), 'datetime')
    % Cannot support STD for datetime
    error(message('MATLAB:bigdata:array:FcnNotSupportedForType', ...
                  upper(mfilename), 'datetime'));
elseif strcmp(tall.getClass(x), 'duration')
    % This is essentially copied from the duration/std implementation
    x = milliseconds(x);
    % TODO: need to preserve Format field here.
    fixOutput = @(result) duration(0, 0, 0, result);
else
    fixOutput = @(result) result;
end

[stdX, meanX] = var(x, flagArg{:}, varargin{:});
stdX = sqrt(stdX);
stdX = fixOutput(stdX);
end

