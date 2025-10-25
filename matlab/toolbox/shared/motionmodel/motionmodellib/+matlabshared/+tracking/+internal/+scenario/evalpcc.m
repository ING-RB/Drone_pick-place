function [f_0, f_1, f_2, f_3] = evalpcc(hcd, hip, hl, k0, k1, course, d)
%MATLABSHARED.TRACKING.INTERNAL.SCENARIO.EVALPCC  Evaluate piecewise continuous clothoids
%
%   This function is for internal use only and may be removed in a later
%   release.
%
%   [F0, F1, F2, F3] = MATLABSHARED.TRACKING.INTERNAL.SCENARIO.EVALPCC( ...
%      HCD, HIP, HL, K0, K1, COURSE, D)
%   evaluates the piecewise clothoid curve and first three derivatives
%   with respect to arclength at the specified distances, D.
%
%   HCD, IP, HL, K0, K1, and COURSE are column vectors whose rows
%   correspond to the parameters of each curve segment:
%
%      HCD     total (horizontal) cumulative distance before the segment
%
%      HIP     starting point in the (horizontal) complex plane
%
%      HL      total (horizontal) length of the segement
%
%      K0      initial curvature of the segment
%      K1      final curvatures of the segment
%
%      COURSE  intial tangent angle of the segment
%
%   % Example:
%
%   % create waypoints
%   waypoints = [7.1 13.1 0;
%               14.5 12.4 0;
%               21.8 12.3 0;
%               12.8 7.2 0;
%               12.6 -5.7 0;
%               13.6 0.9 0;
%               23 2.4 0];
%     
%   % specify G2 continuity at points within curves and zero curvature at
%   % endpoints.
%   course = NaN(size(waypoints,1),1);
%     
%   % set the tangent vector of the second waypoint to align with the x-axis
%   course(2) = 0;
%   
%   % mark the 3rd and 5th waypoint as a cusp.
%   cusps = [3;5];
%   
%   % construct the piecewise clothoid curve parameters
%   [k0, k1, hl, hip, hcd, course] = matlabshared.tracking.internal.scenario.mkpcc(waypoints, course, cusps);
%   
%   % evaluate the parameters uniformly over the total length of the curve
%   d = linspace(0,hcd(end),1000)';
%   
%   % plot the results
%   position = matlabshared.tracking.internal.scenario.evalpcc(hcd, hip, hl, k0, k1, course, d);
%   plot(real(position),imag(position),'.')
%
%   See Also:  MATLABSHARED.TRACKING.INTERNAL.SCENARIO.MKPCC.

%   Copyright 2022 The MathWorks, Inc.

%#codegen

% find index into table 
d(d>hcd(end)) = hcd(end);
d(d<hcd(1)) = hcd(1);
idx = discretize(d, hcd);

% fetch clothoid segment at index and initial position.
dkappa = (k1(idx)-k0(idx))./hl(idx);
dkappa(isnan(dkappa)) = 0;
kappa0 = k0(idx);
theta = course(idx);
p0 = hip(idx);

% get length into clothoid segment
l = d-hcd(idx);

% compute 0th through 3rd derivative of trajectory with respect to length
% evaluated at length l.
f_0 = matlabshared.tracking.internal.scenario.fresnelg2(l, dkappa, kappa0, theta) + p0;
f_1 = matlabshared.tracking.internal.scenario.dfresnelg2(l, dkappa, kappa0, theta);
f_2 = matlabshared.tracking.internal.scenario.ddfresnelg2(l, dkappa, kappa0, theta);
f_3 = matlabshared.tracking.internal.scenario.dddfresnelg2(l, dkappa, kappa0, theta);

end