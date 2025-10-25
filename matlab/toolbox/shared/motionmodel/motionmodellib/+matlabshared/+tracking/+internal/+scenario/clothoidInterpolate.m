function [z0, z1, z2, z3]  = clothoidInterpolate(s, clothspline) %#codegen
%CLOTHOIDINTERPOLATE interpolates using the clothoid model.

%   Copyright 2022 The MathWorks, Inc.

% use column vector input
assert(isvector(s));

k0 = clothspline.k0;
k1 = clothspline.k1;
hl = clothspline.hl;
hip = clothspline.hip;
hcd = clothspline.hcd;
course = clothspline.course;

% copy into temp
l_0 = s(:);

% find nan values
nans = find(~isfinite(s));
l_0(nans(:)) = hcd(1);

% find index into table (if endpoints overrun, clamp them)

l_0(s>hcd(end)) = hcd(end);
l_0(s<hcd(1)) = hcd(1);

idx = discretize(l_0, hcd);

% fetch clothoid segment at index and initial position.
dkappa = (k1(idx)-k0(idx))./hl(idx);
dkappa(isnan(dkappa)) = 0;
kappa0 = k0(idx);
theta = course(idx);
p0 = hip(idx);

% get length into clothoid segment
l = l_0-hcd(idx);

% compute 0th through 3rd derivative of trajectory with respect to length
% evaluated at l(t).
z0 = matlabshared.tracking.internal.scenario.fresnelg2(l, dkappa, kappa0, theta);
z1 = matlabshared.tracking.internal.scenario.dfresnelg2(l, dkappa, kappa0, theta);
z2 = matlabshared.tracking.internal.scenario.ddfresnelg2(l, dkappa, kappa0, theta);
z3 = matlabshared.tracking.internal.scenario.dddfresnelg2(l, dkappa, kappa0, theta);

% offset by initial point
z0 = p0 + z0;

% clobber nans
z0(nans) = nan;
z1(nans) = nan;
z2(nans) = nan;
z3(nans) = nan;
end
