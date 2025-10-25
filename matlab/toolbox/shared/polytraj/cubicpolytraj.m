function [ q, qd, qdd, pp] = cubicpolytraj( wayPoints, timePoints, t, varargin)
%CUBICPOLYTRAJ Generate third-order polynomial trajectories through multiple waypoints
%   [Q, QD, QDD, PP] = cubicpolytraj(WAYPOINTS, TIMEPOINTS, T) generates a
%   third-order polynomial trajectory that achieves a given set of input
%   waypoints with their corresponding time points. The function outputs
%   positions, Q, velocities, QD, and accelerations, QDD, at the given time
%   samples, T. It also outputs the ppforms of the polynomial for the
%   trajectory in PP.
%
%      WAYPOINTS  - An N x P matrix specifying P waypoints that are each an
%                   N x 1 vector of positions.
%
%      TIMEPOINTS - A 1xP vector of times corresponding to the timing of
%                   each associated waypoint.
%
%      T          - A sampled 1xM time vector from zero to the final time.
%
%   [Q, QD, QDD, PP] = cubicpolytraj(___, Name, Value)
%   provide additional options for polynomial interpolation specified by
%   Name-Value pair arguments.
%
%      'VelocityBoundaryCondition'  - The velocity boundary conditions,
%                                     specified as an N x P matrix of
%                                     velocities at each waypoint. By
%                                     default, this is assumed to be zero.
%
%   Example:
%      % Define time and position waypoints
%      tpts = 0:5;
%      wpts = [1 4 4 3 -2 0; 0 1 2 4 3 1];
%
%      % Define time vector
%      tvec = 0:0.01:5;
%
%      % Compute trajectory using default boundary conditions
%      [q, qd, qdd, pp] = cubicpolytraj(wpts, tpts, tvec);
%
%      % Plot results. The x's are waypoints, and the lines are the derived
%      % polynomial curves
%      plot(tvec, q)
%      hold all
%      plot(tpts, wpts, 'x')
%      hold off
%
%   See also BSPLINEPOLYTRAJ, QUINTICPOLYTRAJ, TRAPVELTRAJ

%   Copyright 2018-2019 The MathWorks, Inc.

%#codegen

    narginchk(3,5)

    % Convert strings to chars case by case for codegen support
    if nargin > 3
        charInputs = cell(1,2);
        [charInputs{:}] = convertStringsToChars(varargin{:});
    else
        charInputs = {};
    end

    % Check input validity
    validateattributes(wayPoints, {'numeric'}, {'2d','nonempty','real','finite'}, 'cubicpolytraj','wayPoints');
    validateattributes(timePoints, {'numeric'}, {'nonempty','vector','real','finite','increasing','nonnegative'}, 'cubicpolytraj','timePoints');

    % Ensure timePoints is a row
    timePoints = timePoints(:)';

    % Establish some dimensions
    n = size(wayPoints,1);
    p = size(wayPoints,2);

    % Parse inputs
    names = {'VelocityBoundaryCondition'};
    defaults = {zeros(n,p)};
    parser = robotics.core.internal.NameValueParser(names, defaults);
    parse(parser, charInputs{:});
    velBC = parameterValue(parser, names{1});

    % Input checks
    coder.internal.errorIf(length(timePoints) ~= p, 'shared_robotics:robotcore:utils:WayPointMismatch');
    coder.internal.errorIf(size(velBC,1) ~= n || size(velBC,2) ~= p, 'shared_robotics:robotcore:utils:WaypointVelocityBCDimensionMismatch');

    % Initialize output arrays
    q = zeros(n, length(t));
    qd = zeros(n, length(t));
    qdd = zeros(n, length(t));

    % Initialize the coefficient matrix to zeros. For P waypoints, there are
    % (P-1 segments) x (N dimensions) of polynomials, each with four
    % coefficients.
    coeffdim = 4;
    coefMat = zeros((p-1)*n,coeffdim);

    % Polynomial implementation: solve for the coefficients by segment on an
    % interval from zero to the segment end time.
    for i = 1:p-1
        % Get the final time, which indicates segment length
        finalTime = timePoints(i+1) - timePoints(i);

        % Solve for the coefficients along each dimension
        coeffMat = zeros(n,coeffdim);
        for j = 1:n
            coeffMat(j,:) = generateCubicCoeffs(wayPoints(j,i:i+1), velBC(j, i:i+1), finalTime);

            % Store for pp-form output
            cidx = (i-1)*n + j;
            coefMat(cidx, :) = coeffMat(j,:);
        end
    end

    % Add flat segments to the start and end of each trajectory so the
    % values will be held constant outside the user-specified time values
    [modBreaks, modCoeffs] = robotics.core.internal.addFlatSegmentsToPPFormParts(timePoints, coefMat, n);

    % Compute pp-forms and evaluate using ppval
    pp = mkpp(modBreaks, modCoeffs, n);
    q(:,:) = ppval(pp, t);

    % Only compute velocity and acceleration if needed
    if nargout > 1
        % In order for derivatives to have nonzero values at final time, the
        % second to last break must extend past the final time in the
        % derivative coefficients
        derivativeBreaks = robotics.core.internal.changeEndSegBreaks(modBreaks, t);

        % Get coefficients for first derivative pp-form and evaluate
        dCoeffs = robotics.core.internal.polyCoeffsDerivative(modCoeffs);
        ppd = mkpp(derivativeBreaks, dCoeffs, n);
        qd(:,:) = ppval(ppd, t);
    end

    if nargout > 2
        % Get coefficients for second derivative pp-form and evaluate
        ddCoeffs = robotics.core.internal.polyCoeffsDerivative(dCoeffs);
        ppdd = mkpp(derivativeBreaks, ddCoeffs, n);
        qdd(:,:) = ppval(ppdd, t);
    end

end

%% Helper Functions

function coeffVec = generateCubicCoeffs(posPts, velPts, finalTime)
%generateCubicCoeffs Compute coefficients of a cubic polynomial segments
%   This function computes the cubic polynomial coefficients given the
%   bounding positions and velocities of a segment defined from t=0 to
%   t=finalTime.

% Define initial and final position and velocity
    x0 = posPts(1);
    dx0 = velPts(1);

    xT = posPts(2);
    dxT = velPts(2);

    % First two coefficients can be found by setting t=0 using boundary conditions
    coeffVec = [x0 dx0 0 0]';

    % % The last two coefficients may be found by substituting the first three
    % into the expressions for position and velocity at t=finalTime:
    % [q(T) qd(T)]' = TMat0*[C1 C2]' + TMatF*[C3 C4]
    % where TMatF =
    %   [finalTime^2  finalTime^3; ...
    %    2*finalTime  3*finalTime^2];
    % This expression may be solve for C3 and C4
    TMat0 = [1 finalTime; 0 1];
    B = [xT; dxT] - TMat0*coeffVec(1:2);

    % Since Tmat is a known function of finalTime, use the analytical inverse
    % of TMatF to avoid numerical issues:
    invTMatF = [3/finalTime^2 -1/finalTime; ...
                -2/finalTime^3 1/finalTime^2];
    coeffVec(3:4) = invTMatF * B;

    % Flip the order to match standard form
    coeffVec = fliplr(coeffVec');

end
