function [k0, k1, hl, hip, hcd, theta] = mkpcc(waypoints, course, cusps)
%MATLABSHARED.TRACKING.INTERNAL.SCENARIO.MKPCC  Make piecewise continuous clothoids.
%
%   This function is for internal use only and may be removed in a later
%   release.
%
%   [K0, K1, HL, HIP, HCD, THETA] = ...
%   MATLABSHARED.TRACKING.INTERNAL.SCENARIO.MKPCC(WAYPOINTS, COURSE, CUSPS)
%   returns the initial curvatures, K0; final curvatures, K1; (horizontal)
%   curve lengths, HL; initial points in the horizontal complex plane, HIP;
%   and cumulative lengths, CUMLEN; and intial radian tangent angles,
%   THETA, of each segment of a piecewise-clothoid curve.
% 
%   The curve is constrained to pass through the waypoints specified as the
%   first and second column of WAYPOINTS.  WAYPOINTS may contain extra
%   columns, however these are ignored.  
% 
%   COURSE specifies the radian tangent angles at each waypoint to use when
%   constructing each curve.  COURSE must be a column vector with the same
%   number of rows as WAYPOINTS.  If an element in TANGENT is NaN, then the
%   tangent at the corresponding corresponding waypoint will be chosen to
%   minimize curvature differences between two adjacent segments, or if at
%   an endpoint, will be chosen to set curvature to zero at an endpoint.
%
%   CUSPS specifies which which waypoints are cusps (i.e., the curve exits
%   the waypoint in the opposite direction that it enters).  CUSPS must be
%   a column vector that contains the row indices of each waypoint that is
%   a cusp in ascending order.  If the corresponding element of COURSE is
%   set to NaN, then the waypoint is treated as an endpoint and the tangent
%   angle will be chosen so that the curvature entering the waypoint is
%   zero, otherwise the tangent angle that enters the waypoint will match
%   the angle specified by COURSE.
%
%   See Also:  MATLABSHARED.TRACKING.INTERNAL.SCENARIO.EVALPCC.

%   Copyright 2022 The MathWorks, Inc.

%#codegen

n = size(waypoints,1);

% Obtain the (horizontal) initial positions.
hip = complex(waypoints(:,1), waypoints(:,2));

% provide size hint to MATLAB Coder
theta = course;

if isempty(cusps)
    % Fill in missing course information
    theta = matlabshared.tracking.internal.scenario.solveMissingCourse(waypoints, course);
    
    % Obtain the initial curvatures, final curvatures, and (horizontal) 
    % lengths of each segment.
    [k0, k1, hl] = matlabshared.tracking.internal.scenario.clothoidG1fit2(...
            hip(1:n-1), theta(1:n-1), hip(2:n), theta(2:n));
else
    % sanity-check cusp specifier
    assert(~any(cusps(:)<=1 | cusps(:)>=n));
    assert(issorted(cusps));

    cusps = vertcat(cusps,n);

    % pre-allocate results
    k0 = zeros(n-1,1);
    k1 = zeros(n-1,1);
    hl = zeros(n-1,1);

    % get first cusp-free piecewise curve.
    m = cusps(1);

    % Fill in missing course information up to first cusp
    thetaSeg = matlabshared.tracking.internal.scenario.solveMissingCourse(waypoints(1:m,1:2), course(1:m));

    % Obtain the initial curvatures, final curvatures, and (horizontal) 
    % lengths of each segment.
    [k0Seg, k1Seg, hlSeg] = matlabshared.tracking.internal.scenario.clothoidG1fit2(...
            hip(1:m-1), thetaSeg(1:end-1), hip(2:m), thetaSeg(2:end));

    % provide hint to codegen when assembling result
    theta(1:m-1) = thetaSeg(1:m-1);
    k0(1:m-1) = k0Seg(1:m-1);
    k1(1:m-1) = k1Seg(1:m-1);
    hl(1:m-1) = hlSeg(1:m-1);

    for i = 2:numel(cusps)
        % fetch indices of next piecewise curve
        k = m;
        m = cusps(i);

        % create cusp by inverting sense of first angle from previous segment
        courseSeg = vertcat(angle(-exp(1i*thetaSeg(end))), course(k+1:m));

        % fill in missing course information of next piecewise curve
        thetaSeg = matlabshared.tracking.internal.scenario.solveMissingCourse(waypoints(k:m,1:2), courseSeg);

        % Obtain the initial curvatures, final curvatures, and (horizontal) 
        % lengths of each segment.
        [k0Seg, k1Seg, hlSeg] = matlabshared.tracking.internal.scenario.clothoidG1fit2(...
            hip(k:m-1), thetaSeg(1:end-1), hip(k+1:m), thetaSeg(2:end));

        % provide size hint to codegen when assembling result
        nseg = m-k;
        theta(k:m) = thetaSeg(1:nseg+1);
        k0(k:m-1) = k0Seg(1:nseg);
        k1(k:m-1) = k1Seg(1:nseg);
        hl(k:m-1) = hlSeg(1:nseg);
    end
end

% Report cumulative horizontal distance traveled from initial point.
hcd = [0; cumsum(hl)];