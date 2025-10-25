function [position, velocity, acceleration, jerk] ...
    = getPositionalState(hcd, hip, hl, k0, k1, course, hpp, hspp, happ, hjpp, t)
%FUSION.SCENARIO.INTERNAL.GETPOSITIONALSTATE interpolates positional splines

%   Copyright 2017-2019 The MathWorks, Inc.

%#codegen

% compute 0th through 3rd derivative of length traveled with respect to time.

assert(iscolumn(t));

l_0 = ppval(hpp, t);
l_1 = ppval(hspp, t);
l_2 = ppval(happ, t);
l_3 = ppval(hjpp, t);

% find index into table 
l_0(l_0>hcd(end)) = hcd(end);
l_0(l_0<hcd(1)) = hcd(1);
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
f_0 = matlabshared.tracking.internal.scenario.fresnelg2(l, dkappa, kappa0, theta);
f_1 = matlabshared.tracking.internal.scenario.dfresnelg2(l, dkappa, kappa0, theta);
f_2 = matlabshared.tracking.internal.scenario.ddfresnelg2(l, dkappa, kappa0, theta);
f_3 = matlabshared.tracking.internal.scenario.dddfresnelg2(l, dkappa, kappa0, theta);

% position = f(l(t))
position = p0 + f_0;

% velocity = f'(l(t))*l'(t)
velocity = f_1 .* l_1;

% acceleration = f'(l(t))*l''(t) + f''(l(t))*(l'(t))^2
acceleration = f_1 .* l_2 + f_2 .* l_1.^2;

% jerk = f'(l(t))*l'''(t) + f''(l(t))*l'(t)*l''(t) +
%                           f''(l(t))*2*(l'(t))*l''(t) + f'''(l(t))*(l'(t))^3
% jerk = f'(l(t))*l'''(t) + 3*f''(l(t))*l'(t)*l''(t) + f'''(l(t))*(l'(t))^3
jerk = f_1 .* l_3 + 3 .* f_2 .* l_1 .* l_2 + f_3 .* l_1.^3;

