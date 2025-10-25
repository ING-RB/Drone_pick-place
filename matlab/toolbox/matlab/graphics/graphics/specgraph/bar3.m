function hh = bar3(varargin)
%BAR3   3-D bar graph.
%     BAR3(Z) creates a 3-D bar chart, where each element in Z corresponds
%     to one vertical bar. When Z is a vector, the y-axis scale ranges from
%     1 to length(Z). When Z is a matrix, the y-axis scale ranges from 1 to
%     the number of rows in Z.
%
%     BAR3(Y,Z) draws the bars at the locations specified in vector Y.  The
%     y-values can be nonmonotonic, but cannot contain duplicate values.
%
%     BAR3(...,WIDTH) controls the separation between bars. A WIDTH value
%     greater than 1 produces overlapped bars. The default WIDTH value is
%     0.8.
%
%     BAR3(...,STYLE) specifies the bar style, where STYLE is either
%     'detached', 'grouped', or 'stacked'. The default STYLE value is
%     'detached'.
%
%     BAR3(...,COLOR) specifies the line color. Specify the color as one of
%     these values: 'r', 'g', 'b', 'y', 'm', 'c', 'k', or 'w'.
%
%     BAR3(AX,...) plots into the axes AX instead of the current axes.
%
%     H = BAR3(...) returns a vector of Surface objects.
%
%     Example:
%         subplot(1,2,1)
%         bar3(peaks(5))
%         subplot(1,2,2)
%         bar3(rand(5),'stacked')
%
%   See also BAR, BARH, and BAR3H.

%   Mark W. Reichelt 8-24-93
%   Revised by CMT 10-19-94, WSun 8-9-95
%   Copyright 1984-2023 The MathWorks, Inc.

narginchk(1,inf);
[cax,args] = axescheck(varargin{:});

% Look for the 'horizontal' flag, which must be the last input argument and
% does not support partial or case-insensitive matching.
if numel(args)>0 && strcmp(args{end},'horizontal')
    horizontal = true;
    args = args(1:end-1);
else
    horizontal = false;
end

[msg,x,y,xx,yy,linetype,plottype,barwidth,zz] = makebars(args{:},'3');
if ~isempty(msg)
    % Map from xychk errors to bar3/bar3h errors. This is to replace 'X'
    % and 'Y' with either 'Y' or 'Z'.
    % First column xychk, second column bar3, third column bar3h
    errorMessageIDs = {...
        'MATLAB:xychk:lengthXDoesNotMatchNumRowsY', ... % xychk
        'MATLAB:bar:lengthYDoesNotMatchNumRowsZ', ... % bar3
        'MATLAB:bar:lengthZDoesNotMatchNumRowsY'; % bar3h
        'MATLAB:xychk:XAndYLengthMismatch', ... % xychk
        'MATLAB:bar:YAndZLengthMismatch', ... % bar3
        'MATLAB:bar:ZAndYLengthMismatch'; % bar3h
        'MATLAB:xychk:XNotAVector', ... % xychk
        'MATLAB:bar:YNotAVector', ... % bar3
        'MATLAB:bar:ZNotAVector'; % bar3h
        };
    [tf, loc] = ismember(msg.identifier, errorMessageIDs(:,1));
    if tf
        error(message(errorMessageIDs{loc, horizontal+2}));
    else
        error(msg);
    end
end

% m differs from n when 0xn (n>0) empties are provided in bar3(z)
n = size(y,2);
m = size(yy,2)/4; 
p = size(yy,1);

% Create plot
cax = newplot(cax);
fig = ancestor(cax,'figure');

nextPlot = cax.NextPlot;
facec = 'flat';
cc = ones(p,4);

if ~isempty(linetype)
    facec = linetype;
end

if horizontal
    ydataprop = 'zdata';
    ytickprop = 'ztick';
    zdataprop = 'ydata';
    matlab.graphics.internal.configureAxes(cax,xx,zz,y);
else
    ydataprop = 'ydata';
    ytickprop = 'ytick';
    zdataprop = 'zdata';
    matlab.graphics.internal.configureAxes(cax,xx,y,zz);
end

if p==0
    % Avoid warning in surface() when one dimension is 0.
    xx = []; yy = []; zz = []; cc = [];
    colIdx = [];
else
    colIdx = 1:4;
end

h = matlab.graphics.primitive.Surface.empty(1,0);
for i=1:m
    h(i) = surface('xdata',xx+x(i),...
        ydataprop,yy(:,(i-1)*4+colIdx), ...
        zdataprop,zz(:,(i-1)*4+colIdx),...
        'cdata',i*cc, ...
        'FaceColor',facec,...
        'tag','bar3',...
        'parent',cax);
end

if length(h)==1
    set(cax,'clim',[1 2]);
end

if ~strcmp(nextPlot,'add')
    % Set ticks if y values are integers and fewer than threshold.
    % Ticks are not set for non-numeric data.  
    if ~isempty(y) && ...
            isnumeric(y) && ...
            height(y) < 16 && ...
            all(floor(y)==y,'all')
        set(cax,ytickprop,unique(y(:,1)));
    end

    if ~isempty(x)
        xTickAmount = sort(unique(x(1,:)));
        if length(xTickAmount)<2
            set(cax,'xtick',[]);
        elseif length(xTickAmount)<=16
            set(cax,'xtick',xTickAmount);
        end  %otherwise, will use xtickmode auto, which is fine

        if plottype==0
            set(cax,'xlim',[1-barwidth/n/2, max(x)+barwidth/n/2])
        else
            set(cax,'xlim',[1-barwidth/2, max(x)+barwidth/2])
        end

        dx = diff(get(cax,'xlim'));
        if horizontal
            dz = size(y,1)+1;
            dy = (sqrt(5)-1)/2*dz;
        else
            dy = size(y,1)+1;
            dz = (sqrt(5)-1)/2*dy;
        end
        set(cax,'PlotBoxAspectRatio',[dx dy dz])
    end

    cax.YDir = 'reverse';
    view(cax, 3);
end

if ismember(nextPlot, {'replaceall','replace'})
    grid(cax, 'on');
end

% Disable data tips
for i = 1:numel(h)
    set(hggetbehavior(h(i), 'Datacursor'), 'Enable', false);
    setInteractionHint(h(i), 'DataCursor', false);
end

if nargout>0
    hh = h;
end
