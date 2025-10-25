function comet3(varargin)
%COMET3 3-D Comet-like trajectories.
%   COMET3(Z) displays an animated three dimensional plot of the vector Z.
%   COMET3(X,Y,Z) displays an animated comet plot of the curve through the
%   points [X(i),Y(i),Z(i)].
%   COMET3(X,Y,Z,p) uses a comet of length p*length(Z). Default is p = 0.1.
%
%   COMET3(AX,...) plots into AX instead of GCA.
%
%   Example:
%       t = -pi:pi/500:pi;
%       comet3(sin(5*t),cos(3*t),t)
%
%   See also COMET.

%   Charles R. Denham, MathWorks, 1989.
%   Revised 2-9-92, LS and DTP; 8-18-92, 11-30-92 CBM.
%   Copyright 1984-2022 The MathWorks, Inc.

% Parse possible Axes input
[ax,args,nargs] = axescheck(varargin{:});

if nargs < 1
    error(message('MATLAB:narginchk:notEnoughInputs'));
elseif nargs > 4
    error(message('MATLAB:narginchk:tooManyInputs'));
end

% Parse the rest of the inputs
bodyLengthProportion = 0.10;
if nargs < 2, x = args{1}; end
if nargs == 2, y = args{2}; end
if nargs < 3, z = x; x = 1:length(z); y = 1:length(z); end
if nargs == 3, [x,y,z] = deal(args{:}); end
if nargs == 4, [x,y,z,bodyLengthProportion] = deal(args{:}); end

if ~isscalar(bodyLengthProportion) || ~isreal(bodyLengthProportion) || bodyLengthProportion < 0 || bodyLengthProportion >= 1
    error(message('MATLAB:comet3:InvalidP'));
end

x = matlab.graphics.chart.internal.datachk(x);
y = matlab.graphics.chart.internal.datachk(y);
z = matlab.graphics.chart.internal.datachk(z);

if ~isvector(x) || ~isvector(y) || ~isvector(z) || ...
        numel(x) ~= numel(y) || numel(x) ~= numel(z)
    error(message('MATLAB:comet3:XYZVectorsSameLength'));
end

ax = newplot(ax);
if ~strcmp(ax.NextPlot,'add')
    % If NextPlot is 'add', assume other objects are driving the limits.
    % Otherwise, set the limits so that the axes limits don't jump around
    % during animation.
    [minx,maxx] = minmax(x);
    [miny,maxy] = minmax(y);
    [minz,maxz] = minmax(z);
    if ~isa(ax,'matlab.graphics.axis.GeographicAxes') && ~isa(ax,'map.graphics.axis.MapAxes')
        axis(ax,[minx maxx miny maxy minz maxz])
        view(ax,3);
    else
        % Latitudes are the first axis (x) and longitudes are the second
        % axis (y).
        latmin = minx;
        latmax = maxx;
        lonmin = miny;
        lonmax = maxy;
        
        % Buffer the limits for better display.
        bufferInPercent = 5;
        f = 1 + bufferInPercent / 100;
        half = f * (latmax - latmin)/2;
        latlim = [-half, half] + (latmin + latmax)/2;
        latlim(1) = max(latlim(1), -90);
        latlim(2) = min(latlim(2),  90);
        half = f * (lonmax - lonmin)/2;
        lonlim = [-half, half] + (lonmin + lonmax)/2;
        
        geolimits(ax,latlim,lonlim)
    end
end

totalLength = length(z);
bodyLength = round(bodyLengthProportion*totalLength);

% Choose first three colors for head, body, and tail
head = line('parent',ax,'SeriesIndex_I',0,'marker','o', ...
    'xdata',x(1),'ydata',y(1),'zdata',z(1),'tag','head');
body = animatedline('parent',ax,'SeriesIndex_I',0,...
                    'MaximumNumPoints',max(1,bodyLength),'Tag','body');
tail = animatedline('parent',ax,'SeriesIndex_I',0,'linestyle','-',...
                    'MaximumNumPoints',1+totalLength, 'Tag','tail');

if isequal(body.Color,tail.Color) && isequal(body.LineStyle, tail.LineStyle)
    body.LineStyle='--';
end

if length(x) < 2000
    updateFcn = @()drawnow;
else
    updateFcn = @()drawnow('limitrate');
end

% Grow the body
for i = 1:bodyLength
    % Protect against deleted objects following the call to drawnow.
    if ~(isvalid(head) && isvalid(body))
        return
    end
    set(head,'xdata',x(i),'ydata',y(i),'zdata',z(i))
    addpoints(body,x(i),y(i),z(i));
    updateFcn();
end

% Add a drawnow to capture any events / callbacks
drawnow

% Initialize tail with first point. The next point will be added in the
% first iteration of the primary loop below, creating the first line
% segment of the tail.
addpoints(tail,x(1),y(1),z(1));

% Primary loop
totalLength = length(x);
for i = bodyLength+1:totalLength
    % Protect against deleted objects following the call to drawnow.
    if ~(isvalid(head) && isvalid(body) && isvalid(tail))
        return
    end
    set(head,'xdata',x(i),'ydata',y(i),'zdata',z(i))
    addpoints(body,x(i),y(i),z(i));
    
    nextTailIndex = i-bodyLength+1;
    if(nextTailIndex<=totalLength)
        addpoints(tail,x(nextTailIndex),y(nextTailIndex),z(nextTailIndex));
    end
    updateFcn();
end
drawnow

% Allow tail to continue on to the full length. The last point added to the 
% tail in the primary loop above was at index (totalLength-bodyLength+1), 
% so this loop starts at the following index. 
for i = totalLength-bodyLength+2:totalLength
    % Protect against deleted objects following the call to drawnow.
    if ~isvalid(tail)
        return
    end
    addpoints(tail, x(i),y(i),z(i));
    updateFcn();
end
drawnow

% same subfunction as in comet
function [minx,maxx] = minmax(x)
minx = min(x(isfinite(x)));
maxx = max(x(isfinite(x)));
if minx == maxx
    minx = maxx-1;
    maxx = maxx+1;
end
