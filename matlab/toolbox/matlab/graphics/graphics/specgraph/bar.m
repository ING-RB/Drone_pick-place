function hh = bar(varargin)
%

%   Copyright 1984-2024 The MathWorks, Inc.

matlab.graphics.chart.internal.DDUXLogger(mfilename,varargin);

import matlab.graphics.chart.internal.inputparsingutils.peelFirstArgParent
import matlab.graphics.chart.internal.inputparsingutils.getParent
import matlab.graphics.chart.internal.inputparsingutils.prepareAxes

% Check for first argument parent.
supportDoubleAxesHandle = true;
[parent, args] = peelFirstArgParent(varargin, supportDoubleAxesHandle);

% First, we need to extract the P/V pairs
reservedWords = {'grouped','stacked','hist','histc'};

% The first input might be x-data, which can be strings or cellstrs which 
% extractPVPairs will erroneously detect as part of a name/value pair. To avoid 
% this the first argument is not passed into extractPVPairs. The first input
% argument must be either x or y data so it cannot be a part of a name/value pair.
narginchk(1,inf)
[numArgs, pvPairs] = extractPVPairs(args(2:end),reservedWords);
numArgs = numArgs+1;

% We can only have up to five non-P/V arguments - x,y,width,style,color
if numArgs < 1
    error(message('MATLAB:narginchk:notEnoughInputs'));
elseif numArgs > 5
    error(message('MATLAB:narginchk:tooManyInputs'));
end
args = args(1:numArgs);
pvPairs = matlab.graphics.internal.convertStringToCharArgs(pvPairs);

% Peel off Horizontal property to be used in the constructor if given.  If
% not given, we'll use the default value.  ishorizontal is set to false
% initially in case we need to go through the hist or histc options and the
% horizontal pv pair isn't given.
ishorizontal = false; 
useDefaultHorizontal = true;
i = 1;
while i < numel(pvPairs)
    if numel(pvPairs{i}) > 1 && startsWith('Horizontal_I',pvPairs{i})
        if strcmpi(pvPairs{i+1},'on')
            horizontal_val = 'on';
            ishorizontal = true;
            useDefaultHorizontal = false;
            
            % Strip horizontal pv pair from pvPairs
            pvPairs([i i+1]) = [];
        elseif strcmpi(pvPairs{i+1},'off')
            horizontal_val = 'off';
            ishorizontal = false;
            useDefaultHorizontal = false;
            
            % Strip horizontal pv pair from pvPairs
            pvPairs([i i+1]) = [];
        else
            % If Horizontal_I is not 'on' or 'off', leave it in the list of
            % name/value pairs. It will be passed to the constructor and
            % generate the correct error then.
            i = i+2;
        end
    else
        i = i+2;
    end
end

% Working backwards, take care of string arguments:
while matlab.graphics.internal.isCharOrString(args{numArgs}) && (numArgs > 1)
    args{numArgs} = char(args{numArgs});
    if any(strcmpi(args{numArgs}(1:min(4,length(args{numArgs}))),{'grou','stac'}))
        %grouped or stacked property specified
        pvPairs(end+1:end+2) = {'BarLayout',args{numArgs}};
    elseif any(strcmpi(args{numArgs},{'hist','histc'}))
        % We are going through the hist command.

        % Check for a parent name/value pair.
        [parent, ~, pvPairs] = getParent(parent, pvPairs);

        % Any remaining input arguments following 'hist' or 'histc' are ignored.
        if ~isempty(pvPairs) && ~(ishorizontal && isequal(pvPairs, {'HorizontalMode','manual'}))
            warning(message('MATLAB:bar:HistIgnoredInputs', args{numArgs}));
        end
        
        if ishorizontal
            h = barhV6(parent,args{:});
        else
            h = barV6(parent,args{:});
        end

        if nargout>0
            hh = h;
        end

        return
    else % We have a linespec
        [l,c,m,msg] = colstyle(args{numArgs},'plot');
        if ~isempty(l) || ~isempty(m) || ~isempty(msg)
            error(message('MATLAB:bar:UnrecognizedOption',args{numArgs}));
        end
        if ~isempty(c)
            pvPairs(end+1:end+2) = {'FaceColor',c}; %Note FaceColor, not Color
        end
    end
    numArgs = numArgs-1;
    args(end) = [];
end

% Check to see if we have a width input argument:
if numArgs == 3
    if isscalar(args{3})
        pvPairs(end+1:end+2) = {'BarWidth',args{3}};
        numArgs = numArgs-1;
        args(end) = [];
    else
        error(message('MATLAB:narginchk:tooManyInputs'));
    end
elseif numArgs == 2
    if isnumeric(args{2}) && isscalar(args{2}) && ~isscalar(args{1})
        % We have a width argument
        pvPairs(end+1:end+2) = {'BarWidth',args{2}};
        numArgs = numArgs-1;
        args(end) = [];
    end
elseif numArgs > 3
    error(message('MATLAB:narginchk:tooManyInputs'));
end

autoColor = extractColorProp(pvPairs);

% get the real component if data are complex
allowNonNumeric = true;
allowText = true;
args = matlab.graphics.chart.internal.getRealData(args,allowNonNumeric,allowText);

isXDataModeAuto = false;
x = [];
if numArgs == 1 % bar(y)
    % We have a matrix as input. In this case, each column will be a distinct
    % Bar object.
    y = args{1};
    
    % Make sure y is full
    if isnumeric(y)
        y = full(y);
    end
    if ~ismatrix(y)
        error(message('MATLAB:xychk:non2DInput'));
    end

    isXDataModeAuto = true;
    if isvector(y)
        y = y(:);
    end
else % bar(x,y)
    x = args{1};
    y = args{2};
    
    % Make sure x is full
    if isnumeric(x)
        x = full(x);
    % Convert strings/cellstrs to categorical, removing empties from category data
    elseif isstring(x) || iscellstr(x)
        nonEmpty = x(~ismissing(cellstr(x)));
        x = categorical(x,unique(nonEmpty,'stable'));
    end
    % Make sure y is full
    if isnumeric(y)
        y = full(y);
    end
    
    [msg,x,y] = matlab.graphics.chart.primitive.internal.findMatchingDimensions(x,y);
    if ~isempty(msg)
        error(message(msg))
    end
    
    if height(x) > 1
        sortedx = sort(x,1);
        if any(sortedx(2:end,:) == sortedx(1:end-1,:),"all")
            error(message('MATLAB:bar:DuplicateXValue'));
        end
    end
end
if isa(y,'datetime') || isa(y,'categorical') || isstring(y) || iscellstr(y)
    error(message('MATLAB:specgraph:private:specgraph:DatetimeDependent'));
end

[parent, hasParent] = getParent(parent, pvPairs);
[parent, ancestorAxes, nextplot] = prepareAxes(parent, hasParent, true);

if isscalar(ancestorAxes)
    [x, y] = configureAxesRulers(ancestorAxes, ishorizontal, x, y);
end

numSeries = width(y);
% Create the bars - note that the offsets are set after the bars are created:
h = repmat(matlab.graphics.GraphicsPlaceholder(),1,numSeries);
for i=1:numSeries
    yi = y(:,i);
    xDataPV = {};
    if ~isXDataModeAuto
        xDataPV = {'XData',x(:,i)};
    end

    colorProp = cell(1,0);
    if isscalar(ancestorAxes)
        [~,c] = matlab.graphics.chart.internal.nextstyle(ancestorAxes,autoColor,false,true);
        colorProp = {'FaceColor_I', c};
    end

    % If we did not get a Horizontal value, don't set it (and use the
    % DefaultBarHorizontal value).  If we did get a Horizontal value, it
    % must be set before BaseValue because BaseValue needs to know which of
    % X/YBaseline to set it on. In either case Axes must be set before the
    % BaseValue for similar reasons.
    if useDefaultHorizontal
        h(i) = matlab.graphics.chart.primitive.Bar('Parent', parent, ...
          'YData', yi, xDataPV{:}, colorProp{:}, ...
          'NumPeers', numSeries, ...
          pvPairs{:});        
    else
        h(i) = matlab.graphics.chart.primitive.Bar('Parent', parent,...
          'ExchangeXY', horizontal_val, ...
          'Horizontal_I', horizontal_val, ...
          'YData', yi,xDataPV{:}, colorProp{:}, ...
          'NumPeers', numSeries, ...
          pvPairs{:});
    end
    
    h(i).assignSeriesIndex();
end

BarPeerID = matlab.graphics.chart.primitive.utilities.incrementPeerID();
for i=1:numSeries
    h(i).doPostSetup(BarPeerID);
end

if ~isempty(h)
    if ~isXDataModeAuto
        xt=unique(x);
    else
        xt=unique([h.XData]);
    end
    if ~iscategorical(x)
        matlab.graphics.chart.primitive.bar.internal.tickCallback(ancestorAxes, xt, h(1).Horizontal, false);
    end
    if strcmp(h(1).BarLayout,'grouped')
        numAdjacentBars = numel(y);
    else
        numAdjacentBars = size(y,1);
    end
else
    numAdjacentBars=0;
end

% Turn off edges when they start to overwhelm the colors
% The threshold is 150 adjacent bars
if numAdjacentBars > 150 && ~any(strcmpi('EdgeColor',pvPairs(1:2:end)))
    for i=1:numSeries
        h(i).EdgeColor = 'none';
    end
end

switch nextplot
    case {'replaceall','replace'}
        view(ancestorAxes,2);
        ancestorAxes.Box = 'on';
        ancestorAxes.Layer = 'bottom';
        matlab.graphics.internal.setRulerLayerTop(ancestorAxes);
    case 'replacechildren'
        ancestorAxes.Layer = 'bottom';
        matlab.graphics.internal.setRulerLayerTop(ancestorAxes);
end

% Make sure to call "getcolumn" for properties that require it:
if ~isempty(h)
    if numSeries > 1
        localCallGetColumn(h,numSeries,'DisplayName');
        localCallGetColumn(h,numSeries,'XDataSource');
        localCallGetColumn(h,numSeries,'YDataSource');
    end
end

if nargout>0, hh = h; end

%-------------------------------------------------------------------------%
function localCallGetColumn(h,numSeries,propName)
propMode = get(h, [propName 'Mode']);
propName = [propName '_I']; 
if strcmp(propMode, 'auto')
    return;
end
propVal = get(h(1),propName);
if isempty(propVal)
    return;
end

newVals = getcolumn(propVal,1:numSeries,'expression');
for i=1:numSeries
    set(h(i),propName,newVals{i});
end


function autoColor = extractColorProp(pvPairs)
autoColor = true;
for i = 1:2:numel(pvPairs)
    if startsWith('FaceColor',pvPairs{i}) && ~strcmp(pvPairs{i+1},'flat')
        autoColor = false;
    end
end


function [x, y] = configureAxesRulers(hAx, ishorizontal, x, y)
if ishorizontal
    matlab.graphics.internal.configureAxes(hAx,y,x);
    [y,x] = matlab.graphics.internal.makeNumeric(hAx,y,x);
else
    matlab.graphics.internal.configureAxes(hAx,x,y);
    [x,y] = matlab.graphics.internal.makeNumeric(hAx,x,y);
end
