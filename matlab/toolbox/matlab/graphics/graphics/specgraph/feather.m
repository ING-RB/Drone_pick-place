function hh = feather(varargin)
%

%   Copyright 1984-2024 The MathWorks, Inc.

% Parse possible Axes input
[cax, args, nargs] = axescheck(varargin{:});

numNumericArgs = 1 + (nargs > 1 && isnumeric(args{2}));
[args, nvpairs] = matlab.graphics.chart.internal.inputparsingutils.splitPositionalFromPV(...
    args, numNumericArgs, true);

x = args{1};
if ischar(x)
    error(message('MATLAB:feather:FirstNumericInput'));
end

linespec = '-';
if numel(args) ~= numNumericArgs
    linespec = args{end};
end
if numNumericArgs == 1
    z = matlab.graphics.chart.internal.datachk(args{1});
    x = real(z);
    y = imag(z);
else
    x = matlab.graphics.chart.internal.datachk(args{1});
    y = matlab.graphics.chart.internal.datachk(args{2});
end

xx = [0 1 NaN .8 1 .8]';
yy = [0 0 NaN .08 0 -.08].';
arrow = xx + yy .* sqrt(-1);

if ischar(x) || ischar(y)
    error(message('MATLAB:feather:LeadingNumericInputs'))
end
[st, co, mark, msg] = colstyle(linespec);
error(msg);

x = x(:);
y = y(:);
m = numel(x);
if m ~= numel(y)
    error(message('MATLAB:feather:LengthMismatch'));
end

z = (x + y .* sqrt(-1)).';
a = arrow * z + ones(6, 1) * (1:m);

% Create plot
parax = cax;
if isempty(cax) || ishghandle(cax, 'axes')
    parax = newplot(cax);
end

h = plot(real(a), imag(a), [st co mark], [1 m], [0 0], [st co mark], ...
    'Parent', parax, nvpairs{:});

if ~isempty(h) && h(1).SeriesIndexMode == "auto"
    si = h(1).SeriesIndex;
    set(h(2:end), 'SeriesIndex_I', si)
    parax.setNextSeriesIndex(si+1);
end

if nargout > 0
    hh = h;
end
end
