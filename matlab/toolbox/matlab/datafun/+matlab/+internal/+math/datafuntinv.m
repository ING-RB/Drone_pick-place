function x = datafuntinv(p,v)
% DATAFUNTINV Compute Student's t inverse cumulative distribution function 
% for outlier functions

%   FOR INTERNAL USE ONLY -- This feature is intentionally undocumented.
%   Its behavior may change, or it may be removed in a future release.

%   Copyright 2016 - 2024 The MathWorks, Inc.

x = NaN(size(p));
x(p==0 & v > 0) = -Inf;
x(p==1 & v > 0) = Inf;
k0 = (0<p & p<1) & (v > 0);

% Invert the Cauchy distribution explicitly
k = find(k0 & (v == 1));
if any(k)
  x(k) = tan(pi * (p(k) - 0.5));
end

% For small d.f., call betaincinv which uses Newton's method
k = find(k0 & (v < 1000) & (v~=1));
if any(k)
    q = p(k) - .5;
    df = v(k);
    t = (abs(q) < .25);
    z = zeros(size(q), 'like', x);
    oneminusz = zeros(size(q), 'like', x);
    if any(t)
        % for z close to 1, compute 1-z directly to avoid roundoff
        oneminusz(t) = betaincinv(2.*abs(q(t)),0.5,df(t)/2,'lower');
        z(t) = 1 - oneminusz(t);
    end
    t = ~t; % (abs(q) >= .25);
    if any(t)
        z(t) = betaincinv(2.*abs(q(t)),df(t)/2,0.5,'upper');
        oneminusz(t) = 1 - z(t);
    end
    x(k) = sign(q) .* sqrt(df .* (oneminusz./z));
end

% For large d.f., use Abramowitz & Stegun formula 26.7.5
% k = find(p>0 & p<1 & ~isnan(x) & v >= 1000);
k = find(k0 & (v >= 1000));
if any(k)
   xn = -sqrt(2).*erfcinv(2*p(k));
   df = v(k);
   x(k) = xn + (xn.^3+xn)./(4*df) + ...
           (5*xn.^5+16.*xn.^3+3*xn)./(96*df.^2) + ...
           (3*xn.^7+19*xn.^5+17*xn.^3-15*xn)./(384*df.^3) +...
           (79*xn.^9+776*xn.^7+1482*xn.^5-1920*xn.^3-945*xn)./(92160*df.^4);
end