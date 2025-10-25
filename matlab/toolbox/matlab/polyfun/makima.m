function yq = makima(x,y,xq)
%MAKIMA Modified Akima piecewise cubic Hermite interpolation.
%   YQ = MAKIMA(X,Y,XQ) performs modified Akima cubic Hermite interpolation
%   using the values Y at sample points X to find interpolated values YQ at
%   the query points XQ.
%       - X must be a vector.
%       - If Y is a vector, Y(j) is the value at X(j).
%       - If Y is a matrix or n-D array, Y(:,...,:,j) is the value at X(j).
%
%   MAKIMA chooses slopes at X(j) such that YQ has reduced oscillation.
%   MAKIMA modifies Akima's cubic interpolation formula to eliminate
%   overshoots that arise when the Y data is constant for more than two
%   consecutive points X.
%
%   PP = MAKIMA(X,Y) returns the piecewise polynomial form PP of the
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
%   Example: No overshoot with MAKIMA when the Y data is constant for more
%            than two consecutive points X
%
%       x = 1:12;
%       y = [-1 -1 -1 0 1 1 1 1 1 1.5 1.5 1];
%       xq = 0.75:0.05:12.25;
%       yqm = makima(x,y,xq);
%
%       figure
%       plot(x,y,'ko','LineWidth',2,'MarkerSize',10), hold on
%       plot(xq,yqm,'LineWidth',2)
%       legend('(x,y) data','makima','Location','SouthEast')
%       title('makima has no overshoot for constant data in [5 9]')
%
%   See also INTERP1, SPLINE, PCHIP, PPVAL, MKPP, UNMKPP.

% References:
%    H. Akima, "A New Method of Interpolation and Smooth Curve Fitting
%    Based on Local Procedures", JACM, v. 17-4, p.589-602, 1970.

%   Copyright 2019 The MathWorks, Inc.

% Check and adjust input data
[x,y,sizey] = chckxy(x,y);

% Compute modified Akima slopes
h = diff(x);
m = prod(sizey);
delta = diff(y,1,2)./repmat(h,m,1);
slopes = zeros(size(y));
for r = 1:m
    if isreal(delta)
        slopes(r,:) = makimaSlopes(x,y(r,:),delta(r,:));
    else
        realslopes = makimaSlopes(x,y(r,:),real(delta(r,:)));
        imagslopes = makimaSlopes(x,y(r,:),imag(delta(r,:)));
        slopes(r,:) = complex(realslopes,imagslopes);
    end
end

% Compute piecewise cubic Hermite interpolant for those values and slopes
yq = pwch(x,y,slopes,h,delta);
yq.dim = sizey;

if nargin == 3
    % Evaluate the piecewise cubic Hermite interpolant
    yq = ppval(yq,xq);
end

   
function s = makimaSlopes(x,y,delta)
% Derivative values for modified Akima cubic Hermite interpolation.

% Special case n = 2, use linear interpolation.
n = numel(x);
if n == 2
    s = repmat(delta(1),size(y));
    return
end

% Akima's derivative estimate at grid node x(i) requires the four finite
% differences corresponding to the five grid nodes x(i-2:i+2).
%
% For boundary grid nodes x(1:2) and x(n-1:n), append finite differences
% which would correspond to x(-1:0) and x(n+1:n+2) by using the following
% uncentered difference formula correspondin to quadratic extrapolation
% using the quadratic polynomial defined by data at x(1:3)
% (section 2.3 in Akima's paper):
delta_0  = 2*delta(1)   - delta(2);
delta_m1 = 2*delta_0    - delta(1);
delta_n  = 2*delta(n-1) - delta(n-2);
delta_n1 = 2*delta_n    - delta(n-1);
delta = [delta_m1 delta_0 delta delta_n delta_n1];

% Akima's derivative estimate formula (equation (1) in the paper):
%
%       H. Akima, "A New Method of Interpolation and Smooth Curve Fitting
%       Based on Local Procedures", JACM, v. 17-4, p.589-602, 1970.
%
% s(i) = (|d(i+1)-d(i)| * d(i-1) + |d(i-1)-d(i-2)| * d(i))
%      / (|d(i+1)-d(i)|          + |d(i-1)-d(i-2)|)
%
% To eliminate overshoot and undershoot when the data is constant for more
% than two consecutive nodes, in MATLAB's 'makima' we modify Akima's
% formula by adding an additional averaging term in the weights:
% s(i) = ( (|d(i+1)-d(i)|   + |d(i+1)+d(i)|/2  ) * d(i-1) +
%          (|d(i-1)-d(i-2)| + |d(i-1)+d(i-2)|/2) * d(i)  )
%      / ( (|d(i+1)-d(i)|   + |d(i+1)+d(i)|/2  ) +
%          (|d(i-1)-d(i-2)| + |d(i-1)+d(i-2)|/2)
weights = abs(diff(delta)) + abs(delta(1:end-1)/2 + delta(2:end)/2);

weights1 = weights(1:n);   % |d(i-1)-d(i-2)|
weights2 = weights(3:end); % |d(i+1)-d(i)|
delta1 = delta(2:n+1);     % d(i-1)
delta2 = delta(3:n+2);     % d(i)

weights12 = weights1 + weights2;
s = (weights2./weights12) .* delta1 + (weights1./weights12) .* delta2;

% If the data is constant for more than four consecutive nodes, then the
% denominator is zero and the formula produces an unwanted NaN result.
% Replace this NaN with 0:
s(weights12 == 0) = 0;
