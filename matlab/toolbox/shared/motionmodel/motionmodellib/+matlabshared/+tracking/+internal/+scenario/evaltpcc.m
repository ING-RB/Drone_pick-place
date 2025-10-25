function [position, velocity, acceleration, jerk, idx, L_0, L_1, L_2, L_3, T_0, T_1] ...
    = evaltpcc(hcd, hip, hl, k0, k1, course, hpp, hspp, happ, hjpp, t)
%MATLABSHARED.TRACKING.INTERNAL.SCENARIO.EVALTPCC evaluate time-parameterized piecewise clothoid curve.
%
%   This function is for internal use only and may be removed in a later
%   release.
%
%   [POSITION, VELOCITY, ACCELERATION, JERK, IDX, L_0, L_1, L_2, L_3, T_0, T_1] ...
%   = MATLABSHARED.TRACKING.INTERNAL.SCENARIO.EVALTPCC( ...
%       HCD, HIP, HL, K0, K1, COURSE, HPP, HSPP, HAPP, HJPP, T)
%
%   returns state information of the piecewise clothoid curve traversed via
%   the piecewise polynomials in time.
%
%   HCD, HIP, HL, K0, K1, and COURSE correspond to the (horizontal)
%   cumulative distance, initial positions, segment lengths, initial and
%   final curvatures of each segment, respectively.  They are each column
%   vectors where the N-th row element corresponds to the N-th curve
%   segment.
%
%   HPP, HSPP, HAPP, HJPP, correspond to piecewise polynomials in the same
%   format used by MKPP and PPEVAL that are used to compute the length,
%   speed, acceleration and jerk derivatives for the specified time values,
%   T.  
%
%   POSITION, VELOCITY, ACCELERATION, and JERK return the value of the
%   curve evaluated in the complex plane and its derivatives evaluated at
%   the specified times in T.
%
%   IDX additionally returns the index of the corresponding segment of the
%   piecewise clothoid curve.
%
%   L_0, L_1, L_2, L_3, additionally return the length traveled along the
%   curve, L, and its first three time derivatives: L_1, L_2, L_3.
%
%   T_0 and T_1 additionally return the value of the unit tangent vector
%   and its first time derivative.
   
%   Copyright 2022 The MathWorks, Inc.

%#codegen

% compute 0th through 3rd derivative of length traveled with respect to time.

assert(iscolumn(t));

L_0 = ppval(hpp, t);
L_1 = ppval(hspp, t);
L_2 = ppval(happ, t);
L_3 = ppval(hjpp, t);

% find index into table 
L_0(L_0>hcd(end)) = hcd(end);
L_0(L_0<hcd(1)) = hcd(1);
idx = discretize(L_0, hcd);

% fetch clothoid segment at index and initial position.
dkappa = (k1(idx)-k0(idx))./hl(idx);
dkappa(isnan(dkappa)) = 0;
kappa0 = k0(idx);
theta = course(idx);
p0 = hip(idx);

% get length into clothoid segment
l = L_0-hcd(idx);

% return the active row index and 0th through 3rd derivative of trajectory
% with respect to length evaluated at length l.
f_0 = matlabshared.tracking.internal.scenario.fresnelg2(l, dkappa, kappa0, theta);
f_1 = matlabshared.tracking.internal.scenario.dfresnelg2(l, dkappa, kappa0, theta);
f_2 = matlabshared.tracking.internal.scenario.ddfresnelg2(l, dkappa, kappa0, theta);
f_3 = matlabshared.tracking.internal.scenario.dddfresnelg2(l, dkappa, kappa0, theta);

position = f_0 + p0;

% velocity = f'(l(t))*l'(t)
velocity = f_1 .* L_1;

% acceleration = f'(l(t))*l''(t) + f''(l(t))*(l'(t))^2
acceleration = f_1 .* L_2 + f_2 .* L_1.^2;

% jerk = f'(l(t))*l'''(t) + f''(l(t))*l'(t)*l''(t) +
%                           f''(l(t))*2*(l'(t))*l''(t) + f'''(l(t))*(l'(t))^3
% jerk = f'(l(t))*l'''(t) + 3*f''(l(t))*l'(t)*l''(t) + f'''(l(t))*(l'(t))^3
jerk = f_1 .* L_3 + 3 .* f_2 .* L_1 .* L_2 + f_3 .* L_1.^3;

% unit tangent = f'(l(t))
T_0 = f_1;

% unit tangent derivative = f''(l(t))*l'(t)
T_1 = f_2 .* L_1;