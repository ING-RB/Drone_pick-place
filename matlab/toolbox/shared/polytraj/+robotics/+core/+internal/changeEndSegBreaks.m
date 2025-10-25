function newBreaks = changeEndSegBreaks(oldBreaks, evalTime)
%This function is for internal use only. It may be removed in the future.

%CHANGEENDSEGBREAKS Extend the second to last polynomial segment break to ensure the final non-flat segment behaves correctly%
%   Given the breaks of the old pp-form, OLDBREAKS, and the time over which
%   it is evaluated, EVALTIME, this utility produces a new set of breaks,
%   NEWBREAKS that changes the second-to-last value of OLDBREAKS so that
%   the final computed trajectory segment (i.e. the last one before the
%   flat segment) is evaluated on the closed interval [breaks(end-2),
%   breaks(end-1)]. This is achieved by extending the value of
%   "breaks(end-1)" by a time step that is less than the first value of
%   EVALTIME that is greater than breaks(end-1).
%
%      - OLDBREAKS   - A 1xP vector of polynomial breaks
%
%      - EVALTIME    - An M-element vector of times at which the polynomial
%                      will be evaluated
%
%   NEWBREAKS = changeEndSegBreaks(OLDBREAKS, EVALTIME) computes a 1xP
%   vector of polynomial breaks that ensure that the resultant polynomial
%   behaves like the second-to-last segment at time=OLDBREAKS(end-1), and
%   not like the last segment.
%
%   BACKGROUND: The pp-forms for piecewise polynomials are defined over a
%   set of breaks from t=(initial time) to t=(final time), and then padded
%   with two flat segments that extend the breaks by one (an arbitrary
%   choice) in either direction. This means that the final computed
%   trajectory is defined by a piecewise polynomial that is evaluated on
%   the open interval [OLDBREAKS(end-2), OLDBREAKS(end-1)), while the
%   piecewise polynomial that defines the flat segment governs behavior on
%   the interval [OLDBREAKS(end-1), inf). For the other segments this is a
%   non-issue, since derivative bounds are only set when the corresponding
%   C1/C2 continuity is guaranteed. However, the addition of a flat segment
%   violates these continuity guarantees. Therefore, any values that are
%   expected to be hit at evalTime=OLDBREAKS(end-1) will only be hit if the
%   flat segment holds them, which is only certain for position (i.e. not
%   for non-zero values of velocity or acceleration).

%   Copyright 2018 The MathWorks, Inc.

%#codegen

% Initialize the breaks and time step
newBreaks = oldBreaks;
dt = 0.01;

% Final time over which the last computed trajectory segment is evaluated
finalTime = oldBreaks(end-1);

tGreaterThanTfIdx = find(evalTime > finalTime, 1);
if ~isempty(tGreaterThanTfIdx)
    % If polynomial is being evaluated at a time that is larger than the
    % final time over which the trajectory is defined, ensure that the
    % interval ends before that time
    % Note that tGreaterThanTfIdx is a scalar, but an index is used to
    % ensure codegen compatibility.
    tGreaterThanTf = evalTime(tGreaterThanTfIdx(1));
    dt = min((tGreaterThanTf - finalTime)/2, dt);
end

newBreaks(end-1) = finalTime + dt;

end