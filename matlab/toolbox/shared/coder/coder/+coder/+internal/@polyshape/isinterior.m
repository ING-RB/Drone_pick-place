function [INPOLY, ONPOLY] = isinterior(pshape, varargin)
%MATLAB Code Generation Library Function
% ISINTERIOR Logicals indicating whether the point is on or in polyshape

%   Copyright 2022 The MathWorks, Inc.

%#codegen

narginchk(2, 3);
coder.internal.polyshape.checkScalar(pshape);

param.allow_inf = true;
param.allow_nan = true;
param.one_point_only = false;
param.errorOneInput = 'MATLAB:polyshape:queryPoint1';
param.errorTwoInput = 'MATLAB:polyshape:queryPoint2';
param.errorValue = 'MATLAB:polyshape:queryPointValue';
[X, Y] = coder.internal.polyshape.checkPointArray(param, varargin{:});

if isEmptyShape(pshape)
    INPOLY = false(numel(X),1);
    ONPOLY = false(numel(X),1);
    return;
end

%boundary is closed
[xt, yt] = boundary(pshape);
xv = [xt; nan];
yv = [yt; nan];

[xlim, ylim] = boundingbox(pshape);
xlim = abs(xlim);
ylim = abs(ylim);
maxD = max(xlim(1), xlim(2));
maxD = max(maxD, ylim(1));
maxD = max(maxD, ylim(2));
maxW = max(xlim(2)-xlim(1), ylim(2)-ylim(1));
tol = (maxD+maxW)*1.0e-12;

[in, on] = check_inpolygon(X(:).', Y(:).', xv, yv, tol);

INPOLY = reshape(in, size(X));
ONPOLY = reshape(on, size(X));

%--------------------------------------------------------------------------

function [inPoly, onPoly] = check_inpolygon(x,y,xv,yv,tol)

Nv = length(xv);
Np = length(x);

inPoly = coder.nullcopy(zeros(size(x),'logical'));
onPoly = coder.nullcopy(zeros(size(x),'logical'));
% Compute scale factors for eps that are based on the original vertex
% locations. This ensures that the test points that lie on the boundary
% will be evaluated using an appropriately scaled tolerance.
% (m and mp1 will be reused for setting up adjacent vertices later on.)
m = 1:Nv-1;
mp1 = 2:Nv;

% Translate the vertices so that the test points are
% at the origin.
for ii = 1:Np
    xvt = xv(:,1) - x(ii);
    yvt = yv(:,1) - y(ii);
    
    % Compute the quadrant number for the vertices relative
    % to the test points.
    posX = xvt > 0;
    posY = yvt > 0;
    negX = ~posX;
    negY = ~posY;
    quad = (negX & posY) + 2*(negX & negY) + 3*(posX & negY);
    
    % Ignore crossings between distinct edge loops that are separated by NaNs
    nanidx = isnan(xv) | isnan(yv);
    quad(nanidx) = NaN;
    % Compute the sign() of the cross product and dot product
    % of adjacent vertices.
    theCrossProd = xvt(m,:) .* yvt(mp1,:) - xvt(mp1,:) .* yvt(m,:);
    signCrossProduct = sign(theCrossProd);
    
    
    % Adjust values that are within epsilon of the polygon boundary.
    % Making epsilon larger will treat points close to the boundary as
    % being "on" the boundary. A factor of 3 was found from experiment to be
    % a good margin to hedge against roundoff.
    
    %scaledEps = scaleFactor*eps*3;
    %idx = abs(theCrossProd) < scaledEps;
    idx = abs(theCrossProd) < tol;
    signCrossProduct(idx) = 0;
    
    dotProduct = xvt(m,:) .* xvt(mp1,:) + yvt(m,:) .* yvt(mp1,:);
    
    % Compute the vertex quadrant changes for each test point.
    diffQuad = diff(quad);
    
    % Fix up the quadrant differences.  Replace 3 by -1 and -3 by 1.
    % Any quadrant difference with an absolute value of 2 should have
    % the same sign as the cross product.
    idx = (abs(diffQuad) == 3);
    diffQuad(idx) = -diffQuad(idx)/3;
    idx = (abs(diffQuad) == 2);
    diffQuad(idx) = 2*signCrossProduct(idx);
    
    % Find the inside points.
    % Ignore crossings between distinct loops that are separated by NaNs
    nanidx = isnan(diffQuad);
    diffQuad(nanidx) = 0;
    in = (sum(diffQuad) ~= 0);
    
    % Find the points on the polygon.  If the cross product is 0 and
    % the dot product is nonpositive anywhere, then the corresponding
    % point must be on the contour.
    on = any((signCrossProduct == 0) & (dotProduct <= 0));
    
    in = in | on;
    inPoly(ii) = in;
    onPoly(ii) = on;
end