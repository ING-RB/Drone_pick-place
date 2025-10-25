function h = binscatter(varargin)
%BINSCATTER Binned scatter plot.
%   BINSCATTER(X,Y) displays a binned scatter plot for X and Y,
%   which shows areas of different data density using colors. Density is
%   determined by separating the 2-D space into rectangular bins and
%   counting the number of data points in each bin. Zooming into the
%   plot rebins the data using smaller bins and thus increases the 
%   resolution. 
%
%   With tall inputs, the BINSCATTER command plots in iterations, progressively 
%   updating the plot as more data is read. During updating, a progress 
%   indicator shows the proportion of data that has been plotted. Zooming 
%   and panning is supported during updating before the plot is complete. 
%   To pause the update process, press the pause button in the progress 
%   indicator.
%
%   BINSCATTER(X,Y,N) specifies the number of bins. N is either a scalar or 
%   a two-element vector [Nx Ny]. If N is a scalar, Nx and Ny 
%   are both set to the scalar value. The maximum number of bins in each 
%   dimension is 250. The default value of N is computed based on the data 
%   size and the standard deviation, and does not exceed 100.
%
%   BINSCATTER uses Nx and Ny bins along the X and Y dimensions in the 
%   initial plot, when the axes are not zoomed in (the axes are not zoomed 
%   in when the XLimMode and YLimMode properties are both 'auto'). When 
%   zooming, BINSCATTER may use more bins to maintain a bin size such that 
%   the visible portion of the plot is approximately divided into Nx-by-Ny 
%   bins. 
%
%   BINSCATTER(..., 'XLimits', [XMIN, XMAX]) limits the binned scatter plot to
%   only display data points between the limits along the X axis, 
%   X>=XMIN & X<=XMAX.  Similarly, BINSCATTER(...,'YLimits',[YMIN,YMAX]) 
%   limits the plot along the Y axis. 
% 
%   BINSCATTER(..., 'ShowEmptyBins', ONOFF) specifies whether areas with 
%   no data points are colored. The default is 'off'.
%
%   BINSCATTER(AX,...) plots into AX instead of GCA.
%
%   H = BINSCATTER(...) returns a binned scatter plot object.
%
% Example:
%  x = randn(1e6,1);
%  y = 2*x + randn(1e6,1);
%  h = binscatter(x, y)
%
%   See also SCATTER.

%   Copyright 2017-2024 The MathWorks, Inc.

matlab.graphics.chart.internal.DDUXLogger(mfilename,varargin);

[cax,args] = axescheck(varargin{:});
narginchk(2,inf);
x = args{1};
y = args{2};
args(1:2) = [];

funcname = mfilename;

tallx = istall(x);
tally = istall(y);

% error checking in the first two inputs
if tallx && tally
    x  = tall.validateType(x,funcname,{'numeric','logical','datetime','duration'},1);
    x = lazyValidate(x, {@(x1)iscolumn(x1) && (~isnumeric(x1) || isreal(x1)), ...
        'MATLAB:binscatter:InvalidTallData'});
    y  = tall.validateType(y,funcname,{'numeric','logical','datetime','duration'},2);
    y = lazyValidate(y, {@(y1)iscolumn(y1) && (~isnumeric(y1) || isreal(y1)), ...
        'MATLAB:binscatter:InvalidTallData'});
    [x, y] = validateSameTallSize(x,y);
    tall.checkNotTall(funcname, 2, args{:});
elseif ~tallx && ~tally
    validateattributes(x, {'numeric','logical','datetime','duration'}, ...
        {'vector', 'real'}, funcname, 'x', 1);
    validateattributes(y, {'numeric','logical','datetime','duration'}, ...
        {'vector', 'real', 'size', size(x)}, funcname, 'y', 1);
else
    error(message('MATLAB:binscatter:MixedTallData'));
end

% error checking for the rest of the inputs
args = parseinput(args);

cax = newplot(cax);

if tallx
    % Extract sample from x and y using the adaptors. For non-strong types
    % (numeric and logical), use double as default value. This will not
    % affect datetime and duration.
    xadaptor = matlab.bigdata.internal.adaptors.getAdaptor(x);
    yadaptor = matlab.bigdata.internal.adaptors.getAdaptor(y);
    xtype = buildSample(xadaptor, 'double', [1 1]);
    ytype = buildSample(yadaptor, 'double', [1 1]);
    matlab.graphics.internal.configureAxes(cax,xtype,ytype);
else
    matlab.graphics.internal.configureAxes(cax,x,y);
end

switch cax.NextPlot
    case {'replaceall','replace'}
        cax.Box = 'on';
        assignColormap(cax)
        cb = colorbar(cax);
        cb.Label.String = getString(message('MATLAB:binscatter:BinCounts'));
        matlab.graphics.internal.setRulerLayerTop(cax);
    case 'replacechildren'
        matlab.graphics.internal.setRulerLayerTop(cax);
        if strcmpi(cax.ColormapMode,'auto')
            assignColormap(cax)
        end
end

% mark for reuse if tall
if tallx
    t = table(x, y);
    markforreuse(hGetValueImpl(t));
    x = t.x;
    y = t.y;
end

htemp = matlab.graphics.chart.primitive.Binscatter('XData', x, 'YData', y, ...
    args{:}, 'Parent', cax);
if nargout > 0
    h = htemp;
end
end

function outargs = parseinput(args)
outargs = {};
funcname = mfilename;

nameoffset = 2;
ind = 1;  % parsing index
if ~isempty(args) && ~ischar(args{ind}) && ~isstring(args{ind})
    % NumBins input
    nb = args{ind};
    if isscalar(nb)
        nb = [nb nb];
    end
    validateattributes(nb, {'numeric'}, {'integer', 'positive','numel',2, 'vector'},...
        mfilename, 'N');
    outargs = {'NumBins', reshape(nb,1,2)};
    ind = ind + 1;
end

% remaining must be name-value pairs
if rem(length(args)-ind+1,2) ~= 0
    error(message('MATLAB:binscatter:ArgNameValueMismatch'));
end

names = setdiff(properties('matlab.graphics.chart.primitive.Binscatter'),...
    {'Annotation', 'BeingDeleted', 'Children', 'Type', 'Values', 'XBinEdges', ...
    'YBinEdges'});

% initialize variables used for error checking
numbinsmode = '';
xlimitsmode = '';
ylimitsmode = '';
numbinsdefined = false;
xlimitsdefined = false;
ylimitsdefined = false;
while ind <= length(args)
    % perform partial matching and completion
    paramname = validatestring(args{ind},names,nameoffset+ind);
    paramvalue = args{ind+1};
    outargs = [outargs paramname {paramvalue}]; %#ok<AGROW>
    ind = ind + 2;
    
    % check for consistency between various properties and associated modes
    switch paramname
        case 'NumBinsMode'
            numbinsmode = validatestring(paramvalue, {'auto', 'manual'}, ...
                funcname, 'NumBinsMode');
        case 'XLimitsMode'
            xlimitsmode = validatestring(paramvalue, {'auto', 'manual'}, ...
                funcname, 'XLimitsMode');
        case 'YLimitsMode'
            ylimitsmode = validatestring(paramvalue, {'auto', 'manual'}, ...
                funcname, 'YLimitsMode');
        case 'NumBins'
            numbinsdefined = true;
        case 'XLimits'
            xlimitsdefined = true;
        case 'YLimits'
            ylimitsdefined = true;
    end
end

% check for consistency between various properties and associated modes
if ~isempty(numbinsmode)
    if strcmp(numbinsmode, 'auto') && numbinsdefined
        error(message('MATLAB:binscatter:NonEmptyNumBinsAutoMode'));
    elseif strcmp(numbinsmode, 'manual') && ~numbinsdefined
        error(message('MATLAB:binscatter:EmptyNumBinsManualMode'));
    end
end
if ~isempty(xlimitsmode)
    if strcmp(xlimitsmode, 'auto') && xlimitsdefined
        error(message('MATLAB:binscatter:NonEmptyXLimitsAutoMode'));
    elseif strcmp(xlimitsmode, 'manual') && ~xlimitsdefined
        error(message('MATLAB:binscatter:EmptyXLimitsManualMode'));
    end
end
if ~isempty(ylimitsmode)
    if strcmp(ylimitsmode, 'auto') && ylimitsdefined
        error(message('MATLAB:binscatter:NonEmptyYLimitsAutoMode'));
    elseif strcmp(ylimitsmode, 'manual') && ~ylimitsdefined
        error(message('MATLAB:binscatter:EmptyYLimitsManualMode'));
    end
end
end

function assignColormap(cax)
a = ancestor(cax,'matlab.graphics.mixin.ThemeContainer');
m = size(get(groot,'DefaultFigureColormap'),1);
if isempty(a) || isempty(a.Theme)
    cax.Colormap = sky(m);
elseif a.Theme.BaseColorStyle == "dark"
    cax.Colormap = abyss(m);
else
    cax.Colormap = sky(m);
end
end
