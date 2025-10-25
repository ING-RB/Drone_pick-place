function doUpdate(obj,us)
% doUpdate method for PolarRegion

%   Copyright 2023-2024 The MathWorks, Inc.

didapply = obj.applyColor(us, 'FaceColor');
% Compatibility layer: PolarRegion overrides the default
% none color.
if didapply && isequal(obj.SeriesIndex_I, "none")
    set(obj, 'FaceColor_I', 'factory')
end

% Set Child visibility
vis = obj.Visible;
theta = obj.ThetaSpan_I;
r = obj.RadiusSpan_I;
if any(isnan(r)) || any(isnan(theta))
    vis = false;
end
obj.Edge.Visible = vis;
obj.Face.Visible = vis;

% Use 0/2*pi for ThetaSpan at -inf/inf, and RLim for RadiusSpan at -inf/inf
[theta, r] = replaceInfsWithLimits(us.DataSpace, us.TransformUnderDataSpace, theta, r);

% Set properties on child primitives
if vis
    % A crude level of detail computation
    range = abs(diff(theta));
    n = max(ceil(50 * range / (2*pi))*2, 4);

    layer='back';
    if obj.Layer == "top"
        layer = 'front';
    end

    drawEdge(obj,us,r,theta,n,layer)
    drawFace(obj,us,r,theta,n,layer)
end

drawSelectionHandles(obj,us,r,theta,vis);
end

function [theta, r] = replaceInfsWithLimits(ds, transform, theta, r)

theta(theta==-inf) = ds.XLim(1)/transform(1,1);
theta(theta==inf) = ds.XLim(2)/transform(1,1);

r(r == -inf) = ds.YLim(1);
r(r == inf) = ds.YLim(2);

theta = sort(theta,'ascend');
r = sort(r,'ascend');
end

function drawSelectionHandles(obj,us,r,theta,vis)
sameR = r(1)==r(2);
sameTheta = theta(1)==theta(2);

hasVisibleSelectionHandles = vis && obj.Selected && obj.SelectionHighlight && ...
    ((obj.Edge.Visible && (~sameR || ~sameTheta)) || ...
    (~obj.Edge.Visible && (~sameR && ~sameTheta)));

if hasVisibleSelectionHandles
    if isempty(obj.SelectionHandle)
        obj.SelectionHandle = matlab.graphics.interactor.ListOfPointsHighlight('Internal',true);
        obj.addNode(obj.SelectionHandle);
        obj.SelectionHandle.Description = 'PolarRegion SelectionHandle';
    end
    iter = matlab.graphics.axis.dataspace.XYZPointsIterator;

    iter.XData = [theta theta];
    iter.YData = repelem(r,2);
    obj.SelectionHandle.VertexData = TransformPoints(us.DataSpace, us.TransformUnderDataSpace, iter);
    obj.SelectionHandle.Clipping = obj.Clipping;
    obj.SelectionHandle.Visible = 'on';
elseif ~isempty(obj.SelectionHandle)
    obj.SelectionHandle.VertexData = [];
    obj.SelectionHandle.Visible = 'off';
end
end

function drawEdge(obj,us,r,theta,n,layer)
if ~isequal(obj.EdgeColor_I, 'none') && any(isfinite([obj.ThetaSpan_I obj.RadiusSpan_I]))
    [thetadata, radiusdata, stripdata, uselineloop] = getEdgeVertices(n, theta, r, ...
        isfinite(sort(obj.ThetaSpan_I)), isfinite(sort(obj.RadiusSpan_I)));

    if obj.RadiusOffset ~= 0
        midTheta = sum(theta/2);
        [thetadata, radiusdata] = translatePointsAlongAngle( ...
            thetadata, radiusdata, obj.RadiusOffset, midTheta);
    end

    if uselineloop && isa(obj.Edge, 'matlab.graphics.primitive.world.LineStrip')
        obj.Edge = matlab.graphics.primitive.world.LineLoop(Internal = true);
    elseif ~uselineloop && isa(obj.Edge, 'matlab.graphics.primitive.world.LineLoop')
        obj.Edge = matlab.graphics.primitive.world.LineStrip(Internal = true);
    end
    iter = matlab.graphics.axis.dataspace.XYZPointsIterator;
    iter.XData = thetadata;
    iter.YData = radiusdata;
    vd = TransformPoints(us.DataSpace, us.TransformUnderDataSpace, iter);
    obj.Edge.VertexData=vd;
    obj.Edge.StripData = uint32(stripdata);
else
    obj.Edge.Visible = 'off';
end
hgfilter('RGBAColorToGeometryPrimitive', obj.Edge, obj.EdgeColor_I);
obj.Edge.Layer=layer;
end

function drawFace(obj,us,r,theta,n,layer)
color = obj.FaceColor_I;
if ~isequal(color,'none')
    rlim = us.DataSpace.YLim;
    iter = matlab.graphics.axis.dataspace.XYZPointsIterator;
    crossesZero = isequal(r>=rlim(1),[false true]);
    if crossesZero
        thetadata = repmat(repelem(linspace(theta(1),theta(2),n/2),2),1,2);
        radiusdata = [repmat([r(1) rlim(1)],1,n/2) repmat([rlim(1) r(2)],1,n/2)];
    else
        thetadata = repelem(linspace(theta(1),theta(2),n),2);
        radiusdata = repmat(r,1,n);
    end

    if obj.RadiusOffset ~= 0
        midTheta = sum(theta/2);
        [thetadata, radiusdata] = translatePointsAlongAngle( ...
            thetadata, radiusdata, obj.RadiusOffset, midTheta);
    end
    iter.XData = thetadata;
    iter.YData = radiusdata;

    vd = TransformPoints(us.DataSpace, us.TransformUnderDataSpace, iter);
    obj.Face.VertexData=vd;
    obj.Face.StripData=uint32([1 n*2+1]);
    color=[color obj.FaceAlpha_I];
else
    obj.Face.Visible = 'off';
end
obj.Face.Layer=layer;
hgfilter('RGBAColorToGeometryPrimitive', obj.Face, color);
end

function [theta, r, stripdata, uselineloop] = getEdgeVertices(n, thetaspan, radiusspan, thetafinite, rfinite)
% To choose vertices:
%   start by drawing the inner arc, from the first to the second theta
%   then draw the 'spoke' connecting the arcs at the second theta
%   then draw the outer arc, from the second to the first theta
%   then draw the 'spoke' connecting the arcs at the first theta
%
%   skip segments that aren't finite.


theta = [];
r = [];
if rfinite(1)
    % Add points for an inner arc
    theta = linspace(thetaspan(1),thetaspan(2), n);
    r = repelem(radiusspan(1), n);
elseif thetafinite(2)
    % There's no inner arc, but there is a second spoke. Add a point for
    % the spoke.
    theta = thetaspan(2);
    r = radiusspan(1);
end

if rfinite(2)
    % Add points for outer arc
    theta = [theta linspace(thetaspan(2),thetaspan(1), n)];
    r = [r repelem(radiusspan(2), n)];
else
    if thetafinite(2)
        % There's no outer arc, but there is a second spoke. Add a point
        % for the spoke.
        theta = [theta thetaspan(2)];
        r = [r radiusspan(2)];
    end
    if thetafinite(1)
        % There's no outer arc, but there is a first spoke. Add a point
        % for the spoke.
        theta = [theta thetaspan(1)];
        r = [r radiusspan(2)];
    end
end

% if there is no inner arc and there is a first spoke, append the first
% inner spoke point
if ~rfinite(1) && thetafinite(1)
    theta = [theta thetaspan(1)];
    r = [r radiusspan(1)];
end

% Stripdata can run from the first to the last vertex unless two rings are
% drawn
stripdata = [1 numel(theta)+1];
if all(~thetafinite)
    stripdata = [1 n+1 numel(theta)+1];
end

% use a lineloop if both spokes and arcs are shown, or if both spokes and
% the outer arc is shown. Don't use a lineloop for rings (theta -inf:inf)
% because theta limits add complication
uselineloop = all(thetafinite) && rfinite(2);

% There will be a missing join if:
%  a. there's no outer arc but there is an inner arc and a first spoke
%  b. there's no second spoke but the rest of the segments exist
%  c. there are no arcs and two spokes (which meet at the lower r)
%
% move the first spoke to the beginning
shift = 0;
if isequal(rfinite, [true false]) && thetafinite(1)
    % start with first spoke
    shift = 1;
elseif all(thetafinite) && all(~rfinite)
    % start with outer vertex of first spoke
    shift = 2;
elseif isequal(thetafinite, [true false]) && all(rfinite)
    % start with upper arc
    shift = n;
end
theta = circshift(theta, shift);
r = circshift(r, shift);

end

function [t, r] = translatePointsAlongAngle(theta, rho, offset, translationAngle)
% translate points at (theta, rho) along translationAngle, by offset
[x, y] = pol2cart(theta, rho);
x = x + offset * cos(translationAngle);
y = y + offset * sin(translationAngle);
[t, r] = cart2pol(x, y);
end
