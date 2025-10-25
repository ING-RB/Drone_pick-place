function [q, qd, qdd, pp] = bsplinepolytraj( controlPoints, timeInterval, t)
%BSPLINEPOLYTRAJ Generate multi-axis trajectories through control points using B-splines
%   [Q, QD, QDD, PP] = bsplinepolytraj(CONTROLPOINTS, TIMEINTERVAL, T)
%   generates a piecewise cubic B-spline trajectory that falls in the
%   control polygon defined by CONTROLPOINTS. The trajectory is uniformly
%   sampled between the start and end times given in TIMEINTERVAL. The
%   function outputs positions, Q, velocities, QD, and accelerations, QDD,
%   at the given time samples, T. It also outputs the ppform of the
%   polynomial with respect to time for the trajectory in PP.
%
%      CONTROLPOINTS  - An N x P matrix specifying P control points that 
%                       are each an N x 1 vector of positions.
%
%      TIMEINTERVAL -   A two element vector that indicates the start and
%                       end time of the trajectory
%
%      T          -     A sampled 1xM time vector from zero to the final 
%                       time.
%
%   This function outputs the vector trajectory position, Q, velocity, QD,
%   and acceleration, QDD, as N x M vectors. The values of Q are held
%   constant for values of T outside the range defined in TIMEINTERVAL. The
%   function also outputs PP, a pp-form representation of the piecewise
%   polynomial that defines Q as a function of T.
%
%   Reference:
%   G. Farin, Curves and Surfaces for Computer Aided Geometric Design: A
%   Practical Guide. San Diego, CA: Academic Press, Inc., 1993.
%
%   Example:
%      % Define time and position points
%      tpts = [0 5];
%      cpts = [1 4 4 3 -2 0; 0 1 2 4 3 1];
% 
%      % Define time vector
%      tvec = 0:0.01:5;
% 
%      % Compute trajectory using default boundary conditions
%      [q, qd, qdd, pp] = bsplinepolytraj(cpts, tpts, tvec);
%      
%      % Plot 2-D results in space
%      figure;
%      plot(cpts(1,:), cpts(2,:), 'x-');
%      hold all
%      plot(q(1,:), q(2,:))
%      hold off
% 
%      % Plot results in time. The x's are control points, and the lines 
%      % are the derived polynomial curves
%      figure
%      plot(tvec, q)
%      hold all
%      plot(linspace(0,5, length(cpts)), cpts, 'x')
%      hold off
% 
%   See also CUBICPOLYTRAJ, QUINTICPOLYTRAJ, TRAPVELTRAJ

%   Copyright 2018-2024 The MathWorks, Inc.

%#codegen

narginchk(3,3)

% Check input validity
validateattributes(controlPoints, {'numeric'}, {'2d','nonempty','real','finite'}, 'bsplinepolytraj','wayPoints');
validateattributes(timeInterval, {'numeric'}, {'nonempty','vector','real','finite','increasing','nonnegative'}, 'bsplinepolytraj','timeInterval');

% Establish some dimensions
n = size(controlPoints,1);

% Input checks
coder.internal.errorIf((size(controlPoints,2) < 4), 'shared_robotics:robotcore:utils:TooFewControlPoints');
if length(timeInterval) > 2
    msgID = 'shared_robotics:robotcore:utils:TimePointsSizeWarning';
    if coder.target('MATLAB')
        warning(message(msgID));
    else
        coder.internal.warning(msgID);
    end
end
coder.internal.errorIf((length(timeInterval) < 2), 'shared_robotics:robotcore:utils:TimePointsSizeError');

% Convert B-spline to L Bezier segments. This produces a matrix of points
% that define the bezier points that will be used to construct trajectories
% in space.
[bezierPoints, L] = convertToBezierForm(controlPoints);

% Compute cubic Bezier polynomials as parameterized functions of the knots.
% Here, a uniform interior knot sequence is used. The outputs are provided
% as coefficients and breaks in the standard pp-form format, which means
% that the breaks will occur at the interior knots (the outer 6 knots are
% duplicates of the first and last knot).
[breaks, coeffs] = constructParametrizedBezierPolynomials(bezierPoints, L);

% Convert parameterization to time by scaling linearly between the interior
% knots and the range defined by the start and end times.
[modBreaks, modCoeffs] = processPPFormInputs(breaks, coeffs, timeInterval, n);

% Compute derivatives
dModCoeffs = robotics.core.internal.polyCoeffsDerivative(modCoeffs);
ddModCoeffs = robotics.core.internal.polyCoeffsDerivative(dModCoeffs);

% Construct output pp-forms
pp = mkpp(modBreaks, modCoeffs, n);

% Compute the desired outputs
q = ppval(pp, t);
if nargout > 1
    ppd = mkpp(modBreaks, dModCoeffs, n);
    qd = ppval(ppd, t);
end
if nargout > 2
    ppdd = mkpp(modBreaks, ddModCoeffs, n);
    qdd = ppval(ppdd, t);
end
    
end

%% Helper functions

function [bezierPoints, L] = convertToBezierForm(ctrlPts)
%convertToBezierForm Convert B-spline control points to set of Bezier points
%   This function converts the B-spline control polygon into L Bezier
%   segments, each defined by 4 Bezier points. The fourth point of the ith
%   Bezier segment overlaps with the first point the (i+1)th segment, and
%   that point will occur at a knot. The Bezier points can subsequently be
%   used to construct cubic polynomials parameterized in u, where u falls
%   in the range of knots defined from u(0) to u(m). The following
%   conversion follows the method defined by Farin, Section 7.7.

% Total number of bezier segments
L = size(ctrlPts,2)-3;

% Extract d from cpts
d = ctrlPts(:, 2:(L+2));
dm1 = ctrlPts(:, 1); %d(-1)
dp1 = ctrlPts(:, end); %d(L+1)

bezierPoints = zeros(size(ctrlPts,1), 3*L+1);

% Use offsets to index from zero
b0 = 1;
d0 = 1;

% Start points. These are the points at the beginning of the B-spline
C1 = 1/2;
C2 = 1/2;
bezierPoints(:, b0 + 0) = dm1;
bezierPoints(:, b0 + 1) = d(:, d0 + 0);
if L > 1
    bezierPoints(:, b0 + 2) = C1*d(:, d0 + 0) + C2*d(:, d0 + 1);
end

% End points. These are the points at the end of the B-spline
C1 = 1/2;
C2 = 1/2;
if L > 1
    bezierPoints(:, b0 + 3*L-2) = C1*d(:, d0 + L-1) + C2*d(:, d0 + L);
end
bezierPoints(:, b0 + 3*L-1) = d(:, d0 + L);
bezierPoints(:, b0 + 3*L) = dp1;

% Intermediate points. There are the second and third values of the i(th)
% Bezier curve, excluding the first and last Bezier curves (i.e., in the
% range i = 2 to i = (L-1)).
for i = 2:(L-1)
    C1 = 2/3;
    C2 = 1/3;
    C3 = 1/3;
    C4 = 2/3;
    bezierPoints(:, b0 + 3*i-2) = C1*d(:, d0 + i-1) + C2*d(:, d0 + i);
    bezierPoints(:, b0 + 3*i-1) = C3*d(:, d0 + i-1) + C4*d(:, d0 + i);
end

% Junction points. These are the final values of the ith Bezier curve, i.e.
% the point where the fourth point of the ith Bezier curve becomes the
% first point of the (i+1)th Bezier curve.
for i = 1:(L-1)
    C1 = 1/2;
    C2 = 1/2;
    bezierPoints(:, b0 + 3*i) = C1*bezierPoints(:, b0 + 3*i-1) + C2*bezierPoints(:, b0 + 3*i+1);
end

end

function [qBreaks, qCoeffs] = constructParametrizedBezierPolynomials(bezierPoints, L)
%constructParametrizedBezierPolynomials Compute Bezier polynomials

% Number of axes
n = size(bezierPoints,1);

% Bezier matrix
M = [1 -3 3 -1; 0 3 -6 3; 0 0 3 -3; 0 0 0 1];

% Initialize the breaks and coefficient matrices The breaks define the
% range of each piecewise polynomial. Since a uniform knot sequence is
% used, this will be a vector from zero to L with spacing 1.
qBreaks = 0:L;
qCoeffs = zeros(L*n,4);

% Iterate through the L Bezier segments and construct coefficients for the
% cubic polynomial defined in the segment between the first and fourth
% points of the ith Bezier segment. The breaks define the range of the
% segment. Since a uniform (interior) knot sequence is used, the range of
% each segment will be exactly 1.
for i = 1:L    
    % Construct coefficients for the multi-axis control points. Since the
    % coefficients are defined over piecewise ranges set by the knot
    % sequence and a uniform knot sequence is used for the interior knots,
    % each knot is 1 greater than the last, so the coefficients are
    % parameterized over this range (i.e., from zero to one).
    Gq = zeros(n,4);
    Gq(:, :) = bezierPoints(:, (3*i-2):(3*i+1));
    qCubicCoefs = Gq*M;
    
    % The q coefficients is an array of coefficients for each axis. Since
    % there may be N axes defined in a piecewise polynomial, the ith
    % piecewise polynomial segment defines N rows the L*N x 4 coefficient
    % matrix used in piecewise polynomial construction.
    coeffIndexRange = ((i-1)*n) + (1:n);
    qCoeffs(coeffIndexRange, :) = fliplr(qCubicCoefs);
end

end

function [modBreaks, modCoeffs] = processPPFormInputs(breaks, coeffs, timeDuration, n)
%processPPFormInputs Map the piecewise polynomial to time and add flat segment

% Number of segments
L = length(breaks)-1;

% Modify the breaks so they occur in time
scaledBreaks = linspace(timeDuration(1),timeDuration(end),L+1);

% Scale the coefficients by the break length
scaledCoeffs = zeros(size(coeffs));
for i = 1:L
    segDuration = scaledBreaks(i+1)-scaledBreaks(i);
	cidxRange = ((i-1)*n) + (1:n);
    scaledCoeffs(cidxRange, :) = coeffs(cidxRange, :)*diag([1/segDuration^3 1/segDuration^2 1/segDuration 1]);
end

% Add flat segments to the start and end of each trajectory so the
% values will be held constant outside the user-specified time valuesmodCoeffs
[modBreaks, modCoeffs]=robotics.core.internal.addFlatSegmentsToPPFormParts(scaledBreaks, scaledCoeffs, n);

end

