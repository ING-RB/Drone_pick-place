function output = spline(x,y,xq)
%SPLINE Cubic spline data interpolation.
%   YQ = SPLINE(X,Y,XQ) performs cubic spline interpolation using the
%   values Y at sample points X to find interpolated values YQ at the query
%   points XQ.
%       - X must be a vector.
%       - If Y is a vector, Y(j) is the value at X(j).
%       - If Y is a matrix or n-D array, Y(:,...,:,j) is the value at X(j).
%
%   SPLINE chooses slopes at X(j) such that YQ has a continuous second
%   derivative. Thus, SPLINE produces smooth results.
%
%   Ordinarily, SPLINE uses not-a-knot conditions for the end slopes at
%   X(1) and X(end). However, if Y contains two more values than X has
%   entries, then the first and last value in Y are used as the end slopes.
%
%   PP = SPLINE(X,Y) returns the piecewise polynomial form PP of the
%   interpolant. You can use PP as an input to PPVAL or UNMKPP.
%
%   Comparison of SPLINE, PCHIP, and MAKIMA:
%       - All three are a form of piecewise cubic Hermite interpolation,
%         but each function computes the slopes of YQ at X(j) differently.
%       - SPLINE chooses slopes at X(j) such that the second derivative of
%         YQ is continuous. Therefore, SPLINE is smoother and more accurate
%         if the Y data represents values of a smooth function.
%       - PCHIP has no overshoots and less oscillation than SPLINE.
%       - MAKIMA has less oscillation than SPLINE but may have overshoots.
%       - PCHIP and MAKIMA are less expensive than SPLINE to set up PP.
%       - All three are equally expensive to evaluate.
%       - SPLINE and MAKIMA generalize to n-D grids. See INTERPN.
%
%   Example: Compare SPLINE, PCHIP, and MAKIMA
%
%       x = [1 2 3 4 5 5.5 7 8 9 9.5 10];
%       y = [0 0 0 0.5 0.4 1.2 1.2 0.1 0 0.3 0.6];
%       xq = 0.75:0.05:10.25;
%       yqs = spline(x,y,xq);
%       yqp = pchip(x,y,xq);
%       yqm = makima(x,y,xq);
%
%       plot(x,y,'ko','LineWidth',2,'MarkerSize',10)
%       hold on
%       plot(xq,yqp,'LineWidth',4)
%       plot(xq,yqs,xq,yqm,'LineWidth',2)
%       legend('(x,y) data','pchip','spline','makima')
%
%   Example: Interpolate a sine-like curve over a finer mesh
%
%       x = 0:10;
%       y = sin(x);
%       xq = 0:.25:10;
%       yq = spline(x,y,xq);
%       figure
%       plot(x,y,'o',xq,yq)
%
%   Example: Perform spline interpolation with prescribed end slopes.
%            Set the slopes to zero at the end points of the interpolant.
%
%       x = -4:4;
%       y = [0 .15 1.12 2.36 2.36 1.46 .49 .06 0];
%       cs = spline(x,[0 y 0]);
%       xq = linspace(-4,4,101);
%       figure
%       plot(x,y,'o',xq,ppval(cs,xq));
%
%   See also INTERP1, MAKIMA, PCHIP, PPVAL, MKPP, UNMKPP.

%   Carl de Boor 7-2-86
%   Copyright 1984-2024 The MathWorks, Inc.

% Check and adjust input data
[x,y,sizey,endslopes] = chckxy(x,y);
n = length(x);
yd = prod(sizey);

% Generate the cubic spline interpolant in ppform
dd = ones(yd,1);
dx = diff(x);
divdif = diff(y,[],2)./dx(dd,:);
if n == 2
    if isempty(endslopes)
        % the interpolant is a straight line
        pp = mkpp(x,[divdif y(:,1)],sizey);
    else
        % the interpolant is the cubic Hermite polynomial
        pp = pwch(x,y,endslopes,dx,divdif);
        pp.dim = sizey;
    end
elseif n == 3 && isempty(endslopes)
    % the interpolant is a parabola
    y(:,2:3) = divdif;
    y(:,3) = diff(divdif')'/(x(3)-x(1));
    y(:,2) = y(:,2)-y(:,3)*dx(1);
    pp = mkpp(x([1,3]),y(:,[3 2 1]),sizey);
else
    % set up the sparse, tridiagonal, linear system b = ?*c for the slopes
    b = zeros(yd,n,superiorfloat(x,y));
    b(:,2:n-1) = 3*(dx(dd,2:n-1).*divdif(:,1:n-2)+dx(dd,1:n-2).*divdif(:,2:n-1));
    if isempty(endslopes)
        x31 = x(3)-x(1);
        xn = x(n)-x(n-2);
        b(:,1) = ((dx(1)+2*x31)*dx(2)*divdif(:,1)+dx(1)^2*divdif(:,2))/x31;
        b(:,n) = (dx(n-1)^2*divdif(:,n-2)+(2*xn+dx(n-1))*dx(n-2)*divdif(:,n-1))/xn;
    else
        x31 = 0;
        xn = 0;
        b(:,[1 n]) = dx(dd,[2 n-2]).*endslopes;
    end
    dxt = dx(:);
    c = spdiags([ [x31;dxt(1:n-2);0] ...
        [dxt(2);2*(dxt(2:n-1)+dxt(1:n-2));dxt(n-2)] ...
        [0;dxt(2:n-1);xn] ],[-1 0 1],n,n);
    
    % sparse linear equation solution for the slopes
    mmdflag = spparms('autommd');
    spparms('autommd',0);
    s = b/c;
    spparms('autommd',mmdflag);
    
    % construct piecewise cubic Hermite interpolant
    % to values and computed slopes
    pp = pwch(x,y,s,dx,divdif);
    pp.dim = sizey;
end

if nargin == 2
    output = pp;
else
    output = ppval(pp,xq);
end
