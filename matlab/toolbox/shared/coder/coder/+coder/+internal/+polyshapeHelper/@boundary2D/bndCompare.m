function [s_metric, s_angle, s_v1, s_v2, ...
    s_size, s_ht0_error, s_slope_error] = bndCompare(c1, c2, update_p)
%

%   Copyright 2023 The MathWorks, Inc.

%#codegen

turningFun = coder.internal.polyshapeHelper.sTurning();

if c1.getBoundarySize(1) > c2.getBoundarySize(1)
    [f, c1_len] = coder.internal.polyshapeHelper.sTurning.boundary_to_turn_rep(c1);
    [g, c2_len] = coder.internal.polyshapeHelper.sTurning.boundary_to_turn_rep(c2);
else
    [g, c1_len] = coder.internal.polyshapeHelper.sTurning.boundary_to_turn_rep(c1);
    [f, c2_len] = coder.internal.polyshapeHelper.sTurning.boundary_to_turn_rep(c2);
end

[ht0,slope,alpha] = coder.internal.polyshapeHelper.sTurning.init_vals(f, g);

turningFun = turningFun.init_events(f, g);

if update_p
    nEvt = coder.internal.polyshapeHelper.sTurning.reinit_interval(f, g);
else
    nEvt = 0;
end

[metric2, theta_star, ev, ht0_err, slope_err] = ...
    turningFun.h_t0min(f, g, ht0, slope, alpha, nEvt);

if metric2 > 0
    s_metric = sqrt(metric2);
else
    s_metric = 0;
end
s_angle = (bound_angle(theta_star, 0) * 180) / pi;
assert(c1_len > eps);

s_size = c2_len / c1_len;
s_v2 = f.mod(ev.fi);
s_v1 = g.mod(ev.gi);
s_ht0_error = ht0_err;
s_slope_error = slope_err;

end

%--------------------------------------------------------------------------
% bound input angle 'a' within [base-PI, base+PI).
function a = bound_angle(theta, base)
neg_PI = -pi - 1.0e-6;
a = theta;
while (a - base < neg_PI)
    a = a + 2*pi;
end
while (a - base >= pi)
    a = a - 2*pi;
end
end
